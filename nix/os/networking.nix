_: {
  networking = {
    hostName = "raspberry";
    useDHCP = true;

    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
        53 # DNS (PiHole)
        80 # HTTP
        443 # HTTPS
        6443 # K8s API
        3000 # Grafana
        8080 # Traefik
        8081 # PiHole admin
      ];
      allowedTCPPortRanges = [
        {
          from = 30000;
          to = 32767;
        }
      ];
      allowedUDPPorts = [
        53 # DNS (PiHole)
        41641 # Tailscale
      ];
      allowedUDPPortRanges = [
        {
          from = 30000;
          to = 32767;
        }
      ];
    };
  };
}
