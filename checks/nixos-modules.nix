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
    lib = inputs.nixpkgs.lib;
    nixosSystem = inputs.nixpkgs.lib.nixosSystem;
    stateVersion = {
      boot.isContainer = true;
      nixpkgs.config.allowUnfree = true;
      system.stateVersion = "25.11";
    };
    evaluate = module:
      nixosSystem {
        inherit system;
        modules = [module stateVersion];
      };
    evaluationCheck = name: module:
      builtins.seq (evaluate module).config.system.build.toplevel.drvPath (
        pkgs.runCommand "nixos-module-${name}" {} "touch $out"
      );
    hostEvaluationCheck = name: host:
      builtins.seq host.config.system.build.toplevel.drvPath (
        pkgs.runCommand "nixos-host-${name}" {} "touch $out"
      );
    leaves = {
      preferences = self.nixosModules.preferences;
      user-environment = self.nixosModules.user-environment;
      desktop-session = self.nixosModules.desktop-session;
      deploy-rs-server = self.nixosModules.deploy-rs-server;
      deploy-rs-initiator = self.nixosModules.deploy-rs-initiator;
      gtk = self.nixosModules.gtk;
      intel = self.nixosModules.intel;
      net = self.nixosModules.net;
      nix = self.nixosModules.nix;
      pipewire = self.nixosModules.pipewire;
      vm = self.nixosModules.vm;
      wsl = self.nixosModules.wsl;
      zen-browser = self.nixosModules.zen-browser;
      browsec = self.nixosModules.browsec;
      sanctum-core = self.nixosModules.sanctum-core;
      sanctum-bazarr = self.nixosModules.sanctum-bazarr;
      sanctum-croc = self.nixosModules.sanctum-croc;
      sanctum-homepage = self.nixosModules.sanctum-homepage;
      sanctum-jellyfin = self.nixosModules.sanctum-jellyfin;
      sanctum-jellyseerr = self.nixosModules.sanctum-jellyseerr;
      sanctum-lidarr = self.nixosModules.sanctum-lidarr;
      sanctum-microbin = self.nixosModules.sanctum-microbin;
      sanctum-nginx = self.nixosModules.sanctum-nginx;
      sanctum-prowlarr = self.nixosModules.sanctum-prowlarr;
      sanctum-qbittorrent = self.nixosModules.sanctum-qbittorrent;
      sanctum-radarr = self.nixosModules.sanctum-radarr;
      sanctum-sonarr = self.nixosModules.sanctum-sonarr;
      sanctum-vaultwarden = self.nixosModules.sanctum-vaultwarden;
    };
    aggregates = {
      base = self.nixosModules.base;
      general = self.nixosModules.general;
      desktop = self.nixosModules.desktop;
      deploy-rs = self.nixosModules.deploy-rs;
      sanctum = self.nixosModules.sanctum;
    };
    enableSanctum = name: module: {
      imports = [module];
      sanctum.${name}.enable = true;
    };
    enableSecretSanctum = name: module: {
      imports = [module];
      sanctum.${name}.enable = true;
      sops = {
        defaultSopsFile = ../hosts/tai-lung/secrets/secrets.yaml;
        age.keyFile = "/tmp/age-key.txt";
      };
    };
    enabledLeaves = {
      sanctum-bazarr = enableSanctum "bazarr" self.nixosModules.sanctum-bazarr;
      sanctum-croc = enableSecretSanctum "croc" self.nixosModules.sanctum-croc;
      sanctum-homepage = enableSanctum "homepage" self.nixosModules.sanctum-homepage;
      sanctum-jellyfin = enableSanctum "jellyfin" self.nixosModules.sanctum-jellyfin;
      sanctum-jellyseerr = enableSanctum "jellyseerr" self.nixosModules.sanctum-jellyseerr;
      sanctum-lidarr = enableSanctum "lidarr" self.nixosModules.sanctum-lidarr;
      sanctum-microbin = enableSecretSanctum "microbin" self.nixosModules.sanctum-microbin;
      sanctum-nginx = enableSanctum "nginx" self.nixosModules.sanctum-nginx;
      sanctum-prowlarr = enableSanctum "prowlarr" self.nixosModules.sanctum-prowlarr;
      sanctum-qbittorrent = enableSanctum "qbittorrent" self.nixosModules.sanctum-qbittorrent;
      sanctum-radarr = enableSanctum "radarr" self.nixosModules.sanctum-radarr;
      sanctum-sonarr = enableSanctum "sonarr" self.nixosModules.sanctum-sonarr;
      sanctum-vaultwarden = enableSecretSanctum "vaultwarden" self.nixosModules.sanctum-vaultwarden;
      vm-admin = {
        imports = [self.nixosModules.vm];
        features.vm.adminUser = "operator";
        users.users.operator.isNormalUser = true;
      };
      browsec-user = {
        imports = [self.nixosModules.browsec];
        programs.browsec.users = ["operator"];
        users.users.operator.isNormalUser = true;
      };
      deploy-rs-server = {
        imports = [self.nixosModules.deploy-rs-server];
        features.deploy-rs.server = {
          enable = true;
          user = "operator";
        };
        users.users.operator.isNormalUser = true;
      };
      deploy-rs-initiator = {
        imports = [self.nixosModules.deploy-rs-initiator];
        features.deploy-rs.initiator.enable = true;
      };
    };
    hostsForSystem = lib.filterAttrs (_: host: host.pkgs.stdenv.hostPlatform.system == system) self.nixosConfigurations;
    taiLung = self.nixosConfigurations.tai-lung.config;
    isTaiLungSystem = self.nixosConfigurations.tai-lung.pkgs.stdenv.hostPlatform.system == system;
    gru = self.nixosConfigurations.gru.config;
    deployPackage = inputs.deploy-rs.packages.${system}.default;
    hasPasswordlessSudo = lib.any (rule:
      lib.any (command: lib.elem "NOPASSWD" (command.options or [])) rule.commands)
    taiLung.security.sudo.extraRules;
    persistentPaths = {
      bazarr = [taiLung.services.bazarr.dataDir];
      jellyfin = [
        taiLung.services.jellyfin.cacheDir
        taiLung.services.jellyfin.configDir
        taiLung.services.jellyfin.dataDir
      ];
      lidarr = [taiLung.services.lidarr.dataDir];
      prowlarr = [taiLung.services.prowlarr.dataDir];
      qbittorrent = [taiLung.services.qbittorrent.profileDir];
      radarr = [taiLung.services.radarr.dataDir];
      sonarr = [taiLung.services.sonarr.dataDir];
    };
    expectedPaths = {
      bazarr = ["/srv/bazarr"];
      jellyfin = [
        "/srv/jellyfin/cache"
        "/srv/jellyfin/config"
        "/srv/jellyfin/data"
      ];
      lidarr = ["/srv/lidarr"];
      prowlarr = ["/srv/prowlarr"];
      qbittorrent = ["/srv/qbittorrent"];
      radarr = ["/srv/radarr"];
      sonarr = ["/srv/sonarr"];
    };
    taiLungInvariants = assert persistentPaths == expectedPaths;
    assert lib.all (name: builtins.hasAttr name taiLung.sops.secrets) [
      "croc"
      "microbin"
      "vaultwarden"
      "xray"
    ];
    assert taiLung.sops.age.keyFile == "/home/server/.config/sops/age/keys.txt";
    assert lib.elem pkgs.ghostty.terminfo taiLung.environment.systemPackages;
    assert !lib.elem deployPackage taiLung.environment.systemPackages;
    assert lib.elem deployPackage gru.environment.systemPackages;
    assert !taiLung.features.deploy-rs.server.passwordlessSudo;
    assert !hasPasswordlessSudo;
    assert self.deploy.nodes.tai-lung.hostname == "tai-lung.ssmirnovd.online";
      pkgs.runCommand "tai-lung-invariants" {
        systemPath = taiLung.system.build.toplevel;
      } ''
        test ! -e "$systemPath/sw/bin/ghostty"
        test -e "$systemPath/sw/share/terminfo/x/xterm-ghostty"
        touch "$out"
      '';
  in {
    checks =
      lib.mapAttrs' (name: module: {
        name = "nixos-module-${name}";
        value = evaluationCheck name module;
      })
      leaves
      // lib.mapAttrs' (name: module: {
        name = "nixos-aggregate-${name}";
        value = evaluationCheck "aggregate-${name}" module;
      })
      aggregates
      // lib.mapAttrs' (name: module: {
        name = "nixos-enabled-${name}";
        value = evaluationCheck "enabled-${name}" module;
      })
      enabledLeaves
      // lib.mapAttrs hostEvaluationCheck hostsForSystem
      // lib.optionalAttrs isTaiLungSystem {
        tai-lung-toplevel = taiLung.system.build.toplevel;
        tai-lung-invariants = taiLungInvariants;
      };
  };
}
