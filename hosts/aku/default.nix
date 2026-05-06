{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.aku = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.aku
    ];
  };
}
