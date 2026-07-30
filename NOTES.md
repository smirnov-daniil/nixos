# Provider-independent agent model routing

Agent role files now declare only a complexity tier. The Pi extensions resolve that tier at invocation time against authenticated models from the currently selected provider and product family, so the same role files do not depend on Claude, OpenAI, or another provider-specific model ID.

The resolver recognizes common efficiency, balanced, and capability tier names. It keeps the active model when a provider exposes no meaningful tier distinction, and uses the role complexity as the default thinking level. Explicit `model` and `effort` frontmatter remain available as overrides for custom roles.

# Pi review and workflow extensions

`pi-review` and `pi-review-loop` are pinned as non-flake inputs and patched during the Nix build. The automated reviewer uses native Jujutsu revsets and obtains pull-request patches without changing the checkout. Review Loop compares the current Jujutsu change with `@-`, excludes repository metadata and dependency trees from watching, and omits sensitive, binary, non-UTF-8, symlinked, and oversized files from session checkpoints.

Review Loop uses Glimpse's Chromium backend because its native WebKit layer-shell backend is unavailable on the Ubuntu workstation. The Nix Chromium sandbox runs normally when the NixOS setuid wrapper exists. Ubuntu's AppArmor policy rejects both the packaged setuid helper and unprivileged user namespaces, so the dedicated local Review Loop browser falls back to `--no-sandbox`; its temporary profile and local immutable UI limit the scope of that tradeoff. The prebuilt UI is patched at build time to expose its dynamic Jujutsu baseline and a compositor-independent close control without rebuilding Monaco assets.

The local plan mode retains its read-only enforcement while adding numbered plan extraction, approval choices, persisted execution progress, `[DONE:n]` completion markers, a `/todos` command, and TUI status widgets. Handoff and terminal notifications remain local extensions so they load declaratively with the packaged Pi configuration.

# Niri login and hybrid graphics startup

The desktop greeter is marked as a text greeter so greetd owns VT1 correctly at boot and tuigreet remains visible instead of leaving an apparently plain console. Its Niri command uses a dedicated launcher that clears PRIME-offload selectors from both the process and the systemd user-manager environment before `niri-session` imports the login environment; this prevents a previous `nvidia-offload niri-session` invocation from affecting later Intel sessions.

The `gru` PRIME configuration keeps modesetting alongside NVIDIA and pins Niri's renderer to the Intel render-node symlink. Niri key bindings use the absolute flake-managed Ghostty path, avoiding profile/PATH ambiguity. NVIDIA remains available explicitly through `nvidia-offload` for individual applications.
