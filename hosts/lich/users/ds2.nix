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

  hyprland.use = false;
  gbar.use = false;
  wofi.use = false;
  waybar.use = false;
  swaync.use = false;
  gui.vscode.use = false;
  media.use = false;
  browser.use = false;
  idea.use = false;
  obs.use = false;
  telegram.use = false;
  localsend.use = false;
  ghostty.use = false;
  tmux.use = false;
  qt.use = false;
  vscode-server.use = true;
}
