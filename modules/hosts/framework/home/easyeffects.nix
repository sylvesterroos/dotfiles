{
  # Keep EasyEffects installed, but start it by hand.
  flake.modules.homeManager.framework =
    { lib, ... }:
    {
      systemd.user.services.easyeffects.Install.WantedBy = lib.mkForce [ ];
    };
}
