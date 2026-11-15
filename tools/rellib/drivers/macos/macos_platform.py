# SPDX-License-Identifier: Apache-2.0
"""macOS for core/lane.py: the desktop app on a Mac, driven over ssh from this host.

The Mac (REL_MAC_SSH, else ssh under [host.apple] in the release hosts file) is a person's own Mac with its own BT Wallet. The
lane keeps clear of it. Each run has a folder of its own under the lane folder (REL_MAC_LANE, default
~/wfe-lanes/macos), run/<name>/:
  home/          the app's HOME (and CFFIXED_USER_HOME): its data folder home/.epic_cash_desktop and the
                 home's throwaway keychain home/Library/Keychains/lane.keychain-db (launch.sh)
  Applications/  the installed app, BT Wallet.app
  previous/, candidate/  each build unpacked; launch.sh, the app's stdout (app-<n>.log), its pid file
The user's own home, keychain and app are never read or changed. AppFiles.prepare() refuses data found
anywhere but the lane home's data folder.

Starting the app: a terminal tab (REL_MAC_TERM) in the user's GUI session runs launch.sh, which unlocks the throwaway
keychain in that session and starts the app's binary with the lane home. The app's window shows on the
Mac's screen; nothing else may. The AX helper (axhelper.swift, already running in its own terminal pane
with the Accessibility permission) reads and presses (ax.py MacSurface). A system dialog (keychain,
Gatekeeper, privacy) fails the lane at once: the app is stopped and the dialog cancelled (ax.py).

Signing: the app's keychain items open without a prompt only for an app with the same designated
requirement. A release is signed with BT Labs' Developer ID; a test build is ad hoc. When the previous
and the candidate differ there, an ad hoc candidate is signed again on the Mac with the Developer ID
(build.keychain, as tools/build-apple.sh devid_sign does) before anything starts; any other difference
refuses the run. A flow run installs one build twice: the same requirement.

The update replaces the app bundle (update_method says why). The hermetic node and relay on this
host, or loopback stand-ins (linux/standin.py) of public servers, reach the app on the Mac through
ssh -R on the same port, as on iOS.
"""
import json
import os
import random
import re
import shutil
import socket
import ssl
import subprocess
import sys
import tarfile
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
DRIVERS = os.path.dirname(HERE)
# ios/ (mac.py) and linux/ (standin.py) hold modules of the same names as this folder's (files.py): this
# folder goes first
for d in (DRIVERS, os.path.join(DRIVERS, "linux"), os.path.join(DRIVERS, "ios"), HERE):
    if d in sys.path:
        sys.path.remove(d)
    sys.path.insert(0, d)

from files import AppFiles, DATA_FOLDER  # noqa: E402  (this folder's: imported first)

import facts  # noqa: E402
import nodehealth  # noqa: E402
import seed  # noqa: E402
from core import checks  # noqa: E402
from core import freeze  # noqa: E402
from core import hermetic  # noqa: E402
from core import walletdata as wd  # noqa: E402
from core.faults import HarnessFault, HarnessGone, ProductFault  # noqa: E402
from core.lane import Platform  # noqa: E402
import mac as macmod  # noqa: E402
from mac import Mac, q  # noqa: E402
from ax import MacSurface, SystemDialog  # noqa: E402

BUNDLE_ID = "uk.btlabs.btwallet.macos"
APP_NAME = "BT Wallet.app"
EXE = "Contents/MacOS/btwallet"
TEAM = "AM8YPW9P6T"


def hosts_file():
    return os.environ.get("REL_HOSTS") or os.path.expanduser("~/.config/btlabs/release-hosts.toml")


def apple_host(key):
    """[host.apple] <key> in the release hosts file (REL_HOSTS, ~/.config/btlabs/release-hosts.toml), or ""."""
    try:
        import tomllib
        with open(hosts_file(), "rb") as f:
            return str(tomllib.load(f).get("host", {}).get("apple", {}).get(key) or "")
    except (OSError, ValueError, ImportError):
        return ""


def mac_host_name(e=os.environ):
    """The Mac's ssh name: REL_MAC_SSH, else ssh under [host.apple] in the hosts file; "" when neither says."""
    return e.get("REL_MAC_SSH") or apple_host("ssh")


def mac_term(e=os.environ):
    """The terminal program on the Mac whose panes run the app and the AX helper in the user's GUI session
    (its CLI: tab create, pane run, tab close): REL_MAC_TERM, else mac_term under [host.apple]."""
    return e.get("REL_MAC_TERM") or apple_host("mac_term")
CACHE = os.path.expanduser("~/.cache/rel-trust-macos")
RUN_NAME = re.compile(r"^[A-Za-z0-9.+-]+$")
START_S = 90     # the app's window in the AX tree after the start
QUIT_S = 30      # the app gone after Cmd+Q
CHECK_S = 12     # the start check: how long the app runs before the lane looks for a dialog
SIGN_KEYCHAIN = "~/Library/Keychains/build.keychain-db"


