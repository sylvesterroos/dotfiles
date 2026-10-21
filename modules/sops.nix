# sops-nix on NixOS. Each host decrypts secrets/<host>.yaml with its SSH host
# key (sops-nix's default sops.age.sshKeyPaths); secrets several hosts read
# live in secrets/shared.yaml and set sopsFile. Home-manager reads decrypted
# paths through osConfig. Each feature declares the secrets it reads.
{ inputs, ... }:
{
  flake.modules.nixos.base =
    { config, pkgs, ... }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      # sops-nix installs secrets at boot when systemd-sysusers or userborn
      # manages users; with an activation script instead, /run/secrets (ramfs)
      # is empty after a reboot until the next switch, and the nix daemon loses
      # its signing key. Userborn, because systemd-sysusers can't create normal
      # users.
      services.userborn.enable = true;

      environment.systemPackages = [
        pkgs.sops
        pkgs.age
        pkgs.ssh-to-age
      ];

      sops = {
        defaultSopsFile = "${inputs.self}/secrets/${config.networking.hostName}.yaml";
        defaultSopsFormat = "yaml";
      };
    };

  # Editing secrets takes a FIDO2 key; see .sops.yaml.
  flake.modules.nixos.desktop =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.age-plugin-fido2-hmac ];
    };
}
