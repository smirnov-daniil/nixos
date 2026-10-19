import json
import os
import plistlib
import re
import subprocess
import tempfile
import unittest
from pathlib import Path


class BatThemeTests(unittest.TestCase):
    def setUp(self):
        self.home = tempfile.TemporaryDirectory()
        self.addCleanup(self.home.cleanup)
        self.env = {
            key: value
            for key, value in os.environ.items()
            if not key.startswith("BAT_")
            and key not in {"NO_COLOR", "CLICOLOR", "CLICOLOR_FORCE", "COLORTERM"}
        }
        self.env.update(
            HOME=self.home.name,
            XDG_CONFIG_HOME=self.home.name,
            XDG_CACHE_HOME=self.home.name,
            TERM="xterm-256color",
            COLORTERM="truecolor",
            BAT_PAGER="/pager-must-not-run-for-pipes",
        )
        self.bat = os.environ["BAT_TEST_WRAPPER"]
        self.upstream = os.environ["BAT_TEST_UPSTREAM"]
        self.palette = json.loads(Path(os.environ["BAT_TEST_PALETTE"]).read_text())

    def run_bat(self, *args, text="", executable=None):
        result = subprocess.run(
            [executable or self.bat, "--no-config", *args],
            input=text.encode(),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=self.env,
            check=True,
        )
        self.assertEqual(result.stderr, b"")
        return result.stdout

    def test_builtin_assets_retained(self):
        themes = self.run_bat("--list-themes").decode().splitlines()
        builtins = self.run_bat("--list-themes", executable=self.upstream).decode().splitlines()
        self.assertIn("flake", themes)
        self.assertTrue(set(builtins).issubset(themes))
        self.assertEqual(
            self.run_bat("--list-languages", "--color=never"),
            self.run_bat("--list-languages", "--color=never", executable=self.upstream),
        )

    def test_palette_and_scopes(self):
        theme = plistlib.loads(Path(os.environ["BAT_TEST_THEME"]).read_bytes())
        settings = theme["settings"]
        self.assertEqual(settings[0]["settings"]["foreground"], self.palette["base05"])
        self.assertEqual(settings[0]["settings"]["background"], self.palette["base00"])
        self.assertEqual(settings[0]["settings"]["selection"], self.palette["base02"])
        scopes = {
            scope.strip(): rule["settings"]["foreground"]
            for rule in settings[1:]
            for scope in rule["scope"].split(",")
        }
        for scope, color in {
            "comment": "base03",
            "string": "base0B",
            "constant.numeric": "base09",
            "constant.language": "base09",
            "keyword": "base0E",
            "entity.name.function": "base0D",
            "entity.name.type": "base0A",
            "invalid": "base08",
            "markup.error": "base08",
            "markup.warning": "base0A",
            "markup.info": "base0B",
            "markup.heading": "base0D",
            "entity.name.command-line-option": "base0C",
            "markup.inserted": "base0B",
            "markup.deleted": "base08",
            "markup.changed": "base0A",
            "meta.diff.header": "base0C",
        }.items():
            with self.subTest(scope=scope):
                self.assertEqual(scopes[scope], self.palette[color])

    def test_truecolor_rendering(self):
        source = '# comment\ndef example():\n    return "hello", 42\n'
        rendered = self.run_bat(
            "--language=python", "--color=always", "--style=plain", text=source
        )
        for key in ["base03", "base0B", "base09", "base0E", "base0D"]:
            rgb = bytes.fromhex(self.palette[key].removeprefix("#"))
            sequence = b"38;2;" + b";".join(str(value).encode() for value in rgb)
            with self.subTest(color=key):
                self.assertIn(sequence, rendered)
        self.assertEqual(re.sub(rb"\x1b\[[0-9;]*m", b"", rendered), source.encode())
        diff = self.run_bat(
            "--language=diff",
            "--color=always",
            "--style=plain",
            text="--- a/file\n+++ b/file\n@@ -1 +1 @@\n-old\n+new\n",
        )
        for key in ["base08", "base0B", "base0C"]:
            rgb = bytes.fromhex(self.palette[key].removeprefix("#"))
            self.assertIn(b"38;2;" + b";".join(str(value).encode() for value in rgb), diff)

    def test_man_and_log_rendering(self):
        manual = self.run_bat(
            "--language=man", "--color=always", "--style=plain",
            text="NAME\n       example - manual\nOPTIONS\n       --help\n",
        )
        log = self.run_bat(
            "--language=log", "--color=always", "--style=plain",
            text="ERROR failed\nWARNING caution\nINFO ready\n",
        )
        for rendered, keys in [(manual, ["base0D", "base0C"]), (log, ["base08", "base0A", "base0B"])]:
            for key in keys:
                with self.subTest(color=key):
                    rgb = bytes.fromhex(self.palette[key].removeprefix("#"))
                    self.assertIn(b"38;2;" + b";".join(str(value).encode() for value in rgb), rendered)

    def test_non_tty_output_is_clean(self):
        source = 'def example():\n    return "hello", 42\n'
        self.assertEqual(self.run_bat("--language=python", text=source), source.encode())


if __name__ == "__main__":
    unittest.main(verbosity=2)
