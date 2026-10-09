# A second tailscaled that joins this machine to the headscale tailnet, beside
# the machine's own tailscaled. Hosts with `network` configured use a routed
# TUN in an isolated namespace. Bachus uses the userspace stack to publish its
# host-loopback services, and an HTTP proxy for outgoing connections.
#
# `headscaled` is the tailscale CLI bound to this daemon. A machine joins once
# with `sudo headscaled login --login-server <headscale url>`.
{
  flake.modules.nixos.base =
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
        enable = lib.mkEnableOption "a second tailscaled joined to the headscale tailnet";

        package = lib.mkPackageOption pkgs "tailscale" { };

        socket = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/headscaled/tailscaled.sock";
          readOnly = true;
          description = "Control socket of this daemon.";
        };

        httpProxy = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.submodule {
              options = {
                listen = lib.mkOption {
                  type = lib.types.str;
                  example = "localhost:1055";
                  description = "Listen address of the proxy.";
                };
                domain = lib.mkOption {
                  type = lib.types.str;
                  example = "tailnet.example.com";
                  description = ''
                    MagicDNS base domain of the headscale tailnet. Chromium-based
                    browsers send names under it through the proxy and everything
                    else direct.
                  '';
                };
              };
            }
          );
          default = null;
          description = ''
            An HTTP proxy that dials through the headscale tailnet and resolves its
            MagicDNS names.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
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
              ++ lib.optional (cfg.httpProxy != null) "--outbound-http-proxy-listen=${cfg.httpProxy.listen}"
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
        programs.chromium.extraOpts = lib.mkIf (cfg.httpProxy != null) {
          ProxySettings = {
            ProxyMode = "pac_script";
            ProxyPacUrl =
              "data:application/x-ns-proxy-autoconfig,"
              + lib.escapeURL ''function FindProxyForURL(url, host) { return dnsDomainIs(host, ".${cfg.httpProxy.domain}") ? "PROXY ${cfg.httpProxy.listen}" : "DIRECT"; }'';
          };
        };
      };
    };
}
