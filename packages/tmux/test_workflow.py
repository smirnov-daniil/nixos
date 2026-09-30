import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import yaml

from project import main, session_name
from repo import project_root, repositories


class ProjectTests(unittest.TestCase):
    def test_new_session_starts_only_one_project_shell(self):
        with tempfile.TemporaryDirectory(prefix="project with spaces ") as tmp:
            root = Path(tmp).resolve()
            name = session_name(root)
            with patch("sys.argv", ["mux", str(root)]), \
                    patch.dict("os.environ", {"TMUX": ""}), \
                    patch("project.shutil.which", return_value="/store/mux-exec"), \
                    patch("project.subprocess.run") as run, \
                    patch("project.os.execvp", side_effect=SystemExit(0)) as execute:
                run.side_effect = [subprocess.CompletedProcess([], 1), subprocess.CompletedProcess([], 0)]
                with self.assertRaises(SystemExit):
                    main()
                self.assertEqual(run.call_count, 2)
                self.assertEqual(run.call_args_list[1].args[0], [
                    "tmux", "new-session", "-d", "-s", name, "-c", str(root),
                    "-n", "shell", "/store/mux-exec",
                ])
                execute.assert_called_once_with("tmux", ["tmux", "attach-session", "-t", "=" + name])

    def test_existing_session_is_reused_without_changing_windows(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            with patch("sys.argv", ["mux", str(root)]), \
                    patch.dict("os.environ", {"TMUX": "/tmp/test-socket,1,0"}), \
                    patch("project.shutil.which") as which, \
                    patch("project.subprocess.run", return_value=subprocess.CompletedProcess([], 0)) as run, \
                    patch("project.os.execvp", side_effect=SystemExit(0)) as execute:
                with self.assertRaises(SystemExit):
                    main()
                self.assertEqual(run.call_count, 1)
                which.assert_not_called()
                execute.assert_called_once_with("tmux", [
                    "tmux", "switch-client", "-t", "=" + session_name(root),
                ])

    def test_nested_module_stays_in_umbrella_space(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / ".ff").mkdir()
            (root / ".ff/repo.yml").write_text("nodes: {}\n")
            module = root / "contrib/common/contrib/core"
            (module / ".jj").mkdir(parents=True)
            source = module / "example.cpp"
            source.touch()
            self.assertEqual(project_root(source), root)

    def test_manifest_uses_real_paths_and_deduplicates_shared_modules(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "project with spaces"
            (root / ".ff").mkdir(parents=True)
            module = root / "contrib/common/contrib/core"
            (module / ".jj").mkdir(parents=True)
            (root / "shared").symlink_to(module, target_is_directory=True)
            outside = Path(tmp) / "outside"
            (outside / ".jj").mkdir(parents=True)
            (root / ".ff/repo.yml").write_text(yaml.safe_dump({
                "nodes": {
                    "project": {"path": "."},
                    "core": {"path": "contrib/common/contrib/core"},
                    "shared": {"path": "shared"},
                    "empty": {"path": "contrib/empty"},
                    "outside": {"path": "../outside"},
                }
            }))
            self.assertEqual(repositories(root), [
                (". (root)", root),
                ("contrib/common/contrib/core", module),
            ])

    def test_plain_git_worktree_and_same_named_projects(self):
        with tempfile.TemporaryDirectory() as tmp:
            roots = [Path(tmp) / owner / "same.name" for owner in ["one", "two"]]
            for root in roots:
                (root / "src").mkdir(parents=True)
                (root / ".git").write_text("gitdir: /some/other/path\n")
                self.assertEqual(project_root(root / "src"), root)
                self.assertEqual(repositories(root), [(". (root)", root)])
                self.assertNotIn(".", session_name(root))
                self.assertNotIn(":", session_name(root))
            self.assertNotEqual(session_name(roots[0]), session_name(roots[1]))


if __name__ == "__main__":
    unittest.main()
