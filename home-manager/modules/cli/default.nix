{lib, ...}: {
  imports = [
    ./eza.nix
    ./git.nix
    ./nvf.nix
    ./packages.nix
    ./ranger.nix
    ./zoxide.nix
  ];

  eza.use = lib.mkDefault true;
  git.use = lib.mkDefault true;
  nvf.use = lib.mkDefault true;
  cli.tools.use = lib.mkDefault true;
  cli.utils.use = lib.mkDefault true;
  ranger.use = lib.mkDefault true;
  zoxide.use = lib.mkDefault true;
}
