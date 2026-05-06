{self, ...}: {
  flake.nixosModules.net = {pkgs, ...}: {
    networking = {
      networkmanager = {
        enable = true;
        plugins = with pkgs; [networkmanager-l2tp];
        wifi.backend = "iwd";
      };

      wireless.iwd = {
        enable = true;

        settings = {
          IPv6 = {
            Enabled = true;
          };
          Settings = {
            AutoConnect = true;
          };
        };
      };
    };

    # nftables.enable = true;

    environment.systemPackages = [pkgs.networkmanager-l2tp];
  };
}
