import fcntl
import json
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

import popup


@unittest.skipUnless(os.environ.get("TMUX_TEST_WRAPPER") and os.environ.get("TMUX_TEST_POPUP"),
                     "requires the built tmux and popup helper")
class PopupWorkflowTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="tmux popup workflow ")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.env = dict(os.environ, TERM="xterm-256color", SHELL=os.environ["TMUX_TEST_SHELL"])
        for key in ("TMUX", "TMUX_PANE", "BASH_ENV", "ENV"):
            self.env.pop(key, None)
        binaries = self.root / "bin"
        binaries.mkdir()
        (binaries / "tmux").symlink_to(os.environ["TMUX_TEST_WRAPPER"])
        app = binaries / "mux-repo"
        app.write_text(
            f"#!{sys.executable}\n"
            "import json, os, pathlib, sys, time\n"
            f"root = pathlib.Path({str(self.root)!r})\n"
            "(root / 'started').write_text(json.dumps({'pid': os.getpid(), "
            "'pane': os.environ['TMUX_PANE'], 'cwd': os.getcwd(), 'tool': sys.argv[1]}))\n"
            "print('POPUP_TOOL_READY', flush=True)\n"
            "while not (root / 'exit').exists(): time.sleep(.01)\n"
        )
        app.chmod(0o755)
        self.env["PATH"] = str(binaries) + os.pathsep + self.env["PATH"]
        self.socket = str(self.root / "socket")
        self.command = [os.environ["TMUX_TEST_WRAPPER"], "-u", "-S", self.socket,
                        "-f", "/dev/null"]
        self.master, self.slave = pty.openpty()
        self.addCleanup(os.close, self.master)
        self.addCleanup(os.close, self.slave)
        fcntl.ioctl(self.slave, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 100, 0, 0))
        self.processes = []
        self.addCleanup(self.stop)
        self.tmux("new-session", "-d", "-s", "parent", "-c", str(self.root))
        self.tmux("set-option", "-g", "detach-on-destroy", "off")
        self.tmux("set-option", "-g", "prefix", "C-Space")
        helper = [sys.executable, str(Path(popup.__file__).resolve())]
        self.tmux("bind-key", "!", "run-shell", "-b",
                  shlex.join([*helper, "promote"]) + " '#{pane_id}'")
        self.pane = self.tmux("display-message", "-p", "-t", "parent:", "#{pane_id}")
        self.parent = self.tmux("display-message", "-p", "-t", self.pane, "#{session_id}")
        self.client = subprocess.Popen([*self.command, "attach-session", "-t", "parent"],
                                       env=self.env, stdin=self.slave, stdout=self.slave,
                                       stderr=self.slave)
        self.processes.append(self.client)
        self.wait_for(lambda: bool(self.tmux("list-clients", "-F", "#{client_tty}")))
        self.tty = self.tmux("list-clients", "-F", "#{client_tty}")
        self.helper_env = dict(self.env, TMUX=f"{self.socket},{self.tmux('display-message', '-p', '#{pid}')},0")
        self.helper = helper

    def tmux(self, *args):
        return subprocess.check_output([*self.command, *args], env=self.env,
                                       text=True, stderr=subprocess.PIPE).strip()

    def drain(self):
        if select.select([self.master], [], [], 0.01)[0]:
            os.read(self.master, 65536)

    def wait_for(self, predicate):
        deadline = time.monotonic() + 8
        while time.monotonic() < deadline:
            self.drain()
            if predicate():
                return
        self.fail("Timed out waiting for isolated tmux popup workflow")

    def stop(self):
        subprocess.run([*self.command, "kill-server"], env=self.env, capture_output=True)
        for process in self.processes:
            try:
                process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=3)
            if process.stderr and process.stderr is not self.slave:
                process.stderr.close()

    def open_popup(self, tool):
        self.opening = subprocess.Popen([*self.helper, "open", tool, self.pane, self.tty],
                                        env=self.helper_env, stdout=subprocess.DEVNULL,
                                        stderr=subprocess.PIPE)
        self.processes.append(self.opening)
        self.wait_for(lambda: (self.root / "started").exists()
                      and len(self.tmux("list-clients", "-F", "#{client_tty}").splitlines()) == 2)
        self.app = json.loads((self.root / "started").read_text())
        self.popup_session = self.tmux("display-message", "-p", "-t", self.app["pane"], "#{session_id}")
        self.assertEqual(self.app["cwd"], str(self.root))
        self.assertEqual(self.app["tool"], tool)
        self.assertEqual(self.tmux("show-options", "-qv", "-t", self.popup_session,
                                  "@mux-popup-parent"), self.parent)
        self.assertEqual(self.tmux("show-options", "-qv", "-t", self.popup_session,
                                  "status"), "off")
        self.assertEqual(self.tmux("show-options", "-qv", "-t", self.popup_session,
                                  "detach-on-destroy"), "on")

    def assert_closed(self):
        self.wait_for(lambda: self.opening.poll() is not None)
        self.assertEqual(self.opening.returncode, 0, self.opening.stderr.read().decode())
        self.assertNotIn(self.popup_session, self.tmux("list-sessions", "-F", "#{session_id}").splitlines())
        self.assertEqual(self.tmux("list-clients", "-F", "#{session_id}"), self.parent)
        self.assertIsNone(self.client.poll())

    def test_prefix_promotes_live_pane_and_selects_outer_window(self):
        self.open_popup("tuicr")
        pane_pid = self.tmux("display-message", "-p", "-t", self.app["pane"], "#{pane_pid}")
        os.write(self.master, b"\x00!")
        self.assert_closed()
        self.assertEqual(self.tmux("display-message", "-p", "-t", self.app["pane"], "#{pane_pid}"), pane_pid)
        os.kill(self.app["pid"], 0)
        self.assertEqual(self.tmux("display-message", "-p", "-t", self.app["pane"], "#{session_id}"), self.parent)
        promoted_window = self.tmux("display-message", "-p", "-t", self.app["pane"], "#{window_id}")
        self.wait_for(lambda: self.tmux("list-clients", "-F", "#{window_id}") == promoted_window)

    def test_promotion_closes_popup_with_an_extra_pane(self):
        self.open_popup("tuicr")
        extra = self.tmux("split-window", "-d", "-t", self.app["pane"], "-P", "-F", "#{pane_id}")
        pid = self.tmux("display-message", "-p", "-t", self.app["pane"], "#{pane_pid}")
        os.write(self.master, b"\x00!")
        self.assert_closed()
        self.assertEqual(self.tmux("display-message", "-p", "-t", self.app["pane"], "#{pane_pid}"), pid)
        self.assertNotIn(extra, self.tmux("list-panes", "-a", "-F", "#{pane_id}").splitlines())
        self.wait_for(lambda: self.tmux("list-clients", "-F", "#{pane_id}") == self.app["pane"])

    def test_space_navigation_skips_popup_and_targets_second_client(self):
        self.tmux("new-session", "-d", "-s", "second", "-c", str(self.root))
        second_session = self.tmux("display-message", "-p", "-t", "second:", "#{session_id}")
        second_pane = self.tmux("display-message", "-p", "-t", "second:", "#{pane_id}")
        self.open_popup("tuicr")
        master, slave = pty.openpty()
        self.addCleanup(os.close, master)
        self.addCleanup(os.close, slave)
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 100, 0, 0))
        second_client = subprocess.Popen([*self.command, "attach-session", "-t", "second"],
                                         env=self.env, stdin=slave, stdout=slave, stderr=slave)
        self.processes.append(second_client)
        self.wait_for(lambda: len(self.tmux("list-clients", "-F", "#{client_tty}").splitlines()) == 3)
        tty = os.ttyname(slave)
        def clients():
            return dict(line.split("\t") for line in self.tmux(
                "list-clients", "-F", "#{client_tty}\t#{session_id}").splitlines())

        navigation = [sys.executable, str(Path(popup.__file__).with_name("navigate.py")), "space"]
        subprocess.run([*navigation, "next", second_pane, tty], env=self.helper_env, check=True)
        self.assertEqual(clients()[tty], self.parent)
        subprocess.run([*navigation, "previous", self.pane, tty], env=self.helper_env, check=True)
        self.assertEqual(clients()[tty], second_session)
        self.assertEqual(clients()[self.tty], self.parent)
        self.assertIsNone(self.opening.poll())
        self.assertEqual(len(clients()), 3)
        self.tmux("display-popup", "-C", "-c", self.tty)
        self.wait_for(lambda: self.opening.poll() is not None)
        self.assertEqual(self.opening.returncode, 0, self.opening.stderr.read().decode())
        self.assertNotIn(self.popup_session, self.tmux("list-sessions", "-F", "#{session_id}").splitlines())
        self.assertEqual(clients()[tty], second_session)
        self.assertIsNone(second_client.poll())
        self.assertIsNone(self.client.poll())

    def test_tool_exit_closes_popup_and_removes_temporary_session(self):
        self.open_popup("jjui")
        (self.root / "exit").touch()
        self.assert_closed()
        self.assertEqual(self.tmux("list-windows", "-t", self.parent, "-F", "#{pane_id}"), self.pane)

    def test_popup_cancellation_removes_live_temporary_session(self):
        self.open_popup("tuicr")
        self.tmux("display-popup", "-C", "-c", self.tty)
        self.assert_closed()

    def test_normal_pane_preserves_default_break_pane_behavior(self):
        self.tmux("split-window", "-d", "-t", self.pane, "-P", "-F", "#{pane_id}")
        subprocess.run([*self.helper, "promote", self.pane], env=self.helper_env, check=True)
        self.assertEqual(len(self.tmux("list-windows", "-t", self.parent).splitlines()), 2)
        self.assertEqual(self.tmux("list-clients", "-F", "#{pane_id}"), self.pane)


if __name__ == "__main__":
    unittest.main()
