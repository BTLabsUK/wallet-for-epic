#!/usr/bin/env python3
"""P, the funded CLI wallet the release checks pay from and back to, through the shared P service
(tools/rellib/p_service.py): one owner_api and one Epicbox listener of P for every check at once,
no lock. Each send picks outputs of its own; the service posts every payment P's listener finalizes
with fluff, so nothing waits on a mempool.

    with PSession(log_path) as p:     # the shared service is up (started here if none runs)
        p.send(addr, "0.02")          # P pays addr (capped)
        ...                           # the phone answers; P's listener finalizes, the service posts

Settings (env):
  REL_P_PY         p.py (default /tmp/epic-build/interop/epicpay/p.py; it knows P's host and folder)
  REL_P_PASS_FILE  file holding P's password (default ~/.config/btlabs/p-pass when not empty,
                   else line 1 of ~/.config/btlabs/p-pass-candidates); never printed or logged
  REL_P_ADDRESS    P's Epicbox address (default: the service's, read from P's listener)
  REL_P_MAX_SEND   cap per send, EPIC (default and ceiling 0.05)
  REL_P_MAX_TOTAL  cap on what P pays out in one run (default and ceiling 0.2)
"""
import os
import re
import sys
import time

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
import p_service  # noqa: E402

HOME = os.path.expanduser("~")
P_PY = os.environ.get("REL_P_PY", f"{HOME}/epic-build/interop/epicpay/p.py")
MAX_SEND = min(float(os.environ.get("REL_P_MAX_SEND", "0.05")), 0.05)
MAX_TOTAL = min(float(os.environ.get("REL_P_MAX_TOTAL", "0.2")), 0.2)
ADDR_RE = re.compile(r"\b([1-9A-HJ-NP-Za-km-z]{40,64}@[a-z0-9.-]+\.[a-z]{2,}(?::\d+)?)")


def _pass_file():
    path = os.environ.get("REL_P_PASS_FILE")
    if path:
        return path
    main = f"{HOME}/.config/btlabs/p-pass"
    if os.path.exists(main) and os.path.getsize(main) > 0:
        return main
    return f"{HOME}/.config/btlabs/p-pass-candidates"


class PSession:
    def __init__(self, log_path):
        self.log_path = log_path
        self.paid = 0.0
        self.slates = []
        cfg = p_service.env_paths(dict(os.environ, REL_P_TOOL=P_PY, REL_P_PASS_FILE=_pass_file(), REL_P_PASS_LINE="1"))
        self.client = p_service.Client(cfg, self._log)

    def _log(self, *a):
        with open(self.log_path, "a") as f:
            f.write(time.strftime("%H:%M:%S ") + " ".join(map(str, a)) + "\n")

    def __enter__(self):
        why = self.client.ensure()
        if why:
            raise RuntimeError(why)
        self._log("shared P service up")
        return self

    def __exit__(self, *exc):
        return False  # the service stays up for the other checks; it stops itself when idle

    def address(self):
        a = os.environ.get("REL_P_ADDRESS")
        if a:
            return a
        r = self.client.call("ping")
        m = ADDR_RE.search(r.get("address") or "")
        return m.group(1) if m else None

    def send(self, addr, amount):
        amt = float(amount)
        if not (0 < amt <= MAX_SEND) or self.paid + amt > MAX_TOTAL + 1e-9:
            raise ValueError(f"P send of {amount} refused (cap {MAX_SEND}/send, {MAX_TOTAL}/run)")
        if not ADDR_RE.fullmatch(addr):
            raise ValueError("not an Epicbox address")
        r = self.client.call("send", address=addr, amount=f"{amt:.8f}".rstrip("0"), what="android")
        self._log(f"send {amount} -> {addr[:12]}: {r}")
        if not r.get("ok"):
            return False, "ERROR " + r.get("note", "send failed")
        self.paid += amt
        self.slates.append(r["slate"])
        return True, f"slate {r['slate']}"

    def listener_mark(self):
        return len(self.slates)

    def finalized_since(self, mark):
        """True when one of the sends after `mark` (a listener_mark()) is finalized and posted."""
        return any(self.client.call("status", slate=s).get("state") in ("posted", "confirmed")
                   for s in self.slates[mark:])

    def repost_to(self, addr):
        """Posts P's signed copies of its sends to `addr` that are not posted yet (the service does
        this by itself as soon as P's listener finalizes; this is the driver's nudge)."""
        r = self.client.call("unposted", key=addr.split("@")[0][:24])
        ids = []
        for tx_id, _slate in r.get("sends", []):
            o = self.client.call("repost", tx_id=tx_id)
            self._log(f"repost {tx_id}: {o}")
            ids.append(tx_id)
        return ids

    def info(self):
        r = self.client.call("info")
        return r.get("spendable") if r.get("ok") else None


if __name__ == "__main__":
    # pfund.py info | address
    cmd = sys.argv[1] if len(sys.argv) > 1 else "info"
    log = os.environ.get("REL_P_LOG", os.path.join(os.environ.get("TMPDIR", "/tmp"), "pfund.log"))
    with PSession(log) as s:
        print(s.info() if cmd == "info" else s.address())
