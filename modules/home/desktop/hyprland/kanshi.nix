{
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.hyprland.use {
    services.kanshi = {
      enable = true;
      systemdTarget = "";
      settings = [
        {
          profile = {
            name = "default";
            outputs = [
              {
                criteria = "eDP-1";
                mode = "1920x1080@60.00Hz";
                position = "0,0";
                scale = 1.0;
              }
            ];
          };
        }
        {
          profile = {
            name = "performance";
            outputs = [
              {
                criteria = "eDP-1";
                mode = "1920x1080@144.00Hz";
                position = "0,0";
              }
            ];
          };
        }
        {
          profile = {
            name = "home";
            outputs = [
              {
                criteria = "eDP-1";
                status = "disable";
              }
              {
                criteria = "HDMI-A-1";
                mode = "2560x1440@143.91Hz";
                position = "0,0";
              }
            ];
          };
        }
      ];
    };
  };
}
