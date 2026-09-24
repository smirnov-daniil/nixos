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

try:
    import pyte
except ImportError:
    pyte = None


@unittest.skipUnless(pyte and os.environ.get("TMUX_TEST_WRAPPER"), "requires tmux and pyte")
class PopupTests(unittest.TestCase):
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
