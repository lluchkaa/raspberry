{ config, lib, pkgs, ... }:

{
  # Boot configuration (U-Boot / extlinux for Pi 5)
  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  # Hardware settings handled by nixos-hardware.raspberry-pi-5 module
  # (kernel, firmware, device tree, GPU)

  # Filesystem mounts
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };

  # Swap (optional, useful on a Pi with limited RAM)
  swapDevices = [{
    device = "/swapfile";
    size = 2048; # MB
  }];
}
