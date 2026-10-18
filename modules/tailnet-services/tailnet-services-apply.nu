# Applies this node's declarative Tailscale Services config.
# Inputs arrive from the wrapper environment: PATH carries the tailscale CLI
# from the package the daemon runs from, CONFIG_JSON holds the service and
# node-listener lists.
def serve-until-up [args: list<string>] {
    # tailscaled is up per systemd ordering but not always ready to serve yet;
    # bounded retry instead of systemd Restart (Type=oneshot forbids it).
    mut attempts = 12
    loop {
        let result = (do { tailscale serve ...$args } | complete)
        if $result.exit_code == 0 {
            print ($result.stdout | str trim)
            return
        }
        print -e $"tailscale serve ($args | str join ' ') attempt failed:"
        print -e ($result.stderr | str trim)
        $attempts -= 1
        if $attempts == 0 {
            print -e "tailscale serve kept failing."
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
let config = (open --raw $env.CONFIG_JSON | from json)
let services = $config.services
let listeners = $config.listeners
let declared = ($services | each {|s| $"svc:($s.name)" })
let declared_ports = ($listeners | each {|l| $l.port | into string })
# The Nix lists are the source of truth: serve configs accumulate in tailscaled
# state, so anything currently configured but absent from the lists is stale
# and gets cleared before the declared config is (re)applied.
let stale = (do { tailscale serve status --json } | complete)
if $stale.exit_code != 0 {
    print -e $"tailscale serve status --json failed: ($stale.stderr | str trim)"
    exit $stale.exit_code
}
let live_status = ($stale.stdout | from json)
let live = ($live_status | get Services? | default {})
for name in ($live | columns) {
    if $name not-in $declared {
        print $"Clearing stale config for ($name)"
        tailscale serve clear $name
    }
}
let live_ports = (
    $live_status | get TCP? | default {} | columns
)
for port in $live_ports {
    if $port not-in $declared_ports {
        print $"Clearing stale listener on :($port)"
        tailscale serve --https=($port) off
    }
}
for l in $listeners {
    # Same reasoning as for services below: drop any existing config on the
    # port so a differently-shaped leftover can't make the apply fail.
    do { tailscale serve --https=($l.port) off } | complete | ignore
    serve-until-up [
        "--bg"
        $"--https=($l.port)"
        $l.target
    ]
}
for s in $services {
    # A live serve config for a declared service can conflict with the declared
    # form (e.g. created out-of-band with a different scheme); clearing the
    # service first removes any existing config so the apply below can't fail
    # on a mismatch. Harmless when nothing is configured.
    do { tailscale serve clear $"svc:($s.name)" } | complete | ignore
    # --https gives the TLS listener on the service VIP (browsers need it);
    # the target URL names the scheme its local upstream speaks. The
    # config-file format cannot express this combination, hence per-service
    # CLI config instead of set-config.
    serve-until-up [
        "--service"
        $"svc:($s.name)"
        "--https=443"
        $s.target
    ]
    advertise-or-die $"svc:($s.name)"
}
let status_result = (do { tailscale serve status --json } | complete)
if $status_result.exit_code != 0 {
    exit $status_result.exit_code
}
print ($status_result.stdout | str trim)
