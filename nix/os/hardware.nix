{ config, lib, pkgs, ... }:

{
  # Boot configuration is handled by nixos-raspberrypi modules
  # (raspberry-pi-5.base configures the bootloader automatically)

  # Filesystem mounts
  fileSystems = {
    # Firmware partition (managed by nixos-raspberrypi bootloader)
    "/boot/firmware" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
      options = [
        "noatime"
        "noauto"
        "x-systemd.automount"
        "x-systemd.idle-timeout=1min"
      ];
    };

    # Root filesystem
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  # Swap (useful on Pi with limited RAM)
  swapDevices = [{
    device = "/swapfile";
    size = 2048; # MB
  }];
}
