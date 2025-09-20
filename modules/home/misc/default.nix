{lib, ...}: {
  imports = [
    ./vscode-server.nix
  ];

  misc.vscode-server.enable = lib.mkDefault false;
}
