{ pkgs, ... }:
{
  home.packages = with pkgs; [
    haruna
    lmstudio
    mcp_proxy_rust
  ];
}
