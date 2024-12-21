{
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
              position = "0,0";
              scale = 0.8;
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
              criteria = "*";
              position = "0,0";
            }
          ];
        };
      }
    ];
  };
}
