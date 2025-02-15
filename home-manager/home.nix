{
  homeStateVersion,
  user,
  ...
}: {
  imports = [
    ./home-packages.nix
  ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = homeStateVersion;
  };
}
