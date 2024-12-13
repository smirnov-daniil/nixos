{ pkgs, ... }: {
  home.pointerCursor = {
    name = "DMZ-Black";
    size = 36;
    package = pkgs.vanilla-dmz;
    gtk.enable = true;
  };
}
