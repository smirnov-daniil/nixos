import json
import os
from pathlib import Path
import subprocess
import shutil
import tempfile
import unittest
from unittest.mock import patch

import reviewctl as review
from setup import install


class ReviewTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.env = patch.dict(os.environ, {
            "REVIEWCTL_HOME": str(self.root / "state"),
            "HOME": str(self.root), "GIT_CONFIG_GLOBAL": os.devnull,
            "JJ_CONFIG": str(self.root / "jj.toml"),
        })
        self.env.start()
        (self.root / "jj.toml").write_text('[user]\nname="Test"\nemail="test@example.com"\n')
        self.repo = self.root / "repo with spaces"
        self.repo.mkdir()
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.name", "Test")
        self.git("config", "user.email", "test@example.com")
        (self.repo / "example.cpp").write_text("before\n")
        self.git("add", ".")
        self.git("commit", "-qm", "base")
        (self.repo / "example.cpp").write_text("after\n")

    def tearDown(self):
        self.env.stop()
        self.temp.cleanup()

    def git(self, *args):
        return review.run(["git", *args], self.repo)

    def test_snapshot_tracks_untracked_and_staged_and_detects_edits(self):
        self.git("add", ".")
        extra = self.repo / "untracked file.cpp"
        extra.write_text("new\n")
        ticket = review.prepare(self.repo)
        self.assertEqual(review.prepare(self.repo / "."), ticket)
        diff = (review.ticket_dir(ticket) / "diff.patch").read_text()
        self.assertIn("+after", diff)
        self.assertIn("+new", diff)
        review.assert_current(ticket)
        extra.write_text("changed\n")
        with self.assertRaisesRegex(review.ReviewError, "stale"):
            review.assert_current(ticket)
        self.assertNotEqual(review.prepare(self.repo), ticket)

    def test_jj_working_change_and_branch_have_real_diff(self):
        review.run(["jj", "git", "init", "--colocate"], self.repo)
        ticket = review.prepare(self.repo)
        self.assertEqual(review.load(ticket)["selection"]["vcs"], "jj")
        self.assertIn("+after", (review.ticket_dir(ticket) / "diff.patch").read_text())
        review.assert_current(ticket)
        branch = review.prepare(self.repo, "branch")
        self.assertIn("+after", (review.ticket_dir(branch) / "diff.patch").read_text())

    def test_explicit_jj_range_includes_working_change_like_tuicr(self):
        review.run(["jj", "git", "init", "--colocate"], self.repo)
        review.run(["jj", "new", "-m", "working"], self.repo)
        (self.repo / "example.cpp").write_text("working change after selected commit\n")
        ticket = review.prepare(self.repo, revset="@-")
        self.assertIn("+working change after selected commit", (review.ticket_dir(ticket) / "diff.patch").read_text())

    def test_git_submodule_boundary_wins_over_parent_jj(self):
        (self.repo / ".jj").mkdir()
        module = self.repo / "sub/module"
        module.mkdir(parents=True)
        (module / ".git").write_text("gitdir: ../../.git/modules/module\n")
        self.assertEqual(review.repo_root(module), (module, "git"))

    def test_git_branch_reviews_committed_changes_from_merge_base(self):
        self.git("switch", "-qc", "task")
        self.git("commit", "-qam", "task")
        ticket = review.prepare(self.repo, "branch")
        self.assertIn("+after", (review.ticket_dir(ticket) / "diff.patch").read_text())

    def comment(self, identifier="human", author="user", content="fix the overflow"):
        return {"id": identifier, "author": author, "content": content, "location": "example.cpp:1",
                "comment_type": "issue", "lifecycle_state": "local_draft"}

    def agent(self, status="idle"):
        return {"id": "agent-1", "status": status, "tmuxPane": "%9", "cwd": str(self.repo)}

    def test_delivery_excludes_ai_and_deduplicates_per_recipient_and_content(self):
        ticket = review.prepare(self.repo)
        comments = [self.comment(), self.comment("ai", "Codex AI Reviewer")]
        sent = []
        def daemon(path, payload=None):
            if payload:
                sent.append(payload)
                return {"ok": True}
            return {"session": self.agent()}
        with patch.object(review, "comments", return_value=comments), patch.object(review, "daemon", side_effect=daemon):
            review.send([ticket], "agent-1", enter=False)
            self.assertFalse(sent[0]["enter"])
            self.assertIn("[human]", sent[0]["text"])
            self.assertNotIn("[ai]", sent[0]["text"])
            with self.assertRaisesRegex(review.ReviewError, "No undelivered"):
                review.send([ticket], "agent-1")
            review.send([ticket], "agent-1", ids=["ai"])
            self.assertIn("[ai]", sent[1]["text"])
            comments[0]["content"] = "edited finding"
            review.send([ticket], "agent-1")
            self.assertIn("edited finding", sent[2]["text"])

    def test_busy_agent_and_stale_diff_never_receive_messages(self):
        ticket = review.prepare(self.repo)
        daemon = lambda path, payload=None: {"session": self.agent("working")}
        with patch.object(review, "comments", return_value=[self.comment()]), patch.object(review, "daemon", side_effect=daemon) as api:
            with self.assertRaisesRegex(review.ReviewError, "busy"):
                review.send([ticket], "agent-1")
            self.assertEqual(api.call_count, 1)
            (self.repo / "example.cpp").write_text("another change\n")
            api.reset_mock()
            with self.assertRaisesRegex(review.ReviewError, "stale"):
                review.send([ticket], "agent-1")
            api.assert_not_called()

    def test_failed_send_does_not_mark_comments_delivered(self):
        ticket = review.prepare(self.repo)
        with patch.object(review, "comments", return_value=[self.comment()]), patch.object(review, "recipient"), patch.object(review, "daemon", side_effect=OSError("offline")):
            with self.assertRaises(OSError):
                review.send([ticket], "agent-1")
            self.assertEqual(len(review.pending(ticket, "agent-1")), 1)

    def test_pi_ack_tracks_the_exported_content_only(self):
        ticket = review.prepare(self.repo)
        comment = self.comment()
        key = review.comment_key(comment)
        with patch.object(review, "comments", return_value=[comment]):
            review.acknowledge(ticket, "pi:session-1", [key])
            self.assertEqual(review.pending(ticket, "pi:session-1"), [])
            comment["content"] = "edited after paste"
            with self.assertRaisesRegex(review.ReviewError, "changed since export"):
                review.acknowledge(ticket, "pi:session-2", [key])
            self.assertEqual(len(review.pending(ticket, "pi:session-1")), 1)

    def test_umbrella_reviews_form_one_message(self):
        (self.root / ".ff").mkdir()
        (self.root / ".ff/repo.yml").write_text("nodes: {}\n")
        second = self.root / "nested/another module"
        shutil.copytree(self.repo, second)
        tickets = [review.prepare(self.repo), review.prepare(second)]
        sent = []
        def daemon(path, payload=None):
            if payload:
                sent.append(payload)
                return {"ok": True}
            return {"session": {**self.agent(), "cwd": str(self.root)}}
        with patch.object(review, "comments", return_value=[self.comment()]), patch.object(review, "daemon", side_effect=daemon):
            review.send(tickets, "agent-1")
        self.assertEqual(len(sent), 1)
        for repo in [self.repo, second]:
            self.assertIn(str(repo), sent[0]["text"])

    def test_exact_session_required_and_outside_session_rejected(self):
        ticket = review.prepare(self.repo)
        with patch.object(review, "sessions", return_value=[{"path": "/tmp/a"}, {"path": "/tmp/b"}]):
            with self.assertRaisesRegex(review.ReviewError, "one session"):
                review.session_path(ticket)
        with patch.object(review, "sessions", return_value=[{"path": "/tmp/a"}]):
            with self.assertRaisesRegex(review.ReviewError, "outside"):
                review.session_path(ticket)

    def test_session_repository_and_scope_checked(self):
        ticket = review.prepare(self.repo)
        path = review.ticket_dir(ticket) / "data/session.json"
        path.parent.mkdir()
        review.save(path, {"repo_path": str(self.repo), "diff_source": "working_tree"})
        with patch.object(review, "sessions", return_value=[{"path": str(path)}]):
            self.assertEqual(review.session_path(ticket), path)
            review.save(path, {"repo_path": str(self.repo), "diff_source": "commit_range"})
            with self.assertRaisesRegex(review.ReviewError, "selection changed"):
                review.session_path(ticket)

    def test_agent_in_another_project_is_rejected(self):
        ticket = review.prepare(self.repo)
        agent = {**self.agent(), "cwd": str(self.root)}
        with patch.object(review, "daemon", return_value={"session": agent}):
            with self.assertRaisesRegex(review.ReviewError, "another project"):
                review.recipient("agent-1", [review.load(ticket)])

    def test_skill_setup_preserves_personal_directory(self):
        destination = self.root / "skills/tuicr-review"
        destination.mkdir(parents=True)
        with self.assertRaisesRegex(RuntimeError, "Personal skill"):
            install(Path("/nix/store/test/share/agent-skills/tuicr-review"), [destination])


if __name__ == "__main__":
    unittest.main()
