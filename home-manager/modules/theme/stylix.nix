{
  pkgs,
  inputs,
  lib,
  config,
  ...
}: {
  imports = [inputs.stylix.homeManagerModules.stylix];

  options = {
    stylix.use = lib.mkEnableOption "enables stylix";
  };

  config = lib.mkIf config.stylix.use {
    home.packages = with pkgs; [
      jetbrains-mono
      noto-fonts
      noto-fonts-emoji
      font-awesome
      powerline-fonts
      powerline-symbols
      (nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];})
    ];

    stylix = {
      enable = true;
      autoEnable = true;
      polarity = "dark";
      base16Scheme = "${pkgs.base16-schemes}/share/themes/helios.yaml"; #precious-dark-fifteen #helios #framer #eighties # chalk

      opacity = {
        applications = 0.85;
        desktop = 0.90;
        popups = 0.85;
        terminal = 0.85;
      };

      targets = {
        hyprlock.enable = false;
        wofi.enable = true;
      };

      cursor = {
        name = "DMZ-Black";
        size = 24;
        package = pkgs.vanilla-dmz;
      };

      fonts = {
        emoji = {
          name = "Noto Color Emoji";
          package = pkgs.noto-fonts-color-emoji;
        };
        monospace = {
          name = "JetBrains Mono";
          package = pkgs.jetbrains-mono;
        };
        sansSerif = {
          name = "Noto Sans";
          package = pkgs.noto-fonts;
        };
        serif = {
          name = "Noto Serif";
          package = pkgs.noto-fonts;
        };

        sizes = {
          terminal = 12;
          applications = 12;
          desktop = 12;
          popups = 10;
        };
      };

      iconTheme = {
        enable = true;
        package = pkgs.papirus-icon-theme;
        dark = "Papirus-Dark";
        light = "Papirus-Light";
      };

      #image = ./wallpaper.png;
      image = pkgs.fetchurl {
        url = "https://i.redd.it/ohj1l323kve81.jpg";
        sha256 = "1ff5n5njqq2bsb4p9hdvhlj29286qwqbj3d5xlsh2avkbhzk6r5i";
      };
    };
  };
}
