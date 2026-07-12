{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.my.sops-nix;
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  options.my.sops-nix = {
    enable = mkEnableOption "sops-nix" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sops
      age
      ssh-to-age
    ];

    sops = {
      defaultSopsFile = "${inputs.self}/secrets/secrets.yaml";
      defaultSopsFormat = "yaml";

      age.keyFile = "/home/sylvester/.config/sops/age/keys.txt";

      secrets = {
        ddns-updater-config = { };

        "vaultwarden/vaultwarden.env" = { };

        "nix-signing-keys/delta" = { };

        "wireguard/protonvpn_nl/private_key" = {
          owner = "systemd-network";
          group = "systemd-network";
        };

        "proton/email" = { };
        "proton/rclone_obscured_password" = { };

        "nix-access-tokens/github.com" = { };

        hermes-api-key = { };

        plausible-secret-key = { };

        "open-design/username" = { };
        "open-design/password" = { };
        "open-design/OD_API_KEY" = { };
      };
    };
  };
}
