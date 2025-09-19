{lib, ...}: {
  imports = [
    ./audio.nix
    ./bluetooth.nix
    ./boot.nix
    ./net.nix
    ./zram.nix
  ];
}
