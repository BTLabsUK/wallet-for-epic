# SPDX-License-Identifier: Apache-2.0
"""Windows desktop for core/lane.py: the real release Setups on the rig (rig.py, agent.ps1), the app
run as the rig's user in its session 0 and read through UI Automation (uia.py).

The previous release's Setup installs silently into a run folder of its own (USERPROFILE =
<run>\\home: the per-user install and the data folder are there). The update is the candidate's
Setup started with the arguments the in-app update gives it (/SILENT /NORESTART /UPDATEFROMAPP=1);
Setup installs over the per-user install and opens the candidate itself. The wallet's data is read
from the rig's files (core/walletdata.py over Rig: wallet database copies, wallets.json, the DPAPI
desk store as the rig's user, settings.toml); the encrypted store of a migrating candidate is read
through the shared LEPIC CLI from copies of its files.

The hermetic node and relay on this host (core/hermetic.py plan) reach the rig's own 127.0.0.1 through
an ssh remote forward on the rig's ControlMaster (rig.py forward(): code and unit tests only, never run
on a rig yet; off unless REL_HERMETIC_WINDOWS=1, windows_env); for a server that is not offered, a loopback stand-in of a public one runs inside the rig
agent (agent.ps1). The stand-ins' ports are fixed when the agent has to be started again, so the
servers the wallet was given stay valid.
"""
import json
import os
import re
import socket
import ssl
import subprocess
import sys
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
DRIVERS = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, DRIVERS)
sys.path.insert(0, os.path.join(DRIVERS, "linux"))

import facts  # noqa: E402
import nodehealth  # noqa: E402
import seed  # noqa: E402
from core import checks  # noqa: E402
from core import hermetic  # noqa: E402
from core import walletdata as wd  # noqa: E402
from core.faults import HarnessFault, InfraFault, ProductFault  # noqa: E402
from core.lane import Platform  # noqa: E402
from rig import Rig, RigDead, RigError, candidate_sessions, describe, health, task_name, work_dir  # noqa: E402
from uia import WinSurface  # noqa: E402

AGENT_IDLE_MIN = 90
SSH_TRIES = 3   # the first try and two retries in place
HEALTH_S = 60   # the rig health check's limit: a sick rig ends the run on it
RUN_NAME = re.compile(r"^[A-Za-z0-9.?+-]+$")
APP_LANGUAGE = '{"language":"en"}'   # the desk.settings the rig user's store starts with (store_init)


def retry_ssh(rig, log, step=lambda: "rig"):
    """Every ssh and scp of the rig runs again in place when it times out (twice), then it is an
    InfraFault (sub ssh): the rig is unreachable, not the app wrong. Replaces the Rig's methods on the instance."""
    def wrap(name):
        inner = getattr(rig, name)

        def run(*a, **kw):
            for n in range(1, SSH_TRIES + 1):
                try:
                    return inner(*a, **kw)
                except subprocess.TimeoutExpired:
                    if n == SSH_TRIES:
                        raise InfraFault(step(), "ssh to %s timed out %d times" % (rig.host, SSH_TRIES), sub="ssh")
                    log("ssh to %s timed out (%s): trying again (%d of %d)" % (rig.host, name, n, SSH_TRIES - 1))
        return run
    for name in ("ssh", "put", "get"):
        setattr(rig, name, wrap(name))
    return rig


def windows_env(env=None):
    """The environment hermetic.plan reads here: off (the stand-ins) unless REL_HERMETIC_WINDOWS=1. The
    forward's first live run (26.11.0 run-4) left the node picker unreadable once the local node was in
    use, while the stand-ins path proved 26.10.26."""
    env = os.environ if env is None else env
    if env.get("REL_HERMETIC_WINDOWS") == "1":
        return env
    return dict(env, REL_HERMETIC="0")


