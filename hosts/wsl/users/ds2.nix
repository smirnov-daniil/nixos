{...}: {
  imports = [
    ../../../modules/home
  ];
  nixpkgs.config.allowUnfree = true;

  home = {
    username = "ds2";
    homeDirectory = "/home/ds2";
    stateVersion = "25.05";
  };

  hyprland.enable = false;
  gbar.enable = false;
  wofi.enable = false;
  waybar.enable = false;
  swaync.enable = false;
  vscode.enable = false;
  media.enable = false;
  browser.enable = false;
  idea.enable = false;
  obs.enable = false;
  telegram.enable = false;
  localsend.enable = false;
  ghostty.enable = false;
  tmux.enable = false;
  qt.enable = false;
  vscode-server.enable = true;
}
