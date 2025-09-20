{
  config,
  lib,
  ...
}: {
  services.xserver.videoDrivers = ["nvidia"];

  # hardware.graphics.enable = true;

  hardware.nvidia = {
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.production;

    modesetting.enable = true;

    powerManagement = {
      enable = true;
      finegrained = true;
    };

    dynamicBoost.enable = true;

    nvidiaSettings = true;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      sync.enable = lib.mkDefault false;

      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  #specialisation = {
  #  graphics.configuration = {
  #    system.nixos.tags = ["graphics"];
  #    hardware.nvidia = {
  #      powerManagement = {
  #        finegrained = lib.mkForce false;
  #      };

  #      prime = {
  #        offload = {
  #          enable = lib.mkForce false;
  #          enableOffloadCmd = lib.mkForce false;
  #        };
  #        sync.enable = lib.mkForce true;
  #      };
  #    };
  #  };
  #};
}