class WindowsPlatform(Platform):
    name, family = "windows", "desktop"
    reads_settings_in_ui = True  # the encrypted store's confirmations are read on the Settings page (lane._ui_settings)
    update_method = ("the in-app update's own path: the candidate's published Setup is started with the arguments the app "
                     "gives it (/SILENT /NORESTART /UPDATEFROMAPP=1, plus /LOG), Setup installs over the previous release's "
                     "per-user install and opens the candidate itself. The lane has closed the previous app first (its "
                     "stop phase), where the in-app update closes it right after starting Setup. The download and "
                     "signature check before that are not part of it, nor the update-target mark the app writes first.")

    def __init__(self, out, log):
        e = os.environ
        self.out, self.log = out, log
        self.variant = e.get("REL_VARIANT") or "tor"
        self.prev_dir, self.prev_ver = e.get("REL_PREVIOUS_DIR", ""), e.get("REL_PREVIOUS_VERSION", "")
        self.cand_dir, self.cand_ver = e.get("REL_CANDIDATE_DIR", ""), e.get("REL_CANDIDATE_VERSION", "")
        self.create = e.get("REL_TRUST_MODE") == "create"   # the create-wallet test: the candidate alone
        self.host = e.get("REL_WIN_HOST") or "windows-pc"
        self.node, self.relay = e.get("REL_NODE", ""), e.get("REL_EPICBOX", "")
        self.custom_node = self.custom_relay = None
        self.lan_before = None
        stamp = time.strftime("%Y%m%d-%H%M%S")
        self.name_run = "%s-%s-to-%s-%s" % (self.variant, self.prev_ver or "?", self.cand_ver or "?", stamp)
        self.work_root = e.get("REL_WORK") or os.path.join(os.path.expanduser("~"), ".cache", "rel-trust-windows")
        self.work = os.path.join(self.work_root, self.name_run)
        self.rig = None
        self.surface = None
        self.running = None     # 'previous' | 'candidate' while an app runs
        self.exe = None         # the installed app's exe
        self.entry = None
        self.ports = {}
        self.session = None     # the rig session a resume must use: the store opens for that user alone
        self.point_saved = False
        self.hermetic = None    # core/hermetic.py plan(), from prepare
        self.step = "rig"       # the rig op in hand, for an InfraFault's step

    # ---- preparation

    def setup_exe(self, folder, version):
        sfx = "-notor" if self.variant == "notor" else ""
        for name in ("bt-wallet", "epic-cash-desktop"):
            exact = os.path.join(folder, "%s-%s%s-windows-x64-setup.exe" % (name, version, sfx))
            if os.path.isfile(exact):
                return exact
        rx = re.compile(r"^(?:bt-wallet|epic-cash-desktop)-[\d.]+%s-windows-x64-setup\.exe$" % sfx)
        hits = sorted(f for f in os.listdir(folder) if rx.match(f)) if os.path.isdir(folder) else []
        if len(hits) == 1:
            return os.path.join(folder, hits[0])
        raise HarnessFault("prepare", "no %s Windows Setup for %s in %s" % (self.variant, version, folder))

    def prepare(self):
        prev = None if self.create else self.setup_exe(self.prev_dir, self.prev_ver)
        cand = self.setup_exe(self.cand_dir, self.cand_ver)
        os.makedirs(self.work, mode=0o700, exist_ok=True)
        self.log("previous %s, candidate %s" % (os.path.basename(prev) if prev else "none (create)", os.path.basename(cand)))
        self._healthy_rig(prev, cand)
        self.hermetic = hermetic.plan(checks.P_ADDR, env=windows_env())
        self.log("hermetic: %s" % self.hermetic["reason"])
        self._pick_servers()
        self._servers()
        self.surface = WinSurface(self.rig, self.log, secret_dir=self.work, app_log=self.data + "\\logs\\wfe.log")

    def _servers(self, again=False):
        """The local services forwarded to the rig (once per master; asked again after a recovery), and
        the agent's stand-ins for what is not local, skipped when both are (on the same ports again)."""
        plan = self.hermetic or {}
        try:
            self.rig.forward(plan.get("ports") or [])
        except RigError as e:
            raise HarnessFault("recover" if again else "prepare", "the local node/relay forward to the rig: %s" % e)
        if plan.get("node"):
            self.custom_node = hermetic.entry(plan["node"])
        if plan.get("relay"):
            self.custom_relay = plan["relay"]
        if plan.get("node") and plan.get("relay"):
            return
        r = self.rig.call("standins", node=self.node, relay=self.relay,
                          node_port=self.ports.get("node", 0), relay_port=self.ports.get("relay", 0))
        if not r.get("ok"):
            raise HarnessFault("recover" if again else "prepare", "stand-ins on the rig: %s" % (r.get("error") or "")[:160])
        # the agent starts both; the one for a local server is not given to the app
        self.ports = {"node": r["node"], "relay": r["relay"]}
        if not plan.get("node"):
            self.custom_node = "127.0.0.1:%d" % r["node"]
        if not plan.get("relay"):
            self.custom_relay = "127.0.0.1:%d" % r["relay"]
        self.log("on the rig: node %s -> %s, relay %s -> %s" % (self.custom_node, self.node, self.custom_relay, self.relay))

    def live_servers(self):
        """The public node and relay the live-servers phase puts in use (core/lane.py)."""
        return hermetic.pick_live(node_up, relay_up, nodehealth.synced_first(facts.NODE_PICK, log=self.log), facts.RELAY_PICK)

    def _pick_servers(self):
        plan = self.hermetic or {}
        if plan.get("node"):
            self.node = plan["node"]
        elif not self.node:
            self.node = next((u for u in facts.NODE_PICK if node_up(u)), "")
        if plan.get("relay"):
            self.relay = plan["relay"]
        elif not self.relay:
            self.relay = next((h for h in facts.RELAY_PICK if relay_up(h)), "")
        if not self.node or not self.relay:
            raise HarnessFault("prepare", "no node or Epicbox server answers (%s / %s)" % (facts.NODE_PICK, facts.RELAY_PICK))
        if "://" not in self.node:
            self.node = "https://" + self.node

    def _healthy_rig(self, prev, cand):
        """The first thing a run does with the rig: the variant's rig session, or the next healthy one when it
        is dead (rig.candidate_sessions); a rig that does not say it is healthy ends the run here as infra."""
        sessions = candidate_sessions(self.variant) if self.session is None else [self.session]
        try:
            report = health(self.host, sessions, timeout=HEALTH_S)
        except (RigError, OSError, ValueError, subprocess.SubprocessError) as e:
            raise InfraFault("prepare", "the rig health check on %s did not answer: %s" % (self.host, e), sub="rig")
        dead = []
        for k in sessions:
            probs = report.get(k, (None, []))[1]
            if probs:
                dead.append((k, probs))
                self.log("DEAD %s" % describe(k, probs))
                continue
            self.rig = Rig(self.host, self.name_run, self.log,
                           os.path.join(os.path.expanduser("~"), ".cache", "rel-trust-windows", "ctl"), session=k)
            retry_ssh(self.rig, self.log, lambda: self.step)
            try:
                self.rig.prepare()
                self.rig.stop_orphans()   # a killed run's agent would hold the rig until its idle limit
                if prev:
                    self.rig.put(prev, self.rig.run + "\\prev-setup.exe")
                self.rig.put(cand, self.rig.run + "\\cand-setup.exe")
                waiting = self.rig.busy()
                if waiting:
                    self.log("the rig queue has %d job(s) before ours" % waiting)
                self.rig.start_agent(idle_min=AGENT_IDLE_MIN, wait_s=1800 if waiting else 420, waiting=waiting)
            except RigDead as e:
                dead.append((k, [str(e)]))
                self.log("DEAD %s" % e)
                self.rig.close()
                self.rig = None
                continue
            break
        if dead:
            self._alert_dead(dead, self.rig.session if self.rig else None)
        if not self.rig:
            raise InfraFault("prepare", "no healthy Windows rig: %s" % " | ".join(describe(k, p) for k, p in dead), sub="rig")
        self.log("rig session %d (%s), run folder %s" % (self.rig.session, task_name(self.rig.session), self.rig.run))

    def _alert_dead(self, dead, used):
        """One message to the owner naming the dead rig(s) (REL_OUT/notice.json: the release tool forwards it)."""
        names = ", ".join("rig %d" % k for k, _ in dead)
        notice = {
            "title": "Windows %s dead: %s" % (names, "this run used rig %d" % used if used else "no healthy rig left"),
            "detail": "\n".join(describe(k, p) for k, p in dead),
            "expects": "fix the rig (wintest-rig scripts\\setup-test-user.ps1, elevated), or point [host.windows] rigs "
                       "in release-hosts.toml at a healthy one",
        }
        with open(os.path.join(self.out, "notice.json"), "w", encoding="utf-8") as f:
            json.dump(notice, f, indent=2)
        self.log("ALERT %s" % notice["title"])

    @property
    def data(self):
        return self.rig.run + "\\home\\.epic_cash_desktop"

    def _call(self, op, timeout=120, **kw):
        self.step = op
        return self.surface._call(op, timeout=timeout, **kw)

    # ---- install and the app

    def install_previous(self):
        self._install("previous", "prev-setup.exe")
        self._init_store()

    def install_candidate_fresh(self):
        """The create-wallet test's fresh install: the candidate's Setup, silent, on a rig user without the app."""
        self._install("candidate", "cand-setup.exe")
        self._init_store()

    def _init_store(self):
        """The app's secret store on a rig user that has none, holding only the English language setting, so the
        first start shows English whatever the Windows display language is (agent.ps1 store_init; it refuses an
        existing store). The language stays through the update and the seed (seed.desk_settings keeps every key)."""
        r = self._call("store_init", file=self.data + "\\flutter_secure_storage.dat", set={"desk.settings": APP_LANGUAGE})
        if not r.get("ok"):
            raise HarnessFault("install", "the English language setting could not be put in the app's store: %s" % (r.get("error") or "")[:200])
        self.log("the app's store holds desk.settings %s: the app starts in English" % APP_LANGUAGE)

    def _install(self, which, setup):
        e = self._call("entry").get("entry")
        if e:
            e = self._clear_leftover(e)
        r = self._call("setup", exe=self.rig.run + "\\" + setup, timeout=400, wait_s=300,
                       args=["/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART", "/LOG=%s\\setup-%s.log" % (self.rig.run, which)])
        if not r.get("ok"):
            raise HarnessFault("install", "the %s release's Setup failed: %s" % (which, r.get("error") or "exit %s" % r.get("exit")))
        self.entry = r["entry"]
        self.exe = installed_exe(self.entry)
        self.log("%s installed: %s at %s" % (which, self.entry.get("version"), self.entry.get("location")))

    def _clear_leftover(self, e):
        """An install of this run's own earlier attempt (under <runs>\\<variant>-<prev>-to-<cand>-<time>, a crashed run's
        folder) is uninstalled; any other install is not ours and stays: an InfraFault (leftover)."""
        text = "%s already has %s installed (%s at %s): left alone" % (
            self.rig.user, e.get("name") or "BT Wallet", e.get("version"), e.get("location"))
        prefix = "-".join(self.name_run.split("-")[:-2])   # variant-prev-to-cand, without the date and time
        if not run_folder_of(e.get("location"), self.rig.base + "\\runs\\", prefix):
            raise InfraFault("install", text, sub="leftover")
        self.log("leftover install of an earlier attempt of this run (%s at %s): uninstalling it" % (e.get("version"), e.get("location")))
        r = self._call("uninstall_leftover", timeout=300, prefix=prefix)
        left = self._call("entry").get("entry")
        if not r.get("ok") or left:
            raise InfraFault("install", "%s; uninstalling it failed: %s" % (text, (r.get("error") or "exit %s" % r.get("exit"))[:160]), sub="leftover")
        self.log("leftover install removed")
        return None

    def _procs(self):
        return self._call("procs").get("procs") or []

    def start(self, which):
        """The app running and its window up: started now, or found running (the candidate, opened by
        its Setup; either after recover())."""
        if not any(p.split(" ")[0] in ("btwallet", "epic_wallet") for p in self._procs()):
            if not self.exe:
                raise HarnessFault("start", "no installed app to start")
            r = self._call("start", exe=self.exe)
            if not r.get("ok"):
                raise HarnessFault("start", "the %s app did not start: %s" % (which, (r.get("error") or "")[:160]))
        r = self._call("window", wait_s=90, timeout=150)
        if not r.get("ok"):
            raise HarnessFault("start", "the %s app has no window after 90 s (processes: %s)" % (which, r.get("procs")))
        self.running = which
        self.log("%s app up: %s" % (which, r.get("procs")))
        return self.surface

    def stop(self):
        """The window closed as a user closes it (WM_CLOSE)."""
        if self._procs():
            r = self._call("close", wait_s=60, timeout=90)
            if not r.get("ok") and self._procs():
                raise HarnessFault("stop", "the app did not quit after its window was closed: %s" % (r.get("error") or "")[:120])
        self.running = None

    def update(self):
        if self.running:
            self.stop()
        self.log("update: %s" % self.update_method)
        r = self._call("setup", exe=self.rig.run + "\\cand-setup.exe", wait=False,
                       args=["/SILENT", "/NORESTART", "/UPDATEFROMAPP=1", "/LOG=%s\\setup-candidate.log" % self.rig.run])
        self.log("candidate Setup started (pid %s)" % r.get("pid"))
        w = self._call("wait_exit", pid=r["pid"], wait_s=300, timeout=360)
        self.log("candidate Setup exited: %s" % w)
        if not w.get("exited"):
            raise ProductFault("update", "the candidate's Setup did not finish in 5 min")
        if w.get("exit") not in (0, None):
            raise ProductFault("update", "the candidate's Setup exited with code %s (log setup-candidate.log)" % w.get("exit"))
        e = self._call("entry").get("entry") or {}
        self.entry = e
        if e.get("exe"):
            self.exe = installed_exe(e)  # btwallet.exe from 26.10.25, whatever the previous release ran
        self.log("uninstall entry now %s %s at %s" % (e.get("name"), e.get("version"), e.get("location")))
        if self.cand_ver and not str(e.get("version") or "").startswith(self.cand_ver.split("-")[0]):
            raise ProductFault("update", "after the candidate's Setup the installed version is %s, not %s" % (e.get("version"), self.cand_ver))
        end = time.time() + 120
        while time.time() < end:
            if self._procs():
                self.running = "candidate"
                return
            time.sleep(3)
        raise ProductFault("update", "Setup did not open the candidate within 2 min")

    def recover(self):
        """The rig agent (its stand-ins and the app with it) went: queued again, the stand-ins on the same
        ports, the app that ran started again."""
        r = self.rig.call("ping", timeout=60)
        if not r.get("ok"):
            self.log("recover: the rig agent does not answer; starting it again")
            try:
                self.rig.start_agent(idle_min=AGENT_IDLE_MIN, wait_s=1800 if self.rig.busy() else 420)
            except RigError as e:
                raise HarnessFault("recover", "the rig agent could not be started again: %s" % e)
            self._servers(again=True)
        which = self.running
        if which:
            self.start(which)

    # ---- resume (core/lane.py): from the point only; the failed attempt's rig folder and rig user, its stand-in
    # ports in the wallet's settings. Its shutdown uninstalled the app, so the previous release goes on again.

    def resume_dir(self):
        return os.path.join(self.work_root, ".resume-%s" % self.variant)

    def resume_handle(self):
        if not self.point_saved:
            return None
        return {"session": self.rig.session, "run": self.name_run, "ports": dict(self.ports)}

    def resume_from(self, handle):
        h = handle or {}
        run, prefix = str(h.get("run") or ""), "-".join(self.name_run.split("-")[:-2])
        if not RUN_NAME.match(run) or "-".join(run.split("-")[:-2]) != prefix:
            return False, "the failed attempt's run %r is not an earlier attempt of %s" % (run, prefix)
        if not isinstance(h.get("session"), int):
            return False, "the failed attempt names no rig session"
        self.name_run, self.session = run, h["session"]
        self.work = os.path.join(self.work_root, run)
        self.ports = {k: int(v) for k, v in (h.get("ports") or {}).items() if v}
        return True, "rig session %d, run folder %s, stand-in ports %s" % (self.session, run, self.ports or "none")

    def _point(self):
        return self.rig.run + "\\point"

    def _copy_tree(self, frm, to, step):
        r = self._call("copy_tree", timeout=300, **{"from": frm, "to": to})
        if not r.get("ok"):
            raise HarnessFault(step, "the app's data folder was not copied: %s" % (r.get("error") or "")[:160])

    def save_point(self):
        if self.running:
            self.stop()
        self._copy_tree(self.data, self._point(), "resume-point")
        self.point_saved = True
        self.log("the closed app's data folder kept in %s" % self._point())
        return True

    def load_point(self):
        self._install("previous", "prev-setup.exe")
        self._copy_tree(self._point(), self.data, "point-load")
        self.point_saved = True   # still on the rig: a resumed attempt that fails can be resumed too
        self.running = None
        self.log("the data folder from before the update is back in %s" % self.data)

    # ---- data

    def _files(self):
        return wd.rig_files(self.rig, self.data)

    def digest(self, tag, secrets):
        if self.running and not self.surface.alive():
            raise ProductFault("app_alive", "the %s app is not running any more when its data was read" % self.running)
        return wd.read(self._files(), secrets, migrate=checks.migrating()[0], nodes=[self.node], log=self.log)

    def files_snapshot(self):
        return wd.snapshot(self._files())

    def seed_previous_files(self, secrets):
        """While the previous release is closed and only when the candidate migrates a plain store: a
        contact, a note on the first transaction and the stand-in node's plain-http agreement, in the
        previous release's own files and format (seed.py), written by the agent as the rig's user."""
        if not checks.migrating()[1]:
            return
        files = self._files().listing()
        metas = [f for f in files if re.fullmatch(r"wallets/[^/]+/" + re.escape(facts.META_PLAIN), f)]
        dbs = [f for f in files if re.fullmatch(r"wallets/[^/]+/%s/%s" % (re.escape(facts.STORE_DIR), re.escape(facts.STORE_PLAIN)), f)]
        if len(metas) != 1 or len(dbs) != 1:
            raise HarnessFault("seed", "the previous release left %d %s and %d %s under wallets/ (one each expected)" % (
                len(metas), facts.META_PLAIN, len(dbs), facts.STORE_PLAIN))

        def win(rel):
            return self.data + "\\" + rel.replace("/", "\\")
        try:
            db = self.rig.fetch_db(win(dbs[0]), os.path.join(self.work, "db"), "seed-files")
            meta = seed.meta_note(self.rig.text(win(metas[0])), seed.first_tx_id(db))
            contacts = seed.contacts_json(self.rig.text(win(facts.CONTACTS_PLAIN)), checks.P_ADDR)
        except (seed.SeedError, OSError) as e:
            raise HarnessFault("seed", "seeding the previous release's contact and note: %s" % e)
        lan = seed.lan_nodes_json(["http://%s" % self.custom_node])
        for rel, text in ((metas[0], meta), (facts.CONTACTS_PLAIN, contacts), (facts.LAN_NODES_FILE, lan)):
            r = self._call("write_file", file=win(rel), text=text)
            if not r.get("ok"):
                raise HarnessFault("seed", "writing %s: %s" % (rel, (r.get("error") or "")[:120]))
        self.lan_before = self.rig.text(win(facts.LAN_NODES_FILE))
        self.log("seeded into the closed previous release: contact %r, a note, plain-http agreement for %s" % (
            seed.CONTACT["name"], self.custom_node))

    # ---- saved states (core/state.py): not on Windows yet

    def save_state(self, folder):
        raise HarnessFault("save-state", "saved end states are not built for Windows yet (REL_TRUST_SAVE_STATE=0)")

    def restore_state(self, folder):
        raise HarnessFault("restore", "saved end states are not built for Windows yet")

    def fits(self, meta):
        return False, "no saved states on Windows yet"

    # ---- end

    def logs(self):
        return {n: os.path.join(self.out, n) for n in ("wfe.log", "setup-previous.log", "setup-candidate.log", "agent.log", "standins.log")}

    def shutdown(self):
        if self.rig is None:
            return
        for op, kw in (("close", {"wait_s": 60}), ("stop_all", {}), ("uninstall", {})):
            try:
                r = self.rig.call(op, timeout=200, **kw)
                self.log("rig %s: %s" % (op, {k: v for k, v in r.items() if k != "entry"}))
            except Exception as e:  # noqa: BLE001
                self.log("rig %s: %s" % (op, e))
        try:
            self.rig.get(self.data + "\\logs\\wfe.log", os.path.join(self.out, "wfe.log"))
            for n in ("setup-previous.log", "setup-candidate.log", "agent.log", "standins.log"):
                self.rig.get(self.rig.run + "\\" + n, os.path.join(self.out, n))
        except Exception as e:  # noqa: BLE001
            self.log("logs: %s" % e)
        try:  # the typed-secret folder of the run, by its exact path
            self.rig.pwsh("Remove-Item -LiteralPath '%s\\secret' -Recurse -Force -ErrorAction SilentlyContinue" % self.rig.run, check=False)
        except Exception as e:  # noqa: BLE001
            self.log("secret folder not removed: %s" % e)
        self.rig.quit_agent()
        self.rig.close()
        self.log("rig: app uninstalled, agent stopped; the wallet's data folder stays in %s\\home" % self.rig.run)


