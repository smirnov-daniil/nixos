import json
import os

import pytest

import skillopt_sleep.config as config
from skillopt_sleep.__main__ import main
from skillopt_sleep.staging import adopt as adopt_staging


def invoke(arguments):
    current_umask = os.umask(0)
    os.umask(current_umask)
    try:
        return main(arguments)
    finally:
        os.umask(current_umask)


def test_pi_safety_overrides(monkeypatch, tmp_path):
    monkeypatch.setattr(config, "_user_config_path", lambda: None)
    cfg = config.load_config(
        invoked_project=str(tmp_path),
        target_skill_path="skills/learned/SKILL.md",
        evolve_memory=True,
        auto_adopt=True,
    )
    assert cfg.evolve_memory is False
    assert cfg.auto_adopt is False
    assert cfg.managed_skill_path() == str(tmp_path / "skills/learned/SKILL.md")


def test_missing_target_is_rejected(monkeypatch, capsys):
    monkeypatch.setattr(config, "_user_config_path", lambda: None)
    assert invoke(["run", "--source", "pi", "--backend", "mock"]) == 2
    assert "explicit --target-skill-path is required" in capsys.readouterr().err


def test_task_metadata_cannot_select_target(monkeypatch, tmp_path, capsys):
    monkeypatch.setattr(config, "_user_config_path", lambda: None)
    tasks = tmp_path / "tasks.json"
    tasks.write_text(json.dumps({
        "format": "skillopt_sleep.tasks.v1",
        "reviewed": True,
        "target_skill_path": str(tmp_path / "unexpected" / "SKILL.md"),
        "tasks": [],
    }))
    assert invoke(["run", "--source", "pi", "--backend", "mock", "--tasks-file", str(tasks)]) == 2
    assert "explicit --target-skill-path is required" in capsys.readouterr().err


def test_implicit_target_is_rejected(monkeypatch):
    monkeypatch.setattr(config, "_user_config_path", lambda: None)
    with pytest.raises(ValueError, match="target_skill_path is required"):
        config.load_config().managed_skill_path()


def test_harvest_artifacts_are_private(monkeypatch, tmp_path, capsys):
    monkeypatch.setattr(config, "_user_config_path", lambda: None)
    project = tmp_path / "project"
    target = project / "skills" / "learned" / "SKILL.md"
    target.parent.mkdir(parents=True)
    target.write_text("---\nname: learned\ndescription: learned\n---\n")
    output = project / ".skillopt-sleep" / "tasks.json"
    pi_home = tmp_path / "pi-home"
    sessions = pi_home / "agent" / "sessions" / "project"
    sessions.mkdir(parents=True)
    records = [
        {"type": "session", "version": 1, "id": "private", "cwd": str(project)},
        {"type": "message", "message": {"role": "user", "content": "PRIVATE_HISTORY_SENTINEL"}},
        {"type": "message", "message": {"role": "assistant", "content": "completed"}},
    ]
    (sessions / "private.jsonl").write_text("".join(json.dumps(record) + "\n" for record in records))
    assert invoke([
        "harvest",
        "--project", str(project),
        "--source", "pi",
        "--pi-home", str(pi_home),
        "--target-skill-path", str(target),
        "--output", str(output),
        "--json",
    ]) == 0
    captured = capsys.readouterr()
    summary = json.loads(captured.out)
    assert "tasks" not in summary
    assert "PRIVATE_HISTORY_SENTINEL" not in captured.out
    assert "PRIVATE_HISTORY_SENTINEL" not in captured.err
    assert "PRIVATE_HISTORY_SENTINEL" in output.read_text()
    assert output.stat().st_mode & 0o077 == 0
    assert output.parent.stat().st_mode & 0o077 == 0


def test_memory_proposal_cannot_be_adopted(monkeypatch, tmp_path, capsys):
    monkeypatch.setattr(config, "_user_config_path", lambda: None)
    project = tmp_path / "project"
    target = project / "skills" / "learned" / "SKILL.md"
    memory = project / "CLAUDE.md"
    staging = project / ".skillopt-sleep" / "staging" / "old"
    target.parent.mkdir(parents=True)
    staging.mkdir(parents=True)
    target.write_text("original skill")
    memory.write_text("original memory")
    (staging / "proposed_CLAUDE.md").write_text("replaced memory")
    (staging / "manifest.json").write_text(json.dumps({
        "live_skill_path": str(target),
        "live_memory_path": str(memory),
        "has_skill": False,
        "has_memory": True,
        "accepted": True,
    }))
    arguments = [
        "adopt",
        "--project", str(project),
        "--target-skill-path", str(target),
        "--staging", str(staging),
    ]
    assert invoke(arguments) == 2
    assert "refusing a memory-bearing proposal" in capsys.readouterr().err
    assert memory.read_text() == "original memory"
    with pytest.raises(ValueError, match="memory proposals are disabled"):
        adopt_staging(str(staging))


def test_staged_target_must_match_explicit_target(monkeypatch, tmp_path, capsys):
    monkeypatch.setattr(config, "_user_config_path", lambda: None)
    project = tmp_path / "project"
    expected = project / "expected" / "SKILL.md"
    unexpected = project / "unexpected" / "SKILL.md"
    staging = project / ".skillopt-sleep" / "staging" / "mismatch"
    expected.parent.mkdir(parents=True)
    unexpected.parent.mkdir(parents=True)
    staging.mkdir(parents=True)
    expected.write_text("expected")
    unexpected.write_text("unexpected")
    (staging / "manifest.json").write_text(json.dumps({
        "live_skill_path": str(unexpected),
        "live_memory_path": str(project / "CLAUDE.md"),
        "has_skill": False,
        "has_memory": False,
        "accepted": True,
    }))
    assert invoke([
        "adopt",
        "--project", str(project),
        "--target-skill-path", str(expected),
        "--staging", str(staging),
    ]) == 2
    assert "staged target does not match" in capsys.readouterr().err
    assert unexpected.read_text() == "unexpected"


@pytest.mark.parametrize("arguments", [["run", "--auto-adopt"], ["schedule"], ["unschedule"]])
def test_unsafe_commands_are_unavailable(arguments):
    with pytest.raises(SystemExit) as error:
        invoke(arguments)
    assert error.value.code == 2
