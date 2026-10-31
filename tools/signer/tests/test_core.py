# SPDX-License-Identifier: Apache-2.0
"""TOTP against RFC 6238's vectors, the bundle, and byte-for-byte parity with the tools the
signer replaces: btlabs_sign.py (update manifests) and tools/gitlab-release.py (minisign)."""
import base64
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest

from support import BP, REPO, TEST_KEY, test_keyring
from btsign import crypto, ops

RFC_SECRET = base64.b32encode(b"12345678901234567890").decode()


class Totp(unittest.TestCase):
    def test_rfc6238_sha1_vectors(self):
        # RFC 6238 appendix B (SHA-1), last 6 of the 8 digits.
        for t, code8 in ((59, "94287082"), (1111111109, "07081804"), (1111111111, "14050471"),
                         (1234567890, "89005924"), (2000000000, "69279037"), (20000000000, "65353130")):
            self.assertEqual(crypto.hotp(RFC_SECRET, t // 30, digits=8), code8)
            self.assertEqual(crypto.totp_now(RFC_SECRET, t), code8[-6:])

    def test_window_is_one_step(self):
        t = 1_800_000_000
        step = crypto.totp_step(t)
        for off in (-1, 0, 1):
            self.assertEqual(crypto.totp_match(RFC_SECRET, crypto.hotp(RFC_SECRET, step + off), t), step + off)
        for off in (-2, 2):
            self.assertIsNone(crypto.totp_match(RFC_SECRET, crypto.hotp(RFC_SECRET, step + off), t))
        for bad in ("", "12345", "1234567", "abcdef", None):
            self.assertIsNone(crypto.totp_match(RFC_SECRET, bad, t))

    def test_uri(self):
        uri = crypto.otpauth_uri("ABC", "the owner", "BT Labs signer")
        self.assertTrue(uri.startswith("otpauth://totp/BT%20Labs%20signer:the owner?secret=ABC&"))
        self.assertIn("algorithm=SHA1&digits=6&period=30", uri)


class Bundle(unittest.TestCase):
    def test_roundtrip_and_tamper(self):
        key = crypto.new_bundle_key()
        data = crypto.seal_bundle({"a": 1}, key)
        self.assertEqual(crypto.open_bundle(data, key), {"a": 1})
        with self.assertRaisesRegex(crypto.CryptoError, "wrong bundle key"):
            crypto.open_bundle(data, crypto.new_bundle_key())
        obj = json.loads(data)
        obj["n"] = 2 ** 14  # the header is bound to the ciphertext
        with self.assertRaises(crypto.CryptoError):
            crypto.open_bundle(json.dumps(obj).encode(), key)
        self.assertNotIn(b'"a"', data)

    def test_short_key_refused(self):
        with self.assertRaises(crypto.CryptoError):
            crypto.seal_bundle({}, "short")


@unittest.skipUnless(os.path.isfile(os.path.join(BP, "tool/btlabs_sign.py")), "btlabs-public checkout needed")
class VendoredBtlabsSign(unittest.TestCase):
    def test_pins_hold(self):
        ops._vendored = None
        self.assertIsNotNone(ops.vendored())
        for rel, want in ops.VENDOR_PINS.items():
            self.assertEqual(crypto.sha256_file(os.path.join(ops.VENDOR, rel)), want, rel)

    def test_vendored_copy_is_btlabs_public(self):
        for rel in ops.VENDOR_PINS:
            self.assertEqual(crypto.sha256_file(os.path.join(BP, rel)), ops.VENDOR_PINS[rel],
                             f"btlabs-public's {rel} moved on: re-vendor it and update the pins")

    def _payload(self):
        with open(os.path.join(BP, "samples/update.payload.json"), "rb") as f:
            return f.read()

    def test_update_manifest_bytes_identical_to_btlabs_sign(self):
        with tempfile.TemporaryDirectory() as d:
            ring = os.path.join(d, "ring.json")
            with open(ring, "w") as f:
                json.dump(test_keyring(), f)
            pay = os.path.join(d, "update.payload.json")
            with open(pay, "wb") as f:
                f.write(self._payload())
            now = json.loads(self._payload())["issued_at"]
            subprocess.run([sys.executable, os.path.join(BP, "tool/btlabs_sign.py"), "sign", "--type", "update",
                            "--key", TEST_KEY, "--keyring", ring, "--payload", pay, "--out",
                            os.path.join(d, "theirs.json"), "--now", now], check=True, capture_output=True)
            secrets = {"ed25519": {"test-a": open(TEST_KEY).read()}, "keyring": test_keyring()}
            from datetime import datetime, timezone
            when = datetime.strptime(now, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
            ops.run_job({"op": "update-manifest", "payload": "update.payload.json", "out": "ours.json"},
                        d, d, secrets, None, now=when)
            self.assertEqual(open(os.path.join(d, "ours.json"), "rb").read(),
                             open(os.path.join(d, "theirs.json"), "rb").read())

    def test_update_manifest_refuses_lower_serial(self):
        with tempfile.TemporaryDirectory() as d:
            body = json.loads(self._payload())
            with open(os.path.join(d, "p.json"), "w") as f:
                json.dump(body, f)
            secrets = {"ed25519": {"test-a": open(TEST_KEY).read()}, "keyring": test_keyring()}
            from datetime import datetime, timezone
            when = datetime.strptime(body["issued_at"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
            ops.run_job({"op": "update-manifest", "payload": "p.json", "out": "prev.json"}, d, d, secrets, None, now=when)
            with self.assertRaisesRegex(ops.OpError, "not above the published serial"):
                ops.run_job({"op": "update-manifest", "payload": "p.json", "prev": "prev.json", "out": "x.json"},
                            d, d, secrets, None, now=when)


class Minisign(unittest.TestCase):
    def test_bytes_identical_to_gitlab_release(self):
        try:
            spec = importlib.util.spec_from_file_location("gitlab_release", os.path.join(REPO, "tools/gitlab-release.py"))
            gl = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(gl)
        except ImportError as e:
            self.skipTest(f"tools/gitlab-release.py needs {e.name}")
        key = crypto.load_ed25519_pem(open(TEST_KEY).read())
        data = b"0" * 64 + b"  epic-cash-mobile-26.11.0-arm64-v8a.apk\n"
        kid = crypto.keyid_of(crypto.raw_public(key))
        comment = "Epic Cash 26.11.0 SHA256SUMS, BT Labs key test-a"
        ours = crypto.minisign_sign(key, data, comment)
        self.assertEqual(ours, gl.minisign_sign(key, kid, data, comment))
        ring = {k["keyid"]: dict(k, raw=base64.b64decode(k["public_key"])) for k in test_keyring()["keys"]}
        self.assertEqual(gl.minisign_verify(ours, data, ring)["label"], "test-a")


class Properties(unittest.TestCase):
    def test_java_properties(self):
        p = ops.parse_properties("# c\nstorePassword=a\\=b c\nkeyAlias : x\n! also comment\nkeyPassword=\\\\q\n")
        self.assertEqual(p, {"storePassword": "a=b c", "keyAlias": "x", "keyPassword": "\\q"})


if __name__ == "__main__":
    unittest.main()
