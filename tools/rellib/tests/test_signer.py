# SPDX-License-Identifier: Apache-2.0
"""tools/rel and the release signer (tools/signer): sign-android signs every Android file of the
run once and G3 takes exactly those bytes; without an endpoint it only checks the builds signed
themselves; G1 refuses a signer that holds other keys; the downloads' SHA256SUMS prediction."""
import json
import os
import subprocess
import sys

from support import Base
from rellib import signer
from rellib.engine import sha256_file
from rellib.graph import Step

CERT = "59e4c290f3922d8e7d3b189eb98e7002dc50754c52d612ea91e82386390ec0aa"


def tail(path):
    with open(path, "rb") as f:
        return f.read().endswith(b"signed")


STEPS = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "steps")


class FakeClient:
    """Signs by appending b"signed"; records every request; refuses when told to."""

    def __init__(self, refuse=None, problems=()):
        self.requests, self.refuse, self.problems = [], refuse, list(problems)

    def sign(self, version, jobs, out_dir, label="", then=None, expect=None, run_id=None):
        self.requests.append({"version": version, "jobs": jobs, "label": label, "then": then, "run": run_id})
        if self.refuse:
            raise RuntimeError(self.refuse)
        os.makedirs(out_dir, exist_ok=True)
        for j in jobs:
            with open(j["file"], "rb") as f, open(os.path.join(out_dir, j["out"]), "wb") as g:
                g.write(f.read() + b"signed")
        return {"state": "done"}

    def check(self, repo, keyring):
        return self.problems


