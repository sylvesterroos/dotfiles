{ pkgs, ... }:
{
  services.livebook = {
    enableUserService = true;
    # TODO: switch to unstable once the package is fixed
    package = pkgs.stable.livebook;
    extraPackages = with pkgs; [
      gcc
      gnumake
      cmake
      cargo
    ];
  };
}
