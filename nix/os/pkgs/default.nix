{ pkgs, ... }:
{
  programs.git = {
    enable = true;
  };

  programs.vim = {
    enable = true;
  };

  programs.neovim = {
    enable = true;
  };

  programs.htop = {
    enable = true;
  };

  programs.fish = {
    enable = true;
  };

  programs.zsh = {
    enable = true;
  };

  environment.systemPackages = [
    pkgs.jujutsu
    pkgs.wget
    pkgs.curl
    pkgs.gcc
    pkgs.cachix
    pkgs.kubectl
    pkgs.kubernetes-helm
    pkgs.k9s
  ];
}
