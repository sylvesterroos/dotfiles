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
}
