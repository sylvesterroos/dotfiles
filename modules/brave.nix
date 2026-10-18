{
  flake.modules.nixos.desktop =
    { pkgs, ... }:
    {
      programs.chromium.enable = true;

      environment.systemPackages = with pkgs; [
        brave
      ];
    };
}
