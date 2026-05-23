{inputs, ...}: {
  flake.nixosModules.wsl = {
    pkgs,
    config,
    ...
  }: {
    imports = [inputs.nixos-wsl.nixosModules.default];
    wsl = {
      enable = true;
      interop.register = true;
      docker-desktop.enable = true;
      defaultUser = "${config.preferences.user.name}";
      startMenuLaunchers = true;
      wslConf = {
        boot.systemd = true;
        # wsl2 = {
        #   networkingMode = "mirrored";
        #   processors = 10;
        #   autoProxy = true;
        #   dnsTunneling = true;
        #   localhostForwarding = true;
        # };
        # experimental = {
        #   autoMemoryReclaim = "gradual";
        #   firewall = true;
        #   bestEffortDnsParsing = true;
        # };
        network = {
          generateResolvConf = false;
          hostname = "${config.preferences.hostname}";
        };
      };
    };

    preferences.monitors.enable = false;
  };
}
