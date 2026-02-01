{ config, pkgs, ... }:
{
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      "--disable=traefik" # Manage ingress via Helm instead
      "--write-kubeconfig-mode=644"
    ];
  };

  # Ensure k3s prerequisites
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
}
