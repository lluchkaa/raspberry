{ ... }:
{
  networking = {
    hostName = "raspberry";

    # Static IP configuration
    interfaces.end0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.1.100";
          prefixLength = 24;
        }
      ];
    };

    defaultGateway = "192.168.1.1";
    nameservers = [
      "1.1.1.1"
      "8.8.8.8"
    ];

    # Firewall
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
        53 # DNS (PiHole)
        80 # HTTP
        443 # HTTPS
        6443 # K8s API
      ];
      allowedUDPPorts = [
        53 # DNS (PiHole)
      ];
    };
  };
}
