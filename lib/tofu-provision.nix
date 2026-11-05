# A systemd unit that applies an OpenTofu configuration on every switch. State
# lives in /var/lib/<name>; each credential is exported under its own name.
{
  pkgs,
  name,
  description,
  plugins,
  configuration,
  credentials,
}:
{
  inherit description;
  wantedBy = [ "multi-user.target" ];
  path = [ (pkgs.opentofu.withPlugins plugins) ];
  script = ''
    ${pkgs.lib.concatMapStrings (variable: ''
      ${variable}=$(< "$CREDENTIALS_DIRECTORY/${variable}")
      export ${variable}
    '') (builtins.attrNames credentials)}
    ln -sf ${pkgs.writeText "main.tf.json" (builtins.toJSON configuration)} main.tf.json
    tofu init -input=false -upgrade
    tofu apply -input=false -auto-approve
  '';
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
    StateDirectory = name;
    StateDirectoryMode = "0700";
    WorkingDirectory = "/var/lib/${name}";
    LoadCredential = pkgs.lib.mapAttrsToList (variable: path: "${variable}:${path}") credentials;
    Restart = "on-failure";
    RestartSec = 30;
  };
}
