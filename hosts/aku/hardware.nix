{
  flake.nixosModules.aku = {
    config,
    lib,
    pkgs,
    modulesPath,
    ...
  }: {
    boot = {
      initrd.availableKernelModules = ["virtio_pci"];
      initrd.kernelModules = [];
      kernelModules = ["kvm-amd"];
      extraModulePackages = [];
    };

    fileSystems = {
      "/lib/modules/6.6.114.1-microsoft-standard-WSL2" = {
        device = "none";
        fsType = "overlay";
      };

      "/mnt/wsl" = {
        device = "none";
        fsType = "tmpfs";
      };

      "/usr/lib/wsl/drivers" = {
        device = "drivers";
        fsType = "9p";
      };

      "/" = {
        device = "/dev/disk/by-uuid/bafbf1b6-0b43-4f06-ab9f-1a0aaafe9cb1";
        fsType = "ext4";
      };

      "/mnt/wslg" = {
        device = "none";
        fsType = "tmpfs";
      };

      "/mnt/wslg/distro" = {
        device = "none";
        fsType = "none";
        options = ["bind"];
      };

      "/usr/lib/wsl/lib" = {
        device = "none";
        fsType = "overlay";
      };

      "/tmp/.X11-unix" = {
        device = "/mnt/wslg/.X11-unix";
        fsType = "none";
        options = ["bind"];
      };

      "/mnt/wslg/doc" = {
        device = "none";
        fsType = "overlay";
      };

      "/mnt/c" = {
        device = "C:\134";
        fsType = "9p";
      };

      "/mnt/d" = {
        device = "D:\134";
        fsType = "9p";
      };

      "/mnt/e" = {
        device = "E:\134";
        fsType = "9p";
      };

      "/mnt/h" = {
        device = "H:\134";
        fsType = "9p";
      };

      "/mnt/z" = {
        device = "Z:\134";
        fsType = "9p";
      };

      "/mnt/wslg/run/user/1000" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [
          "uid=1000" # Change 1000 to your user's specific UID
          "gid=100" # Change 100 to your user's primary GID (usually 'users' or 'wheel')
        ];
      };
    };

    swapDevices = [
      {device = "/dev/disk/by-uuid/78ee9002-9743-4fc8-bcab-f42490941120";}
    ];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
