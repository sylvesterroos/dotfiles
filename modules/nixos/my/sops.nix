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
  sopsShared = import ../../shared/sops.nix {
    inherit lib pkgs inputs;
  };
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
    # sops-nix auto-detects boot-time secret installation from systemd-sysusers
    # or userborn (sops.useSystemdActivation). Without it, secrets are installed
    # by an activation script, which only runs on switch/boot while the machine
    # stays up, so /run/secrets (ramfs) vanishes on reboot and the nix daemon
    # loses its signing key. We pick Userborn (not sysusers) because normal users
    # can't be created by systemd-sysusers.
    services.userborn.enable = true;

    environment.systemPackages = sopsShared.tools;

    sops = sopsShared.settings // {
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
      // optionalAttrs (config.services.copyparty.enable or false) {
        "copyparty/sylvester-password" = {
          owner = "copyparty";
          group = "copyparty";
        };
      };
    };
  };
}
