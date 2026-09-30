import fcntl
import os
from pathlib import Path
import pty
import select
import shlex
import shutil
import struct
import subprocess
import tempfile
import termios
import time
import unittest


@unittest.skipUnless(os.environ.get("KAK_TEST_WRAPPER"), "requires packaged Kakoune")
class EditorRuntimeTests(unittest.TestCase):
    wayland = False

    def setUp(self):
        import pyte

        self.directory = tempfile.TemporaryDirectory(prefix="kak-runtime-")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.env = dict(os.environ, HOME=str(self.root), TERM="xterm-256color",
                        SHELL=os.environ["KAK_TEST_SHELL"],
                        XDG_CONFIG_HOME=str(self.root / "config"),
                        XDG_CACHE_HOME=str(self.root / "cache"),
                        XDG_RUNTIME_DIR=str(self.root / "runtime"),
                        TMPDIR=str(self.root / "tmp"))
        for name in ("runtime", "tmp", "path ' quoted"):
            (self.root / name).mkdir(mode=0o700)
        for key in ("TMUX", "TMUX_PANE", "WAYLAND_DISPLAY", "BASH_ENV", "ENV",
                    "KAKOUNE_CONFIG_DIR", "HERDR_ENV"):
            self.env.pop(key, None)
        self.env["PATH"] = str(self.root / "path ' quoted") + ":" + os.environ["KAK_TEST_POPUP_PATH"]
        self.env["FZF_DEFAULT_COMMAND"] = "invalid-inherited-fzf-command"
        self.kak = os.environ["KAK_TEST_WRAPPER"]
        self.session = self.root.name
        self.tmux_command = [shutil.which("tmux"), "-u", "-S", str(self.root / "socket"),
                             "-f", "/dev/null"]
        self.xclip = shutil.which("xclip")
        self.assertNotEqual(subprocess.run([self.env["SHELL"], "-c", "command -v fd"],
                                          env=self.env, capture_output=True).returncode, 0)
        self.fixture = self.root / "original.txt"
        self.original = "выделение\nsecond line\n"
        self.fixture.write_text(self.original)
        self.master, self.slave = pty.openpty()
        fcntl.ioctl(self.slave, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 100, 0, 0))
        self.client = self.server = self.compositor = None
        self.addCleanup(self.stop)

        class Screen(pyte.Screen):
            def report_device_status(self, *args, **kwargs):
                pass

        self.screen = Screen(100, 30)
        self.stream = pyte.ByteStream(self.screen)
        if self.wayland:
            self.env.pop("DISPLAY", None)
            config = self.root / "sway.conf"
            config.write_text("output * resolution 100x100\nseat seat0 fallback true\n")
            compositor_env = dict(self.env, WLR_BACKENDS="headless", WLR_RENDERER="pixman",
                                  WLR_HEADLESS_OUTPUTS="1", WLR_LIBINPUT_NO_DEVICES="1")
            compositor_env.pop("SWAYSOCK", None)
            log = (self.root / "compositor.log").open("w")
            self.addCleanup(log.close)
            self.compositor = subprocess.Popen([os.environ["KAK_TEST_SWAY"], "--config", str(config)],
                                               env=compositor_env, stdout=log, stderr=log)
            self.wait_for(lambda: any(path.is_socket() for path in
                                     (self.root / "runtime").glob("wayland-*")))
            self.env["WAYLAND_DISPLAY"] = next(path.name for path in
                (self.root / "runtime").glob("wayland-*") if path.is_socket())
        self.tmux("new-session", "-d", "-s", "editor", "-c", str(self.root), "sleep 60")
        server_env = dict(self.env)
        server_env.pop("DISPLAY", None)
        server_env.pop("WAYLAND_DISPLAY", None)
        server_env["TMUX"] = self.tmux("display-message", "-p", "#{socket_path},#{pid},0")
        self.server = subprocess.Popen([self.kak, "-d", "-s", self.session], env=server_env,
                                       cwd=self.root, stdout=subprocess.DEVNULL,
                                       stderr=subprocess.DEVNULL)
        self.wait_for(lambda: self.session in subprocess.check_output(
            [self.kak, "-l"], env=self.env, text=True, timeout=3).splitlines())
        command = shlex.join([self.kak, "-c", self.session, str(self.fixture)])
        self.tmux("respawn-pane", "-k", "-t", "editor", "-c", str(self.root), command)
        self.tmux("set", "-g", "status", "off")
        self.client = subprocess.Popen([*self.tmux_command, "attach", "-t", "editor"],
                                       stdin=self.slave, stdout=self.slave, stderr=self.slave,
                                       env=self.env)
        self.wait_for(lambda: any("second line" in row for row in self.screen.display))

    def tmux(self, *args):
        return subprocess.check_output([*self.tmux_command, *args], env=self.env, text=True).strip()

    def kak_command(self, command):
        subprocess.run([self.kak, "-p", self.session], input=command, env=self.env,
                       text=True, capture_output=True, check=True, timeout=3)

    def send(self, keys):
        os.write(self.master, keys.encode())

    def drain(self):
        deadline = time.monotonic() + 0.03
        while time.monotonic() < deadline:
            if select.select([self.master], [], [], 0.01)[0]:
                self.stream.feed(os.read(self.master, 65536))

    def wait_for(self, predicate):
        deadline = time.monotonic() + 8
        while time.monotonic() < deadline:
            self.drain()
            if predicate():
                return
        details = "\n".join(self.screen.display)
        if self.compositor:
            details += "\n" + (self.root / "compositor.log").read_text()
        self.fail("Timed out waiting for Kakoune:\n" + details)

    def stop(self):
        subprocess.run([*self.tmux_command, "kill-server"], env=self.env, capture_output=True)
        if self.client:
            try:
                self.client.wait(timeout=3)
            except subprocess.TimeoutExpired:
                self.client.kill()
                self.client.wait(timeout=3)
        if self.server:
            subprocess.run([self.kak, "-p", self.session], input="kill!", env=self.env,
                           text=True, capture_output=True, timeout=3)
            try:
                self.server.wait(timeout=3)
            except subprocess.TimeoutExpired:
                self.server.kill()
                self.server.wait(timeout=3)
        if self.compositor:
            self.compositor.terminate()
            try:
                self.compositor.wait(timeout=3)
            except subprocess.TimeoutExpired:
                self.compositor.kill()
                self.compositor.wait(timeout=3)
        os.close(self.master)
        os.close(self.slave)

    def clipboard(self):
        command = ([shutil.which("wl-paste"), "--no-newline"] if self.wayland else
                   [self.xclip, "-selection", "clipboard", "-out"])
        result = subprocess.run(command,
                                env=self.env, text=True, capture_output=True, timeout=3)
        return result.stdout if result.returncode == 0 else None

    def test_system_clipboard_keys(self):
        self.send("% y")
        self.wait_for(lambda: self.clipboard() == self.original)
        replacement = "вставка\nclipboard second line\n"
        command = ([shutil.which("wl-copy")] if self.wayland else
                   [self.xclip, "-selection", "clipboard", "-in"])
        subprocess.run(command, input=replacement, stderr=subprocess.DEVNULL,
                       env=self.env, text=True, check=True, timeout=3)
        for key, expected in (("R", replacement), ("p", replacement + self.original),
                              ("P", self.original + replacement)):
            with self.subTest(key=key):
                source = self.root / f"paste-{key}.txt"
                source.write_text(self.original)
                output = self.root / f"result-{key}.txt"
                self.kak_command(f"evaluate-commands -client client0 %{{edit '{source}'}}")
                self.wait_for(lambda: any(source.name in row for row in self.screen.display))
                self.send("% " + key)
                self.wait_for(lambda: any("clipboard second line" in row for row in self.screen.display))
                self.send(":write! " + str(output))
                self.send("\r")
                self.wait_for(output.exists)
                self.assertEqual(output.read_text(), expected)

    def test_file_picker_preserves_editor_path(self):
        target = self.root / "selected file.txt"
        target.write_text("PICKED_FILE_CONTENT\n")
        self.kak_command("set-option global fzf_use_main_selection false")
        self.send("  ")
        self.wait_for(lambda: any(" > " in row for row in self.screen.display))
        self.send("selected file")
        self.wait_for(lambda: any(target.name in row for row in self.screen.display))
        self.send("\r")
        observed = self.root / "opened"

        def selected():
            self.kak_command(f"evaluate-commands -client client0 %{{echo -to-file '{observed}' %val{{buffile}}}}")
            return observed.exists() and observed.read_text().strip() == str(target)

        self.wait_for(selected)
        self.wait_for(lambda: any("PICKED_FILE_CONTENT" in row for row in self.screen.display))


class WaylandEditorRuntimeTests(EditorRuntimeTests):
    wayland = True


if __name__ == "__main__":
    unittest.main()
