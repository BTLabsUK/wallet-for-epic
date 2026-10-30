# SPDX-License-Identifier: Apache-2.0
"""Cleanup keeps exactly the current and the previous release; rollback re-signs the previous
release with a serial above the bad one, which an app that read the bad one accepts while the
old file put back is refused."""
import json
import os
import subprocess
import time
import unittest

from support import Base, REPO
from rellib import retention, rollback
from rellib.engine import Engine
from rellib.run import Run, write_json

BP = os.path.expanduser(os.environ.get("BTLABS_PUBLIC", "~/code/btlabs-public"))
TOOL = os.path.join(BP, "tool/btlabs_sign.py")


def fake_run(root, version, published_at=None, test=False, dry=False, files=()):
    path, run_id = Run.next_path(root, version)
    r = Run.create(root, version, {"version": version, "commit": "c" * 40, "scope": {}, "test": test, "dry": dry},
                   "", [])
    for name in files:
        with open(os.path.join(r.files, name), "w") as f:
            f.write(name)
    if published_at:
        pubs = retention.published(root)
        pubs.append({"version": version, "run_id": r.info["run_id"], "run": r.path, "at": published_at, "tag": f"v{version}"})
        write_json(os.path.join(root, "published.json"), pubs)
    time.sleep(1.01)  # creation order is by second
    return r


class RetentionTest(Base):
    def test_keeps_exactly_current_and_previous(self):
        a = fake_run(self.root, "26.10.22", "1")
        b = fake_run(self.root, "26.10.23", "2")
        b_fail = fake_run(self.root, "26.10.24")          # a failed attempt
        c = fake_run(self.root, "26.10.24", "3")           # the current release
        t = fake_run(self.root, "26.10.24", test=True)     # a test run of the current version
        n1 = fake_run(self.root, "26.10.25")               # candidate, older run
        n2 = fake_run(self.root, "26.10.25", dry=True)     # candidate, newest run
        p = retention.plan(self.root)
        self.assertEqual(sorted(p["keep"]), sorted([b.path, c.path, n2.path]))
        self.assertEqual(sorted(p["remove"]), sorted([a.path, b_fail.path, t.path, n1.path]))
        res = retention.apply(self.root, REPO, lambda *x: None)
        self.assertEqual(sorted(res["removed"]), sorted([a.path, b_fail.path, t.path, n1.path]))
        for x in (b, c, n2):
            self.assertTrue(os.path.isdir(x.path))
        for x in (a, b_fail, t, n1):
            self.assertFalse(os.path.exists(x.path))
        self.assertFalse(os.path.exists(os.path.dirname(a.path)))  # empty version folder gone
        self.assertEqual([p["version"] for p in retention.published(self.root)], ["26.10.23", "26.10.24"])
        # A second cleanup changes nothing.
        self.assertEqual(retention.apply(self.root, REPO, lambda *x: None)["removed"], [])

    def test_after_a_rollback_the_older_version_is_current(self):
        a = fake_run(self.root, "26.10.23", "1")
        b = fake_run(self.root, "26.10.24", "2")
        rb = fake_run(self.root, "26.10.23", "3")  # rollback run, published last
        p = retention.plan(self.root)
        self.assertEqual(sorted(p["keep"]), sorted([rb.path, b.path]))
        self.assertEqual(p["remove"], [a.path])

    def test_nothing_published_keeps_the_newest(self):
        a = fake_run(self.root, "26.10.24")
        b = fake_run(self.root, "26.10.25")
        self.assertEqual(retention.plan(self.root)["keep"], [b.path])

    def test_test_runs_are_never_published(self):
        r = fake_run(self.root, "26.10.25", test=True)
        retention.mark_published(r)
        self.assertEqual(retention.published(self.root), [])
        self.assertIn("published_scratch", Run(r.path).info)


