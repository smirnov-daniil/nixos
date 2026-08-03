---
name: skillopt-sleep
description: Optimize a Pi skill from recurring past Pi sessions with SkillOpt-Sleep. Use when the user asks Pi to learn from prior sessions, run a sleep cycle, inspect learned proposals, or adopt validated cross-session guidance.
compatibility: Requires the flake-packaged skillopt-sleep and pi executables.
---

# SkillOpt-Sleep for Pi

Use SkillOpt-Sleep as an offline proposal layer. Keep `remember` for durable facts, `write_skill` for immediately reusable solved procedures, and `verify` or `/ship` for tool-enabled end-to-end validation.

## Safety Contract

- Every `harvest`, `dry-run`, and `run` command must include `--source pi` and an explicit `--target-skill-path`.
- Never pass `--auto-adopt` and never enable `auto_adopt` in config.
- Never evolve `CLAUDE.md`, `AGENTS.md`, memory files, or safety-critical skills such as `jujutsu`, `verify`, and `security-review`.
- Use `--scope invoked` unless the user explicitly authorizes cross-project harvesting.
- Treat `.skillopt-sleep/` as sensitive local state. Do not quote transcript contents or evidence in chat, logs, or commits.
- A real backend sends transcript-derived prompts to the configured provider. Prefer reviewed task files and inspect provider retention policy before using private sessions.
- SkillOpt's Pi backend disables tools. Its held-out gate evaluates textual guidance, not real repository operations. Require a tool-enabled verification after adoption.
- Do not use the built-in scheduler until the manual workflow has been validated and the user asks for scheduling.

## Target

When operating in this flake, use:

```bash
TARGET=packages/pi/skills/skillopt-learned/SKILL.md
```

For any other repository, ask the user to select a non-critical project skill. Refuse a missing target rather than falling back to a Claude skill path.

## Declarative Nix Boundary

Target source files under `$HOME/flake/packages/pi/skills/`, never generated files under `~/.pi`, a profile, or `/nix/store`. An adopted source skill becomes active only after `nix build .#pi .#environment` succeeds and the `environment` profile is updated.

SkillOpt may update one explicitly selected `SKILL.md`. It must not rewrite Nix modules, `packages/pi/default.nix`, models, agents, extensions, or context files. Change those through the normal reviewed Nix workflow when a learned proposal demonstrates that a configuration change is necessary.

## Workflow

Start with a local, provider-free harvest and mock dry-run:

```bash
umask 077
install -d -m 0700 .skillopt-sleep
chmod -R go-rwx .skillopt-sleep
skillopt-sleep harvest --project "$(pwd)" --scope invoked --source pi \
  --target-skill-path "$TARGET" --max-sessions 5 --max-tasks 3 \
  --output .skillopt-sleep/reviewed-tasks.json >/dev/null
skillopt-sleep dry-run --project "$(pwd)" --scope invoked --source pi \
  --target-skill-path "$TARGET" --backend mock \
  --max-sessions 5 --max-tasks 3 --json >.skillopt-sleep/mock-report.json
jq '{n_sessions, n_tasks, gate_action, accepted}' .skillopt-sleep/mock-report.json
```

Do not read transcript-derived task fields or mock proposals through Pi. Pause and ask the user to inspect and redact `.skillopt-sleep/reviewed-tasks.json` and `.skillopt-sleep/mock-report.json` outside the agent context. Continue only after the user sets the task file's top-level `reviewed` field to `true`. Then use the authenticated Pi backend without pinning a provider-specific model:

```bash
skillopt-sleep dry-run --project "$(pwd)" --source pi \
  --target-skill-path "$TARGET" --tasks-file .skillopt-sleep/reviewed-tasks.json \
  --backend pi --pi-path "$(command -v pi)" --max-tasks 3 --progress
skillopt-sleep run --project "$(pwd)" --source pi \
  --target-skill-path "$TARGET" --tasks-file .skillopt-sleep/reviewed-tasks.json \
  --backend pi --pi-path "$(command -v pi)" --max-tasks 3 --progress
```

`run` may only stage a proposal. Read the emitted `report.md`, `manifest.json`, and `proposed_SKILL.md`. Verify that the proposal has valid Agent Skills frontmatter, contains no secrets or project-specific private data, and does not weaken safety rules.

Summarize the baseline and candidate scores, gate decision, task count, and exact bounded edits without reproducing transcript excerpts. Ask for explicit approval before adoption.

After approval, use the exact staging directory printed by `run`:

```bash
STAGING=.skillopt-sleep/staging/<reviewed-run>
skillopt-sleep adopt --project "$(pwd)" \
  --target-skill-path "$TARGET" --staging "$STAGING"
```

Review the resulting Jujutsu diff, run the target skill's relevant checks, exercise a matching task with tools enabled, and run `nix build .#pi .#environment`. Update the `environment` profile only after those checks pass. If verification fails, restore the staged backup rather than hand-editing the proposal into a passing state.