class LaneMac(Mac):
    """ios/mac.py's Mac with a ControlPath of this lane's own: close() ends only this lane's connection."""

    def __init__(self, host, log=print):
        os.makedirs(CACHE, mode=0o700, exist_ok=True)
        super().__init__(host, log)
        self.opts = [o.replace(macmod.CACHE, CACHE) if o.startswith("ControlPath=") else o for o in self.opts]


# ---- the builds

def build_file(folder, version, variant):
    """The variant's macOS build in a release or test-build folder, or None: the release dmg
    bt-wallet-<v>[-notor]-macos.dmg (in the folder or its macos/), else the one test build of the variant
    (bt-wallet-<id>-<variant>-macos.tar or .zip) or one BT Wallet.app."""
    if not folder or not os.path.isdir(folder):
        return None
    sfx = "-notor" if variant == "notor" else ""
    dirs = [d for d in (folder, os.path.join(folder, "macos")) if os.path.isdir(d)]
    for d in dirs:
        exact = os.path.join(d, "bt-wallet-%s%s-macos.dmg" % (version, sfx))
        if version and os.path.isfile(exact):
            return exact
    rx = re.compile(r"^bt-wallet-[\d.]+%s-macos\.dmg$" % sfx)
    tb = re.compile(r"^bt-wallet-[0-9A-Za-z.]+-%s-macos\.(tar|zip)$" % re.escape(variant))
    for pat in (rx, tb):
        hits = sorted(os.path.join(d, f) for d in dirs for f in os.listdir(d) if pat.match(f))
        if len(hits) == 1:
            return hits[0]
        if len(hits) > 1:
            raise HarnessFault("prepare", "more than one %s macOS build in %s: %s" % (
                variant, folder, ", ".join(os.path.basename(h) for h in hits)))
    apps = [os.path.join(d, f) for d in dirs for f in os.listdir(d) if f == APP_NAME]
    return apps[0] if len(apps) == 1 else None


def kind_of(path):
    """dmg | tar | zip | app | mac-app (an app already on the Mac: mac:<path>), or None."""
    if path.startswith("mac:"):
        return "mac-app"
    if path.endswith(".app") and os.path.isdir(path):
        return "app"
    for k in ("dmg", "tar", "zip"):
        if path.endswith("." + k) and os.path.isfile(path):
            return k
    return None


def designated(text):
    """The designated requirement in `codesign -d -r -` output, or None. An ad hoc build's is implicit
    and printed as a comment ("# designated => cdhash H\"...\"")."""
    m = re.search(r"^(?:# )?designated => (.+)$", text or "", re.M)
    return m.group(1).strip() if m else None


def adhoc(req):
    return bool(req) and req.startswith("cdhash ")


def devid_team(req):
    """The Developer ID team a designated requirement names, or None."""
    m = re.search(r'certificate leaf\[subject\.OU\] = "?([A-Z0-9]{10})"?', req or "")
    return m.group(1) if m and "anchor apple generic" in (req or "") else None


