# sops-nix on both layers, one key and one secrets file. Each feature declares
# the secrets it reads.
{ inputs, ... }:
let
  settings = {
    defaultSopsFile = "${inputs.self}/secrets/secrets.yaml";
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/sylvester/.config/sops/age/keys.txt";
  };
  tools = pkgs: [
    pkgs.sops
    pkgs.age
    pkgs.ssh-to-age
  ];
in
{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      # sops-nix installs secrets at boot when systemd-sysusers or userborn
      # manages users; with an activation script instead, /run/secrets (ramfs)
      # is empty after a reboot until the next switch, and the nix daemon loses
      # its signing key. Userborn, because systemd-sysusers can't create normal
      # users.
      services.userborn.enable = true;

      environment.systemPackages = tools pkgs;

      sops = settings;
    };

  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];
      home.packages = tools pkgs;
      sops = settings;
    };
}
