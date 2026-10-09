# A routed Headscale namespace gives host applications a second VPN and DNS
# domain while keeping each tailscaled's network administration isolated.
{
  _module.args.headscaleNetwork = {
    domain = "tailnet.sylvesterroos.com";
    ipv4Prefix = "100.64.0.0/24";
    ipv6Prefix = "fd7a:115c:a1e0::/120";
  };

  flake.modules.nixos.base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.headscaled;
      network = cfg.network;
      tools = {
        IP = lib.getExe' pkgs.iproute2 "ip";
        NFT = lib.getExe pkgs.nftables;
        SYSCTL = lib.getExe' pkgs.procps "sysctl";
        TAILSCALE = lib.getExe cfg.package;
      };
      settings = pkgs.writeText "headscale-network.json" (
        builtins.toJSON {
          inherit (network) ipv4Prefix ipv6Prefix;
          socket = cfg.socket;
        }
      );
      script = pkgs.writers.writeNu "headscale-network" { } (builtins.readFile ./network.nu);
      environment = tools // {
        CONFIG = settings;
      };
      resolver = pkgs.writeText "headscale-resolv.conf" "nameserver 9.9.9.9\n";
    in
    {
      options.my.headscaled.network = lib.mkOption {
        default = null;
        description = "Address allocation and DNS domain of the routed Headscale network.";
        type = lib.types.nullOr (
          lib.types.submodule {
            options = {
              domain = lib.mkOption {
                type = lib.types.str;
                description = "Headscale's MagicDNS base domain.";
              };
              ipv4Prefix = lib.mkOption {
                type = lib.types.str;
                description = "Headscale's IPv4 allocation prefix, distinct from personal Tailscale peers.";
              };
              ipv6Prefix = lib.mkOption {
                type = lib.types.str;
                description = "Headscale's IPv6 allocation prefix, distinct from personal Tailscale peers.";
              };
            };
          }
        );
      };

      config = lib.mkIf (cfg.enable && network != null) {
        assertions = [
          {
            assertion = cfg.httpProxy == null;
            message = "A routed Headscale network supplies host routing and split DNS; set my.headscaled.httpProxy to null.";
          }
        ];

        services.resolved = {
          enable = true;
          dnsDelegates.headscale.Delegate = {
            DNS = "10.203.0.2";
            Domains = "~${network.domain}";
            DefaultRoute = false;
          };
        };
        networking.networkmanager.unmanaged = [ "interface-name:headscale-host" ];
        networking.firewall.trustedInterfaces = [ "headscale-host" ];
        # Keep anti-spoofing protection active across Headscale stops and
        # restarts. The hosted Tailscale attribute delegates this rule to us.
        networking.firewall.extraCommands = ''
          iptables -I nixos-fw 1 -s 100.64.0.0/10 -j DROP
          iptables -I nixos-fw 1 -s 100.64.0.0/10 -i lo -j nixos-fw-accept
          iptables -I nixos-fw 1 -s 100.64.0.0/10 -i headscale-host -j nixos-fw-accept
          iptables -I nixos-fw 1 -s 100.64.0.0/10 -i tailscale0 -j nixos-fw-accept
        '';
        boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

        systemd.services.headscale-network = {
          description = "Isolated Headscale network and host routing";
          wantedBy = [ "multi-user.target" ];
          before = [ "headscaled.service" ];
          inherit environment;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            RuntimeDirectory = "headscale-network";
            ExecStart = "${script} up";
            ExecStopPost = "${script} down";
          };
        };

        systemd.services.headscaled = {
          requires = [ "headscale-network.service" ];
          after = [ "headscale-network.service" ];
          bindsTo = [ "headscale-network.service" ];
          serviceConfig = {
            NetworkNamespacePath = "/run/netns/headscale";
            BindReadOnlyPaths = [ "${resolver}:/etc/resolv.conf" ];
          };
        };

        systemd.services.headscale-connect = {
          description = "Attach the Headscale node addresses to the host";
          wantedBy = [ "headscaled.service" ];
          requires = [ "headscaled.service" ];
          after = [ "headscaled.service" ];
          partOf = [ "headscaled.service" ];
          inherit environment;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${script} attach";
            ExecStopPost = "${script} detach";
            Restart = "on-failure";
            RestartSec = 10;
            TimeoutStartSec = 90;
          };
        };

        systemd.services.headscale-dns = {
          description = "Headscale MagicDNS endpoint for the host resolver";
          wantedBy = [ "headscaled.service" ];
          requires = [
            "headscaled.service"
            "headscale-network.service"
          ];
          after = [
            "headscaled.service"
            "headscale-network.service"
          ];
          partOf = [ "headscaled.service" ];
          serviceConfig = {
            NetworkNamespacePath = "/run/netns/headscale";
            ExecStart = lib.concatStringsSep " " [
              (lib.getExe pkgs.dnsmasq)
              "--keep-in-foreground"
              "--log-facility=-"
              "--no-resolv"
              "--no-hosts"
              "--bind-interfaces"
              "--listen-address=10.203.0.2"
              "--server=100.100.100.100"
              "--cache-size=0"
              "--user=root"
            ];
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
      };
    };
}
