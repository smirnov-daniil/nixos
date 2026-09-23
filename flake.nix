{
  description = "A very basic flake";

  inputs = {
    # Private source: fetched by the invoking user's SSH agent, never at runtime.
    skinem.url = "git+ssh://git@github.com/smirnov-daniil/tributum.git?ref=master";
    flake-parts.url = "github:hercules-ci/flake-parts";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wrapper-modules = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wrappers = {
      url = "github:Lassulus/wrappers";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Package expressions must be available without import-from-derivation.
    herdr = {
      url = "github:herdrdev/herdr/cca4af8dfad160bc5fb5ae133b70882b5fe28f61";
      flake = false;
    };
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pi = {
      url = "github:lukasl-dev/pi.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pi-review = {
      url = "github:earendil-works/pi-review/f1de050504936046c0f85b21fec0e0a93ef394eb";
      flake = false;
    };
    pi-subagents = {
      url = "github:tintinweb/pi-subagents/2966cd5a33c0640de9698b56a39c11f83207a835";
      flake = false;
    };
    tuicr = {
      url = "github:agavra/tuicr/v0.20.0";
      flake = false;
    };
    skillopt = {
      url = "github:microsoft/SkillOpt/8a4c96a23639eee6ce19de7579ac9006b6dd4a2a";
      flake = false;
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Runtime OpenGL/CUDA driver bridge for running Nix GUI apps on non-NixOS
    # (Ubuntu). Injects the host's installed NVIDIA libs at runtime, so it
    # works even when the host driver is newer than anything in nixpkgs.
    nix-gl-host = {
      url = "github:numtide/nix-gl-host";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: let
    inherit (import ./tools/_sources.nix) moduleFiles;

    mkFlake = inputs.flake-parts.lib.mkFlake {inherit inputs;};
  in
    mkFlake {imports = moduleFiles ./.;};
}
