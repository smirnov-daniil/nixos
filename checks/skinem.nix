{
  inputs,
  self,
  ...
}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    evaluate = extra:
      (inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          self.nixosModules.sanctum-skinem
          self.nixosModules.sanctum-homepage
          {
            boot.isContainer = true;
            system.stateVersion = "25.11";
            sanctum.domain = "example.org";
            sanctum.skinem.enable = true;
            sanctum.homepage.enable = true;
          }
          extra
        ];
      }).config;
    web = evaluate {};
    aggregate =
      (inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          self.nixosModules.sanctum
          {
            boot.isContainer = true;
            system.stateVersion = "25.11";
            sanctum.skinem.enable = true;
          }
        ];
      }).config;
    credentials = evaluate {
      sanctum.skinem.secrets = {
        TELEGRAM_BOT_TOKEN = "skinem/bot";
        WEBHOOK_SECRET = "skinem/webhook";
      };
      sops.defaultSopsFile = ../hosts/tai-lung/secrets/secrets.yaml;
      sops.age.keyFile = "/tmp/test-age-key";
    };
    samePorts = evaluate {sanctum.skinem.healthPort = 9080;};
    polling = evaluate {sanctum.skinem.environment.TELEGRAM_MODE = "polling";};
    customDatabasePort = evaluate {services.postgresql.settings.port = 5544;};
    missingWebhook = evaluate {sanctum.skinem.secrets.TELEGRAM_BOT_TOKEN = "skinem/bot";};
    hasFailedAssertion = config: builtins.any (item: !item.assertion) config.assertions;
    invariants = assert !web.services.skinem.envoy.enable;
    assert aggregate.sanctum.nginx.enable;
    assert polling.systemd.services.skinem-server.environment.TELEGRAM_MODE == "polling";
    assert customDatabasePort.systemd.services.skinem-server.environment.DATABASE_URL == "postgresql:///skinem?host=/run/postgresql&port=5544";
    assert web.systemd.services.skinem-server.serviceConfig.User == "skinem";
    assert web.systemd.services.skinem-server.serviceConfig.LoadCredential == [];
    assert web.systemd.services.skinem-server.environment.DATABASE_URL == "postgresql:///skinem?host=/run/postgresql&port=5432";
    assert web.services.nginx.virtualHosts."split.example.org".locations."/".proxyPass == null;
    assert web.services.nginx.virtualHosts."split.example.org".locations."/skinem.v1.SplitService/".proxyPass == "http://127.0.0.1:9080";
    assert web.sanctum.services.skinem.homepage.siteMonitor == "http://127.0.0.1:9083/healthz";
    assert !builtins.elem 9083 web.networking.firewall.allowedTCPPorts;
    assert builtins.length credentials.systemd.services.skinem-server.serviceConfig.LoadCredential == 2;
    assert !(credentials.systemd.services.skinem-server.environment ? TELEGRAM_BOT_TOKEN);
    assert builtins.elem "skinem-server.service" credentials.sops.secrets."skinem/bot".restartUnits;
    assert hasFailedAssertion samePorts;
    assert hasFailedAssertion missingWebhook; true;
  in {
    checks.skinem-probes =
      pkgs.runCommand "skinem-probes" {
        nativeBuildInputs = [pkgs.python3];
      } ''
        export PYTHONDONTWRITEBYTECODE=1
        cd ${../nixos/features/sanctum/skinem}
        python -m unittest -v test_health
        touch "$out"
      '';
    checks.skinem-invariants = assert invariants; pkgs.runCommand "skinem-invariants" {} "touch $out";
    checks.skinem-credentials =
      pkgs.runCommand "skinem-credentials" {
        nativeBuildInputs = [pkgs.secretspec pkgs.python3];
        webManifest = web.systemd.services.skinem-server.environment.SECRETSPEC_FILE;
        credentialManifest = credentials.systemd.services.skinem-server.environment.SECRETSPEC_FILE;
      } ''
        export HOME="$TMPDIR"
        # These are synthetic fixtures, not deployment secrets.
        secretspec run --file "$webManifest" --profile production -- \
          python -c 'import os; assert os.environ["SKINEM_PUBLIC_ORIGIN"] == "https://split.example.org"; assert os.environ["DATABASE_URL"].startswith("postgresql:///skinem?"); assert not os.environ.get("CLICKHOUSE_URL")'
        export CREDENTIALS_DIRECTORY="$TMPDIR/credentials"
        mkdir -m 700 "$CREDENTIALS_DIRECTORY"
        printf '%s' 'fixture-bot-token' > "$CREDENTIALS_DIRECTORY/TELEGRAM_BOT_TOKEN"
        printf '%s' 'fixture-webhook-secret' > "$CREDENTIALS_DIRECTORY/WEBHOOK_SECRET"
        export TELEGRAM_BOT_TOKEN=incorrect-environment-fallback
        secretspec run --file "$credentialManifest" --profile production -- \
          python -c 'import os; assert os.environ["TELEGRAM_BOT_TOKEN"] == "fixture-bot-token"; assert os.environ["WEBHOOK_SECRET"] == "fixture-webhook-secret"'
        # Missing credentials must not silently fall back to the inherited token.
        export CREDENTIALS_DIRECTORY="$TMPDIR/missing-credentials"
        mkdir -m 700 "$CREDENTIALS_DIRECTORY"
        if secretspec run --file "$credentialManifest" --profile production -- true; then
          echo 'Missing systemd credentials unexpectedly accepted' >&2
          exit 1
        fi
        touch "$out"
      '';
  };
}
