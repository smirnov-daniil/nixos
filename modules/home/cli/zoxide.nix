{
  lib,
  config,
  ...
}: {
  options = {
    zoxide.use = lib.mkEnableOption "enables zoxide";
  };

  config = lib.mkIf config.zoxide.use {
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [
        "--cmd cd"
      ];
    };
  };
}
