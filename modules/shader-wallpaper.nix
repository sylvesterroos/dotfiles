{ ... }:
{
  flake.modules.nixos.desktop =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      shaderWallpaper = pkgs.shader-wallpaper;
    in
    {
      # Built from the system package set: the engine links Qt private API and
      # must match the Qt that plasmashell, kscreenlocker and Plasma Login run.
      environment.systemPackages = [ shaderWallpaper ];

      # Plasma Login Manager hides third-party wallpaper plugins in its
      # dropdown (KDE bug 517325); registering the id enables the plugin.
      services.displayManager.plasma-login-manager.settings.Greeter.WallpaperPluginId =
        "online.knowmad.shaderwallpaper";

      # The login greeter runs with a fixed XDG_DATA_DIRS that holds only the
      # session files; adding the package lets it find the wallpaper plugin.
      systemd.user.services.plasma-login.environment.XDG_DATA_DIRS = lib.mkForce (
        lib.concatStringsSep ":" [
          "${config.services.displayManager.sessionData.desktops}/share"
          "${shaderWallpaper}/share"
        ]
      );
    };
}
