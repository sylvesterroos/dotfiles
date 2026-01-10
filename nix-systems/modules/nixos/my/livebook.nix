{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.my.livebook;
in {
  options.my.livebook = {
    enable =
      mkEnableOption "livebook"
      // {
        default = false;
      };
  };

  config = mkIf cfg.enable {
    services.livebook = {
      enableUserService = true;
      package = pkgs.livebook;
      environment = {
        LIVEBOOK_PORT = 20123;
        LIVEBOOK_TOKEN_ENABLED = false;
      };
      extraPackages = with pkgs; [
        gcc
        gnumake
        cmake
        cargo
      ];
    };
  };
}
