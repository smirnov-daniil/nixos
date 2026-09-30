import os
from pathlib import Path
import pty
import shlex
import subprocess
import tempfile
import time
import unittest

from project import session_name


@unittest.skipUnless(os.environ.get("TMUX_TEST_WRAPPER"), "requires the built tmux wrapper")
class RuntimeTests(unittest.TestCase):
    def test_fresh_server_uses_csi_u(self):
        with tempfile.TemporaryDirectory(prefix="tmux-keys-") as directory:
            env = dict(os.environ, SHELL=os.environ["TMUX_TEST_SHELL"])
            env.pop("TMUX", None)
            command = [os.environ["TMUX_TEST_WRAPPER"], "-S", str(Path(directory) / "socket")]
            try:
                subprocess.run([*command, "new-session", "-d", "-s", "keys"], env=env, check=True)
                for option, value in (("extended-keys", "on"), ("extended-keys-format", "csi-u")):
                    result = subprocess.check_output([*command, "show-options", "-sv", option], env=env, text=True)
                    self.assertEqual(result.strip(), value)
            finally:
                subprocess.run([*command, "kill-server"], env=env, capture_output=True)

    @unittest.skipUnless(os.environ.get("TMUX_TEST_PROJECT"), "requires the built mux launcher")
    def test_mux_opens_one_environment_shell_and_reuses_it(self):
        with tempfile.TemporaryDirectory(prefix="tmux-project-") as directory:
            base = Path(directory)
            root = base / "project with spaces"
            (root / ".git").mkdir(parents=True)
            (root / ".envrc").write_text("export MUX_TEST_IDENTITY=environment-loaded\n")
            env = dict(os.environ, TERM="xterm-256color", SHELL=os.environ["TMUX_TEST_SHELL"],
                       TMUX_TMPDIR=str(base), HOME=str(base / "home"),
                       XDG_CONFIG_HOME=str(base / "config"), XDG_DATA_HOME=str(base / "data"),
                       XDG_CACHE_HOME=str(base / "cache"), CCMUX_HOME=str(base / "ccmux"))
            for key in list(env):
                if key.startswith("DIRENV_") or key in ("TMUX", "TMUX_PANE", "BASH_ENV", "ENV"):
                    env.pop(key)
            command = [os.environ["TMUX_TEST_WRAPPER"]]

            def tmux(*args):
                return subprocess.check_output([*command, *args], env=env, text=True).strip()

            def wait_for(predicate):
                deadline = time.monotonic() + 5
                while time.monotonic() < deadline:
                    if predicate():
                        return
                    time.sleep(0.02)
                self.fail("Timed out waiting for the isolated project shell")

            subprocess.run(["direnv", "allow", str(root)], env=env, check=True, capture_output=True)
            master, slave = pty.openpty()
            client = None
            name = session_name(root)
            target = "=" + name
            try:
                tmux("new-session", "-d", "-s", "bootstrap")
                tmux("set-hook", "-gu", "client-attached")
                client = subprocess.Popen([os.environ["TMUX_TEST_PROJECT"], str(root)], env=env,
                                          stdin=slave, stdout=slave, stderr=slave)
                wait_for(lambda: tmux("list-clients", "-F", "#{session_name}") == name)
                pane = tmux("display-message", "-p", "-t", target, "#{pane_id}")
                self.assertEqual(len(tmux("list-windows", "-t", target, "-F", "#{window_id}").splitlines()), 1)
                probe = base / "environment"
                tmux("send-keys", "-t", pane,
                     'printf \'%s\\n\' "$MUX_TEST_IDENTITY" "$PWD" > ' + shlex.quote(str(probe)), "Enter")
                expected = ["environment-loaded", str(root)]
                wait_for(lambda: probe.exists() and probe.read_text().splitlines() == expected)
                self.assertEqual(probe.read_text().splitlines(), expected)
                inside_env = dict(env, TMUX=tmux("display-message", "-p", "-t", target,
                                               "#{socket_path},#{pid},#{session_id}").replace(",$", ","))
                subprocess.run([os.environ["TMUX_TEST_PROJECT"], str(root)], env=inside_env,
                               check=True, capture_output=True, text=True)
                self.assertEqual(tmux("display-message", "-p", "-t", target, "#{pane_id}"), pane)
                self.assertEqual(len(tmux("list-windows", "-t", target, "-F", "#{window_id}").splitlines()), 1)
            finally:
                subprocess.run([*command, "kill-server"], env=env, capture_output=True)
                if client:
                    client.wait(timeout=3)
                os.close(master)
                os.close(slave)

    def test_background_jobs_find_tmux_and_sleep_without_ambient_path(self):
        with tempfile.TemporaryDirectory(prefix="tmux-runtime-") as directory:
            root = Path(directory)
            env = dict(os.environ, PATH="/nonexistent", SHELL=os.environ["TMUX_TEST_SHELL"])
            for key in ("TMUX", "TMUX_PANE", "BASH_ENV", "ENV"):
                env.pop(key, None)
            command = [os.environ["TMUX_TEST_WRAPPER"], "-S", str(root / "socket"), "-f", "/dev/null"]

            def tmux(*args):
                return subprocess.check_output([*command, *args], env=env, text=True).strip()

            try:
                pane = tmux("new-session", "-d", "-s", "highlight", "-P", "-F", "#{pane_id}",
                            env["SHELL"], "--noprofile", "--norc")
                tmux("set-option", "-p", "-t", pane, "window-style", "bg=#313244")
                result = root / "reset-status"
                # Jobs run in the server environment, independently of the
                # client or popup that scheduled them.
                reset = f"sleep 0.5 && tmux set-option -p -u -t {shlex.quote(pane)} window-style"
                tmux("run-shell", reset + "; printf '%s' \"$?\" > " + shlex.quote(str(result)))
                self.assertEqual(result.read_text(), "0")
                self.assertEqual(tmux("display-message", "-p", "-t", pane, "#{window-style}"), "default")
            finally:
                subprocess.run([*command, "kill-server"], env=env, capture_output=True)


if __name__ == "__main__":
    unittest.main()
