{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.gru = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.gru
    ];
  };
}
