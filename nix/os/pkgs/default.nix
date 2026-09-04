{ pkgs, ... }:
{
  programs = {
    git.enable = true;
    vim.enable = true;
    neovim.enable = true;
    htop.enable = true;
    fish.enable = true;
    zsh.enable = true;
  };

  environment.systemPackages = [
    pkgs.wget
    pkgs.curl
    pkgs.gcc
    pkgs.cachix
    pkgs.kubectl
    pkgs.kubernetes-helm
    pkgs.k9s
    pkgs.fluxcd
  ];
}
