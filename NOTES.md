# Login environment from the zsh wrapper

The user login shell is the flake-wrapped zsh from the `environment` package. The wrapper pins `ZDOTDIR` to a store directory, so `~/.profile`, `~/.zprofile` and `~/.zshrc` are never read, and the system `/etc/zsh/zprofile` on Ubuntu is empty. GDM launches the GNOME session through that login shell, so the session lost `~/.local/bin`, `~/.nix-profile/bin` and the `~/.nix-profile/share` entry of `XDG_DATA_DIRS`; launcher entries for Zen and Ghostty disappeared with it.

The wrapper's `.zshenv` is the only user-controlled file every zsh instance reads, including the non-interactive login shell GDM uses, so the login environment is restored there: it sources the single-user `nix-daemon.sh` profile script (idempotent, provides PATH and `XDG_DATA_DIRS`) and prepends `~/.local/bin`. Overriding `.zshenv` content also replaces the module default, which concatenates `EXAMPLE=TRUE` and the fzf plugin `path+=` onto one line.

# Provider-independent agent model routing

Agent role files now declare only a complexity tier. The Pi extensions resolve that tier at invocation time against authenticated models from the currently selected provider and product family, so the same role files do not depend on Claude, OpenAI, or another provider-specific model ID.

The resolver recognizes common efficiency, balanced, and capability tier names. It keeps the active model when a provider exposes no meaningful tier distinction, and uses the role complexity as the default thinking level. Explicit `model` and `effort` frontmatter remain available as overrides for custom roles.

# Pi review and workflow extensions

`pi-review` remains pinned as a non-flake input and patched during the Nix build. The automated reviewer uses native Jujutsu revsets and obtains pull-request patches without changing the checkout.

Human diff review uses pinned `tuicr` v0.20.0 from the `environment` package. Pi loads the upstream tuicr skill and `/diff-review` invokes its official Herdr wrapper, which owns pane creation, completion waiting, and cleanup. The adapter snapshots local draft comments through the Review CLI before and after the TUI session, then inserts only new or changed feedback into the Pi editor. This replaces the Glimpse/Chromium Review Loop and removes its browser sandbox exception, Node runtime, `xdotool`, and patch maintenance.

The local plan mode retains its read-only enforcement while adding numbered plan extraction, approval choices, persisted execution progress, `[DONE:n]` completion markers, a `/todos` command, and TUI status widgets. Handoff and terminal notifications remain local extensions so they load declaratively with the packaged Pi configuration.

# Niri login and hybrid graphics startup

The desktop greeter is marked as a text greeter so greetd owns VT1 correctly at boot and tuigreet remains visible instead of leaving an apparently plain console. It starts `niri-session` directly and leaves PRIME offload selection to explicitly offloaded applications rather than mutating the session-wide systemd user environment.

The `gru` PRIME configuration keeps modesetting alongside NVIDIA and pins Niri's renderer to the Intel render-node symlink. Niri key bindings use the absolute flake-managed Ghostty path, avoiding profile/PATH ambiguity. NVIDIA remains available explicitly through `nvidia-offload` for individual applications.

# SkillOpt-Sleep for Pi

The flake packages only SkillOpt-Sleep from the first upstream commit containing Pi transcript and backend support. Existing `remember` and `write_skill` workflows remain the online fact and procedure layers; SkillOpt adds bounded cross-session proposals rather than replacing them.

The Pi adaptation requires the exact Nix-managed source skill on every run and adoption, disables `CLAUDE.md` evolution and automatic adoption even when user configuration requests them, rejects stale memory-bearing or mismatched staging manifests, and creates private ignored state. Its textual held-out gate cannot replace tool-enabled `verify` or `/ship`, so learned changes land in a dedicated non-critical skill and require review, real workflow verification, and a successful Pi/environment rebuild before profile activation.

# Steerable background subagents

The blocking vendored subagent executor is replaced by pinned `@tintinweb/pi-subagents` 0.14.3. The broader `nicobailon/pi-subagents` candidate was not selected because its current main branch has an open standalone-Pi startup regression that affects this Nix wrapper. `Agent` calls can return immediately with unique job IDs, the orchestrator can continue accepting user turns, and `steer_subagent` injects corrections into a running child after its current tool completes. Completion arrives as a structured follow-up and the full JSONL transcript lives under a user-private, session-and-job-scoped system temporary directory rather than the repository; the extension removes the session run directory when Pi switches sessions or exits. Explicit schedule metadata also lives under the private temporary root instead of `<cwd>/.pi/`.

Managed roles return research, plans, reviews, and other handoffs in their final response. The `/ship` pipeline passes those responses in memory instead of creating `scratchpad/` files. Roles that edit code or tests may still modify their assigned product files, and Graphify retains its explicit absolute chunk-output exception.

A local adapter preserves provider-portable complexity routing for managed and built-in roles. The packaged upstream source removes its Anthropic-specific default and wizard presets. `isolation: "worktree"` selects the repository-native backend: a temporary Jujutsu workspace for `.jj/` repositories or a Git worktree otherwise. Jujutsu results survive workspace cleanup as change IDs and include a `jj squash --from '<snapshot>..<agent-change>' --into @ -m 'Integrate isolated agent changes' && jj abandon <snapshot>` integration command; empty workspace commits are abandoned.

# Dendritic tai-lung and Sanctum migration

