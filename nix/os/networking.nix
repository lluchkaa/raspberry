{ ... }:
{
  networking = {
    hostName = "raspberry";

    # Static IP configuration
    interfaces = {
      end0 = {
        useDHCP = false;
        ipv4.addresses = [
          {
            address = "192.168.0.103";
            prefixLength = 24;
          }
        ];
      };
      wlan0 = {
        useDHCP = false;
        ipv4.addresses = [
          {
            address = "192.168.0.104";
            prefixLength = 24;
          }
        ];
      };
    };

    wireless = {
      enable = true;
      environmentFile = "/run/secrets/wireless-env";
      networks = {
        "@WIFI_SSID@" = {
          psk = "@WIFI_PSK@";
        };
      };
    };

    defaultGateway = "192.168.0.1";
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
