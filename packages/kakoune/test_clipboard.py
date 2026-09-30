import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


class ClipboardTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="kak-clipboard-")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.log = self.root / "log"
        self.clipboard = self.root / "clipboard"
        self.environment_log = self.root / "environment"
        self.env = dict(os.environ, PATH=str(self.root), TEST_LOG=str(self.log),
                        TEST_ENV_LOG=str(self.environment_log),
                        TEST_CLIPBOARD=str(self.clipboard))
        for key in ("WAYLAND_DISPLAY", "DISPLAY", "BASH_ENV", "ENV"):
            self.env.pop(key, None)
        for name in ("wl-copy", "wl-paste", "xclip"):
            tool = self.root / name
            tool.write_text(
                f"#!{shutil.which('python3')}\n"
                "import json, os, sys\n"
                "from pathlib import Path\n"
                "Path(os.environ['TEST_LOG']).write_text(json.dumps(sys.argv))\n"
                "Path(os.environ['TEST_ENV_LOG']).write_text(json.dumps({name: os.environ.get(name)\n"
                "    for name in ('WAYLAND_DISPLAY', 'DISPLAY', 'XDG_RUNTIME_DIR')}))\n"
                "clipboard = Path(os.environ['TEST_CLIPBOARD'])\n"
                "if sys.argv[0].endswith('wl-copy') or '-in' in sys.argv:\n"
                "    clipboard.write_bytes(sys.stdin.buffer.read())\n"
                "else:\n"
                "    sys.stdout.buffer.write(clipboard.read_bytes())\n"
            )
            tool.chmod(0o755)
        self.command = [shutil.which("bash"), "-euo", "pipefail",
                        str(Path(__file__).with_name("clipboard.sh"))]

    def run_clipboard(self, action, content="", client_env=()):
        return subprocess.run([*self.command, action, *client_env], env=self.env, input=content,
                              capture_output=True, text=True)

    def test_wayland_copy_and_paste(self):
        self.env["WAYLAND_DISPLAY"] = "wayland-test"
        self.env["DISPLAY"] = ":42"
        content = "выделение\nsecond line\n"
        self.assertEqual(self.run_clipboard("copy", content).returncode, 0)
        self.assertEqual(self.clipboard.read_text(), content)
        self.assertEqual(json.loads(self.log.read_text()), [str(self.root / "wl-copy")])
        result = self.run_clipboard("paste")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, content)
        self.assertEqual(json.loads(self.log.read_text()),
                         [str(self.root / "wl-paste"), "--no-newline"])

    def test_x11_copy_and_paste(self):
        self.env["DISPLAY"] = ":42"
        self.env["WAYLAND_DISPLAY"] = ""
        content = "выделение\nsecond line\n"
        self.assertEqual(self.run_clipboard("copy", content).returncode, 0)
        self.assertEqual(self.clipboard.read_text(), content)
        self.assertEqual(json.loads(self.log.read_text()),
                         [str(self.root / "xclip"), "-selection", "clipboard", "-in"])
        result = self.run_clipboard("paste")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, content)
        self.assertEqual(json.loads(self.log.read_text()),
                         [str(self.root / "xclip"), "-selection", "clipboard", "-out"])

    def test_wayland_client_environment_is_forwarded(self):
        self.env["DISPLAY"] = ":server"
        self.env["XDG_RUNTIME_DIR"] = "/server/runtime"
        client_env = ("wayland-1", ":client", "/client/runtime ' quoted")
        result = self.run_clipboard("copy", "selection", client_env)
        self.assertEqual(result.returncode, 0)
        self.assertEqual(json.loads(self.log.read_text()), [str(self.root / "wl-copy")])
        self.assertEqual(json.loads(self.environment_log.read_text()), {
            "WAYLAND_DISPLAY": "wayland-1", "DISPLAY": ":client",
            "XDG_RUNTIME_DIR": "/client/runtime ' quoted",
        })
        self.assertEqual(self.run_clipboard("paste", client_env=client_env).stdout, "selection")

    def test_x11_client_overrides_stale_wayland_server(self):
        self.env["WAYLAND_DISPLAY"] = "stale-wayland"
        result = self.run_clipboard("copy", "selection", ("", ":client", "/client/runtime"))
        self.assertEqual(result.returncode, 0)
        self.assertEqual(json.loads(self.log.read_text()),
                         [str(self.root / "xclip"), "-selection", "clipboard", "-in"])

    def test_client_without_display_does_not_use_server_display(self):
        self.env["WAYLAND_DISPLAY"] = "stale-wayland"
        result = self.run_clipboard("copy", "selection", ("", "", "/client/runtime"))
        self.assertEqual(result.returncode, 1)
        self.assertFalse(self.log.exists())

    def test_incomplete_client_environment_is_rejected(self):
        self.assertEqual(self.run_clipboard("copy", client_env=("wayland-1",)).returncode, 2)
        self.assertFalse(self.log.exists())

    def test_missing_display_is_reported(self):
        result = self.run_clipboard("copy", "selection")
        self.assertEqual(result.returncode, 1)
        self.assertIn("no Wayland or X11 display", result.stderr)
        self.assertFalse(self.log.exists())

    def test_invalid_action_is_reported(self):
        result = self.run_clipboard("invalid")
        self.assertEqual(result.returncode, 2)
        self.assertIn("Usage:", result.stderr)
        self.assertFalse(self.log.exists())

    def test_backend_failure_is_not_hidden(self):
        self.env["WAYLAND_DISPLAY"] = "wayland-test"
        (self.root / "wl-copy").write_text(f"#!{shutil.which('bash')}\nexit 7\n")
        self.assertEqual(self.run_clipboard("copy", "selection").returncode, 7)


if __name__ == "__main__":
    unittest.main()