def run_folder_of(location, runs, prefix):
    """True when `location` is inside `<runs><prefix>-<yyyymmdd>-<hhmmss>\\` (the run folder naming of
    WindowsPlatform.name_run): an earlier attempt of the same run."""
    rx = r"(?i)^%s%s-\d{8}-\d{6}\\" % (re.escape(runs), re.escape(prefix))
    return bool(re.match(rx, str(location or "")))


def installed_exe(entry):
    """The installed app's exe, from Setup's uninstall entry: its DisplayIcon names it (btwallet.exe from
    26.10.25, epic_wallet.exe before); an entry without one is taken as the old name."""
    icon = (entry.get("exe") or "").strip().strip('"')
    icon = re.sub(r",\s*-?\d+$", "", icon).strip('"')
    if icon.lower().endswith(".exe"):
        return icon
    return entry["location"].rstrip("\\") + "\\epic_wallet.exe"


def node_up(url):
    try:
        with urllib.request.urlopen(url.rstrip("/") + "/v1/status", timeout=10) as r:
            return r.status == 200 and b"tip" in r.read()
    except Exception:  # noqa: BLE001
        return False


def relay_up(host):
    """A WebSocket handshake with wss://host answered with 101."""
    h, _, port = host.partition(":")
    try:
        raw = socket.create_connection((h, int(port or 443)), timeout=10)
        s = ssl.create_default_context().wrap_socket(raw, server_hostname=h)
        s.sendall(("GET / HTTP/1.1\r\nHost: %s\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
                   "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n" % h).encode())
        ans = s.recv(200)
        s.close()
        return b" 101 " in ans
    except Exception:  # noqa: BLE001
        return False
