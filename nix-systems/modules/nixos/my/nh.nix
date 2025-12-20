{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.my.nix-hydra;
in {
  options.my.nix-hydra = {
    enable =
      mkEnableOption "nix-hydra"
      // {
        default = true;
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
      # There is probably a better way to define this path, but I figure this will sit untouched for a while
      flake = "/home/sylvester/.dotfiles/nix-systems";
    };
  };
}
