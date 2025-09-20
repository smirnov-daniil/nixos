{
  pkgs,
  lib,
  config,
  ...
}: {
  options = {
    theme.qt.enable = lib.mkEnableOption "enables qt themes";
  };

  config = lib.mkIf config.theme.qt.enable {
    home.packages = with pkgs; [
      papirus-icon-theme
      pcmanfm-qt
    ];
    qt = {
      enable = true;
      #platformTheme.name = "gtk";
      #style = {
      #  package = pkgs.adwaita-qt;
      #  name = "adwaita-dark";
      #};
    };
  };
}
