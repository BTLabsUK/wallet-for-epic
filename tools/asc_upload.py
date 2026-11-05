#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Uploads a signed .ipa to App Store Connect (TestFlight) from Linux.

Uses the App Store Connect API's build uploads (POST /v1/buildUploads, POST /v1/buildUploadFiles,
PUT the parts, PATCH the file as uploaded, then GET /v1/buildUploads/{id} until it is COMPLETE or
FAILED). Apple's Transporter for Linux would need an AppStoreInfo.plist that only Xcode's export
writes; this needs only the team API key (.p8). Standard library and the openssl command only.

Run by tools/apple-sign.sh ios-upload, which passes the key settings:
  asc_upload.py [--dry-run] --key-id ID --issuer-id UUID --p8 AuthKey_ID.p8 --bundle-id ID <.ipa>
Exit status 3 when Apple refuses (an HTTP error or a FAILED upload), 1 for a local problem.
--dry-run reads the .ipa, makes and checks a token with the key, and prints the requests it would
send; nothing goes to Apple.

The app record must exist first (App Store Connect, Apps, +, New App): the API cannot create one.
The request bodies follow Apple's API reference for buildUploads/buildUploadFiles; they were not
yet run against Apple when this was written (tools/apple-release.md lists it as a first-run check).
"""

import pathlib
import argparse
import base64
import hashlib
import json
import plistlib
import subprocess
import sys
import time
import urllib.error
import urllib.request
import zipfile

API = "https://api.appstoreconnect.apple.com"


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def der_to_raw(sig: bytes) -> bytes:
    """An ECDSA signature as openssl writes it (DER SEQUENCE of r, s) -> r || s, 32 bytes each."""
    if sig[0] != 0x30:
        raise ValueError("not a DER signature")
    pos = 2 if sig[1] < 0x80 else 2 + (sig[1] & 0x7F)
    parts = []
    for _ in range(2):
        if sig[pos] != 0x02:
            raise ValueError("not a DER integer")
        length = sig[pos + 1]
        value = sig[pos + 2:pos + 2 + length].lstrip(b"\0")
        parts.append(value.rjust(32, b"\0"))
        pos += 2 + length
    return b"".join(parts)


def token(key_id: str, issuer: str, p8: str) -> str:
    """A 15-minute ES256 token for the App Store Connect API, signed with the .p8 by openssl."""
    now = int(time.time())
    head = b64url(json.dumps({"alg": "ES256", "kid": key_id, "typ": "JWT"}).encode())
    body = b64url(json.dumps({"iss": issuer, "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"}).encode())
    signing_input = f"{head}.{body}".encode()
    sig = subprocess.run(["openssl", "dgst", "-sha256", "-sign", p8], input=signing_input,
                         capture_output=True, check=True).stdout
    return f"{head}.{body}.{b64url(der_to_raw(sig))}"


class Api:
    def __init__(self, key_id: str, issuer: str, p8: str):
        self.key_id, self.issuer, self.p8 = key_id, issuer, p8
        self._token, self._made = "", 0.0

    def call(self, method: str, path: str, body=None):
        if time.time() - self._made > 600:
            self._token, self._made = token(self.key_id, self.issuer, self.p8), time.time()
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(API + path, data=data, method=method, headers={
            "Authorization": f"Bearer {self._token}", "Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                raw = resp.read()
        except urllib.error.HTTPError as e:
            print(f"{method} {path}: HTTP {e.code}: {e.read().decode(errors='replace')[:2000]}", file=sys.stderr)
            sys.exit(3)
        return json.loads(raw) if raw else {}


def ipa_info(path: str) -> dict:
    with zipfile.ZipFile(path) as z:
        names = [n for n in z.namelist() if n.startswith("Payload/") and n.count("/") == 2
                 and n.endswith(".app/Info.plist")]
        if len(names) != 1:
            sys.exit(f"{path}: expected one Payload/<name>.app/Info.plist, found {names}")
        if not any(n.endswith(".app/embedded.mobileprovision") and n.count("/") == 2 for n in z.namelist()):
            sys.exit(f"{path}: no embedded.mobileprovision: sign it with apple-sign.sh ios first")
        return plistlib.loads(z.read(names[0]))


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--key-id", required=True)
    ap.add_argument("--issuer-id", required=True)
    ap.add_argument("--p8", required=True)
    ap.add_argument("--bundle-id", required=True)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("ipa")
    a = ap.parse_args()

    info = ipa_info(a.ipa)
    if info.get("CFBundleIdentifier") != a.bundle_id:
        sys.exit(f"the .ipa is {info.get('CFBundleIdentifier')}, not {a.bundle_id}")
    version, build = info["CFBundleShortVersionString"], info["CFBundleVersion"]
    data = pathlib.Path(a.ipa).read_bytes()
    md5 = hashlib.md5(data).hexdigest()
    print(f"{a.ipa}: {a.bundle_id} {version} ({build}), {len(data)} bytes, md5 {md5}")

    if a.dry_run:
        t = token(a.key_id, a.issuer_id, a.p8)
        check = subprocess.run(["openssl", "pkey", "-in", a.p8, "-pubout"], capture_output=True, check=True).stdout
        print(f"dry run: token made with the key ({len(t)} chars, ES256), public key:\n{check.decode().strip()}")
        print("dry run: would send GET /v1/apps?filter[bundleId]=..., POST /v1/buildUploads "
              "(IOS, version, build), POST /v1/buildUploadFiles (com.apple.ipa), PUT the parts, "
              "PATCH uploaded + MD5, then poll GET /v1/buildUploads/{id}")
        return

    api = Api(a.key_id, a.issuer_id, a.p8)
    apps = api.call("GET", f"/v1/apps?filter[bundleId]={a.bundle_id}")["data"]
    if not apps:
        sys.exit(f"no App Store Connect app record for {a.bundle_id}: create it once in the web page "
                 "(Apps, +, New App)")
    upload_id = api.call("POST", "/v1/buildUploads", {"data": {
        "type": "buildUploads",
        "attributes": {"cfBundleShortVersionString": version, "cfBundleVersion": build, "platform": "IOS"},
        "relationships": {"app": {"data": {"type": "apps", "id": apps[0]["id"]}}},
    }})["data"]["id"]
    file = api.call("POST", "/v1/buildUploadFiles", {"data": {
        "type": "buildUploadFiles",
        "attributes": {"assetType": "ASSET", "fileName": a.ipa.rsplit("/", 1)[-1], "fileSize": len(data),
                       "uti": "com.apple.ipa"},
        "relationships": {"buildUpload": {"data": {"type": "buildUploads", "id": upload_id}}},
    }})["data"]
    ops = file["attributes"]["uploadOperations"]
    for i, op in enumerate(ops, 1):
        part = data[op["offset"]:op["offset"] + op["length"]]
        headers = {h["name"]: h["value"] for h in op.get("requestHeaders") or []}
        req = urllib.request.Request(op["url"], data=part, method=op["method"], headers=headers)
        with urllib.request.urlopen(req, timeout=600) as resp:
            resp.read()
        print(f"part {i}/{len(ops)}: {len(part)} bytes")
    api.call("PATCH", f"/v1/buildUploadFiles/{file['id']}", {"data": {
        "type": "buildUploadFiles", "id": file["id"],
        "attributes": {"uploaded": True, "sourceFileChecksums": {"file": {"hash": md5, "algorithm": "MD5"}}},
    }})
    state: dict = {}
    for _ in range(160):
        state = api.call("GET", f"/v1/buildUploads/{upload_id}")["data"]["attributes"].get("state") or {}
        if state.get("state") in ("COMPLETE", "FAILED"):
            break
        time.sleep(15)
    print(f"build upload {upload_id}: {state.get('state')}")
    for kind in ("errors", "warnings", "infos"):
        for item in state.get(kind) or []:
            print(f"  {kind[:-1]} {item.get('code')}: {item.get('description')}")
    if state.get("state") != "COMPLETE":
        sys.exit(3)
    print("Uploaded. App Store Connect now processes the build; it shows in TestFlight when done.")


if __name__ == "__main__":
    main()
