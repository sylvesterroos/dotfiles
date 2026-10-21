# What every workstation shares: your user account, Bluetooth, aarch64
# emulation for cross builds, an open firewall on the trusted LAN, and a nix
# signing key per host so the other machines trust its store paths.
{
  flake.modules.nixos.desktop =
    { config, pkgs, ... }:
    {
      users.users.sylvester = {
        isNormalUser = true;
        description = "Sylvester Roos";
        shell = pkgs.bash;
        extraGroups = [
          "networkmanager"
          "wheel"
        ];
      };

      hardware.bluetooth.enable = true;

      programs.fish.enable = true;

      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

      networking.firewall.enable = false;

      sops.secrets.nix-signing-key = { };
      nix.settings.secret-key-files = [ config.sops.secrets.nix-signing-key.path ];
    };
}
