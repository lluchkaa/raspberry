{
  username,
  pkgs,
  ...
}:
{
  nix = {
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';

    settings = {
      trusted-users = [
        "root"
        "@admin"
        username
      ];

      experimental-features = [
        "nix-command"
        "flakes"
      ];

      substituters = [
        "https://nix-community.cachix.org"
        "https://lluchkaa.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "lluchkaa.cachix.org-1:OZsJHkBMAfwSUm1gHwqKMA/iaLiyRuC9X90Bp+kX7UI="
      ];
      builders-use-substitutes = true;
    };

    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
  };

  nixpkgs.config.allowUnfree = true;
}
