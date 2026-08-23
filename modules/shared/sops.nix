{
  lib,
  pkgs,
  inputs,
}:
{
  settings = {
    defaultSopsFile = "${inputs.self}/secrets/secrets.yaml";
    defaultSopsFormat = "yaml";

    age.keyFile = "/home/sylvester/.config/sops/age/keys.txt";
  };

  tools = [
    pkgs.sops
    pkgs.age
    pkgs.ssh-to-age
  ];
}
