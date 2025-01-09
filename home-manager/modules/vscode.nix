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
      jnoortheen.nix-ide
      arrterian.nix-env-selector

      # C++
      ms-vscode.cpptools
      xaver.clang-format
      twxs.cmake

      # Utility
      alefragnani.bookmarks

      # Typst
      myriad-dreamin.tinymist
    ];
  };
}
