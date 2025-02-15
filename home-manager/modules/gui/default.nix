{lib, ...}: {
  imports = [
    ./vscode.nix
    ./packages.nix
  ];

  vscode.use = lib.mkDefault true;
  media.use = lib.mkDefault true;
  browser.use = lib.mkDefault true;
  idea.use = lib.mkDefault true;
  obs.use = lib.mkDefault true;
  telegram.use = lib.mkDefault true;
  localsend.use = lib.mkDefault true;
}
