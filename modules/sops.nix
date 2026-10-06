# sops-nix on both layers, one key and one secrets file.
{ inputs, ... }:
let
  settings = {
    defaultSopsFile = ../secrets/secrets.yaml;
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
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      # sops-nix installs secrets at boot when systemd-sysusers or userborn
      # manages users; with an activation script instead, /run/secrets (ramfs)
      # is empty after a reboot until the next switch, and the nix daemon loses
      # its signing key. Userborn, because systemd-sysusers can't create normal
      # users.
      services.userborn.enable = true;

      environment.systemPackages = tools pkgs;

      sops = settings // {
        secrets = {
          ddns-updater-config = { };

          # Porkbun API credentials, used by Caddy's DNS-01 challenge to issue
          # certificates for the headscale tailnet.
          porkbun_api_key = { };
          porkbun_secret_api_key = { };

          "vaultwarden/vaultwarden.env" = { };

          "nix-signing-keys/delta" = { };
          "nix-signing-keys/creek" = { };

          "wireguard/protonvpn_nl/private_key" = {
            owner = "systemd-network";
            group = "systemd-network";
          };

          "proton/email" = { };
          "proton/rclone_obscured_password" = { };

          "nix-access-tokens/github.com" = { };

          hermes-api-key = { };

          plausible-secret-key = { };
        }
        // lib.optionalAttrs (config.services.copyparty.enable or false) {
          "copyparty/sylvester-password" = {
            owner = "copyparty";
            group = "copyparty";
          };
        };
      };
    };

  flake.modules.homeManager.base =
    { pkgs, ... }:
    {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];
      home.packages = tools pkgs;
      sops = settings;
    };
}
