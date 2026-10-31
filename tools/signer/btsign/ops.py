# SPDX-License-Identifier: Apache-2.0
"""The signing operations. Each job names its input files (already uploaded and hashed by the
signer) and its output; `describe` says what the owner is asked to approve, `run` signs.

  update-manifest  btlabs-public's DSSE envelope (update.json, update-v2.json), with the vendored,
                   hash-pinned btlabs_sign.py: the same checks (payload schema, links held to
                   their folders, --prev serial, self-verify) and the same bytes.
  minisign         a minisign signature (SHA256SUMS, provenance.json, an SBOM): the bytes
                   tools/gitlab-release.py writes.
  apk              apksigner with exactly the schemes the release APKs carry (config apk_schemes,
                   today v2 only), existing alignment kept, then verified.
  aab              jarsigner (SHA-256 digests, SHA256withRSA), as Gradle signs the Play bundle.
  export           the portable encrypted bundle (scrypt + AES-256-GCM, the stored bundle key).
"""
from __future__ import annotations

import base64
import hashlib
import importlib.util
import json
import os
import re
import secrets as _secrets
import subprocess
import sys
from datetime import datetime, timezone

from . import crypto

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VENDOR = os.path.join(HERE, "vendor", "btlabs_public")
SELFTEST_APK = os.path.join(HERE, "selftest", "selftest-unsigned.apk")
# The vendored btlabs-public files (btlabs-public 7161d7e). A change here is a change to what
# installed apps accept: update the pins only together with btlabs-public, and run
# tests/test_vendor.py (byte-identical envelopes from both copies).
VENDOR_PINS = {
    "tool/btlabs_sign.py": "8c969e59bc3efaaa40708562a602aff0b7cabf0833a5379c318da53fbcb1c371",
    "schema/envelope.schema.json": "adc2283b1fc976fa1b45d38e0810e3b5734b2c7e268ba0882e1dc2c5406686fc",
    "schema/keyring.schema.json": "9f919e915c22a06b84f3fd7ca9ebe3e966e04874b214d5854c8b2a74c01edb10",
    "schema/payload.schema.json": "5b15a6e4ea8c527ea4fda6fee6e0877f43dc54efde6893ae07d568f6102c4058",
    "schema/update.schema.json": "f1705d28faf726176022f37eb97cc6f8bcadb065c4ab7cd5e3f31f989ee40187",
}
# The fixed, empty throwaway APK selftest signs (package uk.btlabs.signer.selftest, no code;
# selftest/make-selftest-apk.sh). Its signed copy is checked and deleted, never served.
SELFTEST_APK_SHA256 = "ac0b9ca2db5a9a620e8f8a79325595ca060615f970aa12f581b224e074d28384"
SELFTEST_PACKAGE = "uk.btlabs.signer.selftest"
SELFTEST_PREFIX = b"btsign-selftest-v1\n"   # never a DSSE PAE ("DSSEv1 ") nor a 64-byte digest

OPS = ("update-manifest", "minisign", "apk", "aab", "export")
NAME_RE = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]{0,127}\Z")
COMMENT_RE = re.compile(r"[ -~]{1,200}\Z")
SUMS_LINE = re.compile(r"([0-9a-f]{64})  ([A-Za-z0-9][A-Za-z0-9._-]{0,127})\Z")


def _read(path: str, text: bool = False):
    with open(path, encoding="utf-8") if text else open(path, "rb") as f:
        return f.read()


class OpError(Exception):
    """Why a job cannot run; shown to the client and to the owner. Never key material."""


_vendored = None


def vendored():
    """btlabs_sign.py from vendor/, after checking every vendored file against VENDOR_PINS."""
    global _vendored
    if _vendored is None:
        for rel, want in VENDOR_PINS.items():
            got = crypto.sha256_file(os.path.join(VENDOR, rel))
            if got != want:
                raise OpError(f"vendored {rel} does not match its pin: refusing to sign")
        spec = importlib.util.spec_from_file_location("btsign_vendored_btlabs_sign",
                                                      os.path.join(VENDOR, "tool", "btlabs_sign.py"))
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        _vendored = mod
    return _vendored


# ---------------------------------------------------------------- the keys in the store

def update_key(secrets: dict):
    keys = secrets.get("ed25519") or {}
    if len(keys) != 1:
        raise OpError("the store holds no update key (import a bundle)")
    return crypto.load_ed25519_pem(next(iter(keys.values())))


