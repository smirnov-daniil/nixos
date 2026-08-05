{self, ...}: {
  flake.nixosModules.user-environment = {
    pkgs,
    config,
    lib,
    ...
  }: let
    cfg = config."user-environment";
  in {
    imports = [self.nixosModules.preferences];

    options."user-environment" = {
      shellPackage = lib.mkOption {
        type = lib.types.package;
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.environment;
      };
      nhPackage = lib.mkOption {
        type = lib.types.package;
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.nh;
      };
      extraGroups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
      };
    };

    config = {
      users.users.${config.preferences.user.name} = {
        isNormalUser = true;
        description = "${config.preferences.user.name}'s account";
        extraGroups = cfg.extraGroups;
        shell = cfg.shellPackage;
      };

      programs.nh = {
        enable = true;
        package = cfg.nhPackage;
        clean = {
          enable = true;
          extraArgs = "--keep 5 --keep-since 7d";
        };
      };
      environment.variables = {
        "GIT_AUTHOR_NAME" = "${config.preferences.user.fullname}";
        "GIT_AUTHOR_EMAIL" = "${config.preferences.user.email}";
        "GIT_COMMITTER_NAME" = "${config.preferences.user.fullname}";
        "GIT_COMMITTER_EMAIL" = "${config.preferences.user.email}";
        "JJ_USER" = "${config.preferences.user.fullname}";
        "JJ_EMAIL" = "${config.preferences.user.email}";
      };
    };
  };
}
