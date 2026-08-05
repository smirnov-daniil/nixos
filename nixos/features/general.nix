{self, ...}: {
  flake.nixosModules.general = {
    imports = [
      self.nixosModules.user-environment
      self.nixosModules.nix
      self.nixosModules.net
    ];

    user-environment.extraGroups = ["wheel" "networkmanager"];
  };
}
