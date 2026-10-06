{
  flake.modules.homeManager.delta =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        (prismlauncher.override {
          additionalPrograms = [ gamescope ];

          jdks = [
            graalvmPackages.graalvm-ce
            jdk21
            jdk17
            jdk8
          ];
        })
      ];
    };
}
