# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Workflow and safety

- Use Jujutsu (`jj`), not Git, for history mutations. Inspect `jj status`, `jj log -r '@ | @-'`, and `jj diff` before editing. Create or reuse a logically scoped, described change before modifying files; preserve unrelated user work.
- Prefer the commands below from the pinned devenv shell. With the Claude profile active, preserve it in nested invocations (`devenv --profile claude test`) so devenv does not remove the generated Claude configuration mid-session.
- Never activate a system, deploy, restart services, publish changes, or decrypt secrets without explicit user approval for that action and target. A build or test request does not authorize `nh os switch`, `nixos-rebuild`, `deploy`, `switch-to-configuration`, or remote SSH execution.
- Do not read plaintext credentials, `.env*`, SSH private keys, or SOPS age identities. Authentication is managed by the user outside Nix expressions and generated settings.
- Do not bypass permission prompts, enable automatic approval, or add blanket Bash permissions. Project rules are safeguards, not an OS sandbox.
- Run expensive full checks or host builds only when requested or clearly needed; do not attach them to editing hooks. `/flake-check` evaluates without building systems; `/flake-format` formats and reviews the diff.
- `.claude/settings.json` and the two `flake-*` command files are generated from `tools/_claude.nix`; edit that source, not the generated files. Preserve `.claude/settings.local.json` and user-level Claude settings.

## Commands

```bash
devenv shell                     # pinned tools; no activation or secret decryption
devenv test                      # format + workflow tests + flake evaluation (no check builds)
devenv --profile full test       # also build all checks (expensive)
devenv shell flake-build environment # build one package
devenv --profile gru tasks run flake:host # build a host, never activate
devenv tasks run flake:format     # format source Nix files, excluding generated state
statix check .                   # lint Nix files
nh os switch                     # apply config on a NixOS host (no sudo needed; nh is wrapped with NH_FLAKE=$HOME/flake)
nix flake update                 # update all inputs
```

Commit messages follow conventional-commit style, e.g. `fix(omp): jujutsu`, `feat(omp): jj ui instead of git`.

## Architecture

### Auto-import: every .nix file is a flake-parts module

`flake.nix` uses `tools/_sources.nix` to collect ordinary `.nix` files and pass them to `flake-parts.lib.mkFlake`. It excludes `flake.nix`, `devenv.nix`, underscore-prefixed helpers, hidden directories, local overrides, generated state, and symlinks. Consequences:

- Adding a new ordinary `.nix` file in a source directory requires **no import wiring** — it is picked up automatically.
- Every auto-imported `.nix` file **must be a valid flake-parts module** (top-level `flake.*`, `perSystem`, `options`, ...). A plain expression or NixOS module at top level will break evaluation of the entire flake.
- Prefix a filename with `_` to exclude it from auto-import (helper/data files).

`parts.nix` sets `systems = ["x86_64-linux"]` and declares the custom `flake.wrappersModules` option (see below).

### NixOS modules are named leaves and aggregates

Files under `nixos/` export entries in `flake.nixosModules.<name>`. Independently usable leaves are composed by compatibility aggregates such as `base`, `general`, `desktop`, `deploy-rs`, and `sanctum`. Host-independent knobs live in the custom `preferences.*` namespace declared by `nixos/base/_preferences-options.nix` and exported through `preferences.nix` and `default.nix`.

- `nixos/base/` — shared option declarations and minimal foundations.
- `nixos/features/` — opt-in named leaves and explicit compatibility aggregates.

See `README.md` for the required feature, package, and host workflows.

### Hosts

Each `hosts/<name>/` has three files:

- `configuration.nix` exports `flake.nixosModules.<host>-configuration` with selected features and host policy.
- `hardware.nix` wraps generated hardware settings as `flake.nixosModules.<host>-hardware`.
- `default.nix` explicitly composes both modules, retains `nixosModules.<host>`, and constructs the host through `hosts/_lib.nix`.

Secrets use sops-nix. Gru and Tai Lung keep encrypted YAML and SOPS policy under their host `secrets/` directories; age key paths are host configuration.

### No home-manager — apps are configured via wrappers

All per-app configuration (ghostty, zsh, helix, git, jujutsu, fzf, oh-my-posh, niri, ...) lives in `packages/*.nix` as `perSystem` packages built with two wrapper libraries:

- `inputs.wrappers` (Lassulus) — `wrapPackage` (inject env/flags/runtimeInputs) and `wrapModule`; also provides pre-made `wrapperModules.<app>.apply { settings = ...; }`.
- `inputs.wrapper-modules` (BirdeeHub) — used for the niri desktop wrapper.

Reusable wrapper modules are exported under the custom `flake.wrappersModules` option (`niri`, `jjui`, `which-key`) and consumed elsewhere via `self.wrappersModules.<name>`.

Key aggregate packages in `packages/environment.nix`:

