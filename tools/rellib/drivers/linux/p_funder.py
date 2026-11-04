# SPDX-License-Identifier: Apache-2.0
"""P, the funded CLI wallet the release checks pay from and back to, through the shared P service
(tools/rellib/p_service.py): one owner_api and one Epicbox listener of P for every check at once.

There is no P lock any more: sends go to the service at the same time from every driver, each picks
outputs of its own, and P's listener answers and finalizes them all; the service posts each
finalized payment once with fluff, so nothing waits on the mempool. The methods keep the names of
the lock era (exchange, start_listener, stop_listener, finalized), so the
drivers' flow reads the same; start and stop are the service's business now.
"""
import contextlib
import os
import sys
import time

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
import p_service  # noqa: E402


class P:
    def __init__(self, tool, pass_file, pass_line, lock_file, log_dir, log):
        cfg = p_service.env_paths(dict(os.environ, REL_P_TOOL=tool, REL_P_PASS_FILE=pass_file,
                                       REL_P_PASS_LINE=str(pass_line)))
        self.client = p_service.Client(cfg, log)
        self.tool = tool
        self.lock_file = cfg["dir"]  # where the service lives (named for the plan lines)
        self.log_dir = log_dir
        self.log = log
        self.slate = None
        self.fee = None  # the last send's fee, from P's own tx log (None from a service without it)
        self.host = os.environ.get("P_HOST") or p_service._tool_const(tool, "HOST")

    def ready(self):
        """None when P can be used, else why not."""
        if not os.path.exists(self.tool):
            return "no P tool at %s" % self.tool
        if not p_service.password(self.client.cfg):
            return "no P password in %s" % self.client.cfg["pass_file"]
        if not self.host:
            return "no P host (P_HOST or p.py's default)"
        return None

    def _note(self, msg):
        with open(os.path.join(self.log_dir, "p.log"), "a") as lf:
            lf.write(time.strftime("%H:%M:%S ") + msg + "\n")

    @contextlib.contextmanager
    def exchange(self, what, wait_s=None):
        """One use of P: the shared service is up (started here if no driver has started it). No lock."""
        why = self.client.ensure()
        if why:
            raise TimeoutError(why)
        self.log("P (shared service) for %s" % what)
        yield self

    def start_listener(self, tries=3):
        return self.client.up() or self.client.ensure() is None

    def stop_listener(self):
        return True  # the service's listener stays up for the other checks

    def send(self, address, amount):
        r = self.client.call("send", address=address, amount=str(amount), what=os.environ.get("REL_VARIANT", ""))
        self._note("send %s -> %s: %s" % (amount, address[:12], r))
        if not r.get("ok"):
            return False, r.get("note", "send failed")
        self.slate, self.fee = r["slate"], r.get("fee")
        return True, "slate %s, tx %s" % (r["slate"][:8], r.get("tx_id"))

    def finalized(self):
        """P has finalized and posted the last send: the payment is the chain's now."""
        if not self.slate:
            return False
        r = self.client.call("status", slate=self.slate)
        return r.get("state") in ("posted", "confirmed")

    def cancel(self, slate, why=""):
        """P's send of [slate] cancelled (its inputs spendable again): a send no wallet answered. -> (ok, note)."""
        r = self.client.call("cancel", slate=slate, why=why)
        self._note("cancel %s: %s" % (slate[:8], r))
        return bool(r.get("ok")), r.get("note") or "tx %s" % r.get("tx")

    def relay(self):
        """The relay P's listener and sender use: its address's domain, as the service's ping reports it
        (None when the service does not answer). The lane's relay in use must be this one when it is local."""
        try:
            addr = self.client.call("ping", timeout=20).get("address") or ""
        except (OSError, ValueError):  # an unanswered ping: the send says why
            return None
        return addr.split("@", 1)[1] if "@" in addr else None

    def info(self):
        r = self.client.call("info")
        return r.get("spendable") if r.get("ok") else None
