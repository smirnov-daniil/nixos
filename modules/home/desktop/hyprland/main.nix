{
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.desktop.hyprland.enable {
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
        #       "$fileManager" = "$terminal -e sh -c 'ranger'";
        "$menu" = "wofi";

        exec-once = [
          "uwsm app -- systemctl --user enable --now hyprpaper.service"
          "uwsm app -- systemctl --user enable --now hypridle.service"
          "kanshi"
          "wl-paste --type text --watch cliphist store"
          "wl-paste --type image --watch cliphist store"
          "$terminal"
          "uwsm app -- quickshell"
          # "caelestia-shell -d"
          # "gBar bar eDP-1"
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

        workspace = [
          "w[tv1], gapsout:0, gapsin:0"
          "f[1], gapsout:0, gapsin:0"
        ];
      };
    };
  };
}
