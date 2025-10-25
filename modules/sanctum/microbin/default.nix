{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
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
    };
  };
}
