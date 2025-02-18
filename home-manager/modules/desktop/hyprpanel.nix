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

      layout = {
        "bar.layouts" = {
          "0" = {
            "left" = ["windowtitle"];
            "middle" = ["workspaces"];
            "right" = [
              "systray"
              "volume"
              "bluetooth"
              "battery"
              "network"
              "clock"
              "notifications"
            ];
          };
        };
      };

      override = {
        "theme.font.name" = "${font}";
        "theme.font.size" = "${fontSize}px";
        "theme.bar.outer_spacing" = 0;
        "theme.bar.buttons.y_margins" = 0;
        "theme.bar.buttons.spacing" = "0.3em";
        "theme.bar.buttons.padding_x" = "0.8rem";
        "theme.bar.buttons.padding_y" = "0.4rem";
        "theme.bar.buttons.workspaces.hover" = "${accent-alt}";
        "theme.bar.buttons.workspaces.active" = "${accent}";
        "theme.bar.buttons.workspaces.available" = "${accent-alt}";
        "theme.bar.buttons.workspaces.occupied" = "${accent-alt}";
        "theme.bar.menus.monochrome" = true;
        "theme.bar.transparent" = true;
        "theme.bar.menus.background" = "${background}";
        "theme.bar.menus.cards" = "${background-alt}";
        "theme.bar.menus.label" = "${foreground}";
        "theme.bar.menus.text" = "${foreground}";
        "theme.bar.menus.border.color" = "${accent}";
        "theme.bar.menus.popover.text" = "${foreground}";
        "theme.bar.menus.popover.background" = "${background-alt}";
        "theme.bar.menus.listitems.active" = "${accent}";
        "theme.bar.menus.icons.active" = "${accent}";
        "theme.bar.menus.switch.enabled" = "${accent}";
        "theme.bar.menus.check_radio_button.active" = "${accent}";
        "theme.bar.menus.buttons.default" = "${accent}";
        "theme.bar.menus.buttons.active" = "${accent}";
        "theme.bar.menus.iconbuttons.active" = "${accent}";
        "theme.bar.menus.progressbar.foreground" = "${accent}";
        "theme.bar.menus.slider.primary" = "${accent}";
        "theme.bar.menus.tooltip.background" = "${background-alt}";
        "theme.bar.menus.tooltip.text" = "${foreground}";
        "theme.bar.menus.dropdownmenu.background" = "${background-alt}";
        "theme.bar.menus.dropdownmenu.text" = "${foreground}";
        "theme.bar.background" = "${background}";
        "theme.bar.buttons.style" = "default";
        "theme.bar.buttons.monochrome" = true;
        "theme.bar.buttons.text" = "${foreground}";
        "theme.bar.buttons.background" = "${background-alt}";
        "theme.bar.buttons.icon" = "${accent}";
        "theme.bar.buttons.notifications.background" = "${background-alt}";
        "theme.bar.buttons.hover" = "${background}";
        "theme.bar.buttons.notifications.hover" = "${background}";
        "theme.bar.buttons.notifications.total" = "${accent}";
        "theme.bar.buttons.notifications.icon" = "${accent}";
        "theme.notification.background" = "${background-alt}";
        "theme.notification.actions.background" = "${accent}";
        "theme.notification.actions.text" = "${foreground}";
        "theme.notification.label" = "${accent}";
        "theme.notification.border" = "${background-alt}";
        "theme.notification.text" = "${foreground}";
        "theme.notification.labelicon" = "${accent}";
        "theme.osd.bar_color" = "${accent}";
        "theme.osd.bar_overflow_color" = "${accent-alt}";
        "theme.osd.icon" = "${background}";
        "theme.osd.icon_container" = "${accent}";
        "theme.osd.label" = "${accent}";
        "theme.osd.bar_container" = "${background-alt}";
        "theme.bar.menus.menu.media.background.color" = "${background-alt}";
        "theme.bar.menus.menu.media.card.color" = "${background-alt}";
        "theme.bar.menus.menu.media.card.tint" = 90;
        "bar.customModules.updates.pollingInterval" = 1440000;
        "bar.media.show_active_only" = true;
        "theme.bar.location" = "bottom";
        "bar.workspaces.numbered_active_indicator" = "color";
        "bar.workspaces.applicationIconEmptyWorkspace" = "";
        "bar.workspaces.showApplicationIcons" = true;
        "bar.workspaces.showWsIcons" = true;
        "bar.workspaces.workspaces" = 5;
        "bar.workspaces.hideUnoccupied" = false;
        "bar.workspaces.show_numbered" = false;
        "bar.workspaces.monitorSpecific" = false;
        "theme.bar.dropdownGap" = "4.5em";
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
