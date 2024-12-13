{ pkgs, config, ... }:

{
  programs.lf = {
    enable = true;

    commands = {
      editor-open = "$EDITROR"
    };
  };
}
