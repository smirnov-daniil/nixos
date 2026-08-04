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

# Subagent lifecycle status

Subagent results carry explicit `pending`, `running`, `done`, `failed`, and `skipped` states instead of overloading process exit codes. Parallel tasks beyond the concurrency limit remain pending, chain failures skip later steps, cancellation does not launch queued work, and every terminal transition is streamed before completion. Historical session results without an explicit state still render through exit-code inference.
