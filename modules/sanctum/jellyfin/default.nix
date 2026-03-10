{ config, lib, ... }:
let
  service = "jellyfin";
  cfg = config.sanctum."${service}";
  sanctum = config.sanctum;
in
{
  options.sanctum."${service}" = {
    enable = lib.mkEnableOption {
      description = "Enable ${service}";
    };
    configDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/${service}";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8096;
    };
  };

  config = lib.mkIf cfg.enable {
    # Добавляем в sanctum.services для автоматического обнаружения
    sanctum.services."${service}" = {
      enable = true;
      domain = "${service}.${sanctum.domain}";
      port = cfg.port;
      description = "The Free Software Media System";
      homepage = {
        enable = true;
        category = "Media";
        name = "${service}";
        icon = "${service}.svg";
        description = "The Free Software Media System";
      };
    };

    nixpkgs.overlays = [
      (_final: prev: {
        jellyfin-web = prev.jellyfin-web.overrideAttrs (
          _finalAttrs: _previousAttrs: {
            installPhase = ''
              runHook preInstall

              # this is the important line
              sed -i "s#</head>#<script src=\"configurationpage?name=skip-intro-button.js\"></script></head>#" dist/index.html

              mkdir -p $out/share
              cp -a dist $out/share/jellyfin-web

              runHook postInstall
            '';
          }
        );
      })
    ];

    services."${service}" = {
      enable = true;
      # user и group можно настроить при необходимости
      # user = "bazarr";
      # group = "media";
    };

    # Nginx virtualHost создастся автоматически через sanctum.services
  };
}
