{lib, ...}: {
  imports = [
    ./binds.nix
    ./hypridle.nix
    ./hyprlock.nix
    ./kanshi.nix
    ./main.nix
  ];

  options = {
    desktop.hyprland.enable = lib.mkEnableOption "enables Hyprland and stuff.";
  };
}
