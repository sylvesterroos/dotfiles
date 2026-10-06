{
  flake.modules.nixos.desktop =
    { pkgs, ... }:
    {
      programs.appimage = {
        enable = true;
        binfmt = true;
        package = pkgs.appimage-run.override {
          extraPkgs =
            pkgs: with pkgs; [
              zstd
            ];
        };
      };
    };
}
