{lib, ...}: {
  imports = [
    ./wofi.nix
    ./waybar.nix
    ./packages.nix
    ./swaync.nix
    ./hyprpanel.nix
    ./hyprland
  ];

  hyprland.use = lib.mkDefault true;
  hyprpanel.use = lib.mkDefault true;
  wofi.use = lib.mkDefault true;
  waybar.use = lib.mkDefault false;
  swaync.use = lib.mkDefault false;
}
