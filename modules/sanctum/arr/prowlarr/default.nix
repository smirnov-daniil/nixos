{ config, lib, ... }:
let
  service = "prowlarr";
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
      port = 9696;
      description = "Indexer manager";
      homepage = {
        enable = true;
        category = "Media";
        name = "${service}";
        icon = "${service}.svg";
        description = "PVR indexer manager";
      };
    };

    services."${service}" = {
      enable = true;
    };
  };
}
