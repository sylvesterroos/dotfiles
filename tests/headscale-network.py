"""Exercise the Headscale network lifecycle in a disposable NixOS VM.

The controller fixture supplies node metadata; real kernel routes, sockets,
TUN interfaces and DNS services carry the test traffic.
"""
import json
import fcntl
import os
from pathlib import Path
import shutil
import select
import socket
import struct
import subprocess
import sys

SCRIPT = Path(os.environ["NETWORK_SCRIPT"])


def run(*args, namespace=None, check=True, env=None):
    command = list(args)
    if namespace:
        command = ["ip", "netns", "exec", namespace, *command]
    result = subprocess.run(command, text=True, capture_output=True, env=env)
    if check:
        assert result.returncode == 0, f"{command}: {result.stderr}"
    return result


def skip_name(packet, offset):
    while packet[offset]:
        if packet[offset] & 0xC0 == 0xC0:
            return offset + 2
        offset += packet[offset] + 1
    return offset + 1


def query(address, name):
    labels = b"".join(bytes([len(label)]) + label.encode() for label in name.split(".")) + b"\0"
    packet = struct.pack("!HHHHHH", 123, 0x100, 1, 0, 0, 0) + labels + struct.pack("!HH", 1, 1)
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.settimeout(0.2)
        sock.sendto(packet, (address, 53))
        reply, _ = sock.recvfrom(4096)
    assert struct.unpack("!H", reply[:2])[0] == 123
    assert reply[3] & 15 == 0, reply
    _, _, questions, answers, _, _ = struct.unpack("!HHHHHH", reply[:12])
    offset = 12
    for _ in range(questions):
        offset = skip_name(reply, offset) + 4
    for _ in range(answers):
        offset = skip_name(reply, offset)
        kind, _, _, length = struct.unpack("!HHIH", reply[offset:offset + 10])
        offset += 10
        if kind == 1:
            return socket.inet_ntoa(reply[offset:offset + length])
        offset += length
    raise AssertionError(f"DNS response contains no A record: {reply.hex()}")


def worker():
    mode, *args = sys.argv[2:]
    if mode == "relay":
        device, descriptor = args
        tun = os.open("/dev/net/tun", os.O_RDWR)
        fcntl.ioctl(tun, 0x400454CA, struct.pack("16sH", device.encode(), 0x1001))
        transport = socket.socket(fileno=int(descriptor))
        print("ready", flush=True)
        while True:
            ready, _, _ = select.select([tun, transport], [], [])
            if tun in ready:
                packet = os.read(tun, 65535)
                transport.send(packet)
            if transport in ready:
                packet = transport.recv(65535)
                os.write(tun, packet)
    if mode == "dns":
        address, response = args
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
            sock.bind((address, 53))
            print("ready", flush=True)
            while True:
                packet, peer = sock.recvfrom(4096)
                question = packet[12:skip_name(packet, 12) + 4]
                header = packet[:2] + struct.pack("!HHHHH", 0x8180, 1, 1, 0, 0)
                answer = b"\xc0\x0c" + struct.pack("!HHIH", 1, 1, 0, 4) + socket.inet_aton(response)
                sock.sendto(header + question + answer, peer)
    kind, address, port = args
    family = socket.AF_INET6 if ":" in address else socket.AF_INET
    protocol = socket.SOCK_DGRAM if kind == "udp" else socket.SOCK_STREAM
    with socket.socket(family, protocol) as sock:
        sock.settimeout(3)
        if mode == "server":
            sock.bind((address, int(port)))
            if kind == "tcp":
                sock.listen(1)
            print("ready", flush=True)
            if kind == "udp":
                payload, peer = sock.recvfrom(4096)
                sock.sendto(json.dumps({"source": peer[0], "payload": payload.decode()}).encode(), peer)
            else:
                with sock.accept()[0] as connection:
                    payload = connection.recv(4096)
                    connection.sendall(json.dumps({"source": connection.getpeername()[0], "payload": payload.decode()}).encode())
        else:
            sock.connect((address, int(port)))
            sock.send(b"headscale-network")
            print(sock.recv(4096).decode())


