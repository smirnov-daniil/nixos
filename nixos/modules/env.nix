{inputs, ...}: {
  environment = {
    sessionVariables = rec {
      TERMINAL = "ghostty";
      EDITOR = "hx";
      XDG_BIN_HOME = "$HOME/.local/bin";
      PATH = [
        "${XDG_BIN_HOME}"
      ];
    };
  };
}
