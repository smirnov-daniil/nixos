from contextlib import closing
import fcntl
import os
import pathlib
import pty
import re
import select
import signal
import sqlite3
import struct
import subprocess
import tempfile
import termios
import time
import unittest


class Fixture(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="histdb test '")
        self.addCleanup(self.temp.cleanup)
        self.root = pathlib.Path(self.temp.name)
        self.home = self.root / "home"
        self.cwd = self.home / "work's 100%"
        self.cwd.mkdir(parents=True)
        self.db = self.root / "history.sqlite"
        self.env = {"PATH": os.environ["PATH"], "TERM": "xterm-256color", "LANG": "C.UTF-8", "TZ": "UTC"}
        self.env.update(HOME=str(self.home), HISTDB_FILE=str(self.db), HISTFILE="", TMPDIR=str(self.root))
        for key in ("XDG_CONFIG_HOME", "XDG_CACHE_HOME", "XDG_DATA_HOME", "XDG_STATE_HOME", "XDG_RUNTIME_DIR"):
            directory = self.root / key.lower()
            directory.mkdir(mode=0o700)
            self.env[key] = str(directory)
        self.host = self.zsh('print -r -- "$HOST"').strip()
        self.zsh('source "$1"; _histdb_init; _histdb_stop_sqlite_pipe', os.environ["HISTDB_TEST_BACKEND"])
        self.sd = self.root / "state"
        self.sd.mkdir()
        state = dict(width=160, host=0, dir=0, hostname=self.host, pwd=self.cwd, home=self.home,
                     dbfile=self.db, sessmode=0, session="", sesshost="")
        for name, value in state.items():
            (self.sd / name).write_text(str(value))
        self.multiline = "printf 'first line\\n'\nprintf 'second line\\n'"
        rows = [("echo local", self.host, self.cwd, 7),
                ("echo remote", "remote.example", self.cwd, 7),
                ("echo sibling", self.host, str(self.cwd) + "/child", 7),
                ("echo wildcard", self.host, str(self.cwd).replace("100%", "100X"), 7),
                ("echo local", self.host, self.cwd, 7),
                (self.multiline, self.host, self.cwd, 8),
                ("echo companion", self.host, self.cwd, 7)]
        for argv, host, directory, session in rows:
            self.insert(argv, host, directory, session)

    def zsh(self, code, *args):
        result = subprocess.run(["zsh", "-f", "-c", code, "test", *map(str, args)],
                                env=self.env, cwd=self.cwd, capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout

    def insert(self, argv, host, directory, session):
        with closing(sqlite3.connect(self.db)) as db, db:
            db.execute("INSERT OR IGNORE INTO commands(argv) VALUES (?)", (argv,))
            db.execute("INSERT OR IGNORE INTO places(host, dir) VALUES (?, ?)", (host, str(directory)))
            db.execute("INSERT INTO history(session, command_id, place_id, exit_status, start_time, duration) "
                       "SELECT ?, commands.id, places.id, 23, 1700000000 + "
                       "(SELECT count(*) FROM history), 2 FROM commands, places "
                       "WHERE argv = ? AND host = ? AND dir = ?", (session, argv, host, str(directory)))

    def helper(self, name, *args):
        return self.zsh('source "$1"; shift; "$@"', os.environ["HISTDB_TEST_SCRIPT"], name, self.sd, *args)

    def ids(self):
        return [int(line.split("\t", 1)[0]) for line in self.helper("_fzf_histdb_gen").splitlines()]


class Helpers(Fixture):
    def test_latest_deduplicated_order(self):
        self.assertEqual(self.ids(), [7, 6, 5, 4, 3, 2])

    def test_host_and_exact_directory(self):
        self.helper("_fzf_histdb_toggle", "host")
        self.assertEqual(self.ids(), [7, 6, 5, 4, 3])
        self.helper("_fzf_histdb_toggle", "dir")
        self.assertEqual(self.ids(), [7, 6, 5])
        self.helper("_fzf_histdb_toggle", "host")
        self.assertEqual(self.ids(), [7, 6, 5, 2])
        self.helper("_fzf_histdb_toggle", "dir")
        self.assertEqual(self.ids(), [7, 6, 5, 4, 3, 2])

    def test_session_is_host_aware(self):
        self.helper("_fzf_histdb_toggle_session", 5)
        self.assertEqual(self.ids(), [7, 5, 4, 3])
        self.assertEqual((self.sd / "sesshost").read_text(), self.host)
        self.helper("_fzf_histdb_toggle_session", 5)
        self.assertEqual(self.ids(), [7, 6, 5, 4, 3, 2])
        self.helper("_fzf_histdb_toggle_session", 2)
        self.assertEqual(self.ids(), [2])

    def test_raw_multiline_and_preview(self):
        self.assertEqual(self.helper("_fzf_histdb_get", 6), self.multiline + "\n")
        detail = re.sub(r"\x1b\[[0-9;]*m", "", self.helper("_fzf_histdb_detail", 6))
        for expected in ("Host: " + self.host.split(".")[0], "Exit: 23", "Date: 14/11/2023",
                         "Dir: ~/work's 100%", self.multiline):
            self.assertIn(expected, detail)


class Terminal:
    def __init__(self, owner):
        import pyte
        self.owner = owner
        self.screen = pyte.Screen(160, 48)
        self.stream = pyte.ByteStream(self.screen)
        self.master, slave = pty.openpty()
        fcntl.ioctl(slave, termios.TIOCSWINSZ, struct.pack("HHHH", 48, 160, 0, 0))

        def session():
            os.setsid()
            fcntl.ioctl(slave, termios.TIOCSCTTY, 0)

        try:
            self.proc = subprocess.Popen([os.environ["ZSH_TEST_WRAPPER"], "-i"], env=owner.env,
                                         cwd=owner.cwd, stdin=slave, stdout=slave, stderr=slave,
                                         preexec_fn=session)
        except BaseException:
            os.close(self.master)
            raise
        finally:
            os.close(slave)
        owner.addCleanup(self.close)
        self.send("unset HISTFILE; HISTSIZE=0; SAVEHIST=0; "
                  "precmd_functions=(${precmd_functions:#_omp_precmd}); "
                  "_omp_cleanup_stream; _omp_serve_stop; zle -D zle-line-init; PROMPT='HISTDB> '; RPROMPT=''; "
                  "bindkey -e; print READY_HISTDB\n")
        self.wait(lambda text: "READY_HISTDB" in text and any(line.startswith("HISTDB> ") for line in text.splitlines()))

    def send(self, data):
        os.write(self.master, data.encode())

    def drain(self, timeout=0.1):
        if select.select([self.master], [], [], timeout)[0]:
            try:
                data = os.read(self.master, 65536)
            except OSError:
                data = b""
            if data:
                self.stream.feed(data)
        return "\n".join(self.screen.display)

    def wait(self, predicate, timeout=8):
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            text = self.drain()
            if predicate(text):
                return text
            if self.proc.poll() is not None:
                break
        self.owner.fail("Terminal did not reach expected state:\n" + "\n".join(self.screen.display))

    def prompt(self, command):
        return self.wait(lambda text: self.screen.display[self.screen.cursor.y].rstrip() == ("HISTDB> " + command).rstrip())

    def open(self, query="", key="\x12"):
        self.send(query + key)
        return self.wait(lambda text: "host:all" in text and "dir:all" in text)

    def close(self):
        try:
            os.killpg(self.proc.pid, signal.SIGHUP)
        except ProcessLookupError:
            pass
        try:
            self.proc.wait(timeout=3)
        except subprocess.TimeoutExpired:
            os.killpg(self.proc.pid, signal.SIGKILL)
            self.proc.wait(timeout=3)
        os.close(self.master)


class Interactive(Fixture):
    def test_insert_cancel_and_bindings(self):
        command = "printf chosen > selected-marker"
        self.insert(command, self.host, self.cwd, 9)
        terminal = Terminal(self)
        terminal.open("printf chosen")
        terminal.wait(lambda text: command in text and "Host:" in text and "Exit:" in text and "Date:" in text and "Dir:" in text)
        terminal.send("\r")
        terminal.prompt(command)
        marker = self.cwd / "selected-marker"
        self.assertFalse(marker.exists())
        terminal.send("\r")
        terminal.wait(lambda text: marker.exists())
        self.assertEqual(marker.read_text(), "chosen")
        terminal.prompt("")
        for key, cancel in (("\x12", "\x1b"), ("\x1br", "\x07")):
            terminal.send("\x01\x0b")
            terminal.open("printf", key)
            terminal.send(" chosen")
            terminal.wait(lambda text: "printf chosen" in text)
            terminal.send(cancel)
            terminal.prompt("printf chosen")
        terminal.send("\x01\x0bbindkey -v\n")
        terminal.open("printf chosen")
        terminal.send("\x07")
        terminal.prompt("printf chosen")

    def test_filters_reload_same_picker(self):
        terminal = Terminal(self)
        terminal.open("echo")
        text = terminal.wait(lambda text: all("echo " + name in text for name in ("local", "remote", "sibling", "wildcard", "companion")))
        for hint in ("alt-h", "alt-d", "alt-s", "alt-j"):
            self.assertIn(hint, text.lower())
        state_dirs = list(self.root.glob("fzf-histdb.*"))
        self.assertEqual(len(state_dirs), 1)
        terminal.send("\x1bh")
        terminal.wait(lambda text: "host:" + self.host.split(".")[0] in text and "echo remote" not in text)
        terminal.send("\x1bd")
        terminal.wait(lambda text: "dir:~" in text and "echo sibling" not in text and "echo wildcard" not in text)
        terminal.send("\x1bs")
        terminal.wait(lambda text: "session:7@" in text and "echo companion" in text)
        self.assertEqual(list(self.root.glob("fzf-histdb.*")), state_dirs)
        terminal.send("\x07")
        terminal.prompt("echo")

    def test_multiline_insertion_and_directory_jump(self):
        command = "printf 'first line\\n' > multiline-marker\nprintf 'second line\\n' >> multiline-marker"
        self.insert(command, self.host, self.cwd, 9)
        terminal = Terminal(self)
        terminal.send('_histdb_test_buffer() { print -rn -- "$BUFFER" > "$HOME/selected-buffer"; }; '
                      'zle -N _histdb_test_buffer; bindkey "^O" _histdb_test_buffer\n')
        terminal.prompt("")
        terminal.open("multiline-marker")
        terminal.wait(lambda text: "first line" in text and "second line" in text and "Host:" in text)
        terminal.send("\r")
        terminal.wait(lambda text: "Host:" not in text and "second line" in terminal.screen.display[terminal.screen.cursor.y])
        terminal.send("\x0f")
        captured = self.home / "selected-buffer"
        terminal.wait(lambda text: captured.exists())
        self.assertEqual(captured.read_text(), command)
        self.assertFalse((self.cwd / "multiline-marker").exists())
        terminal.send("\x03")
        terminal.prompt("")
        child = self.cwd / "child"
        child.mkdir()
        terminal.open("echo sibling")
        terminal.send("\x1bj")
        terminal.prompt("echo sibling")
        terminal.send('\x01\x0bprint -r -- "$PWD" > "$HOME/selected-dir"\n')
        selected_dir = self.home / "selected-dir"
        terminal.wait(lambda text: selected_dir.exists())
        self.assertEqual(selected_dir.read_text().strip(), str(child))

    def test_empty_history(self):
        terminal = Terminal(self)
        with closing(sqlite3.connect(self.db)) as db, db:
            db.execute("DELETE FROM history")
        terminal.open()
        terminal.send("\r")
        terminal.prompt("")
        self.assertIsNone(terminal.proc.poll())
        terminal.send("printf empty-ok > empty-marker\n")
        terminal.wait(lambda text: (self.cwd / "empty-marker").exists())
        self.assertEqual((self.cwd / "empty-marker").read_text(), "empty-ok")


if __name__ == "__main__":
    unittest.main()
