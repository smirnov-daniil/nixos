{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    qt.use = lib.mkEnableOption "enables qt themes";
  };

  config = lib.mkIf config.qt.use {
    home.packages = with pkgs; [
      papirus-icon-theme
      pcmanfm-qt
    ];
    qt = {
      enable = true;
      platformTheme.name = "gtk";
      style = {
        package = pkgs.adwaita-qt;
        name = "adwaita-dark";
      };
    };
  };
}
