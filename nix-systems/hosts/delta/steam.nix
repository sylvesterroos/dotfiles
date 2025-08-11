{pkgs, ...}: {
  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [proton-ge-bin];
    extraPackages = with pkgs; [gamescope gamemode];
    remotePlay.openFirewall = true;
    protontricks.enable = true;
  };
}