class SignerTest(Base):
    def setUp(self):
        super().setUp()
        self.fake, self.log = FakeClient(), []
        self.saved = signer.client, signer.cert_of
        signer.client = lambda engine, say: self.fake
        signer.cert_of = lambda path, tools: CERT if tail(path) else None

    def tearDown(self):
        signer.client, signer.cert_of = self.saved
        super().tearDown()

    def built(self, endpoint="http://100.64.0.9:8797"):
        if endpoint:
            self.hosts["host"]["signer"] = {"endpoint": endpoint}
        run = self.make_run(only="android", sets=["publish.manifests=false"])
        eng = self.engine(run, relmsg=False)
        eng.drive([s.id for s in run.steps if s.base in ("scope", "build-android")])
        step = Step(id="sign-android", base="sign-android", kind="builtin", title="sign", host="local", lane="sign",
                    platforms=["android"])
        return run, eng, step

    def say(self, *a):
        self.log.append(" ".join(map(str, a)))

    def test_signs_every_android_file_in_one_request_and_g3_takes_those_bytes(self):
        run, eng, step = self.built()
        before = {n: sha256_file(os.path.join(run.files, n)) for n in os.listdir(run.files)}
        res = signer.sign_android(eng, step, self.say)
        self.assertEqual(res["status"], "done", res)
        self.assertEqual(len(self.fake.requests), 1)
        jobs = self.fake.requests[0]["jobs"]
        self.assertEqual(sorted(j["out"] for j in jobs), ["bt-wallet-26.10.25-android-arm64-v8a.apk",
                                                          "bt-wallet-26.10.25-notor-android-arm64-v8a.apk",
                                                          "x-notor.apk", "x.apk"])
        self.assertEqual({j["op"] for j in jobs}, {"apk"})
        signed = signer.read_signed(run)
        self.assertIn("emulator/x.apk", signed)  # the emulator APK the trust drivers install
        self.assertTrue(tail(os.path.join(run.extra, "emulator/x.apk")))
        for n, h in before.items():
            now = sha256_file(os.path.join(run.files, n))
            self.assertNotEqual(now, h)
            self.assertTrue(signer.accepted_change(run, n, h, now))
            self.assertFalse(signer.accepted_change(run, n, h, "0" * 64))  # other bytes: refused
        # The build step still holds the unsigned build it recorded.
        st = run.status("build-android-tor")
        self.assertEqual(st["outputs"]["bt-wallet-26.10.25-android-arm64-v8a.apk"]["sha256"],
                         before["bt-wallet-26.10.25-android-arm64-v8a.apk"])
        # Again (a resumed run): nothing is asked twice.
        res = signer.sign_android(eng, step, self.say)
        self.assertEqual(res["status"], "done", res)
        self.assertEqual(len(self.fake.requests), 1)

    def test_a_run_never_published_signs_the_files_in_hand_without_manifests(self):
        self.hosts["host"]["signer"] = {"endpoint": "http://100.64.0.9:8797"}
        run = self.make_run(only="android")
        eng = self.engine(run, relmsg=False)
        eng.drive(["scope", "build-android-tor"])
        step = Step(id="sign-android", base="sign-android", kind="builtin", title="sign", host="local", lane="sign",
                    platforms=["android"])
        res = signer.sign_android(eng, step, self.say)
        self.assertEqual(res["status"], "failed")  # a run that may publish needs every Android file
        self.assertIn("build-android-notor", res["note"])
        self.assertEqual(self.fake.requests, [])
        run.taint("trust-android-tor run with unmet needs: build-android-notor")
        res = signer.sign_android(eng, step, self.say)
        self.assertEqual(res["status"], "done", res)
        req, = self.fake.requests
        self.assertIsNone(req["then"])  # no manifests declared
        self.assertEqual(req["run"], run.info["run_id"])
        self.assertIn("never published", req["label"])
        self.assertEqual(sorted(j["out"] for j in req["jobs"]), ["bt-wallet-26.10.25-android-arm64-v8a.apk", "x.apk"])
        self.assertIn("not in this run", res["note"])

    def test_the_signer_credential_signs_without_waiting_for_tools_rel_sign(self):
        tok = os.path.join(self.tmp, "approve.token")
        self.hosts["host"]["signer"] = {"endpoint": "http://100.64.0.9:8797", "approve_token": tok}
        run = self.make_run(only="android", sets=["publish.manifests=false"])
        eng = self.engine(run, relmsg=False)
        eng.pipeline.sign = {"when": "on-demand"}
        self.assertFalse(signer.sign_now(eng))
        fd = os.open(tok, os.O_WRONLY | os.O_CREAT, 0o600)
        os.close(fd)
        self.assertTrue(signer.sign_now(eng))

    def test_a_file_changed_after_its_build_is_never_sent(self):
        run, eng, step = self.built()
        with open(os.path.join(run.files, "bt-wallet-26.10.25-android-arm64-v8a.apk"), "ab") as f:
            f.write(b"x")
        res = signer.sign_android(eng, step, self.say)
        self.assertEqual(res["status"], "failed")
        self.assertIn("changed since", res["note"])
        self.assertEqual(self.fake.requests, [])

    def test_a_refusal_leaves_the_unsigned_files_and_no_record(self):
        self.fake.refuse = "signer request r1: rejected (3 wrong codes)"
        run, eng, step = self.built()
        before = {n: sha256_file(os.path.join(run.files, n)) for n in os.listdir(run.files)}
        res = signer.sign_android(eng, step, self.say)
        self.assertEqual(res["status"], "failed")
        self.assertIn("rejected", res["note"])
        self.assertEqual(before, {n: sha256_file(os.path.join(run.files, n)) for n in os.listdir(run.files)})
        self.assertEqual(signer.read_signed(run), {})

    def test_without_an_endpoint_it_checks_the_builds_signed_themselves(self):
        run, eng, step = self.built(endpoint="")
        res = signer.sign_android(eng, step, self.say)
        self.assertEqual(res["status"], "failed")  # the fake builds are not signed
        self.assertIn("not signed by the release key", res["note"])
        signer.cert_of = lambda path, tools: CERT
        res = signer.sign_android(eng, step, self.say)
        self.assertEqual(res["status"], "done", res)
        self.assertEqual(self.fake.requests, [])

    def test_run_file_names_the_signer_and_goes_when_it_is_unset(self):
        run, eng, _ = self.built()
        signer.write_run_file(eng)
        p = os.path.join(run.path, "signer.json")
        with open(p) as f:
            d = json.load(f)
        self.assertEqual(d["endpoint"], "http://100.64.0.9:8797")
        self.assertTrue(d["client"].endswith("tools/signer/btsign_client.py") and os.path.isfile(d["client"]))
        self.assertNotIn("token", json.dumps(d))
        self.hosts["host"]["signer"] = {}
        signer.write_run_file(eng)
        self.assertFalse(os.path.exists(p))

    def test_preflight_refuses_a_signer_with_other_keys(self):
        run, eng, _ = self.built()
        bad, good = [], []
        self.fake.problems = ["the signer holds keys ['aaaa'], not the rank-1 key ['3eb30c1e66220525']"]
        signer.preflight_checks(eng, good.append, bad.append, "keyring.json")
        self.assertTrue(any("rank-1" in b for b in bad), bad)

        def unreachable(engine, say):
            raise OSError("signer at http://100.64.0.9:8797 unreachable")
        signer.client = unreachable
        bad = []
        signer.preflight_checks(eng, good.append, bad.append, "keyring.json")
        self.assertTrue(any("unreachable" in b for b in bad), bad)

    def test_server_sums_are_the_release_and_the_kept_desktop_files(self):
        files, m = os.path.join(self.tmp, "files"), os.path.join(self.tmp, "m")
        os.makedirs(files)
        os.makedirs(m)
        with open(os.path.join(files, "SHA256SUMS"), "w") as f:
            f.write(f"{'b' * 64}  bt-wallet-26.11.0-android-arm64-v8a.apk\n{'c' * 64}  provenance.json\n{'d' * 64}  sbom.cdx.json\n")
        keep = {"desktop": {"windows": {"url": "https://x/downloads/bt-wallet-26.10.30-windows-x64-setup.exe",
                                        "sha256": "a" * 64, "size": 5}}}
        with open(os.path.join(m, "desktop-keep.json"), "w") as f:
            json.dump(keep, f)
        out = os.path.join(m, "SHA256SUMS")
        tool = os.path.join(STEPS, "server_sums.py")
        subprocess.run([sys.executable, "-I", tool, "write", files, m, out], check=True, capture_output=True)
        with open(out) as f:
            lines = f.read().splitlines()
        self.assertEqual([x.split("  ")[1] for x in lines],
                         ["bt-wallet-26.10.30-windows-x64-setup.exe", "bt-wallet-26.11.0-android-arm64-v8a.apk",
                          "provenance.json", "sbom.cdx.json"])
        self.assertTrue(lines[0].startswith("a" * 64 + "  "))
        keep["desktop"]["windows"]["url"] = "https://x/downloads/provenance.json"  # one name, two hashes
        with open(os.path.join(m, "desktop-keep.json"), "w") as f:
            json.dump(keep, f)
        p = subprocess.run([sys.executable, "-I", tool, "write", files, m, out], capture_output=True, text=True)
        self.assertNotEqual(p.returncode, 0)
        self.assertIn("two hashes", p.stderr)


