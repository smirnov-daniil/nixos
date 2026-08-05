{
  inputs,
  self,
  ...
}: {
  flake.wrappersModules.niri = {
    config,
    lib,
    pkgs,
    ...
  }: let
    selfpkgs = self.packages.${config.pkgs.stdenv.hostPlatform.system};
    quickshellExe = lib.getExe config.quickshell;
    # Media keys must not depend on session PATH — bare `wpctl` silently
    # fails when wireplumber's bin isn't in systemPackages.
    wpctl = "${config.pkgs.wireplumber}/bin/wpctl";
    playerctl = lib.getExe config.pkgs.playerctl;
    clipboardWatcher = config.pkgs.writeShellApplication {
      name = "clipboard-watcher";
      runtimeInputs = [config.pkgs.cliphist config.pkgs.wl-clipboard];
      text = ''
        exec wl-paste --watch cliphist store
      '';
    };

    # Named workspaces w0..w9, reachable with Mod+1..Mod+0.
    workspaceNames = map (i: "w${toString i}") (lib.range 0 9);
    workspaceKey = i:
      if i == 9
      then "0"
      else toString (i + 1);
    workspaceBinds = lib.mergeAttrsList (lib.imap0 (i: name: {
        "Mod+${workspaceKey i}".focus-workspace = name;
        "Mod+Shift+${workspaceKey i}".move-column-to-workspace = name;
      })
      workspaceNames);
  in {
    options.terminal = lib.mkOption {
      type = lib.types.str;
      default = "ghostty";
    };
    options.quickshell = lib.mkOption {
      type = lib.types.package;
      default = selfpkgs.quickshellWrapped;
    };
    options.autostart = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.package);
      default = [];
      description = "Extra commands/packages to spawn at niri startup.";
    };
    options.renderDrmDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    config = {
      # The quickshell bar/launcher/notifications are part of the desktop.
      autostart = [config.quickshell clipboardWatcher];

      settings = {
        prefer-no-csd = {};
        debug = lib.mkIf (config.renderDrmDevice != null) {
          render-drm-device = config.renderDrmDevice;
        };

        input = {
          focus-follows-mouse = {};

          keyboard = {
            xkb = {
              layout = "us,ru";
              options = "grp:alt_shift_toggle,caps:escape";
            };
            repeat-rate = 40;
            repeat-delay = 250;
          };

          touchpad = {
            natural-scroll = {};
            tap = {};
          };

          mouse = {
            accel-profile = "flat";
          };
        };

        binds =
          workspaceBinds
          // {
            "Mod+Return".spawn = config.terminal;

            "Mod+Q".close-window = {};
            "Mod+F".maximize-column = {};
            "Mod+G".fullscreen-window = {};
            "Mod+O".toggle-overview = {};
            "Mod+Shift+F".toggle-window-floating = {};
            "Mod+C".center-column = {};

            "Mod+H".focus-column-left = {};
            "Mod+L".focus-column-right = {};
            "Mod+K".focus-window-up = {};
            "Mod+J".focus-window-down = {};

            "Mod+Left".focus-column-left = {};
            "Mod+Right".focus-column-right = {};
            "Mod+Up".focus-window-up = {};
            "Mod+Down".focus-window-down = {};

            "Mod+Shift+H".move-column-left = {};
            "Mod+Shift+L".move-column-right = {};
            "Mod+Shift+K".move-window-up = {};
            "Mod+Shift+J".move-window-down = {};

            "Mod+S".spawn-sh = "${quickshellExe} ipc call launcher toggle";
            "Mod+N".spawn-sh = "${quickshellExe} ipc call history toggle";
            "Mod+V".spawn-sh = "${quickshellExe} ipc call clipboard toggle";
            "Mod+Tab".spawn-sh = "${quickshellExe} ipc call windows toggle";
            "Mod+Escape".spawn-sh = "${quickshellExe} ipc call session toggle";
            "Mod+Ctrl+V".spawn-sh = "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle";

            "XF86AudioRaiseVolume".spawn-sh = "${wpctl} set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+";
            "XF86AudioLowerVolume".spawn-sh = "${wpctl} set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-";
            "XF86AudioMute".spawn-sh = "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";
            "XF86AudioMicMute".spawn-sh = "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
            "XF86AudioPlay".spawn-sh = "${playerctl} play-pause";
            "XF86AudioPause".spawn-sh = "${playerctl} play-pause";
            "XF86AudioNext".spawn-sh = "${playerctl} next";
            "XF86AudioPrev".spawn-sh = "${playerctl} previous";
            "XF86MonBrightnessUp".spawn-sh = "${lib.getExe config.pkgs.brightnessctl} set 5%+";
            "XF86MonBrightnessDown".spawn-sh = "${lib.getExe config.pkgs.brightnessctl} set 5%-";

            "Mod+Ctrl+H".set-column-width = "-5%";
            "Mod+Ctrl+L".set-column-width = "+5%";
            "Mod+Ctrl+J".set-window-height = "-5%";
            "Mod+Ctrl+K".set-window-height = "+5%";

            "Mod+WheelScrollDown".focus-column-left = {};
            "Mod+WheelScrollUp".focus-column-right = {};
            "Mod+Ctrl+WheelScrollDown".focus-workspace-down = {};
            "Mod+Ctrl+WheelScrollUp".focus-workspace-up = {};

            "Mod+Ctrl+S".spawn-sh = "${lib.getExe config.pkgs.grim} -l 0 - | ${config.pkgs.wl-clipboard}/bin/wl-copy";

            "Mod+Shift+E".spawn-sh = "${config.pkgs.wl-clipboard}/bin/wl-paste | ${lib.getExe config.pkgs.swappy} -f -";

            "Mod+Shift+S".spawn-sh = lib.getExe (config.pkgs.writeShellApplication {
              name = "screenshot";
              text = ''
                ${lib.getExe config.pkgs.grim} -g "$(${lib.getExe config.pkgs.slurp} -w 0)" - \
                | ${config.pkgs.wl-clipboard}/bin/wl-copy
              '';
            });

            "Mod+d".spawn-sh = self.mkWhichKeyExe config.pkgs [
              {
                key = "c";
                desc = "Control center";
                cmd = "${quickshellExe} ipc call controlcenter toggle";
              }
              {
                key = "n";
                desc = "Notifications";
                cmd = "${quickshellExe} ipc call history toggle";
              }
              {
                key = "v";
                desc = "Clipboard";
                cmd = "${quickshellExe} ipc call clipboard toggle";
              }
              {
                key = "w";
                desc = "Windows";
                cmd = "${quickshellExe} ipc call windows toggle";
              }
              {
                key = "f";
                desc = "Firefox";
                cmd = "firefox";
              }
              {
                key = "t";
                desc = "Telegram";
                cmd = "Telegram";
              }
              {
                key = "d";
                desc = "Discord";
                cmd = "vesktop";
              }
              {
                key = "m";
                desc = "Youtube Music";
                cmd = "pear-desktop";
              }
              {
                key = "s";
                desc = "Pavucontrol";
                cmd = lib.getExe config.pkgs.pavucontrol;
              }
            ];
          };

        layout = {
          gaps = 5;

          focus-ring = {
            width = 2;
            active-color = "#${self.themeNoHash.base09}";
          };
        };

        workspaces = lib.genAttrs workspaceNames (_: {layout.gaps = 5;});

        xwayland-satellite.path =
          lib.getExe config.pkgs.xwayland-satellite;

        spawn-at-startup = map (entry:
          if lib.isDerivation entry
          then lib.getExe entry
          else entry)
        config.autostart;
      };
    };
  };

  perSystem = {pkgs, ...}: {
    packages.niri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs;
      imports = [self.wrappersModules.niri];
    };
  };
}
