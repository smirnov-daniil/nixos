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
        self.shell = self.base / "shell with spaces"
        self.shell.write_text(
            f"#!{sys.executable}\n"
            "import json, os, sys\n"
            "print(json.dumps([sys.argv[1:], os.environ.get('FFT_TEST_IDENTITY'), os.getcwd()]))\n"
        )
        self.shell.chmod(0o755)
        self.env["SHELL"] = str(self.shell)
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

    def test_interactive_shell_uses_allowed_parent_environment(self):
        (self.root / ".envrc").write_text("export FFT_TEST_IDENTITY=work\n")
        (self.project / "devenv.nix").touch()
        (self.project / "flake.nix").touch()
        self.allow(self.root)
        result = self.run_command()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), [["-i"], "work", str(self.project)])

    def test_blocked_environment_does_not_fall_back_to_devshell(self):
        (self.root / ".envrc").write_text("export FFT_TEST_IDENTITY=work\n")
        (self.project / "devenv.nix").touch()
        (self.project / "flake.nix").touch()
        result = self.run_command()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")

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


class ShellFallbackTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="shell with spaces ")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for name in ("devenv", "nix", "shell with spaces"):
            executable = self.bin / name
            executable.write_text(
                f"#!{sys.executable}\n"
                "import json, os, sys\n"
                "print(json.dumps([os.path.basename(sys.argv[0]), sys.argv[1:], os.getcwd()]))\n"
                "raise SystemExit(int(os.environ.get('LAUNCHER_EXIT_STATUS', '0')))\n"
            )
            executable.chmod(0o755)
        self.shell = self.bin / "shell with spaces"
        self.env = dict(os.environ, PATH=f"{self.bin}:{os.environ['PATH']}", SHELL=str(self.shell))
        self.wrapper = ["bash", str(Path(__file__).with_name("exec.sh").resolve())]

    def run_command(self, *args):
        return subprocess.run(
            [*self.wrapper, *args], cwd=self.root, env=self.env,
            text=True, capture_output=True, check=False,
        )

    def test_devenv_takes_precedence_over_flake(self):
        (self.root / "devenv.nix").touch()
        (self.root / "flake.nix").touch()
        result = self.run_command()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), [
            "devenv", ["shell", "--", str(self.shell), "-i"], str(self.root),
        ])

    def test_flake_enters_nix_develop_with_interactive_user_shell(self):
        (self.root / "flake.nix").touch()
        result = self.run_command()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), [
            "nix", ["develop", "--command", str(self.shell), "-i"], str(self.root),
        ])

    def test_without_environment_starts_normal_interactive_shell(self):
        result = self.run_command()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), ["shell with spaces", ["-i"], str(self.root)])

    def test_direct_commands_do_not_enter_devshell(self):
        (self.root / "devenv.nix").touch()
        (self.root / "flake.nix").touch()
        argument = "space ; $(touch must-not-exist) ' quote"
        result = self.run_command(str(self.shell), argument)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), ["shell with spaces", [argument], str(self.root)])
        self.assertFalse((self.root / "must-not-exist").exists())

    def test_devshell_failure_does_not_fall_back_to_plain_shell(self):
        (self.root / "devenv.nix").touch()
        self.env["LAUNCHER_EXIT_STATUS"] = "23"
        result = self.run_command()
        self.assertEqual(result.returncode, 23, result.stderr)
        self.assertEqual(json.loads(result.stdout)[0], "devenv")


if __name__ == "__main__":
    unittest.main()
