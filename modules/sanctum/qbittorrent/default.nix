{ config, lib, pkgs, ... }:
let
  service = "qbittorrent";
  cfg = config.sanctum."${service}";
  sanctum = config.sanctum;
in
{
  options.sanctum."${service}" = {
    enable = lib.mkEnableOption {
      description = "Enable ${service}";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8888;
    };
  };

  config = lib.mkIf cfg.enable {
    sanctum.services."${service}" = {
      enable = true;
      domain = "${service}.${sanctum.domain}";
      port = cfg.port;
      description = "Bit Torrent Client";
      homepage = {
        enable = true;
        category = "Media";
        name = "${service}";
        icon = "${service}.svg";
        description = "Bit Torrent Client";
      };
    };

    services."${service}" = {
      enable = true;
      group = "media";
      user = "${service}";
      profileDir = "/srv/${service}";
      webuiPort = cfg.port;

      serverConfig = {
        LegalNotice.Accepted = true;
        Preferences = {
          WebUI = {
            # AlternativeUIEnabled = true;
            # RootFolder = "''${pkgs.vuetorrent}/share/vuetorrent";
            Username = "papa_mama";
            Password_PBKDF2 = "@ByteArray(mqlctynfhD/toUDwfYTliw==:WXOiaRobiwIP3cLZr1u/sFaJ3rHLZ16rLflEuKaxzBf1ChG+8fNSyGHGy5v8nhA60rUN9dqHSeZPsUjIVqQlNA==)";
          };
        };
      };
    };
  };
}
