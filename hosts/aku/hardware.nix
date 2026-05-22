{
  flake.nixosModules.aku = {
    config,
    lib,
    pkgs,
    modulesPath,
    ...
  }: {
    boot.initrd.availableKernelModules = ["virtio_pci"];
    boot.initrd.kernelModules = [];
    boot.kernelModules = ["kvm-amd"];
    boot.extraModulePackages = [];

    fileSystems."/lib/modules/6.6.114.1-microsoft-standard-WSL2" = {
      device = "none";
      fsType = "overlay";
    };

    fileSystems."/mnt/wsl" = {
      device = "none";
      fsType = "tmpfs";
    };

    fileSystems."/usr/lib/wsl/drivers" = {
      device = "drivers";
      fsType = "9p";
    };

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/bafbf1b6-0b43-4f06-ab9f-1a0aaafe9cb1";
      fsType = "ext4";
    };

    fileSystems."/mnt/wslg" = {
      device = "none";
      fsType = "tmpfs";
    };

    fileSystems."/mnt/wslg/distro" = {
      device = "none";
      fsType = "none";
      options = ["bind"];
    };

    fileSystems."/usr/lib/wsl/lib" = {
      device = "none";
      fsType = "overlay";
    };

    fileSystems."/tmp/.X11-unix" = {
      device = "/mnt/wslg/.X11-unix";
      fsType = "none";
      options = ["bind"];
    };

    fileSystems."/mnt/wslg/doc" = {
      device = "none";
      fsType = "overlay";
    };

    fileSystems."/mnt/c" = {
      device = "C:\134";
      fsType = "9p";
    };

    fileSystems."/mnt/d" = {
      device = "D:\134";
      fsType = "9p";
    };

    fileSystems."/mnt/e" = {
      device = "E:\134";
      fsType = "9p";
    };

    fileSystems."/mnt/h" = {
      device = "H:\134";
      fsType = "9p";
    };

    fileSystems."/mnt/z" = {
      device = "Z:\134";
      fsType = "9p";
    };

    fileSystems."/mnt/wslg/run/user/1001" = {
      device = "tmpfs";
      fsType = "tmpfs";
    };

    swapDevices = [
      {device = "/dev/disk/by-uuid/78ee9002-9743-4fc8-bcab-f42490941120";}
    ];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
