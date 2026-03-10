{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.sanctum.croc;
  sanctumCfg = config.sanctum;
in {
  options.sanctum.croc = {
    enable = mkEnableOption "Croc file transfer";
    port = mkOption {
      type = types.port;
      default = 9009; # - 9013
      description = "Port croc";
    };
  };

  config = mkIf cfg.enable {
    sanctum.services.croc = {
      enable = true;
      domain = "croc.${sanctumCfg.domain}";
      port = cfg.port;
      description = "File Transfer";
      homepage.enable = false;
    };

    sanctum.services.croc2 = {
      enable = true;
      domain = "croc2.${sanctumCfg.domain}";
      port = cfg.port + 1;
      description = "File Transfer";
      homepage.enable = false;
    };

    sops.secrets.croc = {
      # owner = "croc";
    };

    services.croc = {
      enable = true;
      ports = [9009 9010];
      pass = config.sops.secrets.croc.path;
    };
  };
}
