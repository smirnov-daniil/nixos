import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


class EnvironmentTestCase(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.root = self.base / "FFT with spaces"
        self.project = self.root / "nested repo"
        (self.project / ".git").mkdir(parents=True)
        (self.project / ".jj").mkdir()
        self.env = dict(os.environ)
        for name in list(self.env):
            if name.startswith("DEVENV_") or name == "IN_NIX_SHELL":
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
            "print(json.dumps([sys.argv[1:], os.environ.get('DEVENV_ROOT'), os.getcwd()]))\n"
        )
        self.shell.chmod(0o755)
        self.env["SHELL"] = str(self.shell)
        self.wrapper = (
            [os.environ["TMUX_TEST_EXEC"]]
            if "TMUX_TEST_EXEC" in os.environ
            else ["bash", str(Path(__file__).with_name("exec.sh"))]
        )
        self.devenv = shutil.which("devenv")
        self.assertIsNotNone(self.devenv, "real devenv required for trust-resolution tests")

    def run_command(self, *args):
        return subprocess.run(
            [*self.wrapper, *args], cwd=self.project, env=self.env,
            text=True, capture_output=True, check=False,
        )

    def allow(self, directory):
        subprocess.run(
            [self.devenv, "allow"], cwd=directory, env=self.env,
            text=True, capture_output=True, check=True,
        )

    def resolve(self):
        return subprocess.run(
            [self.devenv, "hook-should-activate"], cwd=self.project, env=self.env,
            text=True, capture_output=True, check=False,
        )


class TrustResolutionTests(EnvironmentTestCase):
    def test_real_parent_lookup_crosses_nested_repositories_and_defers_interactive_entry(self):
        (self.root / "devenv.nix").write_text("{}\n")
        (self.project / "flake.nix").touch()
        self.allow(self.root)
        resolution = self.resolve()
        self.assertEqual(resolution.returncode, 0, resolution.stderr)
        self.assertEqual(resolution.stdout.strip(), str(self.root))
        result = self.run_command()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), [["-i"], None, str(self.project)])

    def test_real_untrusted_environment_does_not_launch_command(self):
        (self.root / "devenv.nix").write_text("{}\n")
        resolution = self.resolve()
        self.assertNotEqual(resolution.returncode, 0)
        result = self.run_command(
            sys.executable, "-c", "from pathlib import Path; Path('executed').touch()",
        )
        self.assertEqual(result.returncode, resolution.returncode, result.stderr)
        self.assertFalse((self.project / "executed").exists())

    def test_real_untrusted_environment_does_not_fall_back_to_flake_or_shell(self):
        (self.project / "devenv.nix").write_text("{}\n")
        (self.project / "flake.nix").touch()
        resolution = self.resolve()
        self.assertNotEqual(resolution.returncode, 0)
        result = self.run_command()
        self.assertEqual(result.returncode, resolution.returncode, result.stderr)
        self.assertEqual(result.stdout, "")

    def test_real_nearest_environment_wins_over_untrusted_parent(self):
        (self.root / "devenv.nix").write_text("{}\n")
        (self.project / "devenv.nix").write_text("{}\n")
        self.allow(self.project)
        result = self.resolve()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), str(self.project))
        self.env["DEVENV_ROOT"] = str(self.project)
        command = self.run_command(sys.executable, "-c", "raise SystemExit(23)")
        self.assertEqual(command.returncode, 23, command.stderr)

    def test_real_untrusted_nearest_project_does_not_use_trusted_parent(self):
        (self.root / "devenv.nix").write_text("{}\n")
        (self.project / "devenv.nix").write_text("{}\n")
        self.allow(self.root)
        self.env["DEVENV_ROOT"] = str(self.project)
        resolution = self.resolve()
        self.assertNotEqual(resolution.returncode, 0)
        result = self.run_command(str(self.shell))
        self.assertEqual(result.returncode, resolution.returncode, result.stderr)
        self.assertEqual(result.stdout, "")

    def test_real_no_environment_preserves_command_exit_status(self):
        resolution = self.resolve()
        self.assertEqual(resolution.returncode, 0, resolution.stderr)
        self.assertEqual(resolution.stdout, "")
        result = self.run_command(sys.executable, "-c", "raise SystemExit(23)")
        self.assertEqual(result.returncode, 23, result.stderr)

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


