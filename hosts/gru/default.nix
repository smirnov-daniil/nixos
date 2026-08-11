{
  inputs,
  self,
  ...
}: let
  inherit (import ../_lib.nix {inherit inputs;}) mkHost;
  modules = [
    self.nixosModules.gru-configuration
    self.nixosModules.gru-hardware
  ];
in {
  flake = {
    nixosModules.gru.imports = modules;
    nixosConfigurations.gru = mkHost {
      modules = [self.nixosModules.gru];
    };
  };
}
