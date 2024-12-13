{
  environment.sessionVariables = rec {
    TERMINAL = "alacritty";
    EDITOR = "nano";
    XDG_BIN_HOME = "$HOME/.local/bin";
    PATH = [
      "${XDG_BIN_HOME}"
    ];
  };
}
