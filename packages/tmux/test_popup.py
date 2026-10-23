"""Exercise real tmux drawing through a PTY, including synchronized frames."""
import fcntl
import os
from pathlib import Path
import pty
import select
import shlex
import struct
import subprocess
import sys
import tempfile
import termios
import time
import unittest
from unittest import mock

import popup as popup_module

try:
    import pyte
except ImportError:
    pyte = None


class LaunchStatusTests(unittest.TestCase):
    def test_launch_status_and_pause(self):
        with mock.patch.dict(os.environ, TMUX="/unused/socket,0,0"), \
                mock.patch.object(sys, "argv", ["mux-popup", "open", "tuicr", "%0", "/dev/pts/0"]), \
                mock.patch.object(popup_module.subprocess, "check_output",
                                  side_effect=["$0", "/tmp", "$1", ""]) as tmux, \
                mock.patch.object(popup_module.subprocess, "run") as run:
            run.return_value.returncode = 0
            popup_module.main()
            launch = tmux.call_args_list[2].args[0][-1]
        for status in (0, 7, 129, 130):
            with self.subTest(status=status):
                script = f"mux-repo() {{ printf 'launch output\\n'; return {status}; }}; " + launch
                result = subprocess.run([os.environ.get("TMUX_TEST_SHELL", "/bin/sh"), "-e", "-c", script],
                                        input="\n", text=True, capture_output=True)
                self.assertEqual(result.returncode, status)
                self.assertIn("launch output", result.stdout)
                if status == 7:
                    self.assertIn("tuicr", result.stdout)
                    self.assertIn("7", result.stdout)
                    self.assertIn("Press Enter to close", result.stdout)
                else:
                    self.assertNotIn("Press Enter to close", result.stdout)


