{
  inputs,
  self,
  ...
}: let
  inherit (import ../_lib.nix {inherit inputs;}) mkHost;
  modules = [
    self.nixosModules.lich-configuration
    self.nixosModules.lich-hardware
  ];
in {
  flake = {
    nixosModules.lich.imports = modules;
    nixosConfigurations.lich = mkHost {
      modules = [self.nixosModules.lich];
    };
  };
}
