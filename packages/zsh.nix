{
  inputs,
  self,
  lib,
  ...
}: {
  perSystem = {
    pkgs,
    self',
    ...
  }: let
    histdb = pkgs.zsh-histdb.overrideAttrs (old: {
      version = "0-unstable-2026-09-18";
      src = pkgs.fetchFromGitHub {
        owner = "larkery";
        repo = "zsh-histdb";
        rev = "27b719a993414321135ddaf73f9a4ecf785bd8c5";
        hash = "sha256-w1HsIkhsB6iG6yFBpiNcyXPiuPprkoQ49wO1jfWRExs=";
      };
      patches = (old.patches or []) ++ [./zsh/histdb-fzf.patch];
      postPatch =
        old.postPatch
        + ''
          substituteInPlace histdb-fzf.zsh \
            --replace-fail 'sqlite3 -batch' '${lib.getExe pkgs.sqlite} -batch' \
            --replace-fail 'zsh -fc' '${lib.getExe pkgs.zsh} -fc' \
            --replace-fail 'FZF_DEFAULT_OPTS_FILE= fzf' 'FZF_DEFAULT_OPTS_FILE= ${lib.getExe self'.packages.fzf-history}' \
            --replace-fail '| awk ' '| ${lib.getExe pkgs.gawk} ' \
            --replace-fail 'mktemp -d' '${pkgs.coreutils}/bin/mktemp -d' \
            --replace-fail 'command rm -rf' 'command ${pkgs.coreutils}/bin/rm -rf'
        '';
      postInstall =
        (old.postInstall or "")
        + ''
          install -Dt "$out/share/zsh-histdb" histdb-fzf.zsh
        '';
    });
    testPython = pkgs.python3.withPackages (p: [p.pyte]);
  in {
    packages.zsh-histdb = histdb;
    packages.zsh =
      (inputs.wrappers.wrapperModules.zsh.apply {
        inherit pkgs;
        settings = {
          integrations = {
            fzf = {
              enable = true;
              package = self'.packages.fzf-history;
            };
            oh-my-posh = {
              enable = true;
              package = self'.packages.oh-my-posh;
            };
            zoxide.enable = true;
          };
          shellAliases = {
            ".." = "cd ..";
            "x" = "eza --group-directories-first --icons=always --git --color=always";
            "c" = "clear";
            "f" = "${self'.packages.fzf-files}/bin/fzf";
            "n" = "nh os switch";
          };
          completion = {
            enable = true;
            extraCompletions = true;
            colors = true;
            fuzzySearch = true;
            init = lib.mkForce ''
              fpath+=(${self'.packages.completions}/share/zsh/site-functions)
              autoload -U compinit && compinit -u
            '';
          };
          autoSuggestions = {
            enable = true;
            highlight = "fg=${self.theme.base03}";
          };
          history = {
            share = true;
            append = true;
            findNoDups = true;
            ignoreAllDups = true;
            ignoreSpace = true;
          };
        };
        ".zshenv".content = ''
          if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
            . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
          fi
          path=($HOME/.local/bin $path)
          typeset -U path
        '';
        extraRC = ''
          path=(${pkgs.sqlite}/bin ${self'.packages.sysq}/bin $path)
          source ${histdb}/share/zsh-histdb/sqlite-history.zsh
          source ${histdb}/share/zsh-histdb/histdb-fzf.zsh
          bindkey '^R' _fzf_histdb_widget
          bindkey '^[r' _fzf_histdb_widget
          bindkey -M viins '^R' _fzf_histdb_widget
          source ${self'.packages.sysq}/share/zsh/site-functions/sysq.zsh
          autoload -Uz edit-command-line
          zle -N edit-command-line
          bindkey '^X^E' edit-command-line
          source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
          source ${./zsh/project-environment.zsh}
          eval "$(${pkgs.direnv}/bin/direnv hook zsh)"
          # Run after direnv so newly activated package completions work now,
          # even though compinit already ran before the first prompt.
          autoload -Uz add-zsh-hook
          add-zsh-hook precmd _flake_project_completions
        '';
      }).wrapper;

    checks.zsh-history =
      pkgs.runCommand "zsh-history-tests" {
        nativeBuildInputs = [testPython pkgs.zsh pkgs.sqlite pkgs.coreutils];
        HISTDB_TEST_SCRIPT = "${histdb}/share/zsh-histdb/histdb-fzf.zsh";
        HISTDB_TEST_BACKEND = "${histdb}/share/zsh-histdb/sqlite-history.zsh";
        ZSH_TEST_WRAPPER = lib.getExe self'.packages.zsh;
      } ''
        cp -r ${./zsh} source
        cd source
        python3 -B -m unittest test_history -v
        touch "$out"
      '';
  };
}
