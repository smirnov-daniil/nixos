{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    media.use = lib.mkEnableOption "enables media apps";
    browser.use = lib.mkEnableOption "enables browser apps";
    idea.use = lib.mkEnableOption "enables ItelliJ IDEA";
    obs.use = lib.mkEnableOption "enables OBS Studio";
    telegram.use = lib.mkEnableOption "enables Telegram";
    localsend.use = lib.mkEnableOption "enables localsend";
  };

  config = lib.mkMerge [
    (lib.mkIf config.media.use {
      home.packages = with pkgs; [
        imv # cl image viewer
        mpv # cl video viewer
      ];
    })
    (lib.mkIf config.browser.use {
      home.packages = with pkgs; [
        zen-browser # browser
      ];
    })
    (lib.mkIf config.idea.use {
      home.packages = with pkgs; [
        jetbrains.idea-ultimate # IDE
      ];
    })
    (lib.mkIf config.obs.use {
      home.packages = with pkgs; [
        obs-studio # screen capture
      ];
    })
    (lib.mkIf config.telegram.use {
      home.packages = with pkgs; [
        telegram-desktop # messager
      ];
    })
    (lib.mkIf config.telegram.use {
      home.packages = with pkgs; [
        localsend # share files
      ];
    })
  ];
}

