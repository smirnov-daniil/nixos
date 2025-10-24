{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.sanctum.services.nginx;
in {
  options.sanctum.services.nginx = {
    enable = mkEnableOption "nginx web server";

    domain = mkOption {
      type = types.str;
      default = "localhost";
      description = "Основной домен сервера";
    };

    ip = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "IP адрес для привязки";
    };

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
    # Настройка firewall
    networking.firewall.allowedTCPPorts = [cfg.httpPort cfg.httpsPort];

    # Настройка nginx
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;

      virtualHosts."${cfg.domain}" = {
        forceSSL = true;
        enableACME = true;
        default = true;
        locations."/" = {
          root = pkgs.writeTextDir "index.html" ''
            <html>
              <body>
                <h1>NixOS Server Ready!</h1>
                <p>Домен: ${cfg.domain}</p>
              </body>
            </html>
          '';
        };
      };
    };

    # Настройка Let's Encrypt
    security.acme = {
      acceptTerms = true;
      defaults.email = cfg.acmeEmail;
    };
  };
}
