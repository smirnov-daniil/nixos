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

  desktop.hyprland.enable = false;
  desktop.gbar.enable = false;
  desktop.wofi.enable = false;
  desktop.waybar.enable = false;
  desktop.swaync.enable = false;
  vscode.enable = false;
  gui.media.enable = false;
  gui.browser.enable = false;
  gui.idea.enable = false;
  gui.obs.enable = false;
  gui.telegram.enable = false;
  gui.localsend.enable = false;
  terminal.ghostty.enable = false;
  terminal.tmux.enable = false;
  theme.qt.enable = false;
  misc.vscode-server.enable = true;
}
