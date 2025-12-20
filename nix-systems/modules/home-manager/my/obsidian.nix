{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
with lib; let
  cfg = config.my.obsidian;
in {
  options.my.obsidian = {
    enable =
      mkEnableOption "obsidian"
      // {
        default = false;
      };
  };

  config = mkIf cfg.enable {
    programs.obsidian = {
      # Enabling this overwrites ad-hoc settings
      # The module is only useful when configuring Obsidian using Nix as well
      enable = true;
    };

    home.packages = with pkgs; [obsidian];
  };
}
