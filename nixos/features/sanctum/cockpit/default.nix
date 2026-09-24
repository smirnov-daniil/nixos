{self, ...}: {
  flake.nixosModules.sanctum-cockpit = {
    config,
    lib,
    ...
  }:
    with lib; let
      service = "cockpit";
      cfg = config.sanctum."${service}";
      sanctum = config.sanctum;
    in {
      imports = [self.nixosModules.sanctum-core];

      options.sanctum."${service}" = {
        enable = mkEnableOption "Cockpit web console behind nginx (system login through PAM)";
        port = mkOption {
          type = types.port;
          default = 9090;
          description = "${service} loopback port";
        };
        domain = mkOption {
          type = types.str;
          default = "${service}.${sanctum.domain}";
          description = "Public name of the console";
        };
      };

      config = mkIf cfg.enable {
        sanctum.services."${service}" = {
          enable = true;
          domain = cfg.domain;
          port = cfg.port;
          description = "System console: services, logs, reboot";
          homepage = {
            enable = true;
            name = "Cockpit";
            icon = "cockpit.svg";
            category = "Admin";
          };
        };

        services."${service}" = {
          enable = true;
          port = cfg.port;
          openFirewall = false;
          showBanner = false;
          allowed-origins = ["https://${cfg.domain}"];
          settings.WebService = {
            # TLS terminates in nginx; Cockpit sees plain HTTP on loopback.
            AllowUnencrypted = true;
            ProtocolHeader = "X-Forwarded-Proto";
            ForwardedForHeader = "X-Forwarded-For";
            LoginTo = false;
          };
        };
      };
    };
}
