{self, ...}: {
  flake.nixosModules.sanctum-lidarr = {
    config,
    lib,
    ...
  }: let
    service = "lidarr";
    cfg = config.sanctum."${service}";
    sanctum = config.sanctum;
  in {
    imports = [self.nixosModules.sanctum-core];

    options.sanctum."${service}" = {
      enable = lib.mkEnableOption {
        description = "Enable ${service}";
      };
    };

    config = lib.mkIf cfg.enable {
      users.groups.media = {};

      sanctum.services."${service}" = {
        enable = true;
        domain = "${service}.${sanctum.domain}";
        port = 8686;
        description = "Music collection manager";
        homepage = {
          enable = true;
          category = "Media";
          name = "${service}";
          icon = "${service}.svg";
          description = "Music collection manager";
        };
      };

      services."${service}" = {
        enable = true;
        user = "${service}";
        group = "media";
        dataDir = "/srv/${service}";
      };
    };
  };
}
