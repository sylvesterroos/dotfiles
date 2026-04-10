{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.my.nh;
in
{
  options.my.nh = {
    enable = mkEnableOption "nh" // {
      default = true;
    };
    flake = mkOption {
      type = types.str;
      default = "/home/sylvester/.dotfiles";
      description = "Path to the flake used by nh.";
    };
  };

  config = mkIf cfg.enable {
    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--nogcroots --keep-since 14d";
      };
      flake = cfg.flake;
    };
  };
}
