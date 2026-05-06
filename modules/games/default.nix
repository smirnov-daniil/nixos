{lib, ...}: {
  imports = [
    ./steam.nix
  ];

  games.steam.enable = lib.mkDefault true;
}
