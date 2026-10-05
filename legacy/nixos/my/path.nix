{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.my.path;
in
{
  options.my.path = {
    # Default false: hosts with home-manager use the home-manager module.
    enable = mkEnableOption "extra user PATH entries";
    user = mkOption {
      type = types.str;
      default = "sylvester";
    };
  };

  config = mkIf cfg.enable {
    environment.loginShellInit = ''
      if [ "$USER" = '${cfg.user}' ]; then
        PATH="$HOME/.local/bin''${PATH:+:$PATH}"
        export PATH
      fi
    '';
  };
}
