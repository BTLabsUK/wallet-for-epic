#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""G4 update trust on Windows: a user on the previous release updates to the candidate the way the
in-app updater does it and keeps everything. Called by ../trust-windows.sh with the REL_* environment
(see there).

Runs on the Windows rig (rig.py, agent.ps1): the previous release's Setup installs silently as
epicrig into a run folder of its own (USERPROFILE = <run>\\home, so the per-user install and the data
folder are there). The real app is driven blind (posted clicks and plain keys; the click map is the
app's layout at the rig's 803x691 window, taken from the same releases on Linux) and every step is
checked in the app's own files, because nothing on the screen can be read there: UIA is off in
Flutter's Windows engine, the MSAA root fails, captures are one colour.

The wallet and the user's own node and Epicbox server go through the release's screens (the server
lists are where #143 broke); the simple settings (theme, Technical details, label, confirmations) are
seeded into its own files while it is closed (../seed.py) and must read back after it reopens.

What is read, before and after: the wallet's own database (wallet.sqlite3: outputs and transactions,
minimum confirmations), wallets.json (wallet id, label, folder, fingerprints), the desk store
(flutter_secure_storage.dat, DPAPI; settings keys only, read by the agent as epicrig), the
candidate's settings.toml (servers, the first in use), wfe.log (wallet opened, slates, which Epicbox
server the listener subscribed to) and the data folder's file list.
"""
import base64
import datetime
import decimal
import importlib.util
import json
import os
import re
import secrets
import sqlite3
import sys
import time
import traceback
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
LINUX = os.path.join(os.path.dirname(HERE), "linux")
sys.path.insert(0, HERE)
sys.path.insert(0, LINUX)
sys.path.insert(0, os.path.dirname(HERE))
from p_funder import P  # noqa: E402
from rig import Rig, RigError  # noqa: E402
import seed  # noqa: E402

_spec = importlib.util.spec_from_file_location("linux_trust", os.path.join(LINUX, "trust.py"))
lt = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(lt)  # helpers only: node_up, relay_up, short, sha256, num

CHECKS = lt.CHECKS
NODE_PICK = lt.NODE_PICK
RELAY_PICK = lt.RELAY_PICK
P_STALL_S = 240  # answered, not finalized this long: restart P's listener. Never sooner: its finalize waits until the node
#                 shows the tx in its mempool, 37 s or ~200 s (Dandelion embargo), and a kill then strands it
FUND_IN = "0.03"
FUND_AFTER = "0.01"
CAP_SEND = decimal.Decimal("0.05")
CAP_JOB = decimal.Decimal("1")
NANO = decimal.Decimal(100000000)
D = decimal.Decimal

# Virtual keys (plain keys only: a posted Ctrl or Shift does not count in Flutter)
TAB, ENTER, SPACE, ESC = 0x09, 0x0D, 0x20, 0x1B

# The click map: client pixels in the rig's 803x691 window (the icon rail under 1000 px). Taken from
# the same releases on Linux at 800x700: top-left anchored points as they are, right-anchored +3 x,
# bottom-anchored -9 y.
CLIENT = (803, 691)
RAIL = {"overview": (36, 82), "activity": (36, 127), "send": (36, 217), "receive": (36, 262), "settings": (36, 326)}
COPY_ADDRESS = (487, 285)       # Receive: copy the Epicbox address
SEND_TO, SEND_MAX, SEND_REVIEW = (380, 433), (716, 557), (705, 655)


class CannotRun(Exception):
    """The driver could not get to the point of checking (exit 2)."""


class Run:
    def __init__(self):
        e = os.environ
        self.out = os.path.abspath(e.get("REL_OUT") or ".")
        self.dry = e.get("REL_DRY_RUN") == "1"
        self.variant = e.get("REL_VARIANT", "tor")
        self.prev_dir = e.get("REL_PREVIOUS_DIR", "")
        self.prev_ver = e.get("REL_PREVIOUS_VERSION", "")
        self.cand_dir = e.get("REL_CANDIDATE_DIR", "")
        self.cand_ver = e.get("REL_CANDIDATE_VERSION", "")
        self.funds = e.get("REL_FUNDS", "1") == "1"
        default = CHECKS if self.funds else [c for c in CHECKS if c not in ("send_ok", "receive_ok")]
        self.required = [c.strip() for c in (e.get("REL_CHECKS") or ",".join(default)).split(",") if c.strip()]
        self.keep_funds = e.get("REL_KEEP_FUNDS") == "1"
        self.node = e.get("REL_NODE", "")
        self.relay = e.get("REL_EPICBOX", "")
        self.host = e.get("REL_WIN_HOST") or "windows-pc"
        self.picked = []
        stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        self.name = "%s-%s-to-%s-%s" % (self.variant, self.prev_ver, self.cand_ver, stamp)
        work_root = e.get("REL_WORK") or os.path.join(os.path.expanduser("~"), ".cache", "rel-trust-windows")
        self.work = os.path.join(work_root, self.name)
        self.p = P(e.get("REL_P_TOOL") or os.path.expanduser("/tmp/epic-build/interop/epicpay/p.py"),
                   e.get("REL_P_PASS_FILE") or os.path.expanduser("~/.config/btlabs/p-pass-candidates"),
                   int(e.get("REL_P_PASS_LINE") or "1"),
                   e.get("REL_P_LOCK") or os.path.expanduser("/opt/epic/qa-funder/.rel-lock"),
                   self.out, self.log)
        self.p_addr = e.get("REL_P_ADDR") or "esa57kJmWkZyX8fSkKPW2Gu12ENhFF6MXfdsrsY4gqVK58ZwzB4d@epicbox.stackwallet.com"
        self.checks = {c: False for c in CHECKS}
        self.details = {}
        self.spent = D(0)
        self.rig = None
        self.snap_n = 0
        self.log_mark = 0
        self.setup_address = None
        self.update_method = (
            "the in-app update's own path: with the previous release open and unlocked, the candidate's published "
            "Setup is started with the arguments the app gives it (/SILENT /NORESTART /UPDATEFROMAPP=1, plus /LOG), "
            "the app is closed (it quits right after starting Setup); Setup waits for it, installs over the per-user "
            "install and opens the candidate itself. The download and signature check before that are not part of "
            "it, nor the update-target mark the app writes first.")

    # ---- output

    def log(self, s):
        line = "%s %s" % (datetime.datetime.now().strftime("%H:%M:%S"), s)
        print(line, flush=True)
        with open(os.path.join(self.out, "trust.log"), "a") as f:
            f.write(line + "\n")

    def fail(self, check, why):
        self.checks[check] = False
        self.details[check] = why
        self.log("FAIL %s: %s" % (check, why))

    def ok(self, check, why):
        self.checks[check] = True
        self.details[check] = why
        self.log("ok   %s: %s" % (check, why))

    def proof(self):
        doc = {
            "platform": "windows", "variant": self.variant,
            "previous": self.prev_ver, "candidate": self.cand_ver,
            "node": self.node, "epicbox": self.relay,
            "update_method": self.update_method,
            "checks": self.checks, "details": self.details,
        }
        tmp = os.path.join(self.out, "proof.json.tmp")
        with open(tmp, "w") as f:
            json.dump(doc, f, indent=2)
            f.write("\n")
        os.replace(tmp, os.path.join(self.out, "proof.json"))

    # ---- preparation

    def setup_exe(self, folder, version):
        sfx = "-notor" if self.variant == "notor" else ""
        exact = os.path.join(folder, "epic-cash-desktop-%s%s-windows-x64-setup.exe" % (version, sfx))
        if os.path.isfile(exact):
            return exact
        # a rebuild keeps the version in the file name (26.10.24-r2 ships ...-26.10.24-...)
        rx = re.compile(r"^epic-cash-desktop-[\d.]+%s-windows-x64-setup\.exe$" % sfx)
        hits = sorted(f for f in os.listdir(folder) if rx.match(f)) if os.path.isdir(folder) else []
        if len(hits) == 1:
            return os.path.join(folder, hits[0])
        raise CannotRun("no %s Windows Setup for %s in %s" % (self.variant, version, folder))

    def pick_servers(self):
        if not self.node:
            self.node = next((u for u in NODE_PICK if lt.node_up(u)), "")
            self.picked.append("node picked by the driver: %s" % (self.node or "none answered"))
        if not self.relay:
            self.relay = next((h for h in RELAY_PICK if lt.relay_up(h)), "")
            self.picked.append("Epicbox picked by the driver: %s" % (self.relay or "none answered"))
        if not self.node or not self.relay:
            raise CannotRun("no node or Epicbox server answers")
        if "://" not in self.node:
            self.node = "https://" + self.node

    def plan(self):
        try:
            prev = self.setup_exe(self.prev_dir, self.prev_ver)
            cand = self.setup_exe(self.cand_dir, self.cand_ver)
        except CannotRun as e:
            prev = cand = str(e)
        return [
            "rig: %s as epicrig through the rig queue (scheduled task EpicWalletRig, session 0); run folder "
            "C:\\EpicRig\\trust\\runs\\%s (USERPROFILE of the app: its per-user install and data folder there)" % (self.host, self.name),
            "local work folder: %s (wallet password, mode 600; DB snapshots)" % self.work,
            "previous: %s" % prev,
            "candidate: %s" % cand,
            "node: %s; Epicbox: %s (picked from %s / %s when unset)" % (self.node or "-", self.relay or "-", NODE_PICK, RELAY_PICK),
            "loopback stand-ins on the rig (agent.ps1): node http://127.0.0.1:<port> -> REL_NODE, relay 127.0.0.1:<port> -> REL_EPICBOX",
            "previous app (Setup /VERYSILENT): create a wallet; Setup assistant: stand-in node added then REL_NODE in use, "
            "stand-in relay added then REL_EPICBOX in use; then, closed, Light theme, Technical details, a label and "
            "%d confirmation(s) seeded into its own files (seed.py) and read back after it reopens" % seed.SEED["confirmations"],
            "fund: P -> wallet %s EPIC via Epicbox (flock %s), wait until spendable" % (FUND_IN, self.p.lock_file),
            "digest: wallet DB (outputs, transactions), wallets.json, desk store settings keys, settings.toml, wfe.log, data folder files",
            "update: candidate Setup /SILENT /NORESTART /UPDATEFROMAPP=1 while the app runs, app closed, Setup reopens it; "
            "unlock, same digest",
            ("funds: P -> wallet %s, then everything back to P" % FUND_AFTER) if self.funds else
            ("funds: none checked; %s" % ("balance left on the rig (REL_KEEP_FUNDS=1)" if self.keep_funds else "balance sent back to P")),
            "end: app closed, uninstalled (HKCU entry gone), rig agent stopped; data folder kept in the run folder",
            "checks required: %s; proof: %s/proof.json" % (",".join(self.required), self.out),
        ]

    # ---- the rig

    def call(self, op, timeout=120, **kw):
        r = self.rig.call(op, timeout=timeout, **kw)
        if not r.get("ok"):
            raise RigError("%s: %s" % (op, r.get("error") or json.dumps(r)[:300]))
        return r

    def keys(self, *vks, gap_ms=400):
        self.call("keys", vks=list(vks), gap_ms=gap_ms, timeout=60 + len(vks))

    def click(self, xy, wait=1.0):
        self.call("click", x=xy[0], y=xy[1])
        time.sleep(wait)

    def type(self, text, wait=0.8):
        self.call("type", text=text)
        time.sleep(wait)

    def type_password(self):
        self.call("type", file=self.pw_remote)
        time.sleep(0.6)

    @property
    def data(self):
        return self.rig.run + "\\home\\.epic_cash_desktop"

    def applog(self):
        lines = (self.rig.text(self.data + "\\logs\\wfe.log") or "").replace("\r", "").splitlines()
        return [l for l in lines if l.strip()]  # the read over SSH ends with a blank line

    def mark(self):
        """From here on: wait_log looks only at lines written after this."""
        self.log_mark = len(self.applog())

    def wait_log(self, pattern, timeout, what):
        rx = re.compile(pattern)
        end = time.time() + timeout
        while time.time() < end:
            lines = self.applog()[self.log_mark:]
            hit = next((l for l in lines if rx.search(l)), None)
            if hit:
                return hit
            time.sleep(3)
        raise CannotRun("%s: no %r in wfe.log in %d s" % (what, pattern, timeout))

    def ensure_unlocked(self, what):
        """Unlock again when the app auto-locked (15 min by default) while the check waited, for P
        or a confirmation: a locked wallet does not listen on Epicbox, so P's payment would wait
        for nothing. The unlock screen has the password field focused."""
        lines = self.applog()
        opened = max((i for i, l in enumerate(lines) if "wallet opened" in l), default=-1)
        locked = max((i for i, l in enumerate(lines) if "wallet locked in lock" in l), default=-1)
        if locked <= opened:
            return
        self.log("%s: the wallet locked itself while the check waited; unlocking again" % what)
        self.mark()
        self.type_password()
        self.keys(ENTER)
        self.wait_log(r"wallet opened", 180, "%s: unlock again" % what)
        time.sleep(5)

    def wallets(self):
        t = self.rig.text(self.data + "\\wallets.json")
        return json.loads(t) if t else None

    def store(self):
        return self.call("store", file=self.data + "\\flutter_secure_storage.dat").get("keys") or {}

    def toml_servers(self):
        """settings.toml [node] and [epicbox] servers (the first in use); None without the file."""
        t = self.rig.text(self.data + "\\settings.toml")
        if t is None:
            return None
        out = {}
        for sect in ("node", "epicbox"):
            m = re.search(r"^\[%s\][^\[]*?servers\s*=\s*\[(.*?)\]" % sect, t, re.S | re.M)
            out[sect] = re.findall(r'"([^"]+)"', m.group(1)) if m else []
        return out

    def db(self):
        """The open wallet's database, copied here: outputs, transactions, settings."""
        w = self.wallets()
        if not w or not w.get("wallets"):
            return None
        wid = w.get("lastUsedId")
        entry = next((x for x in w["wallets"] if x.get("id") == wid), w["wallets"][0])
        path = entry["dataDir"].rstrip("\\/") + "\\lepic\\wallet.sqlite3"
        self.snap_n += 1
        local = self.rig.fetch_db(path, os.path.join(self.work, "db"), "%02d" % self.snap_n)
        if not os.path.exists(local):
            return None
        c = sqlite3.connect(local)
        try:
            outs = [dict(commit=r[0], amount=r[1], status=r[2], height=r[3], tx=r[4]) for r in
                    c.execute("select hex(commitment), amount, status, height, tx_id from outputs")]
            txs = [dict(id=r[0], direction=r[1], state=r[2], transport=r[3], credited=r[4], debited=r[5], fee=r[6],
                        height=r[7], counterparty=r[8], slate=r[9]) for r in
                   c.execute("select id, direction, state, transport, amount_credited, amount_debited, fee, confirmed_height, "
                             "counterparty, hex(slate_id) from transactions order by id")]
            st = dict(c.execute("select key, value from settings"))
        finally:
            c.close()
        return {"path": path, "outputs": outs, "txs": txs, "settings": st}

    # ---- balances from the wallet's own records

    def tip(self):
        for u in (self.node, *NODE_PICK):
            try:
                with urllib.request.urlopen(u.rstrip("/") + "/v1/status", timeout=10) as r:
                    return int(json.load(r)["tip"]["height"])
            except Exception:  # noqa: BLE001
                continue
        return None

    def balance(self, d, tip=None):
        if d is None:
            return None
        conf = conf_of(d) or DEFAULT_CONF
        unspent = [o for o in d["outputs"] if o["status"] == "unspent"]
        spendable = [o for o in unspent if tip and o["height"] and tip - o["height"] + 1 >= conf]
        b = {"total": D(sum(o["amount"] for o in d["outputs"] if o["status"] in ("unspent", "unconfirmed", "locked"))) / NANO,
             "unspent": D(sum(o["amount"] for o in unspent)) / NANO,
             "spendable": D(sum(o["amount"] for o in spendable)) / NANO,
             "unconfirmed": D(sum(o["amount"] for o in d["outputs"] if o["status"] == "unconfirmed")) / NANO,
             "locked": D(sum(o["amount"] for o in d["outputs"] if o["status"] == "locked")) / NANO}
        return b

    def wait_spendable(self, at_least, what, timeout=1800):
        end = time.time() + timeout
        last = None
        while time.time() < end:
            d = self.db()
            b = self.balance(d, self.tip())
            if b != last:
                self.log("%s: %s" % (what, fmt(b)))
                last = b
            if b and b["spendable"] >= at_least and b["spendable"] == b["total"]:
                return b
            time.sleep(20)
        raise TimeoutError("%s: not spendable in %d s (last %s)" % (what, timeout, fmt(last)))

    def budget(self, amount):
        a = D(amount)
        if a > CAP_SEND or self.spent + a > CAP_JOB:
            raise CannotRun("amount %s over the caps (%s per send, %s per job, %s used)" % (amount, CAP_SEND, CAP_JOB, self.spent))
        self.spent += a

    # ---- the app

    def start_app(self, what):
        r = self.call("window", wait_s=90, timeout=150)
        if (r["w"], r["h"]) != CLIENT:
            raise CannotRun("%s window client is %dx%d; the click map is for %dx%d" % (what, r["w"], r["h"], *CLIENT))
        self.log("%s window up: %s" % (what, r.get("procs")))
        return r

    def address(self):
        """The Epicbox address the Receive page copies."""
        for i in range(4):  # a busy box can miss a click: open the page again before each copy
            self.click(RAIL["receive"], 2.5 + i)
            self.call("clear_clipboard")
            self.click(COPY_ADDRESS, 1.5 + i)
            t = (self.call("clipboard").get("text") or "").strip()
            if re.fullmatch(r"[1-9A-HJ-NP-Za-km-z]{40,60}@[\w.:-]+", t):
                return t
        return None

    def create_wallet(self):
        self.start_app("previous")
        self.wait_log(r"dart\.app: desktop start", 60, "previous start")
        time.sleep(6)
        # Welcome: Create a new wallet
        self.keys(TAB, ENTER)
        time.sleep(2.5)
        # Create wallet: the two password fields
        self.keys(TAB, TAB)
        self.type_password()
        self.keys(TAB)
        self.type_password()
        self.keys(ENTER)
        self.wait_log(r"wallet created", 180, "create wallet")
        time.sleep(4)
        # Recovery phrase: Reveal, tick "written down", Continue (the phrase stays in the wallet's store)
        self.keys(TAB, ENTER)
        time.sleep(1.5)
        self.keys(TAB, TAB, TAB, TAB, SPACE)
        self.keys(TAB, ENTER)
        time.sleep(4)
        w = self.wallets()
        if not w or not w.get("wallets"):
            raise CannotRun("no wallet in wallets.json after the create steps")
        self.log("wallet created: %s (id %s)" % (w["wallets"][0].get("label"), w["wallets"][0].get("id")))

    def setup_servers(self):
        """The Setup assistant after creating: the stand-in, then REL_NODE (Enter on a typed address adds it
        and puts it in use); the same for Epicbox; Save settings; then unlock."""
        node_entry = re.sub(r"^https://", "", self.node).rstrip("/")
        # step 1: node picker
        self.keys(TAB, TAB, ENTER)
        time.sleep(1.5)
        self.type("http://%s" % self.custom_node)
        self.keys(ENTER)
        time.sleep(14)
        self.keys(ENTER)
        time.sleep(1.5)
        self.type(self.node)
        self.keys(ENTER)
        time.sleep(10)
        self.keys(TAB, TAB, ENTER)
        time.sleep(3)
        # step 2: Epicbox picker
        self.keys(TAB, TAB, ENTER)
        time.sleep(1.5)
        self.type(self.custom_relay)
        self.keys(ENTER)
        time.sleep(14)
        self.keys(ENTER)
        time.sleep(1.5)
        self.type(self.relay)
        self.keys(ENTER)
        time.sleep(10)
        self.keys(TAB, ENTER)
        time.sleep(3)
        # step 3: Save settings -> Unlock
        self.keys(TAB, TAB, TAB, ENTER)
        time.sleep(5)
        self.mark()
        self.type_password()
        self.keys(ENTER)
        self.wait_log(r"wallet opened", 180, "unlock after setup")
        time.sleep(6)
        self.keys(ESC)  # the tour
        time.sleep(1)
        lists = servers_of(self.store(), self.toml_servers())
        self.log("previous release stores: node in use %s, list %s (added %s); Epicbox %s, list %s (added %s)" % (
            lists["node_in_use"], lists["nodes"], lists["nodes_added"], lists["relay_in_use"], lists["relays"], lists["relays_added"]))
        bad = []
        if host(lists["node_in_use"]) != host(node_entry):
            bad.append("node in use %s, not %s" % (lists["node_in_use"], node_entry))
        if self.custom_node not in [host(x) for x in lists["nodes"]]:
            bad.append("stand-in node %s not listed" % self.custom_node)
        if host(lists["relay_in_use"]) != host(self.relay):
            bad.append("Epicbox in use %s, not %s" % (lists["relay_in_use"], self.relay))
        if self.custom_relay not in [host(x) for x in lists["relays"]]:
            bad.append("stand-in relay %s not listed" % self.custom_relay)
        if bad:
            raise CannotRun("server setup on the previous release: %s" % "; ".join(bad))

    def seed_settings(self):
        """Light theme, Technical details, a wallet label and 1 confirmation (seed.SEED), written into the previous
        release's own files while it is closed (seed.py), then read back from the reopened app."""
        self.call("close", wait_s=60, timeout=90)
        w = self.wallets()
        wid = w.get("lastUsedId")
        entry = next(x for x in w["wallets"] if x.get("id") == wid)
        store_file = self.data + "\\flutter_secure_storage.dat"
        keys = self.store()
        wallet_key = "desk.wallet.%s" % entry.get("chain", "mainnet")
        missing = [k for k in ("desk.settings", wallet_key) if not isinstance(keys.get(k), str)]
        if missing:
            raise CannotRun("the previous release's store has no %s to seed" % ", ".join(missing))
        # what the release wrote, kept as this version's fixture
        sd = os.path.join(self.out, "seed")
        os.makedirs(sd, exist_ok=True)
        with open(os.path.join(sd, "desk-settings-%s.json" % self.prev_ver), "w") as f:
            f.write(keys["desk.settings"] + "\n")
        fx = seed.fixture_for(self.prev_ver)
        template = open(fx[0]).read().strip() if fx else None
        self.details["seed"] = ("simple settings seeded into the closed previous release's files; desk.settings "
                                "over the fixture of %s" % (fx[1] if fx else "none (the release's own file only)"))
        try:
            new_keys = {"desk.settings": seed.desk_settings(keys["desk.settings"], self.want_settings["theme"],
                                                            self.want_settings["technical_details"], template),
                        wallet_key: seed.desk_wallet(keys[wallet_key], self.label)}
            wallets_text = seed.wallets_json(self.rig.text(self.data + "\\wallets.json"), wid, self.label)
            db_remote = entry["dataDir"].rstrip("\\/") + "\\lepic\\wallet.sqlite3"
            db_local = self.rig.fetch_db(db_remote, os.path.join(self.work, "db"), "seed")
            seed.wallet_db(db_local, self.want_settings["confirmations"])
        except seed.SeedError as e:
            raise CannotRun("seeding the previous release's settings: %s" % e)
        self.rig.put(db_local, self.rig.run + "\\seed-wallet.sqlite3")
        self.call("put_db", **{"from": self.rig.run + "\\seed-wallet.sqlite3", "to": db_remote})
        self.call("store_set", file=store_file, set=new_keys)
        self.call("write_file", file=self.data + "\\wallets.json", text=wallets_text)
        self.log("seeded into the closed previous release: desk.settings (theme, Technical details), %s and "
                 "wallets.json (label), the wallet database (minimum confirmations)" % wallet_key)
        # reopened: the release must take the seeded values as its own
        self.mark()
        self.call("start", exe=self.exe)
        self.start_app("previous (seeded)")
        time.sleep(6)
        self.type_password()
        self.keys(ENTER)
        self.wait_log(r"wallet opened", 180, "unlock after seeding")
        time.sleep(5)
        self.keys(ESC)
        got = self.settings_now()
        self.log("previous release settings after seeding: %s" % got)
        wrong = {k: v for k, v in got.items() if v != self.want_settings[k]}
        if wrong:
            raise CannotRun("the previous release did not take the seeded settings: %s" % wrong)
        return got

    def settings_now(self):
        s = self.store()
        ds = s.get("desk.settings") or {}
        if isinstance(ds, str):
            ds = json.loads(ds)
        w = self.wallets() or {}
        wid = w.get("lastUsedId")
        label = next((x.get("label") for x in w.get("wallets", []) if x.get("id") == wid), None)
        d = self.db()
        return {"theme": ds.get("theme"),
                "technical_details": "technicalDetails" in ((ds.get("advanced") or {}).get("features") or []),
                "label": label,
                "confirmations": conf_of(d)}

    # ---- the digest

    def digest(self, tag):
        d = self.db()
        w = self.wallets()
        s = self.store()
        toml = self.toml_servers()
        lines = self.applog()[self.log_mark:]
        subs = [re.search(r"relay=(\S+)", l).group(1) for l in lines if "epicbox subscribed" in l and "relay=" in l]
        dg = {"address": self.address(), "wallets": w, "db_path": d and d["path"],
              "outputs": d and d["outputs"], "txs": d and d["txs"], "db_settings": d and d["settings"],
              "balance": self.balance(d, self.tip()), "settings": self.settings_now(),
              "store_servers": servers_23(s), "servers": servers_of(s, toml), "settings_toml": toml, "relay_subscribed": subs,
              "files": self.rig.files(self.data)}
        with open(os.path.join(self.out, "digest-%s.json" % tag), "w") as f:
            json.dump(dg, f, indent=1, default=str)
        self.log("digest %s: address %s, balance %s, %d transactions, settings %s, store servers %s, settings.toml %s, "
                 "relay subscribed %s, %d files" % (tag, lt.short(dg["address"]), fmt(dg["balance"]), len(dg["txs"] or []),
                                                     dg["settings"], dg["store_servers"], toml, subs[-1:], len(dg["files"])))
        return dg

    # ---- funds

    def fund(self, address, amount, what):
        self.budget(amount)
        d0 = self.db()
        n0 = len([t for t in d0["txs"] if t["direction"] == "incoming"]) if d0 else 0
        with self.p.exchange(what) as p:
            self.ensure_unlocked(what)
            if not p.start_listener():
                return False, "P's listener did not start (3 tries)"
            ok, out = p.send(address, amount)
            self.log("P -> %s %s: %s (%s)" % (lt.short(address), amount, "sent" if ok else "FAILED", out))
            if not ok:
                return False, "P send failed: %s" % out
            end = time.time() + 900
            stuck_since, reposted, last = None, False, None
            while time.time() < end:
                d = self.db()
                inc = [t for t in (d["txs"] if d else []) if t["direction"] == "incoming"]
                new = inc[n0:] if len(inc) > n0 else []
                state = [(t["state"], t["credited"]) for t in new]
                if state != last:
                    self.log("%s: wallet records %s" % (what, state or "nothing yet"))
                    last = state
                if new and new[-1]["state"] == "confirmed":
                    return True, "incoming %s EPIC from %s, confirmed at %s" % (
                        num(D(new[-1]["credited"]) / NANO), lt.short(new[-1]["counterparty"]), new[-1]["height"])
                # answered but P has not posted (its listener can hang there): post P's saved copy
                stuck_since = (stuck_since or time.time()) if new else None
                if stuck_since and time.time() - stuck_since > P_STALL_S and not reposted:
                    reposted = True
                    p.stop_listener()
                    for tx_id, slate in p.unposted_sends(address.split("@")[0]):
                        posted, o = p.repost(tx_id)
                        self.log("P repost of its send %s (slate %s…): %s (%s)" % (tx_id, slate[:8], "ok" if posted else "FAILED", o))
                    p.start_listener()
                time.sleep(15)
            return False, "not received and confirmed in 15 min (wallet records %s)" % last

    def send_to_p(self, what):
        """Everything (Max) to P through the Send page, P's listener answering; True when the wallet's
        records show the payment posted and confirmed."""
        d0 = self.db()
        n0 = len([t for t in d0["txs"] if t["direction"] == "outgoing"])
        avail = self.balance(d0, self.tip())["spendable"]
        if avail > CAP_SEND:
            return False, "available %s over the per-send cap %s" % (avail, CAP_SEND)
        self.budget(avail)
        with self.p.exchange(what) as p:
            self.ensure_unlocked(what)
            if not p.start_listener():
                return False, "P's listener did not start (3 tries)"
            self.mark()
            self.click(RAIL["overview"], 1.5)
            self.click(RAIL["send"], 2.5)
            self.click(SEND_TO, 0.8)
            self.type(self.p_addr, 1.5)
            self.click(SEND_MAX, 2)
            self.click(SEND_REVIEW, 4)
            # the review: the password, then Enter sends
            self.type_password()
            self.keys(ENTER)
            try:
                hit = self.wait_log(r"slate sent in send", 120, "send")
            except CannotRun as e:
                return False, "no send started: %s" % e
            self.log("send started: %s" % hit[-120:])
            end = time.time() + 900
            last = None
            while time.time() < end:
                d = self.db()
                out = [t for t in d["txs"] if t["direction"] == "outgoing"][n0:]
                state = [(t["state"], t["debited"], t["fee"]) for t in out]
                if state != last:
                    self.log("%s: wallet records %s" % (what, state))
                    last = state
                if out and out[-1]["state"] == "confirmed":
                    t = out[-1]
                    return True, "outgoing %s EPIC (fee %s) to %s, posted and confirmed at %s" % (
                        num(D(t["debited"] - t["credited"] - (t["fee"] or 0)) / NANO), num(D(t["fee"] or 0) / NANO),
                        lt.short(t["counterparty"]), t["height"])
                time.sleep(15)
            return False, "not posted and confirmed in 15 min (wallet records %s)" % last

    # ---- the job

    def main(self):
        if self.dry:
            for line in self.plan():
                print("PLAN " + line)
            return 0
        os.makedirs(self.out, exist_ok=True)
        if not os.path.isdir(self.prev_dir) or not os.path.isdir(self.cand_dir):
            raise CannotRun("REL_PREVIOUS_DIR and REL_CANDIDATE_DIR must be folders")
        if self.variant not in ("tor", "notor"):
            raise CannotRun("REL_VARIANT must be tor or notor")
        unknown = [c for c in self.required if c not in CHECKS]
        if unknown:
            raise CannotRun("unknown checks in REL_CHECKS: %s" % ",".join(unknown))
        prev = self.setup_exe(self.prev_dir, self.prev_ver)
        cand = self.setup_exe(self.cand_dir, self.cand_ver)
        why = self.p.ready()
        if why:
            raise CannotRun(why)
        self.pick_servers()
        for line in self.picked:
            self.log(line)
        os.makedirs(self.work, mode=0o700, exist_ok=True)
        self.details["installers"] = "previous %s (sha256 %s), candidate %s (sha256 %s)" % (
            os.path.basename(prev), lt.sha256(prev)[:16], os.path.basename(cand), lt.sha256(cand)[:16])
        self.log(self.details["installers"])
        pw = os.path.join(self.work, "wallet.pw")
        with open(pw, "w") as f:
            f.write(secrets.token_urlsafe(16))
        os.chmod(pw, 0o600)
        self.label = "Trust %s" % datetime.datetime.now().strftime("%m%d %H%M")
        self.want_settings = dict(seed.SEED, label=self.label)
        self.rig = Rig(self.host, self.name, self.log, os.path.join(os.path.expanduser("~"), ".cache", "rel-trust-windows", "ctl"))
        self.rig.prepare()
        self.rig.put(prev, self.rig.run + "\\prev-setup.exe")
        self.rig.put(cand, self.rig.run + "\\cand-setup.exe")
        self.pw_remote = self.rig.put_secret(pw, "wallet.pw")
        self.log("rig run folder %s; local work folder %s" % (self.rig.run, self.work))
        waiting = self.rig.busy()
        if waiting:
            self.log("the rig queue has %d job(s) before ours" % waiting)
        self.rig.start_agent(idle_min=45, wait_s=1800 if waiting else 420)
        try:
            return self.flow()
        finally:
            self.shutdown()

    def flow(self):
        r = self.call("standins", node=self.node, relay=self.relay)
        self.custom_node = "127.0.0.1:%d" % r["node"]
        self.custom_relay = "127.0.0.1:%d" % r["relay"]
        self.log("stand-ins on the rig: node %s -> %s, relay %s -> %s" % (self.custom_node, self.node, self.custom_relay, self.relay))
        e = self.call("entry").get("entry")
        if e:
            raise CannotRun("epicrig already has Epic Cash Desktop installed (%s at %s): left alone" % (e.get("version"), e.get("location")))

        # previous release: installed silently, the user's wallet and choices
        r = self.call("setup", exe=self.rig.run + "\\prev-setup.exe", timeout=400, wait_s=300,
                      args=["/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART", "/LOG=%s\\setup-previous.log" % self.rig.run])
        self.installed = r["entry"]
        self.log("previous installed: %s at %s" % (self.installed.get("version"), self.installed.get("location")))
        self.exe = self.installed["location"].rstrip("\\") + "\\epic_wallet.exe"
        self.mark()
        self.call("start", exe=self.exe)
        self.create_wallet()
        self.setup_servers()
        self.seed_settings()
        addr = self.address()
        if not addr:
            raise CannotRun("no Epicbox address copied from the Receive page")
        self.setup_address = addr
        self.log("wallet address %s" % lt.short(addr))
        ok, why = self.fund(addr, FUND_IN, "funding before the update")
        if not ok:
            raise CannotRun("funding: %s" % why)
        self.wait_spendable(D(FUND_IN), "funding confirmed")
        before = self.digest("previous")
        if not before["txs"]:
            raise CannotRun("no transaction in the wallet before the update")

        # the update, the way the in-app updater runs it
        cand_start = len(self.applog())
        r = self.call("setup", exe=self.rig.run + "\\cand-setup.exe", wait=False,
                      args=["/SILENT", "/NORESTART", "/UPDATEFROMAPP=1", "/LOG=%s\\setup-candidate.log" % self.rig.run])
        time.sleep(1)
        self.call("close", wait_s=60, timeout=90)
        self.log("candidate Setup started (pid %s) and the previous app closed" % r["pid"])
        w = self.call("wait_exit", pid=r["pid"], wait_s=300, timeout=360)
        self.log("candidate Setup exited: %s" % w)
        self.log_mark = cand_start
        e = self.call("entry").get("entry") or {}
        self.details["update"] = "Setup exit %s; uninstall entry now %s at %s" % (w.get("exit"), e.get("version"), e.get("location"))
        opened, why = self.open_after_update(before)
        self.details["wallet_opens"] = why
        if not opened:
            self.fail("wallet_opens", why)
            for c in ("balance_kept", "history_kept", "custom_nodes_kept", "custom_relays_kept", "settings_kept"):
                self.fail(c, "not checked: the wallet did not open")
            after = None
        else:
            time.sleep(20)
            after = self.digest("candidate")
            self.settle(before, after)
            self.compare(before, after)
        self.funds_legs(after)
        return 0

    def open_after_update(self, before):
        try:
            hit = self.wait_log(r"dart\.app: desktop start", 120, "candidate start")
        except CannotRun:
            return False, "Setup did not open the candidate (no app start in wfe.log within 2 min of Setup)"
        self.log("after the update: %s" % hit.split("dart.app: ")[-1][:80])
        if not re.search(r"desktop start %s\b" % re.escape(self.cand_ver.split("-")[0]), hit):
            return False, "the app Setup opened is not the candidate: %s" % hit.split("dart.app: ")[-1][:80]
        try:
            self.start_app("candidate")
        except CannotRun as e:
            return False, str(e)
        time.sleep(6)
        self.type_password()
        self.keys(ENTER)
        try:
            self.wait_log(r"wallet opened", 180, "candidate unlock")
        except CannotRun:
            return False, "no wallet opened in 3 min after typing the password (no unlock in wfe.log)"
        time.sleep(5)
        self.keys(ESC)
        w0, w1 = before["wallets"], self.wallets()
        e0 = next((x for x in w0["wallets"] if x["id"] == w0.get("lastUsedId")), w0["wallets"][0])
        e1 = next((x for x in (w1 or {}).get("wallets", []) if x.get("id") == e0["id"]), None)
        if not e1:
            return False, "wallets.json no longer lists the wallet %s" % e0["id"]
        # The wallet's identity: LEPIC's walletFingerprint when both entries have it (from 26.10.25 an unlock
        # drops the old phraseFingerprint once that is there, WAL-09), else the phrase fingerprint.
        key = "walletFingerprint" if e0.get("walletFingerprint") and e1.get("walletFingerprint") else "phraseFingerprint"
        if e1.get(key) != e0.get(key) or e1.get("dataDir") != e0.get("dataDir"):
            return False, "the wallet entry changed: %s or folder differ" % key
        addr = self.address()
        # The address the digest read, else the one read when the wallet was made: never an empty one.
        a0, a1 = (before["address"] or self.setup_address or "").split("@")[0], (addr or "").split("@")[0]
        if not a1:
            return False, "unlocked (wfe.log), but no Epicbox address could be copied"
        if not a0:
            return False, "the previous release's address could not be copied, so the wallet cannot be compared"
        if a0 != a1:
            return False, "a different wallet opened: address %s, was %s" % (lt.short(a1), lt.short(a0))
        return True, ("unlocked with the same password (wfe.log: wallet opened); same wallet entry %s, same folder, "
                      "same Epicbox address %s (copied from the Receive page)" % (e0["id"], lt.short(a1)))

    def settle(self, b, a, wait_s=150):
        """The candidate may still be refreshing: the wallet's records are read again for up to [wait_s]."""
        a["first_balance"], a["first_txs"] = a["balance"], a["txs"]
        t0 = time.time()
        while time.time() - t0 < wait_s:
            if (a["balance"] or {}).get("total") == (b["balance"] or {}).get("total") and \
                    all(any(same_tx(t, x) for x in (a["txs"] or [])) for t in b["txs"]):
                break
            time.sleep(15)
            d = self.db()
            a["balance"], a["txs"], a["outputs"] = self.balance(d, self.tip()), d and d["txs"], d and d["outputs"]
        a["settled_after_s"] = int(time.time() - t0)
        with open(os.path.join(self.out, "digest-candidate.json"), "w") as f:
            json.dump(a, f, indent=1, default=str)

    def compare(self, b, a):
        self.ok("wallet_opens", self.details.get("wallet_opens"))
        how = " (from the wallet's own database, %s; the screen cannot be read on the rig)" % "\\".join(a["db_path"].split("\\")[-4:])
        b0, b1 = b["balance"] or {}, a["balance"] or {}
        keep0 = sorted((o["commit"], o["amount"]) for o in b["outputs"] if o["status"] == "unspent")
        keep1 = sorted((o["commit"], o["amount"]) for o in (a["outputs"] or []) if o["status"] == "unspent")
        if a["db_path"] != b["db_path"]:
            self.fail("balance_kept", "the candidate keeps the wallet in another database: %s, was %s" % (a["db_path"], b["db_path"]))
        elif b1.get("total") == b0.get("total") and keep0 == keep1:
            self.ok("balance_kept", "total %s EPIC before and after, the same %d unspent outputs%s" % (num(b0["total"]), len(keep0), how))
        else:
            self.fail("balance_kept", "before %s, after %s (read for %d s); unspent outputs %d -> %d%s" % (
                fmt(b0), fmt(b1), a.get("settled_after_s", 0), len(keep0), len(keep1), how))
        missing = [t for t in b["txs"] if not any(same_tx(t, x) for x in (a["txs"] or []))]
        lost = [t for t in b["txs"] if t not in missing and t["counterparty"]
                and not any(same_tx(t, x) and x["counterparty"] == t["counterparty"] for x in a["txs"])]
        senders = sum(1 for t in b["txs"] if t["counterparty"])
        if missing:
            self.fail("history_kept", "%d of %d transactions missing after the update: %s" % (len(missing), len(b["txs"]), txs_text(missing)))
        elif lost:
            self.fail("history_kept", "transactions kept but who paid or was paid lost: %s" % txs_text(lost))
        elif not senders:
            self.fail("history_kept", "the payment before the update has no sender recorded: nothing to compare")
        else:
            self.ok("history_kept", "%d transactions kept with their counterparties (%s)%s" % (len(b["txs"]), txs_text(b["txs"]), how))
        self.compare_list("node", b, a)
        self.compare_list("relay", b, a)
        s0, s1 = b["settings"], a["settings"]
        diff = {k: (s0.get(k), s1.get(k)) for k in s0 if s0.get(k) != s1.get(k)}
        unset = {k: s0.get(k) for k, v in self.want_settings.items() if s0.get(k) != v}
        src = " (desk store desk.settings, wallets.json label, the wallet database's minimum confirmations)"
        if unset:
            self.fail("settings_kept", "the test could not set them on the previous release: %s" % unset)
        elif diff:
            self.fail("settings_kept", "changed by the update (before, after): %s%s" % (diff, src))
        else:
            self.ok("settings_kept", "theme %s, label %r, %s confirmations, Technical details %s%s" % (
                s0["theme"], s0["label"], s0["confirmations"], "on" if s0["technical_details"] else "off", src))
        gone = [f for f in b["files"] if f not in a["files"]]
        self.details["data_folder"] = ("all %d files of the previous data folder still there; %d new" % (
            len(b["files"]), len(set(a["files"]) - set(b["files"])))) if not gone else ("files gone after the update: %s" % ", ".join(gone[:10]))
        self.log("data folder: %s" % self.details["data_folder"])

    def compare_list(self, kind, b, a):
        """Each release's lists are its settings.toml when it has one (its first entry is in use: 26.10.24
        and later), else its store keys (26.10.23 and earlier)."""
        check = "custom_nodes_kept" if kind == "node" else "custom_relays_kept"
        custom = self.custom_node if kind == "node" else self.custom_relay
        chosen = host(self.node if kind == "node" else self.relay)
        lb = b["servers"]
        before_list = [host(x) for x in lb["nodes" if kind == "node" else "relays"]]
        before_use = host(lb["node_in_use" if kind == "node" else "relay_in_use"])
        own = [host(x) for x in lb["nodes_added" if kind == "node" else "relays_added"]]
        if a["settings_toml"] is not None:
            after_list = [host(x) for x in a["settings_toml"]["node" if kind == "node" else "epicbox"]]
            after_use = after_list[0] if after_list else None
            src = "settings.toml (first entry in use)"
        else:
            la = a["store_servers"]
            after_list = [host(x) for x in la["nodes" if kind == "node" else "relays"]]
            after_use = host(la["node_in_use" if kind == "node" else "relay_in_use"])
            src = "the desk store"
        problems = []
        if custom not in before_list:
            problems.append("the stand-in %s %s was not in the previous list" % (kind, custom))
        elif custom not in after_list:
            problems.append("added %s %s gone" % (kind, custom))
        if after_use != chosen:
            problems.append("in use was %s, now %s" % (before_use, after_use))
        lost = [x for x in own if x not in after_list and x != custom]
        if lost:
            problems.append("own entries gone: %s" % ", ".join(lost))
        extra = ""
        if kind == "relay":
            subs = a.get("relay_subscribed") or []
            extra = "; the candidate's listener subscribed to %s (wfe.log)" % (", ".join(sorted(set(subs))) or "nothing")
        if problems:
            self.fail(check, "; ".join(problems) + "; after (%s): %s%s" % (src, ", ".join(after_list), extra))
        else:
            self.ok(check, "%s in use and %s kept; list %s (%s)%s" % (chosen, custom, ", ".join(after_list), src, extra))

    def funds_legs(self, after):
        if not self.funds:
            for c in ("send_ok", "receive_ok"):
                self.fail(c, "not run (REL_FUNDS=0)")
        if after is None or not self.checks.get("wallet_opens") or not self.checks.get("balance_kept"):
            why = "the wallet did not open with the candidate" if after is None or not self.checks.get("wallet_opens") \
                else "the candidate does not keep the wallet's balance"
            if self.funds:
                for c in ("send_ok", "receive_ok"):
                    self.fail(c, "not run: %s" % why)
            self.log("funds left in the rig wallet: %s (data folder and password kept)" % why)
            return
        full = after["address"]
        if self.funds:
            try:
                ok, why = self.fund(full, FUND_AFTER, "receive with the candidate")
                if ok:
                    b = self.wait_spendable(D(FUND_IN) + D(FUND_AFTER), "receive confirmed")
                    self.ok("receive_ok", "P -> %s %s EPIC via Epicbox: %s; spendable %s (wallet database)" % (
                        lt.short(full), FUND_AFTER, why, num(b["spendable"])))
                else:
                    self.fail("receive_ok", why)
            except (TimeoutError, CannotRun, RigError) as e:
                self.fail("receive_ok", "%s" % e)
        self.send_back("send_ok" if self.funds else None)

    def send_back(self, check):
        if not self.funds and self.keep_funds:
            self.log("funds kept in the rig wallet (REL_KEEP_FUNDS=1)")
            return
        try:
            b = self.wait_spendable(D("0.001"), "before sending back", 900)
            ok, why = self.send_to_p("send back to P")
            if check:
                (self.ok if ok else self.fail)(check, ("to P via Epicbox, the Send page with Max: %s" % why) if ok else why)
            else:
                self.log("returned to P: %s" % why)
        except Exception as e:  # noqa: BLE001
            if check:
                self.fail(check, "%s: %s" % (type(e).__name__, e))
            else:
                self.log("could not return the funds: %s" % e)

    def shutdown(self):
        if self.rig is None:
            return
        try:
            self.p.stop_listener()
        except Exception as e:  # noqa: BLE001
            self.log("P listener stop: %s" % e)
        for op, kw in (("close", {"wait_s": 60}), ("stop_all", {}), ("uninstall", {})):
            try:
                r = self.rig.call(op, timeout=200, **kw)
                self.log("rig %s: %s" % (op, {k: v for k, v in r.items() if k != "entry"}))
            except Exception as e:  # noqa: BLE001
                self.log("rig %s: %s" % (op, e))
        try:
            self.rig.get(self.rig.run + "\\home\\.epic_cash_desktop\\logs\\wfe.log", os.path.join(self.out, "wfe.log"))
            for n in ("setup-previous.log", "setup-candidate.log", "agent.log", "standins.log"):
                self.rig.get(self.rig.run + "\\" + n, os.path.join(self.out, n))
        except Exception as e:  # noqa: BLE001
            self.log("logs: %s" % e)
        self.rig.quit_agent()
        self.rig.close()
        self.log("rig: app uninstalled, agent stopped; the wallet's data folder stays in %s\\home (password in %s, mode 600)" % (
            self.rig.run, os.path.join(self.work, "wallet.pw")))


