{ config, lib, ... }:
let
  service = "lidarr";
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
  };

  config = lib.mkIf cfg.enable {
    sanctum.services."${service}" = {
      enable = true;
      domain = "${service}.${sanctum.domain}";
      port = 8686;
      description = "Music collection manager";
      homepage = {
        enable = true;
        category = "Media";
        name = "${service}";
        icon = "${service}.svg";
        description = "Music collection manager";
      };
    };

    services."${service}" = {
      enable = true;
    };
  };
}
