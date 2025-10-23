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
        st = "status --short --branch";
        co = "checkout";
        br = "branch";
        sw = "switch";
        lg = "log --oneline --graph --decorate --all";

        delim = "^";
        log0 = "log --all --graph --abbrev-commit --color --decorate --format=format:'^%C(bold blue)%h%C(reset)^%C(bold green)%<(15,trunc)%ar%C(reset)^%C(dim white)%<(22,trunc)%an^%C(auto)%<(15,trunc)%d^%C(white)%s%C(reset)'";
        log1 = "log --all --graph --abbrev-commit --color --decorate --format=format:'^%C(bold blue)%h%C(reset)  >^%C(bold cyan)%<(30,trunc)%aD%C(reset)^%C(bold green)%<(22,trunc)(%ar)%C(reset)^%C(auto)%D%C(reset)%n^%<(7,trunc)%x20^%C(dim white)%<(30,trunc)%ae^%<(22,trunc)(%an)%C(reset)  <^%C(white)%s%C(reset)'";
        log2 = "log --all --graph --date='format:%Y-%m-%d %H:%M:%S' --color --decorate=short --pretty=format:'^%C(bold dim white)%ad%C(reset)^%C(bold dim cyan)%<(19,trunc)%an%C(reset)^%C(bold cyan)%h%C(reset)^%C(auto)%D%C(reset)%n^%C(dim white)%<(19,trunc)%ar%C(reset)^%C(dim cyan)%<(19,trunc)%ae%C(reset)^%C(bold white)Commit:%C(reset)^%C(white)%s%C(reset)%n'";
        tab = "!bash -c '{ git $@; echo; } | column -t -s $(git config alias.delim); ' \"git-tab\"";
      };

      extraConfig = {
        branch.sort = "-committerdate";
        column.ui = "auto";
        pull.rebase = true;
        diff = {
          algorithm = "histogram";
          colorMoved = "plain";
          mnemonicPrefix = true;
          renames = true;
        };
        fetch.prune = true;
        init.defaultBranch = "master";
      };
    };
  };
}
