{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;

    userSettings = {
      "editor.formatOnSave" = true;
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nixd";
    };

    extensions =
      with pkgs.vscode-marketplace;
      [
        jnoortheen.nix-ide
        arrterian.nix-env-selector
        xaver.clang-format
        twxs.cmake
      ]
      ++ (
        with import <unstable> { };
        with pkgs.vscode-extensions;
        [
          ms-vscode.cpptools
        ]
      );
  };
}