# ---- helpers

DEFAULT_CONF = 6  # the wallet's minimum confirmations while it has none stored


def conf_of(d):
    v = (d or {}).get("settings", {}).get("wallet.minimum_confirmations")
    return int(v) if v else (DEFAULT_CONF if d else None)


def servers_23(s):
    """Node and Epicbox lists and choices as the desktop's store keeps them (26.10.23 and earlier)."""
    def j(k):
        v = s.get(k)
        if isinstance(v, str):
            try:
                return json.loads(v)
            except ValueError:
                return v
        return v or {}
    n, r = j("desk.serverList.node.mainnet"), j("desk.serverList.relay.mainnet")
    return {"node_in_use": s.get("app.node.mainnet") or "", "nodes": (n or {}).get("entries", []), "nodes_added": (n or {}).get("added", []),
            "relay_in_use": s.get("app.relay.mainnet") or "", "relays": (r or {}).get("entries", []), "relays_added": (r or {}).get("added", [])}


def servers_of(s, toml):
    """The lists and choices in servers_23's shape: settings.toml when the release has one (26.10.24 and
    later keep their servers there, the first in use; the file has no "added" record), else the store."""
    if toml is None:
        return servers_23(s)
    n, r = toml.get("node") or [], toml.get("epicbox") or []
    return {"node_in_use": n[0] if n else "", "nodes": n, "nodes_added": [],
            "relay_in_use": r[0] if r else "", "relays": r, "relays_added": []}


