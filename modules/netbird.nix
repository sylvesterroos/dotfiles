# The NetBird network, served from bachus: its shared values and the client
# that joins a host. A desktop joins once with `netbird up`, signing in
# through Pocket ID.
{ config, lib, ... }:
let
  network = config.netbirdNetwork;
in
{
  options.netbirdNetwork = lib.mkOption {
    type = lib.types.submodule {
      options = {
        server = lib.mkOption {
          type = lib.types.str;
          description = "Public hostname of the management server, signal and relay.";
        };
        dashboard = lib.mkOption {
          type = lib.types.str;
          description = "Hostname of the dashboard and its API on the personal tailnet.";
        };
        domain = lib.mkOption {
          type = lib.types.str;
          description = "DNS domain the clients resolve peer and service names under.";
        };
        range = lib.mkOption {
          type = lib.types.str;
          description = "IPv4 range NetBird allocates peer addresses from.";
        };
      };
    };
    description = "Server, DNS domain and address allocation of the NetBird network.";
  };

  config.netbirdNetwork = {
    server = "vpn.sylvesterroos.com";
    dashboard = "netbird.${config.tailnetDomain}";
    # Outside the server's name: clients answer every query in this domain
    # themselves, so the management URL there would not resolve.
    domain = "netbird.sylvesterroos.com";
    # Outside 100.64.0.0/10: the hosted tailscaled drops packets from that
    # range arriving on any interface but its own.
    range = "10.77.0.0/24";
  };

  config.flake.modules.nixos.netbird =
    { config, ... }:
    {
      services.netbird.clients.netbird = {
        port = 51820;
        interface = "wt0";
        environment = {
          NB_MANAGEMENT_URL = "https://${network.server}";
          NB_ADMIN_URL = "https://${network.dashboard}";
          # NetBird's peer zone is always a resolver search domain, so a peer
          # named like the host would answer the short name beside Tailscale.
          NB_HOSTNAME = "${config.networking.hostName}-netbird";
        };
        # The module seeds an empty config, which NetBird reads as one from
        # before the SSH server existed and so enables it. Hosts use OpenSSH.
        config.ServerSSHAllowed = false;
      };

      users.users.sylvester.extraGroups = [ config.services.netbird.clients.netbird.user.group ];

      # The daemon merges config.d into its config only when it starts.
      systemd.services.netbird.restartTriggers = [
        config.environment.etc."netbird/config.d/50-nixos.json".source
      ];
    };
}
