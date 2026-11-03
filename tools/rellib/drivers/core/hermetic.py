# SPDX-License-Identifier: Apache-2.0
"""The hermetic services a trust lane may point the app at: a local mainnet node and a loopback
Epicbox relay, run by tools/rellib/hermetic (node.sh, relay.sh, up.sh).

Their health scripts write status.json under the environment root (REL_HERMETIC_ROOT, default
/tmp/epic-build/rel/hermetic):
    {"node": {"url": "http://127.0.0.1:43413", "height": ..., "public": ...} or null,
     "relay": "127.0.0.1:43423" or null,
     "updated": <unix seconds>}
A service is offered only when its last health check passed and is recent: a status older than
MAX_AGE says nothing about now, so it counts as not healthy. Nothing here starts, stops or probes.
"""
import ipaddress
import json
import os
import time
import urllib.parse

MAX_AGE = 15 * 60


def root():
    return os.environ.get("REL_HERMETIC_ROOT") or os.path.expanduser("/tmp/epic-build/rel/hermetic")


def services(folder=None, now=None, max_age=MAX_AGE):
    """{"node": url or None, "relay": "127.0.0.1:port" or None}: None for a service whose last health
    check failed, or when there is no recent status at all."""
    out = {"node": None, "relay": None}
    try:
        with open(os.path.join(folder or root(), "status.json")) as f:
            d = json.load(f)
    except (OSError, ValueError):
        return out
    if not isinstance(d, dict):
        return out
    updated = d.get("updated")
    if not isinstance(updated, (int, float)) or (now if now is not None else time.time()) - updated > max_age:
        return out
    node = d.get("node")
    if isinstance(node, dict) and isinstance(node.get("url"), str) and _loopback(_host(node["url"])):
        out["node"] = node["url"]
    relay = d.get("relay")
    if isinstance(relay, str) and _loopback(_host(relay)):
        out["relay"] = relay
    return out


def _host(s):
    """The host of a URL, a host:port, a [v6]:port or a bare host."""
    s = s.strip()
    if "://" in s:
        return (urllib.parse.urlsplit(s).hostname or "").lower()
    if s.startswith("["):
        return s[1:].split("]", 1)[0].lower()
    if s.count(":") == 1:
        s = s.split(":", 1)[0]
    return s.lower()


def _loopback(host):
    if host == "localhost":
        return True
    try:
        return ipaddress.ip_address(host).is_loopback
    except ValueError:
        return False


def non_local(hosts):
    """The hosts (URLs, host:port or bare hosts) that are not loopback, in first-seen order, once each:
    what a lane still touched outside this machine."""
    seen = []
    for h in hosts:
        if not h:
            continue
        name = _host(h)
        if name and not _loopback(name) and name not in seen:
            seen.append(name)
    return seen
