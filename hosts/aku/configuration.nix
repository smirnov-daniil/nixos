{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.aku-configuration = {
    pkgs,
    lib,
    config,
    ...
  }: {
    imports = [
      self.nixosModules.wsl
      self.nixosModules.base
      self.nixosModules.general
      self.nixosModules.vm
      self.nixosModules.deploy-rs-initiator
    ];
    system.stateVersion = "25.11";
    networking = {
      networkmanager.enable = true;
    };
    preferences.hostname = "aku";
    features.vm.adminUser = config.preferences.user.name;
    features.deploy-rs.initiator.enable = true;
  };
}
