{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      # bachus is on patched nixpkgs-stable (26.05), which predates the
      # rewrite of the `security.run0` module and lacks
      # `system.tools.nixos-rebuild.enableRun0Elevation`. Those landed in
      # nixpkgs 26.11+ (unstable). Gate the new options on nixpkgs >= 26.11
      # so this module keeps building on bachus until nixpkgs-stable reaches 26.11.
      security.sudo-rs = {
        enable = true;
        execWheelOnly = true;
        wheelNeedsPassword = true;
      };
      security.sudo.enable = false;

      security.run0 = lib.optionalAttrs (lib.versionAtLeast lib.version "26.11") {
        enable = true;
      };
      system.tools.nixos-rebuild = lib.optionalAttrs (lib.versionAtLeast lib.version "26.11") {
        enableRun0Elevation = true;
      };

      # Use AUTH_SELF for all systemd1 root actions so run0 skips the
      # user-selection prompt on multi-user systems. Wheel users authenticate
      # as themselves instead of picking from a list of admins.
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id.indexOf("org.freedesktop.systemd1.") == 0 && subject.isInGroup("wheel")) {
            return polkit.Result.AUTH_SELF_KEEP;
          }
        });
      '';

      # Loupe doesn't work with 'graphene-hardened*'
      # environment.memoryAllocator.provider = "graphene-hardened-light";
    };
}