def keyring(secrets: dict) -> dict:
    ring = secrets.get("keyring")
    if not isinstance(ring, dict):
        raise OpError("the store holds no keyring (import a bundle)")
    return ring


def parse_properties(text: str) -> dict:
    """Java .properties as Gradle's key.properties uses them (key=value, # comments, backslash
    escapes)."""
    out = {}
    for line in text.splitlines():
        s = line.strip()
        if not s or s[0] in "#!":
            continue
        m = re.match(r"((?:\\.|[^=:\s\\])+)\s*[=:\s]\s*(.*)\Z", s)
        if not m:
            continue
        unesc = lambda v: re.sub(r"\\(.)", lambda x: {"t": "\t", "n": "\n", "r": "\r"}.get(x.group(1), x.group(1)), v)
        out[unesc(m.group(1))] = unesc(m.group(2))
    return out


def android_from_files(p12_path: str, properties_path: str) -> dict:
    """The stored Android entry from the keystore and its key.properties; checks the passwords
    open it and returns the certificate's SHA-256 with it."""
    with open(properties_path, "rb") as f:
        props_raw = f.read()
    props = parse_properties(props_raw.decode("utf-8"))
    for k in ("storePassword", "keyPassword", "keyAlias"):
        if not props.get(k):
            raise OpError(f"{properties_path} has no {k}")
    with open(p12_path, "rb") as f:
        p12 = f.read()
    # The original key.properties bytes travel too, so a bundle gives back the very same files.
    entry = {"p12_b64": base64.b64encode(p12).decode(), "store_password": props["storePassword"],
             "key_password": props["keyPassword"], "key_alias": props["keyAlias"],
             "properties_b64": base64.b64encode(props_raw).decode()}
    entry["cert_sha256"] = android_cert_sha256(entry)
    return entry


def android_cert_sha256(entry: dict) -> str:
    from cryptography.hazmat.primitives import serialization
    from cryptography.hazmat.primitives.serialization import pkcs12
    data = base64.b64decode(entry["p12_b64"])
    for pw in (entry["store_password"], entry["key_password"]):
        try:
            _, cert, _ = pkcs12.load_key_and_certificates(data, pw.encode("utf-8"))
        except Exception:  # wrong password: try the other; never the exception text
            continue
        if cert is not None:
            return hashlib.sha256(cert.public_bytes(serialization.Encoding.DER)).hexdigest()
    raise OpError("the Android keystore does not open with its stored passwords")


# ---------------------------------------------------------------- job specs

def check_job(job: dict, inputs: dict) -> dict:
    """Validate one job against the request's declared inputs; returns it normalised."""
    if not isinstance(job, dict):
        raise OpError("a job is an object")
    op = job.get("op")
    if op not in OPS:
        raise OpError(f"unknown op {op!r} (known: {', '.join(OPS)})")
    allowed = {"update-manifest": {"op", "payload", "out", "prev", "app_config"},
               "minisign": {"op", "file", "out", "trusted_comment"},
               "apk": {"op", "file", "out"}, "aab": {"op", "file", "out"},
               "export": {"op", "out"}}[op]
    extra = set(job) - allowed
    if extra:
        raise OpError(f"{op}: unknown fields {sorted(extra)}")
    need = {"update-manifest": ("payload", "out"), "minisign": ("file", "out", "trusted_comment"),
            "apk": ("file", "out"), "aab": ("file", "out"), "export": ("out",)}[op]
    for k in need:
        if not isinstance(job.get(k), str):
            raise OpError(f"{op}: {k} is required")
    for k in ("payload", "prev", "app_config", "file"):
        if k in job and job[k] is not None and job[k] not in inputs:
            raise OpError(f"{op}: {k} {job[k]!r} is not one of the request's files")
    if not NAME_RE.match(job["out"]):
        raise OpError(f"{op}: bad output name {job['out']!r}")
    if op == "minisign" and not COMMENT_RE.match(job["trusted_comment"]):
        raise OpError("minisign: trusted_comment is 1-200 printable ASCII characters")
    return job


def _ledger_mark(ledger: set, sha: str | None) -> str:
    return " ✓signed here" if sha and sha in ledger else ""


