{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.lich-configuration = {
    pkgs,
    lib,
    ...
  }: {
    imports = [self.nixosModules.wsl self.nixosModules.base self.nixosModules.general];
    system.stateVersion = "25.11";
    preferences.hostname = "lich";
    networking = {
      networkmanager.enable = true;
      wireless.enable = lib.mkForce false;
      wireless.iwd.enable = lib.mkForce false;
    };
    preferences.user.email = "dan.smirnov@yadro.com";
  };
}
