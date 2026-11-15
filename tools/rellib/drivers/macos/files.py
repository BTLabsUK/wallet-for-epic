# SPDX-License-Identifier: Apache-2.0
"""The macOS app's data folder as a `files` object for core/walletdata.py, read over ssh (ios/mac.py).

The lane runs the app with HOME (and CFFIXED_USER_HOME) set to a home of the lane's own, so the app's
data folder is `<lane home>/.epic_cash_desktop` (app/lib/src/data_folder_io.dart: `$HOME` on macOS).
prepare() finds the folder by its settings.toml / wallets.json and refuses one outside the lane home:
that is the check that the app's data went where the lane put it.

The app's secure storage is the keychain (flutter_secure_storage, the file keychain: secret_store.dart
MacOsOptions). In the lane that is the home's throwaway keychain, but an item there opens only for the
app without a prompt: reading it from outside would put a keychain dialog on the user's screen. So
store() is empty and says so in store_note; walletdata lists theme, Technical details and level as
"NOT read" instead of passing them.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "ios"))
from core import walletdata as wd  # noqa: E402
from mac import q  # noqa: E402

DATA_FOLDER = ".epic_cash_desktop"
STORE_NOTE = ("the app's secure storage is the lane home's keychain, whose items open only for the app (reading "
              "them from outside asks on screen): theme, Technical details and wallet level are not read")
SKIP_TOP = ("logs", "tor", "cache")


def skip(rel):
    """Files the digest never compares: logs, Tor's state, caches, lock files."""
    return (rel.split("/")[0] in SKIP_TOP or rel.endswith((".lock", ".log"))
            or os.path.basename(rel).startswith("LOCK"))


class AppFiles:
    """The app's data folder under the lane home [home] on [mac] (ios/mac.py Mac)."""

    store_note = STORE_NOTE

    def __init__(self, mac, home):
        self.mac, self.home = mac, home.rstrip("/")
        self.root = None

    def prepare(self):
        """The wallet's data folder: the one folder holding settings.toml or wallets.json under the lane
        home, which must be <home>/.epic_cash_desktop. Raises wd.ReadError."""
        out = self.mac.sh("find %s \\( -name settings.toml -o -name wallets.json \\) -type f -not -path '*/Library/*' 2>/dev/null"
                          % q(self.home), timeout=120)
        dirs = {os.path.dirname(l.strip()) for l in out.splitlines() if l.strip()}
        want = "%s/%s" % (self.home, DATA_FOLDER)
        if not dirs:
            raise wd.ReadError("no app data folder (settings.toml, wallets.json) under the lane home %s" % self.home)
        if dirs != {want}:
            raise wd.ReadError("the app's data is not (only) in the lane home's %s: %s" % (DATA_FOLDER, sorted(dirs)))
        self.root = want
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
        return sorted(f for f in (l.strip()[2:] for l in out.splitlines() if l.strip().startswith("./")) if not skip(f))

    def fetch(self, rel, local):
        b = self.blob(rel)
        if b is None:
            return False
        with open(local, "wb") as f:
            f.write(b)
        return True

    def store(self):
        return {}

    # ---- writing, for the seed step (the previous release's own files and format: seed.py)

    def put(self, rel, text, scratch=None):
        dest = self._path(rel)
        r = self.mac.run("umask 077; cat > %s && chmod 600 %s" % (q(dest), q(dest)), inp=text.encode("utf-8"), text=False)
        if r.returncode != 0 or self.text(rel) != text:
            raise wd.ReadError("could not write %s into the app's data folder" % rel)

    def remove(self, rel):
        self.mac.run("rm -f %s" % q(self._path(rel)))
