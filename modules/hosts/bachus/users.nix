{
  flake.modules.nixos.bachus =
    { pkgs, ... }:
    {
      users.groups.nixadmins = { };

      users.users = {
        root.initialPassword = "password";

        sylvester = {
          uid = 1000;
          initialPassword = "password";
          isNormalUser = true;
          description = "Sylvester Roos";
          shell = pkgs.bash;
          createHome = true;
          extraGroups = [
            "wheel"
            "networkmanager"
            "plugdev"
            "nixadmins"
          ];
        };

        rikr = {
          uid = 1001;
          initialPassword = "password";
          isNormalUser = true;
          shell = pkgs.bash;
          createHome = true;
          extraGroups = [
            "wheel"
            "networkmanager"
            "plugdev"
            "nixadmins"
          ];
        };
      };
    };
}
