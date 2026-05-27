{
  flake.nixosModules.lich = {
    config,
    lib,
    pkgs,
    modulesPath,
    ...
  }: {
    imports = [];

    boot.initrd.availableKernelModules = [];
    boot.initrd.kernelModules = [];
    boot.kernelModules = ["kvm-amd"];
    boot.extraModulePackages = [];

    # fileSystems."/lib/modules/6.6.87.2-microsoft-standard-WSL2" = {
    #   device = "none";
    #   fsType = "overlay";
    # };

    fileSystems."/mnt/wsl" = {
      device = "none";
      fsType = "tmpfs";
    };

    fileSystems."/usr/lib/wsl/drivers" = {
      device = "drivers";
      fsType = "9p";
    };

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/e744ca5c-2d3c-4290-a361-4056c7ddc96c";
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

    fileSystems."/mnt/wslg/doc" = {
      device = "none";
      fsType = "overlay";
    };

    fileSystems."/tmp/.X11-unix" = {
      device = "/mnt/wslg/.X11-unix";
      fsType = "none";
      options = ["bind"];
    };

    fileSystems."/mnt/c" = {
      device = "C:\134";
      fsType = "9p";
    };

    fileSystems."/mnt/z" = {
      device = "/dev/disk/by-uuid/2602ef6c-b358-4ad1-9614-a3b3bb75ee58";
      fsType = "ext4";
    };

    fileSystems."/workspace" = {
      device = "/mnt/z/workspace";
      fsType = "none";
      options = ["bind"];
    };

    fileSystems."/mnt/wslg/run/user/1000" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [
        "uid=1000" # Change 1000 to your user's specific UID
        "gid=100" # Change 100 to your user's primary GID (usually 'users' or 'wheel')
      ];
    };

    swapDevices = [
      {device = "/dev/disk/by-uuid/51d7fee0-114e-4695-9521-eae1f44f73af";}
    ];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
