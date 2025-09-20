{lib, ...}: {
  imports = [
    ./vscode.nix
    ./packages.nix
  ];

  gui.vscode.enable = lib.mkDefault true;
  gui.media.enable = lib.mkDefault true;
  gui.browser.enable = lib.mkDefault true;
  gui.idea.enable = lib.mkDefault false;
  gui.obs.enable = lib.mkDefault true;
  gui.telegram.enable = lib.mkDefault true;
  gui.localsend.enable = lib.mkDefault true;
}
