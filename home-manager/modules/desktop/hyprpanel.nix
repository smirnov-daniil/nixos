{
  pkgs,
  inputs,
  lib,
  config,
  ...
}: let
  accent = "#${config.lib.stylix.colors.base0D}";
  accent-alt = "#${config.lib.stylix.colors.base03}";
  background = "#${config.lib.stylix.colors.base00}";
  background-alt = "#${config.lib.stylix.colors.base01}";
  foreground = "#${config.lib.stylix.colors.base05}";
  font = "${config.stylix.fonts.sansSerif.name}";
  fontSize = "${toString config.stylix.fonts.sizes.desktop}";
  opacity = config.stylix.opacity.desktop * 100;
in {
  imports = [
    inputs.hyprpanel.homeManagerModules.hyprpanel
    inputs.ags.homeManagerModules.default
  ];

  options = {
    hyprpanel.use = lib.mkEnableOption "enables hyprpanel";
  };

  config = lib.mkIf config.hyprpanel.use {
    programs.hyprpanel = {
      enable = true;

      hyprland.enable = true;

      overwrite.enable = true;

      overlay.enable = true;

      layout = {
        "bar.layouts" = {
          "0" = {
            "left" = ["windowtitle"];
            "middle" = ["workspaces"];
            "right" = [
              "systray"
              "battery"
              "network"
              "clock"
              "notifications"
            ];
          };
        };
      };

      override = {
        "bar.media.show_active_only" = true;
        "bar.workspaces.applicationIconEmptyWorkspace" = "";
        "bar.workspaces.hideUnoccupied" = false;
        "bar.workspaces.monitorSpecific" = false;
        "bar.workspaces.numbered_active_indicator" = "color";
        "bar.workspaces.workspaces" = 5;
        "menus.power.lowBatteryNotification" = true;
        "theme.bar.buttons.monochrome" = true;
        "theme.bar.dropdownGap" = "4.5em";
        "theme.bar.location" = "bottom";
        "theme.bar.menus.monochrome" = true;
        "theme.bar.opacity" = opacity;
        "theme.bar.transparrent" = true;
        "theme.font.name" = "${font}";
        "theme.font.size" = "${fontSize}px";
        "theme.matugen" = true;
        "theme.matugen_settings.scheme_type" = "content";
        "wallpaper.image" = config.stylix.image;
        "wallpaper.pywal" = true;
      };
    };

    programs.ags = {
      enable = true;

      extraPackages = with pkgs; [
        gtksourceview
        webkitgtk
        accountsservice
      ];
    };
  };
}
