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
  pair-invite   PAIR-1: A's invite copied and pasted on B, the four words read on both and confirmed:
                Verified on both contact pages (pair_invite_ok)
  pair-remove   B removes the pairing: Pairing ended on A
  pair-proven   B pairs A again by a request, A's address proven by this run's Epicbox payment:
                Verified on both without words (pair_proven_ok)
  pair-invoice  A asks B for 0.01 (an invoice); B approves it; checked in both wallets' data (pair_invoice_ok)
  pair-end      A removes the pairing: Pairing ended on B (pair_end_ok)
  sweep-end     B and A send everything to P
  link-up       LINK-1: A2, a third sandbox, restores A's phrase (named Lane A2) and is linked to A: A's
                Settings › Linked devices › Link a device › Copy invite, pasted on A2's Paste invite (link_ok)
  link-pay      P pays A's address 0.01: both installs listen on it; one answer takes, the other's is
                dropped (wallet data), and both show the receipt in Activity (link_pay_ok)
  link-end      A removes A2: A offers Link a device again, A2 reads it was removed (link_end_ok); the
                install that answered sends the 0.01 back to P; A2 is stopped and its folder removed.
  sweep-last    after a failed phase: what it left in A or B goes to P. returned_ok last of all.
A failed phase does not stop the others (core/lane.py try_phase): pay-http failed, pay-tor still runs;
phases that need it skip and say why (no fund: no payments; no pairing: no invoice; no link: no link-pay).
An A2 a crashed run left (running or not) is stopped and removed in prepare, before any payment: it holds
A's phrase and would answer A's payments.

REL_FUNDS=0: no fund and no payments (sweep-start and sweep-end still return leftovers); pair-invite,
pair-end, link-up and link-end run, link-pay, pair-remove, pair-proven and pair-invoice skip (they need the Epicbox payment and coins); no
check is required. REL_TRUST_UNTIL=<phase> stops after it (--test runs). REL_TX_METHODS=epicbox,file narrows.

REL_TX_PART=payments|pairing|linking runs one part alone, for one step of the release pipeline, so a
fault reruns that part only. Each part starts from one state of both wallets (core/state.py, kept once
per build): state-load puts it back, or the first part restores the seeds and, once sweep-start left both
wallets empty, keeps it (state-save, reopen). Each returns its coins to P in the same run.
  payments  fund, pay-<method>, sweep-end
  pairing   fund and pay-epicbox (the proven address), fund-b (what B pays the invoice with), the pair
            phases, sweep-end
  linking   the link phases, sweep-last
The state knows only what the wallets held when it was kept. A run that did not bring all coins back moves
it aside, and the next run restores from the phrases: that finds them all.

File dialogs: each sandbox runs linux/portal_stub.py, the stand-in file-chooser portal on the
sandbox's own bus; Receive › Transaction files › Open is answered with a file in that sandbox's
inbox (HOME/inbox), never one outside it.

