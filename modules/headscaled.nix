# A second tailscaled that joins this machine to the headscale tailnet, beside
# the machine's own tailscaled. Hosts with `network` configured use a routed
# TUN in an isolated namespace. Bachus uses the userspace stack to publish its
# host-loopback services, and an HTTP proxy for outgoing connections.
#
# `headscaled` is the tailscale CLI bound to this daemon. A machine joins once
# with `sudo headscaled login --login-server <headscale url>`.
{ config, ... }:
let
  inherit (config.headscaleNetwork) domain;
in
{
  flake.modules.nixos.headscaled =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.headscaled;
    in
    {
      options.my.headscaled = {
        package = lib.mkPackageOption pkgs "tailscale" { };

        socket = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/headscaled/tailscaled.sock";
          readOnly = true;
          description = "Control socket of this daemon.";
        };

        proxy = lib.mkOption {
          type = lib.types.str;
          default = "localhost:1055";
          readOnly = true;
          description = ''
            Listen address of the HTTP proxy that the userspace stack runs. It dials
            through the headscale tailnet and resolves its MagicDNS names.
          '';
        };
      };

      config = {
        systemd.services.headscaled = {
          description = "tailscaled joined to the headscale tailnet";
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            # --port=0 picks a free UDP port; the default belongs to the
            # machine's own tailscaled.
            ExecStart = lib.concatStringsSep " " (
              [
                (lib.getExe' cfg.package "tailscaled")
                "--tun=${if cfg.network == null then "userspace-networking" else "tailscale1"}"
                "--port=0"
                "--statedir=/var/lib/headscaled"
                "--socket=${cfg.socket}"
              ]
              ++ lib.optional (cfg.network == null) "--outbound-http-proxy-listen=${cfg.proxy}"
            );
            Restart = "always";
            RestartSec = 5;
            StateDirectory = "headscaled";
          };
        };

        environment.systemPackages = [
          (pkgs.writeShellScriptBin "headscaled" ''
            exec ${lib.getExe cfg.package} --socket=${cfg.socket} "$@"
          '')
        ];

        # A managed policy covers every browser profile. The PAC script travels
        # inline as a data: URL.
        programs.chromium.extraOpts = lib.mkIf (cfg.network == null) {
          ProxySettings = {
            ProxyMode = "pac_script";
            ProxyPacUrl =
              "data:application/x-ns-proxy-autoconfig,"
              + lib.escapeURL ''function FindProxyForURL(url, host) { return dnsDomainIs(host, ".${domain}") ? "PROXY ${cfg.proxy}" : "DIRECT"; }'';
          };
        };
      };
    };
}
