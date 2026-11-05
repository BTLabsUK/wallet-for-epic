# SPDX-License-Identifier: Apache-2.0
"""Step publish-downloads against a local folder as the server: ssh, rsync, sudo and curl are
shims, the update key is btlabs-public's test key. A file the server already holds with the
same bytes is not sent again; a missing or changed one is; SHA256SUMS is rewritten over the
folder and signed, and every release file is read back."""
import hashlib
import os
import shutil
import stat
import subprocess
import tempfile
import unittest

from support import REPO

BP = os.path.expanduser(os.environ.get("BTLABS_PUBLIC", "~/code/btlabs-public"))
SIGN = os.path.join(BP, "tool/btlabs_sign.py")
STEP = os.path.join(REPO, "tools/rellib/steps/publish-downloads.sh")

# ssh <host> <command>: the command runs here, HOME the fake server's home.
SSH = """#!/usr/bin/env bash
shift
cd "$FAKE_HOME" && HOME="$FAKE_HOME" bash -c "$*"
"""
# rsync -t <file>... <host>:<dir>/: copies into the fake home, logs each file sent.
RSYNC = """#!/usr/bin/env bash
args=("$@"); dest="${args[-1]#*:}"; unset 'args[-1]'
for a in "${args[@]}"; do
  [[ "$a" == -* ]] && continue
  if [[ "$dest" == /* ]]; then cp "$a" "$dest"; else cp "$a" "$FAKE_HOME/$dest"; fi
  basename "$a" >> "$FAKE_DIR/sent"
done
"""
# sudo: runs the command; install's owner and group are dropped (no root here).
SUDO = """#!/usr/bin/env bash
if [[ "$1" == install ]]; then
  out=(); skip=0
  for a in "$@"; do
    if (( skip )); then skip=0; continue; fi
    case "$a" in -o|-g) skip=1 ;; *) out+=("$a") ;; esac
  done
  exec "${out[@]}"
fi
exec "$@"
"""
# curl: any URL is a file of the fake downloads folder, by its last path part.
CURL = """#!/usr/bin/env bash
code=0; url=""
for a in "$@"; do
  case "$a" in *http_code*) code=1 ;; http*) url="$a" ;; esac
done
f="$FAKE_DEST/${url##*/}"
if (( code )); then [[ -f "$f" ]] && printf 200 || printf 404; exit 0; fi
[[ -f "$f" ]] || exit 22
cat "$f"
"""


@unittest.skipUnless(os.path.isfile(SIGN), "needs btlabs-public (its test keys)")
class PublishDownloadsTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix="pubdl-")
        bin_ = os.path.join(self.tmp, "bin")
        os.makedirs(bin_)
        for name, text in (("ssh", SSH), ("rsync", RSYNC), ("sudo", SUDO), ("curl", CURL)):
            path = os.path.join(bin_, name)
            with open(path, "w") as f:
                f.write(text)
            os.chmod(path, os.stat(path).st_mode | stat.S_IEXEC)
        self.home = os.path.join(self.tmp, "home")
        self.dest = os.path.join(self.tmp, "downloads")
        self.files = os.path.join(self.tmp, "files")
        self.run_dir = os.path.join(self.tmp, "run")
        for d in (self.home, self.dest, self.files, self.run_dir):
            os.makedirs(d)
        key = os.path.join(self.tmp, "test-a.key")
        shutil.copy(os.path.join(BP, "testdata/keys/test-a.key"), key)
        os.chmod(key, 0o600)
        bp = os.path.join(self.tmp, "bp")
        os.makedirs(os.path.join(bp, "keys"))
        subprocess.run(["python3", SIGN, "keyring", "--out", os.path.join(bp, "keys/btlabs-keyring.json"),
                        os.path.join(BP, "testdata/keys/test-a.pub.json")], check=True, capture_output=True)
        self.env = dict(os.environ, PATH=f"{bin_}:{os.environ['PATH']}", FAKE_DIR=self.tmp, FAKE_HOME=self.home,
                        FAKE_DEST=self.dest, REL_SRC=REPO, REL_RUN=self.run_dir, REL_RUN_ID="26.10.25-run1",
                        REL_VERSION="26.10.25", REL_MANIFESTS=os.path.join(self.tmp, "no-manifests"),
                        REL_SIGNER_SIGNING_KEY=key, REL_SIGNER_BTLABS_PUBLIC=bp)

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def write(self, folder, name, data):
        with open(os.path.join(folder, name), "wb") as f:
            f.write(data)

    def sums(self):
        names = sorted(n for n in os.listdir(self.files) if n != "SHA256SUMS")
        with open(os.path.join(self.files, "SHA256SUMS"), "w") as f:
            for n in names:
                with open(os.path.join(self.files, n), "rb") as g:
                    f.write(f"{hashlib.sha256(g.read()).hexdigest()}  {n}\n")

    def publish(self):
        sent = os.path.join(self.tmp, "sent")
        if os.path.exists(sent):
            os.remove(sent)
        p = subprocess.run(["bash", STEP, self.files, "web", self.dest], capture_output=True, text=True,
                           timeout=120, env=self.env)
        self.assertEqual(p.returncode, 0, p.stdout + p.stderr)
        with open(sent) if os.path.exists(sent) else open(os.devnull) as f:
            return sorted(set(f.read().split()) - {"SHA256SUMS", "SHA256SUMS.sig"}), p.stdout

    def test_only_missing_or_changed_files_are_sent(self):
        apk, dmg = "bt-wallet-26.10.25-android-arm64-v8a.apk", "bt-wallet-26.10.25-macos.dmg"
        self.write(self.files, apk, b"apk" * 100)
        self.write(self.files, "provenance.json", b'{"run": 1}')
        self.write(self.files, "sbom.cdx.json", b"{}")
        self.sums()
        sent, _ = self.publish()
        self.assertEqual(sent, [apk, "provenance.json", "sbom.cdx.json"])
        # A follow-up: one new file and a new provenance.json; the apk is on the server already.
        self.write(self.files, dmg, b"dmg" * 100)
        self.write(self.files, "provenance.json", b'{"run": 2}')
        self.sums()
        sent, out = self.publish()
        self.assertEqual(sent, [dmg, "provenance.json"])
        self.assertIn("4 files served with their checksums", out)
        with open(os.path.join(self.dest, "SHA256SUMS")) as f, open(os.path.join(self.files, "SHA256SUMS")) as g:
            self.assertEqual(f.read(), g.read())
        with open(os.path.join(self.dest, "provenance.json"), "rb") as f:
            self.assertEqual(f.read(), b'{"run": 2}')
        self.assertTrue(os.path.isfile(os.path.join(self.dest, "SHA256SUMS.sig")))
        # Nothing changed: nothing is sent, the listing is signed and read back as before.
        sent, out = self.publish()
        self.assertEqual(sent, [])
        self.assertIn("4 files served with their checksums", out)
        self.assertFalse(os.listdir(self.home))
