# What every workstation shares: Bluetooth, aarch64 emulation for cross
# builds, an open firewall on the trusted LAN, and a nix signing key per host
# so the other machines trust its store paths.
{
  flake.modules.nixos.desktop =
    { config, ... }:
    {
      hardware.bluetooth.enable = true;

      programs.fish.enable = true;

      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

      networking.firewall.enable = false;

      nix.settings.secret-key-files = [
        config.sops.secrets."nix-signing-keys/${config.networking.hostName}".path
      ];
    };
}
