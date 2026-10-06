{
  flake.modules.nixos.creek =
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
    };
}
