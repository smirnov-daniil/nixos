{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.sanctum.nginx;
  sanctumCfg = config.sanctum;

  # Функция для создания nginx virtualHost для сервиса
  makeServiceVirtualHost = serviceName: serviceCfg:
    if serviceCfg.enable && serviceCfg ? port && serviceCfg ? domain then
      {
        "${serviceCfg.domain}" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString serviceCfg.port}";
            proxyWebsockets = true;
          };
        };
      }
    else
      {};

  # Собираем все virtualHosts для включенных сервисов
  serviceVirtualHosts = concatMapAttrs makeServiceVirtualHost sanctumCfg.services;

  # Основной virtualHost
  mainVirtualHost = {
    "${sanctumCfg.domain}" = {
      forceSSL = true;
      enableACME = true;
      default = true;
      locations."/" = {
        root = pkgs.writeTextDir "index.html" ''
          <html>
            <body>
              <h1>Server Ready!</h1>
            </body>
          </html>
        '';
      };
    };
  };

  # Объединяем все virtualHosts
  allVirtualHosts = mainVirtualHost // serviceVirtualHosts;

in {
  options.sanctum.nginx = {
    enable = mkEnableOption "nginx web server";

    httpPort = mkOption {
      type = types.port;
      default = 80;
      description = "HTTP порт";
    };

    httpsPort = mkOption {
      type = types.port;
      default = 443;
      description = "HTTPS порт";
    };

    acmeEmail = mkOption {
      type = types.str;
      default = "admin@example.com";
      description = "Email для Let's Encrypt";
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ cfg.httpPort cfg.httpsPort ];

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;

      virtualHosts = allVirtualHosts;
    };

    security.acme = {
      acceptTerms = true;
      defaults.email = cfg.acmeEmail;
    };
  };
}
