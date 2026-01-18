{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.my.llm;

  llm = pkgs.stable.python3Packages.llm.withPlugins {
    llm-cmd = true;
    llm-deepseek = true;
    llm-git = true;
    llm-github-copilot = true;
    llm-jq = true;
    llm-openrouter = true;
  };
in
{
  options.my.llm = {
    enable = mkEnableOption "llm" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ llm ];
  };
}
