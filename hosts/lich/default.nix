{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.lich = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.lich
    ];
  };
}
