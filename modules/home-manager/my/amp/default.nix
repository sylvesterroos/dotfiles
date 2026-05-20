{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.amp;

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

  # Post-process skills to fix invalid skill names (replace colons with hyphens in frontmatter)
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

  skillLinks = listToAttrs (
    map (name: {
      name = ".config/agents/skills/${name}";
      value = {
        source = "${fixedSkillsDir}/${name}";
        recursive = true;
      };
    }) elixirPhoenixSkillNames
  );
in
{
  options.my.amp = {
    enable = mkEnableOption "amp" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      amp-cli
      uv
    ];

    home.file = skillLinks // {
      ".config/amp/settings.json".source = ./settings.json;
    };
  };
}
