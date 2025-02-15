{lib, ...}: {
  imports = [
    ./oh-my-posh.nix
    ./qt.nix
    ./stylix.nix
  ];

  oh-my-posh.use = lib.mkDefault true;
  qt.use = lib.mkDefault true;
  stylix.use = lib.mkDefault true;
}
