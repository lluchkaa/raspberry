{ self, username, system, ... }:
{
  imports = [
    ./hardware
    ./networking
    ./k3s
    ./secrets
    ./nix
    ./pkgs
    ./user
  ];

  # System
  time.timeZone = "Europe/Kyiv";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.hostPlatform = system;

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Sudo
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "24.11";
  system.configurationRevision = self.rev or self.dirtyRev or null;
}
