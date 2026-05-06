# configuration.nix (or wherever your hardware config lives)
{
  config,
  lib,
  ...
}: {
  services.xserver.videoDrivers = ["nvidia"];
  hardware.graphics.enable = true;
  programs.steam.enable = true;

  # --- DEFAULT BOOT: Normal Desktop (Prime Offload) ---
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

  # --- GAMING BOOT: Jovian Steam Deck Environment ---
  specialisation = {
    steamdeck.configuration = {
      system.nixos.tags = ["jovian-steamdeck"];

      # 1. Force NVIDIA to Sync Mode
      hardware.nvidia = {
        powerManagement.finegrained = lib.mkForce false;
        prime = {
          offload = {
            enable = lib.mkForce false;
            enableOffloadCmd = lib.mkForce false;
          };
          sync.enable = lib.mkForce true;
        };
      };

      # 2. Enable Jovian-NixOS Features
      jovian = {
        steam = {
          enable = true;
          autoStart = true;
          user = "ds2"; # Replace with your actual user

          # Optional: Define what happens when you click "Switch to Desktop"
          # desktopSession = "plasma";
          desktopSession = "hyprland-uwsm";
        };

        steamos = {
          # Use SteamOS-specific kernel patches and sysctl tweaks
          useSteamOSConfig = true;
        };

        # Explicitly disable hardware-specific deck features since you are on an Intel/Nvidia machine
        devices.steamdeck.enable = false;
      };

      # Disable the standard display manager to let Jovian handle the boot sequence directly
      services.displayManager.autoLogin = {
        enable = true;
        user = "ds2"; # Replace with your user
      };
    };
  };
}
