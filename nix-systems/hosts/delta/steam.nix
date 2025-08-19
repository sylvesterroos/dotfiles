{pkgs, ...}: {
  programs.steam = {
    enable = true;
    extraCompatPackages = with pkgs; [proton-ge-bin];
    extraPackages = with pkgs; [gamescope gamemode mangohud];
    remotePlay.openFirewall = true;
    protontricks.enable = true;
  };

  environment.systemPackages = with pkgs; [mangojuice];
}
