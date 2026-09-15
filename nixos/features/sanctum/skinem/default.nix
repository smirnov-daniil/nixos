{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.sanctum-skinem = {
    config,
    pkgs,
    lib,
    ...
  }: let
    cfg = config.sanctum.skinem;
    upstream = inputs.skinem;
    packages = upstream.packages.${pkgs.stdenv.hostPlatform.system};
    definitions = builtins.fromTOML (builtins.readFile "${upstream}/secretspec.toml");
    environment =
      {
        SKINEM_PUBLIC_ORIGIN = "https://${cfg.domain}";
        CLICKHOUSE_URL = "";
        TELEGRAM_MODE = "webhook";
        WEBHOOK_PORT = toString cfg.webhookPort;
        WEBAPP_URL = "https://${cfg.domain}/";
        WEBHOOK_URL = "https://${cfg.domain}/tg/webhook";
      }
      // lib.optionalAttrs cfg.localDatabase {
        DATABASE_URL = "postgresql:///skinem?host=/run/postgresql&port=${toString config.services.postgresql.settings.port}";
      }
      // cfg.environment;
    secretNames = builtins.attrNames cfg.secrets;
    declarations =
      definitions.profiles.default
      // definitions.profiles.production
      // lib.genAttrs (builtins.attrNames environment ++ secretNames) (name: {
        description = "Runtime setting ${name}";
        required = true;
      });
    manifest = (pkgs.formats.toml {}).generate "skinem-systemd-secretspec.toml" {
      inherit (definitions) project;
      profiles.production = lib.mapAttrs (name: declaration:
        (builtins.removeAttrs declaration ["providers" "ref" "default"])
        // (
          if builtins.hasAttr name cfg.secrets
          then {
            required = true;
            providers = ["systemd-credential"];
          }
          else if builtins.hasAttr name environment
          then {
            required = false;
            default = environment.${name};
            providers = ["env"];
          }
          else {
            required = declaration.required or false;
            providers = ["env"];
          }
        ))
      declarations;
    };
    server = pkgs.writeShellScript "skinem-with-credentials" ''
      exec ${pkgs.secretspec}/bin/secretspec run \
        --file ${manifest} --profile production \
        -- ${config.services.skinem.package}/bin/skinem-server
    '';
    gatewayConfig = pkgs.writeText "skinem-gateway.yaml" (builtins.replaceStrings
      ["port_value: 8080" "port_value: 50051" "port_value: 8081"]
      ["port_value: ${toString cfg.gatewayPort}" "port_value: ${toString cfg.grpcPort}" "port_value: ${toString cfg.webhookPort}"]
      (builtins.readFile "${upstream}/deploy/envoy.yaml"));
    probeConfig = pkgs.writeText "skinem-probes.json" (builtins.toJSON {
      port = cfg.healthPort;
      domain = cfg.domain;
      systemctl = "${pkgs.systemd}/bin/systemctl";
      curl = "${pkgs.curl}/bin/curl";
      units =
        ["skinem-server.service" "skinem-gateway.service" "nginx.service"]
        ++ lib.optional cfg.localDatabase "postgresql.service";
      tcp = {
        backend = cfg.grpcPort;
        gateway = cfg.gatewayPort;
      };
      databaseSocket =
        if cfg.localDatabase
        then "/run/postgresql/.s.PGSQL.${toString config.services.postgresql.settings.port}"
        else null;
    });
  in {
    key = toString ./default.nix;
    imports = [
      self.nixosModules.sanctum-core
      self.nixosModules.sanctum-nginx
      upstream.nixosModules.default
      inputs.sops-nix.nixosModules.default
    ];
    options.sanctum.skinem = {
      enable = lib.mkEnableOption "skinem with nginx, systemd and optional SOPS credentials";
      domain = lib.mkOption {
        type = lib.types.str;
        default = "split.${config.sanctum.domain}";
      };
      grpcPort = lib.mkOption {
        type = lib.types.port;
        default = 50051;
      };
      gatewayPort = lib.mkOption {
        type = lib.types.port;
        default = 9080;
      };
      webhookPort = lib.mkOption {
        type = lib.types.port;
        default = 9081;
      };
      healthPort = lib.mkOption {
        type = lib.types.port;
        default = 9083;
      };
      localDatabase = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Create a local skinem database with Unix-socket peer authentication (no password).";
      };
      secrets = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        example = {TELEGRAM_BOT_TOKEN = "skinem/bot-token";};
        description = "Environment variable -> SOPS key in the host's secrets file. Values are key names, never secrets.";
      };
      environment = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "Non-secret runtime settings; secret values belong in secrets.";
      };
      homepage.enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
    };
    config = lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = lib.length (lib.unique [cfg.grpcPort cfg.gatewayPort cfg.webhookPort cfg.healthPort]) == 4;
          message = "skinem: backend, gateway, webhook and health ports must differ.";
        }
        {
          assertion = lib.all (name: builtins.match "[A-Z][A-Z0-9_]*" name != null) secretNames;
          message = "skinem: credential names must be uppercase environment variable names.";
        }
        {
          assertion = cfg.localDatabase || cfg.secrets ? DATABASE_URL || cfg.environment ? DATABASE_URL;
          message = "skinem: configure DATABASE_URL when localDatabase is disabled.";
        }
        {
          assertion =
            !(cfg.secrets ? TELEGRAM_BOT_TOKEN)
            || environment.TELEGRAM_MODE != "webhook"
            || cfg.secrets ? WEBHOOK_SECRET;
          message = "skinem: webhook mode requires WEBHOOK_SECRET when the bot is enabled.";
        }
      ];
      sanctum.nginx.enable = true;
      sanctum.services.skinem = {
        enable = true;
        domain = cfg.domain;
        reverseProxy = false;
        description = "Shared bills and balances";
        homepage = {
          enable = cfg.homepage.enable;
          name = "Скинемся";
          description = "Shared bills and balances";
          icon = "mdi-receipt-text";
          siteMonitor = "http://127.0.0.1:${toString cfg.healthPort}/healthz";
          widget = {
            type = "customapi";
            url = "http://127.0.0.1:${toString cfg.healthPort}/status.json";
            refreshInterval = 30000;
            mappings = [
              {
                field = "status";
                label = "Status";
              }
              {
                field = "passed";
                label = "Checks passed";
              }
              {
                field = "total";
                label = "Checks total";
              }
            ];
          };
        };
      };
      sops.secrets = lib.listToAttrs (map (name:
        lib.nameValuePair cfg.secrets.${name} {
          restartUnits = ["skinem-server.service"];
        })
      secretNames);
      users.groups.skinem = {};
      users.users.skinem = {
        isSystemUser = true;
        group = "skinem";
      };
      services.postgresql = lib.mkIf cfg.localDatabase {
        enable = true;
        ensureDatabases = ["skinem"];
        ensureUsers = [
          {
            name = "skinem";
            ensureDBOwnership = true;
          }
        ];
        authentication = lib.mkBefore "local skinem skinem peer";
      };
      services.skinem = {
        enable = true;
        port = cfg.grpcPort;
        webapp.enable = false;
        envoy.enable = false;
        clickhouseUrl = environment.CLICKHOUSE_URL;
      };
      systemd.services.skinem-server = {
        after = lib.optional cfg.localDatabase "postgresql.service" ++ lib.optional (secretNames != []) "sops-install-secrets.service";
        requires = lib.optional cfg.localDatabase "postgresql.service";
        environment =
          (lib.mapAttrs (_: value: lib.mkForce value)
            (lib.filterAttrs (name: _: !(builtins.hasAttr name cfg.secrets)) environment))
          // {
            SECRETSPEC_FILE = toString manifest;
            XDG_STATE_HOME = "/var/lib/skinem";
          };
        serviceConfig = {
          ExecStart = lib.mkForce server;
          DynamicUser = lib.mkForce false;
          User = "skinem";
          Group = "skinem";
          StateDirectory = "skinem";
          StateDirectoryMode = "0700";
          LoadCredential = map (name: "${name}:${config.sops.secrets.${cfg.secrets.${name}}.path}") secretNames;
          UnsetEnvironment = ["OTEL_EXPORTER_OTLP_ENDPOINT"];
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          UMask = "0077";
        };
      };
      systemd.services.skinem-gateway = {
        description = "skinem private gRPC-Web gateway";
        wantedBy = ["multi-user.target"];
        after = ["skinem-server.service"];
        serviceConfig = {
          ExecStart = "${pkgs.envoy}/bin/envoy -c ${gatewayConfig}";
          DynamicUser = true;
          Restart = "on-failure";
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
        };
      };
      systemd.services.skinem-health = {
        description = "skinem read-only availability probes for Homepage";
        wantedBy = ["multi-user.target"];
        after = ["skinem-gateway.service" "nginx.service"];
        serviceConfig = {
          ExecStart = "${pkgs.python3}/bin/python3 ${./health.py} ${probeConfig}";
          DynamicUser = true;
          Restart = "on-failure";
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
        };
      };
      services.nginx.virtualHosts.${cfg.domain} = {
        forceSSL = true;
        enableACME = true;
        root = "${packages.skinem-webapp}";
        extraConfig = ''
          client_max_body_size 8m;
          access_log off;
          add_header Referrer-Policy "no-referrer" always;
          add_header X-Content-Type-Options "nosniff" always;
          add_header Cache-Control "no-store" always;
        '';
        locations."/".tryFiles = "$uri $uri/ =404";
        locations."/skinem.v1.SplitService/" = {
          proxyPass = "http://127.0.0.1:${toString cfg.gatewayPort}";
          extraConfig = ''
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_buffering off;
            proxy_cache off;
            proxy_read_timeout 3600s;
            proxy_send_timeout 60s;
          '';
        };
        locations."= /tg/webhook" = lib.mkIf (cfg.secrets ? TELEGRAM_BOT_TOKEN && environment.TELEGRAM_MODE == "webhook") {
          proxyPass = "http://127.0.0.1:${toString cfg.webhookPort}";
          extraConfig = "proxy_read_timeout 15s;";
        };
      };
    };
  };
}
