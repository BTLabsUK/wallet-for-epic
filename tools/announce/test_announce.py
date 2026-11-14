"""Tests for announce.py. Run: python3 -I -m unittest tools/announce/test_announce.py"""
import base64
import contextlib
import io
import json
import os
import struct
import sys
import tempfile
import unittest
import zlib
from datetime import timedelta
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import announce as A  # noqa: E402
from cryptography.hazmat.primitives import serialization  # noqa: E402
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey  # noqa: E402


def png(px=128, extra=0):
    def chunk(t, b):
        return struct.pack(">I", len(b)) + t + b + struct.pack(">I", zlib.crc32(t + b))
    ihdr = struct.pack(">IIBBBBB", px, px, 8, 0, 0, 0, 0)
    idat = zlib.compress(b"\x00" * (px + 1) * px)
    out = A.PNG_SIG + chunk(b"IHDR", ihdr) + chunk(b"IDAT", idat) + chunk(b"IEND", b"")
    return A.padded_png(out, len(out) + extra) if extra else out


def write_key(path, priv):
    pem = priv.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
                             serialization.NoEncryption())
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "wb") as f:
        f.write(pem)


class Base(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory(dir=os.environ.get("TMPDIR"))
        self.addCleanup(self._tmp.cleanup)
        self.d = Path(self._tmp.name)
        self.ka, self.kb = Ed25519PrivateKey.generate(), Ed25519PrivateKey.generate()
        write_key(self.d / A.KEY_NAME, self.ka)
        write_key(self.d / "b.key", self.kb)
        keys = []
        for rank, (label, k) in enumerate([("ann-a", self.ka), ("ann-b", self.kb)], 1):
            raw = A.public_raw(k)
            keys.append({"keyid": A.keyid_of(raw), "rank": rank, "public_key": A.b64e(raw),
                         "label": label})
        self.keyring = {"keys": keys}
        (self.d / A.KEYRING_NAME).write_text(json.dumps(self.keyring))
        self.now = A.now_utc()
        self.png_file = self.d / "i.png"
        self.png_file.write_bytes(png())

    def run_cli(self, *args):
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            rc = A.main(["--dir", str(self.d), *args])
        return rc, out.getvalue(), err.getvalue()

    def add(self, mid="m1", text="Hello", *extra):
        return self.run_cli("add", "--id", mid, "--text", text, *extra)

    def signed_env(self, messages, **kw):
        (self.d / A.SOURCE_NAME).write_text(json.dumps({"messages": messages}))
        return A.sign_feed(self.d, kw.get("now", self.now), kw.get("days", 30))


class AddRemoveList(Base):
    def test_add_list_remove(self):
        rc, out, _ = self.add("m1", "Hello", "--link-label", "Go", "--link-url", "https://a.example/x",
                              "--image", str(self.png_file))
        self.assertEqual(rc, 0)
        rc, out, _ = self.run_cli("list")
        self.assertIn("m1  [live]", out)
        self.assertIn("image: %d bytes, 128 px" % len(png()), out)
        self.assertEqual(self.run_cli("remove", "--id", "m1")[0], 0)
        self.assertIn("(no messages)", self.run_cli("list")[1])
        self.assertEqual(self.run_cli("remove", "--id", "m1")[0], 2)

    def test_duplicate_id_refused(self):
        self.add("m1")
        rc, _, err = self.add("m1", "Other")
        self.assertEqual(rc, 2)
        self.assertIn("already", err)

    def test_fifth_message_refused(self):
        for i in range(4):
            self.assertEqual(self.add("m%d" % i)[0], 0)
        self.assertEqual(self.add("m4")[0], 2)

    def test_ended_message_does_not_count(self):
        for i in range(3):
            self.add("m%d" % i)
        old = json.loads((self.d / A.SOURCE_NAME).read_text())
        old["messages"].append({"id": "old", "text": "x", "ends_at": "2020-01-01T00:00:00Z"})
        (self.d / A.SOURCE_NAME).write_text(json.dumps(old))
        self.assertEqual(self.add("m3")[0], 0)

    def test_scheduled_and_ends(self):
        self.add("later", "Hi", "--starts", "2099-01-01T00:00:00Z", "--days", "2")
        src = json.loads((self.d / A.SOURCE_NAME).read_text())["messages"][0]
        self.assertEqual(src["ends_at"], "2099-01-03T00:00:00Z")
        self.assertIn("[scheduled]", self.run_cli("list")[1])

    def test_field_refusals(self):
        long_label = "x" * 25
        cases = [
            ("Bad Id", "t", []),
            ("a", "", []),
            ("a", "x" * 141, []),
            ("a", "two\nlines", []),
            ("a", "zero​width", []),
            ("a", " padded", []),
            ("a", "t", ["--link-label", long_label, "--link-url", "https://a.example/"]),
            ("a", "t", ["--link-label", "L", "--link-url", "http://a.example/"]),
            ("a", "t", ["--link-label", "L", "--link-url", "https://A.example/"]),
            ("a", "t", ["--link-label", "L", "--link-url", "epic:has space"]),
            ("a", "t", ["--link-label", "L", "--link-url", "epic:" + "a" * 520]),
            ("a", "t", ["--link-label", "L"]),
            ("a", "t", ["--platforms", "tv"]),
            ("a", "t", ["--starts", "2026-13-01T00:00:00Z"]),
        ]
        for mid, text, extra in cases:
            with self.subTest(mid=mid, text=text, extra=extra):
                self.assertEqual(self.add(mid, text, *extra)[0], 2)
        self.assertEqual(self.add("ok", "t", "--link-label", "L", "--link-url", "epic:abc?x=1")[0], 0)

    def test_image_refusals(self):
        for name, data in [("notpng", b"hello" * 20), ("wide", png(40)[:16] + struct.pack(">II", 40, 41) + png(40)[24:]),
                           ("small", png(16)), ("huge", png(256)), ("fat", png(128, extra=9000))]:
            f = self.d / (name + ".png")
            f.write_bytes(data)
            with self.subTest(name=name):
                self.assertEqual(self.add("i" + name[:3], "t", "--image", str(f))[0], 2)


class SignVerify(Base):
    def msg(self, mid="m1", **kw):
        return dict({"id": mid, "text": "Hello"}, **kw)

    def test_round_trip(self):
        data = self.signed_env([self.msg(link={"label": "Go", "url": "https://a.example/"},
                                         image={"png": A.b64e(png())})])
        r = A.verify_envelope(data, self.keyring, self.now)
        self.assertEqual(r["outcome"], "accepted")
        p = r["payload"]
        self.assertEqual(p["serial"], int(self.now.timestamp()))
        self.assertEqual(p["issued_at"], A.fmt_ts(self.now))
        self.assertEqual(A.parse_ts(p["expires_at"]) - A.parse_ts(p["issued_at"]), timedelta(days=30))
        self.assertEqual(len(p["messages"]), 1)
        self.assertEqual((self.d / A.ENVELOPE_NAME).read_bytes(), data)

    def test_cli_sign_and_verify(self):
        self.add("m1")
        self.assertEqual(self.run_cli("sign")[0], 0)
        rc, out, _ = self.run_cli("verify", "--envelope", str(self.d / A.ENVELOPE_NAME))
        self.assertEqual(rc, 0)
        self.assertIn("accepted", out)
        self.assertIn("m1", out)

    def test_serial_must_grow(self):
        self.signed_env([self.msg()])
        with self.assertRaises(A.ToolError):
            self.signed_env([self.msg()])
        self.signed_env([self.msg()], now=self.now + timedelta(seconds=1))

    def test_ended_dropped(self):
        old = self.msg("old", ends_at=A.fmt_ts(self.now - timedelta(seconds=1)))
        data = self.signed_env([old, self.msg("new")])
        ids = [m["id"] for m in A.verify_envelope(data, self.keyring, self.now)["payload"]["messages"]]
        self.assertEqual(ids, ["new"])

    def test_empty_list_signs(self):
        data = self.signed_env([])
        self.assertEqual(A.verify_envelope(data, self.keyring, self.now)["payload"]["messages"], [])

    def test_sign_refusals(self):
        bad = [
            [self.msg(text="a\nb")],
            [self.msg(id="BAD")],
            [self.msg("a"), self.msg("a")],
            [self.msg(str(i)) for i in range(5)],
            [self.msg(link={"label": "L", "url": "http://x.example/"})],
            [self.msg(image={"png": A.b64e(png(128, extra=9000))})],
            [self.msg(image={"png": "!!"})],
            [self.msg(starts_at="2030-01-02T00:00:00Z", ends_at="2030-01-01T00:00:00Z")],
            [self.msg(platforms=["desktop", "tv"])],
        ]
        for i, msgs in enumerate(bad):
            with self.subTest(i=i), self.assertRaises(A.ToolError):
                self.signed_env(msgs)
        self.assertFalse((self.d / A.ENVELOPE_NAME).exists())

    def test_days_over_45_refused(self):
        with self.assertRaises(A.ToolError):
            self.signed_env([self.msg()], days=46)

    def test_wrong_key_refused(self):
        with self.assertRaises(A.ToolError):  # rank 2 key
            (self.d / A.SOURCE_NAME).write_text(json.dumps({"messages": []}))
            A.sign_feed(self.d, self.now, 30, keyfile=self.d / "b.key")

    def test_key_mode_checked(self):
        os.chmod(self.d / A.KEY_NAME, 0o644)
        with self.assertRaises(A.ToolError):
            self.signed_env([])

    def test_verify_failures(self):
        data = self.signed_env([self.msg()])
        env = json.loads(data)

        def reason(raw, now=None):
            return A.verify_envelope(raw, self.keyring, now or self.now)["reason"]

        self.assertEqual(reason(b"x" * 65537), "too_large")
        self.assertEqual(reason(b"not json"), "malformed")
        self.assertEqual(reason(json.dumps(dict(env, payload="@@@@")).encode()), "malformed")
        self.assertEqual(reason(json.dumps(dict(env, signatures=[])).encode()), "malformed")
        self.assertEqual(reason(json.dumps(dict(env, payloadType="x")).encode()), "wrong_type")
        self.assertEqual(reason(json.dumps(dict(env, signatures=[{"keyid": "0" * 16, "sig": env["signatures"][0]["sig"]}])).encode()), "unknown_key")
        body = bytearray(A.b64d(env["payload"]))
        body[body.index(b"Hello")] ^= 1
        self.assertEqual(reason(json.dumps(dict(env, payload=A.b64e(bytes(body)))).encode()), "bad_signature")
        self.assertEqual(reason(data, self.now + timedelta(days=31)), "expired")
        dup = data.decode().replace('"payloadType"', '"payloadType": "a", "payloadType"', 1)
        self.assertEqual(reason(dup.encode()), "malformed")

    def test_rollback(self):
        data = self.signed_env([self.msg()])
        r = A.verify_envelope(data, self.keyring, self.now)
        newer = self.signed_env([self.msg("m2")], now=self.now + timedelta(seconds=5))
        r2 = A.verify_envelope(newer, self.keyring, self.now, r["state"])
        self.assertEqual(r2["outcome"], "accepted")
        self.assertEqual(A.verify_envelope(data, self.keyring, self.now, r2["state"])["reason"], "rollback")

    def test_bad_payload_signed_is_rejected_by_verifier(self):
        payload = json.dumps({"schema": 1, "serial": 5, "issued_at": A.fmt_ts(self.now),
                              "expires_at": A.fmt_ts(self.now + timedelta(days=50)),
                              "messages": []}).encode()
        env = A.sign_envelope(payload, A.PAYLOAD_TYPE, [self.ka])
        self.assertEqual(A.verify_envelope(env, self.keyring, self.now)["reason"], "malformed")

    def test_envelope_cap(self):
        msgs = [self.msg(str(i), image={"png": A.b64e(png(128, extra=8192 - len(png())))}) for i in range(4)]
        data = self.signed_env(msgs)  # 4 x 8 KiB images: still under the cap
        self.assertLess(len(data), A.MAX_ENVELOPE_BYTES)

    def test_revoke(self):
        (self.d / A.SOURCE_NAME).write_text(json.dumps({"messages": []}))
        kid_b = self.keyring["keys"][1]["keyid"]
        data = A.sign_feed(self.d, self.now, 30, revoke=[kid_b])
        self.assertEqual(json.loads(A.b64d(json.loads(data)["payload"]))["revoked_keys"], [kid_b])

    def test_publish_targets(self):
        rc, _, err = self.run_cli("--target", "prod", "publish", "--target", "test")
        self.assertEqual(rc, 2)
        self.assertIn("differ", err)
        (self.d / A.SOURCE_NAME).write_text(json.dumps({"messages": []}))
        A.sign_feed(self.d, self.now - timedelta(seconds=5), 30)
        rc, _, err = self.run_cli("publish", "--target", "prod", "--site", str(self.d))
        self.assertEqual(rc, 2)
        self.assertIn("not the Pages repository", err)

    def test_target_picks_dir(self):
        a = A.build_parser().parse_args(["--target", "prod", "list"])
        self.assertEqual(A.target_dir(a), Path(os.path.expanduser(A.PROD_DIR)))
        a = A.build_parser().parse_args(["list"])
        self.assertEqual(A.target_dir(a), Path(os.path.expanduser(A.DEFAULT_DIR)))


class Vectors(Base):
    def test_vectors(self):
        self.signed_env([self.msg_img()])
        out = self.d / "fx"
        names = A.make_vectors(self.d, out, self.png_file, self.now)
        self.assertEqual(len(names), 5)
        ring = json.loads((out / "keyring.json").read_text())
        self.assertNotIn("private", json.dumps(ring))
        got = {n: A.verify_envelope((out / n).read_bytes(), ring, self.now)["reason"]
               for n in names if n.endswith("json") and n != "keyring.json"}
        self.assertIsNone(got["announcements.json"])
        self.assertEqual(got["bad-signature.json"], "bad_signature")
        self.assertEqual(got["wrong-type.json"], "wrong_type")
        self.assertEqual(got["oversized-image.json"], "malformed")
        big = json.loads(A.b64d(json.loads((out / "oversized-image.json").read_bytes())["payload"]))
        self.assertEqual(len(A.b64d(big["messages"][0]["image"]["png"])), 9000)

    def msg_img(self):
        return {"id": "m1", "text": "Hello", "image": {"png": A.b64e(png())}}


if __name__ == "__main__":
    unittest.main()
