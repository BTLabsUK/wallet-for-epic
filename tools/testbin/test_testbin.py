# SPDX-License-Identifier: Apache-2.0
"""Unit tests of the Mac kinds (macos, ios-sim) of testbin.py. Run: python3 -m unittest discover
-s tools/testbin -p 'test_testbin.py'. No ssh, no build: the Mac calls are replaced."""
import importlib.util
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

spec = importlib.util.spec_from_file_location("testbin", Path(__file__).with_name("testbin.py"))
tb = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tb)

SHA = "a" * 40
LEPIC = "b" * 40


class Done:
    def __init__(self, rc=0, out=""):
        self.returncode, self.stdout, self.stderr = rc, out, ""


class MacKinds(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.store = Path(self.tmp.name)
        p = mock.patch.object(tb, "STORE", self.store)
        p.start()
        self.addCleanup(p.stop)
        self.addCleanup(self.tmp.cleanup)
        self.entry = tb.entry_dir(SHA, LEPIC)

    def test_file_names_carry_the_commit(self):
        self.assertEqual(tb.artifact_path(self.entry, "tor", "macos").name,
                         "bt-wallet-aaaaaaaaaaaa-tor-macos.tar")
        self.assertEqual(tb.artifact_path(self.entry, "notor", "macos").name,
                         "bt-wallet-aaaaaaaaaaaa-notor-macos.tar")
        self.assertEqual(tb.artifact_path(self.entry, "notor", "ios-sim").name,
                         "bt-wallet-aaaaaaaaaaaa-notor-ios-simulator.zip")

    def test_linux_and_apk_paths_unchanged(self):
        self.assertEqual(tb.artifact_path(self.entry, "tor", "linux"), self.entry / "tor" / "linux")
        self.assertEqual(tb.artifact_path(self.entry, "tor", "apk"), self.entry / "tor" / "app-debug.apk")

    def test_ios_sim_is_notor_only(self):
        a = mock.Mock(what="ios-sim", variant="tor", commit=SHA, no_build=True)
        with mock.patch.object(tb, "resolve", return_value=(SHA, LEPIC, "")), \
                mock.patch.object(tb, "repo_of", return_value=Path(".")):
            with self.assertRaises(SystemExit) as e:
                tb.cmd_get(a)
        self.assertIn("without Tor only", str(e.exception))

    def test_get_default_variants(self):
        for what, variant in (("macos", "tor"), ("ios-sim", "notor")):
            a = mock.Mock(what=what, variant=None, commit=SHA, no_build=True)
            with mock.patch.object(tb, "resolve", return_value=(SHA, LEPIC, "")), \
                    mock.patch.object(tb, "repo_of", return_value=Path(".")):
                with self.assertRaises(SystemExit) as e:
                    tb.cmd_get(a)
            self.assertIn(f"({variant})", str(e.exception))

    def test_build_mac_stores_the_artifact_and_manifest(self):
        calls = []

        def fake_ssh(script, **kw):
            calls.append(script)
            if script.startswith("tar "):
                kw["stdout"].write(b"TARDATA")
            return Done(0, "/Users/bt/x/y-ios-simulator.zip\n")

        def fake_scp(cmd, **kw):
            Path(cmd[-1]).write_bytes(b"ZIPDATA")
            return Done(0)

        with mock.patch.object(tb, "mac_ssh", fake_ssh), mock.patch.object(tb, "sh", lambda c, **k: Done(0)), \
                mock.patch.object(tb, "push_lepic"), mock.patch.object(tb, "prune"), \
                mock.patch.object(tb, "free_gb", return_value=100), \
                mock.patch.object(tb, "git", return_value="subject"), \
                mock.patch.object(tb.subprocess, "run", fake_scp):
            tb.build_mac(SHA, LEPIC, "", "tor", "macos")
            tb.build_mac(SHA, LEPIC, "", "notor", "ios-sim")
        self.assertTrue(tb.have(self.entry, "tor", "macos"))
        self.assertTrue(tb.have(self.entry, "notor", "ios-sim"))
        self.assertEqual(tb.artifact_path(self.entry, "tor", "macos").read_bytes(), b"TARDATA")
        build = [c for c in calls if "build-apple.sh" in c]
        self.assertIn("macos", build[0])
        self.assertNotIn("WFE_TOR=0", build[0])
        self.assertIn("WFE_TOR=0 ", build[1])
        self.assertIn("ios-sim", build[1])
        for c in build:
            self.assertIn("lockf -k ~/.wfe-mac-build.lock", c)
            self.assertIn(f"--detach {SHA}", c)

    def test_a_failed_mac_build_stores_nothing(self):
        with mock.patch.object(tb, "mac_ssh", lambda s, **k: Done(3)), \
                mock.patch.object(tb, "sh", lambda c, **k: Done(0)), \
                mock.patch.object(tb, "push_lepic"), mock.patch.object(tb, "prune"), \
                mock.patch.object(tb, "free_gb", return_value=100):
            with self.assertRaises(SystemExit):
                tb.build_mac(SHA, LEPIC, "", "tor", "macos")
        self.assertFalse(tb.have(self.entry, "tor", "macos"))

    def test_refresh_without_the_option_builds_no_mac_kind(self):
        a = mock.Mock(with_mac=False)
        entry = self.entry
        with mock.patch.object(tb, "paused", return_value=None), mock.patch.object(tb, "rel_busy", return_value=[]), \
                mock.patch.object(tb, "resolve", return_value=(SHA, LEPIC, "")), \
                mock.patch.object(tb, "have", return_value=True), \
                mock.patch.object(tb, "latest_target", return_value=entry.resolve()), \
                mock.patch.object(tb, "build_mac") as bm:
            tb.cmd_refresh(a)
        bm.assert_not_called()


if __name__ == "__main__":
    unittest.main()
