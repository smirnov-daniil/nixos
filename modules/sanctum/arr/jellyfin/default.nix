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

    port = lib.mkOption {
      type = lib.types.port;
      default = 8096;
      description = "Jellyfin HTTP port";
    };
  };

  config = lib.mkIf cfg.enable {
    sanctum.services."${service}" = {
      enable = true;
      domain = "${service}.${sanctum.domain}";
      port = cfg.port;
      description = "Self-hosted media server";
      homepage = {
        enable = true;
        category = "Media";
        name = "${service}";
        icon = "${service}.svg";
        description = "Self-hosted media server";
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
      openFirewall = false;
      user = "${service}";
      group = "media";

      dataDir = "/srv/${service}/data";
      configDir = "/srv/${service}/config";
      cacheDir = "/srv/${service}/cache";

      # Optional, but usually a good idea to keep explicit:
      # package = pkgs.jellyfin;
    };
  };
}
