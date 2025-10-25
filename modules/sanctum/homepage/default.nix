{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.sanctum.homepage;
  sanctumCfg = config.sanctum;

  # Функция для преобразования сервиса sanctum в формат homepage
  serviceToHomepageItem = serviceName: serviceCfg:
    if serviceCfg.enable && serviceName != "homepage" then
      {
        "${serviceCfg.description}" = {
          icon = "${serviceName}.svg";
          href = "https://${serviceCfg.domain}";
        } // (if serviceCfg.port != null then {
          widget = {
            type = "${serviceName}";
            url = "https://${serviceCfg.domain}";
          };
        } else {});
      }
    else null;

  # Собираем все включенные сервисы
  enabledServices = lib.attrsets.filterAttrs (name: value: value != null)
    (lib.attrsets.mapAttrs serviceToHomepageItem sanctumCfg.services);

  # Преобразуем в список для homepage
  homepageServices = lib.attrsets.attrValues enabledServices;

in {
  options.sanctum.homepage = {
    enable = mkEnableOption "Homepage dashboard";

    port = mkOption {
      type = types.port;
      default = 8082;
      description = "Порт Homepage";
    };

    title = mkOption {
      type = types.str;
      default = "Sanctum Dashboard";
      description = "Заголовок dashboard";
    };

    extraServices = mkOption {
      type = types.listOf types.attrs;
      default = [];
      description = "Дополнительные сервисы для homepage";
    };
  };

  config = mkIf cfg.enable {
    # Добавляем метаданные в sanctum.services
    sanctum.services.homepage = {
      enable = true;
      domain = "home.${sanctumCfg.domain}";
      port = cfg.port;
      description = "Dashboard";
    };

    # Исправляем имя сервиса - должно быть services.homepage
    services.homepage-dashboard = {
      enable = true;

      settings = {
        title = cfg.title;
        services = homepageServices ++ cfg.extraServices;

        widgets = [
          {
            "resources" = {
              "cpu" = true;
              "memory" = true;
              "disk" = "/";
              "swap" = true;
            };
          }
        ];
      };
      allowedHosts= "home.ds-2.duckdns.org,localhost:8082";
    };
  };
}
