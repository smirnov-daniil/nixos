{lib, ...}: {
  imports = [
    ./vscode.nix
    ./packages.nix
  ];

  vscode.enable = lib.mkDefault true;
  media.enable = lib.mkDefault true;
  browser.enable = lib.mkDefault true;
  idea.enable = lib.mkDefault false;
  obs.enable = lib.mkDefault true;
  telegram.enable = lib.mkDefault true;
  localsend.enable = lib.mkDefault true;
}
