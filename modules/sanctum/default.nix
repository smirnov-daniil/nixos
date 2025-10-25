{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  imports = [
    ./nginx
    ./vaultwarden
    ./homepage
    ./microbin
  ];

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
          homepage = {
            enable = mkEnableOption "Enable homepage for service";

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
