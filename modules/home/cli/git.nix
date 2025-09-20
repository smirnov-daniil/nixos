{
  lib,
  config,
  ...
}: {
  options = {
    git.use = lib.mkEnableOption "enables git";
  };

  config = lib.mkIf config.git.use {
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
