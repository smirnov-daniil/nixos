{
  pkgs,
  stateVersion,
  hostname,
  inputs,
  specialArgs,
  ...
}: {
  imports = [
    inputs.nixos-wsl.nixosModules.default
    ../../nixos/modules/env.nix
    ../../nixos/modules/home-manager.nix
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
    defaultUser = specialArgs.user;   
    startMenuLaunchers = true;
  };
  
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = [pkgs.home-manager];

  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
    };

    users = {
      "ds2" = import ./home.nix;
    };

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  };
}
