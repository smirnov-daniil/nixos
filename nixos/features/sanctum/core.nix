{
  flake.nixosModules.sanctum-core = {
    imports = [./_core-options.nix];
  };
}
