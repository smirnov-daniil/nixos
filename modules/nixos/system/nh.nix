{config, ...}: {
  programs.nh = {
    enable = true;
    flake = "/home/${config.main-user.username}/flake";
  };
}
