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
    imports = [
      self.nixosModules.wsl
      self.nixosModules.base
      self.nixosModules.general
      self.nixosModules.pi
      self.nixosModules.vm
    ];
    system.stateVersion = "25.11";
    networking = {
      networkmanager.enable = true;
    };
    preferences.hostname = "aku";
  };
}
