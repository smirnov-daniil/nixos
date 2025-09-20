{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    gui.media.enable = lib.mkEnableOption "enables media apps";
    gui.browser.enable = lib.mkEnableOption "enables browser apps";
    gui.idea.enable = lib.mkEnableOption "enables ItelliJ IDEA";
    gui.obs.enable = lib.mkEnableOption "enables OBS Studio";
    gui.telegram.enable = lib.mkEnableOption "enables Telegram";
    gui.localsend.enable = lib.mkEnableOption "enables localsend";
  };

  config = lib.mkMerge [
    (lib.mkIf config.gui.media.enable {
      home.packages = with pkgs; [
        imv # cl image viewer
        mpv # cl video viewer
      ];
    })
    (lib.mkIf config.gui.browser.enable {
      home.packages = with pkgs; [
        zen-browser # browser
      ];
    })
    (lib.mkIf config.gui.idea.enable {
      home.packages = with pkgs; [
        jetbrains.idea-ultimate # IDE
      ];
    })
    (lib.mkIf config.gui.obs.enable {
      home.packages = with pkgs; [
        obs-studio # screen capture
      ];
    })
    (lib.mkIf config.gui.telegram.enable {
      home.packages = with pkgs; [
        telegram-desktop # messager
      ];
    })
    (lib.mkIf config.gui.telegram.enable {
      home.packages = with pkgs; [
        localsend # share files
      ];
    })
  ];
}
