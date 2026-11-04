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

plan() is the one decision a lane's prepare asks: which of the two the app is given, as its own
server and as the one in use, and which ports the device must reach on this host. The app speaks plain
http/ws to a loopback host only, so on every device the local services must appear on its own
127.0.0.1: Linux shares this host's loopback, the Android emulator gets adb reverses of plan's ports,
the Windows rig an ssh remote forward of them (windows/rig.py forward()).

REL_HERMETIC: "0" never uses them; "1" (release runs) makes a missing one a HarnessFault; unset uses
what services() offers and records why not for the rest (proof.json details["hermetic"]).
"""
import ipaddress
import json
import os
import re
import time
import urllib.parse

from .faults import HarnessFault

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


def local(s):
    """A URL, host:port or host on this machine's loopback."""
    return bool(s) and _loopback(_host(s))


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


def entry(url):
    """A server as the app's lists hold it: no scheme, no trailing slash ("127.0.0.1:43413")."""
    return re.sub(r"^\w+://", "", (url or "").strip()).rstrip("/").lower()


def _port(s):
    m = re.search(r":(\d+)$", entry(s))
    return int(m.group(1)) if m else None


def plan(p_addr, env=None, svc=None):
    """The servers this run gives the app. [p_addr] is P's address (checks.P_ADDR): P, the funder, is
    not on this host (p.py drives it over ssh) and posts through its address's relay, so the local relay
    is used only when that relay is it; the local node does not depend on P and is used on its own.

    -> {"on": both local, "reason": why not (or what is used), "node": the local node URL or None,
        "relay": the local relay or None, "ports": the local ports the device must reach}."""
    env = os.environ if env is None else env
    want = env.get("REL_HERMETIC", "")
    out = {"on": False, "reason": "", "node": None, "relay": None, "ports": []}
    if want == "0":
        out["reason"] = "REL_HERMETIC=0: the public node and relay through the stand-ins"
        return out
    svc = services() if svc is None else svc
    gaps = []
    if svc.get("node"):
        out["node"] = svc["node"]
    else:
        gaps.append("no healthy local node (%s, checked within %d min)" % (os.path.join(root(), "status.json"), MAX_AGE // 60))
    relay = svc.get("relay")
    p_relay = entry(p_addr.split("@", 1)[1]) if p_addr and "@" in p_addr else ""
    if not relay:
        gaps.append("no healthy local relay (%s, checked within %d min)" % (os.path.join(root(), "status.json"), MAX_AGE // 60))
    elif p_relay != entry(relay):
        gaps.append("P (the funder) posts through %s, not the local relay %s: the relay stays public" % (p_relay or "no relay", relay))
    else:
        out["relay"] = relay
    out["ports"] = [p for p in (_port(out["node"]), _port(out["relay"])) if p]
    out["on"] = bool(out["node"] and out["relay"])
    if gaps and want == "1":
        raise HarnessFault("prepare", "REL_HERMETIC=1 but %s" % "; ".join(gaps))
    used = ["local node %s" % out["node"]] if out["node"] else []
    used += ["local relay %s" % out["relay"]] if out["relay"] else []
    out["reason"] = "; ".join(([" and ".join(used) + " in use"] if used else []) + gaps)
    return out


def pick_live(node_up, relay_up, node_picks, relay_picks, env=None):
    """The public node and relay the funds legs run on (the live-servers phase): REL_NODE / REL_EPICBOX
    when set, else the first of the picks that answers its probe. -> (node URL, relay host)."""
    env = os.environ if env is None else env
    node = env.get("REL_NODE") or next((u for u in node_picks if node_up(u if "://" in u else "https://" + u)), "")
    relay = env.get("REL_EPICBOX") or next((h for h in relay_picks if relay_up(h)), "")
    if not node or not relay:
        raise HarnessFault("live-servers", "no public node or Epicbox server answers (%s / %s)" % (node_picks, relay_picks))
    return (node if "://" in node else "https://" + node), relay



# Over Tor (the Tor lanes' after-update payments): a host under the app's onion-only domain is reached at
# its built-in onion (app-config.toml [tor] onions); a public host through a Tor exit; a host on this
# machine or its LAN, or the BT Labs server's bare address (Tor exits are refused there), not at all.
TOR_ONION_ONLY = "btlabs.uk"
TOR_ONIONS = ("node.btlabs.uk", "epicbox.btlabs.uk")
TOR_REFUSED = ("203.0.113.10",)


def tor_route(s):
    """How the app reaches [s] over Tor: "onion", "exit" or None (it cannot)."""
    name = _host(s or "")
    if not name or name in TOR_REFUSED:
        return None
    if name == TOR_ONION_ONLY or name.endswith("." + TOR_ONION_ONLY):
        return "onion" if name in TOR_ONIONS else None
    try:
        a = ipaddress.ip_address(name)
        return None if (a.is_private or a.is_loopback or a.is_link_local) else "exit"
    except ValueError:
        return None if name == "localhost" or name.endswith(".local") else "exit"


HOST_IN_LOG = re.compile(r"\b[a-z][a-z0-9+.-]*://([^/\s'\"<>)]+)|\b(?:relay|node|server|host)=([^\s,;'\"<>)]+)", re.I)


def log_hosts(line):
    """The hosts a log line names: URLs and relay=/node=/server=/host= values."""
    return [a or b for a, b in HOST_IN_LOG.findall(line or "")]
