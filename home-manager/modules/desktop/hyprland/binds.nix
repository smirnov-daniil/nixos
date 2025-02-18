{
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.hyprland.use {
    wayland.windowManager.hyprland.settings = {
      bind = [
        "$mainMod SHIFT, Return, exec, $terminal"
        "$mainMod SHIFT, C, killactive,"
        "$mainMod SHIFT, Q, exec, uwsm stop"
        "$mainMod,       E, exec, $fileManager"
        "$mainMod,   SPACE, exec, $menu --show drun"
        "$mainMod,       P, pseudo,"
        "$mainMod,       J, togglesplit,"
        "$mainMod,       V, exec, cliphist list | $menu --dmenu | cliphist decode | wl-copy"
        "$mainMod,       B, exec, hyprpanel toggleWindow bar-0"
        "$mainMod,       L, exec, loginctl lock-session"

        # Configuration files
        ", Print, exec, grimblast --notify --freeze copysave area"

        # Moving focus
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        # Moving windows
        "$mainMod SHIFT, left,  swapwindow, l"
        "$mainMod SHIFT, right, swapwindow, r"
        "$mainMod SHIFT, up,    swapwindow, u"
        "$mainMod SHIFT, down,  swapwindow, d"

        # Resizeing windows                   X  Y
        "$mainMod CTRL, left,  resizeactive, -60 0"
        "$mainMod CTRL, right, resizeactive,  60 0"
        "$mainMod CTRL, up,    resizeactive,  0 -60"
        "$mainMod CTRL, down,  resizeactive,  0  60"

        # Switching workspaces
        "$mainMod, 1, focusworkspaceoncurrentmonitor, 1"
        "$mainMod, 2, focusworkspaceoncurrentmonitor, 2"
        "$mainMod, 3, focusworkspaceoncurrentmonitor, 3"
        "$mainMod, 4, focusworkspaceoncurrentmonitor, 4"
        "$mainMod, 5, focusworkspaceoncurrentmonitor, 5"
        "$mainMod, 6, focusworkspaceoncurrentmonitor, 6"
        "$mainMod, 7, focusworkspaceoncurrentmonitor, 7"
        "$mainMod, 8, focusworkspaceoncurrentmonitor, 8"
        "$mainMod, 9, focusworkspaceoncurrentmonitor, 9"
        "$mainMod, 0, focusworkspaceoncurrentmonitor, 10"

        # Moving windows to workspaces
        "$mainMod SHIFT, 1, movetoworkspacesilent, 1"
        "$mainMod SHIFT, 2, movetoworkspacesilent, 2"
        "$mainMod SHIFT, 3, movetoworkspacesilent, 3"
        "$mainMod SHIFT, 4, movetoworkspacesilent, 4"
        "$mainMod SHIFT, 5, movetoworkspacesilent, 5"
        "$mainMod SHIFT, 6, movetoworkspacesilent, 6"
        "$mainMod SHIFT, 7, movetoworkspacesilent, 7"
        "$mainMod SHIFT, 8, movetoworkspacesilent, 8"
        "$mainMod SHIFT, 9, movetoworkspacesilent, 9"
        "$mainMod SHIFT, 0, movetoworkspacesilent, 10"

        # Scratchpad
        "$mainMod,       S, togglespecialworkspace,  magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"
      ];

      # Move/resize windows with mainMod + LMB/RMB and dragging
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      # Laptop multimedia keys for volume and LCD brightness
      bindel = [
        ",XF86AudioRaiseVolume,  exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume,  exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute,         exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioMicMute,      exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ",XF86AudioMicMute,      exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ",XF86MonBrightnessUp,   exec, brightnessctl s 10%+"
        ",XF86MonBrightnessDown, exec, brightnessctl s 10%-"
      ];
    };
  };
}
