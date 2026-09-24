"""Exercise real direnv activation for commands launched directly by tmux."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


class EnvironmentTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.root = self.base / "FFT with spaces"
        self.project = self.root / "nested repo"
        (self.project / ".git").mkdir(parents=True)
        self.env = dict(os.environ)
        for name in list(self.env):
            if name.startswith("DIRENV_"):
                del self.env[name]
        self.env.update(
            HOME=str(self.base / "home"),
            XDG_CONFIG_HOME=str(self.base / "config"),
            XDG_DATA_HOME=str(self.base / "data"),
            XDG_CACHE_HOME=str(self.base / "cache"),
        )
        self.wrapper = (
            [os.environ["TMUX_TEST_EXEC"]]
            if "TMUX_TEST_EXEC" in os.environ
            else ["bash", str(Path(__file__).with_name("exec.sh"))]
        )

    def run_command(self, *args):
        return subprocess.run(
            [*self.wrapper, *args], cwd=self.project, env=self.env,
            text=True, capture_output=True, check=False,
        )

    def allow(self, directory):
        subprocess.run(
            ["direnv", "allow", str(directory)], env=self.env,
            text=True, capture_output=True, check=True,
        )

    def test_parent_environment_crosses_nested_repository_and_preserves_arguments(self):
        (self.root / ".envrc").write_text("export FFT_TEST_IDENTITY=work\n")
        self.allow(self.root)
        argument = "space ; $(touch must-not-exist) ' quote"
        result = self.run_command(
            sys.executable, "-c",
            "import json, os, sys; print(json.dumps([os.environ['FFT_TEST_IDENTITY'], os.getcwd(), sys.argv[1]]))",
            argument,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), ["work", str(self.project), argument])
        self.assertFalse((self.project / "must-not-exist").exists())

    def test_blocked_environment_does_not_launch_command(self):
        (self.root / ".envrc").write_text("export FFT_TEST_IDENTITY=work\n")
        result = self.run_command(
            sys.executable, "-c", "from pathlib import Path; Path('executed').touch()",
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.project / "executed").exists())

    def test_no_environment_preserves_command_exit_status(self):
        result = self.run_command(sys.executable, "-c", "raise SystemExit(23)")
        self.assertEqual(result.returncode, 23, result.stderr)

    def test_nearest_environment_wins(self):
        (self.root / ".envrc").write_text("export FFT_TEST_IDENTITY=parent\n")
        (self.project / ".envrc").write_text("export FFT_TEST_IDENTITY=child\n")
        self.allow(self.project)
        result = self.run_command(
            sys.executable, "-c", "import os; print(os.environ['FFT_TEST_IDENTITY'])",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "child")

    def test_zsh_refreshes_completions_on_environment_entry_and_exit(self):
        package = self.base / "completion package"
        (package / "bin").mkdir(parents=True)
        completions = package / "share/zsh/site-functions"
        completions.mkdir(parents=True)
        (completions / "_fft_test_command").write_text("#compdef fft-test-command\n_files\n")
        hook = os.environ.get(
            "ZSH_COMPLETION_HOOK",
            str(Path(__file__).parent.parent / "zsh/project-environment.zsh"),
        )
        result = subprocess.run(
            ["zsh", "-f", "-c", '''
                set -e
                autoload -Uz compinit
                compinit -u
                source "$1"
                original_path=$PATH
                export PATH="$2/bin:$PATH"
                _flake_project_completions
                [[ ${_comps[fft-test-command]} == _fft_test_command ]]
                [[ ${fpath[(Ie)$2/share/zsh/site-functions]} -gt 0 ]]
                export PATH=$original_path
                _flake_project_completions
                [[ ${fpath[(Ie)$2/share/zsh/site-functions]} -eq 0 ]]
                [[ ${fpath[(Ie)$_flake_base_fpath[1]]} -gt 0 ]]
            ''', "completion-test", hook, str(package)],
            cwd=self.project, env=self.env, text=True, capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
