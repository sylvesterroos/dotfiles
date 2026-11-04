{ config, ... }:
let
  mv = config.multiverse;
  inherit (config) tofuProvision;
in
{
  flake.modules.nixos.bachus =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.pocket-id;
      groupId = name: "\${pocketid_group.${name}.id}";
      withSecret = lib.filterAttrs (_: client: client.secret != null) cfg.clients;
      secretVariable = name: "${name}_secret";

      configuration = {
        terraform.required_providers.pocketid.source = "trozz/pocketid";
        provider.pocketid.base_url = "http://127.0.0.1:${toString config.services.pocket-id.settings.PORT}";
        resource = lib.filterAttrs (_: resources: resources != { }) {
          pocketid_group = lib.mapAttrs (name: group: {
            inherit name;
            friendly_name = group.friendlyName;
          }) cfg.groups;
          pocketid_client = lib.mapAttrs (
            name: client:
            {
              client_id = client.id;
              inherit (client) name;
              callback_urls = client.callbackUrls;
              logout_callback_urls = client.logoutCallbackUrls;
              is_public = client.public;
              pkce_enabled = client.pkce;
              allowed_user_groups = map groupId client.groups;
            }
            // lib.optionalAttrs (client.secret != null) {
              client_secret = "\${var.${secretVariable name}}";
            }
          ) cfg.clients;
        };
      }
      // lib.optionalAttrs (withSecret != { }) {
        variable = lib.mapAttrs' (
          name: _:
          lib.nameValuePair (secretVariable name) {
            type = "string";
            sensitive = true;
          }
        ) withSecret;
      }
      // lib.optionalAttrs (lib.any (client: client.existing) (lib.attrValues cfg.clients)) {
        import = lib.mapAttrsToList (name: client: {
          to = "pocketid_client.${name}";
          inherit (client) id;
        }) (lib.filterAttrs (_: client: client.existing) cfg.clients);
      };

      # Stable's provider sends the client ID in a field Pocket ID 2 ignores.
      plugins = _: [ mv.tip.terraform-providers.trozz_pocketid ];
    in
    {
      options.my.pocket-id = {
        groups = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options.friendlyName = lib.mkOption {
                type = lib.types.str;
                description = "Display name of the group.";
              };
            }
          );
          default = { };
          description = "User groups, by the name tokens carry. Membership is managed in Pocket ID.";
        };

        clients = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                id = lib.mkOption {
                  type = lib.types.str;
                  description = "Client ID the application presents.";
                };
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Display name of the client.";
                };
                callbackUrls = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  description = "Redirect URLs allowed after sign-in.";
                };
                logoutCallbackUrls = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "Redirect URLs allowed after sign-out.";
                };
                public = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Whether the client signs in without a secret.";
                };
                pkce = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Whether the client must use PKCE.";
                };
                groups = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "Groups whose members may sign in; every user may when empty.";
                };
                secret = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = ''
                    Name of the sops secret holding the client's secret. Pocket ID
                    takes this value as the client's only secret; a change rotates
                    it and revokes the previous one. Needs at least 16 printable
                    ASCII characters.
                  '';
                };
                existing = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Whether the client is already registered under this ID and is adopted.";
                };
              };
            }
          );
          default = { };
          description = "OIDC clients. A confidential client without `secret` keeps the secret Pocket ID holds.";
        };
      };

      config = {
        assertions = [
          {
            assertion = lib.all (client: lib.all (group: cfg.groups ? ${group}) client.groups) (
              lib.attrValues cfg.clients
            );
            message = "Every group a Pocket ID client admits must be declared in my.pocket-id.groups.";
          }
        ];

        sops.secrets = {
          "pocket-id/encryption_key" = { };
          "pocket-id/static_api_key" = { };
        }
        // lib.mapAttrs' (
          _: client: lib.nameValuePair client.secret { restartUnits = [ "pocket-id-provision.service" ]; }
        ) withSecret;

        services.pocket-id = {
          enable = true;
          settings = {
            APP_URL = "https://pocket-id.sylvesterroos.com";
            PORT = 1411;
            TRUST_PROXY = true;
            ANALYTICS_DISABLED = true;
          };
          credentials = {
            ENCRYPTION_KEY = config.sops.secrets."pocket-id/encryption_key".path;
            STATIC_API_KEY = config.sops.secrets."pocket-id/static_api_key".path;
          };
        };

        systemd.services.pocket-id-provision =
          tofuProvision {
            inherit pkgs plugins configuration;
            name = "pocket-id-provision";
            description = "Apply Pocket ID's declared groups and OIDC clients";
            credentials = {
              POCKETID_API_TOKEN = config.sops.secrets."pocket-id/static_api_key".path;
            }
            // lib.mapAttrs' (
              name: client:
              lib.nameValuePair "TF_VAR_${secretVariable name}" config.sops.secrets.${client.secret}.path
            ) withSecret;
          }
          // {
            requires = [ "pocket-id.service" ];
            after = [ "pocket-id.service" ];
          };

        services.caddy.virtualHosts."pocket-id.sylvesterroos.com" = {
          extraConfig = ''
            reverse_proxy 127.0.0.1:${toString config.services.pocket-id.settings.PORT}
          '';
        };
      };
    };
}
