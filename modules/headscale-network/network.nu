#!/usr/bin/env nu
# Owns the routed Headscale namespace and its host-side addresses.
def checked [command: string, args: list<string>] {
    let result = (^$command ...$args | complete)
    if $result.exit_code != 0 {
        error make {
            msg: $"($command) ($args | str join ' '): ($result.stderr | str trim)"
        }
    }
    $result.stdout
}
def ip [args: list<string>] { checked $env.IP $args }
def ns-ip [args: list<string>] { ip ([
    netns
    exec
    headscale
    $env.IP
] ++ $args) }
def ns-sysctl [setting: string] {
    ip [
        netns
        exec
        headscale
        $env.SYSCTL
        -w
        $setting
    ]
}
def nft [rules: string] {
    let result = ($rules | ^$env.NFT -f - | complete)
    if $result.exit_code != 0 {
        error make {
            msg: ($result.stderr | str trim)
        }
    }
}
def ns-nft [rules: string] {
    let result = ($rules | ^$env.IP netns exec headscale $env.NFT -f - | complete)
    if $result.exit_code != 0 {
        error make {
            msg: ($result.stderr | str trim)
        }
    }
}
def main [action: string] {
    let config = (open $env.CONFIG)
    let state = '/run/headscale-network/addresses.json'
    match $action {
        up => {
            ip [netns, add, headscale] | ignore
            ip [
                link
                add
                headscale-host
                type
                veth
                peer
                name
                headscale-ns
            ] | ignore
            ip [link, set, headscale-ns, netns, headscale] | ignore
            ip [addr, add, 10.203.0.1/30, dev, headscale-host] | ignore
            ip [
                -6
                addr
                add
                fd72:203::1/64
                dev
                headscale-host
                nodad
            ] | ignore
            ip [link, set, headscale-host, up] | ignore
            ns-ip [link, set, lo, up] | ignore
            ns-ip [addr, add, 10.203.0.2/30, dev, headscale-ns] | ignore
            ns-ip [
                -6
                addr
                add
                fd72:203::2/64
                dev
                headscale-ns
                nodad
            ] | ignore
            ns-ip [link, set, headscale-ns, up] | ignore
            ns-ip [route, add, default, via, 10.203.0.1] | ignore
            ns-sysctl net.ipv4.ip_forward=1 | ignore
            ns-sysctl net.ipv6.conf.all.forwarding=1 | ignore
            ns-sysctl net.ipv4.conf.all.rp_filter=0 | ignore
            ns-sysctl net.ipv4.conf.headscale-ns.rp_filter=0 | ignore
            ns-sysctl net.ipv4.conf.headscale-ns.accept_local=1 | ignore
            # Decrypted packets for this node reach host sockets before the
            # namespace's local-address lookup. Locally generated packets keep
            # using the namespace's local addresses and Tailscale route table.
            ns-ip [
                rule
                add
                priority
                100
                lookup
                local
            ] | ignore
            ns-ip [rule, del, priority, 0] | ignore
            ns-ip [
                rule
                add
                priority
                50
                iif
                tailscale1
                lookup
                53
            ] | ignore
            ns-ip [
                -6
                rule
                add
                priority
                100
                lookup
                local
            ] | ignore
            ns-ip [-6, rule, del, priority, 0] | ignore
            ns-ip [
                -6
                rule
                add
                priority
                50
                iif
                tailscale1
                lookup
                53
            ] | ignore
            ip [
                route
                add
                table
                53
                $config.ipv4Prefix
                via
                10.203.0.2
            ] | ignore
            ip [
                -6
                route
                add
                table
                53
                $config.ipv6Prefix
                via
                fd72:203::2
            ] | ignore
            ip [
                rule
                add
                priority
                5000
                to
                $config.ipv4Prefix
                lookup
                53
            ] | ignore
            ip [
                -6
                rule
                add
                priority
                5000
                to
                $config.ipv6Prefix
                lookup
                53
            ] | ignore
            # The namespace's internet connection uses the physical host route,
            # independently of personal Tailscale exit-node policy.
            ip [
                rule
                add
                priority
                5100
                from
                10.203.0.2/32
                lookup
                main
            ] | ignore
            ns-nft 'table inet headscale {
                chain forward {
                    type filter hook forward priority filter; policy drop;
                    ct state established,related accept
                    iifname "headscale-ns" oifname "tailscale1" accept
                    iifname "tailscale1" oifname "headscale-ns" accept
                }
                chain source {
                    type nat hook postrouting priority srcnat; policy accept;
                    oifname "tailscale1" ip saddr 10.203.0.1 masquerade
                    oifname "tailscale1" ip6 saddr fd72:203::1 masquerade
                }
            }'
            nft 'table inet headscale_host {
                chain source {
                    type nat hook postrouting priority srcnat; policy accept;
                    ip saddr 10.203.0.2 oifname != "headscale-host" masquerade
                }
            }'
        }
        attach => {
            checked $env.TAILSCALE [
                $"--socket=($config.socket)"
                set
                --accept-dns=false
                --netfilter-mode=off
            ] | ignore
            ip [
                netns
                exec
                headscale
                $env.TAILSCALE
                $"--socket=($config.socket)"
                wait
                --timeout=60s
            ] | ignore
            let links = (ip [-j, link, show] | from json)
            if ($links | any {|link| $link.ifname == 'tailscale0'}) {
                let primary = (checked $env.TAILSCALE [status, --json] | from json)
                if 'disable-linux-cgnat-drop-rule' not-in ($primary.Self.CapMap? | default {}) {
                    error make {msg: 'Enable disable-linux-cgnat-drop-rule for this device in the hosted Tailscale policy before attaching Headscale.'}
                }
            }
            let status = (checked $env.TAILSCALE [
                $"--socket=($config.socket)"
                status
                --json
            ] | from json)
            let addresses = $status.TailscaleIPs
            $addresses | to json | save --force $state
            for address in $addresses {
                let ipv6 = ($address | str contains ':')
                let family = (if $ipv6 { ['-6'] } else { [] })
                let prefix = (if $ipv6 { $"($address)/128" } else { $"($address)/32" })
                let host = (if $ipv6 { 'fd72:203::1' } else { '10.203.0.1' })
                let gateway = (if $ipv6 { 'fd72:203::2' } else { '10.203.0.2' })
                let allocation = (if $ipv6 { $config.ipv6Prefix } else { $config.ipv4Prefix })
                let dad = (if $ipv6 { [nodad] } else { [] })
                ip ($family ++ [addr, replace, $prefix, dev, headscale-host] ++ $dad) | ignore
                ns-ip ($family ++ [
                    route
                    replace
                    table
                    '53'
                    $prefix
                    via
                    $host
                ]) | ignore
                ip ($family ++ [
                    route
                    replace
                    table
                    '53'
                    $allocation
                    via
                    $gateway
                    src
                    $address
                ]) | ignore
            }
        }
        detach => {
            if ($state | path exists) {
                for address in (open $state) {
                    let ipv6 = ($address | str contains ':')
                    let family = (if $ipv6 { ['-6'] } else { [] })
                    let prefix = (if $ipv6 { $"($address)/128" } else { $"($address)/32" })
                    let gateway = (if $ipv6 { 'fd72:203::2' } else { '10.203.0.2' })
                    let allocation = (if $ipv6 { $config.ipv6Prefix } else { $config.ipv4Prefix })
                    ip ($family ++ [
                        route
                        replace
                        table
                        '53'
                        $allocation
                        via
                        $gateway
                    ]) | ignore
                    ip ($family ++ [addr, del, $prefix, dev, headscale-host]) | ignore
                    ns-ip ($family ++ [route, del, table, '53', $prefix]) | ignore
                }
                rm $state
            }
        }
        down => {
            for family in [
                []
                ['-6']
            ] {
                let rules = (ip ($family ++ [-j, rule, show]) | from json)
                for priority in [5000, 5100] {
                    if ($rules | any {|rule| $rule.priority == $priority}) {
                        ip ($family ++ [
                            rule
                            del
                            priority
                            ($priority | into string)
                        ]) | ignore
                    }
                }
                let routes = (ip ($family ++ [-j, route, show, table, all]) | from json)
                if ($routes | any {|route| $route.table? == 53}) {
                    ip ($family ++ [route, flush, table, '53']) | ignore
                }
            }
            let tables = (checked $env.NFT [-j, list, tables] | from json)
            if ($tables.nftables | any {|item| $item.table?.name? == 'headscale_host'}) {
                checked $env.NFT [delete, table, inet, headscale_host] | ignore
            }
            let namespaces = (ip [-j, netns, list] | from json)
            if ($namespaces | any {|namespace| $namespace.name == 'headscale'}) {
                ip [netns, delete, headscale] | ignore
            }
            let links = (ip [-j, link, show] | from json)
            if ($links | any {|link| $link.ifname == 'headscale-host'}) {
                ip [link, del, headscale-host] | ignore
            }
        }
        _ => { error make {
            msg: $"Expected up, attach, detach or down; got ($action)."
        } }
    }
}
