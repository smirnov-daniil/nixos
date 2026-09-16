# skinem on Sanctum

This optional leaf deploys the private skinem flake as systemd services, with nginx
TLS, a private Envoy gRPC-Web gateway, a local PostgreSQL database, and Homepage
availability checks. Importing the Sanctum aggregate does not enable the service.

## Enable the web application

Inside a host's NixOS configuration:

```nix
sanctum.skinem.enable = true;
```

The default URL is `https://split.${config.sanctum.domain}/`. Point DNS at the host
and make ports 80 and 443 reachable for ACME. The leaf enables Sanctum nginx;
Homepage itself is opt-in through `sanctum.homepage.enable`.

The frontend is independent of Telegram. Backend, gateway, webhook and health
ports default to 50051, 9080, 9081 and 9083. Internal listeners stay on loopback;
the leaf does not open these ports in the firewall. The backend runs as the
dedicated `skinem` user. Local PostgreSQL uses Unix-socket peer authentication:
no database password or SOPS key is needed for the basic web deployment.

Hashed assets are cached as immutable for one year. Core assets and the application
shell revalidate with `no-cache` and ETag, while API responses remain uncacheable
with `no-store`.

Do not upgrade an existing PostgreSQL cluster's major version by changing its
package. Back up the `skinem` database; the application migrates its schema at
startup. This module does not configure backups or deploy itself automatically.

## Secrets: SOPS → systemd credentials → SecretSpec

The `secrets` mapping contains SOPS key names, never plaintext values. For a bot:

```nix
sanctum.skinem = {
  enable = true;
  secrets = {
    TELEGRAM_BOT_TOKEN = "skinem/bot-token";
    WEBHOOK_SECRET = "skinem/webhook-secret";
    TELEGRAM_GROUPS_SECRET = "skinem/groups-secret";
  };
  environment.SKINEM_TELEGRAM_GROUPS = "1";
};
```

Create these encrypted entries in the host's SOPS file using your normal SOPS
workflow. The host must configure `sops.defaultSopsFile` and its decryption key.
The leaf declares the selected secrets and restarts `skinem-server` when they
change. Root reads the decrypted files; `LoadCredential` gives the service private
runtime copies. SecretSpec requires every mapped credential and injects values
into the application's environment. A missing credential fails startup; there is
no fallback to a developer keyring or a plaintext value in the Nix configuration.
The service never receives the SOPS age private key.
SecretSpec's access audit is stored under the service-private `/var/lib/skinem`
state directory. Do not expose it through nginx or Homepage.

Telegram OIDC can be enabled separately by mapping `TELEGRAM_LOGIN_CLIENT_SECRET`
and `TELEGRAM_LOGIN_SUBJECT_SECRET`, then setting non-secret
`TELEGRAM_LOGIN_CLIENT_ID` and `TELEGRAM_LOGIN_REDIRECT_URI` in `environment`.
Register the exact HTTPS origin and callback in BotFather. QR uses
`PROVERKACHEKA_TOKEN`. Only add credentials for integrations you intend to enable.

For a remote database, set `localDatabase = false` and map `DATABASE_URL` to a
SOPS entry containing its DSN. Arrange database ownership, TLS and backups on the
database host. Remote database connectivity is not covered by the local socket
probe.

`environment` is for non-secret settings only: its contents enter the Nix store.
The generated manifest adapts the upstream production declarations, uses the
environment provider for configuration and systemd credentials for secrets, and
allows ClickHouse to remain disabled. The upstream project manifest is unchanged.

## Availability, not an administrative terminal

Homepage links to the application and shows health plus the number of successful
checks. Its server reads these private endpoints:

- `http://127.0.0.1:9083/healthz`: 200 when all checks pass, otherwise 503.
- `http://127.0.0.1:9083/status.json`: a JSON snapshot, including failed checks.

The probe checks systemd units, backend/gateway TCP listeners, the local database
socket, and the frontend through local nginx with the real domain and validated
HTTPS certificate. Checks run independently of requests, approximately every 15
seconds after the preceding sample finishes. Uninitialized or older-than-60-second
snapshots are unhealthy. There is no public health route or remote shell.

These are availability checks, not transaction-readiness guarantees. They do not
execute SQL, create identities, call Telegram, or verify bill calculations. The
TLS check bypasses external DNS/CDN using a local address; public reachability
requires an external monitor. If ACME has not issued a certificate yet, the
frontend check correctly fails.

```sh
systemctl status skinem-server skinem-gateway skinem-health postgresql nginx
journalctl -u skinem-server -u skinem-gateway -u skinem-health
curl --fail http://127.0.0.1:9083/healthz
```

## Private source and deployment

`inputs.skinem` uses SSH and pins a published commit; `flake.lock` records its hash
and upstream nixpkgs. Do not add `nixpkgs.follows` without checking compatibility
with the application's C++/WASM toolchain. Update the revision in `flake.nix` and
run `nix flake lock` to upgrade.

The machine fetching sources needs an authorized SSH key/agent and a verified
GitHub host key. Do not put credentials in the input URL. A host receiving an
already-built system does not need GitHub access; a host rebuilding it may need
access. Private GitHub visibility does not make the Nix store private: local
users may read fetched sources and outputs. Use a private binary cache if needed.

```sh
nix build path:.#checks.x86_64-linux.skinem-probes --no-link
nix build path:.#checks.x86_64-linux.skinem-invariants --no-link
nix build path:.#checks.x86_64-linux.skinem-credentials --no-link
nix flake check path:. --no-build --show-trace
nix build path:.#nixosConfigurations.tai-lung.config.system.build.toplevel
```

Activate using the existing host deployment workflow only after configuring DNS,
the required encrypted secrets, and backups. The integration is initially disabled
on every host.
