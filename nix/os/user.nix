{
  username,
  pkgs,
  ...
}:
{
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
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNKC5A1pTWQ67C9oTLawxzlJA5UuSNGY8VCTEg4UP/26hJm4YNQLRWEZBdYVXzsf+3+F2hAZBKUPKMcKau1W2NM="
    ];

    # Default password: admin (change after first login!)
    initialHashedPassword = "$6$/LxBfBCrnDVzH9B6$oIc7BRPyP4NmNuuPlDDuISlBMJ5qytiAQpT8y9V515koCV4J4jo4HbRk8lU5pNfDDFXkIt9kCg8ySsXkWIahw.";
  };
}