def describe(job: dict, indir: str, hashes: dict, ledger: set) -> list[str]:
    """The lines the owner reads for this job (besides each file's name, size and SHA-256)."""
    op = job["op"]
    if op == "update-manifest":
        bs = vendored()
        body = _read(os.path.join(indir, job["payload"]))
        folders = bs.UpdateFolders.from_app_config(os.path.join(indir, job["app_config"])) \
            if job.get("app_config") else bs.OLD_FOLDERS
        problem = bs.validate_payload_bytes(body, bs.UPDATE_TYPE, folders)
        if problem:
            raise OpError(f"{job['payload']}: payload is not valid ({problem})")
        p = json.loads(body)
        lines = [f"{job['out']}: {p.get('packageName')} {p.get('versionName')} serial {p.get('serial')}"
                 f"{'' if job.get('prev') else ' (no --prev)'}, expires {p.get('expires_at')}"]
        for section, rel in (("", p), ("notor ", p.get("notor") or {})):
            for a in rel.get("apks", []):
                lines.append(f"  {section}apk {a['url'].rsplit('/', 1)[-1]} {a['sha256'][:16]}"
                             f"{_ledger_mark(ledger, a.get('sha256'))}")
            d = rel.get("desktop") or {}
            for entry in [d] if "version" in d else d.values():
                if isinstance(entry, dict) and entry.get("url"):
                    lines.append(f"  {section}desktop {entry['url'].rsplit('/', 1)[-1]} "
                                 f"{(entry.get('sha256') or '')[:16]}")
        return lines
    if op == "minisign":
        lines = [f"{job['out']}: minisign of {job['file']} \"{job['trusted_comment']}\""]
        try:
            text = _read(os.path.join(indir, job["file"]), text=True)
        except (UnicodeDecodeError, OSError):
            return lines
        rows = [SUMS_LINE.match(x) for x in text.splitlines()]
        if text and all(rows):
            for m in rows[:30]:
                lines.append(f"  {m.group(2)} {m.group(1)[:16]}{_ledger_mark(ledger, m.group(1))}")
            if len(rows) > 30:
                lines.append(f"  … {len(rows) - 30} more lines")
        return lines
    if op in ("apk", "aab"):
        return [f"{job['out']}: {op} signature with the Android release key"]
    return [f"{job['out']}: the encrypted key bundle (to move the signer)"]


def _file_entries(o):
    """Every {url, sha256} object of a payload (APKs, desktop builds), wherever it sits."""
    if isinstance(o, dict):
        if isinstance(o.get("url"), str) and "sha256" in o:
            yield o
        for v in o.values():
            yield from _file_entries(v)
    elif isinstance(o, list):
        for v in o:
            yield from _file_entries(v)


def _prev_files(indir: str, job: dict) -> dict:
    """{file name: sha256} of the published manifest a job names as --prev (already signed and
    live: the entries a release keeps from it)."""
    if not job.get("prev"):
        return {}
    env = json.loads(_read(os.path.join(indir, job["prev"])))
    payload = json.loads(base64.b64decode(env["payload"]))
    return {e["url"].rsplit("/", 1)[-1]: e.get("sha256") for e in _file_entries(payload)}


