# SPDX-License-Identifier: Apache-2.0
"""The two listeners end to end with the release tools' client: /info is open, everything else
needs the client token, a request goes through upload, approval and download; the loopback
listener answers only to a loopback Host and its enrolment page closes once enrolled; with an
owner-only approval token file the client gets a request signed without the bot."""
import json
import os
import socket
import threading
import time
import unittest
import urllib.error
import urllib.request

from support import SignerCase
import btsign_client
from btsign import server

SUMS = b"b" * 64 + b"  epic-cash-mobile-26.11.0-arm64-v8a.apk\n"


def free_port():
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


class Http(SignerCase):
    def setUp(self):
        super().setUp()
        self.signer.cfg.update(port=free_port(), admin_port=free_port(), poll_seconds=0.2)
        self.servers = server.serve(self.signer)
        for _ in range(50):
            if len(self.servers) == 2:
                break
            time.sleep(0.05)
        tok = os.path.join(self.data, "..", f"{self._testMethodName}.token")
        with open(tok, "w") as f:
            f.write("c" * 40)
        os.chmod(tok, 0o600)
        self.settings = {"endpoint": f"http://127.0.0.1:{self.signer.cfg['port']}", "client_token": tok,
                         "approve_token": os.path.join(self.data, "..", f"{self._testMethodName}.none")}
        self.client = btsign_client.Client(self.settings, say=lambda *a: None)

    def tearDown(self):
        self.signer.stop.set()
        self.signer.wake.set()
        for s in self.servers:
            s.shutdown()
            s.server_close()

    def test_info_open_rest_needs_token(self):
        info = self.client.info()
        self.assertEqual(info["service"], "btsign")
        self.assertEqual([k["keyid"] for k in info["keys"] if k["held"]], ["940f8a1d8b2e098a"])
        req = urllib.request.Request(self.client.url + "/requests", data=b"{}", method="POST")
        with self.assertRaises(urllib.error.HTTPError) as e:
            urllib.request.urlopen(req, timeout=10)
        self.assertEqual(e.exception.code, 401)
        req.add_header("Authorization", "Bearer " + "x" * 40)
        with self.assertRaises(urllib.error.HTTPError) as e:
            urllib.request.urlopen(req, timeout=10)
        self.assertEqual(e.exception.code, 401)

    def test_sign_through_the_client(self):
        src = os.path.join(self.data, "..", f"{self._testMethodName}-SHA256SUMS")
        with open(src, "wb") as f:
            f.write(SUMS)

        def the owner():
            for _ in range(200):
                if self.bot.requests:
                    rid = next(iter(self.bot.requests))
                    self.bot.reply(rid, "123456" if self.code() != "123456" else "654321")  # one wrong
                    self.bot.reply(rid, self.code())
                    return
                time.sleep(0.05)

        threading.Thread(target=the owner, daemon=True).start()
        out = os.path.join(self.data, "..", f"{self._testMethodName}-out")
        st = self.client.sign("26.11.0", [{"op": "minisign", "file": src, "out": "SHA256SUMS.sig",
                                           "trusted_comment": "Epic Cash 26.11.0 SHA256SUMS"}], out)
        self.assertEqual(st["state"], "done")
        with open(os.path.join(out, "SHA256SUMS.sig")) as f:
            self.assertTrue(f.read().startswith("untrusted comment: "))
        self.assertEqual([r[1] for r in self.bot.results], ["wrong", "done"])

    def approve_file(self, token, mode=0o600):
        p = os.path.join(self.data, "..", f"{self._testMethodName}.approve")
        with open(p, "w") as f:
            f.write(token + "\n")
        os.chmod(p, mode)
        said = []
        return btsign_client.Client(dict(self.settings, approve_token=p), say=lambda *a: said.append(" ".join(a))), said

    def sums_job(self):
        src = os.path.join(self.data, "..", f"{self._testMethodName}-SHA256SUMS")
        with open(src, "wb") as f:
            f.write(SUMS)
        return [{"op": "minisign", "file": src, "out": "SHA256SUMS.sig",
                 "trusted_comment": "Epic Cash 26.11.0 SHA256SUMS"}], os.path.join(self.data, "..", f"{self._testMethodName}-out")

    def test_sign_with_the_approval_token(self):
        token = "k" * 48
        self.assertEqual(self.admin("/admin/secret", body={"name": "approve_token", "value": token})[0], 200)
        self.assertTrue(self.client.info()["auto_approve"])
        client, said = self.approve_file(token)
        jobs, out = self.sums_job()
        st = client.sign("26.11.0", jobs, out, run_id="26.11.0-run3")
        self.assertEqual(st["state"], "done")
        self.assertEqual(self.bot.requests, {})
        self.assertEqual(self.signer._meta(st["id"])["run"], "26.11.0-run3")
        self.assertEqual(self.signer._meta(st["id"])["approved_by"], "release-tool credential")
        self.assertTrue(any("approved by this machine's credential" in x for x in said), said)
        self.assertFalse(any(token in x for x in said))

    def test_wrong_approval_token_is_refused_and_masked(self):
        self.admin("/admin/secret", body={"name": "approve_token", "value": "k" * 48})
        client, said = self.approve_file("w" * 48)
        jobs, out = self.sums_job()
        with self.assertRaises(btsign_client.SignerError) as e:
            client.sign("26.11.0", jobs, out)
        self.assertEqual(e.exception.status, 403)
        self.assertNotIn("w" * 48, str(e.exception))
        self.assertEqual(len(self.signer.store.state()["failures"]), 1)
        self.assertEqual(self.signer.info()["active_request"], None)    # the client cancelled it

    def test_client_refuses_a_shared_approval_token_file(self):
        for mode in (0o640, 0o604, 0o620):
            client, _ = self.approve_file("k" * 48, mode)
            jobs, out = self.sums_job()
            with self.assertRaisesRegex(btsign_client.SignerError, "group/other"):
                client.sign("26.11.0", jobs, out)
        self.assertEqual(self.signer.info()["active_request"], None)     # refused before any request

    def test_check_compares_with_the_repo(self):
        # The test signer holds btlabs-public's TEST key, so against the real repo keyring it fails.
        problems = self.client.check()
        self.assertTrue(any("rank-1" in p or "lacks" in p for p in problems), problems)

    def admin(self, path, host="127.0.0.1", body=None):
        url = f"http://127.0.0.1:{self.signer.cfg['admin_port']}{path}"
        req = urllib.request.Request(url, data=None if body is None else json.dumps(body).encode(),
                                     method="GET" if body is None else "POST", headers={"Host": host})
        try:
            with urllib.request.urlopen(req, timeout=10) as r:
                return r.status, r.read().decode()
        except urllib.error.HTTPError as e:
            return e.code, e.read().decode()

    def test_loopback_listener(self):
        self.assertEqual(self.admin("/admin/status", host="evil.example")[0], 403)
        code, page = self.admin("/enrol")
        self.assertEqual(code, 200)
        self.assertIn("Already enrolled", page)
        self.assertEqual(self.admin("/admin/import", body={"bundle": "", "bundle_key": "x" * 43})[0], 409)
        self.assertEqual(self.admin("/admin/secret", body={"name": "bundle_key", "value": "x" * 40})[0], 400)

    def test_enrol_page_shows_a_secret_until_enrolled(self):
        s = self.signer.store.secrets()
        del s["totp"]
        self.signer.store.save_secrets(s)
        code, page = self.admin("/enrol")
        self.assertEqual(code, 200)
        self.assertIn(self.signer.enrol_secret()[:4], page)
        self.assertIn("name=csrf", page)


class Listen(unittest.TestCase):
    def test_tailnet_or_loopback_only(self):
        for bad in ("0.0.0.0", "192.168.0.57", "::", "example.org"):
            with self.assertRaises(ValueError):
                server.check_listen(bad)
        server.check_listen("10.90.15.122")
        with self.assertRaises(ValueError):
            server.check_listen("10.90.15.122", loopback_only=True)


if __name__ == "__main__":
    unittest.main()
