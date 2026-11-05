# SPDX-License-Identifier: Apache-2.0
"""iOS for core/lane.py: the Simulator build (a debug Runner.app: Flutter makes no release build for the
Simulator) on a Simulator device of the lane's own on a Mac, driven over WebDriverAgent (wda.py) and read
from the app's data container over ssh (files.py). The Mac is reached by ssh (mac.py) from this host.

The update is `simctl install` of the candidate over the previous app: same bundle id, the data container
and the Simulator's Keychain kept, as an App Store or TestFlight update keeps them. A fresh install is
`simctl uninstall` and the Simulator's Keychain reset (an uninstall leaves Keychain items on iOS), then
`simctl install` and the permissions granted (simctl privacy, as Android's `adb install -g`).

The hermetic node and relay on this host (core/hermetic.py plan, ports 43413 / 43423), or a loopback
stand-in (linux/standin.py) of a public server for one that is not offered, are reached from the Simulator
through ssh -R of the same port: the Simulator shares the Mac's loopback, so 127.0.0.1:<port> there is
this host's. WebDriverAgent's port on the Mac comes here by ssh -L.

The device is the lane's: REL_IOS_DEVICE (default wfe-trust-<variant>), made on the newest iOS runtime when
it is missing, booted headless (no Simulator window). WebDriverAgent is built once on the Mac (xcodebuild
build-for-testing into <REL_IOS_HOME>/wda-build, see trust-ios.sh) and run by `xcodebuild
test-without-building` for each lane. No saved states yet: a lane on iOS sets its wallet up through the
screens every run (REL_TRUST_SAVE_STATE=0, fits() is always false).
"""
import io
import json
import os
import plistlib
import shutil
import socket
import ssl
import subprocess
import sys
import time
import urllib.request
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, HERE)

import facts  # noqa: E402
import nodehealth  # noqa: E402
import seed  # noqa: E402
from core import checks  # noqa: E402
from core import hermetic  # noqa: E402
from core import walletdata as wd  # noqa: E402
from core.faults import HarnessFault, HarnessGone, ProductFault  # noqa: E402
from core.lane import Platform  # noqa: E402
from files import BUNDLE, AppFiles  # noqa: E402
from mac import Mac, q  # noqa: E402
from wda import Wda, WdaSurface  # noqa: E402

WDA_BUNDLE = "com.facebook.WebDriverAgentRunner.xctrunner"
# The keyboard as a test needs it: what is typed is what goes in (no autocorrection, capitals, smart
# punctuation or predictions), and no first-use tutorial over the keys. The Simulator's own preferences.
KEYBOARD_PREFS = ("KeyboardAutocorrection", "KeyboardAutocapitalization", "KeyboardPrediction", "KeyboardCheckSpelling",
                  "KeyboardShowPredictionBar", "KeyboardAllowPaddle", "KeyboardAssistant", "KeyboardPeriodShortcut",
                  "SmartQuotesEnabled", "SmartDashesEnabled", "KeyboardCapsLock")
KEYBOARD_SEEN = ("DidShowContinuousPathIntroduction", "DidShowGestureKeyboardIntroduction",
                 "UIKeyboardDidShowInternationalInfoIntroduction", "KeyboardDidShowProductivityTutorial")


def app_info(zpath):
    """(bundle id, short version, build) of the Runner.app in a Simulator build's zip, or Nones."""
    try:
        with zipfile.ZipFile(zpath) as z:
            name = next((n for n in z.namelist() if n.count("/") == 1 and n.endswith(".app/Info.plist")), None)
            if not name:
                return None, None, None
            p = plistlib.load(io.BytesIO(z.read(name)))
    except (OSError, zipfile.BadZipFile, plistlib.InvalidFileException):
        return None, None, None
    return p.get("CFBundleIdentifier"), p.get("CFBundleShortVersionString"), p.get("CFBundleVersion")


