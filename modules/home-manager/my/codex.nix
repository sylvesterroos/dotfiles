{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.codex;

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

  fixedSkillsDir =
    pkgs.runCommand "elixir-phoenix-skills-fixed"
      {
        nativeBuildInputs = with pkgs; [ gnused ];
      }
      ''
        cp -r ${elixirPhoenixSkillsDir} $out
        chmod -R u+w $out
        find $out -name "SKILL.md" -exec sed -i 's/^name: \([^:]*\):\(.*\)$/name: \1-\2/' {} \;
      '';
in
{
  options.my.codex = {
    enable = mkEnableOption "codex" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ uv ];

    programs.codex = {
      enable = true;

      settings = {
        mcp_servers = {
          mcp-nixos = {
            command = "uvx";
            args = [ "mcp-nixos" ];
            enabled = true;
          };
          tidewave = {
            url = "http://localhost:4000/tidewave/mcp";
            enabled = true;
          };
        };
      };

      skills = lib.genAttrs elixirPhoenixSkillNames (name: "${fixedSkillsDir}/${name}");
    };
  };
}
