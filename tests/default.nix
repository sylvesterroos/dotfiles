let
  flake = builtins.getFlake (toString ../.);
  mv = flake.inputs.multiverse.lib.mkMultiverse {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };
  release = builtins.elemAt mv.releases ((builtins.length mv.releases) - 1);
  base = mv.flakeAt release;
  test = import ./service-from.nix;
in
test {
  inherit base;
  pkgs = mv.tip;
}
