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

      zomboid = config.services.pznix.servers.zomboid.ports;

      # Access between groups. `All` is NetBird's group of every peer; a
      # person's group holds that person's devices.
      grants = [
        {
          name = "services";
          sources = [ "All" ];
          destinations = [ "servers" ];
          protocols = [ "tcp" ];
          ports = [ 443 ];
        }
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
        {
          name = "zomboid";
          sources = [ "All" ];
          destinations = [ "servers" ];
          protocols = [ "udp" ];
          ports = [ zomboid.game ] ++ map (p: p.port) zomboid.extra;
        }
        # Minecraft servers run by Playkeeper: the first on 25565, each
        # further one on the next port.
        {
          name = "minecraft";
          sources = [ "All" ];
          destinations = [ "servers" ];
          protocols = [ "tcp" ];
          portRanges = [
            {
              start = 25565;
              end = 25574;
            }
          ];
        }
      ];

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
                  // lib.optionalAttrs (grant ? ports) { ports = map toString grant.ports; }
                  // lib.optionalAttrs (grant ? portRanges) { port_ranges = grant.portRanges; }
                )
              ];
            }
          ) grant.protocols
        ) grants
      );

      configuration = pkgs.writeText "main.tf.json" (
        builtins.toJSON (
          {
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
          }
        )
      );

      tofu = pkgs.opentofu.withPlugins (p: [
        p.hashicorp_local
        pkgs.terraform-provider-netbird
      ]);

      # Firewall openings on bachus for every grant that reaches the servers.
      toServers = lib.filter (g: lib.elem "servers" g.destinations) grants;
      openings =
        protocol:
        let
          matching = lib.filter (g: lib.elem protocol g.protocols) toServers;
        in
        {
          ports = lib.concatMap (g: g.ports or [ ]) matching;
          ranges = map (r: {
            from = r.start;
            to = r.end;
          }) (lib.concatMap (g: g.portRanges or [ ]) matching);
        };
    in
    {
      assertions = [
        {
          assertion = lib.all (name: lib.elem name groups) (lib.attrNames accounts);
          message = "Every NetBird account must belong to a group the grants name.";
        }
      ];

      sops.secrets."netbird/provision_token" = { };

      systemd.services.netbird-provision = {
        description = "Apply NetBird's account settings, groups, policies and setup keys";
        wantedBy = [ "multi-user.target" ];
        requires = [ "netbird-management.service" ];
        after = [ "netbird-management.service" ];
        path = [ tofu ];
        script = ''
          export NB_PAT="$(< "$CREDENTIALS_DIRECTORY/token")"
          ln -sf ${configuration} main.tf.json
          tofu init -input=false
          tofu apply -input=false -auto-approve
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          StateDirectory = "netbird-provision";
          StateDirectoryMode = "0700";
          WorkingDirectory = stateDirectory;
          LoadCredential = "token:${config.sops.secrets."netbird/provision_token".path}";
          # The management API answers some seconds after its unit starts.
          Restart = "on-failure";
          RestartSec = 30;
        };
      };

      services.netbird.clients.netbird.login = {
        enable = true;
        setupKeyFile = "${keyDirectory}/bachus";
        systemdDependencies = [ "netbird-provision.service" ];
      };

      # The module starts the login only alongside the daemon, which a switch
      # leaves running.
      systemd.services.netbird-login.wantedBy = [ "multi-user.target" ];

      networking.firewall.interfaces.${client.interface} = {
        allowedTCPPorts = (openings "tcp").ports;
        allowedTCPPortRanges = (openings "tcp").ranges;
        allowedUDPPorts = (openings "udp").ports;
        allowedUDPPortRanges = (openings "udp").ranges;
      };
    };
}
