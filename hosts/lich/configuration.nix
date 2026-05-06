{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.lich = {
    pkgs,
    lib,
    ...
  }: {
    imports = [self.nixosModules.wsl self.nixosModules.base self.nixosModules.general];
    system.stateVersion = "25.11";
    networking = {
      hostName = "lich";
      networkmanager.enable = true;
    };
    preferences.user.email = "dan.smirnov@yadro.com";
  };
}
