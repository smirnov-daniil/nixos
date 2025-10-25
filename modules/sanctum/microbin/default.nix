{
  config,
  pkgs,
  lib,
  ...
}:
let
  service = "microbin";
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
      domain = "bin.${sanctum.domain}";
      port = config.services.microbin.settings.MICROBIN_PORT;
      description = "Pastebin & File Sharing";
      homepage = {
        category = "Services";
        name = "${service}";
        icon = "${service}.png";
        description = "A minimal pastebin";
      };
    };

    services."${service}" = {
      enable = true;
      settings = {
        MICROBIN_WIDE = true;
        MICROBIN_MAX_FILE_SIZE_UNENCRYPTED_MB = 2048;
        MICROBIN_PUBLIC_PATH = "https://${sanctum.services."${service}"}/";
        MICROBIN_BIND = "127.0.0.1";
        MICROBIN_PORT = 8069;
        MICROBIN_HIDE_LOGO = true;
        MICROBIN_HIGHLIGHTSYNTAX = true;
        MICROBIN_HIDE_HEADER = true;
        MICROBIN_HIDE_FOOTER = true;
      };
    };
  };
}
