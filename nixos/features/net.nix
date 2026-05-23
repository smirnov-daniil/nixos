{self, ...}: {
  flake.nixosModules.net = {
    pkgs,
    config,
    ...
  }: {
    networking = {
      networkmanager = {
        plugins = with pkgs; [networkmanager-l2tp];
        wifi.backend = "iwd";
      };

      wireless.iwd = {
        settings = {
          IPv6 = {
            Enabled = true;
          };
          Settings = {
            AutoConnect = true;
          };
        };
      };
      hostName = "${config.preferences.hostname}";
      nameservers = ["1.1.1.1" "8.8.8.8" "77.88.8.8"];

      nftables.enable = true;
    };

    environment.systemPackages = [pkgs.networkmanager-l2tp];
  };
}
