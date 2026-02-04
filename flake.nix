{
  description = "NixOS configuration for Raspberry Pi 5";

  nixConfig = {
    extra-substituters = [
      "https://nixos-raspberrypi.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    connect-timeout = 5;
  };

  inputs = {
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
  };

  outputs =
    {
      self,
      nixos-raspberrypi,
      ...
    }@inputs:
    let
      system = "aarch64-linux";
      username = "ll-raspberry";
    in
    {
      nixosConfigurations.raspberry = nixos-raspberrypi.lib.nixosSystemFull {
        specialArgs = {
          inherit self username system;
          inherit nixos-raspberrypi;
        };
        modules = [
          ({ nixos-raspberrypi, ... }: {
            imports = with nixos-raspberrypi.nixosModules; [
              raspberry-pi-5.base
              raspberry-pi-5.page-size-16k
              sd-image
            ];
          })
          ./nix/os
        ];
      };

      # Build with: nix build .#images.raspberry
      images.raspberry = self.nixosConfigurations.raspberry.config.system.build.sdImage;
    };
}
