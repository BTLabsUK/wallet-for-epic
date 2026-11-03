# SPDX-License-Identifier: Apache-2.0
"""A platform a release leaves out keeps its previous release: on the page (tools/releases/build.py
add), in the signed SHA256SUMS (server_sums.py live, write) and on the server (prune-downloads).
The inputs are release 26.10.26's run-4, which built Android, Windows and Linux only, over the
folder 26.10.25's run-15 left: its prune deleted both iOS files. Nothing here leaves 127.0.0.1;
ssh, rsync and sudo are shims that act on a temp folder."""
import functools
import hashlib
import importlib.util
import os
import shutil
import subprocess
import sys
import tempfile
import threading
import unittest
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

from support import REPO, builtins

BP = os.path.expanduser(os.environ.get("BTLABS_PUBLIC", "~/code/btlabs-public"))
SIGN = os.path.join(BP, "tool/btlabs_sign.py")
STEPS = os.path.join(REPO, "tools/rellib/steps")
RELEASE_FILES = os.path.join(REPO, "tools/release-files.py")

spec = importlib.util.spec_from_file_location("releases_build", os.path.join(REPO, "tools/releases/build.py"))
build = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build)

RUN_15 = [  # /tmp/epic-build/rel/26.10.25/run-15/files/SHA256SUMS: every platform
    "bt-wallet-26.10.25-android-arm64-v8a.apk", "bt-wallet-26.10.25-ios-unsigned.ipa",
    "bt-wallet-26.10.25-linux-x86_64.AppImage", "bt-wallet-26.10.25-macos.dmg",
    "bt-wallet-26.10.25-notor-android-arm64-v8a.apk", "bt-wallet-26.10.25-notor-ios-unsigned.ipa",
    "bt-wallet-26.10.25-notor-linux-x86_64.AppImage", "bt-wallet-26.10.25-notor-macos.dmg",
    "bt-wallet-26.10.25-notor-windows-x64-setup.exe", "bt-wallet-26.10.25-windows-x64-setup.exe",
]
RUN_4 = [  # /tmp/epic-build/rel/26.10.26/run-4/files/SHA256SUMS: Android, Windows, Linux
    "bt-wallet-26.10.26-android-arm64-v8a.apk", "bt-wallet-26.10.26-linux-x86_64.AppImage",
    "bt-wallet-26.10.26-notor-android-arm64-v8a.apk", "bt-wallet-26.10.26-notor-linux-x86_64.AppImage",
    "bt-wallet-26.10.26-notor-windows-x64-setup.exe", "bt-wallet-26.10.26-windows-x64-setup.exe",
]
CARRIED = [  # what 26.10.26 must leave of 26.10.25: macOS and iOS, both variants
    "bt-wallet-26.10.25-ios-unsigned.ipa", "bt-wallet-26.10.25-macos.dmg",
    "bt-wallet-26.10.25-notor-ios-unsigned.ipa", "bt-wallet-26.10.25-notor-macos.dmg",
]
EXTRA = ["provenance.json", "sbom.cdx.json"]


def body(name):
    return name.encode() * 50


def sha(name):
    return hashlib.sha256(body(name)).hexdigest()


def sums(names):
    return "".join(f"{sha(n)}  {n}\n" for n in sorted(names))


def write(path, text):
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


