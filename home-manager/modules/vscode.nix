{ pkgs, ... }: {
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        arrterian.nix-env-selector 
        xaver.clang-format
        twxs.cmake
      ] ++ (with import <unstable> {};
      with pkgs.vscode-extensions; [
        ms-vscode.cpptools
      ]
    );
  };
}
