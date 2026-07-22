# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
nix flake check                  # evaluate the whole flake (fast sanity check)
nix build .#<name>               # build one package, e.g. .#environment, .#ghostty, .#desktop
nix build .#nixosConfigurations.<host>.config.system.build.toplevel   # build a full host (aku, gru, lich)
alejandra .                      # format Nix files
statix check .                   # lint Nix files
nh os switch                     # apply config on a NixOS host (no sudo needed; nh is wrapped with NH_FLAKE=$HOME/flake)
nix flake update                 # update all inputs
```

Commit messages follow conventional-commit style, e.g. `fix(omp): jujutsu`, `feat(omp): jj ui instead of git`.

## Architecture

### Auto-import: every .nix file is a flake-parts module

`flake.nix` collects **every** `.nix` file in the tree (except `flake.nix` itself and files whose name starts with `_`) and passes them all as imports to `flake-parts.lib.mkFlake`. Consequences:

- Adding a new `.nix` file anywhere requires **no import wiring** — it is picked up automatically.
- Every `.nix` file **must be a valid flake-parts module** (top-level `flake.*`, `perSystem`, `options`, ...). A plain expression or NixOS module at top level will break evaluation of the entire flake.
- Prefix a filename with `_` to exclude it from auto-import (helper/data files).

`parts.nix` sets `systems = ["x86_64-linux"]` and declares the custom `flake.wrappersModules` option (see below).

### NixOS modules are defined piecewise and merged

Files under `nixos/` define entries in `flake.nixosModules.<name>`. The same module name may be defined in several files — e.g. `flake.nixosModules.base` is spread across `nixos/base/user.nix` and `start.nix` and merged by the flake-parts `modules` flakeModule. Host-independent knobs live in the custom `preferences.*` option namespace (`preferences.hostname`, `preferences.user.{name,fullname,email}`, `preferences.autostart`, ...) declared in `nixos/base/`.

- `nixos/base/` — option declarations and fundamentals.
- `nixos/features/` — opt-in named modules (`general`, `desktop`, `intel`, `net`, `nix`, `wsl`, `pi`, ...) that hosts import explicitly.

### Hosts

Each `hosts/<name>/` has three files:

- `configuration.nix` — defines `flake.nixosModules.<host>`: imports the base/feature modules it wants plus host-specific settings (bootloader, GPU, sops).
- `default.nix` — one-liner turning that module into `flake.nixosConfigurations.<host>`.
- `hardware.nix` — generated hardware config.

Secrets use sops-nix; `hosts/gru/secrets/` holds the encrypted yaml, decrypted with an age key at `~/.config/sops/age/keys.txt`.

### No home-manager — apps are configured via wrappers

All per-app configuration (ghostty, zsh, helix, git, jujutsu, zellij, fzf, oh-my-posh, niri, ...) lives in `packages/*.nix` as `perSystem` packages built with two wrapper libraries:

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

Git/jj identity comes from environment variables (`GIT_AUTHOR_*`, `GIT_COMMITTER_*`, `JJ_USER`, `JJ_EMAIL`) set in `nixos/features/general.nix`, not from `user.*` config in the wrapped git/jujutsu packages.

### AI agent integration

`packages/pi/` builds the `pi` coding agent (github.com/earendil-works/pi, packaged via the `pi` flake input `github:lukasl-dev/pi.nix`) as a portable package via `inputs.pi.lib.mkCodingAgent` + `wrapPackage`, shipped through `packages/environment.nix`'s `myTools` like every other tool — not a NixOS module, so it works on the non-NixOS host too. `models.json` adds local Ollama models; the default and all subagents use OpenAI Codex, tiered as Spark for small tasks, GPT-5.4 Mini for implementation/recon/testing, and GPT-5.4 for planning/review/escalation. In-house TypeScript extensions (`extensions/`) add VCS-aware tool preferences (`prefer-rg.ts`, `prefer-fd.ts`, `prefer-jj.ts`), `/plan-mode`, layered memory, the vendored subagent tool, and a deterministic `/ship` scout→plan→test-pin→batched-implement→review→finalize pipeline. `skills/` includes the code-quality workflows plus the global Claude skills (`graphify`, `jujutsu`, and `markitdown`); `APPEND_SYSTEM.md` mirrors global response, code-style, shell, VCS-attribution, and skill-trigger preferences. `clang-tools` is a Pi runtime input corresponding to Claude's enabled clangd plugin. Community Pi extensions are not installed at runtime; executable integration remains flake-managed and vendored into the Nix store.
