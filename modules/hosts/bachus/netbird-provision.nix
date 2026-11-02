# NetBird's account settings, groups, access policies and setup keys, applied
# by OpenTofu against the local management API on every switch. The state
# lives beside NetBird's own database. Bachus joins with the setup key the
# apply writes.
#
# Bootstrap: sign in to the dashboard once, which creates the account and its
# owner. Create a personal access token there, store it as sops
# `netbird/provision_token`, then import this module.
{ config, ... }:
let
  network = config.netbirdNetwork;
  inherit (config) tofuProvision;
in
{
  flake.modules.nixos.netbird-provision =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      management = config.services.netbird.server.management;
      client = config.services.netbird.clients.netbird;
      stateDirectory = "/var/lib/netbird-provision";
      keyDirectory = "${stateDirectory}/setup-keys";

      # The people the grants name, by NetBird user ID (their Pocket ID `sub`)
      # and account role. A person is listed after their first sign-in, when
      # NetBird has created their user.
      accounts = {
        sylvester = {
          id = "51e1dd3c-2057-4dcd-9c9f-a4f9eed0945a";
          role = "owner";
        };
      };

      # Machines that join without a person, and the group each one joins.
      setupKeys = {
        bachus = "servers";
        deck = "deck";
      };

      # Access between groups, declared by the features that serve them through
      # `my.netbird.grants`. `All` is NetBird's group of every peer; a person's
      # group holds that person's devices.
      grants = config.my.netbird.grants;

      groups = lib.subtractLists [ "All" ] (
        lib.unique (lib.concatMap (g: g.sources ++ g.destinations) grants)
      );
      groupId =
        name: if name == "All" then "\${data.netbird_group.all.id}" else "\${netbird_group.${name}.id}";

      policies = lib.listToAttrs (
        lib.concatMap (
          grant:
          map (
            protocol:
            lib.nameValuePair "${grant.name}-${protocol}" {
              name = "${grant.name}-${protocol}";
              enabled = true;
              rule = [
                (
                  {
                    name = "${grant.name}-${protocol}";
                    action = "accept";
                    enabled = true;
                    bidirectional = false;
                    inherit protocol;
                    sources = map groupId grant.sources;
                    destinations = map groupId grant.destinations;
                  }
                  // lib.optionalAttrs (grant.ports != [ ]) { ports = map toString grant.ports; }
                  // lib.optionalAttrs (grant.portRanges != [ ]) { port_ranges = grant.portRanges; }
                )
              ];
            }
          ) grant.protocols
        ) grants
      );

      configuration = {
        terraform.required_providers = {
          netbird.source = "netbirdio/netbird";
          local.source = "hashicorp/local";
        };
        provider.netbird.management_url = "http://127.0.0.1:${toString management.port}";
        data.netbird_group.all.name = "All";
        resource = lib.filterAttrs (_: resources: resources != { }) {
          netbird_account_settings.account = {
            network_range = network.range;
            # Devices stay connected without a periodic re-login.
            peer_login_expiration_enabled = false;
            regular_users_view_blocked = true;
            groups_propagation_enabled = true;
          };
          netbird_group = lib.genAttrs groups (name: {
            inherit name;
          });
          netbird_policy = policies;
          netbird_setup_key = lib.mapAttrs (name: group: {
            inherit name;
            type = "one-off";
            auto_groups = [ (groupId group) ];
            allow_extra_dns_labels = true;
            ephemeral = false;
            expiry_seconds = 0;
          }) setupKeys;
          local_sensitive_file = lib.mapAttrs (name: _: {
            filename = "${keyDirectory}/${name}";
            content = "\${netbird_setup_key.${name}.key}";
            file_permission = "0400";
            directory_permission = "0700";
          }) setupKeys;
          netbird_user = lib.mapAttrs (name: account: {
            is_service_user = false;
            inherit (account) role;
            auto_groups = [ (groupId name) ];
          }) accounts;
        };
      }
      // lib.optionalAttrs (accounts != { }) {
        import = lib.mapAttrsToList (name: account: {
          to = "netbird_user.${name}";
          inherit (account) id;
        }) accounts;
      };

      plugins = p: [
        p.hashicorp_local
        pkgs.terraform-provider-netbird
      ];

      # Firewall openings on bachus for every grant that reaches the servers.
      toServers = lib.filter (g: lib.elem "servers" g.destinations) grants;
      openings =
        protocol:
        let
          matching = lib.filter (g: lib.elem protocol g.protocols) toServers;
        in
        {
          ports = lib.concatMap (g: g.ports) matching;
          ranges = map (r: {
            from = r.start;
            to = r.end;
          }) (lib.concatMap (g: g.portRanges) matching);
        };
    in
    {
      options.my.netbird.grants = lib.mkOption {
        type = lib.types.listOf (
          lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                description = "Policy name; with the protocol it names the policy's OpenTofu resource.";
              };
              sources = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                description = "Groups the traffic comes from.";
              };
              destinations = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                description = "Groups the traffic goes to. Grants to `servers` also open the ports on bachus's NetBird interface.";
              };
              protocols = lib.mkOption {
                type = lib.types.listOf (
                  lib.types.enum [
                    "tcp"
                    "udp"
                  ]
                );
                description = "Transport protocols the grant covers.";
              };
              ports = lib.mkOption {
                type = lib.types.listOf lib.types.port;
                default = [ ];
                description = "Single ports the grant covers.";
              };
              portRanges = lib.mkOption {
                type = lib.types.listOf (
                  lib.types.submodule {
                    options = {
                      start = lib.mkOption { type = lib.types.port; };
                      end = lib.mkOption { type = lib.types.port; };
                    };
                  }
                );
                default = [ ];
                description = "Port ranges the grant covers.";
              };
            };
          }
        );
        default = [ ];
        description = "Access between NetBird groups. Each feature declares the grants for what it serves.";
      };

      config = {
        # People's devices reach each other; the rest of the grants come from the
        # features that serve them.
        my.netbird.grants = [
          {
            name = "rimmolt";
            sources = [ "servers" ];
            destinations = [ "deck" ];
            protocols = [ "tcp" ];
            ports = [ 8787 ];
          }
          {
            name = "skyrim-together";
            sources = [ "fred" ];
            destinations = [
              "sylvester"
              "deck"
            ];
            protocols = [
              "tcp"
              "udp"
            ];
            ports = [ 10578 ];
          }
          # BitTorrent between fred and sylvester, on each one's listen port.
          {
            name = "bittorrent-fred";
            sources = [ "fred" ];
            destinations = [ "sylvester" ];
            protocols = [
              "tcp"
              "udp"
            ];
            ports = [ 43658 ];
          }
          {
            name = "bittorrent-sylvester";
            sources = [ "sylvester" ];
            destinations = [ "fred" ];
            protocols = [
              "tcp"
              "udp"
            ];
            ports = [ 10696 ];
          }
        ];

        assertions = [
          {
            assertion = lib.all (name: lib.elem name groups) (lib.attrNames accounts);
            message = "Every NetBird account must belong to a group the grants name.";
          }
          {
            assertion = lib.all (group: group == "All" || lib.elem group groups) (lib.attrValues setupKeys);
            message = "Every NetBird setup key must join a group the grants name.";
          }
        ];

        sops.secrets."netbird/provision_token" = { };

        systemd.services.netbird-provision =
          tofuProvision {
            inherit pkgs plugins configuration;
            name = "netbird-provision";
            description = "Apply NetBird's account settings, groups, policies and setup keys";
            credentials.NB_PAT = config.sops.secrets."netbird/provision_token".path;
          }
          // {
            requires = [ "netbird-management.service" ];
            after = [ "netbird-management.service" ];
          };

        services.netbird.clients.netbird.login = {
          enable = true;
          setupKeyFile = "${keyDirectory}/bachus";
          systemdDependencies = [ "netbird-provision.service" ];
        };

        # The module starts the login only alongside the daemon, which a switch
        # leaves running.
        systemd.services.netbird-login.wantedBy = [ "multi-user.target" ];

        networking.firewall.interfaces.${client.interface} =
          let
            tcp = openings "tcp";
            udp = openings "udp";
          in
          {
            allowedTCPPorts = lib.unique tcp.ports;
            allowedTCPPortRanges = tcp.ranges;
            allowedUDPPorts = lib.unique udp.ports;
            allowedUDPPortRanges = udp.ranges;
          };
      };
    };
}
