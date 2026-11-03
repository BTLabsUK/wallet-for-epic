# SPDX-License-Identifier: Apache-2.0
"""One G4 update-trust lane, the same on every platform: a user on the previous release updates to
the candidate and keeps their wallet, money, history, servers and settings, then receives and sends.

The lane is a list of phases. A platform (linux/platform.py, android/platform.py,
windows/platform.py) supplies what differs: how the app is installed, started, stopped and updated,
how its files are read, and a Surface for its UI. The UI steps are the family's recipe
(core/desktop.py for Linux and Windows, core/phone.py for Android), written once on targets.
The checks (core/checks.py) compare what the wallet's own files hold before and after, never what a
screen was scraped for.

Start modes (REL_TRUST_START=auto|seed|state|fresh, default auto): `seed` restores the lane's
permanent wallet from its recovery phrase (core/lane_seed.py) through the previous release's own
screens, then sets everything up as `fresh` does; its coins stay in it between runs, and the lane
holds the seed's lock for its whole run and saves no trust state. `state` restores the end state a
passing lane of the previous release saved (core/state.py), so the previous binary only starts,
unlocks, is funded and stopped; `fresh` creates the wallet and sets everything up on the previous
binary. auto: seed when the lane has a seed, else state when one fits, else fresh.

REL_TRUST_MODE=create (create_only): no update and no funds. The candidate is installed with no app
data, a new wallet is created through its screens and its home reached (check create_ok); the phrase
it shows is checked and dropped, never stored.

At its end a lane with a phrase (seed or create) scans its whole REL_OUT for 3 consecutive words of it:
a hit is a HarnessFault naming only the file (exit 2).

Servers: each platform's prepare asks core/hermetic.py plan() which of this host's local node and relay
the app is given (as its own server and in use); the proof records it (details["hermetic"]) and the
hosts outside this machine the app and the driver touched (details["non_local"], before and after
live-servers). With REL_FUNDS the live-servers phase puts a public node and relay in use through the
screens before the funds legs, so one send and receive per platform runs on real mainnet servers.

Resilience: a phase that raises HarnessGone (display, emulator, rig, sandbox gone) has the platform
rebuilt (platform.recover()) and the phase run again, once per phase; phases are written to be
re-run (each starts by finding where the app is). A ProductFault or a false check is never retried.

Exit: 0 every required check true, 1 a check false or a product fault, 2 could not run.
"""
import json
import os
import time
import traceback

from . import breaks
from . import hermetic
from . import lane_seed as ls
from . import state as st
from .recover import Recover
from .faults import Fault, HarnessFault, HarnessGone, ProductFault


class Platform:
    """What a platform supplies; see the module doc. Methods raise HarnessFault / HarnessGone for
    infrastructure trouble, ProductFault when the app itself misbehaves (e.g. the update installer
    fails on a good setup file)."""
    name = "?"          # linux | windows | android
    family = "?"        # desktop | phone
    variant = "tor"
    update_method = "?"

    def prepare(self): ...                      # sandbox/emulator/rig up; nothing of the app yet
    def recover(self): ...                      # rebuild what HarnessGone said went (keeps the app's data)
    def install_previous(self): ...             # a fresh install of the previous release
    def start(self, which): ...                 # 'previous' | 'candidate' -> Surface; the app running
    def stop(self): ...                         # the app closed the way a user closes it
    def update(self): ...                       # the candidate installed over the previous, the platform's way
    def digest(self, tag, secrets): ...         # the wallet's data read from its files (checks.py's schema)
    def files_snapshot(self): ...               # (listing, hashes) of the data folder, for migration checks
    def seed_previous_files(self, secrets): ... # contact, note, LAN node into the previous release's files
    def save_state(self, folder): ...           # the payload of a saved state (state.py)
    def restore_state(self, folder): ...
    def logs(self): ...                         # {name: path} of the app's logs for the evidence
    def shutdown(self): ...

    def install_candidate_fresh(self):          # create mode: the candidate installed with no app data
        raise HarnessFault("install", "%s has no fresh install of the candidate (REL_TRUST_MODE=create)" % self.name)


