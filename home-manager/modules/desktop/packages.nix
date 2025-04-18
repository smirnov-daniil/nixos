{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkMerge [
    (lib.mkIf config.hyprland.use {
      home.packages = with pkgs; [
        libsForQt5.xwaylandvideobridge # impove vide in wayland QT apps
        xdg-desktop-portal-gtk # gtk basef portal for desktop integration in sandboxed apps
        xdg-desktop-portal-hyprland # same, but hyperland-specific
      ];
    })
    (lib.mkIf config.hyprpanel.use {
      home.packages = with pkgs; [
        wireplumber
        bluez
        networkmanager
        dart-sass
        wl-clipboard
        gvfs
      ];
    })
  ];
}
