# SPDX-License-Identifier: Apache-2.0
"""The app's data folder on the iOS Simulator as a `files` object for core/walletdata.py. A Simulator app's
data container is a plain folder of the Mac user's (`simctl get_app_container <udid> <bundle> data`); the
wallet's folder in it is found by its settings.toml / wallets.json, and its files are read over ssh.

The app's secure storage is the Simulator's Keychain, which only the app can read: the theme, Technical
details and the wallet level are therefore not readable here. store() is empty and says so in store_note;
walletdata lists them as "NOT read" in the details instead of passing them.
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from core import walletdata as wd  # noqa: E402
from mac import q  # noqa: E402

BUNDLE = "uk.btlabs.btwallet.ios"
STORE_NOTE = ("the app's secure storage is the Simulator's Keychain (the app's own): theme, Technical details "
              "and wallet level cannot be read from outside the app")


class AppFiles:
    """The app's data folder in the Simulator [udid] on [mac] (mac.Mac)."""

    store_note = STORE_NOTE

    def __init__(self, mac, udid, bundle=BUNDLE):
        self.mac, self.udid, self.bundle = mac, udid, bundle
        self.root = None

    def prepare(self):
        """The app's data container, and the wallet's folder in it. Raises wd.ReadError."""
        r = self.mac.run("xcrun simctl get_app_container %s %s data" % (q(self.udid), q(self.bundle)), timeout=60)
        box = r.stdout.strip()
        if r.returncode != 0 or not box.startswith("/"):
            raise wd.ReadError("the app's data container on %s: %s" % (self.udid, (r.stdout + r.stderr).strip()[-200:]))
        out = self.mac.sh("find %s \\( -name settings.toml -o -name wallets.json \\) -type f 2>/dev/null" % q(box))
        dirs = {os.path.dirname(l.strip()) for l in out.splitlines() if l.strip()}
        if len(dirs) != 1:
            raise wd.ReadError("the app's data folder (settings.toml, wallets.json) not found in %s: %s" % (box, sorted(dirs)))
        self.root = dirs.pop()
        return self.root

    def _need(self):
        if self.root is None:
            self.prepare()

    def _path(self, rel):
        wd.DirFiles.check_rel(rel)
        self._need()
        return "%s/%s" % (self.root, rel)

    # ---- the files interface

    def blob(self, rel):
        r = self.mac.run("cat %s" % q(self._path(rel)), text=False, timeout=120)
        return r.stdout if r.returncode == 0 else None

    def text(self, rel):
        b = self.blob(rel)
        return b.decode("utf-8", "replace") if b is not None else None

    def listing(self):
        self._need()
        out = self.mac.sh("cd %s && find . -type f" % q(self.root), timeout=120)
        files = [l.strip()[2:] for l in out.splitlines() if l.strip().startswith("./")]
        return sorted(f for f in files if f.split("/")[0] not in ("logs", "tor", "cache")
                      and not f.endswith((".lock", ".log")) and not os.path.basename(f).startswith("LOCK"))

    def fetch(self, rel, local):
        b = self.blob(rel)
        if b is None:
            return False
        with open(local, "wb") as f:
            f.write(b)
        return True

    def store(self):
        return {}

    # ---- writing, for the seed step (own files and format: seed.py)

    def put(self, rel, text, scratch=None):
        """Write [text] to <data folder>/rel, mode 600, through ssh's stdin. [scratch] is unused (Android's
        signature)."""
        dest = self._path(rel)
        r = self.mac.run("umask 077; cat > %s && chmod 600 %s" % (q(dest), q(dest)), inp=text.encode("utf-8"), text=False)
        if r.returncode != 0 or self.text(rel) != text:
            raise wd.ReadError("could not write %s into the app's data folder" % rel)

    def remove(self, rel):
        self.mac.run("rm -f %s" % q(self._path(rel)))

