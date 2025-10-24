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
    ../../modules/sanctum
  ];

  nixpkgs.config.allowUnfree = true;

  networking.hostName = hostname;

  system.stateVersion = stateVersion;

  main-user = {
    enable = true;
    username = "server";
  };

  sanctum.services.nginx = {
    enable = true;
    domain = "your-domain.com";
    acmeEmail = "your-email@example.com";
  };
}
