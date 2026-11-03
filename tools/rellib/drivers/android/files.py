# SPDX-License-Identifier: Apache-2.0
"""The app's data folder on the Android emulator as a `files` object for core/walletdata.py. The emulator
image has adb root (the release APK is not debuggable, so no run-as); the data folder is found under
/data/data/<package> by its settings.toml / wallets.json, files are read with `adb exec-out cat`.

The app's secure storage and shared preferences are encrypted by the Android Keystore, which belongs to the
app's uid: the theme, Technical details and the wallet level are therefore not readable here. store() is empty
and says so in store_note; walletdata lists them as "NOT read" in the details instead of passing them.
"""
import os
import subprocess
import sys
import time

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from core import walletdata as wd  # noqa: E402

PKG = "uk.btlabs.btwallet"
ADB = os.environ.get("ADB", os.path.expanduser("~/Android/Sdk/platform-tools/adb"))
STORE_NOTE = ("the app's secure storage and preferences are encrypted by the Android Keystore (the app's uid): "
              "theme, Technical details and wallet level cannot be read from outside the app")


class AppFiles:
    """The app's data folder on the emulator [serial], read as root over adb."""

    store_note = STORE_NOTE

    def __init__(self, serial, pkg=PKG, adb=ADB):
        self.serial, self.pkg, self.adb = serial, pkg, adb
        self.root = None

    # ---- adb

    def _run(self, *args, timeout=60):
        return subprocess.run([self.adb, "-s", self.serial, *args], capture_output=True, timeout=timeout)

    def sh(self, cmd, timeout=60):
        return self._run("shell", cmd, timeout=timeout).stdout.decode("utf-8", "replace")

    def prepare(self):
        """adb root, and the app's data folder. Raises wd.ReadError."""
        if "uid=0" not in self.sh("id"):
            self._run("root")
            self._run("wait-for-device")
            time.sleep(2)
        if "uid=0" not in self.sh("id"):
            raise wd.ReadError("adb root is not available on this emulator image (the app's files cannot be read)")
        out = self.sh("find /data/data/%s -name settings.toml -o -name wallets.json 2>/dev/null" % self.pkg)
        dirs = {os.path.dirname(l.strip()) for l in out.splitlines() if l.strip()}
        if len(dirs) != 1:
            raise wd.ReadError("the app's data folder (settings.toml, wallets.json) not found under /data/data/%s: %s" % (
                self.pkg, sorted(dirs)))
        self.root = dirs.pop()
        return self.root

    def _need(self):
        if self.root is None:
            self.prepare()

    # ---- the files interface

    def blob(self, rel):
        wd.DirFiles.check_rel(rel)
        self._need()
        r = self._run("exec-out", "cat", "%s/%s" % (self.root, rel))
        return r.stdout if r.returncode == 0 else None

    def text(self, rel):
        b = self.blob(rel)
        return b.decode("utf-8", "replace") if b is not None else None

    def listing(self):
        self._need()
        out = self.sh("cd '%s' && find . -type f" % self.root, timeout=120)
        files = [l.strip()[2:] for l in out.splitlines() if l.strip().startswith("./")]
        return sorted(f for f in files if f.split("/")[0] not in ("logs", "tor", "cache")
                      and not f.endswith((".lock", ".log")) and not os.path.basename(f).startswith("LOCK"))

    def fetch(self, rel, local):
        wd.DirFiles.check_rel(rel)
        self._need()
        r = self._run("pull", "%s/%s" % (self.root, rel), local, timeout=120)
        return r.returncode == 0 and os.path.exists(local)

    def store(self):
        return {}

    # ---- writing, for the seed step (own files and format: seed.py)

    def put(self, rel, text, scratch):
        """Write [text] to <data folder>/rel with the app's owner and mode 600. [scratch]: a folder of ours."""
        wd.DirFiles.check_rel(rel)
        self._need()
        local = os.path.join(scratch, "seed-" + os.path.basename(rel))
        with open(local, "w", encoding="utf-8") as f:
            f.write(text)
        self._run("push", local, "/data/local/tmp/seed.tmp")
        uid = self.sh("stat -c %%u '%s'" % self.root).strip()
        dest = "%s/%s" % (self.root, rel)
        self.sh("cat /data/local/tmp/seed.tmp > '%s' && chown %s:%s '%s' && chmod 600 '%s'; restorecon '%s' 2>/dev/null" % (
            dest, uid, uid, dest, dest, dest))
        os.unlink(local)
        if self.text(rel) != text:
            raise wd.ReadError("could not write %s into the app's data folder" % rel)
