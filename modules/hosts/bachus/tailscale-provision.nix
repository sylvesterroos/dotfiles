# The tailnet policy and the Tailscale Services that `my.tailnet-services`
# publishes, applied by OpenTofu on every switch. The state lives on this host.
#
# Bootstrap: create an OAuth client in the admin console with the `services`
# and `policy_file` write scopes, store its ID and secret as sops
# `tailscale/oauth_client_id` and `tailscale/oauth_client_secret`, then import
# this module.
{
  flake.modules.nixos.tailscale-provision =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      stateDirectory = "/var/lib/tailscale-provision";

      serviceNames = map (service: "svc:${service.name}") config.my.tailnet-services.services;

      policy = {
        tagOwners."tag:server" = [ "autogroup:admin" ];
        acls = [
          {
            action = "accept";
            src = [ "*" ];
            dst = [ "*:*" ];
          }
        ];
        # Services bachus (tag:server) may advertise without console approval.
        autoApprovers.services = lib.genAttrs serviceNames (_: [ "tag:server" ]);
        # Services are deny-by-default destinations.
        grants = [
          {
            src = [ "autogroup:member" ];
            dst = serviceNames;
            ip = [ "*" ];
          }
        ];
        ssh = [
          {
            action = "check";
            src = [ "autogroup:member" ];
            dst = [ "autogroup:self" ];
            users = [
              "autogroup:nonroot"
              "root"
            ];
          }
        ];
        nodeAttrs = [
          {
            target = [ "autogroup:member" ];
            attr = [ "funnel" ];
          }
        ];
      };

      configuration = pkgs.writeText "main.tf.json" (
        builtins.toJSON {
          terraform.required_providers.tailscale.source = "tailscale/tailscale";
          resource.tailscale_service = lib.listToAttrs (
            map (
              service:
              lib.nameValuePair service.name {
                name = "svc:${service.name}";
                ports = [ "tcp:443" ];
              }
            ) config.my.tailnet-services.services
          );
          resource.tailscale_acl.policy.acl = builtins.toJSON policy;
          import = [
            {
              to = "tailscale_acl.policy";
              id = "acl";
            }
          ];
        }
      );

      tofu = pkgs.opentofu.withPlugins (p: [ p.tailscale_tailscale ]);
    in
    {
      sops.secrets = {
        "tailscale/oauth_client_id" = { };
        "tailscale/oauth_client_secret" = { };
      };

      systemd.services.tailscale-provision = {
        description = "Define the Tailscale Services of this host";
        wantedBy = [ "multi-user.target" ];
        before = [ "tailnet-services-apply.service" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        path = [ tofu ];
        environment = {
          TAILSCALE_OAUTH_CLIENT_ID = "file:%d/client_id";
          TAILSCALE_OAUTH_CLIENT_SECRET = "file:%d/client_secret";
        };
        script = ''
          ln -sf ${configuration} main.tf.json
          tofu init -input=false
          tofu apply -input=false -auto-approve
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          StateDirectory = "tailscale-provision";
          StateDirectoryMode = "0700";
          WorkingDirectory = stateDirectory;
          LoadCredential = [
            "client_id:${config.sops.secrets."tailscale/oauth_client_id".path}"
            "client_secret:${config.sops.secrets."tailscale/oauth_client_secret".path}"
          ];
        };
      };
    };
}
