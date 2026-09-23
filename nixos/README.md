# NixOS modules

`base` is the compatibility aggregate for `preferences`; import `preferences` directly when a feature only needs shared host and user settings.

Independent feature leaves are `user-environment`, `desktop-session`, `deploy-rs-server`, `deploy-rs-initiator`, `net`, `vm`, `wsl`, `nix`, `gtk`, `pipewire`, `intel`, `zen-browser`, and `browsec`. `user-environment`, `desktop-session`, `net`, and `wsl` import `preferences` automatically. `wsl` imports `nixos-wsl`, and `nix` imports `nix-index-database`. Set `features.vm.adminUser` when an existing account should join `incus-admin`; importing `vm` alone does not create an account or enable unrelated network policy.

`general` remains a compatibility aggregate for `user-environment`, `nix`, and `net`. `deploy-rs` aggregates the disabled server and initiator roles: the server role enables SSH and wheel membership for its explicit user, while the initiator role installs only the deploy-rs client. Passwordless activation is opt-in; Tai Lung uses interactive sudo and Gru is the initiator. `desktop` remains a compatibility aggregate for `desktop-session`, `gtk`, `pipewire`, and `zen-browser`, plus workstation networking, fonts, Bluetooth, and timezone policy.

Package defaults can be overridden through `user-environment.shellPackage`, `user-environment.nhPackage`, `desktop-session.terminalPackage`, `desktop-session.quickshellPackage`, `programs.zen-browser.package`, and `programs.browsec.package`. `user-environment.extraGroups` defaults to an empty list; the `general` compatibility aggregate restores the existing `wheel` and `networkmanager` memberships. The desktop session passes its Quickshell package to the Niri wrapper. `programs.browsec.users` defaults to an empty list; grant its passwordless helper access explicitly.

Deploy Tai Lung from Gru with `devenv --profile tai-lung shell flake-deploy`. First run `devenv --profile tai-lung tasks run flake:deploy-check` for a local evaluation-only preflight; it does not contact the server. The wrapper uses the flake's pinned deploy-rs client and filtered working-tree snapshot, requires a terminal, and never runs from shell entry, tests, or CI. See [the development guide](../README.md#deployment) for details.

The deployment profile connects to `ssmirnovd.online`, activates `nixosConfigurations.tai-lung` as root through the SSH user `server`, and preserves deploy-rs magic rollback and automatic rollback defaults. Tai Lung authorizes Gru's personal Ed25519 key declaratively; its matching private key must remain at `~/.ssh/personal` on Gru, and interactive activation asks for the existing `server` sudo password. The existing lower-level `deploy .#tai-lung` command is still available on Gru, but does not use the devenv wrapper's filtered snapshot or terminal/CI safeguards.

`sanctum-core` supplies the shared Sanctum schema. Every `sanctum-*` service leaf imports it, while `sanctum` aggregates the core and every service leaf. `sanctum-croc`, `sanctum-microbin`, `sanctum-vaultwarden`, and `sanctum-skinem` import SOPS themselves; hosts using other leaves do not need SOPS unless they configure it independently.

[skinem](features/sanctum/skinem/README.md) provides independent web access, nginx TLS,
optional Telegram credentials, and read-only Homepage availability probes. It is
disabled by default and obtains private source through the SSH flake input.
