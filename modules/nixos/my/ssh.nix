{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.my.nixos.ssh;
in
{
  options.my.nixos.ssh = {
    enable = mkEnableOption "SSH server" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };
  };
}
