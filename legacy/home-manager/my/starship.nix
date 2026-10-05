{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.my.starship;
in
{
  options.my.starship = {
    enable = mkEnableOption "starship" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    programs.starship = {
      enable = true;
      settings = builtins.fromTOML (builtins.readFile ./starship.toml);
    };
  };
}
