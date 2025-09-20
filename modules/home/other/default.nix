{lib, ...}: {
  imports = [
    ./vscode-server.nix
  ];

  vscode-server.enable = lib.mkDefault false;
}
