{
  lib,
  config,
  ...
}: let
  cfg = config.my.nix;

  devenvSubstituter = "https://devenv.cachix.org";
  devenvKeys = ["devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=" "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="];

  gituSubstituter = "https://gitu.cachix.org";
  gituKey = "gitu.cachix.org-1:iUIaNys1l3W1LF/M8OXzaTl7N/OinGOlzdUJUSc+5eY=";
in {
  options.my.nix = with lib; {
    devenv.enable = mkEnableOption "devenv cache";
    gitu.enable = mkEnableOption "gitu cache";
  };

  config = {
    nix.settings = {
      substituters = lib.mkIf (cfg.devenv.enable || cfg.gitu.enable) (
        []
        ++ (lib.optional cfg.devenv.enable devenvSubstituter)
        ++ (lib.optional cfg.gitu.enable gituSubstituter)
      );
      trusted-public-keys = lib.mkIf (cfg.devenv.enable || cfg.gitu.enable) (
        []
        ++ lib.optionals cfg.devenv.enable devenvKeys
        ++ lib.optional cfg.gitu.enable gituKey
      );
    };
  };
}
