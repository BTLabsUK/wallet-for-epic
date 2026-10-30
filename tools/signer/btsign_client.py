#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""The release tools' side of the signer (stdlib only): find it, check it, send files, wait for
The owner's approval, fetch the signed files.

  btsign_client.py endpoint                     the endpoint from release-hosts.toml (exit 1: none)
  btsign_client.py check [--repo R] [--keyring K]   /info against the repo's keys and certificate
  btsign_client.py selftest [--repo R] [--keyring K]
  btsign_client.py sign --version V --out-dir D [--label L] JOB...
      JOB is op:key=value,... over local files, e.g.
        update-manifest:payload=build/update.payload.json,out=update.json,prev=pub.json,app_config=app-config.toml
        minisign:file=SHA256SUMS,out=SHA256SUMS.sig,trusted_comment=Epic Cash 26.11.0 SHA256SUMS
        apk:file=app-unsigned.apk,out=app.apk     aab:file=x.aab,out=x.aab
      Files are uploaded under their base names (two inputs with one base name are refused).

Settings: [host.signer] of release-hosts.toml ($REL_HOSTS, else ~/.config/btlabs/release-hosts.toml):
  endpoint = "http://<signer tailnet address>:8797"     unset: no signer (the old local key path)
  key_ids = ["3eb30c1e66220525"]                        the Ed25519 key ids it must hold
  android_cert_sha256 = "59e4…"                         the release certificate it must hold
  client_token = "~/.config/btlabs/signer-client.token" the client token (a file, chmod 600)
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
import re
import sys
import time
import tomllib
import urllib.error
import urllib.request

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
WAIT_SECONDS = 35 * 60


class SignerError(Exception):
    pass


def hosts_file() -> str:
    return os.path.expanduser(os.environ.get("REL_HOSTS", "~/.config/btlabs/release-hosts.toml"))


def signer_settings(path: str | None = None) -> dict:
    p = path or hosts_file()
    try:
        with open(p, "rb") as f:
            return tomllib.load(f).get("host", {}).get("signer", {})
    except FileNotFoundError:
        return {}


def endpoint(settings: dict | None = None) -> str:
    return ((settings if settings is not None else signer_settings()).get("endpoint") or "").strip()


def _text(path: str) -> str:
    with open(path, encoding="utf-8") as f:
        return f.read()


