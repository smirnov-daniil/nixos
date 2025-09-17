{lib, ...}: {
  imports = [
    ./vscode.nix
    ./packages.nix
  ];

  gui.use = lib.mkDefault true;

  vscode.use = lib.mkDefault gui.use;
  media.use = lib.mkDefault gui.use;
  browser.use = lib.mkDefault gui.use;
  idea.use = lib.mkDefault gui.use;
  obs.use = lib.mkDefault gui.use;
  telegram.use = lib.mkDefault gui.use;
  localsend.use = lib.mkDefault gui.use;
}
