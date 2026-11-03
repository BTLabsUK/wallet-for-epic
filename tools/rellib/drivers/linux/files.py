# SPDX-License-Identifier: Apache-2.0
"""The Linux sandbox's wallet data as a `files` object for core/walletdata.py: the data folder is
<sandbox>/home/.epic_cash_desktop, the app's secure storage (flutter_secure_storage) is one libsecret
item in the sandbox's keyring, read here with the sandbox's own dbus session and keyring daemon, or, when
that session is gone (a stopped sandbox), with a throwaway daemon started on a copy of the keyring files
and unlocked with the sandbox's keyring password.

Nothing is printed: the secure-storage JSON goes from the reader process to this one over a pipe.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
sys.path.insert(0, HERE)
from core import walletdata as wd  # noqa: E402

DATA_DIR = ".epic_cash_desktop"
ACCOUNT = "uk.btlabs.epiccash.desktop.secureStorage"

# Runs inside the dbus session; prints the one JSON object of the app's keys.
READER = r"""
import json, sys
import gi
gi.require_version('Secret', '1')
from gi.repository import Secret
svc = Secret.Service.get_sync(Secret.ServiceFlags.LOAD_COLLECTIONS | Secret.ServiceFlags.OPEN_SESSION, None)
for c in svc.get_collections():
    c.load_items_sync(None)
    for it in c.get_items():
        if dict(it.get_attributes()).get('account') != sys.argv[1]:
            continue
        it.load_secret_sync(None)
        v = it.get_secret()
        sys.stdout.write(v.get_text() if v else '')
        sys.exit(0)
sys.exit(3)
"""


def data_root(sandbox):
    return os.path.join(sandbox, "home", DATA_DIR)


def parse_store(text):
    """{key: value} from the item's text (a JSON object); a value that is JSON itself stays text, as the app wrote it."""
    d = json.loads(text)
    if not isinstance(d, dict):
        raise wd.ReadError("the secure-storage item is not a JSON object")
    return d


def _run_reader(env, timeout=30):
    r = subprocess.run([sys.executable, "-I", "-c", READER, ACCOUNT], env=env, capture_output=True, timeout=timeout)
    if r.returncode == 3:
        raise wd.ReadError("the keyring holds no %s item" % ACCOUNT)
    if r.returncode != 0:
        raise wd.ReadError("the keyring read failed (%d): %s" % (r.returncode, r.stderr.decode("utf-8", "replace")[-200:].strip()))
    return parse_store(r.stdout.decode("utf-8"))


def _live_env(sandbox):
    """The sandbox's own session environment when its dbus is still up, else None."""
    import sandbox as sb  # linux/sandbox.py, beside this file
    env = sb.read_env(sandbox)
    addr = env.get("DBUS_SESSION_BUS_ADDRESS", "")
    path = addr.split("=", 1)[1].split(",")[0] if addr.startswith("unix:path=") else ""
    if not path or not os.path.exists(path):
        return None
    out = dict(sb.base_env(sandbox))
    out.update({k: v for k, v in env.items() if k.startswith(("DBUS_", "XDG_RUNTIME_DIR"))})
    return out


def _copy_env(sandbox, scratch):
    """The throwaway recipe: copy the keyring files, run a fresh daemon on them unlocked with the sandbox's password."""
    pw = os.path.join(sandbox, "keyring.pw")
    if not os.path.exists(pw):
        raise wd.ReadError("no keyring.pw in the sandbox, the keyring cannot be unlocked")
    home = os.path.join(scratch, "home")
    rt = tempfile.mkdtemp(prefix="kr", dir=scratch)
    os.chmod(rt, 0o700)
    src = os.path.join(sandbox, "home", ".local", "share", "keyrings")
    dst = os.path.join(home, ".local", "share", "keyrings")
    if not os.path.isdir(src):
        raise wd.ReadError("no keyring folder in the sandbox")
    os.makedirs(os.path.dirname(dst), mode=0o700)
    shutil.copytree(src, dst)
    return {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "LANG": "C.UTF-8", "HOME": home,
            "XDG_DATA_HOME": os.path.join(home, ".local", "share"), "XDG_CONFIG_HOME": os.path.join(home, ".config"),
            "XDG_CACHE_HOME": os.path.join(home, ".cache"), "XDG_RUNTIME_DIR": rt}, pw


def read_store(sandbox, scratch=None):
    """The app's secure-storage keys from the sandbox's keyring -> dict. Raises wd.ReadError."""
    env = _live_env(sandbox)
    if env is not None:
        return _run_reader(env)
    base = scratch or os.environ.get("TMPDIR") or tempfile.gettempdir()
    tmp = tempfile.mkdtemp(prefix="walletdata-kr-", dir=base)
    os.chmod(tmp, 0o700)
    try:
        env, pw = _copy_env(sandbox, tmp)
        # a fresh session bus with its own keyring daemon, unlocked from the password file on stdin
        script = ("gnome-keyring-daemon --unlock --components=secrets < '%s' >/dev/null 2>&1; "
                  "exec '%s' -I -c \"$READER\" '%s'" % (pw, sys.executable, ACCOUNT))
        env = dict(env, READER=READER)
        r = subprocess.run(["dbus-run-session", "--", "sh", "-c", script], env=env, capture_output=True, timeout=60)
        if r.returncode == 3:
            raise wd.ReadError("the keyring holds no %s item" % ACCOUNT)
        if r.returncode != 0:
            raise wd.ReadError("the keyring read failed (%d): %s" % (r.returncode, r.stderr.decode("utf-8", "replace")[-200:].strip()))
        return parse_store(r.stdout.decode("utf-8"))
    finally:
        # our own throwaway folder (a copy of the keyring files), removed by its exact path
        shutil.rmtree(tmp, ignore_errors=True)


class SandboxFiles(wd.DirFiles):
    """DirFiles over <sandbox>/home/.epic_cash_desktop, with the keyring as the secure storage. The keyring is
    read on the first store() call and kept, since the digest is read several times."""

    def __init__(self, sandbox, scratch=None):
        super().__init__(data_root(sandbox))
        self.sandbox, self.scratch = sandbox, scratch
        self._cache = None

    def store(self):
        if self._cache is None:
            try:
                self._cache = read_store(self.sandbox, self.scratch)
                self.store_note = ""
            except (wd.ReadError, subprocess.SubprocessError, OSError, ValueError) as e:
                self._cache = {}
                self.store_note = "the sandbox keyring could not be read: %s" % e
        return dict(self._cache)

    def forget(self):
        """Read the keyring again on the next store() (the app may have written to it since)."""
        self._cache = None
