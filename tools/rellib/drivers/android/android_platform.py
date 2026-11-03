# SPDX-License-Identifier: Apache-2.0
"""Android for core/lane.py: the release APKs (x86_64, signed with the test key) on an emulator of the
lane's own, driven over uiautomator (uia.py) and read as root from the app's data folder (files.py).

The update is `adb install -r`: the candidate APK over the previous one, same package and signer, what
the in-app updater's PackageInstaller does; the data folder and the app's Keystore keys stay. The
hermetic node and relay on this host (core/hermetic.py plan, ports 43413 / 43423), or a loopback stand-in
(linux/standin.py) of a public server for one that is not offered, are reached from the emulator
through `adb reverse` of the same port; `adb root` restarts adbd and drops the reverses, so every root
is followed by setting them again.

The emulator is the lane's: AVD REL_ANDROID_AVD (default wfe_trust_<variant>), port REL_ANDROID_PORT
(5580 tor, 5582 notor), writable (the app's data must outlive an emulator that dies mid-run: recover()
boots it again on the same disk). A saved state is an emulator snapshot of that AVD (the PIN-wrapped
Keystore key cannot leave the device), named in the payload; its meta names the APK signer, and a run
whose previous APK carries another signer does not use it.
"""
import json
import os
import re
import shutil
import socket
import ssl
import signal
import sqlite3
import subprocess
import sys
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, HERE)

import facts  # noqa: E402
import nodehealth  # noqa: E402
import seed  # noqa: E402
from core import checks  # noqa: E402
from core import hermetic  # noqa: E402
from core import state as st  # noqa: E402
from core import walletdata as wd  # noqa: E402
from core.faults import HarnessFault, HarnessGone, ProductFault  # noqa: E402
from core.lane import Platform  # noqa: E402
from avd import AVD_DEVICE, AVD_IMAGE, create_avd  # noqa: E402
from files import PKG, AppFiles  # noqa: E402
from uia import ADB, Device, Uia  # noqa: E402

SDK = os.environ.get("ANDROID_SDK_ROOT") or os.path.expanduser("~/Android/Sdk")
AVD_HOME = os.environ.get("ANDROID_AVD_HOME") or os.path.expanduser("~/.android/avd")
SNAP_PREFIX = "trust-"


def build_tool(name):
    d = os.path.join(SDK, "build-tools")
    vers = sorted((v for v in os.listdir(d) if os.path.isfile(os.path.join(d, v, name))),
                  key=lambda v: [int(x) if x.isdigit() else 0 for x in re.split(r"[.-]", v)]) if os.path.isdir(d) else []
    return os.path.join(d, vers[-1], name) if vers else None


def signer(apk):
    """SHA-256 of the APK's signing certificate (apksigner), or None."""
    tool = build_tool("apksigner")
    if not tool or not os.path.isfile(apk):
        return None
    r = subprocess.run([tool, "verify", "--print-certs", apk], capture_output=True, text=True, timeout=120)
    m = re.search(r"certificate SHA-256 digest: ([0-9a-f]{64})", r.stdout)
    return m.group(1) if r.returncode == 0 and m else None


def apk_version(apk):
    tool = build_tool("aapt2")
    if not tool:
        return None, None
    r = subprocess.run([tool, "dump", "badging", apk], capture_output=True, text=True, timeout=120)
    m = re.search(r"package: name='([^']+)' versionCode='(\d+)'", r.stdout)
    return (m.group(1), m.group(2)) if m else (None, None)


