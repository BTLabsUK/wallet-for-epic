#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""G4 update trust on Linux: a user on the previous release updates to the candidate AppImage and
keeps everything. Called by ../trust-linux.sh with the REL_* environment (see there).

The previous AppImage runs in a sandbox (own HOME, Xvfb, dbus, keyring): a new wallet, the node
and Epicbox server typed in (REL_NODE, REL_EPICBOX) plus a loopback node and relay in no built-in
list, a few stored settings changed, funded from P so it has a balance and history. A digest is
read off the screens. Then the AppImage is swapped for the candidate's on the same HOME (what the
in-app AppImage update does: the file changes, the data folder stays), the same wallet is opened
and read again. With REL_FUNDS=1 the candidate then receives from P and sends everything back.

REL_VIA_DIR + REL_VIA_VERSION: the user ran a release in between (26.10.23 -> 26.10.24-r2 ->
candidate, #143). That release only opens the wallet and is read once (digest-via.json); the
candidate is compared with what the previous release showed.
"""
import datetime
import glob
import decimal
import json
import os
import re
import shutil
import socket
import ssl
import subprocess
import sys
import time
import traceback
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.dirname(HERE))
import sandbox  # noqa: E402
import facts  # noqa: E402
import migration  # noqa: E402
import seed  # noqa: E402
import screens as catalog  # noqa: E402
from p_funder import P  # noqa: E402

# What the update to a release that encrypts the wallet database must leave (migration.py); the four
# apply to a candidate from facts.FIRST_ENCRYPTED_RELEASE and are "not applicable" before it.
MIGRATION_CHECKS = ["store_encrypted", "app_files_kept", "lan_nodes_kept", "contact_note_kept"]
CHECKS = ["wallet_opens", "balance_kept", "history_kept", "custom_nodes_kept", "custom_relays_kept",
          "settings_kept", "send_ok", "receive_ok"] + MIGRATION_CHECKS
NODE_PICK = facts.NODE_PICK      # release/pipeline.toml [defaults], BT Labs first
RELAY_PICK = facts.RELAY_PICK
TEST_CONFIRMATIONS = facts.TEST_CONFIRMATIONS  # the setting the test moves to: test payments spend after one block
FUND_IN = "0.03"     # P -> wallet before the update
FUND_AFTER = "0.01"  # P -> wallet with the candidate
CAP_SEND = decimal.Decimal("0.05")
CAP_JOB = decimal.Decimal("1")
AMOUNT = re.compile(r"^(-?[\d,]+(?:\.\d+)?) EPIC$")
# Settings' sections the driver opens or may see beside them: a narrow page lists them as chips, and
# where two rows of chips are not enough as a dropdown that names only the section shown (87d01a220).
# Both layouts: up to 26.10.24 (This wallet, Transactions, Receiving, ...) and from 26.10.25 (Wallet,
# Payments, Network & privacy, ...: settings_sections.dart settingsSectionLabel).
SECTIONS = ("Node", "Transactions", "Receiving", "Privacy", "Appearance", "This wallet", "All wallets",
            "Recovery phrase", "Recheck balance", "Advanced", "About",
            "Wallet", "Security", "Payments", "Invoices", "Linked devices", "Network & privacy", "Wallets",
            "Files & logs", "Help", "Donate")
# where a setting lives, first match wins: the 26.10.25 page, then the older one
LABEL_PAGES = ("Wallet", "This wallet")
RELAY_PAGES = ("Payments", "Transactions", "Receiving")
CONFIRMATIONS_PAGES = ("Payments", "Advanced")
THEMES = ("System", "Dark", "Light")
# the toast a build with the last-session report shows once after unlock (5f9933de6)
LAST_SESSION = facts.label("deskLastSessionClosed", "The app closed unexpectedly last time. Send the log?")
LAST_SESSION_FROZE = facts.label("deskLastSessionFroze", "The app stopped responding last time. Send the log?")
# a finalized send's row while its post may still succeed (c640a0593: up to 30 s), and after it failed
POSTING = facts.label("postFinishedPosting", "Posting…")
NOT_POSTED = (facts.label("deskTxStatusNotPosted", "Not on the network"), facts.label("txPostElsewhere", "To be posted elsewhere"))
FIRST_RUN_LOG = re.compile(r"first run: ")  # first_run_servers.dart's log lines: the server pick of a fresh install
D = decimal.Decimal


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
        self.prev_ref = e.get("REL_PREVIOUS_REF", "")
        self.cand_dir = e.get("REL_CANDIDATE_DIR", "")
        self.cand_ver = e.get("REL_CANDIDATE_VERSION", "")
        self.cand_src = e.get("REL_CANDIDATE_SRC", "")
        self.via_dir = e.get("REL_VIA_DIR", "")
        self.via_ver = e.get("REL_VIA_VERSION", "")
        self.funds = e.get("REL_FUNDS", "1") == "1"
        self.migrate = facts.encrypts_store(self.cand_ver)
        # the seed and the three app-file checks need a previous release that still keeps the plain files
        self.seed_files = self.migrate and not facts.encrypts_store(self.prev_ver)
        # unset: every check with funds, without send_ok and receive_ok otherwise; the migration checks
        # only for a candidate that encrypts the database
        default = [c for c in CHECKS if (self.funds or c not in ("send_ok", "receive_ok"))
                   and (self.migrate or c not in MIGRATION_CHECKS)]
        self.required = [c.strip() for c in (e.get("REL_CHECKS") or ",".join(default)).split(",") if c.strip()]
        self.keep_funds = e.get("REL_KEEP_FUNDS") == "1"
        self.node = e.get("REL_NODE", "")
        self.relay = e.get("REL_EPICBOX", "")
        self.picked = []
        stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        work_root = e.get("REL_WORK") or os.path.join(os.path.expanduser("~"), ".cache", "rel-trust-linux")
        via = "-via-%s" % self.via_ver if self.via_ver else ""
        self.work = os.path.join(work_root, "%s-%s%s-to-%s-%s" % (self.variant, self.prev_ver, via, self.cand_ver, stamp))
        self.sb = os.path.join(self.work, "sandbox")
        self.p = P(e.get("REL_P_TOOL") or os.path.expanduser("/tmp/epic-build/interop/epicpay/p.py"),
                   e.get("REL_P_PASS_FILE") or os.path.expanduser("~/.config/btlabs/p-pass-candidates"),
                   int(e.get("REL_P_PASS_LINE") or "1"),
                   e.get("REL_P_LOCK") or os.path.expanduser("/opt/epic/qa-funder/.rel-lock"),
                   self.out, self.log)
        self.p_addr = e.get("REL_P_ADDR") or "esa57kJmWkZyX8fSkKPW2Gu12ENhFF6MXfdsrsY4gqVK58ZwzB4d@epicbox.stackwallet.com"
        self.checks = {c: False for c in CHECKS}
        self.details = {}
        self.before_files = ([], {})  # the data folder just before the candidate starts (listing, hashes)
        self.lan_before = None        # lan_nodes.json as the previous release left it
        self.spent = D(0)
        self.ports = {}
        self.standins = []
        self.ui = None
        self.shot_n = 0
        self.screens = catalog.Screens(self.out, "linux", self.variant, self.prev_ver, self.cand_ver, self.log)
        self.update_method = ("appimage-swap: the previous release's AppImage, then the candidate's AppImage on the "
                              "same sandbox HOME (data folder and keyring kept, as the in-app update leaves them); "
                              "both run extracted (--appimage-extract, no libfuse2 here)")

    # ---- output

    def log(self, s):
        line = "%s %s" % (datetime.datetime.now().strftime("%H:%M:%S"), s)
        print(line, flush=True)
        with open(os.path.join(self.out, "trust.log"), "a") as f:
            f.write(line + "\n")

    def shot(self, name):
        if re.search(r"phrase|recovery|seed", name):
            return
        self.shot_n += 1
        try:
            os.makedirs(os.path.join(self.out, "shots"), exist_ok=True)
            sandbox.shot(self.sb, os.path.join(self.out, "shots", "%02d-%s.png" % (self.shot_n, name)))
        except Exception as e:  # noqa: BLE001
            self.log("screenshot %s failed: %s" % (name, e))

    def screen(self, phase, point, note=""):
        """A catalogue screen (screens/<phase>-<point>.png) of what the app shows now. Called only where
        the flow already stands on that screen; never on a phrase or a typed password."""
        if phase:
            self.screens.take(phase, point, lambda png: sandbox.shot(self.sb, png), note)

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
            "platform": "linux", "variant": self.variant,
            "previous": self.prev_ver, "candidate": self.cand_ver,
            **({"in_between": self.via_ver} if self.via_ver else {}),
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

    def appimage(self, folder, version):
        # bt-wallet-<v>[-notor]-linux-x86_64.AppImage; a release before the rename has
        # EpicCashDesktop-<v>[-notor]-x86_64.AppImage.
        sfx = "-notor" if self.variant == "notor" else ""
        names = ["bt-wallet-%s%s-linux-x86_64.AppImage" % (version, sfx), "EpicCashDesktop-%s%s-x86_64.AppImage" % (version, sfx)]
        for n in names:
            p = os.path.join(folder, n)
            if os.path.isfile(p):
                return p
        rx = re.compile(r"^(?:bt-wallet-.*%s-linux|EpicCashDesktop-.*%s)-x86_64\.AppImage$" % ((sfx or r"(?<!-notor)",) * 2))
        hits = sorted(f for f in os.listdir(folder) if rx.search(f)) if os.path.isdir(folder) else []
        if len(hits) == 1:
            return os.path.join(folder, hits[0])
        raise CannotRun("no %s AppImage for %s in %s" % (self.variant, version, folder))

    def pick_servers(self):
        if not self.node:
            for u in NODE_PICK:
                if node_up(u):
                    self.node = u
                    break
            self.picked.append("node picked by the driver: %s" % (self.node or "none answered"))
        if not self.relay:
            for h in RELAY_PICK:
                if relay_up(h):
                    self.relay = h
                    break
            self.picked.append("Epicbox picked by the driver: %s" % (self.relay or "none answered"))
        if not self.node or not self.relay:
            raise CannotRun("no node or Epicbox server answers")
        if "://" not in self.node:
            self.node = "https://" + self.node

    def plan(self):
        prev = cand = "?"
        try:
            prev = self.appimage(self.prev_dir, self.prev_ver)
            cand = self.appimage(self.cand_dir, self.cand_ver)
        except CannotRun as e:
            prev = prev if prev != "?" else str(e)
        return [
            "work folder: %s (sandbox HOME %s/home, its own Xvfb, dbus, keyring)" % (self.work, self.sb),
            "previous: %s" % prev,
            "in between: %s" % (self.appimage(self.via_dir, self.via_ver) if self.via_ver else "none"),
            "candidate: %s" % cand,
            "node: %s; Epicbox: %s (picked from %s / %s when unset)" % (self.node or "-", self.relay or "-", NODE_PICK, RELAY_PICK),
            "loopback stand-ins: node http://127.0.0.1:<free port> -> REL_NODE, relay 127.0.0.1:<free port> -> REL_EPICBOX",
            "previous app: create wallet (the depth dial, where shown: Deep end), Settings: node + stand-in node, Epicbox + stand-in relay, Light theme, label, %d confirmation(s), Technical details" % TEST_CONFIRMATIONS,
            "fund: P -> wallet %s EPIC via Epicbox (shared P service %s, no lock), wait until spendable" % (FUND_IN, self.p.lock_file),
            "digest: address, balance, activity, node and Epicbox lists, settings, data folder files",
            "seed (previous app stopped): a contact in contacts.json, a note in wfe_meta.json, the stand-in node in lan_nodes.json; "
            "file set and hashes taken just before the candidate starts",
            "swap: stop the previous app, start the candidate on the same HOME, unlock, same digest; a candidate with levels must name Deep end (level 3) in Settings › About, "
            "ask no depth and run no first-run server pick (its log line moves servers); a last-session notice is noted and left to close",
            ("migration checks (%s): %s present and %s absent in wallets/*/lepic/, %s kept, sealed app files and the address-book key present "
             "with the plain files unchanged, [node] plain_http holds lan_nodes.json's agreements, the contact and note read through the UI" % (
                 ",".join(MIGRATION_CHECKS), facts.STORE_ENC, facts.STORE_PLAIN, facts.STORE_PRE)) if self.migrate else
            "migration checks: not applicable (candidate %s keeps the plain database)" % self.cand_ver,
            ("funds: P -> wallet %s, then everything back to P" % FUND_AFTER) if self.funds else
            ("funds: none checked; %s" % ("balance left in the sandbox (REL_KEEP_FUNDS=1)" if self.keep_funds else "balance sent back to P")),
            "checks required: %s; proof: %s/proof.json" % (",".join(self.required), self.out),
        ]

    def start_standins(self):
        for kind, up in (("node", self.node), ("relay", self.relay)):
            port = free_port()
            log = open(os.path.join(self.out, "standin-%s.log" % kind), "w")
            p = subprocess.Popen([sys.executable, "-I", os.path.join(HERE, "standin.py"), kind, str(port), up],
                                 stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
            self.standins.append(p)
            self.ports[kind] = port
        # one slow answer from the upstream node is not a dead stand-in: three tries
        for attempt in range(3):
            time.sleep(1 if attempt == 0 else 5)
            if node_up("http://127.0.0.1:%d" % self.ports["node"]):
                break
            self.log("loopback node stand-in: no answer in 10 s (try %d)" % (attempt + 1))
        else:
            raise CannotRun("loopback node stand-in does not answer")
        self.custom_node = "127.0.0.1:%d" % self.ports["node"]
        self.custom_relay = "127.0.0.1:%d" % self.ports["relay"]

    def extract(self, appimage, name):
        dest = os.path.join(self.work, name)
        os.makedirs(dest, exist_ok=True)
        copy = os.path.join(dest, "app.AppImage")
        shutil.copyfile(appimage, copy)
        os.chmod(copy, 0o700)
        r = subprocess.run([copy, "--appimage-extract"], cwd=dest, capture_output=True, text=True, timeout=300)
        os.unlink(copy)
        root = os.path.join(dest, "squashfs-root")
        if r.returncode != 0 or not os.path.exists(os.path.join(root, "AppRun")):
            raise CannotRun("could not extract %s: %s" % (appimage, r.stderr[-300:]))
        return root

    # ---- the app

    def start_app(self, root, what):
        pid = sandbox.app(self.sb, root)
        self.log("%s app started (pid %d)" % (what, pid))
        ui = self.ui
        end = time.time() + 90
        while time.time() < end:
            if ui.find_app() is not None and ui.nodes():
                time.sleep(2)
                self.app_version_seen = self.app_version()
                self.log("%s app shows %s" % (what, self.app_version_seen))
                return
            time.sleep(1)
        raise CannotRun("%s app shows no window in 90 s" % what)

    def app_version(self):
        for t in self.ui.texts():
            m = re.search(r"(?:Epic Cash Desktop|BT Wallet) (\d+\.\d+\.\d+)\b.*\(([0-9a-f]{7,})\)", t)
            if m:
                return "%s (%s)" % (m.group(1), m.group(2))
        return "?"

    def create_wallet(self):
        ui = self.ui
        ui.wait("re:^Create a new wallet", 60)
        self.log("first screen: %s" % self.app_version())
        self.shot("prev-welcome")
        self.pass_depth_dial()
        ui.click("re:^Create a new wallet")
        ui.wait("re:^Create wallet$", 30)
        pw = open(os.path.join(self.sb, "wallet.pw")).read()
        pws = [f for f in ui.fields() if "password" in f.role]
        if len(pws) < 2:
            raise CannotRun("create: %d password fields" % len(pws))
        ui.fill(0, pw)
        ui.fill(1, pw)
        ui.key("Return")
        ui.wait("re:^Reveal phrase$", 180)
        self.shot("prev-phrase-hidden")
        ui.click("re:^Reveal phrase$")
        time.sleep(1.5)
        words = phrase_words([n.name for n in ui.nodes()])
        if len(words) not in (12, 24):
            raise CannotRun("recovery phrase not readable (%d words)" % len(words))
        with open(os.path.join(self.sb, "phrase.txt"), "w") as f:
            f.write(" ".join(words) + "\n")
        os.chmod(os.path.join(self.sb, "phrase.txt"), 0o600)
        del words
        self.log("wallet created; phrase kept in the sandbox (mode 600), not printed")
        self.tick_written_down()
        ui.click("re:^Continue$", timeout=20)
        i = ui.wait_any(["re:^Skip setup$", "re:^Unlock wallet$", "Main navigation"], 120)
        if i == 0:
            ui.click("re:^Skip setup$")
            i = ui.wait_any(["re:^Unlock wallet$", "Main navigation"], 120) + 1
        if i == 1:
            self.screen("before", "wallets", "Unlock after creating, before the password is typed (the field empty)")
            self.unlock()
        else:
            self.screens.miss("before-wallets", "the previous release opened the new wallet without its Unlock screen; "
                                                "not navigated to (locking costs a password retype)")
        self.after_unlock()

    def pass_depth_dial(self):
        """Welcome of a fresh install on a build with wallet levels: the depth dial (Shallow / Deeper /
        Deep end) is answered before the doors open. Deep end = level 3, the app a release before levels
        shows. Nothing on a build without the dial."""
        ui = self.ui
        stop = "re:^%s$" % re.escape(facts.LEVEL_DEEP_END)
        found = ui.find(stop)
        if not found:
            return
        if "checked" not in found[0].states:
            ui.click(stop)
            time.sleep(1.2)
        self.log("depth dial: %s (level 3)" % facts.LEVEL_DEEP_END)

    def level_shown(self):
        """The depth Settings › About names ("View: Deep end"; "Depth: …" before the 26.10.25 rename); None on a build without levels."""
        try:
            self.settings_page("About")
        except Exception as e:  # never sinks the run: the level then reads as not shown, and the log says why
            self.log("Settings › About not opened for the level: %s" % e)
            return None
        rx = re.compile(r"^%s: (.+)$" % re.escape(facts.DESK_DEPTH))
        for n in self.ui.find(rx):
            return rx.match(n.name).group(1).strip()
        return None

    def tick_written_down(self):
        ui = self.ui
        cb = [n for n in ui.nodes() if n.role == "check box"]
        if not cb:
            raise CannotRun("no 'written down' check box")
        if "checked" in cb[0].states:
            return
        if cb[0].actions and ui.tap(cb[0]):
            time.sleep(0.5)
        else:
            # no AT-SPI action on this check box: scroll to the bottom, find the empty box on screen
            ui.scroll("down", 12)
            time.sleep(0.8)
            x, y, w, h = ui.window()
            png = os.path.join(self.sb, "tmp", "cb.png")
            ui.screenshot(png)
            boxes = ui.checkbox_squares(png, (x + w // 4, y + h // 2, x + w * 3 // 4, y + h - 40))
            os.unlink(png)
            for c in reversed(boxes):
                ui.xclick(*c)
                time.sleep(0.6)
                if any("checked" in n.states for n in ui.nodes() if n.role == "check box"):
                    break
        if not any("checked" in n.states for n in ui.nodes() if n.role == "check box"):
            raise CannotRun("could not tick 'written down'")

    def unlock(self):
        ui = self.ui
        ui.wait("re:^Unlock wallet$", 120)
        pw = open(os.path.join(self.sb, "wallet.pw")).read()
        if not [f for f in ui.fields() if "password" in f.role]:
            raise CannotRun("unlock: no password field")
        ui.fill(0, pw)
        ui.click("re:^Unlock$", role="button")
        i = ui.wait_any(["Main navigation", "re:(?i)wrong password|incorrect|did not unlock"], 180)
        if i != 0:
            raise CannotRun("unlock refused")

    def after_unlock(self):
        ui = self.ui
        ui.wait("Main navigation", 180)
        time.sleep(2)
        self.last_session_toast()
        for _ in range(3):
            if ui.has("re:^Skip tour$"):
                ui.click("re:^Skip tour$")
                time.sleep(1)
        if ui.has("re:^Skip setup$"):
            ui.click("re:^Skip setup$")
            time.sleep(1)

    def last_session_toast(self):
        """A build with the last-session report offers a crashed or killed session's log once after
        unlock, as a toast with a Send button (5f9933de6). A user lets it go ("Not now" is the toast
        leaving); the driver does the same and waits it out, so a "Send" press never lands on the
        toast's button. It is noted in the proof, never hidden: after the update it would mean the
        candidate took the previous release's clean close for a crash."""
        ui = self.ui
        rx = "re:^(%s|%s)" % (re.escape(LAST_SESSION), re.escape(LAST_SESSION_FROZE))
        found = ui.find(rx)
        if not found:
            return
        text = found[0].name.split("\n")[0]
        app = getattr(self, "app_version_seen", "?")
        self.log("last-session notice shown by %s: %r; left to close by itself (Not now)" % (app, text))
        self.shot("last-session-notice")
        self.details.setdefault("last_session", "%s showed %r after unlock" % (app, text))
        try:
            ui.wait(rx, 20, gone=True)
        except TimeoutError:
            ui.key("Escape")
            time.sleep(0.8)

    def nav(self, name):
        # A long wait (P busy with another check) can pass the auto-lock: unlock as the user would.
        if self.ui.has("re:^Unlock wallet$"):
            self.log("the wallet locked itself while waiting (auto-lock): unlocking again")
            self.unlock()
            self.after_unlock()
        self.last_session_toast()
        self.ui.click("re:^%s$" % re.escape(name), role="button")
        time.sleep(1.2)

    def settings_page(self, section):
        """Settings › [section]: from the section list beside the page, the chips above it, or (a page
        too narrow for two rows of chips) the dropdown that names the section shown."""
        self.nav("Settings")
        ui = self.ui
        want = "re:^%s$" % re.escape(section)
        shown = {n.name.strip() for n in ui.nodes() if n.role == "button" and n.name.strip() in SECTIONS}
        if len(shown) != 1:
            ui.click(want, role="button")
        elif section not in shown:
            current = shown.pop()
            ui.click("re:^%s$" % re.escape(current), role="button")
            time.sleep(0.8)
            try:
                ui.click(want, timeout=8)
            except LookupError:
                ui.key("Escape")
                time.sleep(0.5)
                raise LookupError("Settings dropdown (on %s) lists no %s" % (current, section))
        time.sleep(1.2)

    def combo(self, label):
        """The server picker's trigger button ('Node server: …' / 'Epicbox server: …')."""
        found = self.ui.find("re:^%s: " % label)
        if not found:
            raise LookupError("no %s picker" % label)
        return found[0]

    def open_picker(self, label):
        ui = self.ui
        for attempt in range(4):
            ui.tap(self.combo(label))
            end = time.time() + 8
            while time.time() < end:
                if [f for f in ui.fields() if "focused" in f.states] or ui.has("re:^Use "):
                    return
                time.sleep(0.4)
            self.log("%s picker not open yet (try %d)" % (label, attempt + 1))
            ui.key("Escape")
            time.sleep(1)
        raise LookupError("%s picker did not open" % label)

    def picker_entries(self, label, phase=None, point=None):
        """[(entry, row text, in use)] of the open picker (rows 'Use <entry>, …'); with [phase] the open list
        is the catalogue's [point] screen."""
        self.open_picker(label)
        time.sleep(1.5)
        if point:
            self.screen(phase, point, "Settings, %s list open: the user's own entry and the one in use" % label)
        rows = []
        for n in self.ui.find("re:^Use "):
            if n.role != "button":
                continue
            entry = n.name[4:].split(",")[0].strip()
            rows.append((entry, n.name, "selected" in n.states or ", In use" in n.name))
        self.ui.key("Escape")
        time.sleep(0.8)
        return rows

    def in_use(self, label, entry):
        found = self.ui.find("re:^%s: " % label)
        if not found:
            return False
        rest = found[0].name[len(label) + 2:]
        return rest == entry or rest.startswith(entry + ",")

    def listed(self, entry):
        return any(n.name[4:].split(",")[0].strip() == entry for n in self.ui.find("re:^Use ") if n.role == "button")

    def use_server(self, label, typed, entry, use):
        """Type [typed] into the picker and press 'Use <entry>' or 'Add <entry>'. Done when the entry is
        listed (use False: adding a server of one's own) or in use (use True; a 'Switch to' offer is taken)."""
        ui = self.ui
        if use and self.in_use(label, entry):
            return
        self.open_picker(label)
        ui.fill(0, typed)
        time.sleep(1.5)
        ui.click("re:^(Use %s(,|$)|Add %s$)" % (re.escape(entry), re.escape(entry)), timeout=20)
        end = time.time() + 120
        while time.time() < end:
            time.sleep(1.5)
            if use and self.in_use(label, entry):
                break
            if ui.has("re:(?i)no answer from this server|nothing added|not a node"):
                raise CannotRun("%s %s refused: %s" % (label, entry, "; ".join(t for t in ui.texts() if "answer" in t or "added" in t)))
            sw = [n for n in ui.find("re:^Switch") if n.actions]
            if use and sw:
                ui.tap(sw[0])
                continue
            if not use:
                if self.in_use(label, entry):
                    break
                if not ui.find("re:^Use "):
                    self.open_picker(label)
                    time.sleep(1.5)
                if self.listed(entry):
                    break
        else:
            raise CannotRun("%s %s never %s" % (label, entry, "in use" if use else "listed"))
        if ui.find("re:^Use ") or [f for f in ui.fields() if "focused" in f.states]:
            ui.key("Escape")
            time.sleep(0.8)

    def set_servers(self):
        node_entry = re.sub(r"^https://", "", self.node).rstrip("/")
        self.settings_page("Node")
        self.use_server("Node server", "http://%s" % self.custom_node, self.custom_node, False)
        self.log("custom node %s added" % self.custom_node)
        self.use_server("Node server", self.node, node_entry, True)
        self.log("node in use: %s" % node_entry)
        self.shot("prev-node")
        self.relay_page()
        self.use_server("Epicbox server", self.custom_relay, self.custom_relay, False)
        self.log("custom Epicbox server %s added" % self.custom_relay)
        self.use_server("Epicbox server", self.relay, self.relay, True)
        self.log("Epicbox in use: %s" % self.relay)
        self.shot("prev-relay")

    def page_with(self, sections, pattern, what):
        """The first of [sections] that shows [pattern]: one setting's page in either layout. Where the
        page lists its sections, the ones this build has not are not tried."""
        self.nav("Settings")
        shown = {n.name.strip() for n in self.ui.nodes() if n.role == "button" and n.name.strip() in SECTIONS}
        if len(shown) > 1:
            sections = [x for x in sections if x in shown] or sections
        for section in sections:
            try:
                self.settings_page(section)
            except LookupError:
                continue
            if self.ui.find(pattern):
                return section
        raise LookupError("no %s under Settings (%s)" % (what, ", ".join(sections)))

    def relay_page(self):
        self.page_with(RELAY_PAGES, "re:^Epicbox server: ", "Epicbox server picker")

    def label_page(self):
        self.page_with(LABEL_PAGES, "re:^(Save label|Name)$", "wallet label")

    def confirmations_page(self):
        self.page_with(CONFIRMATIONS_PAGES, "re:^Fewer confirmations$", "confirmations stepper")

    def label_field(self):
        """The wallet label's field: named Name from 26.10.25, else the page's first text field."""
        f = [x for x in self.ui.fields() if x.role != "password text"]
        named = [i for i, x in enumerate(f) if x.name.strip() == "Name"]
        return (named[0] if named else 0), f

    def change_settings(self):
        ui = self.ui
        self.settings_page("Appearance")
        ui.click("re:^Light$", role="button")
        self.label_page()
        i, label_fields = self.label_field()
        if not label_fields:
            raise CannotRun("no wallet label field")
        ui.fill(i, self.label)
        ui.click("re:^Save label$")
        time.sleep(1)
        self.confirmations_page()
        for _ in range(30):
            v = self.confirmations()
            if v is None or v <= TEST_CONFIRMATIONS:
                break
            ui.click("re:^Fewer confirmations$")
            time.sleep(0.5)
        self.settings_page("Advanced")
        t = ui.find("re:^Technical details$", role="toggle button")
        if t and "checked" not in t[0].states:
            ui.tap(t[0])
            time.sleep(0.6)
        self.shot("prev-settings")

    def confirmations(self):
        """The confirmations count: the field named Confirmations (26.10.25: Payments, beside the
        Epicbox port), else the page's first number field (Advanced up to 26.10.24)."""
        fl = self.ui.fields()
        for f in [x for x in fl if x.name.strip() == "Confirmations"] + fl:
            if f.value and f.value.isdigit():
                return int(f.value)
        return None

    # ---- reading the wallet

    def address(self):
        self.nav("Receive")
        for f in self.ui.fields():
            v = (f.value or "").strip()
            if re.fullmatch(r"[1-9A-HJ-NP-Za-km-z]{40,60}(@[\w.:-]+)?", v):
                return v
        for t in self.ui.texts():
            m = re.search(r"\b([1-9A-HJ-NP-Za-km-z]{48,56})(@[\w.:-]+)?", t)
            if m:
                return m.group(0)
        return None

    def balance(self):
        self.nav("Overview")
        ui = self.ui
        if ui.has("re:^Refresh$"):
            try:
                ui.click("re:^Refresh$", timeout=3)
                time.sleep(3)
            except LookupError:
                pass
        t = ui.texts()
        if "Available to spend" not in t:
            return None
        i = t.index("Available to spend")
        end = t.index("Recent activity") if "Recent activity" in t else len(t)
        part = t[i + 1:end]
        vals = [(j, epic(x)) for j, x in enumerate(part) if epic(x) is not None]
        if not vals:
            return None
        out = {"available": vals[0][1]}
        # the other figures: one block of amounts, their captions just before it in the same order
        block = [vals[-1]]
        for v in reversed(vals[1:-1]):
            if v[0] == block[0][0] - 1:
                block.insert(0, v)
            else:
                break
        if len(vals) > 1:
            caps = part[block[0][0] - len(block):block[0][0]]
            for c, (_, a) in zip(caps, block):
                out[re.sub(r"[^a-z]+", "_", c.lower()).strip("_")] = a
        return out

    def activity(self, phase=None):
        self.nav("Activity")
        time.sleep(1)
        self.screen(phase, "history", "Activity")
        rows = []
        for n in self.ui.nodes():
            first = n.name.split("\n")[0]
            if (re.match(r"^(Received|Sent|Receiving|Sending|Cancelled|Confirming|Waiting|Restored|Incoming|Outgoing|Found)\b", first)
                    and ("EPIC" in n.name or re.search(r"[+-]\d+\.\d+", n.name))):
                rows.append(n.name.replace("\n", " | "))
        return rows

    def lists(self, phase=None):
        out = {}
        self.settings_page("Node")
        out["node_in_use"] = self.combo("Node server").name
        out["nodes"] = self.picker_entries("Node server", phase, "settings-node")
        self.relay_page()
        out["relay_in_use"] = self.combo("Epicbox server").name
        out["relays"] = self.picker_entries("Epicbox server", phase, "settings-epicbox")
        return out

    def settings(self):
        ui = self.ui
        out = {}
        self.settings_page("Appearance")
        themes = ui.find(re.compile(r"^(System|Dark|Light)$"), role="button")
        sel = [n.name for n in themes if "selected" in n.states]
        if not sel and len({n.name for n in themes}) == 1:
            sel = [themes[0].name]  # a narrow page's dropdown names only the theme chosen
        out["theme"] = sel[0] if sel else None
        self.label_page()
        i, f = self.label_field()
        out["label"] = f[i].value if f else None
        self.confirmations_page()
        out["confirmations"] = self.confirmations()
        self.settings_page("Advanced")
        t = ui.find("re:^Technical details$", role="toggle button")
        out["technical_details"] = ("checked" in t[0].states) if t else None
        return out

    def files(self):
        root = os.path.join(self.sb, "home", ".epic_cash_desktop")
        out = []
        for dp, dn, fn in os.walk(root):
            rel = os.path.relpath(dp, root)
            if rel.split(os.sep)[0] in ("logs", "tor", "cache"):
                continue
            for f in fn:
                if f.endswith((".lock", ".log")) or f.startswith("LOCK"):
                    continue
                out.append(os.path.normpath(os.path.join(rel, f)))
        return sorted(out)

    def digest(self, tag):
        phase = {"previous": "before", "candidate": "after"}.get(tag)  # the in-between release: no catalogue screens
        d = {"app": self.app_version_seen, "address": self.address(), "balance": self.balance(),
             "activity": self.activity(phase)}
        d.update(self.lists(phase))
        d["settings"] = self.settings()
        if tag == "candidate":
            d["level"] = self.level_shown()
        d["files"] = self.files()
        self.nav("Overview")
        self.shot("%s-overview" % tag)
        self.screen(phase, "home", "Overview")
        with open(os.path.join(self.out, "digest-%s.json" % tag), "w") as f:
            json.dump(d, f, indent=1, default=str)
        self.log("digest %s: address %s, balance %s, %d activity rows, node %s, relay %s, settings %s, %d files" % (
            tag, short(d["address"]), d["balance"], len(d["activity"]), d["node_in_use"], d["relay_in_use"],
            d["settings"], len(d["files"])))
        return d

    # ---- funds

    def wait_spendable(self, at_least, what, timeout=1800):
        """Waits until nothing is confirming and the available balance is at least [at_least]."""
        end = time.time() + timeout
        last = None
        while time.time() < end:
            b = self.balance()
            if b != last:
                self.log("%s: balance %s" % (what, b))
                last = b
            if b and b["available"] >= at_least and all(v == 0 for k, v in b.items() if k not in ("available", "total")):
                return b
            time.sleep(20)
        raise TimeoutError("%s: not spendable in %d s (last %s)" % (what, timeout, last))

    def budget(self, amount):
        a = D(amount)
        if a > CAP_SEND or self.spent + a > CAP_JOB:
            raise CannotRun("amount %s over the caps (%s per send, %s per job, %s used)" % (amount, CAP_SEND, CAP_JOB, self.spent))
        self.spent += a

    def fund(self, address, amount, what):
        self.budget(amount)
        b0 = self.balance() or {}
        base = b0.get("available", D(0)) + b0.get("confirming", D(0))
        with self.p.exchange(what) as p:
            if not p.start_listener():
                return False, "P's listener did not start (3 tries)"
            ok, out = p.send(address, amount)
            self.log("P -> %s %s: %s (%s)" % (short(address), amount, "sent" if ok else "FAILED", out))
            if not ok:
                return False, "P send failed: %s" % out
            # the wallet answers through Epicbox, P's listener finalizes and posts: the amount moves
            # from waiting (for the sender) to confirming or available
            end = time.time() + 900
            last = None
            while time.time() < end:
                b = self.balance() or {}
                if b != last:
                    self.log("%s: balance %s" % (what, fmt_bal(b)))
                    last = b
                got = b.get("available", D(0)) + b.get("confirming", D(0))
                waiting = sum((v for k, v in b.items() if "waiting" in k or "finaliz" in k), D(0))
                if got >= base + D(amount) and waiting == 0:
                    break
                time.sleep(15)
            else:
                return False, "not received and posted in 15 min (balance %s)" % fmt_bal(last or {})
            rows = self.activity()
            self.log("%s: activity %s" % (what, rows[:2]))
        return True, rows[0] if rows else "received"

    def send_to_p(self, amount, what):
        """Send [amount] (None: the page's Max) to P through the Send page, P's listener answering;
        True when the wallet shows the payment posted."""
        ui = self.ui
        with self.p.exchange(what) as p:
            if not p.start_listener():
                return False, "P's listener did not start (3 tries)"
            self.nav("Send")
            if ui.has("re:^Send another$"):
                ui.click("re:^Send another$")
            # the method row: Epicbox pressed only as a segment beside Link (a narrow row's dropdown
            # names just the method chosen, and pressing it would only open the list)
            eb = ui.find("re:^Epicbox$", role="button")
            if eb and ui.find("re:^Link$", role="button") and "selected" not in eb[0].states:
                ui.tap(eb[0])
                time.sleep(0.8)
            ui.fill(0, self.p_addr)
            if amount is None:
                # "Max" before "All": the advanced panel's coin choice is also named All
                mx = [n for n in ui.find("re:^Max$", role="button") if n.actions] or \
                     [n for n in ui.find("re:^All$", role="button") if n.actions]
                if not mx:
                    return False, "no Max button on the Send page"
                ui.tap(mx[0])
                time.sleep(2)
                f = [x for x in ui.fields() if "password" not in x.role]
                amount = (f[1].value or "").strip() if len(f) > 1 else ""
                if epic(amount + " EPIC") is None:
                    return False, "Max filled %r" % amount
            else:
                ui.fill(1, amount)
            self.budget(amount)
            self.sent_amount = amount
            time.sleep(2)
            self.shot("send-filled")
            self.press_review()
            ui.wait("re:Check and send", 60)
            self.shot("send-review")
            pw_fields = [i for i, f in enumerate(ui.fields()) if "password" in f.role]
            if pw_fields:
                ui.fill(pw_fields[0], open(os.path.join(self.sb, "wallet.pw")).read())
                time.sleep(0.5)
            ui.click(re.compile(r"^Send [\d.,]+ EPIC$"), role="button", timeout=20)
            ui.wait("re:Check and send", 300, gone=True)
            time.sleep(3)
            self.shot("send-after")
            if ui.has("re:(?i)send failed|not sent"):
                return False, "the app says: %s" % "; ".join(t for t in ui.texts() if re.search("(?i)fail|not sent", t))[:300]
            # P's listener answers, the wallet finalizes and posts: nothing waits any more
            end = time.time() + 900
            last = None
            while time.time() < end:
                b = self.balance() or {}
                if b != last:
                    self.log("%s: balance %s" % (what, fmt_bal(b)))
                    last = b
                rows = self.activity()
                waiting = sum((v for k, v in b.items() if "waiting" in k or "finaliz" in k), D(0))
                # the newest Sent row is this send: done once posted (Waiting for a block, Confirming,
                # Sent); Posting… is still on its way, Not on the network its post failed (kept
                # waiting for: the app may post it again)
                sent = [r for r in rows if r.startswith("Sent")][:1]
                done = [r for r in sent if not re.search(r"(?i)waiting for (the )?recipient|cancel|not sent|failed", r)
                        and POSTING not in r and not any(w in r for w in NOT_POSTED)]
                if done and waiting == 0:
                    return True, done[0]
                time.sleep(15)
            return False, "not finalized and posted in 15 min (balance %s; rows %s)" % (fmt_bal(last or {}), self.activity()[:2])

    def press_review(self):
        ui = self.ui
        for pat in ("re:^Review send$", "re:^Review$"):
            for n in ui.find(pat, role="button"):
                if n.actions and ui.tap(n):
                    return
        # no action on the footer button: Ctrl+Enter runs a form's main action
        ui.key("ctrl+Return")
        try:
            ui.wait("re:Check and send", 10)
        except TimeoutError:
            raise CannotRun("could not open the send review")

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
        if self.funds and not self.required:
            pass
        prev = self.appimage(self.prev_dir, self.prev_ver)
        cand = self.appimage(self.cand_dir, self.cand_ver)
        via = self.appimage(self.via_dir, self.via_ver) if self.via_ver else None
        why = self.p.ready()
        if why:
            raise CannotRun(why)
        self.pick_servers()
        for line in self.picked:
            self.log(line)
        os.makedirs(self.sb, mode=0o700, exist_ok=True)
        self.log("work folder %s" % self.work)
        self.details["appimages"] = "previous %s (sha256 %s), candidate %s (sha256 %s)" % (
            os.path.basename(prev), sha256(prev)[:16], os.path.basename(cand), sha256(cand)[:16])
        if via:
            self.details["appimages"] += ", in between %s (sha256 %s)" % (os.path.basename(via), sha256(via)[:16])
        self.log(self.details["appimages"])
        prev_root = self.extract(prev, "previous")
        self.via_root = self.extract(via, "via") if via else None
        cand_root = self.extract(cand, "candidate")
        self.label = "Trust %s" % datetime.datetime.now().strftime("%m%d %H%M")
        with open(os.path.join(self.sb, "wallet.pw"), "w") as f:
            f.write(__import__("secrets").token_urlsafe(16))
        os.chmod(os.path.join(self.sb, "wallet.pw"), 0o600)
        self.start_standins()
        sandbox.start(self.sb)
        os.environ["TRUST_SB"] = self.sb
        import ui  # noqa: E402  (reads the sandbox's env on import, refuses anything else)
        self.ui = ui
        try:
            return self.flow(prev_root, cand_root)
        finally:
            self.shutdown()

    def flow(self, prev_root, cand_root):
        ui = self.ui
        # previous release: the user's wallet and choices
        self.start_app(prev_root, "previous")
        self.create_wallet()
        self.set_servers()
        self.change_settings()
        addr = self.address()
        if not addr:
            raise CannotRun("no Epicbox address on the Receive page")
        full = addr if "@" in addr else "%s@%s" % (addr, self.relay)
        ok, why = self.fund(full, FUND_IN, "funding before the update")
        if not ok:
            raise CannotRun("funding: %s" % why)
        self.wait_spendable(D(FUND_IN), "funding confirmed")
        before = self.digest("previous")
        if not before["activity"]:
            raise CannotRun("no activity row before the update")

        # the update: the AppImage changes, HOME and the data folder stay
        sandbox.app_stop(self.sb)
        self.log("previous app stopped")
        if self.seed_files:
            self.seed_previous_files()
        if self.via_root:
            self.via_hop(before)
        self.before_files = self.snapshot()
        self.start_app(cand_root, "candidate")
        opened, why = self.open_after_update(before)
        self.details["wallet_opens"] = why
        if not opened:
            self.fail("wallet_opens", why)
            for p in catalog.POINTS[1:]:
                self.screens.miss("after-" + p, "not reached: the candidate did not open the wallet")
            for c in ("balance_kept", "history_kept", "custom_nodes_kept", "custom_relays_kept", "settings_kept", *MIGRATION_CHECKS):
                self.fail(c, "not checked: the wallet did not open")
            after = None
        else:
            # give the candidate a moment to read the chain before reading the balance
            time.sleep(20)
            after = self.digest("candidate")
            self.settle(before, after)
            self.compare(before, after)
            self.migration_checks()
        self.funds_legs(after)
        return 0

    def via_hop(self, before):
        """The release in between (REL_VIA_*): opened on the same HOME and read once, then stopped."""
        self.start_app(self.via_root, "in-between %s" % self.via_ver)
        opened, why = self.open_after_update(before)
        if not opened:
            raise CannotRun("the in-between release %s: %s" % (self.via_ver, why))
        time.sleep(20)
        mid = self.digest("via")
        e0 = lambda d, k: [x[0] for x in d[k]]
        self.details["via"] = "%s opened (%s); node %s, list %s; Epicbox %s, list %s" % (
            self.via_ver, mid["app"], mid["node_in_use"], ", ".join(e0(mid, "nodes")),
            mid["relay_in_use"], ", ".join(e0(mid, "relays")))
        self.log("in between: %s" % self.details["via"])
        sandbox.app_stop(self.sb)
        self.log("in-between app stopped")

    def open_after_update(self, before):
        ui = self.ui
        try:
            i = ui.wait_any(["re:^Unlock wallet$", "re:^Create a new wallet", "Main navigation",
                             "re:^%s$" % re.escape(facts.LEVEL_PICK_TITLE)], 120)
        except TimeoutError:
            return False, "the candidate shows neither Unlock nor the wallet in 2 min"
        self.shot("cand-first")
        # an existing install is level 3 and never asked (levels-backend): the depth dial or the
        # picker before unlock means the update took it for a fresh install
        dial = [n for n in ui.find("re:^%s$" % re.escape(facts.LEVEL_DEEP_END)) if n.role != "label"]
        if i == 3 or dial:
            return False, "the candidate asks for the depth (%s) as on a fresh install" % (
                facts.LEVEL_PICK_TITLE if i == 3 else "the dial's %s" % facts.LEVEL_DEEP_END)
        if i == 0:
            self.screen("after", "wallets", "Unlock as the candidate opens after the update, before the password is typed (the field empty)")
        else:
            self.screens.miss("after-wallets", "the candidate did not show its Unlock screen after the update")
        if i == 1:
            return False, "the candidate offers 'Create a new wallet': it found no wallet"
        names = ui.texts()
        if i == 0:
            if before["settings"].get("label") and before["settings"]["label"] not in names:
                self.log("unlock screen does not show %r (shows %s)" % (before["settings"]["label"], [t for t in names if len(t) < 40][:12]))
            try:
                self.unlock()
            except CannotRun as e:
                return False, "unlock failed: %s" % e
        self.after_unlock()
        addr = self.address()
        same, why = facts.same_wallet(before["address"], addr)
        if not same:
            return False, why
        return True, "unlocked with the same password; same Epicbox address %s" % short(why)

    def settle(self, b, a, wait_s=150):
        """A wallet may still be refreshing when first read: the balance and activity are read again for
        up to [wait_s] until they match. The first reading is kept for the details."""
        a["first_balance"], a["first_activity"] = a["balance"], a["activity"]
        t0 = time.time()
        while time.time() - t0 < wait_s:
            if (a["balance"] or {}).get("available") == (b["balance"] or {}).get("available") and \
                    all(any(same_row(r, x) for x in a["activity"]) for r in b["activity"]):
                break
            time.sleep(15)
            a["balance"], a["activity"] = self.balance(), self.activity("after")
        a["settled_after_s"] = int(time.time() - t0)
        if a["balance"] != a["first_balance"] or a["activity"] != a["first_activity"]:
            self.log("after %d s: balance %s, activity %s (first read: %s, %s)" % (
                a["settled_after_s"], fmt_bal(a["balance"] or {}), a["activity"], fmt_bal(a["first_balance"] or {}), a["first_activity"]))
            self.nav("Overview")
            self.shot("candidate-overview-later")
            self.screen("after", "home", "Overview, once the balance and activity settled")
        with open(os.path.join(self.out, "digest-candidate.json"), "w") as f:
            json.dump(a, f, indent=1, default=str)

    def compare(self, b, a):
        self.ok("wallet_opens", self.details.get("wallet_opens") or "opened; same address")

        b0, b1, f1 = b["balance"] or {}, a["balance"] or {}, a.get("first_balance") or {}
        late = "" if f1 == b1 else "; first shown %s, this after %d s" % (fmt_bal(f1), a.get("settled_after_s", 0))
        rebuilt = [r for r in a["activity"] if counterparty(r) == "Found by recheck"
                   and not any(counterparty(x) == "Found by recheck" for x in b["activity"])]
        same = b1.get("available") == b0.get("available") and b1.get("total", b1.get("available")) == b0.get("total", b0.get("available"))
        if same and late and rebuilt:
            self.fail("balance_kept", "the update showed %s; %s EPIC came back only after %d s, found again on the chain by a recheck "
                      "(the wallet's own records were not carried over)" % (fmt_bal(f1), num(b0.get("available")), a.get("settled_after_s", 0)))
        elif same:
            self.ok("balance_kept", "available %s, total %s EPIC before and after%s" % (num(b0.get("available")), num(b0.get("total")), late))
        else:
            self.fail("balance_kept", "before %s, after %s (read for %d s)" % (fmt_bal(b0), fmt_bal(b1), a.get("settled_after_s", 0)))
        missing = [r for r in b["activity"] if not any(same_row(r, x) for x in a["activity"])]
        changed = ["%s → %s" % (r[:70], next(x for x in a["activity"] if same_row(r, x))[:70]) for r in b["activity"]
                   if r not in missing and not any(same_row(r, x) and counterparty(r) == counterparty(x) for x in a["activity"])]
        if changed and not missing:
            self.fail("history_kept", "rows kept but their details lost (who paid or was paid): %s" % "; ".join(changed))
        elif not missing and len(a["activity"]) >= len(b["activity"]):
            self.ok("history_kept", "%d activity rows kept (%s)" % (len(b["activity"]), "; ".join(r[:70] for r in b["activity"])))
        else:
            self.fail("history_kept", "%d of %d rows missing after the update: %s; after: %s" % (
                len(missing), len(b["activity"]), "; ".join(r[:70] for r in missing), "; ".join(r[:70] for r in a["activity"]) or "none"))
        self.compare_list("node", b, a, self.custom_node, re.sub(r"^https://", "", self.node).rstrip("/"))
        self.compare_list("relay", b, a, self.custom_relay, self.relay)
        s0, s1 = b["settings"], a["settings"]
        diff = {k: (s0.get(k), s1.get(k)) for k in s0 if s0.get(k) != s1.get(k)}
        if not diff and all(v is not None for v in s0.values()):
            self.ok("settings_kept", "theme %s, label %r, %s confirmations, Technical details %s" % (
                s0["theme"], s0["label"], s0["confirmations"], "on" if s0["technical_details"] else "off"))
        else:
            self.fail("settings_kept", "changed (before, after): %s" % (diff or {k: v for k, v in s0.items() if v is None}))
        lv, why = facts.level_after_update(a.get("level"))
        self.details["level"] = why
        if lv is False:
            self.fail("settings_kept", "%s; %s" % (why, self.details.get("settings_kept", "")))
        gone = [f for f in b["files"] if f not in a["files"]
                and not (self.migrate and os.path.basename(f).startswith(facts.STORE_PLAIN))]  # the plain database is set aside
        self.details["data_folder"] = ("all %d files of the previous data folder still there; %d new" % (
            len(b["files"]), len(set(a["files"]) - set(b["files"])))) if not gone else ("files gone after the update: %s" % ", ".join(gone[:10]))
        self.log("data folder: %s" % self.details["data_folder"])

    # ---- the data an encrypting release must carry over (migration.py)

    def data_root(self):
        return os.path.join(self.sb, "home", ".epic_cash_desktop")

    def read_root(self, rel):
        try:
            with open(os.path.join(self.data_root(), rel), encoding="utf-8") as f:
                return f.read()
        except OSError:
            return None

    def snapshot(self):
        """(listing, hashes): the data folder's files and the sha256 of the plain app files in it."""
        listing = self.files()
        return listing, {p: sha256(os.path.join(self.data_root(), p)) for p in migration.norm(listing)
                         if os.path.basename(p) in migration.WATCHED}

    def seed_previous_files(self):
        """While the previous release is closed: a contact, a note on the wallet's first transaction and the
        stand-in node's plain-http agreement, in its own files and format (seed.py)."""
        root = self.data_root()
        metas = sorted(glob.glob(os.path.join(root, "wallets", "*", facts.META_PLAIN)))
        dbs = sorted(glob.glob(os.path.join(root, "wallets", "*", facts.STORE_DIR, facts.STORE_PLAIN)))
        if len(metas) != 1 or len(dbs) != 1:
            raise CannotRun("the previous release left %d %s and %d %s under wallets/ (one each expected)" % (
                len(metas), facts.META_PLAIN, len(dbs), facts.STORE_PLAIN))

        def put(path, text):
            tmp = path + ".seed"
            with open(tmp, "w", encoding="utf-8") as f:
                f.write(text)
            os.chmod(tmp, 0o600)
            os.replace(tmp, path)

        try:
            with open(metas[0], encoding="utf-8") as f:
                meta = seed.meta_note(f.read(), seed.first_tx_id(dbs[0]))
            contacts = seed.contacts_json(self.read_root(facts.CONTACTS_PLAIN), self.p_addr)
        except (seed.SeedError, OSError) as e:
            raise CannotRun("seeding the previous release's contact and note: %s" % e)
        put(metas[0], meta)
        put(os.path.join(root, facts.CONTACTS_PLAIN), contacts)
        put(os.path.join(root, facts.LAN_NODES_FILE), seed.lan_nodes_json(["http://%s" % self.custom_node]))
        self.lan_before = self.read_root(facts.LAN_NODES_FILE)
        self.log("seeded into the closed previous release: contact %r, note %r, plain-http agreement for %s" % (
            seed.CONTACT["name"], seed.NOTE, self.custom_node))

    def shows(self, page, text):
        """Whether [page] of the app shows [text]; None when the page cannot be reached."""
        try:
            self.nav(page)
            time.sleep(1.5)
            return any(text in t for t in self.ui.texts())
        except LookupError:
            return None

    def note_shown(self):
        shown = self.shows("Activity", seed.NOTE)
        if shown is False:  # not on the row: on its detail page
            try:
                row = [n for n in self.ui.nodes() if re.match(r"^(Received|Sent|Confirming)\b", n.name.split("\n")[0]) and "EPIC" in n.name]
                if row:
                    self.ui.tap(row[0])
                    time.sleep(1.5)
                    shown = any(seed.NOTE in t for t in self.ui.texts())
                    self.ui.key("Escape")
            except LookupError:
                pass
        return shown

    def migration_checks(self):
        if not self.migrate:
            for c in MIGRATION_CHECKS:
                self.ok(c, "not applicable: candidate %s keeps the plain database" % self.cand_ver)
            return
        b_list, b_hash = self.before_files
        a_list, a_hash = self.snapshot()
        (self.ok if (r := migration.store_files(b_list, a_list))[0] else self.fail)("store_encrypted", r[1])
        if not self.seed_files:
            for c in MIGRATION_CHECKS[1:]:
                self.ok(c, "not applicable: the previous release already encrypts (nothing plain to carry over)")
            return
        try:
            with open(os.path.join(self.data_root(), "wallets.json"), encoding="utf-8") as f:
                ids = [w["id"] for w in json.load(f).get("wallets") or [] if isinstance(w, dict) and w.get("id")]
        except (OSError, ValueError):
            ids = []
        (self.ok if (r := migration.app_files(b_list, b_hash, a_list, a_hash, ids))[0] else self.fail)("app_files_kept", r[1])
        r = migration.lan_nodes(self.lan_before, b_hash.get(facts.LAN_NODES_FILE), a_hash.get(facts.LAN_NODES_FILE),
                                self.read_root(facts.SETTINGS_TOML))
        (self.ok if r[0] else self.fail)("lan_nodes_kept", r[1])
        contact = self.shows("Contacts", seed.CONTACT["name"])
        note = self.note_shown()
        if contact is None or note is None:
            self.fail("contact_note_kept", "the app's %s page could not be reached to read the %s" % (
                ("Contacts", "contact") if contact is None else ("Activity", "note")))
        else:
            r = migration.contact_note(seed.CONTACT["name"], seed.NOTE, b_hash, a_hash, contact, note, "plain files unchanged; read on the Contacts and Activity pages")
            (self.ok if r[0] else self.fail)("contact_note_kept", r[1])

    def first_run_lines(self):
        """The app log's first-run server pick lines (07c430866). A fresh install's pick only: on an
        update it would move the user's servers, so any line is a finding (the previous release
        predates the pick and writes none)."""
        if getattr(self, "_first_run", None) is None:
            self._first_run = []
            for dp, _dn, fn in os.walk(os.path.join(self.sb, "home")):
                for f in fn:
                    if f.startswith("wfe.log"):
                        try:
                            with open(os.path.join(dp, f), errors="replace") as fh:
                                self._first_run += [l.strip()[-160:] for l in fh if FIRST_RUN_LOG.search(l)]
                        except OSError:
                            pass
            self.details["first_run"] = ("no first-run server pick in the app log (an existing install keeps its servers)"
                                         if not self._first_run else "first-run server pick ran: %s" % "; ".join(self._first_run[:3]))
        return self._first_run

    def compare_list(self, kind, b, a, custom, chosen):
        key = "nodes" if kind == "node" else "relays"
        check = "custom_nodes_kept" if kind == "node" else "custom_relays_kept"
        use_key = "%s_in_use" % kind
        e0 = [x[0] for x in b[key]]
        e1 = [x[0] for x in a[key]]
        problems = []
        if custom not in e0:
            problems.append("the stand-in %s %s was not in the previous list" % (kind, custom))
        if custom in e0 and custom not in e1:
            problems.append("added %s %s gone" % (kind, custom))
        if not a[use_key].split(": ", 1)[-1].startswith(chosen):
            problems.append("in use was %r, now %r" % (b[use_key].split(": ", 1)[-1], a[use_key].split(": ", 1)[-1]))
        # the user's own entries only: a public server the new version no longer lists is not the user's choice
        if self.first_run_lines():
            problems.append("the candidate ran first run's server pick on an existing install: %s" % "; ".join(self.first_run_lines()[:2]))
        own = [x[0] for x in b[key] if facts.ADDED_BY_YOU in x[1]]
        lost = [x for x in own if x not in e1 and x != custom]
        if lost:
            problems.append("own entries gone: %s" % ", ".join(lost))
        if problems:
            self.fail(check, "; ".join(problems) + "; after: %s" % ", ".join(e1))
        else:
            self.ok(check, "%s in use and %s kept; list %s" % (chosen, custom, ", ".join(e1)))

    def funds_legs(self, after):
        if not self.funds:
            for c in ("send_ok", "receive_ok"):
                self.fail(c, "not run (REL_FUNDS=0)")
        if after is None or not self.checks.get("wallet_opens") or not self.checks.get("balance_kept"):
            why = "the wallet did not open with the candidate" if after is None or not self.checks.get("wallet_opens") \
                else "the candidate does not show the wallet's balance (a payment would land where the user cannot see it)"
            if self.funds:
                for c in ("send_ok", "receive_ok"):
                    self.fail(c, "not run: %s" % why)
            self.return_from_previous()
            return
        addr = after["address"]
        relay_now = after["relay_in_use"].split(": ", 1)[-1].split(",")[0].strip()
        full = addr if "@" in addr else "%s@%s" % (addr, relay_now)
        if self.funds:
            try:
                ok, why = self.fund(full, FUND_AFTER, "receive with the candidate")
                if ok:
                    b = self.wait_spendable(D(FUND_IN) + D(FUND_AFTER), "receive confirmed")
                    self.ok("receive_ok", "P -> %s %s EPIC via Epicbox %s: %s; available %s" % (short(full), FUND_AFTER, relay_now, why[:80], b["available"]))
                else:
                    self.fail("receive_ok", why)
            except (TimeoutError, LookupError, CannotRun) as e:
                self.fail("receive_ok", "%s" % e)
        self.send_back("send_ok" if self.funds else None)

    def send_back(self, check):
        if not self.funds and self.keep_funds:
            self.log("funds kept in the sandbox (REL_KEEP_FUNDS=1)")
            return
        try:
            b = self.balance() or {}
            avail = b.get("available", D(0))
            if avail <= D("0.01"):
                if check:
                    self.fail(check, "nothing worth sending (available %s)" % avail)
                return
            # everything (Max) when it is within the per-send cap, else the cap
            ok, why = self.send_to_p(None if avail <= CAP_SEND else str(CAP_SEND), "send back to P")
            amount = getattr(self, "sent_amount", "?")
            if check:
                (self.ok if ok else self.fail)(check, ("%s EPIC to P via Epicbox: %s" % (amount, why[:120])) if ok else why)
            else:
                self.log("returned %s EPIC to P: %s" % (amount, why[:120]))
        except Exception as e:  # noqa: BLE001
            if check:
                self.fail(check, "%s: %s" % (type(e).__name__, e))
            else:
                self.log("could not return the funds: %s; phrase in %s/phrase.txt" % (e, self.sb))

    def return_from_previous(self):
        """The candidate did not open the wallet: the previous release still can, so the funds go back
        to P from there (the user's way back: reinstall the old version)."""
        if self.keep_funds:
            return
        self.log("returning the funds with the previous release")
        try:
            sandbox.app_stop(self.sb)
            self.start_app(os.path.join(self.work, "previous", "squashfs-root"), "previous (return)")
            i = self.ui.wait_any(["re:^Unlock wallet$", "Main navigation"], 120)
            if i == 0:
                self.unlock()
            self.after_unlock()
            self.wait_spendable(D("0.001"), "previous release balance", 600)
            self.send_back(None)
        except Exception as e:  # noqa: BLE001
            self.log("could not return the funds: %s; phrase in %s/phrase.txt" % (e, self.sb))

    def shutdown(self):
        try:
            self.p.stop_listener()
        except Exception as e:  # noqa: BLE001
            self.log("P listener stop: %s" % e)
        try:
            sandbox.stop(self.sb)
        except Exception as e:  # noqa: BLE001
            self.log("sandbox stop: %s" % e)
        for p in self.standins:
            try:
                p.terminate()
                p.wait(5)
            except Exception:  # noqa: BLE001
                p.kill()
        for name in ("previous", "candidate"):
            shutil.rmtree(os.path.join(self.work, name), ignore_errors=True)
        self.log("sandbox stopped; wallet data, phrase and password kept in %s (mode 700)" % self.sb)


# ---- helpers

def epic(s):
    m = AMOUNT.match(s.strip())
    return D(m.group(1).replace(",", "")) if m else None


def fmt_bal(b):
    return ", ".join("%s %s" % (k, num(v)) for k, v in b.items()) or "none shown"


def num(v):
    """A balance figure as text: 0.03000000 -> 0.03, 0E-8 -> 0."""
    if not isinstance(v, D):
        return str(v)
    t = format(v.normalize(), "f")
    return t if t not in ("-0",) else "0"


def short(a):
    if not a:
        return str(a)
    k, _, dom = a.partition("@")
    return "%s…%s%s" % (k[:6], k[-6:], ("@" + dom) if dom else "")


def same_row(r0, r1):
    """Same payment: direction and amount (states move on with confirmations)."""
    def key(r):
        m = re.match(r"^(\w+)\D*?([\d.,]+) EPIC", r)
        return (m.group(1), D(m.group(2).replace(",", ""))) if m else r
    return key(r0) == key(r1)


def counterparty(r):
    """The row's second part: the other side's address, or how the wallet learnt of it ("Found by recheck")."""
    m = re.search(r"EPIC, ([^,|]+),", r)
    return m.group(1).strip() if m else ""


def phrase_words(names):
    if "24" in names:
        i = names.index("24")
    elif "12" in names:
        i = names.index("12")
    else:
        return []
    n = 24 if "24" in names else 12
    return [w for w in names[i + 1:] if re.fullmatch(r"[a-z]{3,12}", w)][:n]


def sha256(path):
    import hashlib
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def free_port():
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    p = s.getsockname()[1]
    s.close()
    return p


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


def main():
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
    except CannotRun as e:
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
            run.screens.finish()
    return rc


if __name__ == "__main__":
    sys.exit(main())
