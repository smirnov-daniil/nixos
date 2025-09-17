{
  lib,
  config,
  ...
}: {
  options = {
    eza.use = lib.mkEnableOption "enables eza";
  };

  config = lib.mkIf config.eza.use {
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
