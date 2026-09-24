import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import unittest


@unittest.skipUnless(os.environ.get("TMUX_TEST_WRAPPER"), "requires the built tmux wrapper")
class RuntimeTests(unittest.TestCase):
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
