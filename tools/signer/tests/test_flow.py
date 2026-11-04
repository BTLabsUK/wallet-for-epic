# SPDX-License-Identifier: Apache-2.0
"""Requests and approval: one at a time, hashes the signer's own, TOTP from the bot's reply,
three wrong codes reject, five failures lock for an hour, a used time step is refused, 30-minute
expiry, enrolment once; approval by the release tool's credential (only its SHA-256 kept, a wrong
token refused and counted toward the lock, every signature in the ledger with its run and
approver); and the Android operations with a throwaway keystore."""
import hashlib
import json
import os
import shutil
import unittest

from support import SignerCase, sdk_build_tools
from btsign import crypto, ops, server

SUMS = b"a" * 64 + b"  EpicCashDesktop-26.11.0-x86_64.AppImage\n"
MINISIGN = {"op": "minisign", "file": "SHA256SUMS", "out": "SHA256SUMS.sig",
            "trusted_comment": "Epic Cash 26.11.0 SHA256SUMS"}


class Approval(SignerCase):
    def sums(self):
        return self.file("SHA256SUMS", SUMS)

    def test_approved_request_is_signed_and_verifies(self):
        rid = self.request([MINISIGN], [self.sums()])
        body = self.bot.requests[rid]
        self.assertEqual(body["files"][0]["sha256"], crypto.sha256_file(self.sums()["path"]))
        self.assertTrue(any("EpicCashDesktop-26.11.0-x86_64.AppImage" in x for x in body["lines"]))
        self.bot.reply(rid, self.code())
        self.signer.poll_once()
        st = self.signer.status(rid)
        self.assertEqual(st["state"], "done")
        with open(self.signer.output(rid, "SHA256SUMS.sig"), encoding="utf-8") as f:
            sig = f.read()
        key = ops.update_key(self.signer.store.secrets())
        self.assertEqual(sig, crypto.minisign_sign(key, SUMS, MINISIGN["trusted_comment"]))
        self.assertIn("done", [r[1] for r in self.bot.results])
        self.assertIn(st["outputs"]["SHA256SUMS.sig"]["sha256"], self.signer.ledger())

    def test_upload_hash_is_the_signers(self):
        f = self.sums()
        r = self.signer.create({"version": "26.11.0", "jobs": [MINISIGN],
                                "files": [{"name": "SHA256SUMS", "size": f["size"], "sha256": "0" * 64}]})
        with open(f["path"], "rb") as fh, self.assertRaises(server.Refused) as e:
            self.signer.upload(r["id"], "SHA256SUMS", fh, f["size"])
        self.assertEqual(e.exception.status, 422)
        with self.assertRaises(server.Refused):
            self.signer.submit(r["id"])

    def test_one_request_at_a_time(self):
        self.request([MINISIGN], [self.sums()])
        with self.assertRaises(server.Refused) as e:
            self.request([MINISIGN], [self.sums()])
        self.assertEqual(e.exception.status, 409)

    def test_three_wrong_codes_reject(self):
        rid = self.request([MINISIGN], [self.sums()])
        for c in ("000000", "111111", "222222"):
            self.bot.reply(rid, c if c != self.code() else "333333")
        self.signer.poll_once()
        st = self.signer.status(rid)
        self.assertEqual(st["state"], "rejected")
        self.assertEqual(st["outputs"], {})
        self.assertEqual([r[1] for r in self.bot.results], ["wrong", "wrong", "rejected"])

    def test_five_failures_lock_for_an_hour(self):
        for _ in range(2):
            rid = self.request([MINISIGN], [self.sums()])
            for c in ("000001", "000002", "000003"):
                self.bot.reply(rid, c)
            self.signer.poll_once()
        # 6 failures recorded; the 5th locked it.
        self.assertTrue(self.signer.info()["locked_until"])
        with self.assertRaises(server.Refused) as e:
            self.request([MINISIGN], [self.sums()])
        self.assertEqual(e.exception.status, 423)
        self.clock.t += 3601
        rid = self.request([MINISIGN], [self.sums()])
        self.bot.reply(rid, self.code())
        self.signer.poll_once()
        self.assertEqual(self.signer.status(rid)["state"], "done")

    def test_used_time_step_is_refused(self):
        rid = self.request([MINISIGN], [self.sums()])
        code = self.code()
        self.bot.reply(rid, code)
        self.signer.poll_once()
        self.assertEqual(self.signer.status(rid)["state"], "done")
        rid2 = self.request([MINISIGN], [self.sums()])
        self.bot.reply(rid2, code)              # the same code, same 30 s step
        self.bot.reply(rid2, self.code(-1))     # an older step than the one used
        self.signer.poll_once()
        self.assertEqual(self.signer.status(rid2)["state"], "pending_approval")
        self.assertIn("already used", self.bot.results[-1][2])
        self.clock.t += 30
        self.bot.reply(rid2, self.code())
        self.signer.poll_once()
        self.assertEqual(self.signer.status(rid2)["state"], "done")

    def test_expires_after_30_minutes(self):
        rid = self.request([MINISIGN], [self.sums()])
        self.clock.t += 30 * 60 + 1
        self.bot.reply(rid, self.code())
        self.signer.poll_once()
        self.assertEqual(self.signer.status(rid)["state"], "expired")
        self.assertEqual(self.bot.results[-1][1], "expired")
        self.request([MINISIGN], [self.sums()])  # no longer blocks the next one

    def test_not_enrolled_refuses(self):
        s = self.signer.store.secrets()
        del s["totp"]
        self.signer.store.save_secrets(s)
        with self.assertRaises(server.Refused) as e:
            self.request([MINISIGN], [self.sums()])
        self.assertIn("not enrolled", str(e.exception))

    def test_bad_specs(self):
        f = self.sums()
        decl = [{k: f[k] for k in ("name", "size", "sha256")}]
        for jobs, why in (([{"op": "rm"}], "unknown op"),
                          ([dict(MINISIGN, file="other")], "not one of"),
                          ([dict(MINISIGN, out="../x")], "bad output"),
                          ([dict(MINISIGN, trusted_comment="a\nb")], "trusted_comment")):
            with self.assertRaisesRegex(server.Refused, why):
                self.signer.create({"version": "26.11.0", "jobs": jobs, "files": decl})
        with self.assertRaises(server.Refused):
            self.signer.create({"version": "26.11.0", "jobs": [MINISIGN],
                                "files": [dict(decl[0], name="../SHA256SUMS")]})

    def test_restart_while_signing_fails_the_request(self):
        rid = self.request([MINISIGN], [self.sums()])
        meta = self.signer._meta(rid)
        meta["state"] = "signing"
        self.signer._save(meta)
        again = server.Signer(self.data, self.signer.cfg, clock=self.clock, bot=self.bot)
        self.assertEqual(again.status(rid)["state"], "failed")


