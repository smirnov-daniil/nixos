{
  pkgs,
  inputs,
  stateVersion,
  config,
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
    inputs.sops-nix.nixosModules.default
  ];

  nixpkgs.config.allowUnfree = true;

  networking.hostName = hostname;

  system.stateVersion = stateVersion;

  main-user = {
    enable = true;
    username = "server";
  };

  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/${config.main-user.username}/.config/sops/age/keys.txt";
  };

  sanctum = {
    domain = "ssmirnovd.online";
    ip = "178.66.51.192";

    nginx = {
      enable = true;
      acmeEmail = "ssmirnovd@bk.ru";
    };

    croc = {
      enable = true;
    };

    vaultwarden = {
      enable = true;
    };

    homepage = {
      enable = true;
      title = "My Sanctum Dashboard";
    };

    microbin = {
      enable = true;
    };

    bazarr.enable = true;
    jellyseerr.enable = false;
    lidarr.enable = true;
    prowlarr.enable = true;
    radarr.enable = true;
    sonarr.enable = true;
    jellyfin.enable = true;
    qbittorrent.enable = true;
  };
}
