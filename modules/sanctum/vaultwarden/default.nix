{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.sanctum.services.vaultwarden;
in {
  options.sanctum.services.vaultwarden = {
    enable = mkEnableOption "Vaultwarden password manager";
    
    domain = mkOption {
      type = types.str;
      default = "vault.${config.sanctum.services.nginx.domain}";
      description = "Vaultwarden domen";
    };
    
    port = mkOption {
      type = types.port;
      default = 8222;
      description = "Vaultwarden port";
    };
    
    enableAdmin = mkOption {
      type = types.bool;
      default = true;
      description = "Enable admin panel";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.vaultwarden = {
      owner = "vaultwarden";
    };

    services.vaultwarden = {
      enable = true;
      dbBackend = "sqlite";
      config = {
        DOMAIN = "https://${cfg.domain}";
        ROCKET_PORT = cfg.port;
        SIGNUPS_ALLOWED = false;
        ROCKET_ADDRESS = "127.0.0.1";
        
      };
      environmentFile = "${config.sops.secrets.vaultwarden.path}";
    };

    services.nginx.virtualHosts.${cfg.domain} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString cfg.port}";
        proxyWebsockets = true;
      };
    };
  };
}
