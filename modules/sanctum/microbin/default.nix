{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  nordHighlight = builtins.toFile "nord.css" (builtins.readFile ./nord.css);
  nordUi = builtins.toFile "nord_ui.css" (builtins.readFile ./nord_ui.css);
  highlightJsNix = pkgs.fetchurl {
    url = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.1/languages/nix.min.js";
    hash = "sha256-j4dmtrr8qUODoICuOsgnj1ojTAmxbKe00mE5sfElC/I=";
  };
  highlightJs = pkgs.fetchurl {
    url = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.11.1/highlight.min.js";
    hash = "sha256-xKOZ3W9Ii8l6NUbjR2dHs+cUyZxXuUcxVMb7jSWbk4E=";
  };

  service = "microbin";
  cfg = config.sanctum."${service}";
  sanctum = config.sanctum;
in
{
  options.sanctum."${service}" = {
    enable = mkEnableOption {
      description = "Enable ${service}";
    };
    port = mkOption {
      type = types.port;
      default = 8069;
      description = "${service} port";
    };
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = with pkgs; [
      (_final: prev: {
        microbin = prev.microbin.overrideAttrs (
          _finalAttrs: _previousAttrs: {
            postPatch = ''
              cp ${nordHighlight} templates/assets/highlight/highlight.min.css
              cp ${highlightJs} templates/assets/highlight/highlight.min.js
              cp ${highlightJsNix} templates/assets/highlight/nix.min.js
              echo "" >> templates/assets/water.css
              cat ${nordUi} >> templates/assets/water.css
              sed -i "s#<option value=\"auto\">#<option value=\"auto\" selected>#" templates/index.html
              sed -i "s#highlight.min.js\"></script>#highlight.min.js\"></script><script type=\"text/javascript\" src=\"{{ args.public_path_as_str() }}/static/highlight/nix.min.js\"></script>#" templates/upload.html
            '';
          }
        );
      })
    ];
    
    sanctum.services."${service}" = {
      enable = true;
      domain = "bin.${sanctum.domain}";
      port = cfg.port;
      description = "Minimal paste bin service.";
      homepage = {
        enable = true;
        icon = "${service}.png";
        category = "Services";
      };
    };

    sops.secrets."${service}" = {};

    services."${service}" = {
      enable = true;
      settings = {
        MICROBIN_WIDE = true;
        MICROBIN_MAX_FILE_SIZE_UNENCRYPTED_MB = 2048;
        MICROBIN_PUBLIC_PATH = "https://${sanctum.services."${service}".domain}/";
        MICROBIN_BIND = "127.0.0.1";
        MICROBIN_PORT = cfg.port;
        MICROBIN_HIDE_LOGO = true;
        MICROBIN_HIGHLIGHTSYNTAX = true;
        MICROBIN_HIDE_HEADER = true;
        MICROBIN_HIDE_FOOTER = true;
      };
      passwordFile = config.sops.secrets."${service}".path;
    };
  };
}
