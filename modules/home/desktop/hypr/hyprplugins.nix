{
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkIf config.desktop.hyprland.enable {
    home.packages = with pkgs; [
      hyprpolkitagent
      hyprlauncher
      hyprland-qt-support
      hyprsysteminfo
    ];
  };
}
