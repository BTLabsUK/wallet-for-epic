# SPDX-License-Identifier: Apache-2.0
"""Requests and approval: one at a time, hashes the signer's own, TOTP from the bot's reply,
three wrong codes reject, five failures lock for an hour, a used time step is refused, 30-minute
expiry, enrolment once; and the Android operations with a throwaway keystore."""
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
