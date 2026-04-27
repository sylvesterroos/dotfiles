{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.opencode;

  claude-elixir-phoenix = pkgs.fetchFromGitHub {
    owner = "oliver-kriska";
    repo = "claude-elixir-phoenix";
    rev = "0143e95994c353138c6c5fd88eaf9ec77fce26fc";
    hash = "sha256-pNMggL7KlkK9/Al8IczRjH47L0RnfnOAMZZWlUuAy+Q=";
  };

  elixirPhoenixSkillsDir = "${claude-elixir-phoenix}/plugins/elixir-phoenix/skills";
  elixirPhoenixSkillNames = builtins.attrNames (
    lib.filterAttrs (n: v: v == "directory") (builtins.readDir elixirPhoenixSkillsDir)
  );
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

      skills = lib.genAttrs elixirPhoenixSkillNames (name: "${elixirPhoenixSkillsDir}/${name}");
    };
  };
}
