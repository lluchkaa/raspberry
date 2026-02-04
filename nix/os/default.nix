{ self, username, system, ... }:
{
  imports = [
    ./hardware.nix
    ./networking.nix
    ./k3s.nix
    ./nix.nix
    ./pkgs
    ./user.nix
  ];

  time.timeZone = "Europe/Kyiv";
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.hostPlatform = system;

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
  };

  security.sudo.wheelNeedsPassword = false;

  # Disable man cache generation (fails in Docker builds)
  documentation.man.generateCaches = false;

  system.stateVersion = "25.11";
  system.configurationRevision = self.rev or self.dirtyRev or null;
}
