{
  flake.modules.nixos.logiops =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.logiops ];
      systemd.packages = [ pkgs.logiops ];
      systemd.services.logid.wantedBy = [ "multi-user.target" ];
    };
}
