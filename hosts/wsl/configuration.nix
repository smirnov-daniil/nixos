{
  pkgs,
  stateVersion,
  hostname,
  inputs,
  ...
}: let 
  user = "ds2";
  in{
  imports = [
    inputs.nixos-wsl.nixosModules.default
    inputs.home-manager.nixosModules.default
    ../../nixos/modules/env.nix
    ../../nixos/modules/nh.nix
    ../../nixos/modules/nix.nix
    ../../nixos/modules/user.nix
    ./modules
  ];

  system.stateVersion = stateVersion;
  wsl = {
    enable = true;
    wslConf = {
      network = {
        hostname = hostname;
      };
    };
    interop.register = true;
    docker-desktop.enable = true;
    defaultUser = user;   
    startMenuLaunchers = true;
  };
  
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = [pkgs.home-manager];

  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
      pkgs = import inputs.nixpkgs {
        config.allowUnfree = true;
      };
    };

    users = {
      "ds2" = import ./home.nix;
    };
  };
}
