{
  lib,
  config,
  ...
}: {
  options = {
    zsh.use = lib.mkEnableOption "enables zsh";
  };

  config = lib.mkIf config.zsh.use {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      shellAliases = {
        sw = "nh os switch";
        upd = "nh os switch --update";
        hms = "nh home switch";

        n = "nvim";
        se = "sudoedit";

        nixshell = "nix-shell --command zsh";

        microfetch = "microfetch && echo";

        z = "cd";
        zz = "cd -";

        ".." = "cd ..";
      };

      history.size = 10000;
      history.path = "${config.xdg.dataHome}/zsh/history";

      initContent = ''
        # Start UWSM
        if uwsm check may-start > /dev/null && uwsm select; then
          exec systemd-cat -t uwsm-start uwsm start default
        fi
      '';

      oh-my-zsh = {
        enable = true;
        plugins = [
          "rbw"
        ];
      };
    };
  };
}
