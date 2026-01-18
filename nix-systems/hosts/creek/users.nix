{ pkgs, ... }:
{
  users.users = {
    sylvester = {
      isNormalUser = true;
      description = "Sylvester Roos";
      shell = pkgs.bash;
      extraGroups = [
        "networkmanager"
        "wheel"
        "libvirtd"
        "adbusers"
        "plugdev"
        "podman"
      ];
    };
  };

  programs.fish.enable = true;
}
