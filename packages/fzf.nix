{
  inputs,
  lib,
  self,
  ...
}: {
  perSystem = {pkgs, ...}: {
    packages = {
      fzf = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = pkgs.fzf;
        runtimeInputs = [pkgs.fd];
        env = {
          FZF_DEFAULT_COMMAND = "fd --type f";
          FZF_DEFAULT_OPTS = "--info inline --border rounded --height 40% --layout reverse";
        };
      };

      fzf-history = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = pkgs.fzf;
        flags = {
          "--info" = "inline";
          "--border" = "rounded";
          "--border-label" = " History ";
          "--height" = "75%";
          "--layout" = "reverse";
          "--padding" = "1,2";
          "--prompt" = "History ❯ ";
          "--color" = builtins.concatStringsSep "," [
            "bg:${self.theme.base00}"
            "fg:${self.theme.base05}"
            "bg+:${self.theme.base01}"
            "fg+:${self.theme.base07}"
            "hl:${self.theme.base0B}"
            "hl+:${self.theme.base0B}"
            "border:${self.theme.base03}"
            "header:${self.theme.base04}"
            "info:${self.theme.base03}"
            "pointer:${self.theme.base0D}"
            "marker:${self.theme.base0D}"
            "prompt:${self.theme.base0D}"
            "spinner:${self.theme.base0D}"
            "separator:${self.theme.base02}"
            "preview-bg:${self.theme.base00}"
            "preview-fg:${self.theme.base05}"
          ];
        };
      };

      fzf-files = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = pkgs.fzf;
        flags = {
          "--preview" = "bat --style=numbers --color=always --line-range :500 {}";
          "--layout" = "default";
          "--popup" = "center,75%,90%";
          "--bind" = "enter:become($EDITOR {})";
        };
      };
    };
  };
}
