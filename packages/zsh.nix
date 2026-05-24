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
  }: {
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
            "c" = "cat";
            "f" = "${self'.packages.fzf-files}/bin/fzf";
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
        extraRC = "source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh";
      }).wrapper;
  };
}
