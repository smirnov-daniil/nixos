# Modular Nix configuration

This flake builds reusable packages and NixOS modules for `aku`, `gru`, `lich`, and `tai-lung`. It uses `flake-parts` with recursive module discovery, so additions need little wiring but must follow the contracts below.

## Architecture

`flake.nix` imports every `.nix` file in the repository except `flake.nix` and files whose basename starts with `_`.

- Ordinary `.nix` files must be valid `flake-parts` modules.
- `_*.nix` files are plain helpers and must be imported explicitly.
- `perSystem` defines outputs such as packages and checks for each system in `parts.nix`.
- `flake.nixosModules.<name>` exports reusable NixOS modules.
- `flake.nixosConfigurations.<name>` exports complete hosts.
- Aggregate modules such as `base`, `general`, `desktop`, `deploy-rs`, and `sanctum` preserve convenient defaults. Feature leaves should remain independently usable.

Repository layout:

- `hosts/<name>/`: host composition, configuration, hardware, and encrypted secrets.
- `nixos/base/`: shared options and minimal foundations.
- `nixos/features/`: independently reusable NixOS features and compatibility aggregates.
- `packages/`: packages, wrappers, and package bundles. Pi-owned implementation and support packages are co-located under `packages/pi/`.
- `checks/`: evaluation checks and host-specific invariants.

See [nixos/README.md](nixos/README.md) for the current module catalog and Tai Lung deployment instructions.

## Add a feature

Create `nixos/features/<name>.nix` as a flake-parts module:

```nix
{self, ...}: {
  flake.nixosModules.example = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.features.example;
  in {
    options.features.example.enable = lib.mkEnableOption "example";

    config = lib.mkIf cfg.enable {
      environment.systemPackages = [pkgs.example];
    };
  };
}
```

Then:

1. Import only the feature's actual prerequisites. Do not import a large aggregate merely to obtain one option.
2. Use an `enable` option when importing the module would otherwise change the system.
3. Add the module to `leaves` in `checks/nixos-modules.nix`.
4. Add an `enabledLeaves` fixture when its enabled configuration should be evaluated too.
5. Add it to an aggregate only when every consumer of that aggregate should receive it.
6. Import it from the selected host's `<host>-configuration` module and enable its options there.

For a Sanctum service, also add the leaf explicitly to `nixos/features/sanctum/default.nix`. Sanctum aggregation is intentionally not automatic: adding a file must not silently enable a production service.

## Add a package

Create `packages/<name>.nix`:

```nix
{...}: {
  perSystem = {pkgs, ...}: {
    packages.example = pkgs.example;
  };
}
```

For a custom derivation, assign it to `packages.example` in the same `perSystem` block. Package references depend on context:

```nix
self'.packages.example
```

Use `self'` inside `perSystem`, where it already represents the current system. In a NixOS module exported by a flake-parts module, capture `self` from the outer argument set and use:

```nix
self.packages.${pkgs.stdenv.hostPlatform.system}.example
```

A package output is not installed automatically. Add it deliberately to one of these consumers:

- a feature's `environment.systemPackages` for host-specific installation;
- `packages.environment` in `packages/environment.nix` for the standard CLI environment;
- another wrapper or aggregate package through `self'.packages`.

Use an underscore-prefixed helper for package data that is not itself a flake-parts module.

## Add a host

Create:

```text
hosts/<name>/
├── default.nix
├── configuration.nix
├── hardware.nix
└── secrets/             optional, encrypted only
```

`configuration.nix` exports a named constituent:

```nix
{self, ...}: {
  flake.nixosModules.example-configuration = {config, pkgs, ...}: {
    imports = [
      self.nixosModules.base
      self.nixosModules.general
    ];

    preferences.hostname = "example";
    system.stateVersion = "25.11";
  };
}
```

Wrap generated hardware configuration as another flake-parts module:

```nix
{
  flake.nixosModules.example-hardware = {config, lib, modulesPath, ...}: {
    imports = [(modulesPath + "/installer/scan/not-detected.nix")];
  };
}
```

Do not copy raw `nixos-generate-config` output over `hardware.nix` without preserving this wrapper.

Compose the host explicitly in `default.nix`:

```nix
{
  inputs,
  self,
  ...
}: let
  inherit (import ../_lib.nix {inherit inputs;}) mkHost;
  modules = [
    self.nixosModules.example-configuration
    self.nixosModules.example-hardware
  ];
in {
  flake = {
    nixosModules.example.imports = modules;
    nixosConfigurations.example = mkHost {
      modules = [self.nixosModules.example];
    };
  };
}
```

The aggregate `nixosModules.example` is retained as a reusable compatibility output. Every exported `nixosConfiguration` automatically gets an evaluation check. Add host-specific assertions separately when persistence, secrets, deployment, or package-footprint invariants need protection.

`mkHost` defaults to `x86_64-linux`. Pass `system` explicitly for another architecture and add that architecture to `systems` in `parts.nix` if per-system outputs are required.

## Validate changes

Use `path:.` while files are uncommitted so Nix includes newly created files:

```bash
alejandra --check .
nix flake check path:. --no-build --show-trace
nix flake check path:. --show-trace
nix build path:.#nixosConfigurations.<host>.config.system.build.toplevel
```

Run `statix check .` as an additional lint review; it may report advisory style findings that do not block evaluation.

Apply a local NixOS host with:

```bash
nh os switch
```

Deploy Tai Lung from Gru with:

```bash
deploy .#tai-lung
```

When adding an output, verify its public name directly:

```bash
nix eval --json path:.#nixosModules --apply builtins.attrNames
nix eval --json path:.#nixosConfigurations --apply builtins.attrNames
nix eval --json path:.#packages.x86_64-linux --apply builtins.attrNames
nix eval --json path:.#checks.x86_64-linux --apply builtins.attrNames
```
