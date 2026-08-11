# Pi package

This directory contains the repository-owned Pi coding-agent integration and its Pi-specific support packages.

## Layout

- `default.nix`: assembles the `pi` package and its checks.
- `agents/`: managed subagent roles installed into the Pi agent directory.
- `extensions/`: repository extensions and extension tests.
- `models.json`: additional model definitions.
- `patches/`: patches for Pi integrations such as pi-review.
- `prompts/`: packaged Pi prompt templates.
- `skills/`: packaged Pi skills.
- `pi-subagents/`: patched and tested `pi-subagents` package.
- `skillopt-sleep/`: Pi-safe SkillOpt-Sleep package and tests.

These nested `default.nix` files are discovered automatically as flake-parts modules. They continue to export the top-level package names `pi`, `pi-subagents`, and `skillopt-sleep`.

The following stay outside this directory because they are repository-wide or independently useful:

- Pi-related flake inputs and their locks in `flake.nix` and `flake.lock`.
- Package selection in `packages/environment.nix`.
- Standalone `tuicr` and Herdr packages.
- Project runtime state and repository-specific skills in `.pi/`.
- Graphify's repository graph in `graphify-out/`.
