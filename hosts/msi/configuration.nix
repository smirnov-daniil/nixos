{
  pkgs,
  stateVersion,
  hostname,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ../../modules/nixos/system
    ../../modules/nixos/hardware
    ./modules
  ];

  nixpkgs.config.allowUnfree = true;

  networking.hostName = hostname;

  system.stateVersion = stateVersion;

  main-user = {
    enable = true;
    username = "server";
  };
}
