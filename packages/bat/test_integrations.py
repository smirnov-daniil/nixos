import errno
import fcntl
import os
from pathlib import Path
import pty
import re
import select
import signal
import struct
import subprocess
import tempfile
import termios
import time
import unittest


class BatIntegrations(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.env = dict(os.environ, TERM="xterm-256color", COLORTERM="truecolor", EDITOR="true")
        for key in ("NO_COLOR", "TMUX", "FZF_DEFAULT_OPTS", "FZF_DEFAULT_OPTS_FILE"):
            self.env.pop(key, None)

    def command(self, *args):
        return subprocess.run(
            args, cwd=self.root, env=self.env, text=True,
            capture_output=True, check=True, timeout=15,
        ).stdout

    def terminal(self, command, events=()):
        pid, fd = pty.fork()
        if pid == 0:
            os.chdir(self.root)
            os.execvpe(command[0], command, self.env)
        fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", 32, 120, 0, 0))
        output = b""
        pending = list(events)
        status = None
        deadline = time.monotonic() + 20
        try:
            while time.monotonic() < deadline:
                if select.select([fd], [], [], 0.1)[0]:
                    try:
                        data = os.read(fd, 65536)
                    except OSError as error:
                        if error.errno != errno.EIO:
                            raise
                        break
                    if not data:
                        break
                    output += data
                    while pending and pending[0][0] in output:
                        _, action = pending.pop(0)
                        if callable(action):
                            action()
                        else:
                            os.write(fd, action)
                ended, status = os.waitpid(pid, os.WNOHANG)
                if ended:
                    pid = None
                    break
            else:
                self.fail(f"Terminal timed out: {command!r}\n{output!r}")
            self.assertFalse(pending, output.decode(errors="replace"))
        finally:
            os.close(fd)
            if pid is not None:
                try:
                    os.killpg(pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                _, status = os.waitpid(pid, 0)
        return output

    def test_fd_batches_files_and_handles_search_options(self):
        (self.root / "space name.py").write_text('value = "first-file"\n')
        (self.root / "-leading.py").write_text('value = "second-file"\n')
        (self.root / "ignored.txt").write_text("not-a-python-file\n")
        output = self.command("batfd", "--extension", "py", "--", ".", ".")
        self.assertIn("first-file", output)
        self.assertIn("second-file", output)
        self.assertNotIn("not-a-python-file", output)
        self.assertNotIn("\x1b", output)
        self.assertEqual(self.command("batfd", "does-not-exist"), "")

    def test_search_uses_themed_bat(self):
        source = self.root / "source.py"
        source.write_text('value = "search-needle"\n')
        output = self.command("batgrep", "--color", "--paging=never", "search-needle", str(source))
        self.assertIn("search-needle", output)
        self.assertIn("\x1b[", output)

    def test_man_uses_pager_without_overstrike(self):
        manual = self.root / "example.1"
        manual.write_text(
            '.TH EXAMPLE 1\n.SH NAME\nexample \\- man-integration-marker\n'
            '.SH DESCRIPTION\n.B Highlighted manual text.\n'
        )
        for command in (["man", "-l", str(manual)], ["batman", "-l", str(manual)]):
            with self.subTest(command=command):
                output = self.terminal(command)
                self.assertIn(b"man-integration-marker", output)
                self.assertNotIn(b"\x08", output)
                self.assertRegex(output, rb"\x1b\[[0-9;]*m")

    def test_file_fzf_renders_preview(self):
        (self.root / "preview.py").write_text('value = "file-preview-marker"\n')
        output = self.terminal(
            [os.environ["BAT_TEST_FZF_FILES"], "--no-tmux", "--no-height"],
            [(b"file-preview-marker", b"\x03")],
        )
        self.assertIn(b"file-preview-marker", output)

    def test_shell_fzf_preserves_file_preview_options(self):
        (self.root / "preview.py").write_text('value = "shell-preview-marker"\n')
        self.env["FZF_DEFAULT_OPTS"] = (
            f"--preview '{os.environ['BAT_TEST_BAT']} --paging=never --color=always -- {{}}'"
        )
        output = self.terminal(
            [os.environ["BAT_TEST_FZF"], "--no-height"],
            [(b"shell-preview-marker", b"\x03")],
        )
        self.assertIn(b"shell-preview-marker", output)

    def test_tail_streams_new_lines_and_follows_rotation(self):
        log = self.root / "follow.log"
        log.write_text("INFO initial-tail-marker\n")

        def append_line():
            with log.open("a") as stream:
                stream.write("ERROR follow-tail-marker\n")

        def rotate_log():
            log.rename(self.root / "follow.log.1")
            log.write_text("WARNING rotated-tail-marker\n")

        output = self.terminal(
            ["battail", "-n", "1", "--", str(log)],
            [
                (b"initial-tail-marker", append_line),
                (b"follow-tail-marker", rotate_log),
                (b"rotated-tail-marker", b"\x03"),
            ],
        )
        self.assertIn(b"follow-tail-marker", output)
        self.assertIn(b"rotated-tail-marker", output)

    def test_watch_is_available(self):
        output = self.command("batwatch", "--help")
        self.assertIn("batwatch", re.sub(r"\x1b\[[0-9;]*m", "", output))


if __name__ == "__main__":
    unittest.main()
