{
  inputs,
  lib,
  ...
}: {
  perSystem = {pkgs, ...}: {
    packages.fzf = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.fzf;
      runtimeInputs = [pkgs.fd];
      env = {
        FZF_DEFAULT_COMMAND = "fd --type f";
        FZF_DEFAULT_OPTS = "--info inline --border rounded --height 40% --layout reverse";
      };
    };
    packages.fzf-history = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.fzf;
      flags = {
        "--info" = "inline";
        "--border" = "rounded";
        "--height" = "40%";
        "--layout" = "reverse";
      };
    };
    packages.fzf-files = inputs.wrappers.lib.wrapPackage {
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
}