def sha256_file(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def repo_keyring(repo: str = REPO, keyring: str | None = None) -> dict:
    """The keys installed apps trust: lib/src/btlabs_keys.dart, which must equal the keyring file."""
    app = _text(os.path.join(repo, "app/lib/src/btlabs_keys.dart")).split("'''")[1]
    ring = json.loads(app)
    if keyring:
        with open(os.path.expanduser(keyring), encoding="utf-8") as f:
            if json.load(f) != ring:
                raise SignerError(f"app/lib/src/btlabs_keys.dart and {keyring} hold different keys")
    return ring


def repo_cert(repo: str = REPO) -> str:
    """G3's release certificate (tools/releases/build.py ANDROID_CERT_SHA256)."""
    text = _text(os.path.join(repo, "tools/releases/build.py"))
    m = re.search(r"^ANDROID_CERT_SHA256 = '([0-9a-f]{64})'", text, re.M)
    if not m:
        raise SignerError("no ANDROID_CERT_SHA256 in tools/releases/build.py")
    return m.group(1)


class Client:
    def __init__(self, settings: dict | None = None, say=None):
        self.s = settings if settings is not None else signer_settings()
        self.url = endpoint(self.s).rstrip("/")
        if not self.url:
            raise SignerError("no [host.signer] endpoint in " + hosts_file())
        self.say = say or (lambda *a: print(*a, file=sys.stderr))

    def _token(self) -> str:
        p = os.path.expanduser(self.s.get("client_token", "~/.config/btlabs/signer-client.token"))
        try:
            st = os.stat(p)
            if st.st_mode & 0o077:
                raise SignerError(f"{p} is readable by group/other; chmod 600 it")
            return _text(p).strip()
        except FileNotFoundError:
            raise SignerError(f"no signer client token at {p}") from None

    def call(self, method: str, path: str, body=None, data: bytes | None = None, stream=None,
             length: int | None = None, timeout: float = 60, auth: bool = True, raw: bool = False):
        headers = {}
        if auth:
            headers["Authorization"] = f"Bearer {self._token()}"
        if body is not None:
            data = json.dumps(body).encode()
            headers["Content-Type"] = "application/json"
        if stream is not None:
            headers["Content-Length"] = str(length)
            headers["Content-Type"] = "application/octet-stream"
            data = stream
        req = urllib.request.Request(self.url + path, data=data, method=method, headers=headers)
        try:
            r = urllib.request.urlopen(req, timeout=timeout)
        except urllib.error.HTTPError as e:
            try:
                msg = json.loads(e.read()).get("error")
            except ValueError:
                msg = e.reason
            raise SignerError(f"signer: {method} {path.split('?')[0]} → {e.code}: {msg}") from None
        except (urllib.error.URLError, OSError) as e:
            raise SignerError(f"signer at {self.url} unreachable ({getattr(e, 'reason', e)})") from None
        if raw:
            return r
        with r:
            return json.loads(r.read() or b"{}")

    def info(self) -> dict:
        return self.call("GET", "/info", auth=False, timeout=20)

    def check(self, repo: str = REPO, keyring: str | None = None) -> list[str]:
        """Problems with the signer's /info, none when it holds exactly what the apps trust: the
        rank-1 key of the shipped keyring (and the keyring itself), and G3's certificate."""
        info = self.info()
        problems = []
        ring = repo_keyring(repo, keyring)
        theirs = {k["keyid"]: k for k in info.get("keys", [])}
        ours = {k["keyid"]: k for k in ring["keys"]}
        for kid, k in ours.items():
            t = theirs.get(kid)
            if not t or t.get("public_key") != k["public_key"] or t.get("rank") != k["rank"]:
                problems.append(f"the signer's keyring lacks or differs on {k['label']} ({kid})")
        for kid in theirs:
            if kid not in ours:
                problems.append(f"the signer knows a key {kid} the apps do not ship")
        held = sorted(kid for kid, k in theirs.items() if k.get("held"))
        rank1 = [k["keyid"] for k in ring["keys"] if k["rank"] == min(x["rank"] for x in ring["keys"])]
        if held != rank1:
            problems.append(f"the signer holds keys {held}, not the rank-1 key {rank1}")
        want_ids = sorted(self.s.get("key_ids") or [])
        if want_ids and want_ids != held:
            problems.append(f"release-hosts.toml key_ids {want_ids} differ from the signer's {held}")
        cert = repo_cert(repo)
        if info.get("android_cert_sha256") != cert:
            problems.append(f"the signer's Android certificate {info.get('android_cert_sha256')} is not G3's {cert}")
        want_cert = self.s.get("android_cert_sha256")
        if want_cert and want_cert != cert:
            problems.append(f"release-hosts.toml android_cert_sha256 differs from G3's {cert}")
        return problems

    def selftest(self, repo: str = REPO, keyring: str | None = None) -> dict:
        """Runs the signer's selftest and checks it here, against the repo's keys."""
        from cryptography.exceptions import InvalidSignature
        from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey
        r = self.call("POST", "/selftest", body={}, timeout=180)
        ring = {k["keyid"]: k for k in repo_keyring(repo, keyring)["keys"]}
        e = r["ed25519"]
        k = ring.get(e["keyid"])
        if not k or k["public_key"] != e["public_key"]:
            raise SignerError(f"selftest key {e['keyid']} is not in the shipped keyring")
        challenge = base64.b64decode(e["challenge"])
        if not challenge.startswith(b"btsign-selftest-v1\n") or len(challenge) == 64:
            raise SignerError("selftest challenge has no domain prefix")
        try:
            Ed25519PublicKey.from_public_bytes(base64.b64decode(k["public_key"])).verify(
                base64.b64decode(e["signature"]), challenge)
        except InvalidSignature:
            raise SignerError("selftest signature does not verify with the shipped key") from None
        cert = repo_cert(repo)
        if r["apk"]["cert_sha256"] != cert:
            raise SignerError(f"selftest APK certificate {r['apk']['cert_sha256']} is not G3's {cert}")
        if r["apk"]["package"] == "uk.btlabs.epiccash.mobile":
            raise SignerError("selftest signed our own package")
        return r

    def sign(self, version: str, jobs: list[dict], out_dir: str, label: str = "",
             wait: float = WAIT_SECONDS) -> dict:
        """jobs name local paths; outputs land in out_dir under their out names, checked against
        the signer's SHA-256. Blocks until the owner approved and the signer signed (or refused)."""
        files, paths = [], {}
        remote_jobs = []
        for j in jobs:
            rj = dict(j)
            for k in ("payload", "prev", "app_config", "file"):
                if rj.get(k):
                    p = os.path.abspath(rj[k])
                    name = os.path.basename(p)
                    if name in paths and paths[name] != p:
                        raise SignerError(f"two inputs are called {name}")
                    paths[name] = p
                    rj[k] = name
            remote_jobs.append(rj)
        for name, p in paths.items():
            files.append({"name": name, "size": os.path.getsize(p), "sha256": sha256_file(p)})
        req = self.call("POST", "/requests", body={"version": version, "label": label[:80],
                                                    "jobs": remote_jobs, "files": files})
        rid = req["id"]
        self.say(f"signer request {rid}: {len(remote_jobs)} job(s), {len(files)} file(s)")
        try:
            for f in files:
                with open(paths[f["name"]], "rb") as fh:
                    got = self.call("PUT", f"/requests/{rid}/in/{f['name']}", stream=fh, length=f["size"],
                                    timeout=1800)
                if got["sha256"] != f["sha256"]:
                    raise SignerError(f"{f['name']}: the signer hashed {got['sha256']}")
            self.call("POST", f"/requests/{rid}/submit", body={})
            self.say(f"signer request {rid}: waiting for the owner's code in Telegram (@BTLABS_BOT)")
            deadline, st = time.time() + wait, None
            while time.time() < deadline:
                st = self.call("GET", f"/requests/{rid}", timeout=30)
                if st["state"] in ("done", "rejected", "expired", "failed", "cancelled"):
                    break
                time.sleep(5)
            if not st or st["state"] != "done":
                raise SignerError(f"signer request {rid}: {st['state'] if st else 'no answer'}"
                                  f"{' (' + st['note'] + ')' if st and st.get('note') else ''}")
        except BaseException:
            try:
                self.call("POST", f"/requests/{rid}/cancel", body={}, timeout=15)
            except SignerError:
                pass
            raise
        os.makedirs(out_dir, exist_ok=True)
        for name, meta in st["outputs"].items():
            dst = os.path.join(out_dir, name)
            tmp = dst + ".btsign-part"
            with self.call("GET", f"/requests/{rid}/out/{name}", timeout=1800, raw=True) as r, open(tmp, "wb") as f:
                while chunk := r.read(1 << 20):
                    f.write(chunk)
            if sha256_file(tmp) != meta["sha256"]:
                os.unlink(tmp)
                raise SignerError(f"{name}: download does not match the signer's SHA-256")
            os.replace(tmp, dst)
            self.say(f"  signed {name} {meta['sha256'][:16]}")
        return st


def parse_job(text: str) -> dict:
    op, _, rest = text.partition(":")
    job = {"op": op}
    # trusted_comment may hold commas: it is the last key when present.
    if "trusted_comment=" in rest:
        rest, _, comment = rest.partition("trusted_comment=")
        job["trusted_comment"] = comment
        rest = rest.rstrip(",")
    for kv in filter(None, rest.split(",")):
        k, _, v = kv.partition("=")
        job[k] = v
    return job


def main(argv=None) -> int:
    p = argparse.ArgumentParser(prog="btsign_client", description=__doc__.splitlines()[0])
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("endpoint")
    for name in ("check", "selftest"):
        s = sub.add_parser(name)
        s.add_argument("--repo", default=REPO)
        s.add_argument("--keyring")
    s = sub.add_parser("sign")
    s.add_argument("--version", required=True)
    s.add_argument("--out-dir", required=True)
    s.add_argument("--label", default="")
    s.add_argument("jobs", nargs="+")
    a = p.parse_args(argv)
    try:
        if a.cmd == "endpoint":
            e = endpoint()
            if not e:
                return 1
            print(e)
            return 0
        c = Client()
        if a.cmd == "check":
            problems = c.check(a.repo, a.keyring)
            for x in problems:
                print("FAIL", x)
            if not problems:
                print(f"ok: {c.url} holds the shipped rank-1 key and G3's certificate")
            return 1 if problems else 0
        if a.cmd == "selftest":
            r = c.selftest(a.repo, a.keyring)
            print(f"ok: Ed25519 {r['ed25519']['keyid']} signs a challenge the shipped key verifies; "
                  f"the selftest APK ({r['apk']['package']}) carries {r['apk']['cert_sha256']} "
                  f"with schemes {r['apk']['schemes']}")
            return 0
        c.sign(a.version, [parse_job(j) for j in a.jobs], a.out_dir, a.label)
        return 0
    except SignerError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
