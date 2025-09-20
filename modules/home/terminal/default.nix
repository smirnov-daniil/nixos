{lib, ...}: {
  imports = [
    ./ghostty.nix
    ./tmux.nix
    ./zsh.nix
  ];

  ghostty.enable = lib.mkDefault true;
  tmux.enable = lib.mkDefault false;
  zsh.enable = lib.mkDefault true;
}
