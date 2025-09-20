{lib, ...}: {
  imports = [
    ./oh-my-posh.nix
    ./qt.nix
    ./stylix.nix
  ];

  oh-my-posh.enable = lib.mkDefault true;
  qt.enable = lib.mkDefault true;
  stylix.enable = lib.mkDefault true;
}
