{
  # Wallpaper is configured in ../stylix.nix
  services.hyprpaper = {
    enable = true;

    settings = {
      preload = [ "~/.config/wallpaper.png" ];
      wallpaper = [ ",~/.config/wallpaper.png" ];
    };
  };
}
