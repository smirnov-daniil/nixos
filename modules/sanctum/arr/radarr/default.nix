{ config, lib, ... }:
let
  service = "radarr";
  cfg = config.sanctum."${service}";
  sanctum = config.sanctum;
in
{
  options.sanctum."${service}" = {
    enable = lib.mkEnableOption {
      description = "Enable ${service}";
    };
  };

  config = lib.mkIf cfg.enable {
    sanctum.services."${service}" = {
      enable = true;
      domain = "${service}.${sanctum.domain}";
      port = 7878;
      description = "Movie collection manager";
      homepage = {
        enable = true;
        category = "Media";
        name = "${service}";
        icon = "${service}.svg";
        description = "Movie collection manager";
      };
    };

    services."${service}" = {
      enable = true;
      dataDir = "/srv/${service}";
      openFirewall = false;
      user = "${service}";
      group = "media";
    };
  };
}
