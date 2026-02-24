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
        ++ lib.optionals pkgs.stdenv.isLinux [
          protonmail-bridge-gui
        ];

        protonvpn = lib.optionals pkgs.stdenv.isLinux [
          protonvpn-gui
          proton-vpn-cli
        ];

        protonpass = [
          proton-pass-cli
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [
          proton-pass
          proton-authenticator
        ];

        notes = lib.optionals pkgs.stdenv.isLinux [
          standardnotes
        ];
      in
      [ ] ++ protonmail ++ protonvpn ++ protonpass ++ notes;
  };
}