class CertOfTest(Base):
    """cert_of reads the certificate from apksigner's and keytool's real output."""

    def tool(self, name, text):
        path = os.path.join(self.tmp, name)
        with open(path, "w") as f:
            f.write("#!/bin/sh\ncat <<'EOF'\n%s\nEOF\n" % text)
        os.chmod(path, 0o755)
        return path

    def test_apksigner_signer_line(self):
        out = ("Signer #1 certificate DN: CN=BT Labs Epic Wallet, O=BT Labs\n"
               "Signer #1 certificate SHA-256 digest: %s\n"
               "Signer #1 certificate SHA-1 digest: 0123456789abcdef0123456789abcdef01234567" % CERT)
        tools = {"apksigner": self.tool("apksigner", out), "keytool": "keytool"}
        self.assertEqual(signer.cert_of("x.apk", tools), CERT)

    def test_keytool_colons(self):
        colons = ":".join(CERT[i:i + 2].upper() for i in range(0, len(CERT), 2))
        tools = {"apksigner": "apksigner", "keytool": self.tool("keytool", "\t SHA1: 01:23\n\t SHA256: %s" % colons)}
        self.assertEqual(signer.cert_of("x.aab", tools), CERT)

    def test_unsigned_is_none(self):
        tools = {"apksigner": self.tool("apksigner", "DOES NOT VERIFY"), "keytool": "keytool"}
        self.assertIsNone(signer.cert_of("x.apk", tools))