TOKEN = "t" * 20 + "0123456789abcdef"


class Credential(SignerCase):
    def setUp(self):
        super().setUp()
        self.signer.set_secret("approve_token", TOKEN)

    def sums(self):
        return self.file("SHA256SUMS", SUMS)

    def make(self, files, jobs=(MINISIGN,), run="26.11.0-run1", **extra):
        r = self.signer.create(dict({"version": "26.11.0", "jobs": list(jobs), "run": run,
                                     "files": [{k: f[k] for k in ("name", "size", "sha256")} for f in files]},
                                    **extra))
        for f in files:
            with open(f["path"], "rb") as fh:
                self.signer.upload(r["id"], f["name"], fh, f["size"])
        return r["id"]

    def ledger_rows(self):
        with open(os.path.join(self.data, "signed.jsonl"), encoding="utf-8") as f:
            return [json.loads(x) for x in f]

    def test_signs_without_the_bot(self):
        rid = self.make([self.sums()])
        self.assertTrue(self.signer.info()["auto_approve"])
        self.assertEqual(self.signer.submit(rid, TOKEN)["state"], "approved")
        with self.assertLogs("btsign", "INFO") as logs:
            self.signer.poll_once()
        st = self.signer.status(rid)
        self.assertEqual(st["state"], "done", st["note"])
        self.assertEqual(self.bot.requests, {})
        self.assertEqual(self.bot.results, [])
        sha = st["outputs"]["SHA256SUMS.sig"]["sha256"]
        self.assertIn(f"signed SHA256SUMS.sig sha256 {sha} request {rid} run 26.11.0-run1 "
                      "approved by release-tool credential", "\n".join(logs.output))
        row = self.ledger_rows()[-1]
        self.assertEqual((row["run"], row["approved_by"], row["request"], row["sha256"]),
                         ("26.11.0-run1", "release-tool credential", rid, sha))
        self.assertIn("at", row)

    def test_totp_row_says_totp(self):
        rid = self.make([self.sums()], run=None)
        self.signer.submit(rid)
        self.bot.reply(rid, self.code())
        self.signer.poll_once()
        self.assertEqual(self.signer.status(rid)["state"], "done")
        row = self.ledger_rows()[-1]
        self.assertEqual((row["run"], row["approved_by"]), (None, "TOTP"))

    def test_wrong_token_refused_and_counted(self):
        rid = self.make([self.sums()])
        with self.assertRaises(server.Refused) as e:
            self.signer.submit(rid, "x" * 40)
        self.assertEqual(e.exception.status, 403)
        self.assertEqual(len(self.signer.store.state()["failures"]), 1)
        self.assertEqual(self.signer.status(rid)["state"], "uploading")
        self.assertEqual(self.bot.requests, {})
        self.signer.submit(rid, TOKEN)                       # the right one still approves
        self.signer.poll_once()
        self.assertEqual(self.signer.status(rid)["state"], "done")

    def test_wrong_tokens_lock_like_wrong_codes(self):
        for _ in range(2):
            rid = self.make([self.sums()])
            for _ in range(3):
                with self.assertRaises(server.Refused):
                    self.signer.submit(rid, "y" * 40)
            self.assertEqual(self.signer.status(rid)["state"], "rejected")
        self.assertTrue(self.signer.info()["locked_until"])
        with self.assertRaises(server.Refused) as e:
            self.make([self.sums()])
        self.assertEqual(e.exception.status, 423)

    def test_token_is_stored_only_as_its_sha256(self):
        s = self.signer.store.secrets()
        self.assertEqual(s["approve_sha256"], hashlib.sha256(TOKEN.encode()).hexdigest())
        self.assertNotIn(TOKEN, json.dumps(s))
        for root, _, names in os.walk(self.data):
            for n in names:
                with open(os.path.join(root, n), "rb") as f:
                    self.assertNotIn(TOKEN.encode(), f.read(), n)
        with self.assertRaises(server.Refused):
            self.signer.set_secret("approve_token", "short")

    def test_no_totp_needed_with_the_credential(self):
        s = self.signer.store.secrets()
        del s["totp"]
        self.signer.store.save_secrets(s)
        rid = self.make([self.sums()])
        with self.assertRaises(server.Refused) as e:
            self.signer.submit(rid)                          # no header, no TOTP: nothing to ask
        self.assertEqual(e.exception.status, 409)
        self.signer.submit(rid, TOKEN)
        self.signer.poll_once()
        self.assertEqual(self.signer.status(rid)["state"], "done")

    def test_cancelled_before_signing_is_not_signed(self):
        rid = self.make([self.sums()])
        self.signer.submit(rid, TOKEN)
        self.signer.cancel(rid)
        self.signer.poll_once()
        st = self.signer.status(rid)
        self.assertEqual((st["state"], st["outputs"]), ("cancelled", {}))

    def test_bad_run(self):
        for run in ("", "a b", "x" * 61, 7):
            with self.assertRaisesRegex(server.Refused, "run"):
                self.make([self.sums()], run=run)

    def test_without_the_token_set_a_header_is_refused(self):
        s = self.signer.store.secrets()
        del s["approve_sha256"]
        self.signer.store.save_secrets(s)
        self.assertFalse(self.signer.info()["auto_approve"])
        rid = self.make([self.sums()])
        with self.assertRaises(server.Refused) as e:
            self.signer.submit(rid, TOKEN)
        self.assertEqual(e.exception.status, 403)

    @unittest.skipUnless(sdk_build_tools() and shutil.which("java") and shutil.which("keytool"),
                         "Android build-tools, java and keytool needed")
    def test_follow_up_on_a_credential_approval(self):
        apk = self.file("app-unsigned.apk", open(ops.SELFTEST_APK, "rb").read())
        rid = self.make([apk], jobs=[{"op": "apk", "file": "app-unsigned.apk", "out": "app.apk"}],
                        then=[{"op": "minisign", "out": "SHA256SUMS.sig"}])
        self.signer.submit(rid, TOKEN)
        self.signer.poll_once()
        st = self.signer.status(rid)
        self.assertEqual(st["state"], "continuing", st["note"])
        sums = self.file("SHA256SUMS", f"{st['outputs']['app.apk']['sha256']}  app.apk\n".encode())
        self.signer.follow(rid, {"jobs": [MINISIGN], "files": [{k: sums[k] for k in ("name", "size", "sha256")}]})
        with open(sums["path"], "rb") as fh:
            self.signer.upload(rid, "SHA256SUMS", fh, sums["size"])
        self.assertEqual(self.signer.submit(rid, TOKEN)["state"], "done")
        self.assertEqual(self.bot.requests, {})
        self.assertEqual([(r["name"], r["approved_by"], r["run"]) for r in self.ledger_rows()],
                         [("app.apk", "release-tool credential", "26.11.0-run1"),
                          ("SHA256SUMS.sig", "release-tool credential", "26.11.0-run1")])