@unittest.skipUnless(pyte and os.environ.get("TMUX_TEST_WRAPPER"), "requires tmux and pyte")
class PopupTests(unittest.TestCase):
    @unittest.skipUnless(os.environ.get("TMUX_TEST_POPUP"), "requires packaged mux-popup")
    def test_failed_launch_waits_for_enter(self):
        with tempfile.TemporaryDirectory(prefix="tmux-popup-failure-") as directory:
            root = Path(directory)
            env = dict(os.environ, TERM="xterm-256color", SHELL=os.environ["TMUX_TEST_SHELL"],
                       REVIEWCTL_HOME=str(root / "reviewctl"))
            for key in ("TMUX", "TMUX_PANE", "BASH_ENV", "ENV"):
                env.pop(key, None)
            command = [os.environ["TMUX_TEST_WRAPPER"], "-u", "-S", str(root / "socket"), "-f", "/dev/null"]

            def tmux(*args):
                return subprocess.check_output([*command, *args], env=env, text=True).strip()

            class Screen(pyte.Screen):
                def report_device_status(self, *args, **kwargs):
                    pass

            screen = Screen(100, 30)
            stream = pyte.ByteStream(screen)
            master, slave = pty.openpty()
            fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 100, 0, 0))
            client = popup = None

            def drain(duration):
                deadline = time.monotonic() + duration
                while time.monotonic() < deadline:
                    if select.select([master], [], [], 0.01)[0]:
                        stream.feed(os.read(master, 65536))

            def wait_for(predicate):
                deadline = time.monotonic() + 10
                while time.monotonic() < deadline:
                    drain(0.02)
                    if predicate():
                        return
                self.fail("Timed out waiting for popup: " + "\n".join(screen.display))

            try:
                pane = tmux("new-session", "-d", "-s", "original", "-c", str(root),
                            "-P", "-F", "#{pane_id}", env["SHELL"], "--noprofile", "--norc")
                tmux("set", "-g", "default-shell", env["SHELL"])
                tmux("set-hook", "-gu", "client-attached")
                client = subprocess.Popen([*command, "attach", "-t", "original"], env=env,
                                          stdin=slave, stdout=slave, stderr=slave)
                wait_for(lambda: bool(tmux("list-clients", "-F", "#{client_tty}")))
                tty = tmux("list-clients", "-F", "#{client_tty}")
                popup_env = dict(env, TMUX=f"{root / 'socket'},0,0", TMUX_PANE=pane)
                popup = subprocess.Popen([os.environ["TMUX_TEST_POPUP"], "open", "tuicr", pane, tty],
                                         env=popup_env, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
                wait_for(lambda: any("Press Enter to close" in row for row in screen.display))
                visible = "\n".join(screen.display)
                self.assertIn("reviewctl: Not a repository:", visible)
                self.assertRegex(visible, r"tuicr.*[1-9][0-9]*")
                sessions = tmux("list-sessions", "-F", "#{session_name}").splitlines()
                temporary = [name for name in sessions if name.startswith("mux-popup-")]
                self.assertEqual(len(temporary), 1)
                drain(0.2)
                self.assertIsNone(popup.poll())
                self.assertIn("Press Enter to close", "\n".join(screen.display))
                self.assertIn(temporary[0], tmux("list-sessions", "-F", "#{session_name}"))
                os.write(master, b"\r")
                wait_for(lambda: popup.poll() is not None)
                self.assertEqual(popup.returncode, 0, popup.stderr.read().decode())
                self.assertEqual(tmux("list-sessions", "-F", "#{session_name}"), "original")
                self.assertEqual(tmux("list-panes", "-t", "original", "-F", "#{pane_id}"), pane)
                self.assertIsNone(client.poll())
            finally:
                subprocess.run([*command, "kill-server"], env=env, capture_output=True)
                for process in (popup, client):
                    if process:
                        process.wait(timeout=3)
                if popup and popup.stderr:
                    popup.stderr.close()
                os.close(master)
                os.close(slave)

    def test_scrolling_behind_popup_preserves_borders_with_top_status(self):
        with tempfile.TemporaryDirectory(prefix="tmux-popup-") as directory:
            root = Path(directory)
            env = dict(os.environ, TERM="xterm-256color", SHELL=os.environ["TMUX_TEST_SHELL"])
            for key in ("TMUX", "TMUX_PANE", "BASH_ENV", "ENV"):
                env.pop(key, None)
            command = [os.environ["TMUX_TEST_WRAPPER"], "-u", "-S", str(root / "socket"), "-f", "/dev/null"]

            def tmux(*args):
                return subprocess.check_output([*command, *args], env=env, text=True).strip()

            class Screen(pyte.Screen):
                # tmux probes private device status, which pyte doesn't emulate.
                def report_device_status(self, *args, **kwargs):
                    pass

                def reset_mode(self, *modes, **kwargs):
                    super().reset_mode(*modes, **kwargs)
                    if 2026 in modes and self.border:
                        self.frames += 1
                        changed = [(x, y) for (x, y), char in self.border.items()
                                   if self.buffer[y][x].data != char]
                        if changed:
                            self.damaged_frames.append(changed)

            screen = Screen(100, 30)
            screen.border = {}
            screen.frames = 0
            screen.damaged_frames = []
            stream = pyte.ByteStream(screen)
            master, slave = pty.openpty()
            fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 100, 0, 0))
            client = popup = None

            def drain(duration):
                deadline = time.monotonic() + duration
                while time.monotonic() < deadline:
                    if select.select([master], [], [], 0.01)[0]:
                        stream.feed(os.read(master, 65536))

            def wait_for(predicate):
                deadline = time.monotonic() + 5
                while time.monotonic() < deadline:
                    drain(0.02)
                    if predicate():
                        return
                self.fail("Timed out waiting for the isolated tmux client")

            background = root / "background.py"
            background.write_text(
                "import pathlib, time\n"
                f"while not pathlib.Path({str(root / 'start')!r}).exists(): time.sleep(.01)\n"
                "for i in range(80):\n"
                " print('BACKGROUND' * 30, flush=True)\n"
                " time.sleep(.01)\n"
                f"pathlib.Path({str(root / 'done')!r}).touch()\n"
                "time.sleep(20)\n"
            )
            app = root / "popup.py"
            app.write_text(
                "import pathlib, time\n"
                "print('\\033[?25l\\033[HPOPUP', flush=True)\n"
                f"while not pathlib.Path({str(root / 'start')!r}).exists(): time.sleep(.01)\n"
                "for i in range(80):\n"
                " print('\\033[H\\033[2JPOPUP ' + str(i), flush=True)\n"
                " time.sleep(.01)\n"
                "time.sleep(20)\n"
            )
            try:
                tmux("new-session", "-d", "-s", "render", sys.executable, str(background))
                tmux("set", "-g", "status-position", "top")
                # Exercise the same synchronized-output protocol as Ghostty,
                # without depending on a real terminal answering probes.
                tmux("set", "-as", "terminal-overrides", ",xterm*:Sync=\033[?2026%?%p1%{1}%-%tl%eh%;")
                client = subprocess.Popen([*command, "attach", "-t", "render"], env=env,
                                          stdin=slave, stdout=slave, stderr=slave)
                wait_for(lambda: bool(tmux("list-clients", "-F", "#{client_tty}")))
                popup = subprocess.Popen([*command, "display-popup", "-E", "-w", "60", "-h", "20",
                                          shlex.join([sys.executable, str(app)])], env=env,
                                         stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
                wait_for(lambda: any("POPUP" in row for row in screen.display))
                drain(0.1)
                screen.border = {(x, y): cell.data for y, row in screen.buffer.items()
                                 for x, cell in row.items() if cell.data in "┌┐└┘│─"}
                self.assertEqual(len(screen.border), 2 * 60 + 2 * (20 - 2))
                (root / "start").touch()
                wait_for(lambda: (root / "done").exists())
                drain(0.1)
                self.assertGreater(screen.frames, 10)
                self.assertEqual(len(screen.damaged_frames), 0,
                                 f"Popup border damaged in {len(screen.damaged_frames)}/{screen.frames} frames; "
                                 f"first changed cells: {screen.damaged_frames[:1]}")
            finally:
                subprocess.run([*command, "kill-server"], env=env, capture_output=True)
                for process in (popup, client):
                    if process:
                        process.wait(timeout=3)
                if popup and popup.stderr:
                    popup.stderr.close()
                os.close(master)
                os.close(slave)


if __name__ == "__main__":
    unittest.main()