class MacosPlatform(Platform):
    name, family = "macos", "desktop"
    reads_settings_in_ui = True   # the confirmations count is read on the Settings page (lane._ui_settings)
    update_method = ("the app bundle replaced: the previous release closed (Cmd+Q, as a user quits it), "
                     "Applications/BT Wallet.app replaced by the candidate's (ditto), the candidate started on the same "
                     "home. The in-app update on macOS (DmgApplier, byHand) only opens the downloaded dmg for the user "
                     "to drag the app over; the drag is what this does. Download and signature check are not part of it.")

    def __init__(self, out, log):
        e = os.environ
        self.out, self.log = out, log
        self.variant = e.get("REL_VARIANT") or "tor"
        self.create = (e.get("REL_TRUST_MODE") or "") == "create"
        self.flow = (e.get("REL_TRUST_MODE") or "") == "flow"
        self.vers = {"previous": e.get("REL_PREVIOUS_VERSION", ""), "candidate": e.get("REL_CANDIDATE_VERSION", "")}
        self.dirs = {"previous": e.get("REL_PREVIOUS_DIR", ""), "candidate": e.get("REL_CANDIDATE_DIR", "")}
        self.given = {"previous": e.get("REL_PREVIOUS_APP", ""), "candidate": e.get("REL_CANDIDATE_APP", "")}
        host, self.term = mac_host_name(e), mac_term(e)
        if not host:
            raise HarnessFault("prepare", "no Mac named: set REL_MAC_SSH, or ssh under [host.apple] in %s" % hosts_file())
        if not self.term:
            raise HarnessFault("prepare", "no terminal program on the Mac named: set REL_MAC_TERM, or mac_term "
                               "under [host.apple] in %s" % hosts_file())
        self.mac = LaneMac(host, log)
        self.lane_dir = (e.get("REL_MAC_LANE") or "wfe-lanes/macos").rstrip("/")
        self.keep = e.get("REL_MAC_KEEP") == "1"
        self.node, self.relay = e.get("REL_NODE", ""), e.get("REL_EPICBOX", "")
        self.custom_node = self.custom_relay = None
        self.lan_before = None
        self.ports = []
        self.forwards = []
        self.standins = []
        self.hermetic = None
        stamp = time.strftime("%Y%m%d-%H%M%S")
        self.name_run = "%s-%s-to-%s-%s" % (self.variant, self.vers["previous"] or "none", self.vers["candidate"] or "none", stamp)
        self.work = os.path.join(out, "work")
        self.builds = {}         # which -> local path or mac:<path>
        self.apps = {}           # which -> the unpacked app on the Mac
        self.info = {}           # which -> {version, build, requirement, signer}
        self.root = self.run = self.home = self.installed = None
        self.helper = self.sock = None
        self.surface = None
        self.running = None
        self.pid = None
        self.tab = None
        self.launches = 0
        self.health = {"mac": self.mac.host, "starts": [], "stops": [], "recovered": 0, "resigned": None}

    # ---- preparation

    def find_builds(self):
        """which -> the build to install: REL_<WHICH>_APP (a file or app here, or mac:<path>), else the
        folder's (build_file). HarnessFault when one is missing."""
        need = ("candidate",) if self.create else ("previous", "candidate")
        for which in need:
            path = self.given[which] or build_file(self.dirs[which], self.vers[which], self.variant)
            if not path or not kind_of(path):
                raise HarnessFault("prepare", "no %s %s macOS build (%s)" % (
                    which, self.variant, self.given[which] or self.dirs[which] or "REL_%s_DIR unset" % which.upper()))
            self.builds[which] = path
        return self.builds

    def prepare(self):
        self.find_builds()
        os.makedirs(self.work, mode=0o700, exist_ok=True)
        for which, path in self.builds.items():
            self.log("%s: %s" % (which, path))
        if not RUN_NAME.match(self.name_run):
            raise HarnessFault("prepare", "the run name %r is not a safe folder name" % self.name_run)
        if not self.mac.online():
            raise HarnessGone("mac", "ssh to %s does not answer" % self.mac.host)
        self.root = self.mac.sh("mkdir -p %s && cd %s && pwd" % (q(self.lane_dir), q(self.lane_dir))).strip()
        if not self.root.startswith("/"):
            raise HarnessFault("prepare", "the lane folder %s is not there on the Mac" % self.lane_dir)
        self.run = "%s/run/%s" % (self.root, self.name_run)
        self.home = "%s/home" % self.run
        self.installed = "%s/Applications/%s" % (self.run, APP_NAME)
        self.helper, self.sock = "%s/bin/wfe-axhelper" % self.root, "%s/ax.sock" % self.root
        self._helper_check()
        self._awake()
        self.mac.run("mkdir -p %s %s/Applications && chmod 700 %s" % (q(self.home), q(self.run), q(self.run)), check=True)
        self.mac.put_file(os.path.join(HERE, "launch.sh"), "%s/launch.sh" % self.run)
        self._unpack()
        self._signing()
        self.hermetic = hermetic.plan(checks.P_ADDR)
        self.log("hermetic: %s" % self.hermetic["reason"])
        self._pick_servers()
        self._standins()
        self._tunnel()
        self.start_check()
        self.log("Mac %s, run folder %s; node %s (+ %s), Epicbox %s (+ %s)" % (
            self.mac.host, self.run, self.node, self.custom_node, self.relay, self.custom_relay))

    def _helper_check(self):
        """The AX helper answers and has its Accessibility permission (it is never started here: it runs in its
        own terminal pane, started by a person, so it keeps the permission)."""
        probe = MacSurface(self.mac, self.helper, self.sock, 0, log=self.log)
        r = probe.call("ping", timeout=30)
        if not r.get("ok") or r.get("trusted") is not True:
            raise HarnessFault("prepare", "the AX helper on the Mac is not ready: %s" % json.dumps(r)[:200])
        self.health["helper"] = {k: r.get(k) for k in ("pid", "version", "trusted") if k in r}

    def screen_locked(self):
        """True when the Mac's login session has its screen locked: the app's window is then 0x0 and its
        AX tree holds no content."""
        out = self.mac.sh("ioreg -n Root -d1 | grep -o 'CGSSessionScreenIsLocked\"=[A-Za-z]*' || true")
        return out.strip().endswith("=Yes")

    def _awake(self):
        """The run needs the Mac's screen unlocked (a person unlocks it; never done here) and keeps its display
        awake while it runs: caffeinate -d -i on an ssh connection of the lane's own, waiting on that
        connection's sshd (-w), so it ends with the lane. No system setting changes."""
        if self.screen_locked():
            raise HarnessFault("prepare", "the Mac's screen is locked: the app gets no window. Unlock the Mac "
                               "(a person at it) and run again")
        try:
            p = subprocess.Popen(["ssh", "-o", "ControlMaster=no", "-o", "ControlPath=none", *self.mac.opts,
                                  self.mac.host, "exec caffeinate -d -i -w $PPID"],
                                 stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            self.standins.append(p)
            self.log("display kept awake while the lane runs (caffeinate -d -i)")
        except OSError as e:
            self.log("caffeinate not started: %s" % e)

    def _unpack(self):
        """Each build into the run folder's previous/ or candidate/ (the same build once)."""
        done = {}
        for which, path in self.builds.items():
            key = path if path.startswith("mac:") else os.path.realpath(path)
            dest = "%s/%s" % (self.run, which)
            if key in done:
                self.mac.run("rm -rf %s && mkdir -p %s && ditto %s %s" % (q(dest), q(dest), q(done[key]), q("%s/%s" % (dest, APP_NAME))),
                             timeout=600, check=True)
            else:
                self._unpack_one(which, path, dest)
            app = "%s/%s" % (dest, APP_NAME)
            r = self.mac.run("test -x %s" % q("%s/%s" % (app, EXE)))
            if r.returncode != 0:
                raise HarnessFault("prepare", "the %s build has no %s/%s" % (which, APP_NAME, EXE))
            self.mac.run("xattr -dr com.apple.quarantine %s 2>/dev/null; true" % q(app), timeout=120)
            self.apps[which] = done[key] = app
            self.info[which] = self._app_info(app)
            bid = self.info[which].get("id")
            if bid != BUNDLE_ID:
                raise HarnessFault("prepare", "the %s app is %s, not %s" % (which, bid, BUNDLE_ID))
            self.log("%s app: %s (%s)" % (which, self.info[which].get("version"), self.info[which].get("build")))

    def _unpack_one(self, which, path, dest):
        k = kind_of(path)
        self.mac.run("rm -rf %s && mkdir -p %s" % (q(dest), q(dest)), check=True)
        if k == "mac-app":
            src = path[4:]
            self.mac.run("ditto %s %s" % (q(src), q("%s/%s" % (dest, APP_NAME))), timeout=600, check=True)
        elif k == "app":
            with tarfile.open(os.path.join(self.work, "%s.tar" % which), "w") as t:
                t.add(path, arcname=APP_NAME)
            self.mac.put_file(os.path.join(self.work, "%s.tar" % which), "%s.tar" % dest)
            os.remove(os.path.join(self.work, "%s.tar" % which))
            self.mac.run("tar -xf %s -C %s && rm -f %s" % (q(dest + ".tar"), q(dest), q(dest + ".tar")), timeout=600, check=True)
        elif k == "tar":
            self.mac.put_file(path, "%s.tar" % dest)
            self.mac.run("tar -xf %s -C %s && rm -f %s" % (q(dest + ".tar"), q(dest), q(dest + ".tar")), timeout=600, check=True)
        elif k == "zip":
            self.mac.put_file(path, "%s.zip" % dest)
            self.mac.run("ditto -x -k %s %s && rm -f %s" % (q(dest + ".zip"), q(dest), q(dest + ".zip")), timeout=600, check=True)
        elif k == "dmg":
            dmg, mnt = "%s.dmg" % dest, "%s.mnt" % dest
            self.mac.put_file(path, dmg)
            r = self.mac.run("mkdir -p %s && hdiutil attach -nobrowse -readonly -noautoopen -mountpoint %s %s" % (
                q(mnt), q(mnt), q(dmg)), timeout=300)
            if r.returncode != 0:
                raise HarnessFault("prepare", "the %s dmg does not mount: %s" % (which, (r.stdout + r.stderr).strip()[-200:]))
            try:
                self.mac.run("ditto %s %s" % (q("%s/%s" % (mnt, APP_NAME)), q("%s/%s" % (dest, APP_NAME))), timeout=600, check=True)
            finally:
                self.mac.run("hdiutil detach %s -quiet || hdiutil detach %s -force -quiet; rmdir %s; rm -f %s" % (
                    q(mnt), q(mnt), q(mnt), q(dmg)), timeout=120)
        # a test build's tar may hold the app one folder down
        found = self.mac.sh("cd %s && ls -d %s */%s 2>/dev/null | head -1" % (q(dest), q(APP_NAME), q(APP_NAME))).strip()
        if found and found != APP_NAME:
            self.mac.run("mv %s %s" % (q("%s/%s" % (dest, found)), q("%s/%s" % (dest, APP_NAME))), check=True)

    def _app_info(self, app):
        plist = q("%s/Contents/Info.plist" % app)
        got = {}
        for k, key in (("id", "CFBundleIdentifier"), ("version", "CFBundleShortVersionString"), ("build", "CFBundleVersion")):
            r = self.mac.run("plutil -extract %s raw %s" % (key, plist), timeout=60)
            got[k] = r.stdout.strip() if r.returncode == 0 else None
        r = self.mac.run("codesign -d -r - %s 2>&1" % q(app), timeout=120)
        got["requirement"] = designated(r.stdout)
        got["signer"] = "ad hoc" if adhoc(got["requirement"]) else ("Developer ID %s" % devid_team(got["requirement"])
                                                                     if devid_team(got["requirement"]) else got["requirement"])
        return got

    def _signing(self):
        """The candidate opens the previous release's keychain items without a prompt only with the same
        designated requirement: an ad hoc candidate is signed with the Developer ID of a Developer ID previous
        release; another difference refuses the run before the app starts."""
        if self.create or "previous" not in self.info:
            return
        p, c = self.info["previous"], self.info["candidate"]
        if p["requirement"] == c["requirement"]:
            self.log("signing: previous and candidate have the same designated requirement (%s)" % p["signer"])
            return
        if not (adhoc(c["requirement"]) and devid_team(p["requirement"]) == TEAM):
            raise HarnessFault("prepare", "the candidate (%s) and the previous release (%s) are signed differently: its "
                               "keychain items would ask for the keychain's password on screen" % (c["signer"], p["signer"]))
        self._devid_sign(self.apps["candidate"])
        self.info["candidate"] = self._app_info(self.apps["candidate"])
        if self.info["candidate"]["requirement"] != p["requirement"]:
            raise HarnessFault("prepare", "after signing, the candidate's designated requirement is %s, not %s" % (
                self.info["candidate"]["requirement"], p["requirement"]))
        self.health["resigned"] = "the ad hoc candidate signed with Developer ID %s on the Mac (devid_sign's order)" % TEAM
        self.log("signing: %s" % self.health["resigned"])

    def _devid_sign(self, app):
        """tools/build-apple.sh devid_sign on the Mac: each loose Mach-O deepest first (not a framework's own
        binary), then the frameworks, then the app with Release.entitlements; hardened runtime and Apple's
        timestamp on each. The identity is the Developer ID in build.keychain, unlocked for this ssh session."""
        ent = "%s/Release.entitlements" % self.run
        self.mac.put_file(os.path.join(DRIVERS, "..", "..", "..", "app", "macos", "Runner", "Release.entitlements"), ent)
        guard = MacSurface(self.mac, self.helper, self.sock, 0, log=self.log)
        guard.guard_start()
        script = r"""set -e
kc=%(kc)s
security unlock-keychain -p "" "$kc"
id=$(security find-identity -v -p codesigning "$kc" | awk -v t='(%(team)s)"' 'index($0, "\"Developer ID Application:") && index($0, t) { print $2; exit }')
[ -n "$id" ] || { echo "no Developer ID Application identity of %(team)s in $kc"; exit 3; }
cd %(app)s
find Contents -type f -not -path 'Contents/Resources/*.bundle/*' | awk '{ print length($0) " " $0 }' | LC_ALL=C sort -rn | cut -d' ' -f2- |
while IFS= read -r rel; do
  case "$(file -b "$rel")" in Mach-O*) ;; *) continue ;; esac
  [ "$rel" != %(exe)s ] || continue
  case "$rel" in Contents/Frameworks/*.framework/Versions/*/*)
    fw="${rel%%%%.framework/*}.framework"; name="$(basename "$fw" .framework)"
    case "$rel" in "$fw"/Versions/*/"$name") continue ;; esac ;;
  esac
  codesign --force --timestamp --options runtime --keychain "$kc" --sign "$id" "$rel"
done
for fw in Contents/Frameworks/*.framework; do
  [ -d "$fw" ] && codesign --force --timestamp --options runtime --keychain "$kc" --sign "$id" "$fw"
done
codesign --force --timestamp --options runtime --keychain "$kc" --sign "$id" --entitlements %(ent)s .
codesign --verify --deep --strict .
""" % {"kc": SIGN_KEYCHAIN.replace("~", "$HOME"), "team": TEAM, "app": q(app), "exe": q(EXE), "ent": q(ent)}
        r = self.mac.run("zsh -l -s", inp=script, timeout=900)
        guard.guard(force=True)   # SystemDialog when signing put one on screen
        if r.returncode != 0:
            raise HarnessFault("prepare", "signing the candidate with the Developer ID failed: %s" % (r.stdout + r.stderr).strip()[-300:])

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
        """A stand-in for each server that is not local; a local one is its own custom entry. Every port the
        app is given goes in self.ports for the tunnel's -R, under a port of its own on the Mac: another lane on
        the same Mac may forward the hermetic node's port there."""
        plan = self.hermetic or {}
        ports = {}
        for kind, up in (("node", self.node), ("relay", self.relay)):
            if plan.get(kind):
                continue
            ports[kind] = free_port()
            logf = open(os.path.join(self.out, "standin-%s.log" % kind), "w")
            self.standins.append(subprocess.Popen(
                [sys.executable, "-I", os.path.join(DRIVERS, "linux", "standin.py"), kind, str(ports[kind]), up],
                stdout=logf, stderr=subprocess.STDOUT, start_new_session=True))
        for attempt in range(3):
            time.sleep(1 if attempt == 0 else 5)
            if "node" not in ports or node_up("http://127.0.0.1:%d" % ports["node"]):
                break
        else:
            raise HarnessFault("prepare", "the loopback node stand-in does not answer")
        self.ports = list(ports.values()) + plan.get("ports", [])
        self._mac_ports()
        on_mac = dict((here, there) for there, here in self.forwards)
        node = hermetic.entry(plan["node"]) if plan.get("node") else "127.0.0.1:%d" % ports["node"]
        relay = hermetic.entry(plan["relay"]) if plan.get("relay") else "127.0.0.1:%d" % ports["relay"]
        self.custom_node, self.custom_relay = (re.sub(r":(\d+)$", lambda m: ":%d" % on_mac.get(int(m.group(1)), int(m.group(1))), x)
                                               for x in (node, relay))

    def _mac_ports(self):
        """(port on the Mac, port here) for each of self.ports: ports nothing listens on there, picked once
        so the app's servers stay the same through a recovery."""
        taken = set(int(x) for x in re.findall(r"[.:](\d+)\s", self.mac.sh(
            "netstat -anp tcp 2>/dev/null | awk '/LISTEN/ {print $4\" \"}'")))
        self.forwards = []
        for here in self.ports:
            there = next(p for p in (random.randint(20000, 60999) for _ in range(1000)) if p not in taken)
            taken.add(there)
            self.forwards.append((there, here))

    def _tunnel(self):
        mac_ports = [there for there, _ in self.forwards]
        busy = [p for p in mac_ports if self.mac.sh("lsof -nP -iTCP:%d -sTCP:LISTEN -t 2>/dev/null" % p).strip()]
        if busy:
            raise HarnessFault("prepare", "port(s) %s are taken on the Mac" % busy)
        logf = open(os.path.join(self.out, "tunnel.log"), "a")
        self.mac.open_tunnel(remote=self.forwards, logf=logf)
        for _ in range(20):
            time.sleep(0.5)
            if not self.mac.tunnel_up():
                raise HarnessFault("prepare", "the ssh tunnel to %s ended (a port taken there? tunnel.log)" % self.mac.host)
            if all(self.mac.sh("lsof -nP -iTCP:%d -sTCP:LISTEN -t 2>/dev/null" % p).strip() for p in mac_ports):
                return
        raise HarnessFault("prepare", "the tunnel's ports %s do not listen on the Mac" % mac_ports)

    def live_servers(self):
        """The public node and relay the live-servers phase puts in use (core/lane.py)."""
        return hermetic.pick_live(node_up, relay_up, nodehealth.synced_first(facts.NODE_PICK, log=self.log), facts.RELAY_PICK)

    def start_check(self):
        """Before the run: the first build to run is started once on a home of its own (check-home, removed
        after), left CHECK_S, and the screen looked at. A system dialog fails the run here (ax.py)."""
        which = "candidate" if self.create else "previous"
        home = "%s/check-home" % self.run
        app = self.apps[which]
        self.mac.run("rm -rf %s && mkdir -p %s" % (q(home), q(home)), check=True)
        s = self._launch(app, home, "start-check")
        try:
            t0 = time.time()
            while time.time() - t0 < CHECK_S:
                if not s.alive():
                    raise ProductFault("wallet_opens", "the %s app ended within %d s of its start (start-check.log)" % (which, CHECK_S))
                time.sleep(2)
            s.guard(force=True)
            n = len(s.tree())
            self.health["start_check"] = "the %s app ran %d s on a home of its own; no system dialog; %d nodes on screen" % (
                which, CHECK_S, n)
            self.log("start check: %s" % self.health["start_check"])
        finally:
            self._quit(s)
            self.mac.run("rm -rf %s" % q(home), timeout=120)

    # ---- installs

    def install_previous(self):
        self._install("previous", fresh=True)

    def install_candidate_fresh(self):
        self._install("candidate", fresh=True)

    def _install(self, which, fresh):
        """The build's app in the run's Applications folder; fresh: the home emptied (data folder and keychain)."""
        if self.running:
            self.stop()
        if fresh:
            self.mac.run("rm -rf %s && mkdir -p %s" % (q(self.home), q(self.home)), check=True)
        self.mac.run("rm -rf %s && ditto %s %s" % (q(self.installed), q(self.apps[which]), q(self.installed)), timeout=600, check=True)
        self.log("installed the %s app: %s" % (which, self.version()))

    def version(self):
        got = self._app_info(self.installed)
        return "%s+%s (%s)" % (got.get("version"), got.get("build"), got.get("signer"))

    # ---- the app

    def _launch(self, app, home, tag):
        """launch.sh in a new terminal tab in the user's session; -> a MacSurface once the app's window is read."""
        self.launches += 1
        log, pidf = "%s/%s-%d.log" % (self.run, tag, self.launches), "%s/%s-%d.pid" % (self.run, tag, self.launches)
        guard = MacSurface(self.mac, self.helper, self.sock, 0, log=self.log)
        guard.guard_start()
        r = self.mac.run("%s tab create --cwd %s --label %s" % (q(self.term), q(self.run), q("wfe-lane-%s" % tag)), timeout=60)
        try:
            js = json.loads(r.stdout).get("result") or {}
            pane, tab = js["root_pane"]["pane_id"], js["tab"]["tab_id"]
        except (ValueError, KeyError, TypeError):
            raise HarnessFault("start", "terminal tab create: %s" % (r.stdout + r.stderr).strip()[-200:])
        self.tab = tab
        cmd = "zsh %s %s %s %s %s; exit" % (q("%s/launch.sh" % self.run), q(home), q(app), q(log), q(pidf))
        r = self.mac.run("%s pane run %s %s" % (q(self.term), q(pane), q(cmd)), timeout=60)
        if r.returncode != 0:
            raise HarnessFault("start", "terminal pane run: %s" % (r.stdout + r.stderr).strip()[-200:])
        pid = None
        for _ in range(60):
            got = self.mac.sh("cat %s 2>/dev/null" % q(pidf)).strip()
            if got == "refused":
                raise HarnessFault("start", "launch.sh refused: %s" % self.mac.sh("cat %s" % q(log)).strip()[-300:])
            if got.isdigit():
                pid = int(got)
                break
            time.sleep(1)
        if pid is None:
            raise HarnessFault("start", "the app's launch wrote no pid in 60 s (terminal tab %s)" % tab)
        s = MacSurface(self.mac, self.helper, self.sock, pid, log=self.log, app_log="%s/%s/logs/wfe.log" % (home, DATA_FOLDER))
        s.guard_start()
        t0, hung = time.time(), None
        while time.time() - t0 < START_S:
            if not s.alive():
                raise ProductFault("wallet_opens", "the app ended after its start: %s" % self.mac.sh("tail -c 600 %s" % q(log)).strip())
            try:
                if s.tree():
                    break
                hung = None
            except freeze.Frozen as e:
                # A starting app's main thread is busy (keychain, store, first frame): its AX calls time out
                # for a moment. A freeze is one that outlasts the start window.
                hung = hung or e
                self.log("start: the app's AX calls time out (%d s after its start); waiting" % (time.time() - t0))
            except HarnessFault as e:
                if isinstance(e, SystemDialog):
                    raise
            time.sleep(2)
        else:
            if self.screen_locked():
                raise HarnessFault("start", "the Mac's screen is locked: the app gets no window. Unlock the Mac "
                                   "(a person at it) and run again")
            if hung is not None:
                raise hung
            raise ProductFault("wallet_opens", "the app shows no window in %d s" % START_S)
        self.health["starts"].append({"tag": tag, "pid": pid, "s": round(time.time() - t0)})
        return s

    def start(self, which):
        if self.running == which and self.surface is not None and self.surface.alive():
            self.log("%s app already running" % which)
            return self.surface
        if self.surface is not None and self.pid and self.surface.alive():
            self.stop()
        self.surface = self._launch(self.installed, self.home, which)
        self.pid, self.running = self.surface.pid, which
        self.log("%s app up (pid %d): %s" % (which, self.pid, self.version()))
        return self.surface

    def _quit(self, s):
        """Cmd+Q to the app (a user's quit; the app saves and ends its node and tor), else SIGTERM, then SIGKILL;
        its terminal tab closed."""
        how = "Cmd+Q"
        try:
            s.key("quit")
        except Exception as e:  # noqa: BLE001 — the signals below end it either way
            self.log("Cmd+Q: %s" % e)
        t0 = time.time()
        while time.time() - t0 < QUIT_S and self.mac.run("kill -0 %d 2>/dev/null" % s.pid).returncode == 0:
            time.sleep(1)
        if self.mac.run("kill -0 %d 2>/dev/null" % s.pid).returncode == 0:
            how = "SIGTERM after Cmd+Q did nothing in %d s" % QUIT_S
            self.mac.run("kill -TERM %d" % s.pid)
            for _ in range(15):
                time.sleep(1)
                if self.mac.run("kill -0 %d 2>/dev/null" % s.pid).returncode != 0:
                    break
            else:
                how = "SIGKILL"
                self.mac.run("kill -KILL %d" % s.pid)
        self.health["stops"].append({"pid": s.pid, "how": how, "s": round(time.time() - t0)})
        if self.tab:
            self.mac.run("%s tab close %s" % (q(self.term), q(self.tab)), timeout=30)
            self.tab = None
        return how

    def stop(self):
        if self.surface is None or not self.pid:
            self.running = None
            return
        how = self._quit(self.surface)
        self.log("%s app closed (%s)" % (self.running or "the", how))
        if how != "Cmd+Q":
            self.log("NOTE: the app did not end on Cmd+Q")
        self.running, self.pid = None, None

    def update(self):
        if self.running:
            self.stop()
        before = self.version()
        self.mac.run("rm -rf %s && ditto %s %s" % (q(self.installed), q(self.apps["candidate"]), q(self.installed)),
                     timeout=600, check=True)
        got = self._app_info(self.installed)
        want = self.info["candidate"]
        if (got.get("version"), got.get("build")) != (want.get("version"), want.get("build")):
            raise HarnessFault("update", "after the replacement the app is %s+%s, not %s+%s" % (
                got.get("version"), got.get("build"), want.get("version"), want.get("build")))
        self.log("update: app bundle replaced; %s → %s" % (before, self.version()))

    def recover(self):
        """ssh or the tunnel went: both again, and the app that ran started again if it is gone."""
        which = self.running
        self.health["recovered"] += 1
        self.log("recover: ssh, tunnel")
        if not self.mac.online():
            raise HarnessFault("recover", "the Mac %s does not answer" % self.mac.host)
        self._tunnel()
        self._helper_check()
        if which and not (self.surface and self.surface.alive()):
            self.running = None
            self.start(which)

    def alive(self):
        return self.surface is not None and self.surface.alive()

    # ---- data

    def _files(self):
        f = AppFiles(self.mac, self.home)
        try:
            f.prepare()
        except wd.ReadError as e:
            raise HarnessFault("files", str(e))
        return f

    def digest(self, tag, secrets):
        if self.running and not self.alive():
            raise ProductFault("app_alive", "the %s app is not running any more when its data was read" % self.running)
        return wd.read(self._files(), secrets, migrate=checks.migrating()[0], nodes=[self.node], log=self.log)

    def files_snapshot(self):
        return wd.snapshot(self._files())

    def seed_previous_files(self, secrets):
        """While the previous release is closed and only when the candidate migrates a plain store: a
        contact, a note on the first transaction and the stand-in node's plain-http agreement, in the
        previous release's own files and format (seed.py)."""
        if not checks.migrating()[1]:
            return
        files = self._files()
        listing = files.listing()
        metas = [p for p in listing if re.fullmatch(r"wallets/[^/]+/" + re.escape(facts.META_PLAIN), p)]
        dbs = [p for p in listing if re.fullmatch(r"wallets/[^/]+/%s/%s" % (re.escape(facts.STORE_DIR), re.escape(facts.STORE_PLAIN)), p)]
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
        self.log("seeded into the closed previous release: contact %r, a note, plain-http agreement for %s" % (
            seed.CONTACT["name"], self.custom_node))

    # ---- saved states: none on macOS yet

    def save_state(self, folder):
        raise HarnessFault("save-state", "no saved states on macOS yet (REL_TRUST_SAVE_STATE=0)")

    def restore_state(self, folder):
        raise HarnessFault("restore", "no saved states on macOS yet")

    def fits(self, meta):
        return False, "no saved states on macOS yet"

    def state_meta(self):
        return {}

    # ---- end

    def logs(self):
        return {n: os.path.join(self.out, n) for n in ("wfe.log", "app.log", "tunnel.log")}

    def shutdown(self):
        leave = self.keep or self.keep_up
        try:
            if self.surface is not None and self.pid and not leave:
                self.stop()
        except Exception as e:  # noqa: BLE001
            self.log("stop: %s" % e)
        try:
            if self.run:
                with open(os.path.join(self.out, "wfe.log"), "w") as f:
                    f.write(self.mac.sh("tail -n 3000 %s 2>/dev/null" % q("%s/%s/logs/wfe.log" % (self.home, DATA_FOLDER)), timeout=120))
                with open(os.path.join(self.out, "app.log"), "w") as f:
                    f.write(self.mac.sh("cd %s && for f in *.log; do echo \"== $f\"; tail -n 400 \"$f\"; done 2>/dev/null" % q(self.run),
                                        timeout=120))
        except Exception as e:  # noqa: BLE001
            self.log("logs: %s" % e)
        for p in self.standins:
            try:
                p.terminate()
                p.wait(5)
            except Exception:  # noqa: BLE001
                p.kill()
        self.health["signers"] = {w: i.get("signer") for w, i in self.info.items()}
        with open(os.path.join(self.out, "macos.json"), "w") as f:
            json.dump(self.health, f, indent=1)
        if not leave and self.run:
            try:  # the run's apps; the home (the test wallet's data and throwaway keychain) stays for a look
                self.mac.run("rm -rf %s %s %s" % (q("%s/previous" % self.run), q("%s/candidate" % self.run),
                                                  q("%s/Applications" % self.run)), timeout=300)
            except Exception as e:  # noqa: BLE001
                self.log("run folder: %s" % e)
        try:
            self.mac.close()
        except Exception as e:  # noqa: BLE001
            self.log("ssh close: %s" % e)
        shutil.rmtree(self.work, ignore_errors=True)
        self.log("macOS: %s; stand-ins stopped; run folder %s" % ("app left up" if leave else "app closed", self.run))


# the same server probes as ios/ios_platform.py
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
