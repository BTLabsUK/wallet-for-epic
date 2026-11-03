# SPDX-License-Identifier: Apache-2.0
"""Which of the test nodes is fit to use now: it answers, says it is synced, and is not behind the others.

A wallet on a node that is down, syncing or stuck behind waits for nothing (P's 4.1.0 listener pauses on
"Node not synced" and finalizes no payment; a LEPIC CLI read sees an old chain). The harness moves such a
wallet to the next synced node of its list and logs the move (lane wallets: core/walletdata.py; P:
p_service.py). The list is the wallet's own node first, then release/pipeline.toml [defaults] nodes.
"""
import concurrent.futures
import json
import urllib.error
import urllib.request

BEHIND = 5          # blocks behind the best answering node that still count as synced
TIMEOUT = 8


def status(url, timeout=TIMEOUT):
    """(state, height) of one node from its /v1/status: "ok", "syncing" (with the node's sync_status),
    "down" (no answer) or "unknown" (it answers but not with a status: kept where it is)."""
    u = url if "://" in url else "https://" + url
    try:
        with urllib.request.urlopen(u.rstrip("/") + "/v1/status", timeout=timeout) as r:
            d = json.load(r)
    except urllib.error.HTTPError:
        return "unknown", None
    except Exception:  # noqa: BLE001 - refused, timed out, TLS: nothing usable answers there
        return "down", None
    try:
        height = int(d["tip"]["height"])
    except (KeyError, TypeError, ValueError):
        return "unknown", None
    sync = d.get("sync_status") or "no_sync"
    return ("ok", height) if sync == "no_sync" else ("syncing " + str(sync), height)


def judge(urls, probe=status):
    """{url: why it is unfit, or None} for each of urls, probed side by side."""
    urls = [u for u in dict.fromkeys(urls) if u]
    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1, len(urls))) as ex:
        got = dict(zip(urls, ex.map(probe, urls)))
    best = max((h for s, h in got.values() if s == "ok" and h is not None), default=None)
    why = {}
    for u, (state, h) in got.items():
        if state == "down":
            why[u] = "not reachable"
        elif state.startswith("syncing"):
            why[u] = "not synced (%s, height %s)" % (state.split(" ", 1)[1], h)
        elif state == "ok" and best is not None and h < best - BEHIND:
            why[u] = "not synced (height %d, the others at %d)" % (h, best)
        else:
            why[u] = None
    return why


def synced_first(urls, log=None, probe=status, what="node"):
    """urls with the fit ones first, each group in its own order (so a run with every node unfit still
    tries them all). When the first one moves, log says from which, why and to which."""
    if not urls:
        return list(urls)
    why = judge(urls, probe)
    order = [u for u in urls if not why.get(u)] + [u for u in urls if why.get(u)]
    if log and order[0] != urls[0] and not why.get(order[0]):
        log("%s %s %s: using %s, the next synced one" % (what, urls[0], why[urls[0]], order[0]))
    elif log and why.get(order[0]):
        log("no %s is synced (%s): trying them in order" % (
            what, "; ".join("%s %s" % (u, why[u]) for u in urls)))
    return order
