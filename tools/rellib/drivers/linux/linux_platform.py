# SPDX-License-Identifier: Apache-2.0
"""Linux desktop for core/lane.py: the real release AppImages, extracted (no libfuse2 here), run in a
sandbox of their own (HOME, Xvfb, dbus, keyring; sandbox.py) and read over AT-SPI (atspi.py).

The update is the AppImage swap: the previous release's AppImage stops, the candidate's starts on
the same HOME (data folder and keyring kept), which is what the in-app AppImage update leaves. A
loopback node and relay stand-in (standin.py) give the wallet servers of the user's own that are in
no built-in list. The wallet's data is read from the sandbox's files (files.py, core/walletdata.py).
"""
import glob
import os
import re
import shutil
import signal
import socket
import sqlite3
import ssl
import subprocess
import sys
import tarfile
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, HERE)

import facts  # noqa: E402
import sandbox  # noqa: E402
import seed  # noqa: E402
from atspi import AtspiSurface  # noqa: E402
from core import checks  # noqa: E402
from core import walletdata as wd  # noqa: E402
from core.faults import HarnessFault, HarnessGone, ProductFault  # noqa: E402
from core.lane import Platform  # noqa: E402
from files import SandboxFiles, data_root  # noqa: E402


class LinuxPlatform(Platform):
    name, family = "linux", "desktop"
    update_method = ("appimage-swap: the previous release's AppImage, then the candidate's on the same sandbox HOME "
                     "(data folder and keyring kept, as the in-app update leaves them); both run extracted")

    def __init__(self, out, log):
        e = os.environ
        self.out, self.log = out, log
        self.variant = e.get("REL_VARIANT") or "tor"
        stamp = time.strftime("%Y%m%d-%H%M%S")
        work_root = e.get("REL_WORK") or os.path.join(os.path.expanduser("~"), ".cache", "rel-trust-linux")
        self.work = os.path.join(work_root, "%s-%s-to-%s-%s" % (self.variant, e.get("REL_PREVIOUS_VERSION", "?"),
                                                                 e.get("REL_CANDIDATE_VERSION", "?"), stamp))
        self.sb = os.path.join(self.work, "sandbox")
        self.node, self.relay = e.get("REL_NODE", ""), e.get("REL_EPICBOX", "")
        self.custom_node = self.custom_relay = None
        self.roots = {}
        self.running = None   # 'previous' | 'candidate' while an app runs
        self.standins = []
        self.lan_before = None
        self.surface = None

    # ---- preparation

    def appimage(self, folder, version):
        sfx = "-notor" if self.variant == "notor" else ""
        for n in ("bt-wallet-%s%s-linux-x86_64.AppImage" % (version, sfx), "EpicCashDesktop-%s%s-x86_64.AppImage" % (version, sfx)):
            if os.path.isfile(os.path.join(folder, n)):
                return os.path.join(folder, n)
        rx = re.compile(r"^(?:bt-wallet-.*%s-linux|EpicCashDesktop-.*%s)-x86_64\.AppImage$" % ((sfx or r"(?<!-notor)",) * 2))
        hits = sorted(f for f in os.listdir(folder) if rx.search(f)) if os.path.isdir(folder) else []
        if len(hits) == 1:
            return os.path.join(folder, hits[0])
        raise HarnessFault("prepare", "no %s AppImage for %s in %s" % (self.variant, version, folder))

    def prepare(self):
        e = os.environ
        os.makedirs(self.sb, mode=0o700, exist_ok=True)
        self._pick_servers()
        self._standins()
        for which, folder, ver in (("previous", e.get("REL_PREVIOUS_DIR", ""), e.get("REL_PREVIOUS_VERSION", "")),
                                   ("candidate", e.get("REL_CANDIDATE_DIR", ""), e.get("REL_CANDIDATE_VERSION", ""))):
            self.roots[which] = self._extract(self.appimage(folder, ver), which)
        sandbox.start(self.sb)
        self.log("sandbox %s up; node %s (+ %s), Epicbox %s (+ %s)" % (self.sb, self.node, self.custom_node, self.relay, self.custom_relay))

    def _pick_servers(self):
        if not self.node:
            self.node = next((u for u in facts.NODE_PICK if node_up(u)), "")
        if not self.relay:
            self.relay = next((h for h in facts.RELAY_PICK if relay_up(h)), "")
        if not self.node or not self.relay:
            raise HarnessFault("prepare", "no node or Epicbox server answers (%s / %s)" % (facts.NODE_PICK, facts.RELAY_PICK))
        if "://" not in self.node:
            self.node = "https://" + self.node

    def _standins(self):
        ports = {}
        for kind, up in (("node", self.node), ("relay", self.relay)):
            ports[kind] = free_port()
            log = open(os.path.join(self.out, "standin-%s.log" % kind), "w")
            self.standins.append(subprocess.Popen([sys.executable, "-I", os.path.join(HERE, "standin.py"), kind, str(ports[kind]), up],
                                                  stdout=log, stderr=subprocess.STDOUT, start_new_session=True))
        for attempt in range(3):  # one slow answer from the upstream node is not a dead stand-in
            time.sleep(1 if attempt == 0 else 5)
            if node_up("http://127.0.0.1:%d" % ports["node"]):
                break
        else:
            raise HarnessFault("prepare", "the loopback node stand-in does not answer")
        self.custom_node = "127.0.0.1:%d" % ports["node"]
        self.custom_relay = "127.0.0.1:%d" % ports["relay"]

    def _extract(self, appimage, which):
        dest = os.path.join(self.work, which)
        os.makedirs(dest, exist_ok=True)
        copy = os.path.join(dest, "app.AppImage")
        shutil.copyfile(appimage, copy)
        os.chmod(copy, 0o700)
        r = subprocess.run([copy, "--appimage-extract"], cwd=dest, capture_output=True, text=True, timeout=300)
        os.unlink(copy)
        root = os.path.join(dest, "squashfs-root")
        if r.returncode != 0 or not os.path.exists(os.path.join(root, "AppRun")):
            raise HarnessFault("prepare", "could not extract %s: %s" % (appimage, r.stderr[-300:]))
        self.log("%s: %s" % (which, os.path.basename(appimage)))
        return root

    def install_previous(self):
        """A fresh install is the empty sandbox HOME: nothing to do but make sure it is empty."""
        if os.listdir(data_root(self.sb)) if os.path.isdir(data_root(self.sb)) else False:
            raise HarnessFault("install", "the new sandbox already has a data folder")

    # ---- the app

    def start(self, which):
        """One surface for the whole lane: its AT-SPI worker reads the sandbox's environment when it
        starts, so it follows a sandbox started again by recover(). The app recover() already started
        again is the one the re-run phase uses: a second copy would quit (one instance per user)."""
        if self.running == which and self.alive():
            self.log("%s app already running (started again by the recovery)" % which)
            return self.surface or AtspiSurface(self.sb, self.log)
        pid = sandbox.app(self.sb, self.roots[which])
        self.running = which
        self.log("%s app started (pid %d)" % (which, pid))
        if self.surface is None:
            self.surface = AtspiSurface(self.sb, self.log)
        return self.surface

    def stop(self):
        """Closed the way the desktop session closes it (SIGTERM, then the window's process tree)."""
        if self.surface:
            self.surface.close()
        sandbox.app_stop(self.sb)
        self.running = None
        time.sleep(2)

    def update(self):
        """The AppImage swap: the candidate runs from now on, on the same HOME."""
        if self.running:
            self.stop()
        self.log("update: %s" % self.update_method)

    def recover(self):
        """The sandbox's display, dbus or keyring went: started again on the same HOME, and the app that
        ran is started again (the phase that failed then finds where it is)."""
        which = self.running
        try:
            sandbox.stop(self.sb)
        except (Exception, SystemExit) as e:  # noqa: BLE001
            self.log("recover: sandbox stop: %s" % e)
        sandbox.start(self.sb)
        if self.surface:
            self.surface.close()
        if which:
            self.start(which)

    def alive(self):
        return sandbox._alive(sandbox._pid(self.sb, "app"))

    # ---- data

    def digest(self, tag, secrets):
        if self.running and not self.alive():
            if self.surface and not self.surface.display_alive():  # the app goes with the display
                raise HarnessGone("digest", "the sandbox's Xvfb or dbus is gone")
            raise ProductFault("app_alive", "the %s app is not running any more when its data was read" % self.running)
        files = SandboxFiles(self.sb, os.path.join(self.work, "read"))
        return wd.read(files, secrets, migrate=checks.migrating()[0], nodes=[self.node], log=self.log)

    def files_snapshot(self):
        return wd.snapshot(wd.DirFiles(data_root(self.sb)))

    def seed_previous_files(self, secrets):
        """While the previous release is closed and only when the candidate migrates a plain store: a
        contact, a note on the first transaction and the stand-in node's plain-http agreement, in the
        previous release's own files and format (seed.py)."""
        if not checks.migrating()[1]:
            return
        root = data_root(self.sb)
        metas = sorted(glob.glob(os.path.join(root, "wallets", "*", facts.META_PLAIN)))
        dbs = sorted(glob.glob(os.path.join(root, "wallets", "*", facts.STORE_DIR, facts.STORE_PLAIN)))
        if len(metas) != 1 or len(dbs) != 1:
            raise HarnessFault("seed", "the previous release left %d %s and %d %s under wallets/ (one each expected)" % (
                len(metas), facts.META_PLAIN, len(dbs), facts.STORE_PLAIN))

        def read(rel):
            try:
                with open(os.path.join(root, rel), encoding="utf-8") as f:
                    return f.read()
            except OSError:
                return None

        def put(path, text):
            with open(path + ".seed", "w", encoding="utf-8") as f:
                f.write(text)
            os.chmod(path + ".seed", 0o600)
            os.replace(path + ".seed", path)

        try:
            with open(metas[0], encoding="utf-8") as f:
                meta = seed.meta_note(f.read(), seed.first_tx_id(dbs[0]))
            contacts = seed.contacts_json(read(facts.CONTACTS_PLAIN), checks.P_ADDR)
        except (seed.SeedError, OSError) as e:
            raise HarnessFault("seed", "seeding the previous release's contact and note: %s" % e)
        put(metas[0], meta)
        put(os.path.join(root, facts.CONTACTS_PLAIN), contacts)
        put(os.path.join(root, facts.LAN_NODES_FILE), seed.lan_nodes_json(["http://%s" % self.custom_node]))
        self.lan_before = read(facts.LAN_NODES_FILE)
        self.log("seeded into the closed previous release: contact %r, a note, plain-http agreement for %s" % (
            seed.CONTACT["name"], self.custom_node))

    # ---- saved states (core/state.py)

    def save_state(self, folder):
        """The sandbox HOME and its keyring password; the app is stopped first so its files are whole."""
        if self.running:
            self.stop()
        with tarfile.open(os.path.join(folder, "home.tar"), "w") as t:
            t.add(os.path.join(self.sb, "home"), arcname="home")
        shutil.copy2(os.path.join(self.sb, "keyring.pw"), os.path.join(folder, "keyring.pw"))

    def restore_state(self, folder):
        sandbox.stop(self.sb)
        home = os.path.join(self.sb, "home")
        if os.path.isdir(home):
            shutil.rmtree(home)
        with tarfile.open(os.path.join(folder, "home.tar")) as t:
            t.extractall(self.sb, filter="data")
        shutil.copy2(os.path.join(folder, "keyring.pw"), os.path.join(self.sb, "keyring.pw"))
        sandbox.start(self.sb)
        self.log("restored the saved HOME into %s" % self.sb)

    def fits(self, meta):
        if meta.get("platform") != "linux" or meta.get("variant") != self.variant:
            return False, "saved for %s %s" % (meta.get("platform"), meta.get("variant"))
        return True, ""

    # ---- break tests (core/breaks.py)

    def break_kill(self):
        """Xvfb gone, as when the host's display server dies: the app goes with it."""
        os.kill(int(sandbox._pid(self.sb, "xvfb")), signal.SIGKILL)

    def break_freeze(self, on):
        pid = sandbox._pid(self.sb, "app")
        if pid and sandbox._alive(pid):
            os.killpg(os.getpgid(int(pid)), signal.SIGSTOP if on else signal.SIGCONT)

    def break_lose_balance(self):
        dbs = glob.glob(os.path.join(data_root(self.sb), "wallets", "*", facts.STORE_DIR, facts.STORE_PLAIN))
        if len(dbs) != 1:
            raise HarnessFault("break", "lose-balance needs one plain %s (found %d)" % (facts.STORE_PLAIN, len(dbs)))
        c = sqlite3.connect(dbs[0])
        try:
            n = c.execute("delete from outputs").rowcount
            c.commit()
        finally:
            c.close()
        self.log("BREAK: %d outputs deleted from the closed wallet's database" % n)

    def break_lose_node(self):
        path = os.path.join(data_root(self.sb), "settings.toml")
        if not os.path.exists(path):
            raise HarnessFault("break", "lose-node needs the previous release's settings.toml")
        with open(path) as f:
            lines = f.readlines()
        kept = [ln for ln in lines if self.custom_node not in ln]
        if len(kept) == len(lines):
            raise HarnessFault("break", "lose-node: %s is not in settings.toml" % self.custom_node)
        with open(path, "w") as f:
            f.writelines(kept)
        self.log("BREAK: the custom node %s removed from the closed wallet's settings.toml" % self.custom_node)

    def logs(self):
        return {"wfe.log": os.path.join(data_root(self.sb), "logs", "wfe.log"), "sandbox": os.path.join(self.sb, "logs")}

    def shutdown(self):
        if self.surface:
            self.surface.close()
        try:
            sandbox.stop(self.sb)
        except (Exception, SystemExit) as e:  # noqa: BLE001
            self.log("sandbox stop: %s" % e)
        for p in self.standins:
            try:
                p.terminate()
                p.wait(5)
            except Exception:  # noqa: BLE001
                p.kill()
        for which in ("previous", "candidate"):
            shutil.rmtree(os.path.join(self.work, which), ignore_errors=True)
        shutil.rmtree(os.path.join(self.work, "read"), ignore_errors=True)
        self.log("sandbox stopped; wallet data, phrase and password kept in %s (mode 700)" % self.sb)


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
