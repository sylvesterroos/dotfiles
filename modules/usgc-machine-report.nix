{ inputs, ... }:
{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.usgc-machine-report
      ];
    };
}
