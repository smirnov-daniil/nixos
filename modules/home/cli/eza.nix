{
  lib,
  config,
  ...
}: {
  options = {
    cli.eza.enable = lib.mkEnableOption "enables eza";
  };

  config = lib.mkIf config.cli.eza.enable {
    programs.eza = {
      enable = true;
      enableZshIntegration = true;
      colors = "always";
      git = true;
      icons = "always";
      extraOptions = [
        "--group-directories-first"
      ];
    };
  };
}
