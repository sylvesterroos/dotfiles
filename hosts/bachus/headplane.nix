{
  config,
  ...
}:
{
  sops.secrets."headplane/cookie_secret" = {
    owner = "headscale";
    group = "headscale";
  };

  sops.secrets."headplane/headscale_api_key" = {
    owner = "headscale";
    group = "headscale";
  };

  services.headplane = {
    enable = true;
    settings = {
      server = {
        host = "127.0.0.1";
        port = 9090;
        base_url = "https://headplane.allosaurus-snapper.ts.net";
        cookie_secret_path = config.sops.secrets."headplane/cookie_secret".path;
      };
      # Same OIDC client as headscale: pocket-id derives `sub` from the user, so
      # one client keeps the subject identical across both services and headplane
      # can match a login to its headscale record by subject instead of email.
      # headplane 0.6.2's module (the host's stable nixpkgs) spells this
      # oidc.headscale_api_key_path; upstream 0.7 moved it to
      # headscale.api_key_path, which that module does not declare.
      oidc = {
        inherit (config.services.headscale.settings.oidc) issuer client_id client_secret_path;
        headscale_api_key_path = config.sops.secrets."headplane/headscale_api_key".path;
        use_pkce = true;
      };
    };
  };
}
