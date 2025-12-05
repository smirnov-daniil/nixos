{config, ...}: {
  sops.secrets.xray = {
    #      owner = "xray";
  };

  services.xray = {
    enable = true;
    settingsFile = config.sops.secrets.xray.path;
  };
}
