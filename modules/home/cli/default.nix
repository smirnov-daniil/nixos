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

  cli.tools.enable = lib.mkDefault true;
  cli.utils.enable = lib.mkDefault true;
  eza.enable = lib.mkDefault true;
  fzf.enable = lib.mkDefault true;
  git.enable = lib.mkDefault true;
  ranger.enable = lib.mkDefault true;
  zoxide.enable = lib.mkDefault true;
  helix.enable = lib.mkDefault true;
}
