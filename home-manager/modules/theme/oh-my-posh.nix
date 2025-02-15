{
  lib,
  config,
  ...
}: {
  options = {
    oh-my-posh.use = lib.mkEnableOption "enables oh-my-posh";
  };

  config = lib.mkIf config.oh-my-posh.use {
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
                foreground = "cyan";
                style = "plain";
                template = "{{ if not .Env.IN_NIX_SHELL }}❯{{ end }}";
                type = "text";
              }
              {
                foreground = "green";
                style = "plain";
                template = "{{ if .Env.IN_NIX_SHELL }}❯{{ end }}";
                type = "text";
              }
              {
                foreground = "blue";
                style = "plain";
                template = " {{ .Path }} ";
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
              # {
              #   foreground = "red";
              #   style = "plain";
              #   template = " ✗";
              #   type = "status";
              # }
            ];
          }
          {
            overflow = "hidden";
            type = "rprompt";
            segments = [
              {
                foreground = "yellow";
                style = "plain";
                template = "{{ .FormattedMs }}";
                type = "executiontime";
                properties = {
                  threshold = 5000;
                };
              }
            ];
          }
        ];
        secondary_prompt = {
          background = "transparent";
          foreground = "cyan";
          template = "❯❯ ";
        };
        transient_prompt = {
          background = "transparent";
          newline = true;
          foreground_templates = [
            "{{if gt .Code 0}}red{{end}}"
            "{{if eq .Code 0}}magenta{{end}}"
          ];
          template = "❯ ";
        };
      };
    };
  };
}
