#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""btsign: BT Labs' release signer (docs/RELEASING.md, "Signer").

  btsign.py serve   --data DIR [--config FILE]      run in the foreground (Linux, tests)
  btsign.py service --data DIR [--config FILE]      run under the Windows service manager
  btsign.py bundle-create --ed25519 KEY --keyring JSON --p12 P12 --properties KEY.PROPERTIES
                          --bundle-key-stdin --out BUNDLE
  btsign.py bundle-open   --bundle BUNDLE --bundle-key-stdin --out-dir DIR
                          (writes the key files back, byte for byte: for checking a bundle)
  btsign.py import        --bundle BUNDLE --bundle-key-stdin [--admin URL]
  btsign.py set-secret    {bot_token,client_token,approve_token} --stdin [--admin URL]
                          (approve_token: the signer keeps only its SHA-256)
  btsign.py status        [--admin URL]

import, set-secret and status talk to the running signer's loopback listener (default
http://127.0.0.1:8796), so the service account, not the caller, writes its store. Secrets are
read from stdin only, never from arguments, and never printed.
"""
from __future__ import annotations

import argparse
import base64
import json
import os
import sys
import threading
import urllib.error
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from btsign import crypto, ops  # noqa: E402

SERVICE_NAME = "btsign"


def _stdin_secret() -> str:
    value = sys.stdin.readline().strip()
    if not value:
        sys.exit("error: expected the secret on stdin")
    return value


def _write_new(path: str, data: bytes) -> None:
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "wb") as f:
        f.write(data)


def cmd_bundle_create(a) -> int:
    with open(a.ed25519, encoding="ascii") as f:
        pem = f.read()
    key = crypto.load_ed25519_pem(pem)
    with open(a.keyring, encoding="utf-8") as f:
        ring = json.load(f)
    kid = crypto.keyid_of(crypto.raw_public(key))
    loaded = ops.vendored().load_keyring(ring)
    if kid not in loaded:
        sys.exit(f"error: the key {kid} is not in {a.keyring}")
    android = ops.android_from_files(a.p12, a.properties)
    content = {"ed25519": {loaded[kid]["label"]: pem}, "keyring": ring, "android": android}
    ops.check_bundle_content(content)
    _write_new(a.out, crypto.seal_bundle(content, _stdin_secret()))
    print(f"wrote {a.out}: update key {kid}, Android certificate {android['cert_sha256']}")
    return 0


def cmd_bundle_open(a) -> int:
    with open(a.bundle, "rb") as f:
        content = crypto.open_bundle(f.read(), _stdin_secret())
    ops.check_bundle_content(content)
    os.makedirs(a.out_dir, mode=0o700, exist_ok=True)
    (label, pem), = content["ed25519"].items()
    _write_new(os.path.join(a.out_dir, f"{label}.key"), pem.encode("ascii"))
    andr = content["android"]
    _write_new(os.path.join(a.out_dir, "release.p12"), base64.b64decode(andr["p12_b64"]))
    if andr.get("properties_b64"):
        _write_new(os.path.join(a.out_dir, "key.properties"), base64.b64decode(andr["properties_b64"]))
    _write_new(os.path.join(a.out_dir, "keyring.json"),
               (json.dumps(content["keyring"], indent=2) + "\n").encode())
    print(f"opened into {a.out_dir}: {label}.key, release.p12, key.properties, keyring.json "
          f"(Android certificate {andr['cert_sha256']}); delete them when checked")
    return 0


def _admin(url: str, method: str, path: str, body: dict | None = None) -> dict:
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(url.rstrip("/") + path, data=data, method=method,
                                 headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        try:
            msg = json.loads(e.read()).get("error")
        except ValueError:
            msg = None
        sys.exit(f"error: the signer answered {e.code}: {msg or e.reason}")
    except urllib.error.URLError as e:
        sys.exit(f"error: the signer is not running at {url} ({e.reason})")


def cmd_import(a) -> int:
    with open(a.bundle, "rb") as f:
        bundle = base64.b64encode(f.read()).decode()
    info = _admin(a.admin, "POST", "/admin/import", {"bundle": bundle, "bundle_key": _stdin_secret()})
    print(json.dumps(info, indent=1))
    return 0


def cmd_set_secret(a) -> int:
    _admin(a.admin, "POST", "/admin/secret", {"name": a.name, "value": _stdin_secret()})
    print(f"{a.name} set")
    return 0


def cmd_status(a) -> int:
    print(json.dumps(_admin(a.admin, "GET", "/admin/status"), indent=1))
    return 0


def _signer(a):
    from btsign import server
    cfg_path = a.config or os.path.join(a.data, "btsign.toml")
    cfg = server.load_config(cfg_path)
    server.setup_logging(a.data, stderr=a.cmd == "serve")
    return server, server.Signer(a.data, cfg)


def cmd_serve(a) -> int:
    server, signer = _signer(a)
    server.serve(signer)
    try:
        threading.Event().wait()
    except KeyboardInterrupt:
        signer.stop.set()
    return 0


def cmd_service(a) -> int:
    from btsign import winsvc
    holder = {}

    def start():
        server, signer = _signer(a)
        holder["servers"] = server.serve(signer)
        holder["signer"] = signer

    def stop():
        holder["signer"].stop.set()
        for s in holder.get("servers", []):
            s.shutdown()

    winsvc.run(SERVICE_NAME, start, stop)
    return 0


def main(argv=None) -> int:
    p = argparse.ArgumentParser(prog="btsign", description=__doc__.splitlines()[0])
    sub = p.add_subparsers(dest="cmd", required=True)
    for name, fn in (("serve", cmd_serve), ("service", cmd_service)):
        s = sub.add_parser(name)
        s.add_argument("--data", required=True)
        s.add_argument("--config")
        s.set_defaults(fn=fn)
    s = sub.add_parser("bundle-create")
    for k in ("--ed25519", "--keyring", "--p12", "--properties", "--out"):
        s.add_argument(k, required=True)
    s.add_argument("--bundle-key-stdin", action="store_true", required=True)
    s.set_defaults(fn=cmd_bundle_create)
    s = sub.add_parser("bundle-open")
    s.add_argument("--bundle", required=True)
    s.add_argument("--out-dir", required=True)
    s.add_argument("--bundle-key-stdin", action="store_true", required=True)
    s.set_defaults(fn=cmd_bundle_open)
    admin = "http://127.0.0.1:8796"
    s = sub.add_parser("import")
    s.add_argument("--bundle", required=True)
    s.add_argument("--bundle-key-stdin", action="store_true", required=True)
    s.add_argument("--admin", default=admin)
    s.set_defaults(fn=cmd_import)
    s = sub.add_parser("set-secret")
    s.add_argument("name", choices=("bot_token", "client_token", "approve_token"))
    s.add_argument("--stdin", action="store_true", required=True)
    s.add_argument("--admin", default=admin)
    s.set_defaults(fn=cmd_set_secret)
    s = sub.add_parser("status")
    s.add_argument("--admin", default=admin)
    s.set_defaults(fn=cmd_status)
    a = p.parse_args(argv)
    try:
        return a.fn(a)
    except (crypto.CryptoError, ops.OpError, OSError) as e:
        print(f"error: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