class MockedCommandLaunchTests(EnvironmentTestCase):
    def setUp(self):
        super().setUp()
        self.bin = self.base / "bin"
        self.bin.mkdir()
        self.launch_log = self.base / "launch.json"
        launcher = self.bin / "devenv"
        launcher.write_text(
            f"#!{sys.executable}\n"
            "import json, os, pathlib, sys\n"
            "if sys.argv[1:] == ['hook-should-activate']:\n"
            f"    os.execv({self.devenv!r}, [{self.devenv!r}, *sys.argv[1:]])\n"
            f"pathlib.Path({str(self.launch_log)!r}).write_text(json.dumps([sys.argv[1:], os.getcwd()]))\n"
            "if sys.argv[1:4] != ['--no-tui', 'shell', '--']:\n"
            "    raise SystemExit(99)\n"
            "os.environ['DEVENV_ROOT'] = os.getcwd()\n"
            "os.environ['FFT_TEST_IDENTITY'] = 'mock-environment'\n"
            "os.execvp(sys.argv[4], sys.argv[4:])\n"
        )
        launcher.chmod(0o755)
        self.env["PATH"] = f"{self.bin}:{self.env['PATH']}"
        self.wrapper = ["bash", str(Path(__file__).with_name("exec.sh").resolve())]
        (self.root / "devenv.nix").write_text("{}\n")
        self.allow(self.root)

    def test_mocked_shell_launch_preserves_cwd_quoted_arguments_and_status(self):
        arguments = ["space ; $(touch must-not-exist) ' quote", "", "line\nbreak", "*", "--flag"]
        probe = (
            "import json, os, sys; "
            "print(json.dumps([os.environ['FFT_TEST_IDENTITY'], os.environ['DEVENV_ROOT'], os.getcwd(), sys.argv[1:]])); "
            "raise SystemExit(23)"
        )
        result = self.run_command(sys.executable, "-c", probe, *arguments)
        self.assertEqual(result.returncode, 23, result.stderr)
        self.assertEqual(json.loads(result.stdout), [
            "mock-environment", str(self.root), str(self.project), arguments,
        ])
        self.assertEqual(json.loads(self.launch_log.read_text()), [
            ["--no-tui", "shell", "--", "bash", "-c",
             'cd -- "$1" || exit "$?"; shift; exec "$@"', "mux-exec", str(self.project),
             sys.executable, "-c", probe, *arguments], str(self.root),
        ])
        self.assertFalse((self.project / "must-not-exist").exists())

    def test_mocked_shell_launch_uses_nearest_trusted_root(self):
        (self.project / "devenv.nix").write_text("{}\n")
        self.allow(self.project)
        result = self.run_command(str(self.shell))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), [[], str(self.project), str(self.project)])
        self.assertEqual(json.loads(self.launch_log.read_text())[1], str(self.project))

    def test_matching_active_environment_executes_directly_without_duplicate_entry(self):
        self.env["DEVENV_ROOT"] = str(self.root)
        result = self.run_command(str(self.shell), "quoted ' argument")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), [["quoted ' argument"], str(self.root), str(self.project)])
        self.assertFalse(self.launch_log.exists())

    def test_different_active_environment_enters_resolved_project(self):
        self.env["DEVENV_ROOT"] = str(self.base / "different environment")
        result = self.run_command(str(self.shell))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), [[], str(self.root), str(self.project)])
        self.assertTrue(self.launch_log.exists())

    def test_interactive_shell_never_uses_mocked_devenv_shell(self):
        (self.project / "flake.nix").touch()
        result = self.run_command()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), [["-i"], None, str(self.project)])
        self.assertFalse(self.launch_log.exists())


class ShellFallbackTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="shell with spaces ")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        for name in ("devenv", "nix", "bash", "shell with spaces"):
            executable = self.bin / name
            executable.write_text(
                f"#!{sys.executable}\n"
                "import json, os, sys\n"
                "if os.path.basename(sys.argv[0]) == 'devenv' and sys.argv[1:] == ['hook-should-activate']:\n"
                "    print(os.environ.get('HOOK_PROJECT_ROOT', ''), end='')\n"
                "    raise SystemExit(int(os.environ.get('HOOK_EXIT_STATUS', '0')))\n"
                "print(json.dumps([os.path.basename(sys.argv[0]), sys.argv[1:], os.getcwd()]))\n"
                "raise SystemExit(int(os.environ.get('LAUNCHER_EXIT_STATUS', '0')))\n"
            )
            executable.chmod(0o755)
        self.shell = self.bin / "shell with spaces"
        self.env = dict(os.environ, PATH=f"{self.bin}:{os.environ['PATH']}", SHELL=str(self.shell))
        self.env.pop("DEVENV_ROOT", None)
        self.wrapper = [shutil.which("bash"), str(Path(__file__).with_name("exec.sh").resolve())]

    def run_command(self, *args):
        return subprocess.run(
            [*self.wrapper, *args], cwd=self.root, env=self.env,
            text=True, capture_output=True, check=False,
        )

    def test_devenv_defers_interactive_entry_to_native_hook_instead_of_flake(self):
        (self.root / "devenv.nix").touch()
        (self.root / "flake.nix").touch()
        self.env["HOOK_PROJECT_ROOT"] = str(self.root)
        result = self.run_command()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), ["shell with spaces", ["-i"], str(self.root)])

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

    def test_empty_shell_falls_back_to_interactive_bash(self):
        self.env["SHELL"] = ""
        result = self.run_command()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), ["bash", ["-i"], str(self.root)])

    def test_direct_commands_do_not_enter_flake_devshell(self):
        (self.root / "flake.nix").touch()
        argument = "space ; $(touch must-not-exist) ' quote"
        result = self.run_command(str(self.shell), argument)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), ["shell with spaces", [argument], str(self.root)])
        self.assertFalse((self.root / "must-not-exist").exists())

    def test_flake_devshell_failure_does_not_fall_back_to_plain_shell(self):
        (self.root / "flake.nix").touch()
        self.env["LAUNCHER_EXIT_STATUS"] = "23"
        result = self.run_command()
        self.assertEqual(result.returncode, 23, result.stderr)
        self.assertEqual(json.loads(result.stdout)[0], "nix")

    def test_devenv_shell_failure_preserves_status_without_fallback(self):
        (self.root / "devenv.nix").touch()
        self.env["HOOK_PROJECT_ROOT"] = str(self.root)
        self.env["LAUNCHER_EXIT_STATUS"] = "23"
        result = self.run_command(str(self.shell))
        self.assertEqual(result.returncode, 23, result.stderr)
        self.assertEqual(json.loads(result.stdout)[0], "devenv")

    def test_project_cd_failure_does_not_launch_command(self):
        self.env["HOOK_PROJECT_ROOT"] = str(self.root / "missing project")
        result = self.run_command(str(self.shell))
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")

    def test_hook_failure_status_propagates_without_launch(self):
        self.env["HOOK_EXIT_STATUS"] = "37"
        for args in ((), (str(self.shell),)):
            with self.subTest(args=args):
                result = self.run_command(*args)
                self.assertEqual(result.returncode, 37, result.stderr)
                self.assertEqual(result.stdout, "")


if __name__ == "__main__":
    unittest.main()
