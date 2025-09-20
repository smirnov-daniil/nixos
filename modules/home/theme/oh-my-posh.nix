{
  lib,
  config,
  ...
}: {
  options = {
    theme.oh-my-posh.enable = lib.mkEnableOption "enables oh-my-posh";
  };

  config = lib.mkIf config.theme.oh-my-posh.enable {
    programs.oh-my-posh = {
      enable = true;
      enableZshIntegration = true;

      settings = {
        final_space = true;
        version = 3;
        blocks = [
          {
            alignment = "left";
            newline = true;
            type = "prompt";
            segments = [
              {
                foreground = "magenta";
                style = "plain";
                template = "~> ";
                type = "text";
              }
              {
                foreground = "blue";
                style = "plain";
                template = "{{ .Path }}";
                type = "path";
                properties = {
                  style = "folder";
                };
              }
              {
                foreground = "darkGray";
                style = "plain";
                template = " {{ .HEAD }}{{ if or (.Working.Changed) (.Staging.Changed) }}*{{ end }} <cyan>{{ if gt .Behind 0 }}⇣{{ end }}{{ if gt .Ahead 0 }}⇡{{ end }}</>";
                type = "git";
                properties = {
                  branch_icon = "";
                  commit_icon = "@";
                  fetch_status = true;
                };
              }
            ];
          }
          {
            overflow = "hidden";
            type = "rprompt";
            segments = [
              {
                foreground = "yellow";
                style = "plain";
                template = "{{ .FormattedMs }} ";
                type = "executiontime";
                properties = {
                  threshold = 5000;
                };
              }
              {
                foreground = "darkGray";
                style = "plain";
                template = " ";
                type = "nix-shell";
              }
            ];
          }
        ];
        secondary_prompt = {
          background = "transparent";
          foreground = "magenta";
          template = "~~>";
        };
        transient_prompt = {
          background = "transparent";
          newline = true;
          foreground_templates = [
            "{{if gt .Code 0}}red{{end}}"
            "{{if eq .Code 0}}magenta{{end}}"
          ];
          template = "~> ";
        };
      };
    };
  };
}
