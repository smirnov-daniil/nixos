{lib, ...}: {
  imports = [
    ./eza.nix
    ./fzf.nix
    ./git.nix
    ./helix.nix
    ./packages.nix
    ./ranger.nix
    ./zoxide.nix
  ];

  cli.tools.use = lib.mkDefault true;
  cli.utils.use = lib.mkDefault true;
  eza.use = lib.mkDefault true;
  fzf.use = lib.mkDefault true;
  git.use = lib.mkDefault true;
  ranger.use = lib.mkDefault true;
  zoxide.use = lib.mkDefault true;
  helix.use = lib.mkDefault true;
}
