{ pkgs, ... }:
{
  systemd.packages = [ pkgs.logiops ];
  systemd.services.logid.wantedBy = [ "multi-user.target" ];
}
