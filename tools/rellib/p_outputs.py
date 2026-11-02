# SPDX-License-Identifier: Apache-2.0
"""P's spendable outputs, so the update-trust checks never queue on P's locked change.

The trust checks pay from P (the funded CLI wallet, driven through p.py) and run side by side; a
send locks the output it spends until its change confirms. With at least LOW confirmed outputs
every check finds one free. The release preflight counts them and, below LOW, splits P with one
self-send (`-m self`: no Epicbox, no listener, a few seconds) towards TARGET. It does not wait for
the split to confirm: P counts outputs with one confirmation, and the builds take longer than a
block. P's one-shots go through the shared P service (p_service): no lock, no confirmation wait.
"""
import time
import os
import re

LOW, TARGET, HIGH = 8, 16, 20
MIN_CONF = 1  # P is a test wallet: one confirmation, not the CLI's default of 10 (p.py passes -c 1)
SPLIT_AMOUNT = "0.01"


def spendable(outputs_text, min_conf=MIN_CONF):
    """How many outputs of `outputs` are Unspent with at least `min_conf` confirmations."""
    m = re.search(r"Block Height:\s*(\d+)", outputs_text)
    if not m:
        return None
    tip = int(m.group(1))
    n = 0
    for line in outputs_text.splitlines():
        r = re.match(r"\s*[0-9a-f]{66}\s+\S+\s+(\d+)\s+\d+\s+Unspent\b", line)
        if r and tip - int(r.group(1)) + 1 >= min_conf:
            n += 1
    return n


def split_args(have):
    """The p.py arguments of the self-send that brings `have` spendable outputs to about TARGET.
    The CLI's self-send splits both sides into -o outputs, so it adds about twice -o (5 outputs
    with -o 11 came to 27 on 2026-10-31)."""
    change = max(1, (TARGET - have) // 2)
    return ["send", "-m", "self", "-d", "default", "-o", str(change), SPLIT_AMOUNT]


class P:
    """p.py one-shots through the shared P service (p_service), which runs them beside P's owner_api and
    listener; no lock of its own. The password stays in the service's p.py environment."""

    def __init__(self, tool, pass_file, lock_file=None, pass_line=1, timeout=300):
        self.tool, self.pass_file, self.timeout, self.pass_line = tool, pass_file, timeout, pass_line
        from . import p_service
        self.svc = p_service
        self.client = p_service.Client(p_service.env_paths(dict(
            os.environ, REL_P_TOOL=tool, REL_P_PASS_FILE=pass_file, REL_P_PASS_LINE=str(pass_line))))

    @classmethod
    def from_env(cls, env=os.environ):
        """P as the trust drivers find it (REL_P_TOOL, REL_P_PASS_FILE, REL_P_PASS_LINE)."""
        home = os.path.expanduser
        return cls(env.get("REL_P_TOOL") or home("/tmp/epic-build/interop/epicpay/p.py"),
                   env.get("REL_P_PASS_FILE") or home("~/.config/btlabs/p-pass-candidates"),
                   None, int(env.get("REL_P_PASS_LINE") or "1"))

    def ready(self):
        return os.path.exists(self.tool) and bool(self.svc.password(self.client.cfg))

    def run(self, args):
        why = self.client.ensure()
        if why:
            return 2, why
        r = self.client.call("cli", args=args, timeout=self.timeout + 60)
        return r.get("rc", 1), r.get("out") or r.get("note", "")


def ensure(p, say):
    """Counts P's spendable outputs and splits below LOW. (ok, note)."""
    rc, out = p.run(["outputs"])
    have = spendable(out)
    if rc != 0 or have is None:
        # One read in three failed on 2026-11-02 with the next one fine (P busy with another call);
        # one more try before a whole release stops at G1.
        time.sleep(10)
        rc, out = p.run(["outputs"])
        have = spendable(out)
    if rc != 0 or have is None:
        return False, "P's outputs could not be read twice (p.py outputs exit %d)" % rc
    if have >= LOW:
        return True, "P has %d spendable outputs (at least %d)" % (have, LOW)
    args = split_args(have)
    say("P has %d spendable outputs (under %d): splitting with %s" % (have, LOW, " ".join(args[:-1])))
    rc, out = p.run(args)
    if rc != 0 or not re.search(r"Command 'send' completed", out) or re.search(r"\bERROR\b", out):
        tail = [l for l in out.splitlines() if "ERROR" in l][-1:] or ["no 'send completed'"]
        return False, "P's split failed: %s" % tail[0][-200:]
    return True, "P had %d spendable outputs: split into about %d (spendable after one block)" % (
        have, have + 2 * int(args[6]))
