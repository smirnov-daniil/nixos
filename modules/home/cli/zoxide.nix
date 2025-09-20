{
  lib,
  config,
  ...
}: {
  options = {
    cli.zoxide.enable = lib.mkEnableOption "enables zoxide";
  };

  config = lib.mkIf config.cli.zoxide.enable {
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [
        "--cmd cd"
      ];
    };
  };
}
