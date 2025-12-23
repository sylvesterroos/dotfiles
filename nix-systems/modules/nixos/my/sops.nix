{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.my.sops-nix;
in {
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  options.my.sops-nix = {
    enable =
      mkEnableOption "sops-nix"
      // {
        default = true;
      };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sops
      age
      ssh-to-age
    ];

    sops.defaultSopsFile = "${inputs.self}/secrets/secrets.yaml";
    sops.defaultSopsFormat = "yaml";

    sops.age.keyFile = "/home/sylvester/.config/sops/age/keys.txt";

    sops.secrets."fin_man/secret_key_base" = {};
  };
}
