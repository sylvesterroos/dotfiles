{
  flake.modules.nixos.desktop =
    { pkgs, ... }:
    let

      # Mount options for the bind mounts
      mountOptions = [
        "ro"
        "x-gvfs-hide"
        # Resolves symlinks as if they were real files.
        # Needed for applications that don't follow symlinks,
        # e.g. OnlyOffice.
        "resolve-symlinks"
      ];
    in
    {
      # Expose all fonts under /run/current-system/sw/share/X11/fonts
      fonts.fontDir.enable = true;

      system.fsPackages = [ pkgs.bindfs ];

      # Bind mount fonts, icons and themes from /run/current-system/sw/share
      # to their /usr/share equivalents, so Flatpak, Distrobox, AppImage and
      # other non-Nix applications can find them under the FHS paths they
      # expect.
      #
      # https://wiki.nixos.org/wiki/Fixes_for_non-Nix_applications#Flatpak,_Distrobox,_Appimage_and_other_non-Nix_applications_can't_find_system_fonts/icons/themes
      fileSystems = {
        "/usr/share/fonts" = {
          device = "/run/current-system/sw/share/X11/fonts";
          fsType = "fuse.bindfs";
          options = mountOptions;
        };

        "/usr/share/icons" = {
          device = "/run/current-system/sw/share/icons";
          fsType = "fuse.bindfs";
          options = mountOptions;
        };

        "/usr/share/themes" = {
          device = "/run/current-system/sw/share/themes";
          fsType = "fuse.bindfs";
          options = mountOptions;
        };
      };
    };
}
