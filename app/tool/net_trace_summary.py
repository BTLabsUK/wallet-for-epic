#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Sums up a network trace from tool/offline_check.sh (OFFLINE_TRACE=1).

The trace is strace's `-f -Y -yy -e trace=connect,sendto,sendmsg,sendmmsg` output of every
process in the test's network namespace. Printed per process name:

- every connect() to an address that is not loopback (IPv4, IPv6), with how often;
- every DNS question (a datagram to port 53), by name;
- connects to Unix sockets that resolve names outside the namespace (systemd-resolved, nscd,
  avahi), which would hide a lookup;
- every TCP listen() (its address from strace's -yy), and every ADD_ONION a process sent to a
  tor control port (a published onion service).

    net_trace_summary.py TRACE [--node HOST]

With --node, the last line says whether the non-loopback connects of the app's processes went
only to HOST's addresses and the DNS questions asked only for HOST. Exit status 0 always: the
test's own records say pass or fail.
"""
import argparse
import collections
import ipaddress
import re
import socket
import sys
import urllib.parse

LINE = re.compile(r'^(\d+)(?:<([^>]*)>)?\s+(connect|sendto|sendmsg|sendmmsg|listen)\((.*)$')
LISTEN_ADDR = re.compile(r'<TCPv?6?:\[([^\]]+)\]>')
INET4 = re.compile(r'sa_family=AF_INET, sin_port=htons\((\d+)\), sin_addr=inet_addr\("([^"]+)"\)')
INET6 = re.compile(r'sa_family=AF_INET6, sin6_port=htons\((\d+)\).*?inet_pton\(AF_INET6, "([^"]+)"')
UNIX = re.compile(r'sa_family=AF_UNIX, sun_path=(@?)"([^"]*)"')
# -yy names a connected UDP socket's peer: 7<UDP:[10.1.2.50:40000->1.1.1.1:53]>
UDP_PEER = re.compile(r'<UDPv?6?:\[[^\]]*->\[?([0-9a-fA-F:.]+)\]?:53\]>')
STRING = re.compile(r'"((?:[^"\\]|\\.)*)"')
RESOLVER_SOCKETS = ('/run/systemd/resolve', '/var/run/nscd', '/run/nscd', '/run/avahi-daemon', '/var/run/avahi-daemon')


def is_loopback(addr):
    try:
        ip = ipaddress.ip_address(addr)
    except ValueError:
        return False
    if ip.version == 6 and ip.ipv4_mapped:
        ip = ip.ipv4_mapped
    return ip.is_loopback or ip.is_unspecified


def unescape(text):
    """strace's C-style string escapes back to bytes."""
    out = bytearray()
    i = 0
    while i < len(text):
        c = text[i]
        if c != '\\':
            out += c.encode('latin-1', 'replace')
            i += 1
            continue
        n = text[i + 1] if i + 1 < len(text) else ''
        if n == 'x':
            out.append(int(text[i + 2:i + 4], 16))
            i += 4
        elif n.isdigit():
            j = i + 1
            while j < len(text) and j < i + 4 and text[j] in '01234567':
                j += 1
            out.append(int(text[i + 1:j], 8) & 0xFF)
            i = j
        else:
            out += {'n': b'\n', 't': b'\t', 'r': b'\r', 'v': b'\v', 'f': b'\f', '"': b'"', '\\': b'\\'}.get(n, n.encode())
            i += 2
    return bytes(out)


def qname(payload):
    """The question name of a DNS query, or None."""
    if len(payload) < 13:
        return None
    labels = []
    i = 12
    while i < len(payload):
        n = payload[i]
        if n == 0:
            return '.'.join(labels) or '.'
        if n > 63 or i + 1 + n > len(payload):
            return None
        labels.append(payload[i + 1:i + 1 + n].decode('ascii', 'replace'))
        i += 1 + n
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('trace')
    ap.add_argument('--node', help='the node host Node only may reach')
    args = ap.parse_args()

    connects = collections.defaultdict(collections.Counter)  # comm -> "ip:port" -> n
    dns = collections.defaultdict(collections.Counter)  # comm -> name -> n
    resolver = collections.defaultdict(collections.Counter)
    loopback = collections.Counter()
    listens = collections.defaultdict(collections.Counter)
    onions = collections.Counter()
    with open(args.trace, errors='replace') as f:
        for raw in f:
            m = LINE.match(raw)
            if not m:
                continue
            comm = m.group(2) or m.group(1)
            call, rest = m.group(3), m.group(4)
            if 'ADD_ONION' in rest:
                onions[comm] += 1
            if call == 'listen':
                a = LISTEN_ADDR.search(rest)
                # Counted at the call: strace may print its result on a later line.
                if not re.search(r'= -1 ', raw):
                    listens[comm][a.group(1) if a else '?'] += 1
                continue
            if call == 'connect':
                a = INET4.search(rest) or INET6.search(rest)
                if a:
                    port, addr = a.group(1), a.group(2)
                    if port == '53':
                        pass  # counted with its query below
                    elif is_loopback(addr):
                        loopback[comm] += 1
                    else:
                        connects[comm][f'{addr}:{port}'] += 1
                    continue
                u = UNIX.search(rest)
                # A resolver that is not there (ENOENT) answered nothing.
                if u and u.group(2).startswith(RESOLVER_SOCKETS) and raw.rstrip().endswith('= 0'):
                    resolver[comm][u.group(2)] += 1
                continue
            # A datagram: DNS when its socket's peer or its address is port 53.
            to53 = UDP_PEER.search(rest) or re.search(r'sin6?_port=htons\(53\)', rest)
            if not to53:
                continue
            # sendmmsg carries several questions (A and AAAA): each string is one.
            names = [qname(unescape(s.group(1))) for s in STRING.finditer(rest)] or [None]
            for name in names:
                dns[comm][name or '?'] += 1

    comms = sorted(set(connects) | set(dns) | set(resolver) | set(loopback) | set(listens) | set(onions))
    print('== network trace ==')
    if not comms:
        print('no connect() and no DNS question at all')
    for c in comms:
        out = sum(connects[c].values())
        print(f'{c}: {out} non-loopback connects, {sum(dns[c].values())} DNS questions, {loopback[c]} loopback connects')
        for dest, n in connects[c].most_common():
            print(f'    connect {dest} x{n}')
        for name, n in dns[c].most_common():
            print(f'    dns {name} x{n}')
        for path, n in resolver[c].most_common():
            print(f'    resolver socket {path} x{n}')
        for addr, n in listens[c].most_common():
            print(f'    listen {addr} x{n}')
        if onions[c]:
            print(f'    ADD_ONION sent x{onions[c]}')
    total_out = sum(sum(v.values()) for v in connects.values())
    total_dns = sum(sum(v.values()) for v in dns.values()) + sum(sum(v.values()) for v in resolver.values())
    print(f'TOTAL non-loopback connects {total_out}, DNS questions {total_dns}, '
          f'listen() {sum(sum(v.values()) for v in listens.values())}, ADD_ONION {sum(onions.values())}')
    if args.node:
        host = args.node.lower()
        if '://' in host:
            host = urllib.parse.urlsplit(host).hostname or host
        host = host.split(':')[0].rstrip('.')
        try:
            allowed = {ai[4][0] for ai in socket.getaddrinfo(host, None)}
        except OSError:
            allowed = set()
        stray = [(c, d) for c in connects for d in connects[c] if d.rsplit(':', 1)[0] not in allowed]
        stray_dns = [(c, n) for c in dns for n in dns[c] if n.lower().rstrip('.') != host]
        print(f'NODE {host} {sorted(allowed)}: other destinations {stray or "none"}; other names {stray_dns or "none"}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
