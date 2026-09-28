---
name: extend-dendritic-nix-flake
description: Add NixOS features, packages, and explicitly composed hosts safely in this repository's recursive flake-parts architecture.
---

# Extend the dendritic Nix flake

1. Follow the recursive module discovery rules in `README.md`: ordinary discovered `.nix` files must be flake-parts modules; `_*.nix` helpers require explicit imports. Hidden/generated/local state and symlinks are excluded.
2. Export features as `flake.nixosModules.<name>`. Keep leaves independently usable, add them to the explicit `leaves` check inventory, and add an enabled fixture when useful. Keep production aggregates such as Sanctum explicit.
3. Export packages under `perSystem.packages`. Use `self'.packages` within `perSystem`; capture outer `self` and select `self.packages.${pkgs.stdenv.hostPlatform.system}` inside exported NixOS modules.
4. Build hosts from `<host>-configuration` and `<host>-hardware` constituent outputs. In `default.nix`, import `hosts/_lib.nix`, compose the constituents into compatibility output `nixosModules.<host>`, then call `mkHost` for `nixosConfigurations.<host>`.
5. Generate host checks by filtering `self.nixosConfigurations` to the current `perSystem` platform. Keep host-specific package invariants platform-gated.
6. Use the pinned devenv workflow: `devenv test`, with relevant profile checks when needed. It includes new/uncommitted files and excludes mutable runtime state. Preserve an active `claude` profile. Build affected outputs only when needed for validation; do not activate or deploy without explicit authorization.
7. Keep `README.md` authoritative and synchronize `AGENTS.md`/`CLAUDE.md` when architecture changes.
