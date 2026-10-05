{
  lib,
  pkgs,
}:
{
  settings = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    age.keyFile = "/home/sylvester/.config/sops/age/keys.txt";
  };

  tools = [
    pkgs.sops
    pkgs.age
    pkgs.ssh-to-age
  ];
}
