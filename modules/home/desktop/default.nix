{lib, ...}: {
  imports = [
    ./wofi.nix
    ./waybar.nix
    ./packages.nix
    ./swaync.nix
    ./gbar.nix
    ./hyprland
    ./quickshell
  ];

  desktop.hyprland.enable = lib.mkDefault true;
  desktop.gbar.enable = lib.mkDefault false;
  desktop.wofi.enable = lib.mkDefault true;
  desktop.waybar.enable = lib.mkDefault false;
  desktop.swaync.enable = lib.mkDefault false;
  desktop.quickshell.enable = lib.mkDefault true;
}
