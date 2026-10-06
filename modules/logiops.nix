{
  flake.modules.nixos.desktop =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.logiops ];
      systemd.packages = [ pkgs.logiops ];
      systemd.services.logid.wantedBy = [ "multi-user.target" ];
    };
}