The phrases and passwords go to the test DB (wallet.put); trust.log and proof.json name neither, and
the end-of-lane scan looks for both phrases in REL_OUT."""
import hashlib
import json
import re
import os
import shutil
import signal
import socket
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, HERE)

from core import lane as core_lane  # noqa: E402
from core import lane_seed as ls  # noqa: E402
from core import record  # noqa: E402
from core import state as st  # noqa: E402
from core import txchecks as tx  # noqa: E402
from core import walletdata as wd  # noqa: E402
from core.desktop import Desktop  # noqa: E402
from core.driver import Driver  # noqa: E402
from core.faults import HarnessFault, LaneStopped, ProductFault  # noqa: E402
from core import linking as lk  # noqa: E402
from core.labels import Labels  # noqa: E402
from core.lane import Lane, Platform  # noqa: E402
from core.linking import Linking  # noqa: E402
from core.pairing import Pairing  # noqa: E402
from core.payments import METHODS, Payments, file_for  # noqa: E402
import clipboard  # noqa: E402
from files import data_root  # noqa: E402
import sandbox  # noqa: E402
from linux_platform import LinuxPlatform  # noqa: E402
from p_funder import P  # noqa: E402
import portal_stub  # noqa: E402

LANE = "linux-tx"
SEEDS = {"a": "linux-tx-a", "b": "linux-tx-b", "a2": "linux-tx-a"}  # A2: A's phrase on a second install
PHASES = ("prepare", "state-load", "restore-a", "restore-b", "addresses", "sweep-start", "state-save", "reopen", "fund", "fund-b",
          "pay-epicbox", "pay-http", "pay-tor", "pay-file",
          "pair-invite", "pair-remove", "pair-proven", "pair-invoice", "pair-end", "sweep-end",
          "link-up", "link-pay", "link-end", "sweep-last")
PAIR_NAME = {"a": "Lane A", "b": "Lane B"}  # the name each is seen as, and its contact's name on the other
PAIR_CHECKS = ("pair_invite_ok", "pair_proven_ok", "pair_invoice_ok", "pair_end_ok")
INVOICE = "0.01"  # pair-invoice: what A asks B for (B pays it)
LINK_CHECKS = ("link_ok", "link_pay_ok", "link_end_ok")
LINK_NAME = "Lane A2"  # A2's device name, as A lists it
LINK_AMOUNT = tx.AMOUNT  # link-pay: P -> A's address
LINK_DROP_S = 600  # the losing install's own answer dropped within this after the winner's confirmed
PARTS = ("payments", "pairing", "linking")  # the pipeline's lane-<part>-linux steps


def methods_for(part, want):
    """The payments a run makes: pairing needs the one its proven address rests on, linking none."""
    return {"pairing": ["epicbox"], "linking": []}.get(part, want)


def required_for(part, methods):
    """The checks that decide a funded run: the whole lane's or a part's."""
    pays = ["tx_%s_ok" % m for m in methods]
    if part == "payments":
        return pays + ["returned_ok"]
    if part == "pairing":
        return list(PAIR_CHECKS) + ["returned_ok"]
    if part == "linking":
        return list(LINK_CHECKS) + ["returned_ok"]
    pairs = [c for c in PAIR_CHECKS if "epicbox" in methods or c in ("pair_invite_ok", "pair_end_ok")]
    return pays + pairs + list(LINK_CHECKS) + ["returned_ok"]


class PairPlatform(Platform):
    """Two LinuxPlatforms on the candidate, one per wallet, as the one platform core/lane.py runs."""
    name = "linux"
    family = "desktop"
    update_method = "none: two wallets on the candidate (the payments lane)"

    def __init__(self, out, log):
        e = os.environ
        self.out, self.log = out, log
        self.variant = e.get("REL_VARIANT") or "tor"
        root = os.path.join(e.get("REL_WORK") or os.path.join(os.path.expanduser("~"), ".cache", "rel-trust-linux"),
                            "tx-%s-%s-%s" % (self.variant, e.get("REL_CANDIDATE_VERSION", "?"), time.strftime("%Y%m%d-%H%M%S")))
        self.root = root
        self.pair = {}
        for k in ("a", "b"):
            self.pair[k] = self._one(k)
        self.hermetic = None
        self.node = self.relay = None

    def _one(self, k):
        p = LinuxPlatform(self.out, lambda s, k=k: self.log("%s: %s" % (k.upper(), s)))
        p.create = True  # the candidate alone
        p.work = os.path.join(self.root, k)
        p.sb = os.path.join(p.work, "sandbox")
        return p

    def prepare(self):
        self.clean_a2()
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

    def alive(self):
        """Both wallets' apps and displays up (A2 comes and goes)."""
        return all(p.surface and p.surface.display_alive() and p.alive() for k, p in self.pair.items() if k != "a2")

    def digest(self, tag, secrets):
        raise HarnessFault("digest", "the pair has no one wallet: read A or B (Wallet.digest)")

    # ---- the parts' saved state (core/state.py): both sandboxes, for this build

    def build(self):
        e = os.environ
        p = self.pair["a"]
        h = hashlib.sha256()
        with open(p.appimage(e.get("REL_CANDIDATE_DIR", ""), e.get("REL_CANDIDATE_VERSION", "")), "rb") as f:
            for chunk in iter(lambda: f.read(1 << 20), b""):
                h.update(chunk)
        return h.hexdigest()

    def fits_build(self, meta):
        """(ok, why): a state holds this build's app data, and the stand-in ports its settings name are free."""
        if meta.get("build") != self.build():
            return False, "saved on another build"
        for k, ports in (meta.get("ports") or {}).items():
            for kind, port in ports.items():
                if not port_free(port):
                    return False, "%s's %s stand-in port %d (in the wallet's settings) is taken" % (k.upper(), kind, port)
        return True, ""

    def use_ports(self, meta):
        for k, ports in (meta.get("ports") or {}).items():
            self.pair[k].ports = dict(ports)

    def state_meta(self):
        return {"build": self.build(), "ports": {k: dict(self.pair[k].ports) for k in ("a", "b")}}

    def save_state(self, folder):
        for k in ("a", "b"):
            d = os.path.join(folder, k)
            os.makedirs(d, mode=0o700)
            self.pair[k].save_state(d)

    def restore_state(self, folder):
        for k in ("a", "b"):
            self.pair[k].restore_state(os.path.join(folder, k))
            os.makedirs(inbox(self.pair[k]), exist_ok=True)

    # ---- A2 (LINK-1): a third sandbox, only while the link phases run

    def add_a2(self):
        p = self.pair.get("a2")
        if p is None:
            p = self.pair["a2"] = self._one("a2")
            p.prepare()
            os.makedirs(inbox(p), exist_ok=True)
        return p

    def drop_a2(self):
        """A2 stopped and its folder (A's wallet data on a second install) removed."""
        p = self.pair.pop("a2", None)
        if p is None:
            return
        try:
            p.shutdown()
        finally:
            logs = os.path.join(p.work, "sandbox", "home", ".epic_cash_desktop", "logs")
            if os.path.isdir(logs):  # the wallet goes, what it read and said stays for the report
                shutil.copytree(logs, os.path.join(self.out, "a2-logs"), dirs_exist_ok=True)
            shutil.rmtree(p.work, ignore_errors=True)
            self.log("A2: removed %s" % p.work)

    def clean_a2(self):
        """Every A2 an earlier run of this lane left under the work folder: stopped (its app, keyring, bus
        and display, found by the sandbox's runtime folder) and removed. Only <work>/tx-*/a2 folders."""
        top = os.path.dirname(self.root)
        try:
            runs = sorted(os.listdir(top))
        except OSError:
            return
        for n in runs:
            a2 = os.path.join(top, n, "a2")
            if not n.startswith("tx-") or not os.path.isdir(a2):
                continue
            sb = os.path.join(a2, "sandbox")
            try:
                if os.path.isdir(sb):
                    sandbox.stop(sb)
            except (Exception, SystemExit) as e:  # noqa: BLE001 — removed all the same
                self.log("A2 left by a run before: stop: %s" % e)
            shutil.rmtree(a2, ignore_errors=True)
            self.log("A2 left by a run before: stopped and removed %s" % a2)

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


