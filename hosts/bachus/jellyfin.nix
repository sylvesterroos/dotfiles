{ ... }:
{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  # Tailnet-only: reached via https://jellyfin.<tailnet>.ts.net (see tailnet-services.nix).
}
