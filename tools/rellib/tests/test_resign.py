# SPDX-License-Identifier: Apache-2.0
"""tools/rel resign: the live manifests signed again with only a new serial, issued_at and
expires_at, in one signer request, verified, published only while the live files are still the
current release; and the [manifest] validity and the live-expiry warning. Signed with the test
keys of app/test/fixtures/btlabs/."""
import base64
import copy
import hashlib
import json
import os
import shutil
import subprocess
import time
import unittest

from support import Base, REPO
from rellib import resign, retention, signer
from rellib.config import ConfigError
from rellib.resign import DATES, Resign, ResignError
from rellib.run import Run, write_json

BP = os.path.expanduser(os.environ.get("BTLABS_PUBLIC", "~/code/btlabs-public"))
TOOL = os.path.join(BP, "tool/btlabs_sign.py")
FIX = os.path.join(REPO, "app/test/fixtures/btlabs")
RING = os.path.join(FIX, "test-keyring.json")
CFG = os.path.join(REPO, "app/assets/config/app-config.toml")
OLD = "https://examples.btlabs.uk/epic-cash-wallets/downloads/"
NEW = "https://epiccash.btlabs.uk/releases/downloads/"


def private_key(name, folder):
    """btlabs_sign.py takes a key file only when it is private: a 0600 copy of the fixture."""
    p = os.path.join(folder, f"{name}.key")
    if not os.path.isfile(p):
        shutil.copyfile(os.path.join(FIX, f"{name}.key"), p)
        os.chmod(p, 0o600)
    return p


def sign(payload_path, out, key="test-a", app_config=False):
    cmd = ["python3", TOOL, "sign", "--type", "update", "--key", private_key(key, os.path.dirname(out)), "--keyring", RING,
           "--payload", payload_path, "--out", out]
    if app_config:
        cmd += ["--app-config", CFG]
    subprocess.run(cmd, check=True, capture_output=True)


def payload_of(path):
    return json.loads(base64.b64decode(json.load(open(path))["payload"]))


def verifies(path, v2):
    cmd = ["python3", TOOL, "verify", "--type", "update", "--keyring", RING, "--envelope", path]
    if v2:
        cmd += ["--app-config", CFG]
    return subprocess.run(cmd, capture_output=True).returncode == 0


class FakeSigner:
    """The release signer as tools/rel sees it: signs every update-manifest job with test-a,
    honouring prev; records each request. tamper changes a payload before signing."""

    def __init__(self, tamper=None):
        self.requests, self.tamper = [], tamper

    def sign(self, version, jobs, out_dir, label=""):
        self.requests.append({"version": version, "jobs": copy.deepcopy(jobs), "label": label})
        for j in jobs:
            assert j["op"] == "update-manifest" and j.get("prev"), j
            src = j["payload"]
            if self.tamper:
                pl = json.load(open(src))
                self.tamper(pl)
                src = os.path.join(out_dir, "tampered-" + j["out"])
                write_json(src, pl)
            cmd = ["python3", TOOL, "sign", "--type", "update", "--key", private_key("test-a", out_dir),
                   "--keyring", RING, "--payload", src, "--prev", j["prev"], "--out", os.path.join(out_dir, j["out"])]
            if j.get("app_config"):
                cmd += ["--app-config", j["app_config"]]
            subprocess.run(cmd, check=True, capture_output=True)
        return {"state": "done"}


