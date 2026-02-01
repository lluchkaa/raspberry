{ ... }:

{
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    age.keyFile = "/var/lib/sops-nix/key.txt";

    # Define secrets here as needed
    # secrets.example = {};
  };
}