def test():
    processes = []
    results = []
    work = Path("/run/headscale-network")
    work.mkdir()
    config = work / "config.json"
    config.write_text(json.dumps({"ipv4Prefix": "100.64.0.0/24", "ipv6Prefix": "fd7a:115c:a1e0::/120", "socket": "fixture"}))
    fixture = work / "tailscale-fixture"
    fixture.write_text(f'''#!{sys.executable}
import json, os, sys
if "status" in sys.argv:
    if "--socket=fixture" in sys.argv:
        print(json.dumps({{"TailscaleIPs": ["100.64.0.3", "fd7a:115c:a1e0::3"]}}))
    else:
        caps = {{"disable-linux-cgnat-drop-rule": []}} if os.environ.get("ATTRIBUTE") == "enabled" else {{}}
        print(json.dumps({{"Self": {{"CapMap": caps}}}}))
''')
    fixture.chmod(0o700)
    env = os.environ | {"CONFIG": str(config), "TAILSCALE": str(fixture), "ATTRIBUTE": "enabled"}
    env |= {name: shutil.which(exe) for name, exe in [("IP", "ip"), ("NFT", "nft"), ("SYSCTL", "sysctl")]}

    def action(name, check=True, environment=env):
        return run(str(SCRIPT), name, check=check, env=environment)

    def start(namespace, *args, pass_fds=()):
        command = [sys.executable, str(Path(__file__).resolve()), "worker", *args]
        if namespace:
            command = ["ip", "netns", "exec", namespace, *command]
        process = subprocess.Popen(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, pass_fds=pass_fds)
        processes.append(process)
        assert process.stdout is not None and process.stderr is not None
        assert process.stdout.readline().strip() == "ready", process.stderr.read()
        return process

    def exchange(direction, kind, source_namespace, server_namespace, target, expected_source):
        server = start(server_namespace, "server", kind, target, "23456")
        result = json.loads(run(sys.executable, str(Path(__file__).resolve()), "worker", "client", kind, target, "23456", namespace=source_namespace).stdout)
        assert result == {"source": expected_source, "payload": "headscale-network"}, result
        assert server.wait(timeout=5) == 0
        results.append({"direction": direction, "protocol": kind, "target": target})

    try:
        run("ip", "link", "set", "lo", "up")
        # A separate personal VPN supplies actual traffic in routing table 52.
        run("ip", "netns", "add", "personal")
        run("ip", "link", "add", "tailscale0", "type", "veth", "peer", "name", "personal-peer")
        run("ip", "link", "set", "personal-peer", "netns", "personal")
        run("ip", "addr", "add", "100.101.139.30/32", "dev", "tailscale0")
        run("ip", "link", "set", "tailscale0", "up")
        run("ip", "addr", "add", "100.95.166.12/32", "dev", "personal-peer", namespace="personal")
        run("ip", "link", "set", "personal-peer", "up", namespace="personal")
        run("ip", "route", "add", "100.101.139.30/32", "dev", "personal-peer", namespace="personal")
        run("ip", "route", "add", "table", "52", "100.95.166.12/32", "dev", "tailscale0", "src", "100.101.139.30")
        run("ip", "rule", "add", "priority", "5270", "lookup", "52")
        before = run("ip", "-j", "route", "show", "table", "52").stdout
        run("ip", "netns", "add", "internet")
        run("ip", "link", "add", "internet-host", "type", "veth", "peer", "name", "internet-peer")
        run("ip", "link", "set", "internet-peer", "netns", "internet")
        run("ip", "addr", "add", "192.0.2.1/30", "dev", "internet-host")
        run("ip", "link", "set", "internet-host", "up")
        run("ip", "addr", "add", "192.0.2.2/30", "dev", "internet-peer", namespace="internet")
        run("ip", "link", "set", "internet-peer", "up", namespace="internet")
        action("up")
        for kind in ["tcp", "udp"]:
            exchange("namespace-internet", kind, "headscale", "internet", "192.0.2.2", "192.0.2.1")
        run("ip", "netns", "add", "peer")
        run("ip", "tuntap", "add", "dev", "tailscale1", "mode", "tun", namespace="headscale")
        run("ip", "tuntap", "add", "dev", "remote", "mode", "tun", namespace="peer")
        for namespace, device, v4, v6 in [("headscale", "tailscale1", "100.64.0.3/24", "fd7a:115c:a1e0::3/120"), ("peer", "remote", "100.64.0.2/24", "fd7a:115c:a1e0::2/120")]:
            run("ip", "addr", "add", v4, "dev", device, namespace=namespace)
            run("ip", "-6", "addr", "add", v6, "dev", device, "nodad", namespace=namespace)
            run("ip", "link", "set", device, "up", namespace=namespace)
            run("ip", "link", "set", "lo", "up", namespace=namespace)
        # Both TUN devices are up before relays deliver their first packets.
        left, right = socket.socketpair(socket.AF_UNIX, socket.SOCK_DGRAM)
        start("headscale", "relay", "tailscale1", str(left.fileno()), pass_fds=(left.fileno(),))
        start("peer", "relay", "remote", str(right.fileno()), pass_fds=(right.fileno(),))
        left.close()
        right.close()
        denied = action("attach", check=False, environment=env | {"ATTRIBUTE": "disabled"})
        assert denied.returncode != 0 and "Enable disable-linux-cgnat-drop-rule" in denied.stderr, denied.stderr
        results.append({"missing_policy_attribute": "rejected"})
        action("attach")
        for kind in ["tcp", "udp"]:
            for node, peer in [("100.64.0.3", "100.64.0.2"), ("fd7a:115c:a1e0::3", "fd7a:115c:a1e0::2")]:
                exchange("outgoing", kind, None, "peer", peer, node)
                exchange("incoming", kind, "peer", None, node, peer)
            exchange("personal-vpn", kind, None, "personal", "100.95.166.12", "100.101.139.30")
        run("ip", "addr", "add", "100.100.100.100/32", "dev", "lo", namespace="headscale")
        start("headscale", "dns", "100.100.100.100", "100.64.0.2")
        start(None, "dns", "100.101.139.30", "100.95.166.12")
        dns = subprocess.Popen(["ip", "netns", "exec", "headscale", "dnsmasq", "--keep-in-foreground", "--log-facility=-", "--no-resolv", "--no-hosts", "--bind-interfaces", "--listen-address=10.203.0.2", "--server=100.100.100.100", "--cache-size=0", "--user=root"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        processes.append(dns)
        assert dns.stderr is not None
        for name in ["bachus.tailnet.sylvesterroos.com", "jellyfin.tailnet.sylvesterroos.com"]:
            for attempt in range(20):
                try:
                    assert query("10.203.0.2", name) == "100.64.0.2"
                    break
                except TimeoutError:
                    if dns.poll() is not None:
                        raise AssertionError(dns.stderr.read())
            else:
                raise AssertionError("DNS endpoint did not answer")
            results.append({"dns_forwarding": name})
            assert socket.gethostbyname(name) == "100.64.0.2"
            results.append({"split_dns": name})
        assert socket.gethostbyname("bachus.personal.test") == "100.95.166.12"
        results.append({"split_dns": "personal network"})
        assert run("ip", "-j", "route", "show", "table", "52").stdout == before
        action("detach")
        action("attach")
        exchange("reattached", "udp", None, "peer", "100.64.0.2", "100.64.0.3")
        action("detach")
        action("down")
        action("down")
        assert run("ip", "-j", "route", "show", "table", "52").stdout == before
        assert all(link["ifname"] != "headscale-host" for link in json.loads(run("ip", "-j", "link", "show").stdout))
        exchange("personal-after-stop", "udp", None, "personal", "100.95.166.12", "100.101.139.30")
        assert socket.gethostbyname("bachus.personal.test") == "100.95.166.12"
        results.append({"cleanup": "repeatable; primary routes and traffic preserved"})
        print(json.dumps({"passed": results}, indent=2))
    finally:
        if sys.exc_info()[0] is not None:
            for namespace in [None, "headscale", "peer"]:
                for command in [("ip", "rule", "show"), ("ip", "route", "show", "table", "all"), ("ip", "-6", "route", "show", "table", "all")]:
                    print(namespace, run(*command, namespace=namespace, check=False).stdout, file=sys.stderr)

        for process in reversed(processes):
            if process.poll() is None:
                process.terminate()
            process.wait(timeout=5)
            if process.returncode not in (0, -15) and process.stderr is not None:
                print(process.args, process.stderr.read(), file=sys.stderr)
        # The test driver destroys the VM after the test.


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "worker":
        worker()
    else:
        test()
