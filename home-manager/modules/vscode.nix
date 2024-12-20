{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;

    userSettings = {
      "editor.formatOnSave" = true;
      "editor.fontLigatures" = true;
      "editor.tabSize" = 2;
      "editor.insertSpaces" = true;
      "editor.detectIndentation" = false;
      "editor.minimap.scale" = 2;
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nixd";
      "workbench.activityBar.location" = "top";
    };

    extensions =
      with pkgs.vscode-marketplace;
      [
        # Nix
        jnoortheen.nix-ide
        arrterian.nix-env-selector

        # C++
        xaver.clang-format
        twxs.cmake

        # Utility
        alefragnani.bookmarks
        cweijan.vscode-office

        # Typst
        mgt19937.typst-preview
        surv.typst-math
      ]
      ++ (
        with import <unstable> { };
        with pkgs.vscode-extensions;
        [
          # C++
          ms-vscode.cpptools
        ]
      );
  };
}
