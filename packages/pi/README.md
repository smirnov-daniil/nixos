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

Pi is supplied by the installed `environment` user profile package. For a new
release, update its Nix input, then upgrade the environment without activating
a system:

```sh
cd ~/flake
nix flake update pi
nix profile upgrade environment
exec ~/.nix-profile/bin/zsh
```

To build and check a candidate before updating the profile:

```sh
devenv shell flake-build pi
./.devenv/builds/pi/bin/pi --version
```

Building alone does not update the installed environment. Run the personal
configuration's compatibility checks against the candidate before upgrading.
Use `command -v pi` and `pi --version` in the new profile shell to verify the
selected runtime. Existing shells and Pi processes retain their old environment.
The migration's `~/.local/bin/pi` override was removed; do not recreate it.
Old roots under `~/.local/state/pi/` are rollback artifacts, not active launchers.
Avoid the historical wrapper that rewrites settings/roles and duplicates resource
arguments.

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
remain independent. Pi discovers the shared tuicr skill in `~/.agents/skills`
directly; the personal package does not keep a duplicate. Update the shared
installation explicitly when changing `packages/review/tuicr-review`.
