{lib, ...}:
with lib; {
  options.sanctum = {
    domain = mkOption {
      type = types.str;
      default = "localhost";
      description = "Base domain";
    };

    ip = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "IP address";
    };

    terminalUser = mkOption {
      type = types.str;
      default = "server";
      description = "Account used by interactive admin services such as the browser terminal.";
    };

    services = mkOption {
      type = types.attrsOf (types.submodule ({name, ...}: {
        options = {
          enable = mkEnableOption "Enable ${name} service";
          domain = mkOption {
            type = types.str;
            description = "Domain for ${name}";
          };
          port = mkOption {
            type = types.nullOr types.port;
            default = null;
            description = "Port for ${name}";
          };
          description = mkOption {
            type = types.str;
            default = name;
            description = "Description for ${name}";
          };
          reverseProxy = mkOption {
            type = types.bool;
            default = true;
            description = "Generate the generic single-port nginx proxy; disable for a custom virtual host.";
          };
          allowedNetworks = mkOption {
            type = types.listOf types.str;
            default = [];
            example = ["100.64.0.0/10"];
            description = "Client networks admitted to the generic proxy; empty means public. Real client IPs are used even behind the SSH-over-TLS dispatcher.";
          };
          homepage = {
            enable = mkEnableOption "Enable homepage for service";

            siteMonitor = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Server-side health URL; null monitors the public service URL.";
            };
            widget = mkOption {
              type = types.nullOr types.attrs;
              default = null;
              description = "Optional Homepage service widget configuration (no plaintext secrets).";
            };

            category = mkOption {
              type = types.str;
              default = "Services";
              description = "Category for homepage";
            };
            name = mkOption {
              type = types.str;
              default = name;
              description = "Display name in homepage";
            };
            icon = mkOption {
              type = types.str;
              default = "${name}.svg";
              description = "Icon for homepage";
            };
            description = mkOption {
              type = types.str;
              default = name;
              description = "Description for homepage";
            };
          };
        };
      }));
      default = {};
      description = "Sanctum services configuration";
    };
  };

  config.sanctum.services = {};
}
