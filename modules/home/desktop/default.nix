{lib, ...}: {
  imports = [
    ./wofi.nix
    ./waybar.nix
    ./packages.nix
    ./swaync.nix
    ./gbar.nix
    ./hyprland
  ];

  hyprland.enable = lib.mkDefault true;
  gbar.enable = lib.mkDefault true;
  wofi.enable = lib.mkDefault true;
  waybar.enable = lib.mkDefault false;
  swaync.enable = lib.mkDefault false;
}
