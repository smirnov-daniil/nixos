{
  description = "A very basic flake";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixpkgs-stable.url = "github:NixOS/nixpkgs?ref=nixos-25.11";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";
    wrappers.url = "github:Lassulus/wrappers";
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: let
    inherit (inputs.nixpkgs) lib;
    inherit (lib.fileset) toList fileFilter;

    isNixModule = file:
      file.hasExt "nix"
      && file.name != "flake.nix"
      && !lib.hasPrefix "_" file.name;

    importTree = path:
      toList (fileFilter isNixModule path);

    mkFlake = inputs.flake-parts.lib.mkFlake {inherit inputs;};
  in
    mkFlake {imports = importTree ./.;};
}
