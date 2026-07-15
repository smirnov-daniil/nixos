---
name: run
description: Launch and drive this project's app to confirm a change works in practice (CLI, server, TUI, or web app). Use when asked to run, start, or demo the app.
---

# Run

1. Detect the project type (check for package.json scripts, a Makefile, flake.nix apps, Cargo.toml, etc.) and how it's normally launched.
2. Start it, following its actual entrypoint — don't assume a generic command.
3. Drive the golden path relevant to the current task.
4. Report what you observed (output, errors, behavior), not just that it "started."
5. Stop/clean up any process you started before finishing, unless asked to leave it running.
