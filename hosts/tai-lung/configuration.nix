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
    domain = "ds-2.duckdns.org";
    ip = "178.66.51.192";
    
    nginx = {
      enable = true;
      # acmeEmail = "admin@your-domain.com";
    };
    
    vaultwarden = {
      enable = true;
    };
    
    # nextcloud = {
    #   enable = true;
    # };
    
    homepage = {
      enable = true;
      title = "My Sanctum Dashboard";
    };
    
    # telegram-notify = {
    #   enable = true;
    # };
  };
}
