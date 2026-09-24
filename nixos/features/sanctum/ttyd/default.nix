{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.sanctum-ttyd = {
    config,
    pkgs,
    lib,
    ...
  }:
    with lib; let
      service = "ttyd";
      cfg = config.sanctum."${service}";
      sanctum = config.sanctum;

      # Run the user's login shell directly; ttyd itself runs unprivileged.
      userShell = config.users.users.${cfg.user}.shell;
      shellExe =
        if isString userShell
        then userShell
        else "${userShell}${userShell.shellPath or "/bin/sh"}";
    in {
      imports = [
        self.nixosModules.sanctum-core
        inputs.sops-nix.nixosModules.default
      ];

      options.sanctum."${service}" = {
        enable = mkEnableOption "browser terminal (ttyd) behind nginx with mandatory HTTP basic auth";
        port = mkOption {
          type = types.port;
          default = 7681;
          description = "${service} loopback port";
        };
        domain = mkOption {
          type = types.str;
          default = "terminal.${sanctum.domain}";
          description = "Public name of the terminal";
        };
        user = mkOption {
          type = types.str;
          default = sanctum.terminalUser;
          description = "Account whose login shell the terminal opens; ttyd runs as this user.";
        };
        username = mkOption {
          type = types.str;
          default = cfg.user;
          description = "HTTP basic auth login; the password is the `${service}` SOPS secret.";
        };
      };

      config = mkIf cfg.enable {
        sanctum.services."${service}" = {
          enable = true;
          domain = cfg.domain;
          port = cfg.port;
          description = "Terminal in the browser";
          homepage = {
            enable = true;
            name = "Terminal";
            icon = "mdi-console";
            category = "Admin";
          };
        };

        # Plain password string; loaded by systemd as a credential, so no owner needed.
        sops.secrets."${service}" = {};

        services."${service}" = {
          enable = true;
          interface = "127.0.0.1";
          port = cfg.port;
          user = cfg.user;
          entrypoint = [shellExe "-l"];
          writeable = true;
          # Origin must match the proxied Host; blocks cross-site WebSocket hijacking.
          checkOrigin = true;
          username = cfg.username;
          passwordFile = config.sops.secrets."${service}".path;
          clientOptions = {
            fontSize = "14";
            enableSixel = "true";
          };
        };
      };
    };
}
