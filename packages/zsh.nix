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
            fzf.enable = true;
            oh-my-posh = {
              enable = true;
              package = self'.packages.omp;
            };
            zoxide.enable = true;
          };
          shellAliases = {
            ".." = "cd ..";
            "x" = "eza --group-directories-first --icons=always --git --color=always";
          };
          completion = {
            enable = true;
            extraCompletions = true;
            colors = true;
            fuzzySearch = true;
          };
          autoSuggestions = {
            enable = true;
            highlight = "fg=${self.theme.base03}";
          };
        };
        extraRC = "source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
      }).wrapper;
  };
}
