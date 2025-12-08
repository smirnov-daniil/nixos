{
  lib,
  pkgs-unstable,
  config,
  ...
}: {
  options = {
    desktop.quickshell.enable = lib.mkEnableOption "enables quickshell";
  };

  config = lib.mkIf config.desktop.quickshell.enable {
    home.packages = with pkgs-unstable; [
      quickshell
    ];
    home.file = {
      "${config.xdg.configHome}/quickshell" = {
        source = ./config;
        recursive = true;
      };
    };
    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = false;
      settings = {
        env = [
          "QML_XHR_ALLOW_FILE_READ,1"
        ];
      };
    };
  };
}
