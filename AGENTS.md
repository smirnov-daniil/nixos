# Repository guidance

Use [README.md](README.md) as the authoritative guide for adding features, packages, and hosts. Use [nixos/README.md](nixos/README.md) for the module catalog and deploy-rs workflow.

## Architecture

- `flake.nix` recursively imports every `.nix` file except `flake.nix` and files beginning with `_`.
- Every ordinary `.nix` file must therefore be a valid `flake-parts` module.
- `_*.nix` files are plain helpers and require explicit imports.
- Hosts are `aku`, `gru`, `lich`, and `tai-lung`.
- A host exports separate `<host>-configuration` and `<host>-hardware` modules, composes them in `hosts/<host>/default.nix`, and retains `nixosModules.<host>` as an aggregate.
- Shared NixOS modules live in `nixos/base/` and `nixos/features/`. Leaves should remain independently usable; aggregates are compatibility and convenience boundaries.
- Packages and wrappers live under `packages/` and are exported from `perSystem`.
- Pi lives in `packages/pi/` and is included through `packages.environment`; it is not a NixOS feature.

## Change workflow

- Feature: export a named `flake.nixosModules` leaf, add standalone and enabled checks as appropriate, then import it from the selected host.
- Package: export it under `perSystem.packages`, then add it explicitly to a feature, wrapper, or package bundle when installation is intended.
- Host: use the three-file host pattern and `hosts/_lib.nix`; host evaluation checks are generated automatically.
- Keep Sanctum aggregate membership explicit in `nixos/features/sanctum/default.nix`.
- Keep encrypted secrets under each host's `secrets/` directory and never add plaintext credentials.

## Validation

Run formatting and evaluation with uncommitted files included:

```bash
alejandra --check .
nix flake check path:. --no-build --show-trace
nix flake check path:. --show-trace
nix build path:.#nixosConfigurations.<host>.config.system.build.toplevel
```

Use `statix check .` for advisory lint review. Use `nh os switch` for a local host and `deploy .#tai-lung` from Gru for Tai Lung.
