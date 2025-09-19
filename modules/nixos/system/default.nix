{lib, ...}: {
  imports = [
    ./env.nix
    ./nh.nix
    ./nix.nix
    ./timezone.nix
    ./user.nix
  ];

  main-user.enable = lib.mkDefault false;
}
