{ pkgs, ... }:
{
  users.users = {
    root.initialPassword = "password";

    sylvester = {
      uid = 1000;
      initialPassword = "password";
      isNormalUser = true;
      description = "Sylvester Roos";
      shell = pkgs.bash;
      extraGroups = [
        "wheel"
        "networkmanager"
        "plugdev"
      ];
      createHome = true;
    };

    rikr = {
      uid = 1001;
      initialPassword = "password";
      isNormalUser = true;
      shell = pkgs.bash;
      createHome = true;
    };
  };

  programs.fish.enable = true;
}
