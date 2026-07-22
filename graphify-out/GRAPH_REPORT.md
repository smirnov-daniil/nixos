# Graph Report - /tmp/graphify-flake-corpus  (2026-07-22)

## Corpus Check
- Corpus is ~8,407 words - fits in a single context window. You may not need a graph.

## Summary
- 145 nodes · 119 edges · 41 communities (12 shown, 29 thin omitted)
- Extraction: 89% EXTRACTED · 11% INFERRED · 0% AMBIGUOUS · INFERRED: 13 edges (avg confidence: 0.9)
- Token cost: 30,300 input · 26,000 output

## Community Hubs (Navigation)
- Desktop App Wrappers
- Lich User Networking
- Host Configurations
- Desktop Session Modules
- Gru Secrets NVIDIA
- Shell CLI Wrappers
- Nix Tooling Module
- Flake Parts Wrappers
- Auto Import Flake
- CI Workflow
- Intel Graphics
- Zen Browser
- NixGL Host
- WSL Mounts
- Herdr Wrapper
- Agent Instructions
- Architecture Overview
- NixOS Modules
- Packages Overview
- Pi Integration
- Development Commands
- Claude Guidance
- Host Pattern
- Preferences Namespace
- QuickShell Shell
- Theme Exports
- No Home Manager
- Claude Settings
- Claude Permissions
- Flake Root
- Wrapper Modules Input
- Wrappers Input
- Workflow File
- Aku Configuration
- Gru Boot Kernel
- Gru Imports
- Gru Filesystems
- Pi Sync Note
- Nix Check App
- Git Wrapper
- Readme Summary

## God Nodes (most connected - your core abstractions)
1. `flake.wrappersModules.niri Niri wrapper module` - 7 edges
2. `preferences.user identity options` - 6 edges
3. `NixOS module desktop (nixos/features/desktop.nix)` - 6 edges
4. `theme.nix base16 theme palette` - 6 edges
5. `flake.nixosModules.aku` - 5 edges
6. `flake.nixosModules.gru` - 5 edges
7. `flake.nixosModules.lich` - 4 edges
8. `NixOS module net (nixos/features/net.nix)` - 4 edges
9. `Zsh integrations for fzf oh-my-posh zoxide completions autosuggestions and history` - 4 edges
10. `flake.wrappersModules option submodule namespace` - 4 edges

## Surprising Connections (you probably didn't know these)
- `aku imports wsl, base, general, vm modules` --semantically_similar_to--> `lich imports wsl, base, general modules`  [INFERRED] [semantically similar]
  hosts__aku__configuration.nix.md → hosts__lich__configuration.nix.md
- `myTools CLI and wrapped package toolset` --semantically_similar_to--> `Nix tooling packages nil nixd statix alejandra manix nix-inspect`  [INFERRED] [semantically similar]
  packages__environment.nix.md → nixos__features__nix.nix.md
- `normal user account from preferences.user.name` --references--> `preferences.user identity options`  [EXTRACTED]
  nixos__features__general.nix.md → nixos__base__user.nix.md
- `Oh My Posh jujutsu prompt segment showing change ID bookmarks and working changes` --conceptually_related_to--> `packages.jujutsu wrapper with log alias default command and snapshot limit`  [INFERRED]
  packages__oh-my-posh.nix.md → packages__jujutsu.nix.md
- `flake.wrappersModules option submodule namespace` --conceptually_related_to--> `flake.wrappersModules.niri Niri wrapper module`  [INFERRED]
  parts.nix.md → packages__niri.nix.md

