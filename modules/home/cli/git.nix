{
  lib,
  config,
  ...
}: {
  options = {
    cli.git.enable = lib.mkEnableOption "enables git";
  };

  config = lib.mkIf config.cli.git.enable {
    programs.git = {
      enable = true;
      userName = "Daniil Smirnov";
      userEmail = "dsmirnov.ds2+github@yandex.com";

      aliases = {
        ci = "commit";
        st = "status";
        co = "checkout";
        br = "branch";
        sw = "switch";
        lg = "log --oneline --graph --decorate --all";
      };

      extraConfig = {
        pull = {
          rebase = true;
        };
      };
    };
  };
}
