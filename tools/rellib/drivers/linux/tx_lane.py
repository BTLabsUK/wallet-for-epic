#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""TX-1: the Linux payments lane. Two wallets on the candidate, A and B (lane seeds linux-tx-a and
linux-tx-b), each in its own sandbox, pay each other on mainnet by every method, and every coin goes
back to P (the funder) in the same run. Called by ../trust-tx-linux.sh with the REL_* environment.

Phases (each starts by reading where things are, and skips what is done):
  prepare       both sandboxes up, the candidate extracted in each, the file-chooser stand-ins
  restore-a/-b  each lane seed restored through the candidate's screens (Deep end view)
  addresses     A's Epicbox address; B's Epicbox, Link · HTTP, Link · Tor addresses and File on
  sweep-start   what a run before left in A or B goes back to P
  fund          P pays A what the remaining payments need (core/txchecks.py fund_plan)
  pay-<method>  A pays B 0.01 by epicbox, http, tor, file; tx_<method>_ok from both wallets' data
  sweep-end     B and A send everything to P; returned_ok
Later lanes (PAIR-1, LINK-1) add phases: PHASES and _pays.

REL_FUNDS=0: no fund and no payments (sweep-start and sweep-end still return leftovers); no check is
required. REL_TRUST_UNTIL=<phase> stops after it (--test runs). REL_TX_METHODS=epicbox,file narrows.

File dialogs: each sandbox runs linux/portal_stub.py, the stand-in file-chooser portal on the
sandbox's own bus; Receive › Transaction files › Open is answered with a file in that sandbox's
inbox (HOME/inbox), never one outside it.

