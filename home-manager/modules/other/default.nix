{lib, ...}: {
  imports = [
    ./vscode-server.nix
  ];

  vscode-server.use = lib.mkDefault false;
}
