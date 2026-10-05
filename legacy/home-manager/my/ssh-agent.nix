{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.my.ssh-agent;
in
{
  options.my.ssh-agent = {
    enable = mkEnableOption "ssh-agent" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    services.ssh-agent.enable = true;
  };
}
