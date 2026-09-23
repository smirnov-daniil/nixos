# Repository guidance

Use [README.md](README.md) as the authoritative guide for adding features, packages, and hosts. Use [nixos/README.md](nixos/README.md) for the module catalog and deploy-rs workflow.

## Architecture

- `flake.nix` uses `tools/_sources.nix` to recursively import ordinary `.nix` modules. It excludes `flake.nix`, `devenv.nix`, underscore-prefixed helpers, hidden directories, local overrides, generated state, and symlinks.
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

Use the pinned devenv environment. Checks include uncommitted/new files and exclude mutable runtime state; shell entry never activates or deploys a system:

```bash
devenv test
devenv tasks run flake:format
devenv --profile full test
devenv --profile gru tasks run flake:host
```

Use `statix check .` for advisory lint review. Use `nh os switch` for a local host and `devenv --profile tai-lung shell flake-deploy` from Gru for Tai Lung, only with explicit user authorization to activate/deploy. `devenv --profile tai-lung tasks run flake:deploy-check` only evaluates the local deployment target; it does not build, connect over SSH, or activate. Never attach deployment to tests or shell entry.

Keep the root `nixpkgs` pin in `flake.lock` aligned with `devenv.yaml` and `devenv.lock`. Do not add automatic deployment, secret decryption, or Git hooks to shell entry. See README.md for bootstrap and standalone helper commands.

The `ci` profile runs credential-free workflow checks only; whole-flake evaluation is a separate push/manual CI step using the locked private source and `SKINEM_READ_TOKEN`. Never expose this token or source to pull request events. The opt-in `claude` profile generates ignored settings and commands from `tools/_claude.nix`; preserve the profile in nested devenv invocations and never overwrite personal Claude settings.
