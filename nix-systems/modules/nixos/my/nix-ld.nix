{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.my.nix-ld;
in {
  options.my.nix-ld = {
    enable =
      mkEnableOption "nix-ld"
      // {
        default = true;
      };
  };

  config = mkIf cfg.enable {
    # Run unpatched dynamic binaries on NixOS
    programs.nix-ld = {
      enable = true;
    };
  };
}
