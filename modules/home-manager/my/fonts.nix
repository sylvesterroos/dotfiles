{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.my.fonts;
in
{
  options.my.fonts = {
    enable = mkEnableOption "fonts" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    fonts.fontconfig.enable = true;
    home.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.zed-mono
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      libre-baskerville # Times New Roman alternative
    ];
  };
}
