{
  inputs,
  self,
  ...
}: {
  perSystem = {system, ...}: {
    checks = inputs.deploy-rs.lib.${system}.deployChecks self.deploy;
  };

  flake.nixosModules = {
    deploy-rs-server = {
      config,
      lib,
      ...
    }: let
      cfg = config.features.deploy-rs.server;
    in {
      options.features.deploy-rs.server = {
        enable = lib.mkEnableOption "deploy-rs target support";
        user = lib.mkOption {
          type = lib.types.str;
        };
        passwordlessSudo = lib.mkEnableOption "passwordless deploy-rs system activation";
        authorizedKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
        };
      };

      config = lib.mkIf cfg.enable {
        services.openssh.enable = true;
        users.users.${cfg.user} = {
          extraGroups = ["wheel"];
          openssh.authorizedKeys.keys = cfg.authorizedKeys;
        };
        security.sudo.extraRules = lib.mkIf cfg.passwordlessSudo [
          {
            users = [cfg.user];
            commands = [
              {
                command = "ALL";
                options = ["NOPASSWD"];
              }
            ];
          }
        ];
      };
    };

    deploy-rs-initiator = {
      config,
      lib,
      pkgs,
      ...
    }: let
      cfg = config.features.deploy-rs.initiator;
    in {
      options.features.deploy-rs.initiator = {
        enable = lib.mkEnableOption "deploy-rs initiator";
        package = lib.mkOption {
          type = lib.types.package;
          default = inputs.deploy-rs.packages.${pkgs.stdenv.hostPlatform.system}.default;
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [cfg.package];
      };
    };

    deploy-rs = {
      imports = [
        self.nixosModules.deploy-rs-server
        self.nixosModules.deploy-rs-initiator
      ];
    };
  };
}
