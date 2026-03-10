{ config, lib, ... }:
let
  service = "jellyseerr";
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
      default = 5055;
    };
  };

  config = lib.mkIf cfg.enable {
    sanctum.services."${service}" = {
      enable = true;
      domain = "${service}.${sanctum.domain}";
      port = cfg.port;
      description = "Media request manager";
      homepage = {
        enable = true;
        category = "Media";
        name = "${service}";
        icon = "${service}.svg";
        description = "Media request and discovery manager";
      };
    };

    services."${service}" = {
      enable = true;
      port = cfg.port;
    };
  };
}
