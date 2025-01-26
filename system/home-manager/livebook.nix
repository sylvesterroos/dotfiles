{ pkgs }:

with pkgs;
writeShellApplication {
  name = "livebook";
  runtimeInputs = [
    gcc # some dependencies require compilation
    gnumake
    cmake
    cargo # some dependencies use rustler
  ];
  text = # bash
    ''
      export LD_LIBRARY_PATH=$NIX_LD_LIBRARY_PATH
      exec ${livebook}/bin/livebook "$@"
    '';
}
