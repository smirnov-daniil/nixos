{lib, ...}: {
  imports = [
    ./wofi.nix
    ./waybar.nix
    ./packages.nix
    ./swaync.nix
    ./gbar.nix
    ./hyprland
  ];

  desktop.use = lib.mkDefault true;

  hyprland.use = lib.mkDefault desktop.use;
  gbar.use = lib.mkDefault desktop.use;
  wofi.use = lib.mkDefault desktop.use;
  waybar.use = lib.mkDefault desktop.use;
  swaync.use = lib.mkDefault desktop.use;
}
