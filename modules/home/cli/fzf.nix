{
  lib,
  config,
  ...
}: {
  options = {
    fzf.use = lib.mkEnableOption "enables fzf";
  };

  config = lib.mkIf config.fzf.use {
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultOptions = [
        "--info=inline"
        "--border=rounded"
        "--height=40%"
        "--layout reverse"
      ];
    };
  };
}
