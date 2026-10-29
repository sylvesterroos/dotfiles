{
  flake.modules.nixos.desktop =
    { pkgs, ... }:
    {
      programs.steam = {
        enable = true;
        extraCompatPackages = with pkgs; [ proton-ge-bin ];
        remotePlay.openFirewall = true;
        protontricks.enable = true;
      };

      programs.gamemode.enable = true;
      programs.gamescope.enable = true;

      environment.systemPackages = with pkgs; [
        mangohud
        mangojuice
      ];
    };

  flake.modules.homeManager.desktop =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ sgdboop ];
    };
}
