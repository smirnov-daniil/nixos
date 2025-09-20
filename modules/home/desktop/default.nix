{lib, ...}: {
  imports = [
    ./wofi.nix
    ./waybar.nix
    ./packages.nix
    ./swaync.nix
    ./gbar.nix
    ./hyprland
  ];

  desktop.hyprland.enable = lib.mkDefault true;
  desktop.gbar.enable = lib.mkDefault true;
  desktop.wofi.enable = lib.mkDefault true;
  desktop.waybar.enable = lib.mkDefault false;
  desktop.swaync.enable = lib.mkDefault false;
}
