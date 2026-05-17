{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.aku = {
    pkgs,
    lib,
    ...
  }: {
    imports = [self.nixosModules.wsl self.nixosModules.base self.nixosModules.general self.nixosModules.pi];
    system.stateVersion = "25.11";
    networking = {
      hostName = "aku";
      networkmanager.enable = true;
    };
  };
}
