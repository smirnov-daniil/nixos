{
  flake.nixosModules.preferences = {
    imports = [./_preferences-options.nix];
  };
}
