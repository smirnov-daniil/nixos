{ config, lib, ... }:
let
  service = "bazarr";
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
    # Добавляем в sanctum.services для автоматического обнаружения
    sanctum.services."${service}" = {
      enable = true;
      domain = "${service}.${sanctum.domain}";
      port = config.services."${service}".listenPort;
      description = "Subtitle manager";
      homepage = {
        enable = true;
        category = "Media";
        name = "${service}";
        icon = "${service}.svg";
        description = "Subtitle manager";
      };
    };

    services."${service}" = {
      enable = true;
      # user и group можно настроить при необходимости
      # user = "bazarr";
      # group = "media";
    };

    # Nginx virtualHost создастся автоматически через sanctum.services
  };
}
