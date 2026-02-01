{
  description = "NixOS configuration for Raspberry Pi 5";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs?ref=nixos-unstable";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      make = import ./nix/lib/make.nix {
        inherit nixpkgs inputs;
      };
    in
    {
      nixosConfigurations.raspberry = make {
        system = "aarch64-linux";
        username = "ll-raspberry";
      };
    };
}