Tai Lung and Sanctum follow master's flake-parts/import-tree architecture. The host uses the standard `default.nix`, `configuration.nix`, and `hardware.nix` layout; machine-specific settings remain in its configuration rather than creating a second feature hierarchy under the host.

Sanctum is a shared opt-in NixOS feature under `nixos/features/sanctum/`. Its active service files contribute named `flake.nixosModules` outputs and the aggregate `sanctum` module composes them through `self`. Tai Lung imports that feature alongside master's `base`, `general`, `intel`, and `pipewire` features.

The `nix-minecraft` input is retained because Tai Lung consumes it, while master's existing `sops-nix` input is reused. The SSH source rule uses nftables and limits access to the intended `/32` address. The previously unimported, internally inconsistent Telegram module stays absent rather than becoming a new public module accidentally.

ARR state paths are asserted against the pre-refactor `/srv` layout so a future module change cannot silently start services with fresh configuration directories. Lidarr and qBittorrent explicitly require their state paths before systemd starts them; the other enabled services already receive equivalent mount requirements from their NixOS modules. The encrypted Tai Lung SOPS file and creation rules are byte-identical to the pre-dendritic revision, the age key remains `/home/server/.config/sops/age/keys.txt`, and evaluation asserts that the Croc, Microbin, and Vaultwarden secret declarations remain present.

Tai Lung installs only Ghostty's standalone terminfo output, not the terminal application. SSH propagates the client's `TERM=xterm-ghostty`, so remote terminal-aware commands need that database entry even though this server has no graphical environment.

# Independent NixOS module boundaries

Preferences now form a foundational leaf, feature leaves import their own prerequisites, and `base`, `general`, `desktop`, and `sanctum` remain compatibility aggregates. Desktop, user-environment, browser, and Browsec packages expose override options while preserving their prior defaults; Sanctum leaves import only the shared core and only secret-using leaves import SOPS.

# deploy-rs roles

Deploy-rs is split into independent server and initiator NixOS features. The target role adds no deploy client package and grants no passwordless sudo by default; Tai Lung uses its existing `server` account with interactive sudo. Gru installs the pinned deploy-rs client and can activate Tai Lung through the flake deployment profile with deploy-rs rollback protection.

## Explicit host composition and contributor workflow

Host configuration and hardware modules now have distinct public names and are composed explicitly through an underscore-excluded `mkHost` helper. This removes reliance on flake-parts merging two unrelated files into the same output while retaining the existing `nixosModules.<host>` compatibility outputs. Host evaluation checks are generated from `nixosConfigurations`, so a newly exported host cannot be omitted from the basic check matrix. The root README is now the authoritative guide for feature, package, and host additions; package access remains context-specific and Sanctum membership remains explicit to avoid hiding system selection or silently enabling production services.

## Co-located Pi implementation

Pi-owned implementation assets now live under `packages/pi/`, including the patched `pi-subagents` and Pi-safe `skillopt-sleep` package modules and tests. Their public package and check names remain unchanged because recursive flake-parts discovery is path-independent. Repository-wide flake inputs and environment selection, standalone tuicr/Herdr packages, project `.pi/` runtime state, and root `graphify-out/` remain outside because they have broader ownership or location-dependent behavior.

## Terminal navigation moved from Ghostty to Herdr

Ghostty still shipped its stock multiplexing keymap — splits on `ctrl+shift+o/e` and `ctrl+alt+arrows`, tabs on `ctrl+shift+t`, `ctrl+tab` and `alt+1..9`, zoom on `ctrl+shift+enter` — even though Herdr owns panes and tabs here. Those defaults were never removed, only left undocumented, so they silently intercepted keys before the multiplexer saw them. The Ghostty config now starts its `keybind` list with `clear`, which drops every binding including the defaults, and re-adds an explicit allowlist: clipboard and selection, font size, quick terminal, fullscreen, quit/close, config reload, inspector and command palette. Font size uses the W3C physical codes `ctrl+equal`, `ctrl+minus` and `ctrl+digit_0` so no `=` has to be escaped inside a `trigger=action` string. Ghostty's own scrollback and search bindings are gone as well: under Herdr the scrollback belongs to its copy mode (`prefix+[`) and `prefix+e`.

Herdr's navigation is deliberately hybrid. Frequent motions are direct chords that need no prefix — `alt+h/j/k/l` for pane focus, `alt+f` zoom, `alt+1..9` for tabs (the same keys Ghostty used for `goto_tab`), `alt+[`/`alt+]` for previous/next tab. Everything rarer keeps the upstream prefix defaults (`prefix+c`, `prefix+v`, `prefix+minus`, `prefix+x`, `prefix+r`, `prefix+[`, workspace bindings), so the config does not restate them.

The bindings are written as arrays because `[keys]` merges with defaults per field, but a field the user sets replaces its default entirely. The previous single-string form (`focus_pane_left = "alt+h"`, `zoom = "alt+f"`) had therefore silently removed the stock `prefix+h/j/k/l` and `prefix+z`; listing both variants restores them. Note also that Herdr's key parser has no `page_up`/`page_down` names, and that resize mode and copy mode navigation are hardcoded, so only their entry bindings are configurable.

Herdr's palette is set to the built-in `terminal` theme instead of its bundled Catppuccin. That theme resolves its tokens to plain ANSI colors (`Color::Reset` for background and text), so the shell inherits whatever Ghostty renders, which is the base16 palette from `theme.nix` — one place still owns the colors.
