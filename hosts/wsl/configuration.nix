{
  pkgs,
  stateVersion,
  hostname,
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
    defaultUser = user;   
    startMenuLaunchers = true;
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = [pkgs.home-manager];

  desktop.use = false;
  gui.use = false;
  ghostty.use = false;
  tmux.use = false;
  qt.use = false;
  stylix.use = false;
}