The phrases and passwords go to the test DB (wallet.put); trust.log and proof.json name neither, and
the end-of-lane scan looks for both phrases in REL_OUT."""
import json
import os
import shutil
import signal
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, HERE)

from core import lane as core_lane  # noqa: E402
from core import lane_seed as ls  # noqa: E402
from core import record  # noqa: E402
from core import txchecks as tx  # noqa: E402
from core.desktop import Desktop  # noqa: E402
from core.driver import Driver  # noqa: E402
from core.faults import HarnessFault, ProductFault  # noqa: E402
from core.labels import Labels  # noqa: E402
from core.lane import Lane, Platform  # noqa: E402
from core.payments import METHODS, Payments, file_for  # noqa: E402
from linux_platform import LinuxPlatform  # noqa: E402
from p_funder import P  # noqa: E402
import portal_stub  # noqa: E402

LANE = "linux-tx"
SEEDS = {"a": "linux-tx-a", "b": "linux-tx-b"}
PHASES = ("prepare", "restore-a", "restore-b", "addresses", "sweep-start", "fund",
          "pay-epicbox", "pay-http", "pay-tor", "pay-file", "sweep-end")


class PairPlatform(Platform):
    """Two LinuxPlatforms on the candidate, one per wallet, as the one platform core/lane.py runs."""
    name = "linux"
    family = "desktop"
    update_method = "none: two wallets on the candidate (the payments lane)"

    def __init__(self, out, log):
        e = os.environ
        self.variant = e.get("REL_VARIANT") or "tor"
        root = os.path.join(e.get("REL_WORK") or os.path.join(os.path.expanduser("~"), ".cache", "rel-trust-linux"),
                            "tx-%s-%s-%s" % (self.variant, e.get("REL_CANDIDATE_VERSION", "?"), time.strftime("%Y%m%d-%H%M%S")))
        self.root = root
        self.pair = {}
        for k in ("a", "b"):
            p = LinuxPlatform(out, lambda s, k=k: log("%s: %s" % (k.upper(), s)))
            p.create = True  # the candidate alone
            p.work = os.path.join(root, k)
            p.sb = os.path.join(p.work, "sandbox")
            self.pair[k] = p
        self.hermetic = None
        self.node = self.relay = None

    def prepare(self):
        for p in self.pair.values():
            p.prepare()
        a = self.pair["a"]
        self.hermetic, self.node, self.relay = a.hermetic, a.node, a.relay
        for p in self.pair.values():
            os.makedirs(inbox(p), exist_ok=True)

    def recover(self):
        for k, p in self.pair.items():
            if not (p.surface and p.surface.display_alive()) or (p.running and not p.alive()):
                p.recover()

    def digest(self, tag, secrets):
        raise HarnessFault("digest", "the pair has no one wallet: read A or B (Wallet.digest)")

    def logs(self):
        out = {}
        for k, p in self.pair.items():
            out.update({"%s-%s" % (k, n): v for n, v in (p.logs() or {}).items()})
        return out

    def shutdown(self):
        for p in self.pair.values():
            try:
                p.shutdown()
            except Exception as e:  # noqa: BLE001 — the other one still goes
                p.log("shutdown: %s" % e)


def inbox(p):
    return os.path.join(p.sb, "home", "inbox")


class Wallet:
    """One of the pair: its platform, seed, recipe (ui), payments recipes, secrets."""

    def __init__(self, lane, key, plat):
        self.lane, self.key, self.p = lane, key, plat
        self.seed = ls.LaneSeed(SEEDS[key])
        self.ui = self.pay = None
        self.secrets = {}

    def digest(self, tag):
        d = self.p.digest(tag, self.secrets)
        try:
            b = (d or {}).get("balance") or {}
            if b:
                record.emit("wallet.snapshot", name=self.seed.lane, role="lane", origin="digest %s (%s)" % (tag, self.lane.phase),
                            spendable=ls.epic(b.get("spendable")), total=ls.epic(b.get("total")),
                            unconfirmed=ls.epic(b.get("unconfirmed")), locked=ls.epic(b.get("locked")),
                            txs=json.dumps(d.get("txs") or [], default=str))
        except Exception as e:  # noqa: BLE001 — evidence only
            self.lane.log("wallet snapshot not sent: %s" % e)
        return d

    def choose(self, path):
        portal_stub.ensure(self.p.sb)  # the app's restart takes the stand-in with it
        portal_stub.answer(self.p.sb, path)


class TxLane(Lane):
    PHASES = PHASES

    def __init__(self, plat, recipe_for, *, out, log, required, funds, p):
        super().__init__(plat, recipe_for, tx, out=out, log=log, required=required, funds=funds, p=p)
        self.mode = "seed"
        self.w = {k: Wallet(self, k, plat.pair[k]) for k in ("a", "b")}
        self.ledger = tx.Ledger()
        self.base = {}
        self.pending = {}  # method -> (A's, B's data) just before its send (txchecks.pay)
        self.address = {"a": {}, "b": {}}
        want = [m.strip() for m in (os.environ.get("REL_TX_METHODS") or "").split(",") if m.strip()]
        bad = [m for m in want if m not in METHODS]
        if bad:
            raise HarnessFault("start", "REL_TX_METHODS: unknown %s (known: %s)" % (", ".join(bad), " ".join(METHODS)))
        self.methods = want or list(METHODS)
        self.p_before = self.p_after = None

    # ---- the lane

    def main(self):
        try:
            return self._run(self._main)
        finally:
            for w in self.w.values():
                w.seed.unlock()

    def _main(self):
        for w in self.w.values():
            w.seed.lock()
        self.needles = ls.Needles([w.seed.phrase() for w in self.w.values()])
        self.p_before = self._p_balance()
        self.run_phase("prepare", self.p.prepare)
        self._hermetic()
        for k in ("a", "b"):
            self.run_phase("restore-" + k, lambda k=k: self._restore_one(self.w[k]))
        self.run_phase("addresses", self._addresses)
        self._sweep_phase("sweep-start")
        if not self.funds:
            for name in ("fund",) + tuple("pay-" + m for m in self.methods):
                self.skip_phase(name, "REL_FUNDS=0: no coins from P")
        else:
            try:
                self._fund_and_pay()
            except core_lane._Stop:
                raise  # REL_TRUST_UNTIL: what A holds goes back in the next run's sweep-start
            except BaseException:
                try:  # the coins go back whatever went wrong; the first fault is the lane's
                    self._sweep_end()
                except BaseException as e:  # noqa: BLE001
                    self.log("sweep-end after the fault: %s" % e)
                raise
            self._sweep_end()
        self.p_after = self._p_balance()
        return 0

    def _fund_and_pay(self):
        a0 = tx.digest(self, self.w["a"], "fund")
        self.base.setdefault("a", a0)
        left = tx.remaining(self)
        plan = tx.fund_plan(tx.held(a0), len(left))
        if plan:
            self.run_phase("fund", lambda: tx.fund(self, left))
        else:
            self.skip_phase("fund", "A's %s EPIC covers %d payments" % (tx.num(tx.held(a0)), len(left)))
        for m in self.methods:
            done = tx.paid_already(self.base["a"], tx.digest(self, self.w["a"], "pay-" + m), m)
            if done:
                self.skip_phase("pay-" + m, "A paid B by %s this run (%s)" % (m, done["state"]))
                continue
            self.run_phase("pay-" + m, lambda m=m: tx.pay(self, m, self._sender(m)))

    def _sweep_end(self):
        try:
            self._sweep_phase("sweep-end", ("b", "a"))
        except core_lane.Fault as e:
            self.log("sweep-end: %s; the next run's sweep-start returns what is left" % e.line())
            raise
        finally:
            try:
                tx.returned(self)
            except Exception as e:  # noqa: BLE001 — evidence; the fault above is the lane's
                self.log("returned_ok not read: %s" % e)

    def _sweep_phase(self, name, keys=("a", "b")):
        held = {k: tx.digest(self, self.w[k], name) for k in keys}
        if all(((d.get("balance") or {}).get("total") or 0) < tx.nano(tx.DUST) for d in held.values()):
            self.skip_phase(name, "%s hold less than %s EPIC (wallet data)" % (" and ".join(k.upper() for k in keys), tx.DUST))
            return
        self.run_phase(name, lambda: tx.sweep(self, keys, name))

    def _restore_one(self, w):
        if w.ui is not None and w.secrets.get("password"):
            w.ui.open_wallet(w.secrets)
            return
        surface = w.p.start("candidate")
        self.rec.build = os.environ.get("REL_CANDIDATE_VERSION", "candidate")
        w.ui = self.recipe_for(self, "candidate", surface)
        w.pay = Payments(w.ui, w.choose, self.log)
        birth = w.seed.birth()
        if birth.get("height") is None:
            raise HarnessFault("restore", "lane seed %s has no birth height (lane_seed.py birth %s)" % (w.seed.lane, w.seed.lane))
        self.log("restore %s: lane seed %s from height %d" % (w.key.upper(), w.seed.lane, birth["height"]))
        got = w.ui.restore_wallet(w.seed.phrase(), birth) or {}
        w.secrets.update({k: got[k] for k in ("pin", "password") if got.get(k)})
        w.secrets["phrase"] = w.seed.phrase()
        record.emit("wallet.put", name=w.seed.lane, role="lane", platform="linux", lane=LANE, phrase=w.secrets["phrase"],
                    password=w.secrets.get("password") or "", origin="the lane seed restored on the candidate (TX lane)")
        w.ui._view_deep_end()
        portal_stub.ensure(w.p.sb)
        self.ui = w.ui  # the fault bundle reads the screen of the wallet that ran last

    def _addresses(self):
        a, b = self.w["a"], self.w["b"]
        # A: File on to pay with a file (the Send page offers it only then)
        for w, methods in ((a, ("epicbox",) + (("file",) if "file" in self.methods else ())), (b, self.methods)):
            for m in methods:
                if m in self.address[w.key]:
                    continue
                self.ui = w.ui
                addr = w.pay.enable_receive(m)
                self.address[w.key][m] = addr
                if addr:
                    record.emit("wallet.address", name=w.seed.lane, role="lane", kind=m, address=addr)
        self.details["addresses"] = {k: sorted(v) for k, v in self.address.items()}

    # ---- the sends

    def _sender(self, method):
        a, b = self.w["a"], self.w["b"]

        def send(a0, b0):
            self.awake()
            self.ui = a.ui
            if method == "file":
                return self._file_round_trip(a0)
            to = self.address["b"][method]
            if method == "epicbox":
                to = tx.pay_to(to, getattr(b.p, "relay", None))
            return a.pay.send(method, to, format(tx.AMOUNT, "f"))
        return send

    def _file_round_trip(self, a0):
        """A makes the file, B opens it (signs, writes the response beside it), A opens the response
        (finalizes and posts). Each file is carried into the other sandbox's inbox."""
        a, b = self.w["a"], self.w["b"]
        t0 = time.time()
        ok, why = a.pay.send_file(format(tx.AMOUNT, "f"))
        if not ok:
            return ok, why
        d = tx.wait_for(self, a, "file made", lambda x: any(t.get("transport") == "file" for t in tx.new_txs(a0, x, "outgoing")), 120)
        slate = [t for t in tx.new_txs(a0, d, "outgoing") if t.get("transport") == "file"][-1].get("slate")
        home = os.path.join(a.p.sb, "home")
        made = file_for([os.path.join(home, "Downloads"), os.path.join(home, "Documents"), home], slate)
        if not made or os.path.getmtime(made) < t0 - 5:
            return False, "A's transaction file for slate %s is not in its Downloads or Documents" % (slate or "?")[:8]
        sent = shutil.copy2(made, os.path.join(inbox(b.p), os.path.basename(made)))
        self.ui = b.ui
        line = b.pay.open_file(sent) or ""
        if not line.lower().startswith("signed"):
            return False, "B opened %s: %s" % (os.path.basename(made), line or "no result line")
        resp = file_for([inbox(b.p)], slate, ".response")
        if not resp:
            return False, "B signed the file, its response file is not beside it"
        back = shutil.copy2(resp, os.path.join(inbox(a.p), os.path.basename(resp)))
        self.ui = a.ui
        line = a.pay.open_file(back) or ""
        if "posted" not in line.lower() or "not posted" in line.lower():
            return False, "A opened %s: %s" % (os.path.basename(resp), line or "no result line")
        self.details["file_round_trip"] = "A made %s, B: signed, A: %s" % (os.path.basename(made), line)
        return True, "file round trip: %s" % line

    def history_label(self, method):
        """The Method A's Activity detail names for the newest sent 0.01 (None when it cannot be read)."""
        a = self.w["a"]
        self.ui = a.ui
        try:
            return a.pay.history_method(format(tx.AMOUNT, "f"), False)
        except (HarnessFault, ProductFault) as e:
            self.log("pay-%s: A's Activity detail not read: %s" % (method, e.what))
            return None

    def awake(self):
        """Both wallets unlocked: a locked wallet neither listens nor sends (auto-lock while waiting)."""
        for w in self.w.values():
            if w.ui is not None:
                w.ui.ensure_unlocked()

    # ---- the core's hooks

    def _phase(self, name, fn):
        """A harness that went is rebuilt and the phase run again once, with both wallets open again."""
        while True:
            try:
                return fn()
            except core_lane.HarnessGone as e:
                if name in self.retried:
                    raise
                self.retried.add(name)
                self.log("phase %s: %s; rebuilding and running the phase again" % (name, e.line()))
                self.details.setdefault("harness_recovered", []).append("%s: %s" % (name, e.what))
                self.p.recover()
                for w in self.w.values():
                    if w.ui is not None and w.secrets.get("password"):
                        w.ui.open_wallet(w.secrets)
                        portal_stub.ensure(w.p.sb)

    def _wallet(self):
        return LANE, "lane"

    def _resume_point(self):
        return None

    def _save_resume_secrets(self):
        return None

    def _p_balance(self):
        try:
            with self.funder.exchange("P's balance"):
                return self.funder.info()
        except Exception as e:  # noqa: BLE001 — evidence only
            self.log("P's balance not read: %s" % e)
            return None

    def proof(self, extra=None):
        self.details["money"] = self.ledger.doc(self.p_before, self.p_after)
        return super().proof(dict(extra or {}, lane=LANE, methods=self.methods))


