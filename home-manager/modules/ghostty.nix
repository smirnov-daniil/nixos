{ lib, ... }:
{
  programs.ghostty = {
    enable = true;
    settings = {
      background-opacity = 0.85;
      window-decoration = true;
      mouse-hide-while-typing = true;
    };
  };
}
