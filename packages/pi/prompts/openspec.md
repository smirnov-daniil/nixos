---
description: Bootstrap or use OpenSpec spec-driven workflow in this project
---
Check whether this project already has OpenSpec set up (an `openspec/` directory with `specs/`, `changes/`, `config.yaml`).

- If NOT set up: run `openspec init --tools pi` (non-interactive) to scaffold it. This generates pi-native skills and `/opsx-*` commands for the propose/explore/apply/sync/archive workflow — no need to hand-roll them.
- If already set up: use the generated `/opsx-*` commands (run `openspec instructions --json` if unsure which step comes next) rather than editing spec/change files freehand.

Task: $@
