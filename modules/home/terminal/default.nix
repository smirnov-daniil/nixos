{lib, ...}: {
  imports = [
    ./ghostty.nix
    ./tmux.nix
    ./zsh.nix
  ];

  terminal.ghostty.enable = lib.mkDefault true;
  terminal.tmux.enable = lib.mkDefault false;
  terminal.zsh.enable = lib.mkDefault true;
}
