{
  flake.modules.homeManager.creek =
    { lib, pkgs, ... }:
    {
      home.packages = [
        (pkgs.writeShellScriptBin "qmobiel-vpn" ''
          VPN_HOST=vpn.qmobiel.nl && VPN_PORT=10443 \
            && ${lib.getExe pkgs.openfortivpn-webview-qt} "''${VPN_HOST}:''${VPN_PORT}" 2>/dev/null \
            | sudo ${lib.getExe pkgs.openfortivpn} "''${VPN_HOST}:''${VPN_PORT}" --cookie-on-stdin --pppd-accept-remote
        '')
      ];
    };
}
