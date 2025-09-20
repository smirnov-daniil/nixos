{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    media.enable = lib.mkEnableOption "enables media apps";
    browser.enable = lib.mkEnableOption "enables browser apps";
    idea.enable = lib.mkEnableOption "enables ItelliJ IDEA";
    obs.enable = lib.mkEnableOption "enables OBS Studio";
    telegram.enable = lib.mkEnableOption "enables Telegram";
    localsend.enable = lib.mkEnableOption "enables localsend";
  };

  config = lib.mkMerge [
    (lib.mkIf config.media.enable {
      home.packages = with pkgs; [
        imv # cl image viewer
        mpv # cl video viewer
      ];
    })
    (lib.mkIf config.browser.enable {
      home.packages = with pkgs; [
        zen-browser # browser
      ];
    })
    (lib.mkIf config.idea.enable {
      home.packages = with pkgs; [
        jetbrains.idea-ultimate # IDE
      ];
    })
    (lib.mkIf config.obs.enable {
      home.packages = with pkgs; [
        obs-studio # screen capture
      ];
    })
    (lib.mkIf config.telegram.enable {
      home.packages = with pkgs; [
        telegram-desktop # messager
      ];
    })
    (lib.mkIf config.telegram.enable {
      home.packages = with pkgs; [
        localsend # share files
      ];
    })
  ];
}
