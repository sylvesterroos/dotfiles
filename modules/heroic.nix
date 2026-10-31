{
  flake.modules.nixos.gaming =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        (heroic.override {
          extraPkgs =
            pkgs: with pkgs; [
              gamescope
              gamemode
            ];
        })
      ];
    };
}
