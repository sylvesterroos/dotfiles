# Applies this node's declarative Tailscale Services config.
# Inputs arrive from the wrapper environment: PATH carries the tailscale CLI
# from the package the daemon runs from, SERVICES_JSON holds the service list.
def set-config-until-up [config_path: string] {
    # tailscaled is up per systemd ordering but not always ready to serve yet;
    # bounded retry instead of systemd Restart (Type=oneshot forbids it).
    mut attempts = 12
    loop {
        let result = (do { tailscale serve set-config --all $config_path } | complete)
        if $result.exit_code == 0 {
            print ($result.stdout | str trim)
            return
        }
        print -e "tailscale serve set-config attempt failed:"
        print -e ($result.stderr | str trim)
        $attempts -= 1
        if $attempts == 0 {
            print -e "tailscale serve set-config kept failing."
            exit 1
        }
        sleep 10sec
    }
}
def advertise-or-die [service: string] {
    let result = (do { tailscale serve advertise $service } | complete)
    if $result.exit_code == 0 {
        print ($result.stdout | str trim)
    } else {
        print -e $"Advertising ($service) failed."
        print -e "Check: node is tagged (tagOwners in the ACL file), ($service) exists on the admin console Services page, and the services auto-approver rule covers it."
        exit 1
    }
}
let services = (open --raw $env.SERVICES_JSON | from json)
# The admin-console service definition carries the MagicDNS name and the
# https:443 endpoint; this config binds each service name to its local target.
let services_config = ($services | each {|s|
    {
      $"svc:($s.name)": {
        endpoints: {
          "tcp:443": $"http://($s.target)"
        }
      }
    }
  } | reduce --fold {} {|entry, acc| $acc | merge $entry })
let config_path = ([
    $nu.temp-dir
    "tailnet-services-serve.json"
] | path join)
{version: "0.0.1", services: $services_config} | to json | save --force $config_path
set-config-until-up $config_path
for s in $services { advertise-or-die $"svc:($s.name)" }
let status_result = (do { tailscale serve status } | complete)
if $status_result.exit_code != 0 {
    exit $status_result.exit_code
}
print ($status_result.stdout | str trim)
