{
  imports = [
    ./cli
    ./desktop
    ./gui
    ./misc
    ./terminal
    ./theme
  ];
  programs.opencode = {
    enable = true;
    settings = {};
  };
}
