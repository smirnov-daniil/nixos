{self, ...}: {
  flake.nixosModules.sanctum = {lib, ...}:
    with lib; {
      imports = [
        self.nixosModules.sanctum-bazarr
        self.nixosModules.sanctum-croc
        self.nixosModules.sanctum-homepage
        self.nixosModules.sanctum-jellyfin
        self.nixosModules.sanctum-jellyseerr
        self.nixosModules.sanctum-lidarr
        self.nixosModules.sanctum-microbin
        self.nixosModules.sanctum-nginx
        self.nixosModules.sanctum-prowlarr
        self.nixosModules.sanctum-qbittorrent
        self.nixosModules.sanctum-radarr
        self.nixosModules.sanctum-sonarr
        self.nixosModules.sanctum-vaultwarden
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
    };
}