def main():
    e = os.environ
    out = os.path.abspath(e.get("REL_OUT") or ".")
    os.makedirs(out, exist_ok=True)

    def log(s):
        line = "%s %s" % (time.strftime("%H:%M:%S"), s)
        print(line, flush=True)
        with open(os.path.join(out, "trust.log"), "a") as f:
            f.write(line + "\n")

    funds = e.get("REL_FUNDS", "1") == "1"
    plat = PairPlatform(out, log)
    funder = P(e.get("REL_P_TOOL") or os.path.expanduser("/tmp/epic-build/interop/epicpay/p.py"),
               e.get("REL_P_PASS_FILE") or os.path.expanduser("~/.config/btlabs/p-pass-candidates"),
               int(e.get("REL_P_PASS_LINE") or "1"),
               e.get("REL_P_LOCK") or os.path.expanduser("/opt/epic/qa-funder/.rel-lock"), out, log)

    def recipe_for(lane, which, surface):
        d = Driver(surface, Labels.for_build(which), lane.rec, out=lane.out, log=lane.log)
        return Desktop(d, which, lane.log)

    def stopped(sig, _frame):  # a runner's timeout: the sandboxes and stand-ins still go
        raise HarnessFault(lane.phase or "start", "the lane was stopped (signal %d)" % sig)
    given = [c.strip() for c in (e.get("REL_CHECKS") or "").split(",") if c.strip()]
    lane = TxLane(plat, recipe_for, out=out, log=log, funds=funds, p=funder,
                  required=given or ([("tx_%s_ok" % m) for m in (e.get("REL_TX_METHODS") or ",".join(METHODS)).split(",")
                                      if m.strip()] + ["returned_ok"] if funds else []))
    signal.signal(signal.SIGTERM, stopped)
    return lane.main()


if __name__ == "__main__":
    sys.exit(main())
