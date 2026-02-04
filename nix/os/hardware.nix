{ config, lib, pkgs, ... }:

{
  # Enable cgroup memory for k3s/containers
  boot.kernelParams = [
    "cgroup_enable=cpuset"
    "cgroup_enable=memory"
    "cgroup_memory=1"
  ];

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
