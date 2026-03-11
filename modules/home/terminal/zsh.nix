{
  lib,
  config,
  pkgs,
  ...
}: {
  options = {
    terminal.zsh.enable = lib.mkEnableOption "enables zsh";
  };

  config = lib.mkIf config.terminal.zsh.enable {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      shellAliases = {
        sw = "nh os switch";
        upd = "nh os switch --update";
        hms = "nh home switch";

        se = "sudoedit";

        nixshell = "nix-shell --command zsh";

        microfetch = "microfetch && echo";

        z = "cd";
        zz = "cd -";

        ".." = "cd ..";
      };

      history.size = 10000;
      #     history.path = "${config.xdg.dataHome}/zsh/history";

      initContent = ''
        # Start UWSM
        if uwsm check may-start; then
          exec uwsm start hyprland-uwsm.desktop
        fi
      '';

      plugins = [
        {
          name = "fzf-tab";
          src = pkgs.fetchFromGitHub {
            owner = "Aloxaf";
            repo = "fzf-tab";
            rev = "c2b4aa5ad2532cca91f23908ac7f00efb7ff09c9";
            sha256 = "1b4pksrc573aklk71dn2zikiymsvq19bgvamrdffpf7azpq6kxl2";
          };
        }
      ];

      oh-my-zsh = {
        enable = true;
        plugins = [
          "rbw"
        ];
      };
    };
  };
}