class AndroidPlatform(Platform):
    name, family = "android", "phone"
    update_method = ("adb install -r: the candidate APK over the previous one (same package, same signer), as the "
                     "in-app updater's PackageInstaller does; data folder and Keystore kept")
    settings_from_ui = True  # theme, Technical details and level are Keystore-encrypted: core/lane.py reads Settings

    def __init__(self, out, log):
        e = os.environ
        self.out, self.log = out, log
        self.variant = e.get("REL_VARIANT") or "tor"
        self.port = int(e.get("REL_ANDROID_PORT") or (5582 if self.variant == "notor" else 5580))
        self.avd = e.get("REL_ANDROID_AVD") or "wfe_trust_%s" % self.variant
        self.own = not e.get("REL_ANDROID_SERIAL")
        self.serial = e.get("REL_ANDROID_SERIAL") or "emulator-%d" % self.port
        self.apks = {"previous": e.get("REL_PREVIOUS_APK", ""), "candidate": e.get("REL_CANDIDATE_APK", "")}
        self.node, self.relay = e.get("REL_NODE", ""), e.get("REL_EPICBOX", "")
        self.custom_node = self.custom_relay = None
        self.ports = []
        self.standins = []
        self.lan_before = None
        self.dev = Device(self.serial)
        self.emu = None          # the emulator process when this lane started it
        self.health = {"avd": self.avd, "port": self.port, "own_emulator": self.own, "boots": [], "recovered": 0}
        self.running = None
        self.surface = None
        self.certs = {}
        self.snapshot = None     # the saved state's snapshot name, for state_meta()
        self.hermetic = None     # core/hermetic.py plan(), from prepare
        self._secrets = {}
        self.work = os.path.join(out, "work")

    # ---- the emulator

    def _emu_cmd(self, *args, timeout=120):
        return self.dev.run("emu", *args, timeout=timeout, check_gone=False)

    def _boot(self):
        """The lane's emulator up and booted (started here when none answers on its port)."""
        if self.dev.online() and self._booted():
            return
        if not self.own:
            raise HarnessGone("emulator", "emulator %s (REL_ANDROID_SERIAL) is not online" % self.serial)
        self._kill()
        if not os.path.isdir(os.path.join(AVD_HOME, self.avd + ".avd")):
            err = create_avd(self.avd)
            if err:
                raise HarnessFault("prepare", "no AVD %s in %s, and creating it failed: %s" % (self.avd, AVD_HOME, err))
            self.log("created AVD %s (%s, %s)" % (self.avd, AVD_IMAGE, AVD_DEVICE))
        logf = open(os.path.join(self.out, "emulator.log"), "a")
        t0 = time.time()
        self.emu = subprocess.Popen([os.path.join(SDK, "emulator", "emulator"), "-avd", self.avd, "-no-window", "-no-audio",
                                     "-no-boot-anim", "-no-snapshot-load", "-no-snapshot-save", "-port", str(self.port),
                                     "-gpu", "swiftshader_indirect"], stdout=logf, stderr=subprocess.STDOUT,
                                    stdin=subprocess.DEVNULL, start_new_session=True)
        end = t0 + 300
        while time.time() < end:
            if self.emu.poll() is not None:
                break
            if self.dev.online() and self._booted():
                break
            time.sleep(3)
        took = round(time.time() - t0)
        ok = self.dev.online() and self._booted()
        self.health["boots"].append({"s": took, "booted": ok})
        if not ok:
            raise HarnessFault("emulator", "AVD %s did not boot in %ds (emulator.log)" % (self.avd, took))
        for k in ("window_animation_scale", "transition_animation_scale", "animator_duration_scale"):
            self.dev.sh("settings put global %s 0" % k)
        self.log("emulator %s (%s) booted in %ds" % (self.serial, self.avd, took))

    def _booted(self):
        try:
            return self.dev.run("shell", "getprop sys.boot_completed", timeout=20, check_gone=False).stdout.strip() == "1"
        except subprocess.TimeoutExpired:
            return False

    def _kill(self):
        if self.dev.online():
            self._emu_cmd("kill", timeout=30)
        if self.emu and self.emu.poll() is None:
            try:
                self.emu.wait(30)
            except subprocess.TimeoutExpired:
                self.emu.kill()
        self.emu = None

    def _root(self):
        """adb as root (the app's files); adbd restarts and drops the reverses, set again here."""
        if "uid=0" not in self.dev.sh("id"):
            self.dev.run("root", timeout=60)
            self.dev.run("wait-for-device", timeout=120)
            for _ in range(20):
                if self.dev.online() and "uid=0" in self.dev.sh("id"):
                    break
                time.sleep(1)
        if "uid=0" not in self.dev.sh("id"):
            raise HarnessFault("prepare", "adb root is not available on %s (the app's files cannot be read)" % self.avd)
        self._reverse()

    def _reverse(self):
        for p in self.ports:
            self.dev.run("reverse", "tcp:%d" % p, "tcp:%d" % p)

    def _sync_clock(self):
        """A loaded snapshot wakes with the clock it was saved with; Tor and the relay need today's."""
        self.dev.sh("date -u %s" % time.strftime("%m%d%H%M%Y.%S", time.gmtime()))

    # ---- preparation

    def prepare(self):
        os.makedirs(self.work, mode=0o700, exist_ok=True)
        create = (os.environ.get("REL_TRUST_MODE") or "").strip() == "create"  # the candidate alone: no update
        for which, apk in self.apks.items():
            if create and which == "previous":
                continue
            if not os.path.isfile(apk):
                raise HarnessFault("prepare", "no %s APK (%s)" % (which, apk or "REL_%s_APK unset" % which.upper()))
            self.certs[which] = signer(apk)
            pkg, code = apk_version(apk)
            self.log("%s: %s (%s %s, signer %s…)" % (which, os.path.basename(apk), pkg, code, (self.certs[which] or "?")[:12]))
            if pkg != PKG:
                raise HarnessFault("prepare", "%s APK is package %s, not %s" % (which, pkg, PKG))
        if not create and (not self.certs["previous"] or self.certs["previous"] != self.certs["candidate"]):
            raise HarnessFault("prepare", "the two APKs are not signed with the same certificate (%s / %s): an update "
                               "would be refused; sign both with the test key" % (self.certs["previous"], self.certs["candidate"]))
        self.hermetic = hermetic.plan(checks.P_ADDR)
        self.log("hermetic: %s" % self.hermetic["reason"])
        self._pick_servers()
        self._standins()
        self._boot()
        self._root()
        self.log("emulator %s; node %s (+ %s), Epicbox %s (+ %s)" % (self.serial, self.node, self.custom_node,
                                                                     self.relay, self.custom_relay))

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

    def _standins(self):
        """A stand-in for each server that is not local; a local one is its own custom entry. Every port
        the app is given, the local services' fixed ones too, goes in self.ports for _reverse()."""
        plan = self.hermetic or {}
        ports = {}
        for kind, up in (("node", self.node), ("relay", self.relay)):
            if plan.get(kind):
                continue
            ports[kind] = free_port()
            logf = open(os.path.join(self.out, "standin-%s.log" % kind), "w")
            self.standins.append(subprocess.Popen(
                [sys.executable, "-I", os.path.join(os.path.dirname(HERE), "linux", "standin.py"), kind, str(ports[kind]), up],
                stdout=logf, stderr=subprocess.STDOUT, start_new_session=True))
        for attempt in range(3):
            time.sleep(1 if attempt == 0 else 5)
            if "node" not in ports or node_up("http://127.0.0.1:%d" % ports["node"]):
                break
        else:
            raise HarnessFault("prepare", "the loopback node stand-in does not answer")
        self.ports = list(ports.values()) + plan.get("ports", [])
        self.custom_node = hermetic.entry(plan["node"]) if plan.get("node") else "127.0.0.1:%d" % ports["node"]
        self.custom_relay = plan["relay"] if plan.get("relay") else "127.0.0.1:%d" % ports["relay"]

    def live_servers(self):
        """The public node and relay the live-servers phase puts in use (core/lane.py)."""
        return hermetic.pick_live(node_up, relay_up, nodehealth.synced_first(facts.NODE_PICK, log=self.log), facts.RELAY_PICK)

    def install_previous(self):
        """A fresh install: whatever the emulator had of the app goes, then the previous APK."""
        self._install_fresh("previous")

    def install_candidate_fresh(self):
        """REL_TRUST_MODE=create: the candidate on its own, no previous release before it (a new user's
        install), whatever the emulator had of the app gone first."""
        self._install_fresh("candidate")

    def _install_fresh(self, which):
        self.running = None
        self.dev.run("uninstall", PKG, timeout=120)
        r = self.dev.run("install", "-g", "--no-incremental", self.apks[which], timeout=300)
        if "Success" not in r.stdout:
            raise HarnessFault("install", "adb install of the %s APK: %s" % (which, (r.stdout + r.stderr).strip()[-200:]))
        self._sync()
        self.log("installed the %s release fresh: versionCode %s" % (which, self.version()))

    def version(self):
        m = re.search(r"versionCode=(\d+)", self.dev.sh("dumpsys package %s | grep -m1 versionCode" % PKG))
        return m.group(1) if m else None

    # ---- the app

    def start(self, which):
        # recover() started it again already: a force-stop now would cut its first launch short
        if self.running == which and self.surface is not None and self.alive():
            self.log("%s app already running" % which)
            return self.surface
        self.dev.sh("am force-stop %s" % PKG)
        self.dev.run("shell", "monkey -p %s -c android.intent.category.LAUNCHER 1" % PKG, timeout=60)
        for _ in range(30):
            if self.dev.sh("pidof %s" % PKG).strip():
                break
            time.sleep(1)
        else:
            raise ProductFault("wallet_opens", "the %s app does not start (no process 30 s after launch)" % which)
        self.running = which
        self.log("%s app started (versionCode %s)" % (which, self.version()))
        if self.surface is None:
            self.surface = Uia(self.dev, PKG, self.log)
        return self.surface

    def stop(self):
        """Home (the app goes to the background and saves, as when a user leaves it), then the process
        ends the way the system or a swipe from Recents ends it."""
        self.dev.sh("input keyevent 3")
        time.sleep(3)
        self.dev.sh("am force-stop %s" % PKG)
        self.running = None
        time.sleep(1)
        self._sync()

    def _sync(self):
        """What was just written (the app's files, an install) on the emulator's disk: a killed emulator loses
        writes still in its page cache, and a package whose base.apk is half written is dropped at the next boot."""
        self.dev.run("shell", "sync", timeout=120)

    def update(self):
        if self.running:
            self.stop()
        before = self.version()
        r = self.dev.run("install", "-r", "--no-incremental", self.apks["candidate"], timeout=300)
        after = self.version()
        msg = (r.stdout + r.stderr).strip()[-200:]
        if "Success" not in r.stdout:
            raise ProductFault("update", "adb install -r of the candidate over the previous release failed: %s" % msg)
        self._sync()
        self.log("update: %s; versionCode %s → %s" % (self.update_method, before, after))

    def recover(self):
        """The emulator went (killed, adb gone): booted again on the same disk, root and reverses again,
        and the app that ran started again (the phase that failed then finds where it is)."""
        which = self.running
        self.health["recovered"] += 1
        self.log("recover: emulator %s" % self.serial)
        self._kill()
        self._boot()
        self._root()
        if which:
            self.start(which)

    def alive(self):
        if not self.dev.online():  # the emulator went, not the app
            raise HarnessGone("alive", "emulator %s gone" % self.serial)
        return bool(self.dev.sh("pidof %s" % PKG).strip())

    # ---- data

    def _files(self):
        f = AppFiles(self.serial)
        try:
            f.prepare()
        except wd.ReadError as e:
            raise HarnessFault("files", str(e))
        self._reverse()  # files.prepare() may have restarted adbd as root
        return f

    def digest(self, tag, secrets):
        if self.running and not self.alive():
            raise ProductFault("app_alive", "the %s app is not running any more when its data was read" % self.running)
        self._secrets = secrets  # for the lose-balance break, which runs between two digests
        return wd.read(self._files(), secrets, migrate=checks.migrating()[0], nodes=[self.node], log=self.log)

    def files_snapshot(self):
        return wd.snapshot(self._files())

    def seed_previous_files(self, secrets):
        """While the previous release is stopped and only when the candidate migrates a plain store: a
        contact, a note on the first transaction and the stand-in node's plain-http agreement, in the
        previous release's own files and format (seed.py)."""
        if not checks.migrating()[1]:
            return
        files = self._files()
        listing = files.listing()
        metas = [p for p in listing if p.endswith("/" + facts.META_PLAIN) and p.count("/") == 2]
        dbs = [p for p in listing if p.endswith("/%s/%s" % (facts.STORE_DIR, facts.STORE_PLAIN))]
        if len(metas) != 1 or len(dbs) != 1:
            raise HarnessFault("seed", "the previous release left %d %s and %d %s (one each expected)" % (
                len(metas), facts.META_PLAIN, len(dbs), facts.STORE_PLAIN))
        d = os.path.join(self.work, "seed-db")
        os.makedirs(d, exist_ok=True)
        try:
            for sfx in ("", "-wal", "-shm"):
                files.fetch(dbs[0] + sfx, os.path.join(d, facts.STORE_PLAIN + sfx))
            meta = seed.meta_note(files.text(metas[0]), seed.first_tx_id(os.path.join(d, facts.STORE_PLAIN)))
            contacts = seed.contacts_json(files.text(facts.CONTACTS_PLAIN), checks.P_ADDR)
        except (seed.SeedError, OSError) as e:
            raise HarnessFault("seed", "seeding the previous release's contact and note: %s" % e)
        finally:
            shutil.rmtree(d, ignore_errors=True)
        try:
            files.put(metas[0], meta, self.work)
            files.put(facts.CONTACTS_PLAIN, contacts, self.work)
            files.put(facts.LAN_NODES_FILE, seed.lan_nodes_json(["http://%s" % self.custom_node]), self.work)
        except wd.ReadError as e:
            raise HarnessFault("seed", str(e))
        self.lan_before = files.text(facts.LAN_NODES_FILE)
        self._sync()
        self.log("seeded into the stopped previous release: contact %r, a note, plain-http agreement for %s" % (
            seed.CONTACT["name"], self.custom_node))

    # ---- saved states (core/state.py)

    def _snapshots(self):
        d = os.path.join(AVD_HOME, self.avd + ".avd", "snapshots")
        return set(os.listdir(d)) if os.path.isdir(d) else set()

    def save_state(self, folder):
        """An emulator snapshot with the app stopped (its files whole, its Keystore key in place); the
        payload names it. Snapshots of this AVD no saved state names any more are deleted."""
        if self.running:
            self.stop()
        name = "%s%s-%s-%s" % (SNAP_PREFIX, self.variant, os.environ.get("REL_CANDIDATE_VERSION", "x"), time.strftime("%Y%m%d%H%M%S"))
        r = self._emu_cmd("avd", "snapshot", "save", name, timeout=600)
        if name not in self._snapshots():
            raise HarnessFault("save-state", "emulator snapshot %s not saved: %s" % (name, (r.stdout + r.stderr).strip()[-200:]))
        self.snapshot = name
        with open(os.path.join(folder, "snapshot.json"), "w") as f:
            json.dump({"avd": self.avd, "snapshot": name, "versionCode": self.version()}, f)
        self._prune_snapshots(keep={name})
        self.log("saved emulator snapshot %s of %s" % (name, self.avd))

    def _prune_snapshots(self, keep):
        base = os.path.join(st.root(), "android-%s" % self.variant)
        for d in (os.listdir(base) if os.path.isdir(base) else ()):
            try:
                with open(os.path.join(base, d, "payload", "snapshot.json")) as f:
                    keep.add(json.load(f)["snapshot"])
            except (OSError, ValueError, KeyError):
                pass
        for s in sorted(self._snapshots()):
            if s.startswith(SNAP_PREFIX + self.variant + "-") and s not in keep:
                self._emu_cmd("avd", "snapshot", "delete", s, timeout=120)
                self.log("emulator snapshot %s deleted (no saved state names it)" % s)

    def restore_state(self, folder):
        with open(os.path.join(folder, "snapshot.json")) as f:
            snap = json.load(f)
        r = self._emu_cmd("avd", "snapshot", "load", snap["snapshot"], timeout=600)
        if "OK" not in r.stdout:
            raise HarnessFault("restore", "emulator snapshot %s did not load: %s" % (snap["snapshot"], (r.stdout + r.stderr).strip()[-200:]))
        for _ in range(60):
            if self.dev.online() and self._booted():
                break
            time.sleep(2)
        self._root()
        self._sync_clock()
        self.dev.sh("am force-stop %s" % PKG)
        self.log("restored emulator snapshot %s (versionCode %s)" % (snap["snapshot"], self.version()))

    def fits(self, meta):
        if meta.get("platform") != "android" or meta.get("variant") != self.variant:
            return False, "saved for %s %s" % (meta.get("platform"), meta.get("variant"))
        if meta.get("signer") != self.certs.get("previous"):
            return False, "saved with APKs of signer %s…, this run's previous APK has %s…" % (
                (meta.get("signer") or "?")[:12], (self.certs.get("previous") or "?")[:12])
        if meta.get("avd") != self.avd or meta.get("snapshot") not in self._snapshots():
            return False, "its emulator snapshot %s is not in AVD %s" % (meta.get("snapshot"), self.avd)
        return st.hermetic_fits(meta, self)

    def state_meta(self):
        return {"signer": self.certs.get("candidate"), "avd": self.avd, "snapshot": self.snapshot}

    # ---- break tests (core/breaks.py)

    def break_kill(self):
        """The emulator dies (as when the host kills it): every adb call then finds it gone."""
        pids = [int(x) for x in subprocess.run(["pgrep", "-f", "qemu.*-port %d" % self.port], capture_output=True,
                                               text=True).stdout.split()]
        if self.emu and self.emu.poll() is None:
            pids.append(self.emu.pid)
        for pid in set(pids):
            try:
                os.kill(pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
        self.log("BREAK: emulator processes %s killed" % sorted(set(pids)))

    def break_freeze(self, on):
        pid = self.dev.sh("pidof %s" % PKG).strip()
        if pid:
            self.dev.sh("kill -%s %s" % ("STOP" if on else "CONT", pid))

    def _push_bin(self, files, local, rel):
        dest = "%s/%s" % (files.root, rel)
        self.dev.run("push", local, "/data/local/tmp/break.tmp", timeout=120)
        uid = self.dev.sh("stat -c %%u '%s'" % files.root).strip()
        self.dev.sh("cat /data/local/tmp/break.tmp > '%s' && chown %s:%s '%s' && chmod 600 '%s'; rm -f /data/local/tmp/break.tmp; "
                    "restorecon '%s' 2>/dev/null" % (dest, uid, uid, dest, dest, dest))
        self._sync()

    def break_lose_node(self):
        """The custom node's line goes from the closed previous release's settings.toml."""
        files = self._files()
        text = files.text(facts.SETTINGS_TOML)
        if text is None:
            raise HarnessFault("break", "lose-node needs the previous release's settings.toml")
        lines = text.splitlines(keepends=True)
        kept = [ln for ln in lines if self.custom_node not in ln]
        if len(kept) == len(lines):
            raise HarnessFault("break", "lose-node: %s is not in settings.toml" % self.custom_node)
        os.makedirs(self.work, exist_ok=True)
        local = os.path.join(self.work, "settings.toml")
        with open(local, "w") as f:
            f.writelines(kept)
        self._push_bin(files, local, facts.SETTINGS_TOML)
        self.log("BREAK: the custom node %s removed from the closed wallet's settings.toml" % self.custom_node)

    def break_lose_balance(self):
        """The closed wallet's database loses its outputs. A plain store: its outputs deleted. An encrypted
        store: replaced by an empty store under the same key (a CLI restore of the wallet's phrase, no scan),
        so the candidate opens a valid wallet that holds nothing."""
        files = self._files()
        listing = files.listing()
        enc = [p for p in listing if os.path.basename(p) == facts.STORE_ENC]
        plain = [p for p in listing if os.path.basename(p) == facts.STORE_PLAIN and "/%s/" % facts.STORE_DIR in "/" + p]
        d = os.path.join(self.work, "break-db")
        os.makedirs(d, mode=0o700, exist_ok=True)
        try:
            if len(enc) == 1:
                store_dir = os.path.dirname(enc[0])
                cli = wd.LepicCli(log=self.log)
                try:
                    cli._restore(self._secrets["phrase"], self._secrets["password"], files.text("settings.toml"))
                    empty = [n for n in (facts.STORE_ENC, facts.STORE_CHECK) if os.path.exists(os.path.join(cli.dst, n))]
                    if facts.STORE_ENC not in empty:
                        raise HarnessFault("break", "the CLI restore made no %s" % facts.STORE_ENC)
                    self.dev.sh("rm -f '%s/%s/%s-wal' '%s/%s/%s-shm'" % ((files.root, store_dir, facts.STORE_ENC) * 2))
                    for n in empty:
                        self._push_bin(files, os.path.join(cli.dst, n), "%s/%s" % (store_dir, n))
                finally:
                    cli.close()
                self.log("BREAK: the closed wallet's encrypted store replaced by an empty one under the same key")
            elif len(plain) == 1:
                for sfx in ("", "-wal", "-shm"):
                    files.fetch(plain[0] + sfx, os.path.join(d, facts.STORE_PLAIN + sfx))
                c = sqlite3.connect(os.path.join(d, facts.STORE_PLAIN))
                try:
                    n = c.execute("delete from outputs").rowcount
                    c.commit()
                    c.execute("pragma wal_checkpoint(truncate)")
                finally:
                    c.close()
                self.dev.sh("rm -f '%s/%s-wal' '%s/%s-shm'" % ((files.root, plain[0]) * 2))
                self._push_bin(files, os.path.join(d, facts.STORE_PLAIN), plain[0])
                self.log("BREAK: %d outputs deleted from the closed wallet's database" % n)
            else:
                raise HarnessFault("break", "lose-balance needs one wallet store (found %d encrypted, %d plain)" % (len(enc), len(plain)))
        finally:
            shutil.rmtree(d, ignore_errors=True)

    def logs(self):
        return {"logcat": os.path.join(self.out, "logcat.txt"), "emulator": os.path.join(self.out, "emulator.log")}

    def shutdown(self):
        try:
            if self.dev.online():
                r = self.dev.run("logcat", "-d", "-v", "time", timeout=120, check_gone=False)
                with open(os.path.join(self.out, "logcat.txt"), "w") as f:
                    f.write(r.stdout)
                self.dev.run("reverse", "--remove-all", check_gone=False)
        except Exception as e:  # noqa: BLE001
            self.log("logcat: %s" % e)
        for p in self.standins:
            try:
                p.terminate()
                p.wait(5)
            except Exception:  # noqa: BLE001
                p.kill()
        self.health["alive_at_end"] = self.dev.online()
        self.health["signer"] = self.certs.get("previous")
        with open(os.path.join(self.out, "emulator.json"), "w") as f:
            json.dump(self.health, f)
        if self.own and os.environ.get("REL_ANDROID_KEEP") != "1":
            self._kill()
        shutil.rmtree(self.work, ignore_errors=True)
        self.log("emulator %s; stand-ins stopped" % ("left running" if not self.own or os.environ.get("REL_ANDROID_KEEP") == "1"
                                                     else "stopped"))


# the same server probes as linux/linux_platform.py (not imported: its files.py is not this folder's)
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