class Lane:
    def __init__(self, platform, recipe_for, checks, *, out, log, required, funds, p=None):
        """recipe_for(lane, which, surface) -> the family's recipe on a Driver over that surface, with the
        build's strings (core.labels) and the lane's one Recover (lane.rec)."""
        breaks.refuse_in_release()
        self.p, self.recipe_for, self.checks_mod = platform, recipe_for, checks
        self.out, self.log, self.required, self.funds, self.funder = out, log, required, funds, p
        self.results, self.details = {}, {}
        self.rec = Recover(out, platform.name, log=log)
        self.ui = None  # the recipe on the app that runs now
        self.fault = None
        self.secrets = {}
        self.mode = None
        self.phase = None
        self.retried = set()
        self.ui_settings = {}  # what the screens show where the files cannot be read (platform.reads_settings_in_ui)
        self.seed = None  # the lane seed (lane_seed.LaneSeed) in start mode seed; it alone holds the phrase
        self.balance = None  # the last balance the wallet's data showed in this run (seed mode)
        self.needles = None  # what the end-of-lane scan looks for (lane_seed.Needles): no word kept
        self.fund_tx = self.inflow = self.send_pending = None  # set by checks.py
        self.touched = []      # the servers the driver gave the app at prepare, and P's relay
        self.last_digest = None  # the newest digest read (checks._digest): its log names the hosts the app used
        self.split = None      # the app log's line count when live-servers started

    # ---- results

    def ok(self, check, why):
        self.results[check] = True
        self.details[check] = why
        self.log("PASS %s: %s" % (check, why))

    def fail(self, check, why):
        self.results[check] = False
        self.details[check] = why
        self.log("%s %s: %s" % ("FAIL" if check in self.required else "false (not required)", check, why))

    def proof(self, extra=None):
        p = {"platform": self.p.name, "variant": self.p.variant,
             "previous": None if self.mode == "create" else os.environ.get("REL_PREVIOUS_VERSION"),
             "candidate": os.environ.get("REL_CANDIDATE_VERSION"),
             "update_method": self.p.update_method, "start": self.mode,
             "node": getattr(self.p, "node", None), "epicbox": getattr(self.p, "relay", None),
             "checks": {c: self.results.get(c, False) for c in self.required},
             "details": self.details, "recovered": self.rec.used}
        if self.fault:
            p["fault"] = {"kind": self.fault.kind, "step": self.fault.step, "what": self.fault.what, "shot": self.fault.shot,
                          "line": self.fault.line()}
        p.update(extra or {})
        with open(os.path.join(self.out, "proof.json"), "w") as f:
            json.dump(p, f, indent=1, default=str)
        return p

    # ---- phases

    def run_phase(self, name, fn):
        self.phase = name
        self.log("== phase %s" % name)
        breaks.at_phase(self, name)
        while True:
            try:
                return fn()
            except HarnessGone as e:
                if name in self.retried:
                    raise
                self.retried.add(name)
                self.log("phase %s: %s; rebuilding the platform and running the phase again" % (name, e.line()))
                self.details.setdefault("harness_recovered", []).append("%s: %s" % (name, e.what))
                self.p.recover()
                if self.ui is not None and getattr(self.p, "running", True) and name not in ("prepare", "restore", "install", "previous", "candidate", "update"):
                    # the app was started again: back to the wallet before the phase
                    self.ui.open_wallet(self.secrets, after_update=getattr(self.ui, "which", "") == "candidate")

    def main(self):
        """The lane, or create_only() when REL_TRUST_MODE=create. -> exit code."""
        mode = os.environ.get("REL_TRUST_MODE") or "update"
        if mode == "create":
            return self.create_only()
        if mode != "update":
            return self._run(lambda: self._refuse("REL_TRUST_MODE=%s: not update or create" % mode))
        return self._run(self._main)

    def create_only(self):
        """REL_TRUST_MODE=create. -> exit code, as main()."""
        return self._run(self._create)

    def _refuse(self, why):
        raise HarnessFault("start", why)

    def _run(self, body):
        code = 2
        try:
            code = body()
        except Fault as f:
            self.fault = f
            self.log(f.line())
            code = 1 if isinstance(f, ProductFault) else 2
        except Exception as e:  # noqa: BLE001 — a bug in the harness is the harness's fault
            self.fault = HarnessFault(self.phase or "start", "%s: %s" % (type(e).__name__, e))
            self.log(traceback.format_exc())
            code = 2
        finally:
            try:
                self.p.shutdown()
            except Exception as e:  # noqa: BLE001
                self.log("shutdown: %s" % e)
        try:
            self._non_local()
        except Exception as e:  # noqa: BLE001 — evidence, never the result
            self.log("non_local not recorded: %s" % e)
        if code == 0 and not all(self.results.get(c) for c in self.required):
            code = 1
        missing = [c for c in self.required if c not in self.results]
        if code == 1 and not self.fault and missing:  # a check that never ran says nothing about the app
            self.fault = HarnessFault(self.phase or "checks", "required checks never computed: %s" % ", ".join(missing))
            code = 2
        try:
            self._record_seed()
            code = self._result(code)
            hits = self._leak_scan()
            if hits:
                if self.fault:
                    self.details["fault_before_scan"] = self.fault.line()
                self.fault = HarnessFault("leak", "lane seed words found in %s" % ", ".join(hits))
                self.log(self.fault.line())
                code = self._result(2)
        finally:
            if self.seed:
                self.seed.unlock()
        return code

    def _result(self, code):
        """proof.json and result.txt for [code]."""
        proof = self.proof()
        line = self.fault.line() if self.fault else (
            "PASS %s %s %s%s" % (self.p.name, self.p.variant, "create %s" % proof["candidate"] if self.mode == "create"
                                 else "%s → %s" % (proof["previous"], proof["candidate"]),
                                 " (recovered: %s)" % ", ".join(r["step"] for r in self.rec.used) if self.rec.used else "")
            if code == 0 else "PRODUCT checks false: " + "; ".join(
                "%s (%s)" % (c, str(self.details.get(c, "not reached"))[:120]) for c in self.required if not self.results.get(c)))
        with open(os.path.join(self.out, "result.txt"), "w") as f:
            f.write(line + "\n")
        self.log("RESULT " + line)
        return code

    def _main(self):
        self.run_phase("prepare", self.p.prepare)
        self._hermetic()
        saved = self._pick()
        if self.mode == "seed":
            self.seed.lock()
            self.run_phase("install", self.p.install_previous)
            self.run_phase("previous", self._restore)
            self.run_phase("restore-ok", self._restore_ok)
            self.run_phase("previous-setup", self._setup)
        elif saved:
            self.secrets = saved.secrets()
            self.run_phase("restore", lambda: self.p.restore_state(saved.payload))
            self.run_phase("previous", lambda: self._open("previous"))
        else:
            self.run_phase("install", self.p.install_previous)
            self.run_phase("previous", self._fresh)
        ui_read = getattr(self.p, "reads_settings_in_ui", False)
        if ui_read:
            self.run_phase("settings-ui-before", lambda: self._ui_confirmations("before"))
        address = self.run_phase("address", lambda: self.ui.address())
        self.details["address"] = address[:8] + "…" + address[-6:] if address else None
        self.run_phase("fund", lambda: self.checks_mod.fund_before(self, address))
        before = self.run_phase("digest-before", lambda: self.p.digest("previous", self.secrets))
        self._ui_settings(before)
        if hasattr(self.checks_mod, "setup_took"):
            self.checks_mod.setup_took(self, before)
        self.run_phase("stop-previous", self.p.stop)
        if not saved:
            self.run_phase("seed", lambda: self.p.seed_previous_files(self.secrets))
        snap = self.run_phase("snapshot", self.p.files_snapshot)
        self.run_phase("update", self.p.update)
        self.run_phase("candidate", lambda: self._open("candidate"))
        if ui_read:
            self.run_phase("settings-ui-after", lambda: self._ui_confirmations("after"))
        after = self.run_phase("digest-after", lambda: self.checks_mod.settle(self, before))
        self._ui_settings(after)
        self.checks_mod.compare(self, before, after, snap)
        if self.funds:
            self.run_phase("live-servers", lambda: self._live_servers(after))
        # without REL_FUNDS the legs are not checked; the balance still goes back to P
        self.run_phase("funds", lambda: self.checks_mod.funds_legs(self, after))
        # a passing lane leaves its wallet for the next release (REL_TRUST_SAVE_STATE=0 for trial runs)
        if self.mode == "seed":
            self.log("no trust state saved: the lane seed's wallet is restored from its phrase next run")
        elif all(self.results.get(c) for c in self.required) and os.environ.get("REL_TRUST_SAVE_STATE", "1") != "0":
            self.run_phase("save-state", lambda: st.save(self.p, self.secrets, self.checks_mod.public(after), log=self.log))
        return 0

    # ---- servers (core/hermetic.py)

    def _hermetic(self):
        plan = getattr(self.p, "hermetic", None) or {"on": False, "reason": "the platform has no hermetic plan"}
        self.details["hermetic"] = {"on": bool(plan.get("on")), "reason": plan.get("reason", ""),
                                    "node": getattr(self.p, "node", None), "relay": getattr(self.p, "relay", None)}
        p_addr = getattr(self.checks_mod, "P_ADDR", "") or ""
        self.touched = [getattr(self.p, k, None) for k in ("node", "relay", "custom_node", "custom_relay")]
        self.touched.append(p_addr.split("@", 1)[1] if "@" in p_addr else None)  # the app answers P there

    def _live_servers(self, after):
        """The funds legs on public servers: the node and relay in use that are this host's own become a
        public pair (platform.live_servers(): REL_NODE / REL_EPICBOX or health-picked), through the
        recipe's screens. The wallet's own servers stay listed; nothing is switched back."""
        self.split = ((after or {}).get("log") or {}).get("lines")
        local = [k for k in ("node", "relay") if hermetic.local(getattr(self.p, k, ""))]
        if not local:
            self.log("live servers: the node and relay in use are public already")
            return
        if after is None or not self.results.get("wallet_opens") or not self.results.get("balance_kept"):
            self.log("live servers: not switched (the funds legs do not run)")
            return
        node, relay = self.p.live_servers()
        node = node if "node" in local else self.p.node
        relay = relay if "relay" in local else self.p.relay
        self.ui.use_servers(node, relay)
        self.p.node, self.p.relay = node, relay
        self.details["live_servers"] = {"node": node, "relay": relay}

    def _non_local(self):
        """details["non_local"]: the hosts outside this machine the driver and the app (its log's lines, as
        the newest digest read them) touched, before and after live-servers. Before is logged, not failed."""
        log = ((self.last_digest or {}).get("log") or {})
        hosts = log.get("hosts") or []
        split = self.split if self.split is not None else float("inf")
        live = self.details.get("live_servers") or {}
        before = hermetic.non_local(self.touched + [h for i, h in hosts if i < split])
        after = hermetic.non_local([live.get("node"), live.get("relay")] + [h for i, h in hosts if i >= split])
        self.details["non_local"] = {"before": before, "after": after, "app_log": bool(log)}
        if before:
            self.log("hosts outside this machine before live-servers (logged, not failed): %s" % ", ".join(before))

    def _ui_settings(self, digest):
        """A platform whose files cannot show the settings (settings_from_ui: Android keeps them
        Keystore-encrypted) has them read off the app's Settings pages; a value the files showed stays."""
        if not getattr(self.p, "settings_from_ui", False):
            return
        got = self.run_phase("settings-%s" % self.ui.which, self.ui.read_settings)
        s, unread = digest.setdefault("settings", {}), digest.setdefault("unread", {})
        for k, v in got.items():
            if k == "level":
                if digest.get("level") is None and v is not None:
                    digest["level"] = v
                    unread.pop("level", None)
            elif s.get(k) is None and v is not None:
                s[k] = v
                unread.pop(k, None)
        digest["settings_source"] = "the app's Settings pages (its storage is Keystore-encrypted)"
        self.log("settings read off the %s app: %s" % (self.ui.which, got))

    def _open(self, which):
        surface = self.p.start(which)
        self.rec.build = os.environ.get("REL_%s_VERSION" % which.upper(), which)
        self.ui = self.recipe_for(self, which, surface)
        self.ui.open_wallet(self.secrets, after_update=(which == "candidate"))

    def _ui_confirmations(self, when):
        """The confirmations count on the app's Settings page; after the update it is also set one
        step away and back through the stepper, each read back on the page opened again."""
        v = self.ui.read_confirmations()
        self.ui_settings[when] = {"confirmations": v}
        if when == "after" and v is not None:
            to = v + 1 if v < 30 else v - 1  # 30: the app's highest count
            read, refused = self.ui.confirmations_land(to)
            back, refused_back = self.ui.confirmations_land(v)
            self.ui_settings["set"] = {"from": v, "to": to, "read": read, "back": back, "refused": refused or refused_back}
        self.ui.leave_settings()
        self.details["settings_ui"] = self.ui_settings
        self.log("settings on screen %s the update: %s" % (when, self.ui_settings))

    def _fresh(self):
        surface = self.p.start("previous")
        self.rec.build = os.environ.get("REL_PREVIOUS_VERSION", "previous")
        self.ui = self.recipe_for(self, "previous", surface)
        self.secrets.update(self.ui.create_wallet())
        self._setup()

    def _setup(self):
        self.ui.set_servers(self.p.node, self.p.custom_node, self.p.relay, self.p.custom_relay)
        self.ui.change_settings(self.checks_mod.WANT_SETTINGS)

    # ---- the lane seed

    def _pick(self):
        """The start mode (self.mode) -> the saved state to start from, or None."""
        want = os.environ.get("REL_TRUST_START") or "auto"
        if want not in ("auto", "seed", "state", "fresh"):
            raise HarnessFault("start", "REL_TRUST_START=%s: not auto, seed, state or fresh" % want)
        seed = ls.LaneSeed(ls.lane_name(self.p.name, self.p.variant))
        if want == "seed" or (want == "auto" and seed.exists()):
            if not seed.exists():
                raise HarnessFault("start", "REL_TRUST_START=seed but lane %s has no seed in %s (lane_seed.py init %s)" % (
                    seed.lane, seed.dir, seed.lane))
            self.seed, self.mode = seed, "seed"
            self.needles = ls.Needles([seed.phrase()])
            read = self.p.digest

            def digest(tag, secrets):  # the last balance read, for the seed's record
                d = read(tag, secrets)
                if d and d.get("balance"):
                    self.balance = d["balance"]
                return d
            self.p.digest = digest
            self.log("start mode: seed (lane seed %s, born %s)" % (seed.lane, seed.birth()))
            return None
        saved = st.pick(self.p.name, self.p.variant, os.environ.get("REL_PREVIOUS_VERSION"),
                        fits=getattr(self.p, "fits", None), log=self.log)
        self.mode = "state" if saved else "fresh"
        self.log("start mode: %s%s" % (self.mode, " (%s)" % saved.folder if saved else ""))
        self.ok("restore_ok", "not applicable: start mode %s (no lane seed)" % self.mode)
        return saved

    def _restore(self):
        """The lane seed's wallet restored through the previous release's screens; the recipe leaves the app
        on the wallet's home. The pin and password it chose go into the lane's secrets, and the phrase too:
        an encrypted store (desktop from 26.10.25) is read through the LEPIC CLI, which restores from it."""
        surface = self.p.start("previous")
        self.rec.build = os.environ.get("REL_PREVIOUS_VERSION", "previous")
        self.ui = self.recipe_for(self, "previous", surface)
        birth = self.seed.birth()
        if birth.get("height") is None:
            raise HarnessFault("restore", "lane seed %s has no birth height (lane_seed.py birth %s)" % (
                self.seed.lane, self.seed.lane))
        self.details["birth"] = {k: birth.get(k) for k in ("height", "date", "method")}
        self.log("restore: from the lane seed's birth height %d (%s, %s)" % (birth["height"], birth.get("date"), birth.get("method")))
        got = self.ui.restore_wallet(self.seed.phrase(), birth) or {}
        self.secrets.update({k: got[k] for k in ("pin", "password") if got.get(k)})
        self.secrets["phrase"] = self.seed.phrase()

    def _restore_ok(self):
        """The restored wallet's spendable reaches the one the lane seed has on record (the scan may still
        run: read again until REL_TRUST_RESTORE_WAIT_S)."""
        want = self.seed.last_spendable()
        on_record = (self.seed.meta().get("last") or {}).get("run")
        wait = int(os.environ.get("REL_TRUST_RESTORE_WAIT_S") or 900)
        poll = float(os.environ.get("REL_TRUST_RESTORE_POLL_S") or 20)
        t0 = time.time()
        got, err = None, None
        while True:
            try:
                b = (self.p.digest("previous", self.secrets) or {}).get("balance")
                got, err = (b or {}).get("spendable"), None if b else "no balance in the wallet's data"
            except Fault:
                raise
            except Exception as e:  # noqa: BLE001 — read again until the wait is over
                err = "%s: %s" % (type(e).__name__, e)
            took = int(time.time() - t0)
            if want is None and got is not None:
                self.ok("restore_ok", "first run of lane seed %s: no balance on record to reach; the restored wallet's "
                        "spendable is %s EPIC (wallet data)" % (self.seed.lane, ls.epic(got)))
                return
            if got is not None and got >= want:
                self.ok("restore_ok", "the restored wallet's spendable %s EPIC reached the %s EPIC on record (run %s) after %d s "
                        "(wallet data)" % (ls.epic(got), ls.epic(want), on_record, took))
                return
            if took >= wait:
                self.fail("restore_ok", "the restored wallet's spendable %s did not reach the %s EPIC on record (run %s) in %d s%s" % (
                    "%s EPIC" % ls.epic(got) if got is not None else "NOT read", ls.epic(want) if want is not None else "?",
                    on_record, took, " (%s)" % err if err else " (wallet data)"))
                return
            self.log("restore: spendable %s, on record %s%s; reading again" % (ls.epic(got), ls.epic(want), " (%s)" % err if err else ""))
            time.sleep(poll)

    def on_funding(self, amount, tx):
        """checks.py: P paid the wallet [amount] and its data shows it (tx)."""
        if self.seed:
            try:
                self.seed.record_funding(amount, ls.run_id(), tx.get("slate"))
            except OSError as e:
                self.log("lane seed %s: funding not recorded: %s" % (self.seed.lane, e))

    def on_funding_height(self, tx, height):
        """checks.py: the funding [tx] confirmed at [height] (the wallet's data)."""
        if self.seed:
            try:
                self.seed.record_funding_height(tx.get("slate"), height)
            except OSError as e:
                self.log("lane seed %s: funding height not recorded: %s" % (self.seed.lane, e))

    def _record_seed(self):
        """meta.last of the lane seed: the last balance this run read, once the restore reached the one on
        record (an incomplete scan never lowers the bar). A send to P not seen confirmed counts as gone."""
        if not self.seed or self.balance is None:
            return
        if not self.results.get("restore_ok"):
            self.log("lane seed %s: last balance kept as it was (the restore did not reach it)" % self.seed.lane)
            return
        b = dict(self.balance)
        if self.send_pending:
            fee = getattr(self.checks_mod, "FEE_MAX", 0)
            b["spendable"] = max(0, b["spendable"] - int((self.send_pending + fee) * ls.NANO))
        try:
            self.seed.record_last(b, ls.run_id())
            self.log("lane seed %s: last spendable %s EPIC, total %s EPIC recorded" % (
                self.seed.lane, ls.epic(b["spendable"]), ls.epic(b.get("total"))))
        except OSError as e:
            self.log("lane seed %s: last balance not recorded: %s" % (self.seed.lane, e))

    def _leak_scan(self):
        """[files under REL_OUT holding 3 consecutive words of this lane's phrase] (paths relative to it)."""
        if not self.needles:
            return []
        try:
            hits, n = ls.scan([self.out], needles=self.needles, skip=[ls.root()])
        except OSError as e:
            return ["(the scan could not read a file: %s)" % e]
        self.log("phrase scan of %s: %d files read, %d with words of the phrase" % (self.out, n, len(hits)))
        return [os.path.relpath(h, self.out) for h in hits]

    # ---- create mode

    def _create(self):
        self.mode = "create"
        self.log("trust mode: create (the candidate installed with no app data, a new wallet created; no funds, "
                 "the phrase checked and dropped)")
        self.run_phase("prepare", self.p.prepare)
        self.run_phase("install", self.p.install_candidate_fresh)
        words = self.run_phase("candidate", self._create_wallet)
        try:
            self.run_phase("home", lambda: self.ui.d.wait(self.ui._home(), 120))
        except ProductFault as e:
            self.fail("create_ok", "wallet created, its home not reached: %s" % e.what)
            return 1
        ok, why = words
        if ok:
            self.ok("create_ok", "a new wallet created on the candidate %s with no app data and its home reached; the "
                    "phrase it showed: %s (dropped, not stored)" % (os.environ.get("REL_CANDIDATE_VERSION", "?"), why))
        else:
            self.fail("create_ok", "a new wallet created and its home reached, but the phrase it showed: %s" % why)
        return 0

    def _create_birth(self):
        """The chain's tip as the new wallet is made: its birth, as a lane seed keeps one (proof details)."""
        try:
            height, node = ls.tip()
        except Exception as e:  # noqa: BLE001 — evidence only; the create check does not hang on a node
            self.details["birth"] = {"height": None, "why": str(e)[:200]}
            self.log("create: birth height not read: %s" % e)
            return
        date = time.strftime("%Y-%m-%d", time.gmtime())
        self.details["birth"] = {"height": height, "date": date, "method": "tip at creation", "node": node}
        self.log("create: birth height %d, date %s (tip at creation, %s)" % (height, date, node))

    def _create_wallet(self):
        """-> (phrase valid, what it is): the words never leave this function but as the scan's hashes."""
        surface = self.p.start("candidate")
        self.rec.build = os.environ.get("REL_CANDIDATE_VERSION", "candidate")
        self.ui = self.recipe_for(self, "candidate", surface)
        self._create_birth()
        got = dict(self.ui.create_wallet() or {})
        phrase = got.pop("phrase", None) or getattr(self.ui, "phrase", None)
        if hasattr(self.ui, "phrase"):
            self.ui.phrase = None
        self.secrets.update({k: got[k] for k in ("pin", "password") if got.get(k)})
        if not phrase:
            return False, "none read off the screen"
        self.needles = ls.Needles([phrase])
        res = ls.validate(phrase)
        del phrase
        return res
