{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.gru = {
    pkgs,
    config,
    lib,
    ...
  }: {
    imports = [
      self.nixosModules.base
      self.nixosModules.general
      self.nixosModules.intel
      self.nixosModules.desktop
      inputs.sops-nix.nixosModules.default
    ];
    system.stateVersion = "25.11";
    networking = {
      hostName = "gru";
      networkmanager.enable = true;
    };
    sops = {
      defaultSopsFile = ./secrets/secrets.yaml;
      defaultSopsFormat = "yaml";
      age.keyFile = "/home/${config.preferences.user.name}/.config/sops/age/keys.txt";
    };

    services.xserver.videoDrivers = ["nvidia"];
    hardware.graphics.enable = true;

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

    boot = {
      kernelPackages = pkgs.linuxPackages_latest;

      loader.grub.enable = true;
      loader.grub.devices = ["nodev"];
      loader.grub.efiSupport = true;
      loader.efi.canTouchEfiVariables = true; # let NixOS add a boot entry

      supportedFilesystems.ntfs = true;
    };

    xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];
    xdg.portal.enable = true;

    programs.niri.enable = true;
  };
}
