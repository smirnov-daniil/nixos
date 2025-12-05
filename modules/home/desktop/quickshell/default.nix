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
    home.file."${config.xdg.configHome}/quickshell/shell.qml" = {
      source = ./config.qml;
    };
  };
}
