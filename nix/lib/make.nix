{
  nixpkgs,
  inputs,
}:
{
  system,
  username,
}:
let
  inherit (inputs) self nixos-hardware sops-nix;
in
nixpkgs.lib.nixosSystem {
  inherit system;

  specialArgs = {
    inherit self username system;
  };

  modules = [
    nixos-hardware.nixosModules.raspberry-pi-5
    sops-nix.nixosModules.sops

    ../os
  ];
}
