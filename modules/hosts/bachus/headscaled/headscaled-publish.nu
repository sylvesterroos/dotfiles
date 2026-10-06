#!/usr/bin/env nu
# Publishes bachus's services once headscaled is on the headscale tailnet.
#
# Tags this node so the ACL policy grants it the published port, and fills its
# address into the MagicDNS records, so each published hostname resolves to the
# tailnet rather than to the public address the Porkbun wildcard answers with.
# Then forwards the published port of that address to the local proxy.
#
# Paths and values arrive through the environment. The records arrive as a
# template holding @ADDRESS@ wherever the address belongs.
# The interpolation needs its own quotes: in a bare word nu passes
# --socket=$env.SOCKET through literally.
let socket = $"--socket=($env.SOCKET)"
# headscaled reports no address until it has connected, which takes a few
# seconds after it starts.
let waited = (^$env.TAILSCALE $socket wait --timeout=60s | complete)
if $waited.exit_code != 0 {
    error make {
        msg: $"headscaled is not on the headscale tailnet: ($waited.stderr | str trim). A new machine logs in with `sudo headscaled login --login-server <url>`."
    }
}
let address = (^$env.TAILSCALE $socket ip -4 | lines | first)
# headscale may still be starting when this runs during a switch; its CLI
# fails until the socket answers.
def headscale [args: list<string>] {
    mut result = {}
    for attempt in 1..30 {
        $result = (^$env.HEADSCALE ...$args --output json | complete)
        if $result.exit_code == 0 {
            return ($result.stdout | from json)
        }
        sleep 1sec
    }
    error make {
        msg: $"headscale ($args | str join ' ') kept failing: ($result.stderr | str trim)"
    }
}
let node = (headscale [nodes, list] | where {|node| $address in $node.ip_addresses } | first)
if $node == null {
    error make {
        msg: $"headscale has no node with address ($address)"
    }
}
if $env.TAG not-in ($node.tags? | default []) {
    headscale [
        nodes
        tag
        --identifier
        ($node.id | into string)
        --tags
        $env.TAG
    ] | ignore
    print $"tagged node ($node.id) with ($env.TAG)"
}
# Written in place: headscale watches the records file by inode, so a replaced
# file ends the watch. A half-written read fails to parse and headscale keeps
# the previous records until the next write event.
open --raw $env.RECORDS_TEMPLATE | str replace --all "@ADDRESS@" $address | save --force $env.RECORDS_FILE
# Raw TCP forwarding: TLS terminates at the proxy, with its own certificates.
^$env.TAILSCALE $socket serve --bg $"--tcp=($env.SERVE_PORT)" $env.SERVE_TARGET
print $"published on ($address)"