## Hyperedges (group relationships)
- **flake.nix auto-imports repository .nix files into flake-parts mkFlake** — flake_nix_mkflake_structure, flake_nix_import_tree, agents_md_auto_import_flake_parts, claude_md_auto_import_contract [INFERRED 0.95]
- **Host files define module plus nixosConfiguration and generated hardware** — claude_md_hosts_pattern, hosts_aku_configuration_nix_module_aku, hosts_aku_default_nix_nixos_configuration_aku, hosts_aku_hardware_nix_aku_hardware_module, hosts_gru_configuration_nix_module_gru, hosts_gru_default_nix_nixos_configuration_gru, hosts_gru_hardware_nix_gru_hardware_module, hosts_lich_configuration_nix_module_lich, hosts_lich_default_nix_nixos_configuration_lich [INFERRED 0.95]
- **aku and lich share WSL/base/general host module imports** — hosts_aku_configuration_nix_module_aku, hosts_aku_configuration_nix_aku_imports, hosts_lich_configuration_nix_module_lich, hosts_lich_configuration_nix_lich_imports, flake_nix_input_nixos_wsl [INFERRED 0.85]
- **Pi integration aligns Claude instructions, skills, runtime inputs, and workflow tiers** — agents_md_pi_agent_integration, claude_md_pi_package_integration, notes_md_pi_claude_sync_rationale, flake_nix_input_pi [INFERRED 0.85]
- **desktop module composes GTK, PipeWire, and Zen Browser modules** — nixos_features_desktop_nixos_module_desktop, nixos_features_gtk_nixos_module_gtk, nixos_features_pipewire_nixos_module_pipewire, nixos_features_zen_browser_nixos_module_zen_browser [EXTRACTED 1.00]
- **general module composes nix and net modules** — nixos_features_general_nixos_module_general, nixos_features_nix_nixos_module_nix, nixos_features_net_nixos_module_net [EXTRACTED 1.00]
- **user identity preferences feed account, VCS env, WSL, VM, and Browsec sudo rules** — nixos_base_user_preferences_user_identity, nixos_features_general_user_account, nixos_features_general_git_jj_identity_environment, nixos_features_wsl_configuration, nixos_features_vm_nixos_module_vm, packages_browsec_nixos_module_browsec [EXTRACTED 1.00]
- **Browsec derivation supplies VPN app while module installs it and grants helper sudo** — packages_browsec_package_browsec, packages_browsec_nixos_module_browsec, packages_browsec_apparmor_sandbox_profile [EXTRACTED 1.00]
- **environment package wraps zsh with myTools and exposes related desktop terminal completions utilities** — packages_environment_package_environment, packages_environment_mytools_toolset, packages_environment_package_desktop, packages_environment_package_terminal, packages_environment_package_nix_check_bin [EXTRACTED 1.00]
- **Theme shared by terminal editor shell compositor launcher and quickshell** — theme_base16_palette, packages_ghostty, packages_helix_flake_theme, packages_quickshell_theme_env, packages_wlr_which_key_mkwhichkeyexe, packages_niri_wrappers_modules_niri, packages_zsh_integrations [INFERRED 0.95]
- **Interactive shell workflow links zsh fzf oh-my-posh jujutsu and nh switch** — packages_zsh, packages_fzf_history, packages_fzf_files, packages_oh_my_posh, packages_oh_my_posh_jujutsu_segment, packages_jujutsu, packages_nh, packages_zsh_workflow_aliases [INFERRED 0.85]
- **Desktop session stack combines niri ghostty quickshell which-key media controls and Zen Browser** — packages_niri, packages_niri_wrappers_modules_niri, packages_ghostty, packages_quickshell_wrapped, packages_wlr_which_key_mkwhichkeyexe, packages_niri_media_screenshot_binds, packages_zen_browser [INFERRED 0.85]

## Communities (41 total, 29 thin omitted)

### Community 0 - "Desktop App Wrappers"
Cohesion: 0.14
Nodes (18): packages/ghostty.nix Ghostty terminal wrapper, Ghostty nixglhost entrypoint with NixOS skip logic and desktop Exec rewrite, packages/helix.nix Helix editor wrapper, Helix base16 flake theme generated from self.theme, Helix language servers and formatters for nix rust haskell c cpp cmake json markdown, packages.niri built with wrapper-modules niri wrapper, Niri media brightness audio and screenshot key bindings, Niri option autostart for extra startup commands or packages (+10 more)

### Community 1 - "Lich User Networking"
Cohesion: 0.13
Nodes (17): NixOS module lich (hosts/lich/hardware.nix), lich WSL-oriented filesystems and mounts, x86_64-linux host platform for lich, NixOS module base user options (nixos/base/user.nix), preferences.hostname option default nixos, preferences.user identity options, Git and Jujutsu identity environment variables, hostname, DNS nameservers, and nftables networking (+9 more)

### Community 2 - "Host Configurations"
Cohesion: 0.14
Nodes (14): Hosts area /hosts with aku, gru, lich, aku imports wsl, base, general, vm modules, aku networking.networkmanager.enable = true, NixOS host aku, flake.nixosModules.aku, flake.nixosConfigurations.aku via nixpkgs.lib.nixosSystem, aku generated hardware module, NixOS host gru (+6 more)

### Community 3 - "Desktop Session Modules"
Cohesion: 0.14
Nodes (14): NixOS module base autostart options (nixos/base/start.nix), preferences.autostart option, greetd tuigreet login for niri-session, swayidle quickshell lock and monitor power workflow, niri desktop session wrapped with autostart, NixOS module desktop (nixos/features/desktop.nix), Gruvbox GTK theme and icon configuration, NixOS module gtk (nixos/features/gtk.nix) (+6 more)

