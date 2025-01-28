{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "bottom";
        height = 30; 
#        width = 1240;
        modules-center = [ "hyprland/workspaces" ];
        modules-left = [ "hyprland/window" ];
        modules-right = [
          "hyprland/language"
          "pulseaudio"
          "battery"
          "clock"
          "tray"
        ];
        "hyprland/workspaces" = {
          disable-scroll = true;
          show-special = true;
          special-visible-only = true;
          all-outputs = false;
          format = "{icon}";
          format-icons = {
            "1" = "";
            "2" = "";
            "3" = "";
            "4" = "󰨞";
            "5" = "";
            "6" = " ";
          };

          persistent-workspaces = {
            "*" = 5;
          };
        };

        "hyprland/language" = {
          format-en = "en";
          format-ru = "ru";
          format = "{}";
        };

        "battery" = {
          states = {
            warning = 30;
            critical = 1;
          };
          format = "{icon} {capacity}%";
          format-charging = " {capacity}%";
          format-alt = "{time} {icon}";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
        };

        "tray" = {
          icon-size = 14;
          spacing = 1;
        };

        "clock" = {
           format = "{:%a %H:%M}";
        };

        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-bluetooth = "{icon} {volume}% ";
          format-muted = "";
          format-icons = {
            "headphones" = "";
            "handsfree" = "";
            "headset" = "";
            "phone" = "";
            "portable" = "";
            "car" = "";
            "default" = [
              ""
              ""
            ];
          };
          on-click = "pavucontrol";
        };
      };
    };
  };
}
