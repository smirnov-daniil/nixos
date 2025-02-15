{lib, config, ...}: {
  imports = [
    ./binds.nix
    ./hypridle.nix
    ./hyprlock.nix
    ./hyprpaper.nix
    ./kanshi.nix
    ./main.nix
  ];

  options = {
    hyprland.use = lib.mkEnableOption "enables Hyprland and stuff.";
  };
}
