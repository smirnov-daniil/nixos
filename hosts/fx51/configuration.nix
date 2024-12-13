{ stateVersion, hostname, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../../nixos/packages.nix
      ./local-packages.nix
      ../../nixos/modules
      ./hardware
    ];

  networking.hostName = hostname;

  system.stateVersion = stateVersion;

  services.xserver.enable = true;
 
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
}
