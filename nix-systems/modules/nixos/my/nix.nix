{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.my.nix;

  devenvSubstituter = "https://devenv.cachix.org";
  devenvKeys = ["devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=" "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="];
in {
  options.my.nix = {
    devenv.enable =
      mkEnableOption "devenv cache"
      // {
        default = true;
      };
  };

  config = {
    nix.settings = {
      substituters =
        []
        ++ (optionals cfg.devenv.enable [devenvSubstituter]);
      trusted-public-keys =
        []
        ++ (optionals cfg.devenv.enable devenvKeys);
    };
  };
}
