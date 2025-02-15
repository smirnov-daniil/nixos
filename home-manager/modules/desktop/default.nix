{lib, ...}: {
  imports = [
    ./wofi.nix
    ./waybar.nix
    ./swaync.nix
    ./hyprland
  ];

  hyprland.use = lib.mkDefault true;
  wofi.use = lib.mkDefault true;
  waybar.use = lib.mkDefault true;
  swaync.use = lib.mkDefault true;
}
