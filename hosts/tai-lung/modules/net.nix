{... }:
{
  networking = {
    firewall = {
      enable = true;
      extraCommands = ''
        iptables -A nixos-fw -p tcp --source 192.168.31.6/24 --dport 22:22 -j nixos-fw-accept
        iptables -A nixos-fw -p udp --source 192.168.31.6/24 --dport 22:22 -j nixos-fw-accept
      '';
      extraStopCommands = ''
        iptables -D nixos-fw -p tcp --source 192.168.31.6/24 --dport 22:22 -j nixos-fw-accept || true
        iptables -D nixos-fw -p udp --source 192.168.31.6/24 --dport 22:22 -j nixos-fw-accept || true
      '';
    };
    interfaces = {
      enp3s0.useDHCP= true;
      wlan0.useDHCP = false;
    };
  };
}