- `packages.environment` — wrapped zsh bundling all CLI tools (`myTools`); set as the **login shell** for the user on NixOS hosts (`nixos/features/general.nix`).
- `packages.desktop` — wrapped niri session with ghostty as terminal and helix as `$EDITOR`.
- `packages.terminal` — alias for the wrapped ghostty.

### Quickshell desktop shell

`packages/quickshell/` is a custom QML shell for niri (bar, app launcher, control center, notification daemon with DND, OSDs, session menu, lock screen, calendar, low-battery alerts). Key facts:

- `Services/Niri.qml` tracks workspaces/keyboard layout by consuming `niri msg --json event-stream` (full state resent on every reconnect; the Process auto-restarts because niri drops slow IPC clients). There is no quickshell niri module — don't use `Quickshell.Hyprland` here.
- Singletons under `Services/` use `pragma Singleton` + the `qs.Services` import; wifi is nmcli polling (`Network.qml`), notifications are `Quickshell.Services.Notifications` (`Notifs.qml`); battery/bluetooth/audio/tray use quickshell's UPower/Bluetooth/Pipewire/SystemTray modules directly.
- Panels are toggled via IPC: `quickshell ipc call <launcher|controlcenter|history|session|calendar> toggle` and `quickshell ipc call lock lock` — niri binds in `packages/niri.nix` call the *wrapped* binary so `-c <config>` matches the running instance. After `nh os switch`, the running shell is still the old store path, so IPC binds from the new generation won't reach it until niri/quickshell restarts.
- The lock screen (`Modules/Lock/`) is ext-session-lock + `Quickshell.Services.Pam` with the default `login` PAM config (works on NixOS and Ubuntu without pam.d wiring); the session menu locks in-process before suspend/hibernate instead of relying on a `loginctl lock-session` listener. Low-battery alerts (`Modules/Notifications/BatteryAlerts.qml`) self-notify via `notify-send`, which loops back into the shell's own notification server — `libnotify` is in the wrapper's runtimeInputs for this.
- The palette is injected from `theme.nix` via `QS_FLAKE_THEME_FILE` (plus `QML_XHR_ALLOW_FILE_READ=1` — Qt 6 blocks file:// XHR otherwise). Root `shell.qml` needs `//@ pragma UseQApplication` or tray menus break.
- niri autostarts the shell through the `autostart` option of `flake.wrappersModules.niri`; hosts add extras via `preferences.autostart` (consumed in `nixos/features/desktop.nix`).

### Theme

`theme.nix` exposes a base16 palette as `flake.theme` (with `#`) and `flake.themeNoHash`. Package configs reference it as `self.theme.base0X` — change colors there, not in individual app configs.

### Non-NixOS (Ubuntu) usage

The flake also serves a non-NixOS Ubuntu machine. GUI apps needing OpenGL are wrapped with `nix-gl-host` (see `packages/ghostty.nix`): the entrypoint is a dispatcher that execs the app directly on NixOS (`/etc/NIXOS` present) and through `nixglhost -- <app>` elsewhere, injecting the host's NVIDIA driver at runtime. Keep this wrapping intact when touching ghostty — and keep the NixOS bypass: nixglhost also scans `/run/opengl-driver/lib`, so without the bypass it pins an NVIDIA-only EGL vendor on NixOS and breaks GL on PRIME-offload hosts (gru).

Git/jj author names come from environment variables (`GIT_AUTHOR_NAME`, `GIT_COMMITTER_NAME`, `JJ_USER`) set in `nixos/features/user-environment.nix`. Email addresses are configured through Git/jj configuration; the flake does not set email environment variables.

### AI agent integration

`packages/pi/` co-locates the Pi coding agent, managed roles, extensions, prompts, skills, Pi-specific patches and tests, and the supporting `pi-subagents` and `skillopt-sleep` package modules. Its `default.nix` builds the `pi` coding agent (github.com/earendil-works/pi, packaged via the `pi` flake input `github:lukasl-dev/pi.nix`) as a portable package via `inputs.pi.lib.mkCodingAgent` + `wrapPackage`, shipped through `packages/environment.nix`'s `myTools` like every other tool — not a NixOS module, so it works on the non-NixOS host too. `models.json` adds local Ollama models; managed subagents select authenticated provider models at runtime according to role complexity rather than pinning provider-specific model IDs. In-house TypeScript extensions (`extensions/`) add VCS-aware tool preferences (`prefer-rg.ts`, `prefer-fd.ts`, `prefer-jj.ts`), `/plan-mode`, layered memory, the vendored subagent tool, and a deterministic `/ship` scout→plan→test-pin→batched-implement→review→finalize pipeline. `skills/` includes the code-quality workflows plus the global Claude skills (`graphify`, `jujutsu`, and `markitdown`); `APPEND_SYSTEM.md` mirrors global response, code-style, shell, VCS-attribution, and skill-trigger preferences. `clang-tools` is a Pi runtime input corresponding to Claude's enabled clangd plugin. Community Pi extensions are not installed at runtime; executable integration remains flake-managed and vendored into the Nix store.
