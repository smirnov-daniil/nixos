{lib, ...}: {
  imports = [
    ./oh-my-posh.nix
    ./qt.nix
    ./stylix.nix
  ];

  theme.oh-my-posh.enable = lib.mkDefault true;
  theme.qt.enable = lib.mkDefault true;
  theme.stylix.enable = lib.mkDefault true;
}
