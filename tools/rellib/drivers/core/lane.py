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

REL_TRUST_MODE=flow: the update lane on one build, the run's quick test build before the release builds
(release/pipeline.toml flow-*): the step names that build as both previous and candidate, so the lane
installs it, restores or sets up the wallet through its screens, takes the setup's settings, servers,
contacts and notes, reinstalls the same build over it and checks all of it kept, then (REL_FUNDS) runs
the send and receive legs. A flow failure shows before any release build. No trust state is saved.

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

Faults: every failure ends in a cause class (PRODUCT, INFRA or HARNESS-ui), written into proof.json's
fault next to its kind, and leaves a bundle in REL_OUT/bundles/<n>-<step>/: step.txt (step, cause
class, what, the recoveries tried), screen.txt (the tree read then, a password's value with it; a
phrase screen's words are not written), log-tail.txt (the last 200 lines of trust.log) and shot.png.
Each phase sends step.start and step.end events, a fault failure and bundle events
(core/record.py; a no-op without the test DB).

Test wallets (the owner, 2026-11-03): the lane's wallet goes to the local test DB with its phrase and
password (wallet.put, where it is created or restored), its address (wallet.address) and each digest's
balance and transactions (wallet.snapshot). The bundle's shot is taken on any screen, a phrase's too:
they are test wallets and the bundle stays under REL_OUT. trust.log and proof.json stay clean.

Resume (REL_TRUST_RESUME=1): the previous attempt's proof (proof.before-attempt-N.json, the newest, or
proof.json) names the phases done and the one that failed. When it failed after the previous release
was installed and its wallet made (RESUMABLE) and the platform can take its state again
(platform.resume_from: Linux, the sandbox still there and its stand-ins' ports free), the lane opens
the previous release on that state and starts at the failed phase; the checks that passed are kept.
Else it starts fresh and logs why. The secrets the resumed lane needs wait in a 0600 file in the
platform's resume_dir() (outside REL_OUT), read once.

Stop (REL_TRUST_UNTIL=<phase>, --test runs only): the lane runs up to and including that phase and
ends there, before the next: no payment to P, no update. "STOP after <phase> (REL_TRUST_UNTIL)" in the
log, proof.json with what ran (until, phases), exit 0 when no fault came up; a fault keeps its cause.
The break-test runs use it so they move no coins (fund pays P back even with REL_FUNDS=0).

Exit: 0 every required check true, 1 a check false or a product fault, 2 could not run.
"""
import glob
import json
import os
import re
import sys
import time
import traceback

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import facts  # noqa: E402
from . import breaks  # noqa: E402
from . import hermetic  # noqa: E402
from . import lane_seed as ls  # noqa: E402
from . import record  # noqa: E402
from . import state as st  # noqa: E402
from .recover import Recover, phrase_screen  # noqa: E402
from .faults import Fault, HarnessFault, HarnessGone, InfraFault, ProductFault  # noqa: E402

# The phases a lane can be resumed at: the previous release installed, its wallet made and open.
RESUMABLE = ("previous-setup", "settings-ui-before", "address", "fund")
# The phases REL_TRUST_UNTIL may name (a typo would run the whole lane, payment and all).
PHASES = ("prepare", "install", "restore", "previous", "restore-ok", "previous-open", "previous-setup",
          "settings-ui-before", "address", "fund", "digest-before", "stop-previous", "seed", "snapshot", "update",
          "candidate", "settings-ui-after", "digest-after", "live-servers", "tor-on", "funds", "save-state", "home")


class UntilRefused(RuntimeError):
    pass


def until_phase(phases=PHASES):
    """REL_TRUST_UNTIL's phase or None; UntilRefused in a release run or for a phase the lane has not."""
    until = (os.environ.get("REL_TRUST_UNTIL") or "").strip()
    if not until:
        return None
    if os.environ.get("REL_RUN_KIND") == "release":
        raise UntilRefused("REL_TRUST_UNTIL is set in a release run: a lane stopped early runs in --test runs only")
    if until not in phases:
        raise UntilRefused("REL_TRUST_UNTIL: unknown phase %s (known: %s)" % (until, " ".join(phases)))
    return until


class _Stop(Exception):
    """The lane ends cleanly after REL_TRUST_UNTIL's phase."""
LOG_TAIL = 200


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

    # resume (REL_TRUST_RESUME=1): a platform that can take a failed attempt's state again
    def resume_dir(self):                       # a private folder outside REL_OUT for the resume secrets, or None
        return None

    def resume_handle(self):                    # what resume_from needs (no secret), or None
        return None

    def resume_from(self, handle):              # -> (True, what is reused) or (False, why not); then prepare reuses it
        return False, "the %s platform cannot resume a lane" % self.name


class Lane:
    PHASES = PHASES  # a lane with other phases (linux/tx_lane.py) names its own

    def __init__(self, platform, recipe_for, checks, *, out, log, required, funds, p=None):
        """recipe_for(lane, which, surface) -> the family's recipe on a Driver over that surface, with the
        build's strings (core.labels) and the lane's one Recover (lane.rec)."""
        breaks.refuse_in_release()
        self.until = until_phase(self.PHASES)
        self.stopped = None
        self.attempt = time.strftime("%Y%m%d-%H%M%S", time.gmtime())   # a fresh wallet's name in the test DB
        self.p, self.recipe_for, self.checks_mod = platform, recipe_for, checks
        self.out, self.log, self.required, self.funds, self.funder = out, log, required, funds, p
        if self.until and "fund" in self.PHASES and self.PHASES.index(self.until) >= self.PHASES.index("fund"):
            log("REL_TRUST_UNTIL=%s is at or after fund: P pays this lane's wallet and the stop leaves it there "
                "(its phrase is in the test DB); stop at address to move no coins" % self.until)
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
        self.done = []         # the phases that ended, in order (proof.json, for a resume)
        self.bundles = 0
        self.resumed = None    # the resume plan this run started from
        self.flow = False      # REL_TRUST_MODE=flow: previous and candidate are the same test build

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
             "update_method": self.p.update_method, "start": self.mode, "trust_mode": "flow" if self.flow else None,
             "node": getattr(self.p, "node", None), "epicbox": getattr(self.p, "relay", None),
             "checks": {c: self.results.get(c, False) for c in self.required},
             "details": self.details, "recovered": self.rec.used}
        if self.fault:
            p["fault"] = {"kind": self.fault.kind, "cause_class": self.fault.cause_class, "step": self.fault.step,
                          "what": self.fault.what, "shot": self.fault.shot, "line": self.fault.line(),
                          "tried": getattr(self.fault, "tried", []) or []}
            if getattr(self.fault, "sub", None):
                p["fault"]["sub"] = self.fault.sub
        p["phases"] = {"done": list(self.done), "failed": self.phase if self.fault else None}
        if self.until:
            p["until"] = {"phase": self.until, "stopped": bool(self.stopped)}
        if self.fault and self.mode != "create":
            p["resume"] = self._resume_point()
        p.update(extra or {})
        with open(os.path.join(self.out, "proof.json"), "w") as f:
            json.dump(p, f, indent=1, default=str)
        return p

    # ---- phases

    def run_phase(self, name, fn):
        self.phase = name
        self.log("== phase %s" % name)
        record.emit("step.start", step=name, detail="phase")
        try:
            breaks.at_phase(self, name)
            r = self._phase(name, fn)
        except BaseException as e:
            record.emit("step.end", step=name, state="failed", detail=str(e)[:200])
            raise
        record.emit("step.end", step=name, state="recovered" if name in self.retried else "ok")
        self.done.append(name)
        if name == self.until:
            self.stopped = name
            self.log("STOP after %s (REL_TRUST_UNTIL)" % name)
            raise _Stop(name)
        return r

    def skip_phase(self, name, why):
        self.log("SKIP %s: %s" % (name, why))
        record.emit("step.start", step=name, detail="phase")
        record.emit("step.end", step=name, state="skipped", detail=why)
        self.done.append(name)

    def _phase(self, name, fn):
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
        if mode not in ("update", "flow"):
            return self._run(lambda: self._refuse("REL_TRUST_MODE=%s: not update, flow or create" % mode))
        self.flow = mode == "flow"
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
        except _Stop:
            code = 0
        except Fault as f:
            if isinstance(f, InfraFault) and f.step == "wallet-read":  # the LEPIC CLI's: the phase that read
                f.step = self.phase or f.step
            self.fault = f
            self.log(f.line())
            code = 1 if isinstance(f, ProductFault) else 2
            self._faulted()
        except Exception as e:  # noqa: BLE001 — a bug in the harness is the harness's fault
            self.fault = HarnessFault(self.phase or "start", "%s: %s" % (type(e).__name__, e))
            self.log(traceback.format_exc())
            code = 2
            self._faulted()
        finally:
            try:
                self.p.shutdown()
            except Exception as e:  # noqa: BLE001
                self.log("shutdown: %s" % e)
        try:
            self._non_local()
        except Exception as e:  # noqa: BLE001 — evidence, never the result
            self.log("non_local not recorded: %s" % e)
        if code == 0 and not self.stopped and not all(self.results.get(c) for c in self.required):
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
        line = self.fault.line() if self.fault else ("STOP %s %s after %s (REL_TRUST_UNTIL): no fault" % (
            self.p.name, self.p.variant, self.stopped) if self.stopped and code == 0 else None) or (
            "PASS %s %s %s%s" % (self.p.name, self.p.variant, "create %s" % proof["candidate"] if self.mode == "create"
                                 else "flow %s (test build)" % proof["candidate"] if self.flow else "%s → %s" % (proof["previous"], proof["candidate"]),
                                 " (recovered: %s)" % ", ".join(r["step"] for r in self.rec.used) if self.rec.used else "")
            if code == 0 else "PRODUCT checks false: " + "; ".join(
                "%s (%s)" % (c, str(self.details.get(c, "not reached"))[:120]) for c in self.required if not self.results.get(c)))
        with open(os.path.join(self.out, "result.txt"), "w") as f:
            f.write(line + "\n")
        self.log("RESULT " + line)
        return code

    def _main(self):
        self._watch_digests()
        plan = self._resume_plan()
        self.run_phase("prepare", self.p.prepare)
        self._hermetic()
        if plan:
            saved = self._resume(plan)
        else:
            saved = self._pick()
            if self.mode == "seed":
                self.seed.lock()
                self.run_phase("install", self.p.install_previous)
                self.run_phase("previous", self._restore)
                self.run_phase("restore-ok", self._restore_ok)
                self.run_phase("previous-setup", self._setup)
            elif saved:
                self.secrets = saved.secrets()
                self._wallet_put("the lane's saved state")
                self.run_phase("restore", lambda: self.p.restore_state(saved.payload))
                self.run_phase("previous", lambda: self._open("previous"))
            else:
                self.run_phase("install", self.p.install_previous)
                self.run_phase("previous", self._fresh)
                self.run_phase("previous-setup", self._setup)
        ui_read = getattr(self.p, "reads_settings_in_ui", False)
        if ui_read and not self._resumed_past("settings-ui-before"):
            self.run_phase("settings-ui-before", lambda: self._ui_confirmations("before"))
        address = self.run_phase("address", lambda: self.ui.address())
        if address:
            record.emit("wallet.address", name=self._wallet()[0], role=self._wallet()[1], kind="epicbox", address=address)
        self.details["address"] = address[:8] + "…" + address[-6:] if address else None
        if hasattr(self.ui, "contacts"):   # Home › Contacts on the phone, Settings › Contacts on desktop (26.11.3)
            self.run_phase("contacts", self.ui.contacts)
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
        # a Tor lane's after-update payments go over Tor (REL_TRUST_UNTIL=tor-on tries it without REL_FUNDS)
        tor = self.p.variant == "tor" and (self.funds or self.until == "tor-on")
        if self.funds or tor:
            self.run_phase("live-servers", lambda: self._live_servers(after))
        if tor:
            self.run_phase("tor-on", lambda: self._tor_on(after))
        # without REL_FUNDS the legs are not checked; the balance still goes back to P
        self.run_phase("funds", lambda: self.checks_mod.funds_legs(self, after))
        # a passing lane leaves its wallet for the next release (REL_TRUST_SAVE_STATE=0 for trial runs)
        if self.mode == "seed":
            self.log("no trust state saved: the lane seed's wallet is restored from its phrase next run")
        elif self.flow:
            self.log("no trust state saved: a flow lane's build is a test build, never a release")
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

    def _tor_on(self, after):
        """The candidate's Connection mode Tor only before the funds legs, Tor and Epicbox connected (the
        recipe's tor_on). A relay Tor cannot reach is moved first to the first pick it can. Tor that does
        not come up is not the lane's: tor_payment_ok false (never required) and the legs run in the
        clear (checks.funds_legs reads lane.tor)."""
        info = self.details["tor"] = {"node": self.p.node, "relay": self.p.relay}
        self.tor = {"on": False}
        if after is None or not self.results.get("wallet_opens") or not self.results.get("balance_kept"):
            info["state"] = "not turned on: the funds legs do not run"
            self.log("tor-on: %s" % info["state"])
            return
        if not hermetic.tor_route(self.p.relay):
            alt = next((h for h in facts.RELAY_PICK if hermetic.tor_route(h)), None)
            if alt:
                self.log("tor-on: Tor cannot reach the relay %s; %s in use instead" % (self.p.relay, alt))
                self.ui.use_servers(self.p.node, alt)
                info["relay_moved"] = {"from": self.p.relay, "to": alt}
                self.p.relay = info["relay"] = alt
        info["route"] = {"node": hermetic.tor_route(self.p.node), "relay": hermetic.tor_route(self.p.relay)}
        try:
            info["goal"] = self.ui.tor_on()
        except HarnessGone:
            raise
        except Fault as e:
            self.checks_mod.tor_failed(self, "Tor did not come up: %s" % e.what, e.cause_class)
            info["state"] = "off: %s" % e.line()
            return
        self.tor = {"on": True}
        info["mode"] = "Tor only"
        info["state"] = self.ui.tor_status()
        self.log("tor-on: Connection mode Tor only; %s" % info["state"])

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
        self._wallet_put("created by the lane on the previous release")

    def _setup(self):
        self.ui.set_servers(self.p.node, self.p.custom_node, self.p.relay, self.p.custom_relay)
        self.ui.change_settings(self.checks_mod.WANT_SETTINGS)

    # ---- the lane seed

    def _pick(self):
        """The start mode (self.mode) -> the saved state to start from, or None."""
        want = os.environ.get("REL_TRUST_START") or "auto"
        if want not in ("auto", "seed", "state", "fresh"):
            raise HarnessFault("start", "REL_TRUST_START=%s: not auto, seed, state or fresh" % want)
        lane = ls.lane_name(self.p.name, self.p.variant)
        seed = ls.LaneSeed(lane) if lane in ls.LANES else None   # a platform with no lane seeds yet (iOS)
        if want == "seed" or (want == "auto" and seed and seed.exists()):
            if not seed or not seed.exists():
                raise HarnessFault("start", "REL_TRUST_START=seed but lane %s has no seed (lane_seed.py init %s)" % (lane, lane))
            self._seed_mode(seed)
            return None
        saved = st.pick(self.p.name, self.p.variant, os.environ.get("REL_PREVIOUS_VERSION"),
                        fits=getattr(self.p, "fits", None), log=self.log)
        self.mode = "state" if saved else "fresh"
        self.log("start mode: %s%s" % (self.mode, " (%s)" % saved.folder if saved else ""))
        self.ok("restore_ok", "not applicable: start mode %s (no lane seed)" % self.mode)
        return saved

    def _seed_mode(self, seed):
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

    # ---- test wallets in the test DB

    def _wallet(self):
        """(name, role) of the lane's wallet in the test DB. A wallet made by this attempt is named by it: a
        retry in the same run makes another wallet, and the first one's phrase must stay (it may hold coins)."""
        lane = ls.lane_name(self.p.name, self.p.variant)
        if self.seed:
            return self.seed.lane, "seed"
        if self.mode == "create":
            return "%s-%s-%s-create" % (lane, ls.run_id(), self.attempt), "create"
        if self.mode == "state":
            return "%s-state" % lane, "lane"
        return "%s-%s-%s-sandbox" % (lane, ls.run_id(), self.attempt), "sandbox"

    def _wallet_put(self, origin, phrase=None):
        name, role = self._wallet()
        record.emit("wallet.put", name=name, role=role, platform=self.p.name, lane=ls.lane_name(self.p.name, self.p.variant),
                    phrase=phrase or self.secrets.get("phrase") or "", password=self.secrets.get("password") or "",
                    origin=origin)

    def _watch_digests(self):
        """Each digest of the lane's wallet into the test DB as a wallet.snapshot."""
        read = self.p.digest

        def digest(tag, secrets):
            d = read(tag, secrets)
            try:
                b = (d or {}).get("balance") or {}
                if b:
                    name, role = self._wallet()
                    record.emit("wallet.snapshot", name=name, role=role, origin="digest %s (%s)" % (tag, self.phase),
                                spendable=ls.epic(b.get("spendable")), total=ls.epic(b.get("total")),
                                unconfirmed=ls.epic(b.get("unconfirmed")), locked=ls.epic(b.get("locked")),
                                txs=json.dumps(d.get("txs") or [], default=str))
            except Exception as e:  # noqa: BLE001 — evidence only
                self.log("wallet snapshot not sent: %s" % e)
            return d
        self.p.digest = digest

    # ---- faults: the bundle

    def _faulted(self):
        """On any fault: the bundle, its events and what a resume needs. Never raises."""
        try:
            self._bundle(self.fault)
        except Exception as e:  # noqa: BLE001 — evidence, never the result
            self.log("fault bundle not written: %s" % e)
        try:
            self._save_resume_secrets()
        except Exception as e:  # noqa: BLE001
            self.log("resume secrets not kept: %s" % e)

    def _bundle(self, f):
        self.bundles += 1
        step = f.step or self.phase or "start"
        d = os.path.join(self.out, "bundles", "%d-%s" % (self.bundles, re.sub(r"[^\w.-]+", "-", step)[:60]))
        os.makedirs(d, exist_ok=True)
        tried = getattr(f, "tried", None) or []
        with open(os.path.join(d, "step.txt"), "w", encoding="utf-8") as fh:
            fh.write("step: %s\nphase: %s\ncause class: %s\nkind: %s%s\nwhat: %s\ntried:\n%s\n" % (
                step, self.phase, f.cause_class, f.kind, " (%s)" % f.sub if getattr(f, "sub", None) else "", f.what,
                "\n".join("  - " + t for t in tried) or "  (nothing)"))
        tree, why = None, None
        drv = getattr(self.ui, "d", None)
        if drv is None:
            why = "no app screen (no recipe running)"
        else:
            try:
                # a frozen app does not answer a tree read: the last screen read is its screen
                if getattr(f, "evidence", None) is not None:
                    tree = drv.last_tree or None
                    why = "the app froze before any screen was read"
                else:
                    tree = drv.s.tree()
            except Exception as e:  # noqa: BLE001
                why = "the screen could not be read: %s" % e
        for name, text in (getattr(f, "evidence", None) or {}).items():   # a freeze's own files (freeze.Frozen)
            with open(os.path.join(d, os.path.basename(name)), "w", encoding="utf-8") as fh:
                fh.write(text)
        screen = os.path.join(d, "screen.txt")
        with open(screen, "w", encoding="utf-8") as fh:
            if tree is not None and phrase_screen(tree):
                fh.write("(a recovery phrase screen: not kept)\n")
            elif tree is not None:
                fh.write("\n".join(n.brief() + (" value=%r" % n.value if "password" in n.states and n.value else "")
                                    for n in tree) + "\n")
            else:
                fh.write("(%s)\n" % why)
        tail = os.path.join(d, "log-tail.txt")
        try:
            with open(getattr(self, "log_path", None) or os.path.join(self.out, "trust.log"), encoding="utf-8", errors="replace") as fh:
                lines = fh.readlines()[-LOG_TAIL:]
        except OSError:
            lines = []
        with open(tail, "w", encoding="utf-8") as fh:
            fh.writelines(lines)
        shot = None
        if tree is not None:
            p = os.path.join(d, "shot.png")
            try:
                shot = p if drv.s.screenshot(p) else None
            except Exception:  # noqa: BLE001
                shot = None
        rel = lambda p: os.path.relpath(p, self.out) if p else None  # noqa: E731
        self.log("fault bundle: %s" % rel(d))
        record.emit("bundle", step=step, dir=rel(d), screen_path=rel(screen), log_tail_path=rel(tail), shot_path=rel(shot))
        record.emit("failure", step=step, cause_class=f.cause_class, cause=f.kind + (":" + f.sub if getattr(f, "sub", None) else ""),
                    what=f.what[:500])

    # ---- resume

    def _secrets_path(self):
        d = self.p.resume_dir()
        if not d:
            return None
        d = os.path.abspath(d)
        if (d + os.sep).startswith(os.path.abspath(self.out) + os.sep):
            return None   # never inside REL_OUT: the evidence is shared
        return os.path.join(d, "lane-resume.json")

    def _resume_point(self):
        h = self.p.resume_handle()
        return {"handle": h, "mode": self.mode, "secrets": self._secrets_path() if h else None} if h else None

    def _save_resume_secrets(self):
        if self.mode in (None, "create") or self.phase not in RESUMABLE or not self.p.resume_handle():
            return
        path = self._secrets_path()
        if not path:
            return
        os.makedirs(os.path.dirname(path), mode=0o700, exist_ok=True)
        fd = os.open(path + ".tmp", os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        with os.fdopen(fd, "w") as fh:
            json.dump({"secrets": self.secrets}, fh)
        os.replace(path + ".tmp", path)

    def _previous_proof(self):
        """(path, proof) of the attempt before this one: the newest proof.before-attempt-N.json, else proof.json."""
        def n(p):
            m = re.search(r"proof\.before-attempt-(\d+)\.json$", p)
            return int(m.group(1)) if m else -1
        paths = sorted(glob.glob(os.path.join(self.out, "proof.before-attempt-*.json")), key=n)
        for p in ([paths[-1]] if paths else []) + [os.path.join(self.out, "proof.json")]:
            try:
                with open(p, encoding="utf-8") as fh:
                    return p, json.load(fh)
            except (OSError, ValueError):
                continue
        return None, None

    def _resume_plan(self):
        """The resume plan, or None (logged why) when the lane starts fresh."""
        if os.environ.get("REL_TRUST_RESUME") != "1":
            return None
        path, prev = self._previous_proof()
        ph = (prev or {}).get("phases") or {}
        point = (prev or {}).get("resume") or {}
        failed, why, secrets = ph.get("failed"), None, None
        if not prev:
            why = "no proof of a previous attempt in %s" % self.out
        elif ((prev.get("fault") or {}).get("kind")) == "product":
            why = "the previous attempt ended on a product fault (a result, not resumed)"
        elif failed not in RESUMABLE:
            why = "the previous attempt failed in %s, not after the previous release's wallet was made (%s)" % (
                failed or "no phase", ", ".join(RESUMABLE))
        elif "previous" not in (ph.get("done") or []):
            why = "the previous attempt never opened the previous release's wallet"
        elif not point.get("handle"):
            why = "the previous attempt left no state to resume from (%s)" % self.p.name
        else:
            secrets, why = self._read_resume_secrets(point.get("secrets"))
            if why is None:
                ok, what = self.p.resume_from(point["handle"])
                why = None if ok else what
        if why:
            self.log("RESUME: starting fresh: %s" % why)
            self.details["resume"] = {"resumed": False, "why": why}
            return None
        self.log("RESUME: from %s, at phase %s (%s)" % (os.path.basename(path), failed, what))
        return {"failed": failed, "mode": point.get("mode"), "secrets": secrets, "proof": prev, "from": os.path.basename(path)}

    def _read_resume_secrets(self, path):
        if not path or path != self._secrets_path_for(path):
            return None, "no resume secrets were kept"
        try:
            with open(path, encoding="utf-8") as fh:
                got = json.load(fh).get("secrets") or {}
        except (OSError, ValueError, AttributeError):
            return None, "the resume secrets %s cannot be read" % path
        try:
            os.remove(path)   # read once
        except OSError:
            pass
        return got, None

    def _secrets_path_for(self, path):
        """The kept path, when it is a resume file outside REL_OUT (a proof's path is not trusted blindly)."""
        p = os.path.abspath(path)
        if os.path.basename(p) != "lane-resume.json" or (p + os.sep).startswith(os.path.abspath(self.out) + os.sep):
            return None
        return path

    def _resume(self, plan):
        """The previous release opened on the failed attempt's state; the phases before the failed one
        skipped, the checks they passed kept. -> truthy when the state came from a saved state (no seed phase)."""
        self.resumed = plan
        mode = plan["mode"]
        if mode == "seed":
            seed = ls.LaneSeed(ls.lane_name(self.p.name, self.p.variant))
            if not seed.exists():
                raise HarnessFault("start", "resume in seed mode but lane %s has no seed" % seed.lane)
            self._seed_mode(seed)
            self.seed.lock()
        else:
            self.mode = mode
        self.secrets = dict(plan["secrets"])
        prev = plan["proof"]
        kept = {c: True for c, v in (prev.get("checks") or {}).items() if v is True}
        self.results.update(kept)
        for c in kept:
            if c in (prev.get("details") or {}):
                self.details[c] = prev["details"][c]
        self.details["resume"] = {"resumed": True, "from": plan["from"], "at": plan["failed"], "checks_kept": sorted(kept)}
        for name in [p for p in (prev.get("phases") or {}).get("done", []) if p not in ("prepare",)]:
            self.skip_phase(name, "done in the previous attempt")
        self.run_phase("previous-open", lambda: self._open("previous"))
        if plan["failed"] == "previous-setup":
            self.run_phase("previous-setup", self._setup)
        return mode == "state"

    def _resumed_past(self, name):
        """True when a resume started after phase `name` (it was done in the previous attempt)."""
        if not self.resumed:
            return False
        return name in RESUMABLE and RESUMABLE.index(name) < RESUMABLE.index(self.resumed["failed"])

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
        self._wallet_put("the lane seed restored on the previous release")

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
        self._wallet_put("created on the candidate with no app data", phrase=phrase)
        if not phrase:
            return False, "none read off the screen"
        self.needles = ls.Needles([phrase])
        res = ls.validate(phrase)
        del phrase
        return res
