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
    # Generate the .xonshrc configuration file
    xonshrc = pkgs.writeText "xonshrc" ''
      # Aliases
      aliases['..'] = 'cd ..'
      aliases['x'] = 'eza --group-directories-first --icons=always --git --color=always'
      aliases['c'] = 'cat'

      # History settings
      $HISTCONTROL = {'ignoredups', 'ignorespace'}

      # Xonsh interactive defaults (replacing zsh-syntax-highlighting and auto-suggestions)
      $XONSH_PROMPT_AUTO_SUGGEST = True
      $COLOR_INPUT = True
      $COMPLETIONS_CONFIRM = True

      # Integrations
      # oh-my-posh
      execx($(${lib.getExe self'.packages.oh-my-posh} init xonsh))

      # zoxide
      execx($(${lib.getExe pkgs.zoxide} init xonsh))

      # fzf
      # Note: fzf does not provide native xonsh bindings out of the box.
      # If you require Ctrl+R / Ctrl+T functionality in the future, you will
      # need to package and import 'xontrib-fzf-widgets'.
    '';
  in {
    packages.xonsh = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.xonsh;
      env = {
        # Instruct xonsh to use our generated configuration file
        XONSHRC = "${xonshrc}";
      };
    };
  };
}