class Enrolment(SignerCase):
    def test_once_only(self):
        s = self.signer.store.secrets()
        del s["totp"]
        self.signer.store.save_secrets(s)
        secret = self.signer.enrol_secret()
        self.assertEqual(self.signer.enrol_confirm("000000", "bad"), "csrf")
        wrong = "000000" if crypto.totp_now(secret, self.clock.t) != "000000" else "111111"
        self.assertEqual(self.signer.enrol_confirm(wrong, self.signer._enrol_csrf), "wrong")
        ok = crypto.totp_now(secret, self.clock.t)
        self.assertEqual(self.signer.enrol_confirm(ok, self.signer._enrol_csrf), "ok")
        self.assertEqual(self.signer.store.secrets()["totp"]["secret"], secret)
        self.assertEqual(self.bot.notices, [{"kind": "enrolled"}])
        self.assertEqual(self.signer.enrol_confirm(ok, self.signer._enrol_csrf), "enrolled")
        # The code that confirmed the enrolment cannot also approve a request.
        self.assertEqual(self.signer.check_code(ok), "reused")


class Bundles(SignerCase):
    def test_export_then_import_elsewhere(self):
        if not self.keystore:
            self.skipTest("keytool needed")
        rid = self.request([{"op": "export", "out": "bundle.json"}], [])
        self.bot.reply(rid, self.code())
        self.signer.poll_once()
        with open(self.signer.output(rid, "bundle.json"), "rb") as f:
            data = f.read()
        bk = self.signer.store.secrets()["bundle_key"]
        other = os.path.join(self.tmp_root, f"other-{self._testMethodName}")
        os.makedirs(other, mode=0o700)
        s2 = server.Signer(other, self.signer.cfg, clock=self.clock, bot=self.bot)
        with self.assertRaises(server.Refused):
            s2.import_bundle(data, "wrong-" + bk)
        info = s2.import_bundle(data, bk)
        self.assertEqual(info["keys"], self.signer.info()["keys"])
        self.assertEqual(info["android_cert_sha256"], self.signer.info()["android_cert_sha256"])
        self.assertTrue(info["enrolled"])
        with self.assertRaises(server.Refused) as e:
            s2.import_bundle(data, bk)
        self.assertEqual(e.exception.status, 409)
        self.assertNotIn("client_token", s2.store.secrets())


