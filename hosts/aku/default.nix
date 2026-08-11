{
  inputs,
  self,
  ...
}: let
  inherit (import ../_lib.nix {inherit inputs;}) mkHost;
  modules = [
    self.nixosModules.aku-configuration
    self.nixosModules.aku-hardware
  ];
in {
  flake = {
    nixosModules.aku.imports = modules;
    nixosConfigurations.aku = mkHost {
      modules = [self.nixosModules.aku];
    };
  };
}