def pick_device_type(runtime):
    """An iPhone the runtime supports: the newest plain "iPhone N Pro", else the first iPhone that is not an
    "iPhone Duo" (Xcode 27.2's, on which a launch fails: tools/build-apple.sh simulator())."""
    phones = [t for t in runtime.get("supportedDeviceTypes", []) if t.get("name", "").startswith("iPhone")
              and not t["name"].startswith("iPhone Duo")]
    pro = [t for t in phones if t["name"].endswith(" Pro") and t["name"][len("iPhone "):-len(" Pro")].isdigit()]
    pick = (pro[-1:] or phones[:1])
    return pick[0]["identifier"] if pick else None


class Sim:
    """The lane's Simulator device on the Mac: the app's process and its console (simctl launch's
    --stdout/--stderr file), for WdaSurface."""

    def __init__(self, mac, udid, bundle, rdir):
        self.mac, self.udid, self.bundle, self.rdir = mac, udid, bundle, rdir
        self.console = None
        self._seen = 0

    def simctl(self, *args, timeout=120, check=False):
        return self.mac.run("xcrun simctl " + " ".join(q(a) for a in args), timeout=timeout, check=check)

    def running(self):
        out = self.simctl("spawn", self.udid, "launchctl", "list", timeout=60).stdout
        for ln in out.splitlines():
            if "UIKitApplication:%s[" % self.bundle in ln:
                return ln.split()[0].isdigit()
        return False

    def new_console(self, n):
        self.console, self._seen = "%s/console-%d.txt" % (self.rdir, n), 0
        return self.console

    def console_new(self):
        if not self.console:
            return []
        b = self.mac.run("tail -c +%d %s 2>/dev/null" % (self._seen + 1, q(self.console)), text=False).stdout
        self._seen += len(b)
        return b.decode("utf-8", "replace").splitlines()

    def console_tail(self, n=400):
        return self.mac.sh("tail -n %d %s 2>/dev/null" % (n, q(self.console))) if self.console else ""

    def screenshot(self):
        path = "%s/shot.png" % self.rdir
        self.simctl("io", self.udid, "screenshot", path, timeout=60)
        r = self.mac.run("cat %s" % q(path), text=False)
        return r.stdout if r.returncode == 0 else None


