{lib, ...}: {
  imports = [
    ./vscode.nix
  ];

  vscode.use = lib.mkDefault true;
}
