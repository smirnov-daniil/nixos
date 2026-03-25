{ config, lib, ... }:
let
  service = "sonarr";
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
      port = 8989;
      description = "TV show manager";
      homepage = {
        enable = true;
        category = "Media";
        name = "${service}";
        icon = "${service}.svg";
        description = "TV show collection manager";
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
