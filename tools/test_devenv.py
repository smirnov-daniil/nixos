"""Regression tests for source discovery, pins, and build-only commands."""

import json
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
HELPERS = ROOT / "tools/_sources.nix"
COMMAND = ROOT / "tools/flake-dev.sh"


class SourceFixture(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="flake-sources-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)

    def create(self, name, content="{}"):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        return path

    def evaluate(self, operation):
        expression = f"(import {HELPERS}).{operation} (builtins.toPath {json.dumps(str(self.root))})"
        result = subprocess.run(
            ["nix", "eval", "--impure", "--json", "--expr", expression],
            check=True, text=True, capture_output=True,
        )
        return json.loads(result.stdout)

    def relative_files(self, operation):
        return [str(Path(path).relative_to(self.root)) for path in self.evaluate(operation)]

    def test_module_discovery_excludes_helpers_and_devenv(self):
        for name in ["parts.nix", "hosts/new/default.nix", "_helper.nix", "flake.nix", "devenv.nix"]:
            self.create(name)
        self.assertEqual(self.relative_files("moduleFiles"), ["hosts/new/default.nix", "parts.nix"])

    def test_generated_hidden_and_symlinked_modules_are_not_imported(self):
        for name in [".devenv/bootstrap/default.nix", ".direnv/a.nix", ".hidden/a.nix",
                     "result-test/a.nix", "devenv.local.nix"]:
            self.create(name, "not valid Nix")
        (self.root / "cycle").symlink_to(self.root, target_is_directory=True)
        (self.root / "linked.nix").symlink_to(self.root / "devenv.local.nix")
        self.assertEqual(self.relative_files("moduleFiles"), [])

    def test_formatter_includes_helpers_and_devenv(self):
        for name in ["_helper.nix", "devenv.nix", "flake.nix", ".devenv/generated.nix"]:
            self.create(name)
        self.assertEqual(self.relative_files("nixFiles"), ["_helper.nix", "devenv.nix", "flake.nix"])

    def test_snapshot_includes_new_files_and_encrypted_secret_policies(self):
        self.create("hosts/new/configuration.nix")
        self.create("hosts/new/secrets/.sops.yaml", "encrypted fixture policy")
        snapshot = Path(self.evaluate("snapshot"))
        self.assertTrue((snapshot / "hosts/new/configuration.nix").is_file())
        self.assertTrue((snapshot / "hosts/new/secrets/.sops.yaml").is_file())

    def test_runtime_changes_do_not_change_snapshot(self):
        self.create("parts.nix")
        before = self.evaluate("snapshot")
        for name in [".devenv/state.db", ".jj/state", ".git/config", ".direnv/cache",
                     ".env", ".env.local", "devenv.local.nix", "devenv.local.yaml", "result/a"]:
            self.create(name, "local data")
        with socket.socket(socket.AF_UNIX) as runtime_socket:
            runtime_socket.bind(str(self.root / ".devenv/runtime.sock"))
            self.assertEqual(self.evaluate("snapshot"), before)
        self.create("parts.nix", "{ changed = true; }")
        self.assertNotEqual(self.evaluate("snapshot"), before)

    def test_claude_generated_files_are_excluded_but_handwritten_commands_remain(self):
        self.create(".claude/commands/review.md", "handwritten instructions")
        before = self.evaluate("snapshot")
        for name in [".claude/settings.json", ".claude/settings.local.json",
                     ".claude/commands/flake-check.md", ".claude/commands/flake-format.md"]:
            self.create(name, "generated settings or local permissions")
        self.assertEqual(self.evaluate("snapshot"), before)
        self.assertTrue((Path(before) / ".claude/commands/review.md").is_file())


class PinTests(unittest.TestCase):
    def test_shell_and_flake_use_the_same_nixpkgs(self):
        def locked_input(filename, name):
            lock = json.loads((ROOT / filename).read_text())
            node = lock["nodes"][lock["root"]]["inputs"][name]
            return lock["nodes"][node]["locked"]

        flake = locked_input("flake.lock", "nixpkgs")
        shell = locked_input("devenv.lock", "nixpkgs")
        self.assertEqual(flake, shell, "Update devenv.yaml's nixpkgs revision, then run devenv update nixpkgs")
        self.assertIn(f"github:NixOS/nixpkgs/{flake['rev']}", (ROOT / "devenv.yaml").read_text())


class CommandTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="flake-commands-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        mock = self.root / "nix"
        mock.write_text(
            "#!/usr/bin/env python3\n"
            "import json, os, sys\n"
            "with open(os.environ['NIX_TEST_LOG'], 'a') as log:\n"
            "    log.write(json.dumps(sys.argv[1:]) + '\\n')\n"
            "if sys.argv[1] == 'eval': print('/nix/store/fixture-source')\n"
            "sys.exit(int(os.environ.get('NIX_TEST_EXIT', '0')))\n"
        )
        mock.chmod(0o755)
        self.log = self.root / "calls.jsonl"
        self.env = dict(os.environ, DEVENV_ROOT=str(self.root), FLAKE_HOST="",
                        FLAKE_SKINEM_SOURCE="", PATH=f"{self.root}:{os.environ['PATH']}",
                        NIX_TEST_LOG=str(self.log))

    def run_command(self, *arguments, **environment):
        return subprocess.run(["bash", str(COMMAND), *arguments], text=True,
                              capture_output=True, env=self.env | environment)

    def calls(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def test_eval_does_not_build_or_update_lock(self):
        self.assertEqual(self.run_command("eval").returncode, 0)
        self.assertEqual(self.calls()[-1], ["flake", "check", "path:/nix/store/fixture-source",
                                          "--no-write-lock-file", "--show-trace", "--no-build"])

    def test_full_check_builds_checks_without_activation(self):
        self.assertEqual(self.run_command("check").returncode, 0)
        self.assertEqual(self.calls()[-1][:2], ["flake", "check"])
        self.assertNotIn("--no-build", self.calls()[-1])

    def test_package_build_has_a_separate_ignored_result(self):
        self.assertEqual(self.run_command("build", "environment").returncode, 0)
        self.assertEqual(self.calls()[-1], ["build", "path:/nix/store/fixture-source#environment",
                                          "--no-write-lock-file", "--show-trace", "--out-link",
                                          f"{self.root}/.devenv/builds/environment"])

    def test_host_argument_overrides_profile_without_switching(self):
        self.assertEqual(self.run_command("host", "gru", FLAKE_HOST="aku").returncode, 0)
        self.assertEqual(self.calls()[-1][0], "build")
        self.assertIn("#nixosConfigurations.gru.config.system.build.toplevel", self.calls()[-1][1])

    def test_host_profile_is_used_when_no_argument_is_given(self):
        self.assertEqual(self.run_command("host", FLAKE_HOST="tai-lung").returncode, 0)
        self.assertIn("#nixosConfigurations.tai-lung.", self.calls()[-1][1])

    def test_invalid_arguments_fail_before_calling_nix(self):
        for arguments in [("build",), ("build", "--impure"), ("build", "a", "b"),
                          ("host",), ("host", "unknown"), ("host", "gru", "aku"), ("switch",)]:
            with self.subTest(arguments=arguments):
                self.assertEqual(self.run_command(*arguments).returncode, 2)
                self.assertFalse(self.log.exists())

    def test_nix_failure_is_propagated(self):
        self.assertEqual(self.run_command("eval", NIX_TEST_EXIT="42").returncode, 42)

    def test_ci_uses_the_supplied_private_checkout_without_updating_the_lock(self):
        upstream = self.root / "private source"
        upstream.mkdir()
        (upstream / "flake.nix").write_text("{}")
        for arguments in [("eval",), ("check",), ("build", "environment"), ("host", "gru")]:
            with self.subTest(arguments=arguments):
                self.assertEqual(self.run_command(*arguments, FLAKE_SKINEM_SOURCE=str(upstream)).returncode, 0)
                call = self.calls()[-1]
                position = call.index("--override-input")
                self.assertEqual(call[position:position + 3], ["--override-input", "skinem", f"path:{upstream}"])
                self.assertIn("--no-write-lock-file", call)

    def test_invalid_private_checkout_fails_before_calling_nix(self):
        for source in ["relative/path", str(self.root / "missing")]:
            with self.subTest(source=source):
                self.assertEqual(self.run_command("eval", FLAKE_SKINEM_SOURCE=source).returncode, 2)
                self.assertFalse(self.log.exists())


if __name__ == "__main__":
    unittest.main()
