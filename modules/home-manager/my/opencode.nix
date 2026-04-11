{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.opencode;
in
{
  options.my.opencode = {
    enable = mkEnableOption "opencode" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ uv ];

    programs.opencode = {
      enable = true;
      settings = {
        plugin = [ "opencode-handoff" ];

        mcp = {
          mcp-nixos = {
            type = "local";
            command = [
              "uvx"
              "mcp-nixos"
            ];
            enabled = true;
          };
          tidewave = {
            type = "remote";
            url = "http://localhost:4000/tidewave/mcp";
            enabled = true;
          };
        };
      };
    };
  };
}
