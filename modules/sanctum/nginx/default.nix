{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.sanctum.nginx;
  sanctum = config.sanctum;

  sanctumServices =
    lib.attrsets.filterAttrs (
      _name: value: value.enable
    )
    sanctum.services;

  makeServiceVirtualHost = serviceName: serviceCfg:
    {
      "${serviceCfg.domain}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString serviceCfg.port}";
          proxyWebsockets = true;
        };
      };
    };

  serviceVirtualHosts = concatMapAttrs makeServiceVirtualHost sanctumServices;

  mainVirtualHost = {
    "${sanctum.domain}" = {
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
    networking.firewall.allowedTCPPorts = [cfg.httpPort cfg.httpsPort];

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
