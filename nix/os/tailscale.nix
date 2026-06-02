_: {
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    authKeyFile = "/etc/tailscale-authkey";
    extraUpFlags = [ "--advertise-exit-node" ];
  };
}