class KeepRuleTest(unittest.TestCase):
    def test_run_4_keeps_macos_and_ios_from_26_10_25(self):
        kept = build.keep("26.10.26", RUN_15 + RUN_4 + EXTRA)
        self.assertEqual(sorted(kept), sorted(RUN_4 + CARRIED))

    def test_the_next_release_keeps_each_platform_at_its_newest(self):
        # 26.10.27 builds Android only: Windows and Linux stay at 26.10.26, macOS and iOS at 26.10.25.
        new = ["bt-wallet-26.10.27-android-arm64-v8a.apk", "bt-wallet-26.10.27-notor-android-arm64-v8a.apk"]
        kept = build.keep("26.10.27", RUN_4 + CARRIED + new)
        self.assertEqual(sorted(kept), sorted(new + CARRIED + [n for n in RUN_4 if "android" not in n]))

    def test_a_variant_left_out_keeps_its_own_previous(self):
        kept = build.keep("26.10.26", RUN_15 + ["bt-wallet-26.10.26-macos.dmg"])
        self.assertIn("bt-wallet-26.10.26-macos.dmg", kept)
        self.assertNotIn("bt-wallet-26.10.25-macos.dmg", kept)
        self.assertIn("bt-wallet-26.10.25-notor-macos.dmg", kept)

    def test_the_cli_reads_names_on_stdin(self):
        p = subprocess.run([sys.executable, "-I", os.path.join(REPO, "tools/releases/build.py"), "keep", "26.10.26"],
                           input="\n".join(RUN_15 + RUN_4 + EXTRA), capture_output=True, text=True, check=True)
        self.assertEqual(p.stdout.split(), sorted(RUN_4 + CARRIED))

    def test_the_page_record_keeps_the_left_out_platforms(self):
        rec = lambda v, names: {"version": v, "date": "2026-11-0" + v[-1],
                                "files": [{"name": n, "size": 1, "sha256": sha(n)} for n in names]}
        out = build.merge([rec("26.10.25", RUN_15)], rec("26.10.26", RUN_4))
        self.assertEqual([r["version"] for r in out], ["26.10.26", "26.10.25"])
        self.assertEqual(sorted(f["name"] for f in out[1]["files"]), sorted(CARRIED))
        g = build.group(out)
        self.assertEqual({k: g[k]["primary"]["version"] for k in g if g[k]["primary"]},
                         {"windows": "26.10.26", "linux": "26.10.26", "android": "26.10.26",
                          "macos": "26.10.25", "ios": "26.10.25"})


class Quiet(SimpleHTTPRequestHandler):
    def log_message(self, *a):
        pass


@unittest.skipUnless(os.path.isfile(SIGN), "needs btlabs-public (BTLABS_PUBLIC)")
class SignedListingTest(unittest.TestCase):
    """manifests signs the folder as it stands once pruned: the run's files and the carried ones."""

    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix="keep-prev-")
        self.addCleanup(shutil.rmtree, self.tmp)
        self.key = os.path.join(self.tmp, "test-a.key")
        shutil.copy(os.path.join(BP, "testdata/keys/test-a.key"), self.key)
        os.chmod(self.key, 0o600)
        self.ring = os.path.join(self.tmp, "ring.json")
        subprocess.run([sys.executable, SIGN, "keyring", "--out", self.ring, os.path.join(BP, "testdata/keys/test-a.pub.json")],
                       check=True, capture_output=True)
        self.live = os.path.join(self.tmp, "live")
        os.makedirs(self.live)
        self.files = os.path.join(self.tmp, "files")
        os.makedirs(self.files)
        write(os.path.join(self.files, "SHA256SUMS"), sums(RUN_4 + EXTRA))
        self.m = os.path.join(self.tmp, "manifests")
        os.makedirs(self.m)
        srv = ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(Quiet, directory=self.live))
        threading.Thread(target=srv.serve_forever, daemon=True).start()
        self.addCleanup(srv.server_close)
        self.addCleanup(srv.shutdown)
        self.base = f"http://127.0.0.1:{srv.server_address[1]}/"

    def server_sums(self, *args, check=True):
        return subprocess.run([sys.executable, "-I", os.path.join(STEPS, "server_sums.py"), *args],
                              capture_output=True, text=True, check=check)

    def live_folder(self, names):
        write(os.path.join(self.live, "SHA256SUMS"), sums(names))
        self.server_sums("sign-key", os.path.join(self.live, "SHA256SUMS"), self.key, "26.10.25", self.ring, RELEASE_FILES)

    def test_run_4_signs_the_carried_files_with_their_live_hashes(self):
        self.live_folder(RUN_15 + EXTRA)
        out = os.path.join(self.m, "live-keep.sums")
        self.server_sums("live", self.base, self.files, "26.10.26", self.ring, RELEASE_FILES, out)
        with open(out) as f:
            self.assertEqual(f.read(), sums(CARRIED))
        self.server_sums("write", self.files, self.m, os.path.join(self.m, "SHA256SUMS"))
        with open(os.path.join(self.m, "SHA256SUMS")) as f:
            self.assertEqual(f.read(), sums(RUN_4 + CARRIED + EXTRA))

    def test_a_live_listing_with_a_bad_signature_is_refused(self):
        self.live_folder(RUN_15 + EXTRA)
        write(os.path.join(self.live, "SHA256SUMS"), sums(RUN_15))  # changed after signing
        p = self.server_sums("live", self.base, self.files, "26.10.26", self.ring, RELEASE_FILES,
                             os.path.join(self.m, "live-keep.sums"), check=False)
        self.assertNotEqual(p.returncode, 0)
        self.assertFalse(os.path.exists(os.path.join(self.m, "live-keep.sums")))

    def test_no_live_listing_carries_nothing(self):
        out = os.path.join(self.m, "live-keep.sums")
        self.server_sums("live", self.base, self.files, "26.10.26", self.ring, RELEASE_FILES, out)
        self.assertEqual(os.path.getsize(out), 0)


