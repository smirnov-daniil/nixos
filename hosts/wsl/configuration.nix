{
  pkgs,
  stateVersion,
  hostname,
  inputs,
  ...
}: let 
    user = "ds2";
    system = "x86_64-linux";
  in{
  imports = [
    inputs.nixos-wsl.nixosModules.default
    inputs.home-manager.nixosModules.default
    ../../modules/nixos/system
    ./modules
  ];

  main-user = {
    enable = true;
    username = user;
  };

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
        inherit system;
        config.allowUnfree = true;
      };
    };

    users = {
      "${user}" = import ./users/ds2.nix;
    };
  };
}