def host(u):
    return re.sub(r"^\w+://", "", (u or "").strip()).rstrip("/")


def same_tx(t0, t1):
    """The same payment: its slate, else direction and amounts (states move on with confirmations)."""
    if t0.get("slate") and t1.get("slate"):
        return t0["slate"] == t1["slate"]
    return (t0["direction"], t0["credited"], t0["debited"]) == (t1["direction"], t1["credited"], t1["debited"])


def txs_text(ts):
    return "; ".join("%s %s EPIC %s, %s" % (t["direction"], num(D(t["credited"] or t["debited"]) / NANO), t["state"],
                                             lt.short(t["counterparty"]) or "no counterparty") for t in ts)


def num(v):
    return lt.num(v)


def fmt(b):
    return ", ".join("%s %s" % (k, num(v)) for k, v in (b or {}).items()) or "none"


def main():
    if len(sys.argv) > 2 and sys.argv[1] == "fail":
        run = Run()
        os.makedirs(run.out, exist_ok=True)
        run.details["run"] = "could not run: %s" % sys.argv[2]
        for c in CHECKS:
            run.details.setdefault(c, "not reached")
        run.proof()
        return 2
    run = Run()
    if not run.dry:
        os.makedirs(run.out, exist_ok=True)
    rc = 2
    try:
        rc = run.main()
        if run.dry:
            return 0
        missing = [c for c in run.required if not run.checks.get(c)]
        rc = 1 if missing else 0
        run.log("checks required %s: %s" % (",".join(run.required), "all true" if not missing else "false: " + ",".join(missing)))
    except (CannotRun, RigError) as e:
        run.details["run"] = "could not run: %s" % e
        run.log("COULD NOT RUN: %s" % e)
        rc = 2
    except Exception as e:  # noqa: BLE001
        run.details["run"] = "driver error: %s: %s" % (type(e).__name__, e)
        run.log("DRIVER ERROR: %s" % traceback.format_exc())
        rc = 2
    finally:
        if not run.dry:
            for c in CHECKS:
                run.details.setdefault(c, "not reached")
            if run.picked:
                run.details["servers"] = "; ".join(run.picked)
            run.proof()
    return rc


if __name__ == "__main__":
    sys.exit(main())
