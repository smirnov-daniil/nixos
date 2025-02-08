{inputs, ...}: {
  imports = [inputs.home-manager.nixosModules.default];
  home-manager.backupFileExtension = "backup";
  home-manager.sharedModules = [{stylix.targets.xyz.enable = false;}];
}