@unittest.skipUnless(sdk_build_tools() and shutil.which("java") and shutil.which("keytool"),
                     "Android build-tools, java and keytool needed")
class Android(SignerCase):
    def test_selftest(self):
        r = self.signer.selftest()
        self.assertEqual(r["apk"]["cert_sha256"], self.signer.store.secrets()["android"]["cert_sha256"])
        self.assertEqual(r["apk"]["schemes"], {"v1": False, "v2": True, "v3": False, "v4": False})
        self.assertEqual(r["apk"]["package"], "uk.btlabs.signer.selftest")
        self.assertTrue(r["ed25519"]["challenge"])
        self.assertEqual(os.listdir(self.signer.tools.tmp), [])   # nothing usable left behind
        with self.assertRaises(server.Refused):
            self.signer.selftest()                                  # rate limited

    def test_apk_and_aab(self):
        apk = self.file("app-unsigned.apk", open(ops.SELFTEST_APK, "rb").read())
        aab = self.file("bundle.aab", open(ops.SELFTEST_APK, "rb").read())  # any zip does for jarsigner
        rid = self.request([{"op": "apk", "file": "app-unsigned.apk", "out": "app.apk"},
                            {"op": "aab", "file": "bundle.aab", "out": "app.aab"}], [apk, aab])
        self.bot.reply(rid, self.code())
        self.signer.poll_once()
        st = self.signer.status(rid)
        self.assertEqual(st["state"], "done", st["note"])
        v = ops.verify_apk(self.signer.tools, self.signer.output(rid, "app.apk"), None)
        self.assertEqual(v["schemes"], {"v1": False, "v2": True, "v3": False, "v4": False})
        self.assertEqual(v["cert_sha256"], self.signer.store.secrets()["android"]["cert_sha256"])
        self.assertEqual([n for n in os.listdir(self.signer.tools.tmp)], [])

    def test_wrong_apksigner_pin_refuses(self):
        self.signer.tools.apksigner_sha256 = "0" * 64
        with self.assertRaises(server.Refused):
            self.signer.selftest()


if __name__ == "__main__":
    unittest.main()
