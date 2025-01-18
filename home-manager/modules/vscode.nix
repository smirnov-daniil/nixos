{pkgs, ...}: {
  programs.vscode = {
    enable = true;

    userSettings = {
      "editor.formatOnSave" = true;
      "editor.fontLigatures" = true;
      "editor.tabSize" = 2;
      "editor.insertSpaces" = true;
      "editor.detectIndentation" = false;
      "editor.minimap.scale" = 2;
      "nix.formatterPath" = ["alejandra" "--" "-"];
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nixd";
      "workbench.activityBar.location" = "top";
    };

    extensions = with pkgs.vscode-extensions; [
      # Nix
      arrterian.nix-env-selector
      jnoortheen.nix-ide

      # C++
      ms-vscode.cmake-tools
      ms-vscode.cpptools
      ms-vscode.cpptools-extension-pack
      twxs.cmake
      xaver.clang-format

      # Utility
      alefragnani.bookmarks

      # Typst
      myriad-dreamin.tinymist
    ];
  };
}
