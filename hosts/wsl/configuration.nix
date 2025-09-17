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

  hyprland.use     = false;
  gbar.use         = false;
  wofi.use         = false;
  waybar.use       = false;
  swaync.use       = false;
  vscode.use       = false;
  media.use        = false;
  browser.use      = false;
  idea.use         = false;
  obs.use          = false;
  telegram.use     = false;
  localsend.use    = false;
  ghostty.use      = false;
  tmux.use         = false;
  qt.use           = false;
  stylix.use       = false;
  vscode-server.use = true;
}
