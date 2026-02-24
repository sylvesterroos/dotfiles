{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.appimage;
in
{
  options.my.appimage = {
    enable = mkEnableOption "appimage" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    programs.appimage = {
      enable = true;
      binfmt = true;
      package = pkgs.appimage-run.override {
        extraPkgs =
          pkgs: with pkgs; [
            zstd
          ];
      };
    };
  };
}
