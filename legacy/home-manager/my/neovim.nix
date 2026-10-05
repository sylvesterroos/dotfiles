{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.my.neovim;
in
{
  options.my.neovim = {
    enable = mkEnableOption "neovim" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      withPython3 = false;
      withRuby = false;
    };
  };
}
