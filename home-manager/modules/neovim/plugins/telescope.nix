{
  programs.nixvim.plugins = {
    telescope = {
      enable = true;

      settings.defaults = {
        file_ignore_patterns = [
          "^.git/"
        ];
      };
    };
    web-devicons.enable = true;
  };
}
