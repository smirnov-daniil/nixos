# Pi runtime

Nix supplies the Pi executable and command-line tools. Personal Pi resources
are maintained separately in the native local package at `~/pi-config`.
Its README documents setup, resource tests, updates and rollback.

- `default.nix` exports `pi-unwrapped`, `pi` and the `pi-runtime` smoke check.
- `skillopt-sleep/` still packages the independent SkillOpt-Sleep CLI.
- `packages.environment` includes Pi and SkillOpt-Sleep explicitly.
- The `pi` flake input pins the runtime; changing personal configuration needs
  no flake edit or Nix rebuild.

The wrapper adds `rg`, `fd`, `eza`, `jj`, Git, GitHub CLI, Node/npm, clang tools
and review tools to Pi's PATH. It has no startup hooks, resource arguments,
model defaults, role copying or settings merging. It respects Pi's native
`PI_CODING_AGENT_DIR` handling.

For a new Pi release, update its Nix input and build the runtime without
activating a system. Use this workflow for runtime update notifications:

```sh
nix flake update pi
devenv shell flake-build pi
```

The personal migration uses `~/.local/bin/pi` pointing through
`~/.local/state/pi/runtime`, a Nix GC root. To update that local runtime after
building (or after updating the `pi` input):

```sh
nix build --offline --out-link "$HOME/.local/state/pi/runtime" "$(readlink -f .devenv/builds/pi)"
```

Use `command -v pi` to check which runtime a shell starts. Avoid the old wrapper:
it rewrites settings/roles and also passes the same resources through CLI flags.
The user-local launcher takes precedence until the normal environment is updated.

Pi reads mutable settings, models, authentication, sessions and memory from
`~/.pi/agent`. The local package's one-time `scripts/setup.py` registers its path
and links rules/roles there while preserving personal files and saving backups.
Use Pi's settings UI or `pi config` to change resource selection; use `/reload`
or restart Pi after editing skills/extensions. New roles require rerunning setup.

The existing subagent and review integrations, including their jj patches and
tests, moved to `~/pi-config/vendor/`. Their source revisions and original patches
are recorded in that repository's `provenance/`. They are no longer flake inputs
or Nix build dependencies. The original sources remain in this flake's history.

`tuicr`, its shared agent-review skill, Herdr and repository-specific `.pi/` state
remain independent. The personal package holds a copy of the tuicr skill; update
that copy explicitly when changing `packages/review/tuicr-review`.
