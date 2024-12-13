{ pkgs, inputs, ... }: {
  imports = [ inputs.stylix.nixosModules.stylix ];
  stylix = {
    enable = true;
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";

#    image = ./images.jpeg;
     image = pkgs.fetchurl {
       url = "https://codeberg.org/lunik1/nixos-logo-gruvbox-wallpaper/src/branch/master/png/gruvbox-dark-rainbow.png";
#       sha256 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b";
     };
  };
}
