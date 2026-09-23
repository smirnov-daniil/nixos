"""Evaluate profile contracts without entering a shell, fetching private inputs,
starting Claude, or contacting an AI service.
"""

import json
from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]


def evaluate(*profiles):
    command = ["devenv", "--no-tui"]
    for profile in profiles:
        command.extend(["--profile", profile])
    command.extend(["eval", "claude.code.enable", "claude.code.commands", "tasks.flake:test.after",
                    "claude.code.hooks.git-hooks-run.enable"])
    if "gru" in profiles:
        command.append("env.FLAKE_HOST")
    if "claude" in profiles:
        command.extend(["claude.code.permissions", "claude.code.mcpServers", "claude.code.hooks"])
    else:
        command.append("files")
    result = subprocess.run(command, cwd=ROOT, text=True, capture_output=True)
    if result.returncode:
        raise AssertionError(f"Profile evaluation failed: {result.stderr}")
    return json.loads(result.stdout)


class ProfileTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.base = evaluate()
        cls.claude = evaluate("claude", "gru")
        cls.ci = evaluate("ci")

    def test_claude_is_opt_in(self):
        for config in [self.base, self.ci]:
            self.assertFalse(config["claude.code.enable"])
            self.assertFalse(any(path.startswith(".claude/") for path in config["files"]))
        self.assertTrue(self.claude["claude.code.enable"])
        self.assertEqual(self.claude["env.FLAKE_HOST"], "gru")

    def test_profile_permissions_require_confirmation(self):
        permissions = self.claude["claude.code.permissions"]
        self.assertEqual(permissions["defaultMode"], "default")
        self.assertTrue(permissions["disableBypassPermissionsMode"])
        bash = permissions["rules"]["Bash"]
        self.assertFalse(bash["allow"])
        for rule in ["nh *", "deploy *", "nixos-rebuild *", "sudo *",
                     "ssh *", "*switch-to-configuration*", "sops *"]:
            self.assertIn(rule, bash["ask"])

    def test_profile_adds_no_mcp_connections_or_automatic_edit_hooks(self):
        self.assertEqual(self.claude["claude.code.mcpServers"], {})
        self.assertFalse(self.claude["claude.code.hooks.git-hooks-run.enable"])
        self.assertFalse(any(hook["enable"] for hook in self.claude["claude.code.hooks"].values()))

    def test_slash_commands_preserve_profile_and_jj_workflow(self):
        commands = self.claude["claude.code.commands"]
        check = commands["flake-check"]
        formatter = commands["flake-format"]
        self.assertIn("devenv --profile claude test", check)
        self.assertIn("flake-fmt --check", formatter)
        self.assertIn("jj diff", formatter)
        self.assertIn("described change", formatter)

    def test_ci_does_not_require_private_flake_evaluation(self):
        self.assertEqual(set(self.ci["tasks.flake:test.after"]),
                         {"flake:format-check", "flake:workflow-test"})
        self.assertIn("flake:eval", self.base["tasks.flake:test.after"])
        self.assertIn("flake:eval", self.claude["tasks.flake:test.after"])


if __name__ == "__main__":
    unittest.main()
