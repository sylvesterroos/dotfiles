# Let NetworkManager and Tailscale share link-aware DNS through resolved.
{
  flake.modules.nixos.base.services.resolved.enable = true;
}
