{ pkgs, stateVersion, hostname, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./local-packages.nix
      ../../nixos/modules
      ./hardware
    ];

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = [ pkgs.home-manager ];

  networking.hostName = hostname;

  system.stateVersion = stateVersion;
}