@unittest.skipUnless(os.path.isfile(TOOL), "btlabs-public is not checked out")
class ResignTest(Base):
    def setUp(self):
        super().setUp()
        self.live = os.path.join(self.tmp, "live")
        os.makedirs(self.live)
        self.log = []
        self.fake = FakeSigner()
        self.saved = signer.client
        signer.client = lambda engine, say: self.fake
        self.serial = int(time.time()) - 86400 * 170
        self.release = self.published("26.10.24", self.serial)

    def tearDown(self):
        signer.client = self.saved
        super().tearDown()

    def published(self, version, serial):
        """A published run with its kept payloads, and the live folder holding them signed."""
        path, run_id = Run.next_path(self.root, version)
        r = Run.create(self.root, version, {"version": version, "commit": "c" * 40, "scope": {}}, "", [])
        m = os.path.join(r.path, "manifests")
        apk = lambda v: {"abi": "arm64-v8a", "versionCode": 2610240, "url": OLD + f"epic-cash-mobile-{version}{v}-arm64-v8a.apk",
                         "sha256": hashlib.sha256(v.encode()).hexdigest(), "size": 123456789}
        pl = {"schema": 1, "serial": serial, "issued_at": resign.iso(serial), "expires_at": resign.iso(serial + 182 * 86400),
              "packageName": "uk.btlabs.btwallet", "versionName": version, "apks": [apk("")],
              "notes": "Faster sync.\nCafé fixes.", "notor": {"apks": [apk("-notor")]}}
        v2 = json.loads(json.dumps(pl).replace(OLD, NEW))
        for pname, ename, p, v in (("update.payload.json", "update.json", pl, False),
                                   ("update-v2.payload.json", "update-v2.json", v2, True)):
            write_json(os.path.join(m, pname), p)
            sign(os.path.join(m, pname), os.path.join(m, ename), app_config=v)
            shutil.copyfile(os.path.join(m, ename), os.path.join(self.live, ename))
        pubs = retention.published(self.root)
        pubs.append({"version": version, "run_id": run_id, "run": r.path, "at": "x", "tag": f"v{version}"})
        write_json(os.path.join(self.root, "published.json"), pubs)
        return r

    def resigner(self, test=False):
        r = Resign(REPO, self.root, self.pipeline, self.hosts, say=self.log.append, test=test, live_dir=self.live)
        r.keyring = RING  # the fixtures' keyring stands in for the shipped one
        return r

    def live_bytes(self):
        return {n: open(os.path.join(self.live, n), "rb").read() for n in ("update.json", "update-v2.json")}

    def test_only_serial_and_expiry_change_in_one_signer_request(self):
        self.hosts["host"]["signer"] = {"endpoint": "http://100.64.0.9:8797"}
        self.pipeline.data["manifest"] = {"validity_days": 45}
        before = {n: payload_of(os.path.join(self.live, n)) for n in ("update.json", "update-v2.json")}
        res = self.resigner().run()
        self.assertEqual(len(self.fake.requests), 1, "one approval for both files")
        req = self.fake.requests[0]
        self.assertEqual([j["out"] for j in req["jobs"]], ["update.json", "update-v2.json"])
        self.assertEqual(req["version"], "26.10.24")
        self.assertIn("RE-SIGN", req["label"])
        for n, old in before.items():
            path = os.path.join(self.live, n)
            self.assertTrue(verifies(path, n == "update-v2.json"), n)
            new = payload_of(path)
            # The proof: drop the three date fields and the payloads are equal, field order included.
            self.assertEqual(list({k: v for k, v in new.items() if k not in DATES}.items()),
                             list({k: v for k, v in old.items() if k not in DATES}.items()), n)
            self.assertEqual(set(new) ^ set(old), set())
            self.assertGreater(new["serial"], old["serial"])
            self.assertEqual(new["serial"], res["serial"])
            self.assertEqual(new["issued_at"], resign.iso(new["serial"]))
            self.assertEqual(resign.parse_iso(new["expires_at"]) - new["serial"], 45 * 86400)
        rec = json.load(open(os.path.join(res["work"], "resign.json")))
        self.assertEqual((rec["status"], rec["old_serial"], rec["days"]), ("published", self.serial, 45))

    def test_the_default_validity_and_the_release_setting(self):
        # 182 without a [manifest] section; the release sets 45 (the owner, 2026-10-31).
        self.assertEqual(self.pipeline.manifest_days(), 182)
        with open(os.path.join(REPO, "release/pipeline.toml"), "rb") as f:
            import tomllib
            self.assertEqual(tomllib.load(f)["manifest"]["validity_days"], 45)
        res = self.resigner(test=True).run()
        new = payload_of(os.path.join(self.live, "update.json"))
        self.assertEqual(resign.parse_iso(new["expires_at"]) - res["serial"], 182 * 86400)

    def test_validity_outside_what_clients_accept_is_refused(self):
        for bad in (0, 401, "45"):
            self.pipeline.data["manifest"] = {"validity_days": bad}
            with self.assertRaises(ConfigError):
                self.pipeline.manifest_days()

    def test_no_signer_endpoint_no_resign(self):
        before = self.live_bytes()
        with self.assertRaisesRegex(ResignError, "no signer"):
            self.resigner().run()
        self.assertEqual(self.live_bytes(), before)

    def test_live_files_that_are_not_the_current_release_are_refused(self):
        pl = payload_of(os.path.join(self.live, "update-v2.json"))
        pl["notes"] = "something else"
        p = os.path.join(self.tmp, "other.payload.json")
        write_json(p, pl)
        sign(p, os.path.join(self.live, "update-v2.json"), app_config=True)
        before = self.live_bytes()
        with self.assertRaisesRegex(ResignError, "not the current release.*notes"):
            self.resigner(test=True).run()
        self.assertEqual(self.live_bytes(), before)

    def test_a_live_file_signed_by_an_unknown_key_is_refused(self):
        bad = os.path.join(BP, "testdata/keys")
        r = self.resigner(test=True)
        r.keyring = os.path.join(self.tmp, "ring-b-only.json")
        subprocess.run(["python3", TOOL, "keyring", "--out", r.keyring, os.path.join(bad, "test-b.pub.json")],
                       check=True, capture_output=True)
        with self.assertRaisesRegex(ResignError, "does not verify"):
            r.run()

    def test_a_live_change_during_the_resign_publishes_nothing(self):
        r = self.resigner(test=True)
        reads, real = [], r.read_live

        def read_live():
            got = real()
            reads.append(1)
            if len(reads) == 2:  # someone published while the signer waited for the code
                got = dict(got, **{"update.json": got["update.json"].replace(b"}", b"} ", 1)})
            return got

        r.read_live = read_live
        before = self.live_bytes()
        with self.assertRaisesRegex(ResignError, "changed while re-signing"):
            r.run()
        self.assertEqual(self.live_bytes(), before)

    def test_a_signer_that_changes_anything_else_is_caught(self):
        self.hosts["host"]["signer"] = {"endpoint": "http://100.64.0.9:8797"}
        self.fake.tamper = lambda pl: pl["apks"][0].update(sha256="0" * 64)
        before = self.live_bytes()
        with self.assertRaisesRegex(ResignError, "another payload"):
            self.resigner().run()
        self.assertEqual(self.live_bytes(), before)

    def test_dry_run_signs_nothing(self):
        before = self.live_bytes()
        res = self.resigner(test=True).run(dry=True)
        self.assertEqual(self.live_bytes(), before)
        self.assertGreater(res["serial"], self.serial)
        self.assertEqual(self.fake.requests, [])

    def test_check_only_dates(self):
        old = json.dumps({"schema": 1, "serial": 5, "issued_at": resign.iso(5), "expires_at": resign.iso(9), "x": 1})
        good = resign.resigned(old.encode(), 100, 45)
        self.assertEqual(resign.check_only_dates(old, good, 45), [])
        self.assertEqual(resign.check_only_dates(old, good, 46), [f"expires_at {resign.iso(100 + 45 * 86400)} is not 46 days after issued_at"])
        worse = json.loads(good)
        worse["x"] = 2
        self.assertEqual(resign.check_only_dates(old, json.dumps(worse), 45), ["x changed"])
        older = resign.resigned(old.encode(), 5, 45)
        self.assertIn("serial 5 is not above 5", resign.check_only_dates(old, older, 45))


class ExpiryWarningTest(unittest.TestCase):
    def fetcher(self, expires):
        def fetch(url):
            pl = {"serial": 1, "expires_at": resign.iso(expires)}
            return json.dumps({"payload": base64.b64encode(json.dumps(pl).encode()).decode()}).encode()
        return fetch

    def test_warns_within_warn_days_only(self):
        now = 1_800_000_000
        self.assertIsNone(resign.live_expiry_warning(REPO, 14, self.fetcher(now + 15 * 86400), now))
        w = resign.live_expiry_warning(REPO, 14, self.fetcher(now + 13 * 86400), now)
        self.assertIn("in 13.0 days", w)
        self.assertIn("tools/rel resign", w)
        self.assertIn("expired", resign.live_expiry_warning(REPO, 14, self.fetcher(now - 60), now))

    def test_an_unreadable_live_file_is_a_warning(self):
        def fetch(url):
            raise OSError("offline")
        self.assertIn("unreadable", resign.live_expiry_warning(REPO, 14, fetch, 0))


if __name__ == "__main__":
    unittest.main()
