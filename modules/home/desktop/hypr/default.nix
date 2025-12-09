{lib, ...}: {
  imports = [
    ./binds.nix
    ./hypridle.nix
    ./hyprlock.nix
    ./hyprplugins.nix
    ./kanshi.nix
    ./main.nix
    ./windowrules.nix
  ];

  options = {
    desktop.hyprland.enable = lib.mkEnableOption "enables Hyprland and stuff.";
  };
}
