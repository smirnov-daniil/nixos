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
      self.nixosModules.browsec
      self.nixosModules.deploy-rs-initiator
      inputs.sops-nix.nixosModules.default
    ];
    system.stateVersion = "25.11";
    preferences = {
      hostname = "gru";
      niri.renderDrmDevice = "/dev/dri/by-path/pci-0000:00:02.0-render";
    };
    programs.browsec.users = [config.preferences.user.name];
    features.deploy-rs.initiator.enable = true;
    sops = {
      defaultSopsFile = ./secrets/secrets.yaml;
      defaultSopsFormat = "yaml";
      age.keyFile = "/home/${config.preferences.user.name}/.config/sops/age/keys.txt";
    };

    services = {
      xserver.videoDrivers = [
        "modesetting"
        "nvidia"
      ];
      fstrim.enable = true;
      fwupd.enable = true;
      thermald.enable = true;
    };
    zramSwap.enable = true;
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

      loader = {
        limine = {
          enable = true;
          efiSupport = true;
          biosSupport = false;
          efiInstallAsRemovable = false;
          enableEditor = false;
          maxGenerations = 10;
        };
        efi.canTouchEfiVariables = true; # let NixOS add a boot entry
      };

      supportedFilesystems.ntfs = true;
    };

    xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];
    xdg.portal.enable = true;
  };
}
