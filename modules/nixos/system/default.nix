{lib, ...}:{
  imports = [
    ./env.nix
    ./nh.nix
    ./nix.nix
    ./stylix.nix
    ./timezone.nix
    ./user.nix
  ];

  main-user.enable = lib.mkDefault false;
}
