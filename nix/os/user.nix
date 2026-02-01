{
  username,
  pkgs,
  ...
}:
{
  programs.zsh.enable = true;

  users.users.${username} = {
    isNormalUser = true;
    home = "/home/${username}";
    description = username;
    shell = pkgs.zsh;

    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOKn3uiYhv6fwhtnM6sv11jI4KQGAKAWXEMnRPfbaTvY lluchkaa@gmail.com"
    ];
  };
}
