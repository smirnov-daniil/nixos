{
  lib,
  config,
  ...
}: {
  options = {
    cli.fzf.enable = lib.mkEnableOption "enables fzf";
  };

  config = lib.mkIf config.cli.fzf.enable {
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
