{ pkgs, ... }:
{
  home.packages = with pkgs; [
    haruna
    mcp_proxy_rust
  ];
}