class PruneTest(unittest.TestCase):
    """prune-downloads over the folder run-4 published into: 26.10.25's Android, Windows and Linux
    files go (archived first), its macOS and iOS files stay, and the signed listing still holds."""

    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix="keep-prune-")
        self.addCleanup(shutil.rmtree, self.tmp)
        bin_ = os.path.join(self.tmp, "bin")
        os.makedirs(bin_)
        shims = {
            "ssh": '#!/usr/bin/env bash\nshift\nexec bash -c "$*"\n',
            "sudo": '#!/bin/sh\nexec "$@"\n',
            "rsync": '#!/usr/bin/env bash\na=()\nfor x in "$@"; do [[ $x == -* ]] || a+=("${x#fake:}"); done\n'
                     'exec cp -p "${a[@]}"\n',
        }
        for n, text in shims.items():
            write(os.path.join(bin_, n), text)
            os.chmod(os.path.join(bin_, n), 0o755)
        self.dest = os.path.join(self.tmp, "srv/downloads")
        os.makedirs(self.dest)
        for n in RUN_15 + RUN_4 + EXTRA:
            with open(os.path.join(self.dest, n), "wb") as f:
                f.write(body(n))
        signed = sums(RUN_4 + CARRIED + EXTRA)  # what manifests signed (SignedListingTest)
        write(os.path.join(self.dest, "SHA256SUMS"), signed)
        write(os.path.join(self.dest, "SHA256SUMS.sig"), "signature\n")
        self.run_dir = os.path.join(self.tmp, "rel/26.10.26/run-4")
        self.m = os.path.join(self.run_dir, "manifests")
        os.makedirs(self.m)
        write(os.path.join(self.m, "SHA256SUMS"), signed)
        self.prev = os.path.join(self.tmp, "rel/26.10.25/run-15")
        os.makedirs(self.prev)
        self.env = dict(os.environ, PATH=f"{bin_}:{os.environ['PATH']}", HOME=self.tmp, REL_RUN=self.run_dir,
                        REL_RUN_ID="test", REL_SRC=REPO)

    def test_out_of_scope_platforms_stay_and_the_listing_holds(self):
        p = subprocess.run([os.path.join(STEPS, "prune-downloads.sh"), "26.10.26", "fake", self.dest, self.prev, self.m],
                           env=self.env, capture_output=True, text=True)
        self.assertEqual(p.returncode, 0, p.stderr)
        gone = sorted(set(RUN_15) - set(CARRIED))
        self.assertEqual(sorted(os.listdir(self.dest)),
                         sorted(RUN_4 + CARRIED + EXTRA + ["SHA256SUMS", "SHA256SUMS.sig"]))
        self.assertEqual(sorted(os.listdir(os.path.join(self.prev, "../server-archive"))), gone)
        self.assertIn("the signed listing is the pruned folder's", p.stdout)
        with open(os.path.join(self.dest, "SHA256SUMS")) as f:
            self.assertEqual(f.read(), sums(RUN_4 + CARRIED + EXTRA))


class ScratchPruneTest(unittest.TestCase):
    """The TEST run's scratch target prunes by the same rule."""

    def test_scratch_keeps_the_left_out_platforms(self):
        tmp = tempfile.mkdtemp(prefix="keep-scratch-")
        self.addCleanup(shutil.rmtree, tmp)
        run = type("Run", (), {"path": tmp})()
        engine = type("Engine", (), {"run": run, "repo": REPO, "info": {"version": "26.10.26"}})()
        d = os.path.join(builtins.scratch_dir(engine), "downloads")
        os.makedirs(d)
        for n in RUN_15 + RUN_4 + EXTRA + ["SHA256SUMS"]:
            write(os.path.join(d, n), n)
        builtins.scratch_prune(engine, None, lambda *a: None)
        self.assertEqual(sorted(os.listdir(d)), sorted(RUN_4 + CARRIED + EXTRA + ["SHA256SUMS"]))


if __name__ == "__main__":
    unittest.main()
