{... }:
{
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
    interfaces = {
      enp3s0.useDHCP= true;
      wlan0.useDHCP = false;
    };
  };
}
