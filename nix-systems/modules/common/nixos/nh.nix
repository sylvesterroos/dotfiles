{flakeDir, ...}: {
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--nogcroots --keep-since 14d";
    };
    # There is probably a better way to define this path, but I figure this will sit untouched for a while
    flake = flakeDir;
  };
}
