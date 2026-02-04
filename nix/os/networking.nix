{ ... }:
{
  networking = {
    hostName = "raspberry";
    useDHCP = true;

    firewall = {
      enable = true;
      allowedTCPPorts = [
        22    # SSH
        53    # DNS (PiHole)
        80    # HTTP
        443   # HTTPS
        6443  # K8s API
      ];
      allowedUDPPorts = [
        53    # DNS (PiHole)
      ];
    };
  };
}
