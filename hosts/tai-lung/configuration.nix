{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.tai-lung-configuration = {
    config,
    lib,
    pkgs,
    ...
  }: let
    persistentServicePaths = {
      bazarr = [config.services.bazarr.dataDir];
      jellyfin = [
        config.services.jellyfin.cacheDir
        config.services.jellyfin.configDir
        config.services.jellyfin.dataDir
      ];
      lidarr = [config.services.lidarr.dataDir];
      prowlarr = [config.services.prowlarr.dataDir];
      qbittorrent = [config.services.qbittorrent.profileDir];
      radarr = [config.services.radarr.dataDir];
      sonarr = [config.services.sonarr.dataDir];
    };
    expectedServicePaths = {
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
  in {
    imports = [
      inputs.nix-minecraft.nixosModules.minecraft-servers
      inputs.sops-nix.nixosModules.default
      self.nixosModules.base
      self.nixosModules.deploy-rs-server
      # self.nixosModules.general
      self.nixosModules.intel
      self.nixosModules.net
      self.nixosModules.nix
      self.nixosModules.sanctum
    ];

    assertions =
      lib.mapAttrsToList (service: paths: {
        assertion = paths == expectedServicePaths.${service};
        message = "${service} state moved away from its persistent Tai Lung path";
      })
      persistentServicePaths
      ++ [
        {
          assertion = lib.all (secret: builtins.hasAttr secret config.sops.secrets) [
            "croc"
            "microbin"
            "ttyd"
            "vaultwarden"
            "xray"
          ];
          message = "Tai Lung Sanctum secrets are not fully declared";
        }
      ];

    system.stateVersion = "25.05";

    preferences = {
      hostname = "tai-lung";
      user.name = "server";
    };
    features.deploy-rs.server = {
      enable = true;
      user = config.preferences.user.name;
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIELPJWLL9894I4Lp3j/BillsJsr1bWTsY12W7DwBpWd6"
      ];
    };
    users.users.${config.preferences.user.name} = {
      isNormalUser = true;
      description = "${config.preferences.user.name}'s account";
      extraGroups = ["wheel" "networkmanager"];
      # hashedPasswordFile = "/persist/passwd";
      # initialPassword = "12345";
    };

    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    environment = {
      sessionVariables.EDITOR = "hx";
      systemPackages = with pkgs; [
        ghostty.terminfo
        git
        jujutsu
        jjui
        helix
      ];
    };

    hardware = {
      bluetooth = {
        enable = true;
        powerOnBoot = false;
      };
      graphics.enable = true;
      nvidia = {
        open = false;
        package = config.boot.kernelPackages.nvidiaPackages.production;
        nvidiaSettings = true;
        prime = {
          offload = {
            enable = true;
            enableOffloadCmd = true;
          };
          sync.enable = false;
          intelBusId = "PCI:0:2:0";
          nvidiaBusId = "PCI:1:0:0";
        };
      };
    };

    services.tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "none";
      # Tailscale SSH: key-less login by tailnet identity, plus the browser
      # console in the Tailscale admin panel.
      extraSetFlags = ["--ssh"];
    };

    # Unattended recovery: reboot on kernel panic and when PID 1 stops
    # feeding the hardware watchdog (the host is only reachable remotely).
    boot.kernel.sysctl."kernel.panic" = 10;
    systemd.settings.Manager = {
      RuntimeWatchdogSec = "30s";
      RebootWatchdogSec = "5min";
    };

    networking = {
      networkmanager.enable = true;
      wireless.iwd.enable = true;
      firewall = {
        enable = true;
        allowedTCPPorts = [22 1234 25565];
        allowedUDPPorts = [500 4500 1701];
        trustedInterfaces = ["tailscale0"];
        checkReversePath = "loose";
      };
      interfaces = {
        enp3s0.useDHCP = true;
        wlan0.useDHCP = false;
      };
    };

    nixpkgs.overlays = [inputs.nix-minecraft.overlay];

    sops = {
      defaultSopsFile = ./secrets/secrets.yaml;
      defaultSopsFormat = "yaml";
      age.keyFile = "/home/${config.preferences.user.name}/.config/sops/age/keys.txt";
    };

    sops.secrets.xray = {};

    services = {
      blueman.enable = true;
      openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        };
      };
      flaresolverr.enable = true;
      xray = {
        enable = true;
        settingsFile = config.sops.secrets.xray.path;
      };
      openvpn.servers.somevpn = {
        config = "config /root/nixos/openvpn/be.ovpn";
        autoStart = false;
      };
      xserver.videoDrivers = ["nvidia"];
      logind.settings.Login = {
        HandleLidSwitch = "ignore";
        HandleLidSwitchDocked = "ignore";
        HandleLidSwitchExternalPower = "ignore";
        HandlePowerKey = "ignore";
        HandleSuspendKey = "ignore";
        IdleAction = "ignore";
      };
      minecraft-servers = {
        enable = true;
        eula = true;
        openFirewall = true;
        servers.minecraft-server = {
          enable = true;
          package = pkgs.vanillaServers.vanilla-1_21;
          serverProperties = {
            gamemode = "survival";
            difficulty = "hard";
            simulation-distance = 32;
          };
          jvmOpts = "-Xmx6G -Xms2G";
        };
      };
    };

    systemd = {
      services = {
        lidarr.unitConfig.RequiresMountsFor = persistentServicePaths.lidarr;
        qbittorrent.unitConfig.RequiresMountsFor = persistentServicePaths.qbittorrent;
      };
      sleep.settings.Sleep = {
        AllowSuspend = "no";
        AllowHibernation = "no";
        AllowHybridSleep = "no";
        AllowSuspendThenHibernate = "no";
      };
      tmpfiles.rules = [
        "d /srv/media     2775 root media -"
        "d /srv/backups   0750 root root  -"
      ];
    };

    time.timeZone = "Europe/Moscow";

    users.groups.media = {};

    fileSystems = {
      "/srv/media" = {
        device = "/dev/disk/by-label/data";
        fsType = "btrfs";
        options = ["subvol=media" "compress=zstd" "noatime"];
      };
      "/srv/backups" = {
        device = "/dev/disk/by-label/data";
        fsType = "btrfs";
        options = ["subvol=backups" "compress=zstd" "noatime"];
      };
      "/srv/radarr" = {
        device = "/dev/disk/by-label/data";
        fsType = "btrfs";
        options = ["subvol=radarr" "compress=zstd" "noatime"];
      };
      "/srv/jellyfin" = {
        device = "/dev/disk/by-label/data";
        fsType = "btrfs";
        options = ["subvol=jellyfin" "compress=zstd" "noatime"];
      };
      "/srv/sonarr" = {
        device = "/dev/disk/by-label/data";
        fsType = "btrfs";
        options = ["subvol=sonarr" "compress=zstd" "noatime"];
      };
      "/srv/prowlarr" = {
        device = "/dev/disk/by-label/data";
        fsType = "btrfs";
        options = ["subvol=prowlarr" "compress=zstd" "noatime"];
      };
      "/srv/qbittorrent" = {
        device = "/dev/disk/by-label/data";
        fsType = "btrfs";
        options = ["subvol=qbittorrent" "compress=zstd" "noatime"];
      };
      "/srv/bazarr" = {
        device = "/dev/disk/by-label/data";
        fsType = "btrfs";
        options = ["subvol=bazarr" "compress=zstd" "noatime"];
      };
    };

    zramSwap = {
      enable = true;
      algorithm = "lz4";
      memoryPercent = 100;
      priority = 999;
    };

    sanctum = {
      domain = "ssmirnovd.online";
      ip = "178.66.51.192";
      nginx = {
        enable = true;
        acmeEmail = "ssmirnovd@bk.ru";
        # Inbound TCP/22 is filtered upstream; SSH rides the HTTPS port instead.
        sshOverTls.enable = true;
      };
      # Browser admin access; public for now, later restrict with
      # sanctum.services.{ttyd,cockpit}.allowedNetworks = ["100.64.0.0/10"].
      ttyd.enable = true;
      cockpit.enable = true;
      croc.enable = true;
      vaultwarden.enable = true;
      homepage = {
        enable = true;
        title = "My Sanctum Dashboard";
      };
      microbin.enable = true;
      bazarr.enable = true;
      jellyseerr.enable = true;
      lidarr.enable = true;
      prowlarr.enable = true;
      radarr.enable = true;
      sonarr.enable = true;
      jellyfin.enable = true;
      qbittorrent.enable = true;
      skinem = {
        # Temporarily off: keeps the local rebuild small. Re-enable after the
        # host is reachable again; the module (and its flake input) stays imported.
        enable = false;
        secrets = {
          TELEGRAM_BOT_TOKEN = "skinem/bot-token";
          WEBHOOK_SECRET = "skinem/webhook-secret";
          TELEGRAM_GROUPS_SECRET = "skinem/groups-secret";
          TELEGRAM_LOGIN_CLIENT_SECRET = "skinem/login-client-secret";
          TELEGRAM_LOGIN_SUBJECT_SECRET = "skinem/login-subject-secret";
          PROVERKACHEKA_TOKEN = "skinem/proverkacheka-token";
        };
        environment = {
          SKINEM_TELEGRAM_GROUPS = "1";
          TELEGRAM_API_BASE = "https://skinem-telegram-relay.danogun.workers.dev";
          WEBHOOK_URL = "https://skinem-telegram-relay.danogun.workers.dev/tg/webhook";
          TELEGRAM_LOGIN_API_BASE = "https://skinem-telegram-relay.danogun.workers.dev";
          TELEGRAM_LOGIN_CLIENT_ID = "7528531098";
          TELEGRAM_LOGIN_REDIRECT_URI = "https://split.ssmirnovd.online/";
        };
      };
    };
  };
}
