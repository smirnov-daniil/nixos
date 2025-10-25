{ config, pkgs, lib, ... }:

with lib;

{
  imports = [
    ./nginx
    ./vaultwarden
    ./homepage
  ];

  options.sanctum = {
    domain = mkOption {
      type = types.str;
      default = "localhost";
      description = "Основной домен сервера";
    };

    ip = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "IP адрес сервера";
    };

    # Определяем sanctum.services как свободный attrset
    services = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
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
        };
      }));
      default = {};
      description = "Sanctum services configuration";
    };
  };
}
