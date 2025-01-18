{ config, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases =
      let
        flakeDir = "~/flake";
      in
      {
        sw = "nh os switch";
        upd = "nh os switch --update";
        hms = "nh home switch";

        pkgs = "nvim ${flakeDir}/nixos/packages.nix";

        n = "nvim";
        se = "sudoedit";
        microfetch = "microfetch && echo";
        
        ls = "exa --oneline";
        ll = "exa --all --header --long";
        tree = "exa --tree";

        z = "cd";
        zz = "cd -";

        ".." = "cd ..";
      };

    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";

    initExtra = ''
      # Start Tmux automatically if not already running. No Tmux in TTY
      if [ -z "$TMUX" ] && [ -n "$DISPLAY" ]; then
        tmux attach-session -t default || tmux new-session -s default
      fi

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
}
