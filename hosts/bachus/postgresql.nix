{pkgs, ...}: {
  services.postgresql = {
    package = pkgs.postgresql_18_jit;
    # non-default port so we don't get in the way of development postgres instances
    settings.port = 5431;
  };
}
