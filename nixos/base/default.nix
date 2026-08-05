{self, ...}: {
  flake.nixosModules.base = {
    imports = [self.nixosModules.preferences];
  };
}
