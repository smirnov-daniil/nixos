{self, ...}: {
  flake.nixosModules.vm = {
    config,
    lib,
    ...
  }: let
    cfg = config.features.vm;
  in {
    options.features.vm.adminUser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    config = {
      users.users = lib.mkIf (cfg.adminUser != null) {
        ${cfg.adminUser}.extraGroups = ["incus-admin"];
      };

      networking.nftables.enable = true;

      virtualisation.incus = {
        enable = true;
        preseed = {
          networks = [
            {
              config = {
                "ipv4.address" = "10.0.100.1/24";
                "ipv4.nat" = "true";
              };
              name = "incusbr0";
              type = "bridge";
            }
          ];
          profiles = [
            {
              devices = {
                eth0 = {
                  name = "eth0";
                  network = "incusbr0";
                  type = "nic";
                };
                root = {
                  path = "/";
                  pool = "default";
                  size = "35GiB";
                  type = "disk";
                };
              };
              name = "default";
            }
          ];
          storage_pools = [
            {
              config = {
                source = "/var/lib/incus/storage-pools/default";
              };
              driver = "dir";
              name = "default";
            }
          ];
        };
      };
      networking.firewall.interfaces.incusbr0.allowedTCPPorts = [
        53
        67
      ];
      networking.firewall.interfaces.incusbr0.allowedUDPPorts = [
        53
        67
      ];
      # OR, the entire interface can be trusted.
      # networking.firewall.trustedInterfaces = [ "incusbr0" ];
    };
  };
}
