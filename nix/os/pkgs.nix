{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.git
    pkgs.jujutsu
    pkgs.vim
    pkgs.wget
    pkgs.curl
    pkgs.htop
    pkgs.gcc
    pkgs.cachix
    pkgs.fish
    pkgs.zsh
    pkgs.kubectl
    pkgs.helm
    pkgs.k9s
  ];
}
