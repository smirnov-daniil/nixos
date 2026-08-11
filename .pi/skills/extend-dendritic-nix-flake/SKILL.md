---
name: extend-dendritic-nix-flake
description: Add NixOS features, packages, and explicitly composed hosts safely in this repository's recursive flake-parts architecture.
---

# Extend the dendritic Nix flake

1. Remember that `flake.nix` imports every non-underscore `.nix` file. Ordinary files must be flake-parts modules; use `_*.nix` for plain helpers.
2. Export features as `flake.nixosModules.<name>`. Keep leaves independently usable, add them to the explicit `leaves` check inventory, and add an enabled fixture when useful. Keep production aggregates such as Sanctum explicit.
3. Export packages under `perSystem.packages`. Use `self'.packages` within `perSystem`; capture outer `self` and select `self.packages.${pkgs.stdenv.hostPlatform.system}` inside exported NixOS modules.
4. Build hosts from `<host>-configuration` and `<host>-hardware` constituent outputs. In `default.nix`, import `hosts/_lib.nix`, compose the constituents into compatibility output `nixosModules.<host>`, then call `mkHost` for `nixosConfigurations.<host>`.
5. Generate host checks by filtering `self.nixosConfigurations` to the current `perSystem` platform. Keep host-specific package invariants platform-gated.
6. Use `path:.` while testing newly created files. Run `alejandra --check .`, `nix flake check path:. --show-trace`, and build affected host closures. A useful end-to-end smoke is to temporarily create a package, feature consuming it, and container host consuming the feature, then evaluate the package, hostname, and auto-generated host check before removing the files.
7. Keep `README.md` authoritative and synchronize `AGENTS.md`/`CLAUDE.md` when architecture changes.