### Community 4 - "Gru Secrets NVIDIA"
Cohesion: 0.18
Nodes (11): Pi coding agent packaged via packages/pi and environment tools, flake input nixpkgs github:NixOS/nixpkgs/nixos-unstable, flake input pi github:lukasl-dev/pi.nix follows nixpkgs, flake input sops-nix follows nixpkgs, flake.nixosModules.gru, gru NVIDIA PRIME offload configuration, gru sops secrets configuration with age keyFile, flake.nixosConfigurations.gru via nixpkgs.lib.nixosSystem (+3 more)

### Community 5 - "Shell CLI Wrappers"
Cohesion: 0.22
Nodes (10): packages.fzf-files wrapper with bat preview and editor bind, packages.fzf wraps pkgs.fzf with fd default command and fzf options, packages.fzf-history wrapper with history-oriented fzf flags, packages/fzf.nix fzf wrapper package set, packages/nh.nix nh wrapper with NH_FLAKE=$HOME/flake, packages/oh-my-posh.nix Oh My Posh wrapper with TOML prompt config, Oh My Posh jujutsu prompt segment showing change ID bookmarks and working changes, packages/zsh.nix Zsh wrapper shell configuration (+2 more)

### Community 6 - "Nix Tooling Module"
Cohesion: 0.25
Nodes (8): nh enable and cleanup workflow, NixOS module general (nixos/features/general.nix), normal user account from preferences.user.name, Nix settings for cachix, trusted users, nix-command and flakes, NixOS module nix tooling (nixos/features/nix.nix), Nix tooling packages nil nixd statix alejandra manix nix-inspect, myTools CLI and wrapped package toolset, wrapped shell environment package with primary tools

### Community 7 - "Flake Parts Wrappers"
Cohesion: 0.29
Nodes (7): packages.jujutsu wrapper with log alias default command and snapshot limit, packages.jjui wrapper using defaultRevset all(), flake.wrappersModules.jjui wrapModule defining settings option and JJUI_CONFIG_DIR, perSystem formatter is pkgs.alejandra, parts.nix flake-parts structure imports wrapper modules and flake modules, flake.wrappersModules option submodule namespace, flake systems includes x86_64-linux

### Community 8 - "Auto Import Flake"
Cohesion: 0.40
Nodes (5): Auto-import every .nix file as flake-parts module, Auto-import contract: every .nix file must be valid flake-parts module unless prefixed _, importTree filters .nix files excluding flake.nix and _-prefixed files, flake input flake-parts github:hercules-ci/flake-parts, flake-parts mkFlake imports = importTree ./. structure

### Community 9 - "CI Workflow"
Cohesion: 0.67
Nodes (3): CI step: nix build .#environment, GitHub Actions workflow check, CI step: nix flake check

### Community 10 - "Intel Graphics"
Cohesion: 1.00
Nodes (3): custom-hardware.intelgpu options, NixOS module intel hardware graphics (nixos/features/intel.nix), Intel VAAPI, media, OpenCL, compute runtime graphics packages

### Community 11 - "Zen Browser"
Cohesion: 0.67
Nodes (3): packages.zen-browser nixglhost wrapper for Zen Browser, packages.zen-browser-plain wrapped Zen Browser for NixOS hosts, Zen Browser locked prefs policies extensions and Nix search engines

## Knowledge Gaps
- **67 isolated node(s):** `.claude/settings.local.json`, `Claude local permission: Read //home/smirnovd/.claude/plugins/**`, `.github/workflows/check.yml`, `CI step: nix flake check`, `CI step: nix build .#environment` (+62 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **29 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `theme.nix base16 theme palette` connect `Desktop App Wrappers` to `Shell CLI Wrappers`?**
  _High betweenness centrality (0.030) - this node is a cross-community bridge._
- **Why does `Zsh integrations for fzf oh-my-posh zoxide completions autosuggestions and history` connect `Shell CLI Wrappers` to `Desktop App Wrappers`?**
  _High betweenness centrality (0.023) - this node is a cross-community bridge._
- **What connects `.claude/settings.local.json`, `Claude local permission: Read //home/smirnovd/.claude/plugins/**`, `.github/workflows/check.yml` to the rest of the system?**
  _67 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Desktop App Wrappers` be split into smaller, more focused modules?**
  _Cohesion score 0.13725490196078433 - nodes in this community are weakly interconnected._
- **Should `Lich User Networking` be split into smaller, more focused modules?**
  _Cohesion score 0.1323529411764706 - nodes in this community are weakly interconnected._
- **Should `Host Configurations` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._
- **Should `Desktop Session Modules` be split into smaller, more focused modules?**
  _Cohesion score 0.14285714285714285 - nodes in this community are weakly interconnected._