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

A loopback node and relay stand-in run inside the rig agent (agent.ps1); their ports are fixed when
the agent has to be started again, so the servers the wallet was given stay valid.
"""
import json
import os
import re
import socket
import ssl
import sys
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
DRIVERS = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.path.insert(0, DRIVERS)
sys.path.insert(0, os.path.join(DRIVERS, "linux"))

import facts  # noqa: E402
import seed  # noqa: E402
from core import checks  # noqa: E402
from core import walletdata as wd  # noqa: E402
from core.faults import HarnessFault, ProductFault  # noqa: E402
from core.lane import Platform  # noqa: E402
from rig import Rig, RigDead, RigError, candidate_sessions, describe, health, task_name, work_dir  # noqa: E402
from uia import WinSurface  # noqa: E402

AGENT_IDLE_MIN = 90


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
        work_root = e.get("REL_WORK") or os.path.join(os.path.expanduser("~"), ".cache", "rel-trust-windows")
        self.work = os.path.join(work_root, self.name_run)
        self.rig = None
        self.surface = None
        self.running = None     # 'previous' | 'candidate' while an app runs
        self.exe = None         # the installed app's exe
        self.entry = None
        self.ports = {}

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
        self._pick_servers()
        os.makedirs(self.work, mode=0o700, exist_ok=True)
        self.log("previous %s, candidate %s" % (os.path.basename(prev) if prev else "none (create)", os.path.basename(cand)))
        self._healthy_rig(prev, cand)
        r = self.rig.call("standins", node=self.node, relay=self.relay)
        if not r.get("ok"):
            raise HarnessFault("prepare", "stand-ins on the rig: %s" % (r.get("error") or "")[:160])
        self.ports = {"node": r["node"], "relay": r["relay"]}
        self.custom_node = "127.0.0.1:%d" % r["node"]
        self.custom_relay = "127.0.0.1:%d" % r["relay"]
        self.surface = WinSurface(self.rig, self.log, secret_dir=self.work)
        self.log("stand-ins on the rig: node %s -> %s, relay %s -> %s" % (self.custom_node, self.node, self.custom_relay, self.relay))

    def _pick_servers(self):
        if not self.node:
            self.node = next((u for u in facts.NODE_PICK if node_up(u)), "")
        if not self.relay:
            self.relay = next((h for h in facts.RELAY_PICK if relay_up(h)), "")
        if not self.node or not self.relay:
            raise HarnessFault("prepare", "no node or Epicbox server answers (%s / %s)" % (facts.NODE_PICK, facts.RELAY_PICK))
        if "://" not in self.node:
            self.node = "https://" + self.node

    def _healthy_rig(self, prev, cand):
        """The variant's rig session, or the next healthy one when it is dead (rig.candidate_sessions)."""
        sessions = candidate_sessions(self.variant)
        try:
            report = health(self.host, sessions)
        except (RigError, OSError, ValueError) as e:  # an unanswered health check never blocks the run
            self.log("rig health not read (%s): trying rig session %d as configured" % (e, sessions[0]))
            report = {}
        dead = []
        for k in sessions:
            probs = report.get(k, (None, []))[1]
            if probs:
                dead.append((k, probs))
                self.log("DEAD %s" % describe(k, probs))
                continue
            self.rig = Rig(self.host, self.name_run, self.log,
                           os.path.join(os.path.expanduser("~"), ".cache", "rel-trust-windows", "ctl"), session=k)
            try:
                self.rig.prepare()
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
            raise HarnessFault("prepare", "no healthy Windows rig: %s" % " | ".join(describe(k, p) for k, p in dead))
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
        return self.surface._call(op, timeout=timeout, **kw)

    # ---- install and the app

    def install_previous(self):
        self._install("previous", "prev-setup.exe")

    def install_candidate_fresh(self):
        """The create-wallet test's fresh install: the candidate's Setup, silent, on a rig user without the app."""
        self._install("candidate", "cand-setup.exe")

    def _install(self, which, setup):
        e = self._call("entry").get("entry")
        if e:
            raise HarnessFault("install", "%s already has %s installed (%s at %s): left alone" % (
                self.rig.user, e.get("name") or "BT Wallet", e.get("version"), e.get("location")))
        r = self._call("setup", exe=self.rig.run + "\\" + setup, timeout=400, wait_s=300,
                       args=["/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART", "/LOG=%s\\setup-%s.log" % (self.rig.run, which)])
        if not r.get("ok"):
            raise HarnessFault("install", "the %s release's Setup failed: %s" % (which, r.get("error") or "exit %s" % r.get("exit")))
        self.entry = r["entry"]
        self.exe = installed_exe(self.entry)
        self.log("%s installed: %s at %s" % (which, self.entry.get("version"), self.entry.get("location")))

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
        time.sleep(2)

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
            s = self.rig.call("standins", node=self.node, relay=self.relay,
                              node_port=self.ports.get("node", 0), relay_port=self.ports.get("relay", 0))
            if not s.get("ok"):
                raise HarnessFault("recover", "stand-ins again: %s" % (s.get("error") or "")[:160])
        which = self.running
        if which:
            self.start(which)

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

    # ---- break tests (core/breaks.py)

    def break_kill(self):
        """The rig agent quits: the app, the stand-ins and the session's agent go, as when the rig's job dies."""
        self.rig.call("quit", timeout=60)

    def break_freeze(self, on):
        script = ("Add-Type -Namespace N -Name S -MemberDefinition '[DllImport(\"ntdll.dll\")] public static extern int NtSuspendProcess(IntPtr h); "
                  "[DllImport(\"ntdll.dll\")] public static extern int NtResumeProcess(IntPtr h);'; "
                  "Get-Process btwallet, epic_wallet -ErrorAction SilentlyContinue | Where-Object { $_.Path -like '%s\\*' } | "
                  "ForEach-Object { [N.S]::%s($_.Handle) | Out-Null }" % (self.rig.run, "NtSuspendProcess" if on else "NtResumeProcess"))
        self.rig.as_owner(script)

    def break_lose_node(self):
        """The custom node's line goes from the closed previous release's settings.toml (written back by
        the agent, as the rig's user)."""
        path = self.data + "\\" + facts.SETTINGS_TOML
        text = self.rig.text(path)
        if text is None:
            raise HarnessFault("break", "lose-node needs the previous release's settings.toml")
        lines = text.splitlines(keepends=True)
        kept = [ln for ln in lines if self.custom_node not in ln]
        if len(kept) == len(lines):
            raise HarnessFault("break", "lose-node: %s is not in settings.toml" % self.custom_node)
        r = self._call("write_file", file=path, text="".join(kept))
        if not r.get("ok"):
            raise HarnessFault("break", "lose-node: writing settings.toml: %s" % (r.get("error") or "")[:120])
        self.log("BREAK: the custom node %s removed from the closed wallet's settings.toml" % self.custom_node)

    def break_lose_balance(self):
        files = self._files().listing()
        dbs = [f for f in files if re.fullmatch(r"wallets/[^/]+/%s/%s" % (re.escape(facts.STORE_DIR), re.escape(facts.STORE_PLAIN)), f)]
        if len(dbs) != 1:
            raise HarnessFault("break", "lose-balance needs one plain %s (found %d)" % (facts.STORE_PLAIN, len(dbs)))
        import sqlite3
        remote = self.data + "\\" + dbs[0].replace("/", "\\")
        local = self.rig.fetch_db(remote, os.path.join(self.work, "db"), "break")
        c = sqlite3.connect(local)
        try:
            n = c.execute("delete from outputs").rowcount
            c.commit()
            c.execute("pragma wal_checkpoint(truncate)")
        finally:
            c.close()
        self.rig.put(local, self.rig.run + "\\break-wallet.sqlite3")
        self._call("put_db", **{"from": self.rig.run + "\\break-wallet.sqlite3", "to": remote})
        self.log("BREAK: %d outputs deleted from the closed wallet's database" % n)

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
