# SPDX-License-Identifier: Apache-2.0
"""One G4 update-trust lane, the same on every platform: a user on the previous release updates to
the candidate and keeps their wallet, money, history, servers and settings, then receives and sends.

The lane is a list of phases. A platform (linux/platform.py, android/platform.py,
windows/platform.py) supplies what differs: how the app is installed, started, stopped and updated,
how its files are read, and a Surface for its UI. The UI steps are the family's recipe
(core/desktop.py for Linux and Windows, core/phone.py for Android), written once on targets.
The checks (core/checks.py) compare what the wallet's own files hold before and after, never what a
screen was scraped for.

Start modes (REL_TRUST_START=auto|state|fresh, default auto): `state` restores the end state a
passing lane of the previous release saved (core/state.py), so the previous binary only starts,
unlocks, is funded and stopped; `fresh` creates the wallet and sets everything up on the previous
binary (the bootstrap for a previous release no lane has saved yet).

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


class Lane:
    def __init__(self, platform, recipe_for, checks, *, out, log, required, funds, p=None):
        """recipe_for(lane, which, surface) -> the family's recipe on a Driver over that surface, with the
        build's strings (core.labels) and the lane's one Recover (lane.rec)."""
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

    # ---- results

    def ok(self, check, why):
        self.results[check] = True
        self.details[check] = why
        self.log("PASS %s: %s" % (check, why))

    def fail(self, check, why):
        self.results[check] = False
        self.details[check] = why
        self.log("FAIL %s: %s" % (check, why))

    def proof(self, extra=None):
        p = {"platform": self.p.name, "variant": self.p.variant,
             "previous": os.environ.get("REL_PREVIOUS_VERSION"), "candidate": os.environ.get("REL_CANDIDATE_VERSION"),
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
                if self.ui is not None and name not in ("prepare", "restore", "install", "previous", "candidate", "update"):
                    # the app was started again: back to the wallet before the phase
                    self.ui.open_wallet(self.secrets, after_update=getattr(self.ui, "which", "") == "candidate")

    def main(self):
        code = 2
        try:
            code = self._main()
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
        if code == 0 and not all(self.results.get(c) for c in self.required):
            code = 1
        proof = self.proof()
        line = self.fault.line() if self.fault else (
            "PASS %s %s %s → %s%s" % (self.p.name, self.p.variant, proof["previous"], proof["candidate"],
                                      " (recovered: %s)" % ", ".join(r["step"] for r in self.rec.used) if self.rec.used else "")
            if code == 0 else "PRODUCT checks false: " + "; ".join(
                "%s (%s)" % (c, str(self.details.get(c, "not reached"))[:120]) for c in self.required if not self.results.get(c)))
        with open(os.path.join(self.out, "result.txt"), "w") as f:
            f.write(line + "\n")
        self.log("RESULT " + line)
        return code

    def _main(self):
        self.run_phase("prepare", self.p.prepare)
        saved = st.pick(self.p.name, self.p.variant, os.environ.get("REL_PREVIOUS_VERSION"),
                        fits=getattr(self.p, "fits", None), log=self.log)
        self.mode = "state" if saved else "fresh"
        self.log("start mode: %s%s" % (self.mode, " (%s)" % saved.folder if saved else ""))
        if saved:
            self.secrets = saved.secrets()
            self.run_phase("restore", lambda: self.p.restore_state(saved.payload))
            self.run_phase("previous", lambda: self._open("previous"))
        else:
            self.run_phase("install", self.p.install_previous)
            self.run_phase("previous", self._fresh)
        address = self.run_phase("address", lambda: self.ui.address())
        self.details["address"] = address[:8] + "…" + address[-6:] if address else None
        self.run_phase("fund", lambda: self.checks_mod.fund_before(self, address))
        before = self.run_phase("digest-before", lambda: self.p.digest("previous", self.secrets))
        if hasattr(self.checks_mod, "setup_took"):
            self.checks_mod.setup_took(self, before)
        self.run_phase("stop-previous", self.p.stop)
        if not saved:
            self.run_phase("seed", lambda: self.p.seed_previous_files(self.secrets))
        snap = self.run_phase("snapshot", self.p.files_snapshot)
        self.run_phase("update", self.p.update)
        self.run_phase("candidate", lambda: self._open("candidate"))
        after = self.run_phase("digest-after", lambda: self.checks_mod.settle(self, before))
        self.checks_mod.compare(self, before, after, snap)
        if self.funds:
            self.run_phase("funds", lambda: self.checks_mod.funds_legs(self, after))
        # a passing lane leaves its wallet for the next release (REL_TRUST_SAVE_STATE=0 for trial runs)
        if all(self.results.get(c) for c in self.required) and os.environ.get("REL_TRUST_SAVE_STATE", "1") != "0":
            self.run_phase("save-state", lambda: st.save(self.p, self.secrets, self.checks_mod.public(after), log=self.log))
        return 0

    def _open(self, which):
        surface = self.p.start(which)
        self.rec.build = os.environ.get("REL_%s_VERSION" % which.upper(), which)
        self.ui = self.recipe_for(self, which, surface)
        self.ui.open_wallet(self.secrets, after_update=(which == "candidate"))

    def _fresh(self):
        surface = self.p.start("previous")
        self.rec.build = os.environ.get("REL_PREVIOUS_VERSION", "previous")
        self.ui = self.recipe_for(self, "previous", surface)
        self.secrets.update(self.ui.create_wallet())
        self.ui.set_servers(self.p.node, self.p.custom_node, self.p.relay, self.p.custom_relay)
        self.ui.change_settings(self.checks_mod.WANT_SETTINGS)
