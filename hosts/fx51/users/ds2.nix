{...}: {
  imports = [
    ../../../modules/home
  ];
  nixpkgs.config.allowUnfree = true;

  home = {
    username = "ds2";
    homeDirectory = "/home/ds2";
    stateVersion = "25.05";
  };
}
