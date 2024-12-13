{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "JetBrains Mono";
        use-bold = "yes";
      };
      colors = {
        background = "#282828ff";
        text = "#ebdbb2ff";
        prompt = "ebdbb2ff";
        placeholder = "#928374ff";
        input = "#928374ff";
        match = "#cb4b16ff";
        selection = "#ebdbb2ff";
        selection-text = "#282828ff";
        # selection-match = "cb4b16ff";
        # counter = "93a1a1ff";
        border = "d65d0eff";
      };
      border = {
        width = 5;
        radius = 0;
      };
    };
  };
}
