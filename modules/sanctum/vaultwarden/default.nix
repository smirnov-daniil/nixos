{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.sanctum.vaultwarden;
  sanctumCfg = config.sanctum;
in {
  options.sanctum.vaultwarden = {
    enable = mkEnableOption "Vaultwarden password manager";
    port = mkOption {
      type = types.port;
      default = 8222;
      description = "Порт Vaultwarden";
    };
    enableAdmin = mkOption {
      type = types.bool;
      default = true;
      description = "Включить админ панель";
    };
  };

  config = mkIf cfg.enable {
    sanctum.services.vaultwarden = {
      enable = true;
      domain = "vault.${sanctumCfg.domain}";
      port = cfg.port;
      description = "Password Manager";
      homepage = {
        category = "Services";
        name = "Vaultwarden";
        icon = "vaultwarden.svg";
        description = "Password Manager";
      };
    };

    sops.secrets.vaultwarden = {
      owner = "vaultwarden";
    };

    services.vaultwarden = {
      enable = true;
      dbBackend = "sqlite";
      config = {
        DOMAIN = "https://vault.${sanctumCfg.domain}";
        ROCKET_PORT = cfg.port;
        SIGNUPS_ALLOWED = false;
        ROCKET_ADDRESS = "127.0.0.1";
      };
      environmentFile = config.sops.secrets.vaultwarden.path;
    };
  };
}
