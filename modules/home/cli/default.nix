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
  cli.eza.enable = lib.mkDefault true;
  cli.fzf.enable = lib.mkDefault true;
  cli.git.enable = lib.mkDefault true;
  cli.ranger.enable = lib.mkDefault false;
  cli.zoxide.enable = lib.mkDefault true;
  cli.helix.enable = lib.mkDefault true;
}
