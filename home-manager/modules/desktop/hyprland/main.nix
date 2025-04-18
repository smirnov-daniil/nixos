{
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.hyprland.use {
    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = false;
      settings = {
        env = [
          # Hint Electron apps to use Wayland
          "NIXOS_OZONE_WL,1"
          "XDG_CURRENT_DESKTOP,Hyprland"
          "XDG_SESSION_TYPE,wayland"
          "XDG_SESSION_DESKTOP,Hyprland"
          "QT_QPA_PLATFORM,wayland"
          "XDG_SCREENSHOTS_DIR,$HOME/screens"
          "AQ_DRM_DEVICES,/dev/dri/card1:/dev/dri/card0"
        ];

        "$mainMod" = "SUPER";
        "$terminal" = "ghostty";
        "$fileManager" = "$terminal -e sh -c 'ranger'";
        "$menu" = "wofi";

        exec-once = [
          "uwsm app -- systemctl --user enable --now hyprpaper.service"
          "uwsm app -- systemctl --user enable --now hypridle.service"
          "kanshi"
          "wl-paste --type text --watch cliphist store"
          "wl-paste --type image --watch cliphist store"
          "$terminal"
        ];

        xwayland.force_zero_scaling = true;

        general = {
          gaps_in = 0;
          gaps_out = 0;

          border_size = 5;

          resize_on_border = true;

          allow_tearing = false;
          layout = "master";
        };

        decoration = {
          rounding = 0;

          shadow = {
            enabled = false;
          };
        };

        animations = {
          enabled = false;
        };

        input = {
          kb_layout = "us,ru";
          kb_options = "grp:caps_toggle";
        };

        gestures = {
          workspace_swipe = true;
          workspace_swipe_invert = false;
          workspace_swipe_forever = true;
        };

        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        master = {
          new_status = "slave";
          new_on_top = true;
          mfact = 0.5;
        };

        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
        };

        windowrulev2 = [
          "bordersize 0, floating:0, onworkspace:w[t1]"

          "float,class:(mpv)|(imv)|(showmethekey-gtk)"
          "move 990 60,size 900 170,pin,noinitialfocus,class:(showmethekey-gtk)"
          "noborder,nofocus,class:(showmethekey-gtk)"

          "workspace 1,class:(zen)"
          "workspace 2,class:(tty)"
          "workspace 3,class:(telegram-desktop)"
          "workspace 4,class:(code)"
          "workspace 4,class:(idea)"
          "workspace 5,class:(com.obsproject.Studio)"

          "suppressevent maximize, class:.*"
          "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"

          "opacity 0.0 override, class:^(xwaylandvideobridge)$"
          "noanim, class:^(xwaylandvideobridge)$"
          "noinitialfocus, class:^(xwaylandvideobridge)$"
          "maxsize 1 1, class:^(xwaylandvideobridge)$"
          "noblur, class:^(xwaylandvideobridge)$"
          "nofocus, class:^(xwaylandvideobridge)$"
        ];

        workspace = [
          "w[tv1], gapsout:0, gapsin:0"
          "f[1], gapsout:0, gapsin:0"
        ];
      };
    };
  };
}
