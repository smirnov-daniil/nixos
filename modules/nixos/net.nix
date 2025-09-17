{pkgs, ...}: {
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

  environment.systemPackages = [pkgs.networkmanager-l2tp];

  # for VPN
  networking.firewall.allowedUDPPorts = [500 4500 1701];

  services.openvpn.servers = {
    somevpn = {
      config = "config /root/nixos/openvpn/be.ovpn";
      autoStart = false;
    };
  };
}
