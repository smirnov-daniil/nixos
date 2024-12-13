{
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
  }; 
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  hardware.graphics.enable = true;

  hardware.nvidia = {
    open = true;

    modesetting.enable = true;

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      intelBusId = "PCI:0:2:0";

      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
