{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.my.protonsuite;
in
{
  options.my.protonsuite = {
    enable = mkEnableOption "protonsuite" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      let
        protonmail = [
          protonmail-desktop
          protonmail-bridge
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          protonmail-bridge-gui
        ];

        protonvpn = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          proton-vpn
          proton-vpn-cli
        ];

        protonpass = [
          proton-pass-cli
        ]
        ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
          proton-pass
          proton-authenticator
        ];
      in
      [ ] ++ protonmail ++ protonvpn ++ protonpass;
  };
}
