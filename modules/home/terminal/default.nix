{lib, ...}: {
  imports = [
    ./ghostty.nix
    ./tmux.nix
    ./zsh.nix
  ];

  ghostty.use = lib.mkDefault true;
  tmux.use = lib.mkDefault false;
  zsh.use = lib.mkDefault true;
}