class IosPlatform(Platform):
    name, family = "ios", "phone"
    update_method = ("simctl install: the candidate Runner.app over the previous one (same bundle id), as an App "
                     "Store or TestFlight update; data container and Keychain kept")
    settings_from_ui = True  # theme, Technical details and level are in the Keychain: core/lane.py reads Settings

    def __init__(self, out, log):
        e = os.environ
        self.out, self.log = out, log
        self.variant = e.get("REL_VARIANT") or "notor"
        self.mac = Mac(e.get("REL_IOS_SSH") or "bob-mac", log)
        self.home = (e.get("REL_IOS_HOME") or "btlabs-ios-driver").rstrip("/")   # relative: in the Mac user's home
        self.device = e.get("REL_IOS_DEVICE") or "wfe-trust-%s" % self.variant
        self.wda_port = int(e.get("REL_IOS_WDA_PORT") or (8102 if self.variant == "notor" else 8100))
        self.apps = {"previous": e.get("REL_PREVIOUS_APP", ""), "candidate": e.get("REL_CANDIDATE_APP", "")}
        self.node, self.relay = e.get("REL_NODE", ""), e.get("REL_EPICBOX", "")
        self.custom_node = self.custom_relay = None
        self.ports = []
        self.standins = []
        self.lan_before = None
        self.udid = None
        self.sim = None
        self.wda = None
        self.wda_local = None
        self.wda_pid = None
        self.remote_app = {}
        self.health = {"device": self.device, "mac": self.mac.host, "wda_port": self.wda_port, "boots": [],
                       "wda_starts": [], "recovered": 0}
        self.running = None
        self.surface = None
        self.certs = {}
        self.launches = 0
        self.hermetic = None
        self._secrets = {}
        self.work = os.path.join(out, "work")
        self.rdir = "%s/run/%s" % (self.home, self.device)

    # ---- the Simulator device

    def _simctl(self, *args, timeout=120, check=False):
        return self.mac.run("xcrun simctl " + " ".join(q(a) for a in args), timeout=timeout, check=check)

    def _device(self):
        """The udid of the lane's device, made on the newest iOS runtime when there is none of its name."""
        js = json.loads(self._simctl("list", "devices", "available", "-j", check=True).stdout)
        for runtime, devs in js.get("devices", {}).items():
            for d in devs:
                if d.get("name") == self.device and "iOS" in runtime:
                    self.health["runtime"] = runtime
                    return d["udid"]
        rts = [r for r in json.loads(self._simctl("list", "runtimes", "available", "-j", check=True).stdout).get("runtimes", [])
               if r.get("platform") == "iOS" or "iOS" in r.get("identifier", "")]
        if not rts:
            raise HarnessFault("prepare", "no iOS Simulator runtime on %s (Xcode › Settings › Components)" % self.mac.host)
        rt = max(rts, key=lambda r: [int(x) for x in str(r.get("version", "0")).split(".") if x.isdigit()])
        dtype = os.environ.get("REL_IOS_DEVICE_TYPE") or pick_device_type(rt)
        if not dtype:
            raise HarnessFault("prepare", "runtime %s supports no iPhone" % rt.get("identifier"))
        r = self._simctl("create", self.device, dtype, rt["identifier"], timeout=180)
        udid = r.stdout.strip()
        if r.returncode != 0 or len(udid) != 36:
            raise HarnessFault("prepare", "simctl create %s: %s" % (self.device, (r.stdout + r.stderr).strip()[-200:]))
        self.health["runtime"] = rt["identifier"]
        self.log("created Simulator %s (%s, %s)" % (self.device, dtype.rsplit(".", 1)[-1], rt.get("name")))
        return udid

    def _boot(self):
        t0 = time.time()
        if self._state() != "Booted":
            r = self._simctl("bootstatus", self.udid, "-b", timeout=600)
            if r.returncode != 0 or self._state() != "Booted":
                raise HarnessFault("simulator", "Simulator %s did not boot: %s" % (self.device, (r.stdout + r.stderr).strip()[-200:]))
            took = round(time.time() - t0)
            self.health["boots"].append({"s": took, "booted": True})
            self.log("Simulator %s (%s) booted in %ds" % (self.device, self.udid, took))
        self._keyboard_prefs()

    def _state(self):
        js = json.loads(self._simctl("list", "devices", "-j", check=True).stdout)
        for devs in js.get("devices", {}).values():
            for d in devs:
                if d.get("udid") == self.udid:
                    return d.get("state")
        return None

    def _keyboard_prefs(self):
        sets = ["defaults write com.apple.keyboard.preferences %s -bool NO" % k for k in KEYBOARD_PREFS]
        sets += ["defaults write com.apple.keyboard.preferences %s -bool YES" % k for k in KEYBOARD_SEEN]
        sets += [s.replace("com.apple.keyboard.preferences", "com.apple.Preferences") for s in sets]
        self.mac.run("; ".join("xcrun simctl spawn %s %s" % (q(self.udid), s) for s in sets), timeout=120)

    # ---- WebDriverAgent

    def _xctestrun(self):
        out = self.mac.sh("ls %s/wda-build/Build/Products/*.xctestrun 2>/dev/null" % q(self.home)).split()
        if not out:
            raise HarnessFault("prepare", "no WebDriverAgent build on %s (%s/wda-build): run trust-ios.sh setup" % (
                self.mac.host, self.home))
        return out[0]

    def _wda_stop(self):
        pidf = "%s/wda.pid" % self.rdir
        self.mac.run("p=$(cat %s 2>/dev/null) && kill $p 2>/dev/null; rm -f %s" % (q(pidf), q(pidf)))
        self._simctl("terminate", self.udid, WDA_BUNDLE)
        self.wda_pid = None

    def _wda_start(self):
        """WebDriverAgent's runner on the device by `xcodebuild test-without-building` in the background on
        the Mac (its log in the run folder), answering on the Mac's wda_port; up when /status answers here."""
        self._wda_stop()
        busy = self.mac.sh("lsof -nP -iTCP:%d -sTCP:LISTEN -t 2>/dev/null" % self.wda_port).strip()
        if busy:
            raise HarnessFault("prepare", "port %d on the Mac is taken (pid %s): set REL_IOS_WDA_PORT" % (self.wda_port, busy))
        xr = self._xctestrun()
        log = "%s/wda.log" % self.rdir
        cmd = ("cd %s && (TEST_RUNNER_USE_PORT=%d nohup /usr/bin/xcodebuild test-without-building -xctestrun %s "
               "-destination id=%s > %s 2>&1 < /dev/null & echo $! > %s)" % (
                   q(self.rdir), self.wda_port, q(xr), q(self.udid), q(log), q("%s/wda.pid" % self.rdir)))
        self.mac.run(cmd, check=True)
        t0 = time.time()
        while time.time() < t0 + 300:
            if self.wda.up():
                break
            if self.mac.run("kill -0 $(cat %s)" % q("%s/wda.pid" % self.rdir)).returncode != 0:
                raise HarnessFault("prepare", "WebDriverAgent's xcodebuild ended: %s" % self.mac.sh("tail -n 15 %s" % q(log)).strip()[-600:])
            time.sleep(3)
        else:
            raise HarnessFault("prepare", "WebDriverAgent did not answer in 300 s (%s on the Mac)" % log)
        took = round(time.time() - t0)
        self.health["wda_starts"].append(took)
        self.wda.sid = None
        self.log("WebDriverAgent up on the Mac's port %d (here 127.0.0.1:%d) in %ds" % (self.wda_port, self.wda_local, took))

    def _tunnel(self):
        if self.wda_local is None:
            self.wda_local = free_port()
            self.wda = Wda("http://127.0.0.1:%d" % self.wda_local)
        logf = open(os.path.join(self.out, "tunnel.log"), "a")
        self.mac.open_tunnel(local=[(self.wda_local, self.wda_port)], remote=self.ports, logf=logf)
        for _ in range(20):
            time.sleep(0.5)
            if not self.mac.tunnel_up():
                raise HarnessFault("prepare", "the ssh tunnel to %s ended (a port taken there? tunnel.log)" % self.mac.host)
            try:
                socket.create_connection(("127.0.0.1", self.wda_local), timeout=2).close()
                return
            except OSError:
                pass
        raise HarnessFault("prepare", "the ssh tunnel's port 127.0.0.1:%d does not open" % self.wda_local)

    # ---- preparation

    def prepare(self):
        os.makedirs(self.work, mode=0o700, exist_ok=True)
        create = (os.environ.get("REL_TRUST_MODE") or "").strip() == "create"
        for which, zpath in self.apps.items():
            if create and which == "previous":
                continue
            if not os.path.isfile(zpath):
                raise HarnessFault("prepare", "no %s Simulator app (%s)" % (which, zpath or "REL_%s_APP unset" % which.upper()))
            bundle, short, build = app_info(zpath)
            self.log("%s: %s (%s %s+%s)" % (which, os.path.basename(zpath), bundle, short, build))
            if bundle != BUNDLE:
                raise HarnessFault("prepare", "%s app is bundle %s, not %s" % (which, bundle, BUNDLE))
            self.certs[which] = "simulator (ad-hoc)"
        if not self.mac.online():
            raise HarnessGone("mac", "ssh to %s does not answer" % self.mac.host)
        self.home = self.mac.sh("cd %s && pwd" % q(self.home)).strip() or self.home   # absolute: commands cd elsewhere
        self.rdir = "%s/run/%s" % (self.home, self.device)
        self.hermetic = hermetic.plan(checks.P_ADDR)
        self.log("hermetic: %s" % self.hermetic["reason"])
        self._pick_servers()
        self._standins()
        self.mac.run("mkdir -p %s" % q(self.rdir), check=True)
        self.udid = self._device()
        self.health["udid"] = self.udid
        self.sim = Sim(self.mac, self.udid, BUNDLE, self.rdir)
        self._boot()
        self._upload()
        self._tunnel()
        self._wda_start()
        self.log("Simulator %s; node %s (+ %s), Epicbox %s (+ %s)" % (self.device, self.node, self.custom_node,
                                                                      self.relay, self.custom_relay))

    def _upload(self):
        """Each build's zip to the Mac's run folder, unpacked there (the same zip once)."""
        done = {}
        for which, zpath in self.apps.items():
            if not os.path.isfile(zpath):
                continue
            key = os.path.realpath(zpath)
            if key in done:
                self.remote_app[which] = done[key]
                continue
            rz, rd = "%s/%s.zip" % (self.rdir, which), "%s/%s" % (self.rdir, which)
            self.mac.put_file(zpath, rz)
            self.mac.run("rm -rf %s && mkdir -p %s && ditto -x -k %s %s && rm -f %s" % (q(rd), q(rd), q(rz), q(rd), q(rz)),
                         timeout=300, check=True)
            app = self.mac.sh("ls -d %s/*.app" % q(rd)).split("\n")[0].strip()
            if not app.endswith(".app"):
                raise HarnessFault("prepare", "the %s zip holds no .app" % which)
            self.remote_app[which] = done[key] = app

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
        the app is given, the local services' fixed ones too, goes in self.ports for the tunnel's -R."""
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

    # ---- installs

    def install_previous(self):
        self._install_fresh("previous")

    def install_candidate_fresh(self):
        self._install_fresh("candidate")

    def _install_fresh(self, which):
        """Whatever the device had of the app goes, its Keychain items too, then the build, its permissions given."""
        self.running = None
        self._simctl("terminate", self.udid, BUNDLE)
        self._simctl("uninstall", self.udid, BUNDLE, timeout=180)
        self._simctl("keychain", self.udid, "reset", timeout=60)
        r = self._simctl("install", self.udid, self.remote_app[which], timeout=300)
        if r.returncode != 0:
            raise HarnessFault("install", "simctl install of the %s app: %s" % (which, (r.stdout + r.stderr).strip()[-200:]))
        self._simctl("privacy", self.udid, "grant", "all", BUNDLE, timeout=60)
        self.log("installed the %s release fresh: build %s" % (which, self.version()))

    def version(self):
        app = self._simctl("get_app_container", self.udid, BUNDLE, "app", timeout=60).stdout.strip()
        if not app.startswith("/"):
            return None
        r = self.mac.run("plutil -extract CFBundleVersion raw %s" % q(app + "/Info.plist"), timeout=60)
        return r.stdout.strip() if r.returncode == 0 else None

    # ---- the app

    def start(self, which):
        if self.running == which and self.surface is not None and self.alive():
            self.log("%s app already running" % which)
            return self.surface
        self.launches += 1
        console = self.sim.new_console(self.launches)
        self._simctl("terminate", self.udid, BUNDLE)
        r = self._simctl("launch", "--terminate-running-process", "--stdout=" + console, "--stderr=" + console,
                         self.udid, BUNDLE, timeout=120)
        if r.returncode != 0:
            raise ProductFault("wallet_opens", "the %s app does not launch: %s" % (which, (r.stdout + r.stderr).strip()[-200:]))
        for _ in range(30):
            if self.sim.running():
                break
            time.sleep(1)
        else:
            raise ProductFault("wallet_opens", "the %s app does not start (no process 30 s after launch)" % which)
        self.running = which
        self.log("%s app started (build %s)" % (which, self.version()))
        if self.surface is None:
            self.surface = WdaSurface(self.wda, self.sim, BUNDLE, self.log)
        self.wda.sid = None   # a session on the app now in front
        return self.surface

    def stop(self):
        """Home (the app goes to the background and saves, as when a user leaves it), then the process
        ends the way the system or a swipe from the app switcher ends it."""
        try:
            self.wda.home()
        except Exception as e:  # noqa: BLE001 — the terminate below ends it either way
            self.log("home: %s" % e)
        time.sleep(3)
        self._simctl("terminate", self.udid, BUNDLE)
        self.running = None
        time.sleep(1)

    def update(self):
        if self.running:
            self.stop()
        before = self.version()
        r = self._simctl("install", self.udid, self.remote_app["candidate"], timeout=300)
        after = self.version()
        if r.returncode != 0:
            raise ProductFault("update", "simctl install of the candidate over the previous release failed: %s" % (
                (r.stdout + r.stderr).strip()[-200:]))
        self.log("update: %s; build %s → %s" % (self.update_method, before, after))

    def recover(self):
        """The Mac's ssh, the tunnel or WebDriverAgent went: the device booted again if it went down,
        WebDriverAgent and the tunnel again, and the app that ran started again."""
        which = self.running
        self.health["recovered"] += 1
        self.log("recover: Simulator %s, WebDriverAgent, tunnel" % self.device)
        if not self.mac.online():
            raise HarnessFault("recover", "the Mac %s does not answer" % self.mac.host)
        self.mac.close_tunnel()
        self._boot()
        self._tunnel()
        self._wda_start()
        self.running = None
        if which:
            self.start(which)

    def alive(self):
        return self.sim.running()

    # ---- data

    def _files(self):
        f = AppFiles(self.mac, self.udid)
        try:
            f.prepare()
        except wd.ReadError as e:
            raise HarnessFault("files", str(e))
        return f

    def digest(self, tag, secrets):
        if self.running and not self.alive():
            raise ProductFault("app_alive", "the %s app is not running any more when its data was read" % self.running)
        self._secrets = secrets
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
            files.put(metas[0], meta)
            files.put(facts.CONTACTS_PLAIN, contacts)
            files.put(facts.LAN_NODES_FILE, seed.lan_nodes_json(["http://%s" % self.custom_node]))
        except wd.ReadError as e:
            raise HarnessFault("seed", str(e))
        self.lan_before = files.text(facts.LAN_NODES_FILE)
        self.log("seeded into the stopped previous release: contact %r, a note, plain-http agreement for %s" % (
            seed.CONTACT["name"], self.custom_node))

    # ---- saved states: none on iOS yet

    def save_state(self, folder):
        raise HarnessFault("save-state", "no saved states on the iOS Simulator yet (REL_TRUST_SAVE_STATE=0)")

    def restore_state(self, folder):
        raise HarnessFault("restore", "no saved states on the iOS Simulator yet")

    def fits(self, meta):
        return False, "no saved states on the iOS Simulator yet"

    def state_meta(self):
        return {}

    def logs(self):
        return {"console": os.path.join(self.out, "console.txt"), "wda": os.path.join(self.out, "wda.log")}

    def shutdown(self):
        keep = os.environ.get("REL_IOS_KEEP") == "1"
        try:
            if self.sim is not None and self.sim.console:
                with open(os.path.join(self.out, "console.txt"), "w") as f:
                    f.write(self.sim.console_tail(5000))
            if self.udid:
                with open(os.path.join(self.out, "wda.log"), "w") as f:
                    f.write(self.mac.sh("tail -n 400 %s 2>/dev/null" % q("%s/wda.log" % self.rdir)))
                if not keep:
                    self._wda_stop()
                    self._simctl("shutdown", self.udid, timeout=120)
        except Exception as e:  # noqa: BLE001
            self.log("Simulator logs: %s" % e)
        for p in self.standins:
            try:
                p.terminate()
                p.wait(5)
            except Exception:  # noqa: BLE001
                p.kill()
        self.health["signer"] = self.certs.get("previous")
        with open(os.path.join(self.out, "simulator.json"), "w") as f:
            json.dump(self.health, f)
        try:
            self.mac.close()
        except Exception as e:  # noqa: BLE001
            self.log("ssh close: %s" % e)
        shutil.rmtree(self.work, ignore_errors=True)
        self.log("Simulator %s; stand-ins stopped" % ("and WebDriverAgent left running" if keep else "shut down"))


# the same server probes as android/android_platform.py (not imported: its files.py is not this folder's)
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
