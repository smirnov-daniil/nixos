{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.tai-lung = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules.tai-lung];
  };
}
