# Modular Nix configuration

This flake builds reusable packages and NixOS modules for `aku`, `gru`, `lich`, and `tai-lung`. It uses `flake-parts` with recursive module discovery, so additions need little wiring but must follow the contracts below.

## Development environment

Use Nix with flakes enabled and devenv 2.3.1 or newer. The standard CLI environment includes devenv. To bootstrap it without rebuilding your system:

```bash
cd ~/flake
nix run --inputs-from path:. nixpkgs#devenv -- shell
```

Once the CLI is installed, use `devenv shell`, or run `direnv allow` once to enable automatic activation through `.envrc`. Shell entry provides Nix tooling (`nixd`, Alejandra, Statix, deadnix), Jujutsu, and the commands below. It does not format files, install Git hooks, decrypt secrets, evaluate hosts, or activate a system.

```bash
devenv test                         # format, workflow regression tests, whole-flake evaluation
devenv tasks run flake:format        # format repository Nix files
devenv tasks run flake:eval          # evaluate without building checks
devenv --profile full test          # also build all flake checks; potentially expensive
devenv shell flake-build environment # build one package
devenv --profile gru tasks run flake:host # build Gru, never switch it
```

Inside the shell, `flake-fmt [--check]`, `flake-eval`, `flake-check`, `flake-build PACKAGE`, and `flake-host HOST` are available directly. The `aku`, `gru`, `lich`, and `tai-lung` profiles select the default host for `flake-host`; an explicit argument overrides the profile. Profiles can be combined, for example `devenv --profile gru --profile full shell`. Build result links live in `.devenv/builds/`.

Checks and builds use a filtered source snapshot: new/uncommitted files are included, but VCS metadata, `.devenv`, `.direnv`, local overrides, `.env*`, and build result links are excluded. Keep plaintext credentials outside the source tree; this filter is not a general secret scanner. `devenv.local.nix` and `devenv.local.yaml` are ignored personal overrides. No services or containers are needed for maintaining this repository, so use `devenv shell` and tasks, not `devenv up`.

The private `skinem` input still needs your SSH access (or an already fetched source) for whole-flake evaluation/builds. Devenv does not provide credentials. Activation and deployment remain explicit operations described below.

Both lock files are committed. When updating the root `nixpkgs` input in `flake.lock`, copy its revision into `devenv.yaml` and run `devenv update nixpkgs`; the regression tests check that the pins match. `devenv update` alone does not update the NixOS flake. Official references: [profiles](https://devenv.sh/profiles/), [tasks](https://devenv.sh/tasks/), and [direnv](https://devenv.sh/integrations/direnv/).

The pinned devenv `v2.3.1` release still has `2.2.2` in its upstream `src/modules/latest-version` metadata. Its shell can therefore print a version-mismatch hint even with the correct lock file; this does not indicate a failed setup.

## Architecture

`flake.nix` discovers modules through `tools/_sources.nix`. It recursively imports ordinary `.nix` files, excluding `flake.nix`, `devenv.nix`, underscore-prefixed helpers, hidden directories, local overrides, generated state, and symlinks.

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

Prefer `devenv test` during development. It includes new files without copying live devenv state into the flake source. For an environment without devenv, run the equivalent helpers with Nix, Alejandra, and jq available:

```bash
bash tools/flake-dev.sh format --check
bash tools/flake-dev.sh eval
bash tools/flake-dev.sh check
bash tools/flake-dev.sh host <host>
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