def check_follow(jobs: list[dict], indir: str, signed: dict, expect: dict, version: str) -> None:
    """A follow-up signed on the code of the Android request before it (server.py, `then`). Each
    update manifest is for the request's version; each APK it names is one this request signed
    (URL file name, SHA-256, size); each other file it names (a desktop build) is one the
    request declared when the owner approved it (`expect`: name, SHA-256, size) or one the live
    manifest (--prev) already names with that SHA-256. Each SHA256SUMS lists every file the
    manifests name, and a line for a file signed or declared here carries that hash. Raises
    OpError otherwise."""
    known = {n: {"sha256": v["sha256"], "size": v["size"]} for n, v in expect.items()}
    known.update({n: {"sha256": v["sha256"], "size": v["size"]} for n, v in signed.items()})
    named = set()
    for j in jobs:
        if j["op"] != "update-manifest":
            continue
        p = json.loads(_read(os.path.join(indir, j["payload"])))
        if p.get("versionName") != version:
            raise OpError(f"{j['payload']}: versionName {p.get('versionName')!r} is not the request's {version}")
        apks = list(p.get("apks") or []) + list((p.get("notor") or {}).get("apks") or [])
        if not apks:
            raise OpError(f"{j['payload']}: names no APK")
        apk_ids = {id(a) for a in apks}
        try:
            prev = _prev_files(indir, j)
        except (ValueError, KeyError, TypeError, AttributeError):
            raise OpError(f"{j['prev']}: not a readable manifest") from None
        for e in _file_entries(p):
            name = e["url"].rsplit("/", 1)[-1]
            k = (signed if id(e) in apk_ids else known).get(name)
            if k and e.get("sha256") == k["sha256"] and e.get("size") == k["size"]:
                named.add(name)
            elif id(e) not in apk_ids and name not in known and prev.get(name) == e.get("sha256"):
                continue    # kept from the live manifest: not this release's file
            else:
                what = "signed" if id(e) in apk_ids else "declared"
                raise OpError(f"{j['payload']}: {name} is not the file {what} in this request")
    for j in jobs:
        if j["op"] == "update-manifest":
            continue
        if j["op"] != "minisign":
            raise OpError(f"{j['op']} cannot follow on an earlier code")
        try:
            text = _read(os.path.join(indir, j["file"]), text=True)
        except UnicodeDecodeError:
            raise OpError(f"{j['file']}: not a SHA256SUMS listing") from None
        rows = [SUMS_LINE.match(x) for x in text.splitlines()]
        if not text or not all(rows):
            raise OpError(f"{j['file']}: not a SHA256SUMS listing")
        listed = {m.group(2): m.group(1) for m in rows}
        for name, k in known.items():
            if name in listed and listed[name] != k["sha256"]:
                raise OpError(f"{j['file']}: {name} is listed with another hash than the one approved here")
        missing = sorted(named - set(listed))
        if missing:
            raise OpError(f"{j['file']}: does not list {', '.join(missing)}")
        if not any(name in listed for name in signed):
            raise OpError(f"{j['file']}: lists none of the files signed in this request")


# ---------------------------------------------------------------- running

class Tools:
    """Where Java, apksigner and the work folder are (config)."""

    def __init__(self, cfg: dict, data_dir: str):
        self.java = cfg.get("java", "java")
        self.jarsigner = cfg.get("jarsigner") or os.path.join(os.path.dirname(self.java), "jarsigner")
        self.keytool = cfg.get("keytool") or os.path.join(os.path.dirname(self.java), "keytool")
        self.apksigner_jar = cfg.get("apksigner_jar", "")
        self.apksigner_sha256 = cfg.get("apksigner_jar_sha256", "")
        self.schemes = dict({"v1": False, "v2": True, "v3": False, "v4": False}, **cfg.get("apk_schemes", {}))
        self.tmp = os.path.join(data_dir, "tmp")
        os.makedirs(self.tmp, exist_ok=True)

    def apksigner(self, *args, env=None) -> subprocess.CompletedProcess:
        if not self.apksigner_jar or not os.path.isfile(self.apksigner_jar):
            raise OpError("apksigner.jar is not installed (config apksigner_jar)")
        if crypto.sha256_file(self.apksigner_jar) != self.apksigner_sha256:
            raise OpError("apksigner.jar does not match its pinned SHA-256")
        return _run([self.java, "-jar", self.apksigner_jar, *args], env)


def _run(argv, env=None, timeout=900) -> subprocess.CompletedProcess:
    full = dict(os.environ)
    full.update(env or {})
    kw = {"creationflags": 0x08000000} if os.name == "nt" else {}  # CREATE_NO_WINDOW
    return subprocess.run(argv, env=full, capture_output=True, text=True, timeout=timeout, **kw)


