{lib, ...}: {
  imports = [
    ./wofi.nix
    ./waybar.nix
    ./packages.nix
    ./swaync.nix
    ./gbar.nix
    ./hyprland
  ];

  hyprland.use = lib.mkDefault true;
  gbar.use = lib.mkDefault true;
  wofi.use = lib.mkDefault true;
  waybar.use = lib.mkDefault false;
  swaync.use = lib.mkDefault false;
}
