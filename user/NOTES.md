## Herdr mirror integration

Packed `herdr-mirror` as a local Nix package, exposed its plugin root and helper binaries through `packages/herdr`, auto-linked the plugin on every `herdr` launch, and added mirror keybindings plus a `herdr-mirror-init` helper that writes `~/.config/herdr-mirror/hosts.toml` from a template.

## Herdr plugin colocation

Moved the `herdr-mirror` package definition into `packages/herdr.nix` so the wrapped Herdr package and its bundled plugins live in one module and can share local let-bindings instead of cross-file package references.

## Herdr version bump

Switched the wrapped Herdr base package from `pkgs.herdr` to the upstream `herdrdev/herdr` v0.7.5 Nix package so the flake gets the latest Herdr release without waiting for nixpkgs to catch up.

## Pi output-semantics role

Added `packages/pi/agents/output-semantics.md` as a provider-portable Pi subagent role for analyzing large shell outputs, logs, and traces when mechanical filtering is not enough. Kept routing neutral with `complexity` and `effort` frontmatter instead of pinning a provider model, and relied on `packages/pi/default.nix` auto-install of every file under `packages/pi/agents/` so no packaging code change was needed.
