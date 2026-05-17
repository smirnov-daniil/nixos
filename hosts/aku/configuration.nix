{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.aku = {
    pkgs,
    lib,
    config,
    ...
  }: {
    imports = [self.nixosModules.wsl self.nixosModules.base self.nixosModules.general self.nixosModules.pi];
    system.stateVersion = "25.11";
    networking = {
      hostName = "aku";
      networkmanager.enable = true;
    };

    users.users.${config.preferences.user.name} = {
      uid = 1001;
    };
  };
}