@unittest.skipUnless(os.path.isfile(TOOL), "btlabs-public is not checked out")
class RollbackTest(Base):
    def signed_release(self, version, serial):
        """A published run with test-signed manifests and their payloads."""
        r = fake_run(self.root, version, files=[f"epic-cash-mobile-{version}-arm64-v8a.apk"])
        m = os.path.join(r.path, "manifests")
        ring = os.path.join(m, "ring.json")
        subprocess.run(["python3", TOOL, "keyring", "--out", ring, os.path.join(BP, "testdata/keys/test-a.pub.json")], check=True,
                       capture_output=True)
        url = "https://examples.btlabs.uk/epic-cash-wallets/downloads/"
        apk = os.path.join(r.files, f"epic-cash-mobile-{version}-arm64-v8a.apk")
        import hashlib
        sha = hashlib.sha256(open(apk, "rb").read()).hexdigest()
        payload = {"schema": 1, "serial": serial, "issued_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(serial)),
                   "expires_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(serial + 182 * 86400)),
                   "packageName": "uk.btlabs.epiccash.mobile", "versionName": version,
                   "apks": [{"abi": "arm64-v8a", "versionCode": 1, "url": url + os.path.basename(apk), "sha256": sha,
                             "size": os.path.getsize(apk)}]}
        import copy
        cfg = os.path.join(REPO, "app/assets/config/app-config.toml")
        v2 = copy.deepcopy(payload)
        v2["apks"][0]["url"] = "https://epiccash.btlabs.uk/releases/downloads/" + os.path.basename(apk)
        for p, e, pl, extra in (("update.payload.json", "update.json", payload, []),
                                ("update-v2.payload.json", "update-v2.json", v2, ["--app-config", cfg])):
            write_json(os.path.join(m, p), pl)
            subprocess.run(["python3", TOOL, "sign", "--type", "update", "--key", os.path.join(BP, "testdata/keys/test-a.key"),
                            "--keyring", ring, "--payload", os.path.join(m, p), "--out", os.path.join(m, e)] + extra,
                           check=True, capture_output=True)
        pubs = retention.published(self.root)
        pubs.append({"version": version, "run_id": r.info["run_id"], "run": r.path, "at": str(serial), "tag": f"v{version}"})
        write_json(os.path.join(self.root, "published.json"), pubs)
        r.info["scope"] = {"publish": {"target": "scratch", "manifests": True, "notes": ""},
                           "platforms": {"android": True, "linux": False, "windows": False, "macos": False, "ios": False},
                           "variants": {"tor": True, "notor": False}, "stores": {"play": False}, "skip": {},
                           "proof": {"waive": {}, "previous_dir": "", "previous_version": "", "previous_ref": ""},
                           "test": True, "version": version}
        r.save_info()
        return r, ring

    def verify(self, envelope, ring, state=None, write_state=None):
        cmd = ["python3", TOOL, "verify", "--type", "update", "--keyring", ring, "--envelope", envelope]
        if state:
            cmd += ["--state", state]
        if write_state:
            cmd += ["--write-state", write_state]
        p = subprocess.run(cmd, capture_output=True, text=True)
        return p.returncode, p.stdout + p.stderr

    def test_rollback_resigns_above_the_bad_serial(self):
        now = int(time.time())
        good, ring = self.signed_release("26.10.23", now - 7200)
        bad, _ = self.signed_release("26.10.24", now - 60)
        # An app that read the bad manifest keeps its serial.
        state = os.path.join(self.tmp, "app-state.json")
        rc, out = self.verify(os.path.join(bad.path, "manifests/update.json"), ring, write_state=state)
        self.assertEqual(rc, 0, out)
        # Putting the old file back is what 26.10.24's rollback did: the app refuses it.
        rc, out = self.verify(os.path.join(good.path, "manifests/update.json"), ring, state=state)
        self.assertNotEqual(rc, 0, "an older serial must be refused")
        # tools/rel rollback: a run of the good version, re-signed with a higher serial.
        b, g = rollback.choose(self.root)
        self.assertEqual((b["version"], g["version"]), ("26.10.24", "26.10.23"))
        run = rollback.make_run(self.root, self.pipeline, self.hosts, REPO, b, g, True,
                                {"host": {}, "path": {}, "node": "", "epicbox": ""})
        self.assertEqual([s.id for s in run.steps][:2], ["rollback-resign", "rollback-gate"])
        self.hosts["host"]["signer"] = {"btlabs_public": BP}
        eng = Engine(run, self.pipeline, self.hosts, REPO)
        st = eng.execute(run.step("rollback-resign"))
        self.assertEqual(st["status"], "done", st.get("note"))
        self.assertGreater(st["serial"], now - 60)
        self.assertIn("Desktops already on 26.10.24", st["note"])
        rc, out = self.verify(os.path.join(run.path, "manifests/update.json"), os.path.join(run.path, "manifests/test-keyring.json"),
                              state=state)
        self.assertEqual(rc, 0, f"the re-signed rollback must be accepted by an app that read the bad one: {out}")
        self.assertIn("26.10.23", out + json.dumps(json.load(open(os.path.join(run.path, "manifests/update.payload.json")))))
        # The gate in front of it fails closed like the publish gate.
        os.environ["REL_FAKE_GATE"] = "held"
        eng2 = self.engine(run)
        self.assertEqual(eng2.execute(run.step("rollback-gate"))["status"], "held")

    def test_rollback_needs_a_kept_previous_release(self):
        with self.assertRaises(ValueError):
            rollback.choose(self.root)
        self.signed_release("26.10.24", int(time.time()))
        with self.assertRaises(ValueError):
            rollback.choose(self.root)


if __name__ == "__main__":
    unittest.main()