class _Keystore:
    """The Android keystore as a temporary file in the signer's own tmp folder (the data folder's
    ACL covers it), its passwords only in the child's environment. Removed on exit."""

    def __init__(self, entry: dict, tmp: str):
        self.entry, self.tmp, self.path = entry, tmp, None

    def __enter__(self):
        self.path = os.path.join(self.tmp, f"ks-{_secrets.token_hex(8)}.p12")
        fd = os.open(self.path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(fd, "wb") as f:
            f.write(base64.b64decode(self.entry["p12_b64"]))
        self.env = {"BTSIGN_KS_PASS": self.entry["store_password"],
                    "BTSIGN_KEY_PASS": self.entry["key_password"]}
        return self

    def __exit__(self, *exc):
        if self.path and os.path.exists(self.path):
            os.unlink(self.path)


def _clean(text: str, secrets_in: dict) -> str:
    """Tool output for an error message, with any stored password masked."""
    for v in (secrets_in.get("store_password"), secrets_in.get("key_password")):
        if v:
            text = text.replace(v, "***")
    return text.strip()[-600:]


def verify_apk(tools: Tools, path: str, want_cert: str) -> dict:
    p = tools.apksigner("verify", "-v", "--print-certs", path)
    out = p.stdout + p.stderr
    if p.returncode != 0:
        raise OpError("apksigner verify failed: " + out.strip()[-400:])
    got = {}
    for v, label in (("v1", "v1 scheme (JAR signing)"), ("v2", "v2 scheme (APK Signature Scheme v2)"),
                     ("v3", "v3 scheme (APK Signature Scheme v3)"), ("v4", "v4 scheme (APK Signature Scheme v4)")):
        got[v] = f"Verified using {label}: true" in out
    m = re.search(r"Signer #1 certificate SHA-256 digest: ([0-9a-f]{64})", out)
    signers = re.search(r"Number of signers: (\d+)", out)
    return {"schemes": got, "cert_sha256": m.group(1) if m else None,
            "signers": int(signers.group(1)) if signers else 0}


def sign_apk(tools: Tools, entry: dict, src: str, dst: str) -> dict:
    with _Keystore(entry, tools.tmp) as ks:
        p = tools.apksigner(
            "sign", "--ks", ks.path, "--ks-type", "PKCS12", "--ks-key-alias", entry["key_alias"],
            "--ks-pass", "env:BTSIGN_KS_PASS", "--key-pass", "env:BTSIGN_KEY_PASS",
            *[a for v in ("v1", "v2", "v3", "v4")
              for a in (f"--{v}-signing-enabled", "true" if tools.schemes[v] else "false")],
            "--alignment-preserved", "true", "--out", dst, src, env=ks.env)
        if p.returncode != 0:
            raise OpError("apksigner sign failed: " + _clean(p.stdout + p.stderr, entry))
    for leftover in (dst + ".idsig",):
        if os.path.exists(leftover) and not tools.schemes["v4"]:
            os.unlink(leftover)
    v = verify_apk(tools, dst, entry["cert_sha256"])
    if v["cert_sha256"] != entry["cert_sha256"] or v["signers"] != 1:
        raise OpError("the signed APK does not carry the release certificate alone")
    if v["schemes"] != tools.schemes:
        raise OpError(f"the signed APK's schemes {v['schemes']} are not {tools.schemes}")
    return v


def sign_aab(tools: Tools, entry: dict, src: str, dst: str) -> None:
    with open(src, "rb") as f, open(dst, "wb") as g:
        while chunk := f.read(1 << 20):
            g.write(chunk)
    with _Keystore(entry, tools.tmp) as ks:
        p = _run([tools.jarsigner, "-keystore", ks.path, "-storetype", "PKCS12",
                  "-storepass:env", "BTSIGN_KS_PASS", "-keypass:env", "BTSIGN_KEY_PASS",
                  "-digestalg", "SHA-256", "-sigalg", "SHA256withRSA", dst, entry["key_alias"]], ks.env)
        if p.returncode != 0:
            raise OpError("jarsigner failed: " + _clean(p.stdout + p.stderr, entry))
    p = _run([tools.keytool, "-printcert", "-jarfile", dst])
    m = re.search(r"SHA256:\s*([0-9A-F:]{95})", p.stdout)
    if not m or m.group(1).replace(":", "").lower() != entry["cert_sha256"]:
        raise OpError("the signed bundle does not carry the release certificate")


def run_job(job: dict, indir: str, outdir: str, secrets: dict, tools: Tools, now=None) -> str:
    """Signs one job into outdir/<out>; returns the output's SHA-256."""
    op, dst = job["op"], os.path.join(outdir, job["out"])
    if op == "update-manifest":
        bs = vendored()
        body = _read(os.path.join(indir, job["payload"]))
        folders = bs.UpdateFolders.from_app_config(os.path.join(indir, job["app_config"])) \
            if job.get("app_config") else bs.OLD_FOLDERS
        try:
            problem = bs.validate_payload_bytes(body, bs.UPDATE_TYPE, folders)
            if problem:
                raise OpError(f"payload is not valid ({problem})")
            if job.get("prev"):
                bs.check_newer_than(body, os.path.join(indir, job["prev"]))
            key = update_key(secrets)
            ring = keyring(secrets)
            loaded = bs.load_keyring(ring)
            kid = crypto.keyid_of(crypto.raw_public(key))
            if kid not in loaded:
                raise OpError(f"the update key {kid} is not in the stored keyring")
            if loaded[kid]["rank"] != min(v["rank"] for v in loaded.values()):
                raise OpError("the stored key is a rotation key; the signer only signs with rank 1")
            data = bs.sign_envelope(body, bs.UPDATE_TYPE, [key])
            r = bs.verify_envelope(data, bs.UPDATE_TYPE, ring, None, now or datetime.now(timezone.utc), folders)
        except bs.ToolError as e:
            raise OpError(str(e)) from None
        if r["outcome"] != "accepted":
            raise OpError(f"signed file does not verify ({r['reason']}); nothing written")
        with open(dst, "wb") as f:
            f.write(data)
    elif op == "minisign":
        data = _read(os.path.join(indir, job["file"]))
        with open(dst, "w", encoding="utf-8", newline="\n") as f:
            f.write(crypto.minisign_sign(update_key(secrets), data, job["trusted_comment"]))
    elif op == "apk":
        sign_apk(tools, _android(secrets), os.path.join(indir, job["file"]), dst)
    elif op == "aab":
        sign_aab(tools, _android(secrets), os.path.join(indir, job["file"]), dst)
    elif op == "export":
        bk = secrets.get("bundle_key")
        if not bk:
            raise OpError("the store holds no bundle key")
        with open(dst, "wb") as f:
            f.write(crypto.seal_bundle(bundle_content(secrets), bk))
    return crypto.sha256_file(dst)


def _android(secrets: dict) -> dict:
    a = secrets.get("android")
    if not a:
        raise OpError("the store holds no Android keystore (import a bundle)")
    return a


def bundle_content(secrets: dict) -> dict:
    """What a bundle carries: the keys, the keyring, the Android keystore and, once enrolled,
    the TOTP secret (so a move keeps the enrolment). Never the tokens or the bundle key."""
    out = {"ed25519": secrets.get("ed25519") or {}, "keyring": secrets.get("keyring"),
           "android": {k: v for k, v in (secrets.get("android") or {}).items()}}
    if secrets.get("totp"):
        out["totp"] = secrets["totp"]
    return out


def check_bundle_content(content: dict) -> None:
    if not isinstance(content, dict) or len(content.get("ed25519") or {}) != 1:
        raise OpError("the bundle holds no single update key")
    key = crypto.load_ed25519_pem(next(iter(content["ed25519"].values())))
    ring = vendored().load_keyring(content["keyring"])
    if crypto.keyid_of(crypto.raw_public(key)) not in ring:
        raise OpError("the bundle's update key is not in its keyring")
    a = content.get("android") or {}
    if not a.get("p12_b64") or android_cert_sha256(a) != a.get("cert_sha256"):
        raise OpError("the bundle's Android keystore does not match its certificate digest")


# ---------------------------------------------------------------- selftest

def selftest(secrets: dict, tools: Tools) -> dict:
    """Key identity without a usable artefact: a signature over a random challenge with a domain
    prefix (never a manifest or a minisign digest), and the release certificate of a signed copy
    of the pinned throwaway APK (another package; the copy is deleted, never returned)."""
    key = update_key(secrets)
    raw = crypto.raw_public(key)
    challenge = SELFTEST_PREFIX + os.urandom(32)
    sig = key.sign(challenge)
    ring = vendored().load_keyring(keyring(secrets))
    kid = crypto.keyid_of(raw)
    from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey
    Ed25519PublicKey.from_public_bytes(ring[kid]["raw"]).verify(sig, challenge)
    out = {"ed25519": {"keyid": kid, "public_key": base64.b64encode(raw).decode(),
                       "challenge": base64.b64encode(challenge).decode(),
                       "signature": base64.b64encode(sig).decode()}}
    if crypto.sha256_file(SELFTEST_APK) != SELFTEST_APK_SHA256:
        raise OpError("the selftest APK does not match its pin")
    entry = _android(secrets)
    dst = os.path.join(tools.tmp, f"selftest-{_secrets.token_hex(6)}.apk")
    try:
        v = sign_apk(tools, entry, SELFTEST_APK, dst)
    finally:
        for p in (dst, dst + ".idsig"):
            if os.path.exists(p):
                os.unlink(p)
    out["apk"] = {"package": SELFTEST_PACKAGE, "cert_sha256": v["cert_sha256"], "schemes": v["schemes"],
                  "unsigned_sha256": SELFTEST_APK_SHA256}
    return out


if __name__ == "__main__":  # pragma: no cover
    sys.exit("not a command: use btsign.py")
