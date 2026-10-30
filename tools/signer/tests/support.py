# SPDX-License-Identifier: Apache-2.0
"""Shared fixtures: a signer in a temp folder with btlabs-public's TEST keys (never the release
keys), a test Android keystore made with keytool, and a fake bot that plays the owner."""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
SIGNER = os.path.dirname(HERE)
REPO = os.path.dirname(os.path.dirname(SIGNER))
sys.path.insert(0, SIGNER)

from btsign import crypto, ops, server  # noqa: E402

BP = os.path.expanduser(os.environ.get("BTLABS_PUBLIC", "~/code/btlabs-public"))
TEST_KEY = os.path.join(BP, "testdata/keys/test-a.key")
TEST_PUB = os.path.join(BP, "testdata/keys/test-a.pub.json")


def sdk_build_tools():
    sdk = os.environ.get("ANDROID_HOME") or os.path.expanduser("~/Android/Sdk")
    bt = os.path.join(sdk, "build-tools")
    if not os.path.isdir(bt):
        return None
    vers = sorted(os.listdir(bt), key=lambda v: [int(x) if x.isdigit() else 0 for x in v.replace("-", ".").split(".")])
    return os.path.join(bt, vers[-1]) if vers else None


def test_keyring() -> dict:
    with open(TEST_PUB, encoding="utf-8") as f:
        return {"keys": [json.load(f)]}


class FakeBot:
    """The bot's /signer routes in memory. `codes` are what the owner replied, in order."""

    def __init__(self):
        self.requests, self.results, self.notices, self.codes = {}, [], [], {}

    def call(self, method, path, body=None, timeout=20):
        if method == "POST" and path == "/signer/requests":
            self.requests[body["request_id"]] = body
            self.codes.setdefault(body["request_id"], [])
            return {"message_id": len(self.requests)}
        if method == "GET" and "/codes" in path:
            rid = path.split("/")[3]
            after = int(path.split("after=")[1])
            rows = [{"seq": i + 1, "code": c} for i, c in enumerate(self.codes.get(rid, []))]
            return {"codes": [r for r in rows if r["seq"] > after]}
        if method == "POST" and path.endswith("/result"):
            self.results.append((path.split("/")[3], body["status"], body["note"]))
            return {}
        if method == "POST" and path == "/signer/notice":
            self.notices.append(body)
            return {}
        raise AssertionError(f"unexpected bot call {method} {path}")

    def reply(self, rid, code):
        self.codes.setdefault(rid, []).append(code)


class Clock:
    def __init__(self, t=1_800_000_000.0):
        self.t = t

    def __call__(self):
        return self.t


def make_keystore(d: str) -> tuple[str, str]:
    """A throwaway PKCS12 keystore and its key.properties (keytool)."""
    p12, props = os.path.join(d, "test.p12"), os.path.join(d, "key.properties")
    subprocess.run(["keytool", "-genkeypair", "-keystore", p12, "-storetype", "PKCS12", "-storepass", "test-pass-1",
                    "-keypass", "test-pass-1", "-alias", "testkey", "-keyalg", "RSA", "-keysize", "2048",
                    "-validity", "3650", "-dname", "CN=btsign test"], check=True, capture_output=True)
    with open(props, "w") as f:
        f.write(f"storePassword=test-pass-1\nkeyPassword=test-pass-1\nkeyAlias=testkey\nstoreFile={p12}\n")
    return p12, props


class SignerCase(unittest.TestCase):
    """A fresh signer per test (file backend, TEST keys, enrolled with a known secret)."""
    keystore = None
    tmp_root = None

    @classmethod
    def setUpClass(cls):
        cls.tmp_root = tempfile.mkdtemp(prefix="btsign-test-")
        os.chmod(cls.tmp_root, 0o700)
        if shutil.which("keytool"):
            cls.keystore = make_keystore(cls.tmp_root)

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.tmp_root, ignore_errors=True)

    def setUp(self):
        self.data = tempfile.mkdtemp(prefix="data-", dir=self.tmp_root)
        os.chmod(self.data, 0o700)
        self.clock, self.bot = Clock(), FakeBot()
        bt = sdk_build_tools()
        cfg = dict(server.DEFAULTS, listen="127.0.0.1", port=0, admin_port=0, backend="file",
                   java=shutil.which("java") or "java",
                   apksigner_jar=os.path.join(bt, "lib", "apksigner.jar") if bt else "")
        if cfg["apksigner_jar"] and os.path.isfile(cfg["apksigner_jar"]):
            cfg["apksigner_jar_sha256"] = crypto.sha256_file(cfg["apksigner_jar"])
        self.signer = server.Signer(self.data, cfg, clock=self.clock, bot=self.bot)
        with open(TEST_KEY, encoding="ascii") as f:
            pem = f.read()
        secrets = {"ed25519": {"test-a": pem}, "keyring": test_keyring(), "bundle_key": crypto.new_bundle_key(),
                   "client_token": "c" * 40, "bot_token": "b" * 40}
        if self.keystore:
            secrets["android"] = ops.android_from_files(*self.keystore)
        self.signer.store.save_secrets(secrets)
        self.secret = crypto.new_totp_secret()
        self.signer.store.update_secrets(totp={"secret": self.secret, "enrolled_at": "2026-10-30T00:00:00Z"})

    def code(self, offset_steps=0):
        return crypto.hotp(self.secret, crypto.totp_step(self.clock.t) + offset_steps)

    def file(self, name, data: bytes) -> dict:
        p = os.path.join(self.data, "..", f"{self._testMethodName}-{name}")
        with open(p, "wb") as f:
            f.write(data)
        return {"name": name, "size": len(data), "sha256": crypto.sha256_file(p), "path": p}

    def request(self, jobs, files):
        """create + upload + submit; returns the request id."""
        r = self.signer.create({"version": "26.11.0", "jobs": jobs,
                                "files": [{k: f[k] for k in ("name", "size", "sha256")} for f in files]})
        for f in files:
            with open(f["path"], "rb") as fh:
                self.signer.upload(r["id"], f["name"], fh, f["size"])
        self.signer.submit(r["id"])
        return r["id"]