def port_free(port):
    with socket.socket() as so:
        so.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            so.bind(("127.0.0.1", int(port)))
        except OSError:
            return False
    return True


def inbox(p):
    return os.path.join(p.sb, "home", "inbox")


def short(address):
    a, _, at = (address or "").partition("@")
    return "%s…%s%s" % (a[:8], a[-6:], "@" + at if at else "") if len(a) > 16 else address


class Wallet:
    """One of the pair: its platform, seed, recipe (ui), payments recipes, secrets."""

    def __init__(self, lane, key, plat):
        self.lane, self.key, self.p = lane, key, plat
        self.seed = ls.LaneSeed(SEEDS[key])
        self.ui = self.pay = self.pair = self.link = None
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

    def clip(self, text=None):
        """The app's clipboard on this sandbox's display: read (text None) or set."""
        return clipboard.read(self.p.sb) if text is None else clipboard.write(self.p.sb, text)

    def epicbox(self, address):
        """[address] as other wallets reach it: at settings.toml's first Epicbox server, the one the app
        listens on (Receive shows the address without it). As read when it names a server already."""
        if not address or "@" in address:
            return address
        try:
            with open(os.path.join(data_root(self.p.sb), "settings.toml")) as f:
                first = ((wd.toml_servers(f.read()) or {}).get("epicbox") or [None])[0]
        except OSError:
            first = None
        if not first:
            raise HarnessFault("addresses", "%s: settings.toml names no Epicbox server" % self.key.upper())
        return "%s@%s" % (address, first)

    def listening(self):
        """The Epicbox relay the app last subscribed on (its logs/wfe.log), or None."""
        try:
            with open(os.path.join(data_root(self.p.sb), "logs", "wfe.log"), errors="replace") as f:
                hits = re.findall(r"epicbox subscribed\b.*?\brelay=(\S+)", f.read())
        except OSError:
            return None
        return hits[-1] if hits else None

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
        self.part = os.environ.get("REL_TX_PART") or None
        self.state = None  # the saved state this run started from or made (a part)
        want = [m.strip() for m in (os.environ.get("REL_TX_METHODS") or "").split(",") if m.strip()]
        bad = [m for m in want if m not in METHODS]
        if bad:
            raise HarnessFault("start", "REL_TX_METHODS: unknown %s (known: %s)" % (", ".join(bad), " ".join(METHODS)))
        self.methods = methods_for(self.part, want or list(METHODS))
        self.p_before = self.p_after = None
        self.link_answered = None  # link-pay: the install whose answer took ("a" | "a2")

    # ---- the lane

    def main(self):
        try:
            return self._run(self._refuse if self.part not in (None,) + PARTS else self._main)
        finally:
            for w in self.w.values():
                w.seed.unlock()  # A2 shares A's seed (and its lock); unlocking twice is nothing

    def _refuse(self):
        raise HarnessFault("start", "REL_TX_PART: unknown %s (known: %s)" % (self.part, " ".join(PARTS)))

    def _main(self):
        try:
            return self._lane()
        finally:  # P's balance after, whatever stopped the lane (proof.json's money)
            self.p_after = self._p_balance()
            if self.state and not self.results.get("returned_ok"):
                self.log("coins may be left outside the saved state: the next run restores from the phrases")
                st.retire(self.state, self.log)

    def _lane(self):
        for w in self.w.values():
            w.seed.lock()
        self.needles = ls.Needles([w.seed.phrase() for w in self.w.values()])
        self.p_before = self._p_balance()
        saved = self._saved()
        if saved:
            self.p.use_ports(saved.meta)
        self.run_phase("prepare", self.p.prepare)
        self._hermetic()
        self._start(saved)
        try:
            if self.part != "linking":
                self._fund_and_pay()
            if self.part in (None, "pairing"):
                self._pairing()
            if self.part != "linking":
                self.soft("sweep-end", self._sweep_end)
            if self.part in (None, "linking"):
                self._linking()
            if self.kept or self.part == "linking":  # what a failed phase, or link-pay, left behind
                self.soft("sweep-last", lambda: self._sweep_end("sweep-last"))
        except core_lane._Stop:
            raise  # REL_TRUST_UNTIL: what A holds goes back in the next run's sweep-start
        except BaseException:
            at = self.phase
            try:  # the coins go back whatever went wrong; the first fault is the lane's
                self._sweep_end()
            except BaseException as e:  # noqa: BLE001
                self.log("sweep-end after the fault: %s" % e)
            self._returned()
            self.phase = at
            raise
        self._returned()
        return 0

    def _saved(self):
        """A part's saved state of this build, or None: read before prepare, whose stand-ins take its ports."""
        if not self.part:
            return None
        return st.pick(LANE, self.p.variant, os.environ.get("REL_CANDIDATE_VERSION"), self.p.fits_build, self.log)

    def _start(self, saved):
        """Both wallets open on the candidate, their addresses read, what runs before left sent to P."""
        ok, why = st.hermetic_fits(saved.meta, self.p) if saved else (False, "")
        if saved and not ok:
            self.log("saved state %s not used: %s" % (saved.folder, why))
        if ok:
            self.state = saved.folder
            self.run_phase("state-load", lambda: self._load_state(saved))
        else:
            for k in ("a", "b"):
                self.run_phase("restore-" + k, lambda k=k: self._restore_one(self.w[k]))
        self.run_phase("addresses", self._addresses)
        self.soft("sweep-start", lambda: self._sweep_phase("sweep-start"))
        if self.part and not ok and os.environ.get("REL_TRUST_SAVE_STATE", "1") != "0":
            self._keep_state()

    def _load_state(self, saved):
        try:
            got = saved.secrets()
            self.p.restore_state(saved.payload)
            for k in ("a", "b"):
                w = self.w[k]
                w.secrets.update({n: got["%s.%s" % (k, n)] for n in ("password", "pin") if "%s.%s" % (k, n) in got})
                w.secrets["phrase"] = w.seed.phrase()
                self._put(w, "the TX lane's saved state")
                self._open_one(w)
        except core_lane.Fault as e:
            if not e.fatal:
                st.retire(saved.folder, self.log)
                self.state = None
            raise

    def _keep_state(self):
        """Both wallets kept for the parts after this one, only when sweep-start emptied them: coins kept in
        them would read as held after a later run spent them. Saving stops the apps."""
        if any(((tx.digest(self, w, "state-save").get("balance") or {}).get("total") or 0) >= tx.nano(tx.DUST) for w in self.w.values()):
            self.skip_phase("state-save", "A or B still holds coins (wallet data): the next run restores too")
            return
        secrets = {"%s.%s" % (k, n): w.secrets[n] for k, w in self.w.items() for n in ("password", "pin") if w.secrets.get(n)}
        try:
            self.state = self.run_phase("state-save", lambda: st.save(self.p, secrets, None, log=self.log, family=LANE))
        except core_lane.Fault as e:
            if e.fatal:
                raise
            self.log("no saved state: %s" % e.line())
        self.run_phase("reopen", lambda: [self._open_one(self.w[k]) for k in ("a", "b") if not self.w[k].p.running])

    def _fund_and_pay(self):
        """fund, then a payment per method; a payment that fails leaves the others to run."""
        funded = None
        if self.funds:
            why = "A has no Epicbox address (addresses)" if "epicbox" not in self.address["a"] else None
            if why:
                self.skip_phase("fund", why)
            else:
                funded = self.soft("fund", self._fund)
            if funded and self.part == "pairing":
                self.try_phase("fund-b", lambda: tx.fund(self, ["the invoice"], key="b"))
        else:
            self.skip_phase("fund", "REL_FUNDS=0: no coins from P")
        for m in self.methods:
            why = self._cannot_pay(m, funded)
            if why:
                self.skip_phase("pay-" + m, why)
            else:
                self.soft("pay-" + m, lambda m=m: self._pay(m))

    def _fund(self):
        a0 = tx.digest(self, self.w["a"], "fund")
        self.base.setdefault("a", a0)
        left = tx.remaining(self)
        plan = tx.fund_plan(tx.held(a0), len(left))
        if plan:
            self.run_phase("fund", lambda: tx.fund(self, left))
        else:
            self.skip_phase("fund", "A's %s EPIC covers %d payments" % (tx.num(tx.held(a0)), len(left)))
        return True

    def _cannot_pay(self, method, funded):
        if not self.funds:
            return "REL_FUNDS=0: no coins from P"
        if not funded:
            return "needs fund"
        if method not in self.address["b"] or (method == "file" and method not in self.address["a"]):
            return "no %s address (addresses)" % method
        return None

    def _pay(self, m):
        done = tx.paid_already(self.base["a"], tx.digest(self, self.w["a"], "pay-" + m), m)
        if done:
            self.skip_phase("pay-" + m, "A paid B by %s this run (%s)" % (m, done["state"]))
        else:
            self.run_phase("pay-" + m, lambda: tx.pay(self, m, self._sender(m)))

    # ---- PAIR-1: pairing between A and B, through the UI

    def _pairing(self):
        """pair-invite, then (funded) pair-remove, pair-proven and pair-invoice, then pair-end."""
        self.try_phase("pair-invite", self._pair_invite)
        why = None
        if not self.funds:
            why = "REL_FUNDS=0: needs the Epicbox payment and coins"
        elif "epicbox" not in self.methods or not self.results.get("tx_epicbox_ok"):
            why = "needs this run's Epicbox payment (tx_epicbox_ok)"
        elif not self.results.get("pair_invite_ok"):
            why = "needs the pairing from pair-invite"
        for name, fn, needs in (("pair-remove", self._pair_remove, ()), ("pair-proven", self._pair_proven, ("pair-remove",)),
                                ("pair-invoice", self._pair_invoice, ("pair-proven", "fund-b"))):
            lost = next((n for n in needs if self.failed(n)), None)
            if why or lost:
                self.skip_phase(name, why or "needs " + lost)
            else:
                self.try_phase(name, lambda fn=fn: (self.awake(), fn())[1])
        if self.results.get("pair_invite_ok") or self.results.get("pair_proven_ok"):
            self.try_phase("pair-end", lambda: (self.awake(), self._pair_end())[1])
        else:
            self.skip_phase("pair-end", "A and B are not paired")

    def _both_verified(self, check, how, words=True):
        """Verified on both contact pages; after the [words] check also each with the other confirmed too
        (a request to a proven contact has no check, so no verdict comes over: LEPIC verifies it by the address)."""
        self.awake()  # a locked wallet takes no notice of the other's confirmation
        a, b = self.w["a"].pair, self.w["b"].pair
        sides = (("a", "b", a), ("b", "a", b))
        got = {k: p.wait_state(PAIR_NAME[o], "verified") for k, o, p in sides}
        too = {k: not words or (got[k] and p.wait_confirmed(PAIR_NAME[o])) for k, o, p in sides}
        if all(got.values()) and all(too.values()):
            self.ok(check, "%s: Verified on both contact pages%s" % (how, ", each with the other confirmed too" if words else ""))
        else:
            self.fail(check, "%s: A reads %s, B reads %s" % (how, *(
                ("Verified" if got[k] else "%s" % (self.w[k].pair.state(PAIR_NAME[o], refresh=False)[0],))
                + ("" if too[k] else ", the other's confirmation not shown") for k, o in (("a", "b"), ("b", "a")))))

    def _pair_invite(self):
        """A's invite (Copy invite, the clipboard) into B's Have their invite?; the words read on both."""
        self.awake()
        for k in ("a", "b"):
            p = self.w[k].pair
            p.enable(invoices=True)
            p.open_pair()
            p.seen_as(PAIR_NAME[k])
        a, b = self.w["a"].pair, self.w["b"].pair
        b.enter_invite(a.copy_invite(), PAIR_NAME["a"])
        wa = a.words()  # the inviter's check opens on B's answer; B's waits for A's confirmation
        a.confirm_words(allow_invoices=True)
        wb = b.words(timeout=240, contact=PAIR_NAME["a"])  # opens on A's confirmation, which comes by Epicbox
        if wa != wb:  # the words are no secret, but a mismatch is all the proof needs
            self.fail("pair_invite_ok", "the four words differ between A and B")
            return
        b.confirm_words(allow_invoices=True)
        self._both_verified("pair_invite_ok", "invite by text, the same four words on both")

    def _pair_remove(self):
        """B removes the pairing: Pairing ended on A (B's contact keeps no pairing)."""
        self.w["b"].pair.remove(PAIR_NAME["a"])
        if not self.w["a"].pair.wait_state(PAIR_NAME["b"], "ended"):
            self.fail("pair_proven_ok", "B removed the pairing; A does not read Pairing ended")

    def _pair_proven(self):
        """B pairs A again by a request (A's Epicbox address proven by pay-epicbox); A accepts; no words."""
        if not self.w["b"].pair.request(PAIR_NAME["a"]):
            self.fail("pair_proven_ok", "B was not offered a request to A after the Epicbox payment (the invite page opened)")
            return
        why = self.w["a"].pair.accept_request()
        if self.results.get("pair_proven_ok") is False:
            return  # pair-remove's finding stands
        self._both_verified("pair_proven_ok", "a request to a proven contact, no words", words=False)
        if why and self.results.get("pair_proven_ok"):  # the proof names the finding; the phases after it still run
            self.fail("pair_proven_ok", "Verified on both contact pages, but %s" % why)

    def _pair_invoice(self):
        """A asks B for INVOICE EPIC; B approves and pays; checked in both wallets' data."""
        tx.invoice(self, INVOICE, PAIR_NAME)

    def _pair_end(self):
        """A removes the pairing: Pairing ended on B, and on A."""
        a, b = self.w["a"].pair, self.w["b"].pair
        a.remove(PAIR_NAME["b"])
        ended = b.wait_state(PAIR_NAME["a"], "ended")
        mine = a.state(PAIR_NAME["b"])[0]
        if ended and mine in ("ended", "none"):
            self.ok("pair_end_ok", "A removed the pairing: B reads Pairing ended, A reads %s" % mine)
        else:
            self.fail("pair_end_ok", "A removed the pairing: B reads %s, A reads %s" % (b.state(PAIR_NAME["a"])[0], mine))

    def _sweep_end(self, name="sweep-end"):
        for k in ("a", "b"):  # off the contact pages: their own Send and Receive would stand in for nav's
            if not (k in self.w and self.w[k].pair):
                continue
            try:
                self.w[k].pair.contacts_list()
            except Exception as e:  # noqa: BLE001 — the sweep's nav says the rest
                self.log("%s: Contacts list not reached: %s" % (k.upper(), e))
        try:
            self._sweep_phase(name, ("b", "a"))
        except core_lane.Fault as e:
            self.log("%s: %s; the next run's sweep-start returns what is left" % (name, e.line()))
            raise

    def _returned(self):
        try:
            tx.returned(self)
        except Exception as e:  # noqa: BLE001 — evidence; a fault before is the lane's
            self.log("returned_ok not read: %s" % e)

    # ---- LINK-1: A2, a second install of A's phrase, linked to A

    def _linking(self):
        """link-up, link-pay (funded), link-end; A2 goes whatever happens (its coin, if it holds one, to P first)."""
        try:
            self.try_phase("link-up", self._link_up)
            if self.failed("link-up"):
                self.skip_phase("link-pay", "needs the link from link-up")
                self.skip_phase("link-end", "needs the link from link-up")
                return
            if self.funds:
                self.try_phase("link-pay", self._link_pay)
            else:
                self.skip_phase("link-pay", "REL_FUNDS=0: no coins from P")
            self.try_phase("link-end", self._link_end)
        finally:
            self._a2_down()

    def _link_up(self):
        a = self.w["a"]
        if "a2" not in self.w:
            plat = self.p.add_a2()
            w = Wallet(self, "a2", plat)
            w.seed = a.seed  # the same lane seed: its lock is A's
            self.w["a2"] = w
        w = self.w["a2"]
        if w.ui is None or not w.secrets.get("password"):
            self._restore_one(w, put=False)
        addr = w.pay.enable_receive("epicbox")
        same = bool(addr) and addr.split("@")[0] == (self.address["a"].get("epicbox") or "").split("@")[0]
        self.details["link_address"] = "A2's Epicbox address %s A's" % ("is" if same else "is NOT")
        if not same:
            raise HarnessFault("link-up", "A2's Epicbox address is not A's: not the same phrase")
        w.link.rename(LINK_NAME)
        if a.link.linked() and w.link.linked():
            self.ok("link_ok", "A and A2 linked already")
            return
        invite = a.link.show_invite()
        self.ui = w.ui
        w.link.paste_invite(invite)
        got_a2 = w.link.result()
        self.ui = a.ui
        got_a = a.link.result(timeout=120)
        a_lists = a.link.linked()
        a2_lists = w.link.linked()
        why = "A: %s; A2: %s; Linked devices lists the other on A: %s, on A2: %s" % (
            got_a[1], got_a2[1], "yes" if a_lists else "no", "yes" if a2_lists else "no")
        if got_a[0] and got_a2[0] and a_lists and a2_lists:
            self.ok("link_ok", "A's invite pasted on A2: " + why)
        else:
            for x in (a, w):
                x.link.cancel()
            self.fail("link_ok", "A's invite pasted on A2: " + why)

    def _link_pay(self):
        """P pays A's address LINK_AMOUNT; one install's answer takes, the other's is dropped; both list it."""
        if not self.results.get("link_ok"):
            self.fail("link_pay_ok", "A and A2 are not linked (link_ok)")
            return
        keys = ("a", "a2")
        p = tx.checks._p_ready(self)
        self.ledger.charge(LINK_AMOUNT)
        with p.exchange("link: P pays A's address"):
            relay = tx.checks._relay_with_p(self, p)
            to = tx.fund_to(self.address["a"]["epicbox"], relay)
            ok, out = p.send(to, LINK_AMOUNT)
            self.log("P -> A's address %s EPIC: %s (%s)" % (LINK_AMOUNT, "sent" if ok else "FAILED", out))
            if not ok:
                self.ledger.p_sent.pop()
                raise HarnessFault("link-pay", "P send failed: %s" % out)
            self.ledger.p_sent_by(p)
        slate = p.slate
        start = time.time()
        both = set()
        confirmed_at = None
        last = None
        kicked = False
        while True:
            self.awake()
            data = {k: tx.digest(self, self.w[k], "link-pay") for k in keys}
            both |= {k for k in keys if lk.answers(slate, data[k])}
            now = time.time()
            settled = confirmed_at is not None and now - confirmed_at >= LINK_DROP_S
            ok, why, facts = lk.check_answers(slate, data, tx.nano(LINK_AMOUNT), settled=settled)
            if facts.get("confirmed") and confirmed_at is None:
                confirmed_at = now
            if why != last:
                self.log("link-pay: %s" % why)
                last = why
            if ok is not None:
                break
            if not both and now - start >= tx.PAY_WAIT_S["epicbox"]:
                tx.unanswered(self, p, LINK_AMOUNT, "link-pay: neither A nor A2 answered")
                wrong = tx.wrong_relay(to, self.w["a"].listening())
                if wrong:
                    raise HarnessFault("link-pay", "neither A nor A2 answered P's payment: %s" % wrong)
                raise ProductFault("link-pay", "neither A nor A2 answered P's payment in %d s" % tx.PAY_WAIT_S["epicbox"])
            if both and not kicked and now - start >= tx.KICK_AFTER_S and not p.finalized():
                tx.kick(self, p, "link-pay: answered, P has not finalized")
                kicked = True
            if both and not p.finalized() and now - start >= 2 * tx.PAY_WAIT_S["epicbox"]:
                raise tx.InfraFault("link-pay", "A or A2 answered, P did not finalize in %d s (P's node or listener)" %
                                    (2 * tx.PAY_WAIT_S["epicbox"]), sub="p")
            if now - start >= tx.SPEND_WAIT_S + LINK_DROP_S:
                raise ProductFault("link-pay", "not settled in %d s: %s" % (tx.SPEND_WAIT_S + LINK_DROP_S, why))
            time.sleep(tx.POLL_S)
        self.link_answered = facts.get("answered")
        answered = "both installs answered" if len(both) == 2 else "only %s answered" % "".join(both).upper()
        self.details["link_pay"] = {"slate": (slate or "")[:8], "answers": answered, "states": {k: facts.get(k) for k in keys}}
        if not ok:
            self.fail("link_pay_ok", "%s; %s" % (answered, why))
            return
        rows = {}
        for k in keys:
            self.ui = self.w[k].ui
            rows[k] = lk.activity_row(self.w[k].ui, format(LINK_AMOUNT, "f"))
        shown = "; ".join("%s's Activity: %s" % (k.upper(), rows[k] or "no receipt of %s" % LINK_AMOUNT) for k in keys)
        if all(rows.values()):
            self.ok("link_pay_ok", "%s; %s; %s" % (answered, why, shown))
        else:
            self.fail("link_pay_ok", "%s; %s; %s" % (answered, why, shown))

    def _link_end(self):
        """A removes A2: Link a device offered on A again, A2 reads it was removed; the answer's coin back to P."""
        a, w = self.w["a"], self.w["a2"]
        if not (a.link.linked() or w.link.linked()):
            self.fail("link_end_ok", "nothing to remove: neither lists the other")
        else:
            self.ui = a.ui
            gone_a = a.link.remove()
            self.ui = w.ui
            ended, why = w.link.ended()
            a_free = not a.link.linked()
            text = "A removed %s: A offers Link a device again: %s; A2: %s" % (LINK_NAME, "yes" if gone_a and a_free else "no", why)
            (self.ok if gone_a and a_free and ended else self.fail)("link_end_ok", text)
        if self.link_answered:
            tx.sweep(self, (self.link_answered,), "link-end")

    def _a2_down(self):
        """A2's coin (the payment it answered, when link-end did not send it back) to P, then A2 stopped and removed."""
        w = self.w.get("a2")
        if w is None:
            self.p.drop_a2()
            return
        try:
            if w.ui is not None and w.secrets.get("password"):
                d = tx.digest(self, w, "link-back")
                if ((d.get("balance") or {}).get("total") or 0) >= tx.nano(tx.DUST):
                    tx.sweep(self, ("a2",), "link-back")
        except BaseException as e:  # noqa: BLE001 — A2 goes all the same
            self.log("link-back: %s; A's next restore finds what A2 held (the next run's sweep-start)" % e)
        finally:
            del self.w["a2"]
            self.p.drop_a2()

    def _sweep_phase(self, name, keys=("a", "b")):
        held = {k: tx.digest(self, self.w[k], name) for k in keys}
        if all(((d.get("balance") or {}).get("total") or 0) < tx.nano(tx.DUST) for d in held.values()):
            if name == "sweep-start":  # too little to send back, still in the wallets: returned_ok counts it
                for k, d in held.items():
                    tx.carry(self, k, d)
            self.skip_phase(name, "%s hold less than %s EPIC (wallet data)" % (" and ".join(k.upper() for k in keys), tx.DUST))
            return
        self.run_phase(name, lambda: tx.sweep(self, keys, name))

    def _restore_one(self, w, put=True):
        if w.ui is not None and w.secrets.get("password"):
            w.ui.open_wallet(w.secrets)
            return
        self._recipes(w, w.p.start("candidate"))
        birth = w.seed.birth()
        if birth.get("height") is None:
            raise HarnessFault("restore", "lane seed %s has no birth height (lane_seed.py birth %s)" % (w.seed.lane, w.seed.lane))
        self.log("restore %s: lane seed %s from height %d" % (w.key.upper(), w.seed.lane, birth["height"]))
        got = w.ui.restore_wallet(w.seed.phrase(), birth) or {}
        w.secrets.update({k: got[k] for k in ("pin", "password") if got.get(k)})
        w.secrets["phrase"] = w.seed.phrase()
        if put:  # A2 holds A's phrase: its password is its own sandbox's, kept there, not over A's record
            self._put(w, "the lane seed restored on the candidate (TX lane)")
        w.ui._view_deep_end()
        portal_stub.ensure(w.p.sb)
        self.ui = w.ui  # the fault bundle reads the screen of the wallet that ran last

    def _recipes(self, w, surface):
        self.rec.build = os.environ.get("REL_CANDIDATE_VERSION", "candidate")
        w.ui = self.recipe_for(self, "candidate", surface)
        w.pay = Payments(w.ui, w.choose, self.log)
        w.pair = Pairing(w.ui, w.clip, self.log)
        w.link = Linking(w.ui, w.clip, self.log)

    def _open_one(self, w):
        """The candidate started on a wallet that is there already."""
        self._recipes(w, w.p.start("candidate"))
        w.ui.open_wallet(w.secrets)
        w.ui._view_deep_end()
        portal_stub.ensure(w.p.sb)
        self.ui = w.ui

    def _put(self, w, origin):
        record.emit("wallet.put", name=w.seed.lane, role="lane", platform="linux", lane=LANE, phrase=w.secrets["phrase"],
                    password=w.secrets.get("password") or "", origin=origin)

    def _addresses(self):
        """Every address the methods need; one that cannot be read leaves its method out (_cannot_pay)."""
        a, b = self.w["a"], self.w["b"]
        # A: File on to pay with a file (the Send page offers it only then)
        for w, methods in ((a, ("epicbox",) + (("file",) if "file" in self.methods else ())), (b, self.methods)):
            for m in methods:
                if m not in self.address[w.key]:
                    self.soft("addresses", lambda w=w, m=m: self._address(w, m))
        self.details["addresses"] = {k: sorted(v) for k, v in self.address.items()}

    def _address(self, w, m):
        self.ui = w.ui
        addr = w.pay.enable_receive(m)
        if m == "epicbox":
            shown, addr = addr, w.epicbox(addr)
            self.details.setdefault("epicbox_address", {})[w.key] = {"receive_shows": shown, "paid_at": addr}
            if shown != addr:
                self.log("%s: Receive shows the Epicbox address without its server (%s); paid at %s (settings.toml's "
                         "first server)" % (w.key.upper(), short(shown), short(addr)))
        self.address[w.key][m] = addr
        if addr:
            record.emit("wallet.address", name=w.seed.lane, role="lane", kind=m, address=addr)

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
                to = tx.fund_to(to, getattr(b.p, "relay", None))  # as B's app shows it: B listens there
            # an onion: A's Tor as a user leaves it (off); Payments.tor_ready waits for Review
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
            sent = [t for t in tx._txs(tx.digest(self, a, "pay-" + method))
                    if t["direction"] == "outgoing" and tx.sent_of(t) == tx.nano(tx.AMOUNT) and t["state"] != "cancelled"]
            return a.pay.history_method(format(tx.AMOUNT, "f"), False, rows=len(sent))
        except (HarnessFault, ProductFault) as e:
            self.log("pay-%s: A's Activity detail not read: %s" % (method, e.what))
            return None

    def awake(self):
        """Both wallets unlocked, their idle time started again: a locked wallet neither listens nor
        sends (auto-lock while waiting)."""
        for w in self.w.values():
            if w.ui is not None:
                w.ui.ensure_unlocked()
                w.ui.poke()

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
        """P's total: it counts what awaits confirmation, so it reads this run's sweeps at once. Evidence."""
        try:
            with self.funder.exchange("P's balance"):
                return self.funder.total()
        except Exception as e:  # noqa: BLE001 — evidence only
            self.log("P's balance not read: %s" % e)
            return None

    def proof(self, extra=None):
        self.details["money"] = self.ledger.doc(self.p_before, self.p_after)
        return super().proof(dict(extra or {}, lane=LANE, part=self.part, methods=self.methods))


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
        raise LaneStopped(lane.phase or "start", "the lane was stopped (signal %d)" % sig)
    given = [c.strip() for c in (e.get("REL_CHECKS") or "").split(",") if c.strip()]
    part = e.get("REL_TX_PART") or None
    methods = methods_for(part, [m.strip() for m in (e.get("REL_TX_METHODS") or ",".join(METHODS)).split(",") if m.strip()])
    lane = TxLane(plat, recipe_for, out=out, log=log, funds=funds, p=funder,
                  required=given or (required_for(part, methods) if funds else []))
    signal.signal(signal.SIGTERM, stopped)
    return lane.main()


if __name__ == "__main__":
    sys.exit(main())
