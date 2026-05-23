{
  inputs,
  lib,
  ...
}: {
  perSystem = {pkgs, ...}: let
    ompConf =
      pkgs.writeText "config.toml"
      ''
        version = 3
        final_space = true

        [secondary_prompt]
          template = '~~>'
          foreground = 'magenta'
          background = 'transparent'

        [transient_prompt]
          template = '~> '
          background = 'transparent'
          foreground_templates = ['{{if gt .Code 0}}red{{end}}', '{{if eq .Code 0}}magenta{{end}}']
          newline = true

        [upgrade]
          source = 'cdn'
          interval = '168h'
          auto = false
          notice = false

        [[blocks]]
          type = 'prompt'
          alignment = 'left'
          newline = true

          [[blocks.segments]]
            template = '~> '
            foreground = 'magenta'
            type = 'text'
            style = 'plain'

          [[blocks.segments]]
            template = '{{ .Path }}'
            foreground = 'blue'
            type = 'path'
            style = 'plain'

            [blocks.segments.properties]
              style = 'folder'

          [[blocks.segments]]
            template = ' {{ .HEAD }}{{ if or (.Working.Changed) (.Staging.Changed) }}*{{ end }} <cyan>{{ if gt .Behind 0 }}⇣{{ end }}{{ if gt .Ahead 0 }}⇡{{ end }}</>'
            foreground = 'darkGray'
            type = 'git'
            style = 'plain'

            [blocks.segments.properties]
              branch_icon = ""
              commit_icon = '@'
              fetch_status = true

        [[blocks]]
          type = 'rprompt'
          overflow = 'hidden'

          [[blocks.segments]]
            template = '{{ .FormattedMs }} '
            foreground = 'yellow'
            type = 'executiontime'
            style = 'plain'

            [blocks.segments.properties]
              threshold = 5000.0

          [[blocks.segments]]
            template = ' '
            foreground = 'darkGray'
            type = 'nix-shell'
            style = 'plain'
      '';
  in {
    packages.oh-my-posh = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.oh-my-posh;
      flags = {
        "--config" = ompConf;
      };
    };
  };
}
