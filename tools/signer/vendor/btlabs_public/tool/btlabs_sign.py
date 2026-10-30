#!/usr/bin/env python3
"""BT Labs signed public file: signing / verification tool (FORMAT.md v1).

CLI: python3 tool/btlabs_sign.py {keygen,keyring,sign,verify,show} ...
Also importable: pae, keyid_of, sign_envelope, verify_envelope, load_keyring, ...

Private key material is never printed or logged by this tool.
"""
from __future__ import annotations

import argparse
import base64
import binascii
import copy
import hashlib
import json
import os
import re
import sys
import tempfile
from datetime import datetime, timedelta, timezone
from pathlib import Path

from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import (
    Ed25519PrivateKey,
    Ed25519PublicKey,
)
import jsonschema

ROOT = Path(__file__).resolve().parent.parent
SCHEMA_DIR = ROOT / "schema"

PUBLIC_TYPE = "application/vnd.btlabs.public+json"
UPDATE_TYPE = "application/vnd.btlabs.wallet-for-epic.update+json"
KNOWN_TYPES = (PUBLIC_TYPE, UPDATE_TYPE)
TYPE_ALIASES = {"public": PUBLIC_TYPE, "update": UPDATE_TYPE}
MAX_ENVELOPE_BYTES = 65536
MAX_SIGNATURES = 8
MAX_VALIDITY = timedelta(days=400)


class UpdateFolders:
    """Where an update manifest's links may point (FORMAT.md section 6).

    downloads: the folder of every release file, a plain file name right after it.
    pages: the prefixes a desktop entry's page may start with.
    apks_in_downloads: phone APKs are held to downloads too (update-v2.json); in update.json
    (OLD_FOLDERS, the format installed apps up to 26.10.23 read) an APK may be any https URL.
    """

    def __init__(self, downloads: str, pages, apks_in_downloads: bool):
        self.downloads = downloads
        self.pages = tuple(pages)
        self.apks_in_downloads = apks_in_downloads

    @classmethod
    def from_app_config(cls, path) -> "UpdateFolders":
        """update-v2.json's folders: [updates] downloads and pages of the wallet's app-config.toml."""
        import tomllib
        try:
            with open(path, "rb") as f:
                u = tomllib.load(f).get("updates", {})
        except (OSError, tomllib.TOMLDecodeError) as e:
            raise ToolError("cannot read %s: %s" % (path, e)) from None
        dl, pages = u.get("downloads"), u.get("pages")
        if (not isinstance(dl, str) or not dl.endswith("/") or not isinstance(pages, list)
                or not pages or not all(isinstance(x, str) for x in pages)):
            raise ToolError("%s: [updates] needs downloads (a folder) and pages" % path)
        return cls(dl, pages, apks_in_downloads=True)


OLD_FOLDERS = UpdateFolders("https://examples.btlabs.uk/epic-cash-wallets/downloads/",
                            ["https://github.com/BTLabs-EPIC/"], apks_in_downloads=False)
_FILE_NAME_RE = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]*")
MAX_SERIAL = 2**53 - 1

TS_RE = re.compile(
    r"([0-9]{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])"
    r"T([01][0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])Z\Z"
)
LABEL_RE = re.compile(r"[a-z0-9][a-z0-9-]{0,31}\Z")
KEYID_RE = re.compile(r"[0-9a-f]{16}\Z")
DIGEST_RE = re.compile(r"[0-9a-f]{64}\Z")


class ToolError(Exception):
    """User-facing error. Messages must never contain key material."""


class KeyringError(ValueError):
    pass


# --------------------------------------------------------------------------
# primitives
# --------------------------------------------------------------------------

def pae(payload_type: str, body: bytes) -> bytes:
    t = payload_type.encode("utf-8")
    return b"DSSEv1 %d %s %d %s" % (len(t), t, len(body), body)


def keyid_of(raw_pub: bytes) -> str:
    return hashlib.sha256(raw_pub).hexdigest()[:16]


def b64e(raw: bytes) -> str:
    return base64.b64encode(raw).decode("ascii")


def b64d(s: str) -> bytes:
    """Strict standard-alphabet base64 with padding; canonical encoding only."""
    if not isinstance(s, str) or len(s) % 4 != 0:
        raise ValueError("bad base64")
    try:
        raw = base64.b64decode(s, validate=True)
    except (binascii.Error, ValueError):
        raise ValueError("bad base64") from None
    if base64.b64encode(raw).decode("ascii") != s:  # reject non-canonical bits
        raise ValueError("bad base64")
    return raw


def parse_ts(s) -> datetime:
    """Strict UTC timestamp YYYY-MM-DDTHH:MM:SSZ; ValueError if impossible."""
    if not isinstance(s, str):
        raise ValueError("bad timestamp")
    m = TS_RE.match(s)
    if not m:
        raise ValueError("bad timestamp")
    y, mo, d, h, mi, se = (int(x) for x in m.groups())
    return datetime(y, mo, d, h, mi, se, tzinfo=timezone.utc)  # ValueError on 02-30


def fmt_ts(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def sha256_hex(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


# --------------------------------------------------------------------------
# strict JSON
# --------------------------------------------------------------------------

def _no_dupes(pairs):
    d = {}
    for k, v in pairs:
        if k in d:
            raise ValueError("duplicate key")
        d[k] = v
    return d


def _no_const(name):
    raise ValueError("non-finite number")


def strict_json_loads(text: str):
    """json.loads that rejects duplicate keys and NaN/Infinity."""
    return json.loads(text, object_pairs_hook=_no_dupes, parse_constant=_no_const)


# --------------------------------------------------------------------------
# schemas
# --------------------------------------------------------------------------

def _anchor_patterns(node):
    # Python's "$" also matches before a trailing newline; "\Z" does not.
    if isinstance(node, dict):
        for k, v in node.items():
            if k == "pattern" and isinstance(v, str) and v.endswith("$") and not v.endswith("\\$"):
                node[k] = v[:-1] + r"\Z"
            else:
                _anchor_patterns(v)
    elif isinstance(node, list):
        for v in node:
            _anchor_patterns(v)


_validators: dict = {}


def _validator(name: str):
    if name not in _validators:
        with open(SCHEMA_DIR / name, encoding="utf-8") as f:
            schema = json.load(f)
        _anchor_patterns(schema)
        cls = jsonschema.validators.validator_for(schema)
        cls.check_schema(schema)
        _validators[name] = cls(schema)
    return _validators[name]


def payload_problem(obj, payload_type: str = PUBLIC_TYPE,
                    folders: UpdateFolders = OLD_FOLDERS) -> str | None:
    """Return None if payload obj is acceptable, else 'unsupported_schema' or 'malformed'.

    Dispatches on the payload type; an unknown type has no schema, so it is malformed.
    """
    if payload_type == UPDATE_TYPE:
        return _update_problem(obj, folders)
    if payload_type != PUBLIC_TYPE:
        return "malformed"
    return _public_problem(obj)


def _update_problem(obj, folders: UpdateFolders) -> str | None:
    if not isinstance(obj, dict):
        return "malformed"
    if "schema" in obj:
        sch = obj["schema"]
        if type(sch) is int and sch != 1:
            return "unsupported_schema"
        if type(sch) is not int:
            return "malformed"
    if _validator("update.schema.json").is_valid(obj) is False:
        return "malformed"
    # exact-int fields (jsonschema accepts 1.0 as an integer; we do not)
    if type(obj["serial"]) is not int:
        return "malformed"
    # The notor section (the release of the builds without Tor) is checked as the top level.
    releases = [obj] + ([obj["notor"]] if "notor" in obj else [])
    for rel in releases:
        for a in rel["apks"]:
            if type(a["versionCode"]) is not int or type(a["size"]) is not int:
                return "malformed"
        desktop = rel.get("desktop", {})
        for entry in [desktop] if "version" in desktop else desktop.values():
            if "size" in entry and type(entry["size"]) is not int:
                return "malformed"
    try:
        issued = parse_ts(obj["issued_at"])
        expires = parse_ts(obj["expires_at"])
    except ValueError:
        return "malformed"
    if not (expires > issued) or expires - issued > MAX_VALIDITY:
        return "malformed"
    for rel in releases:
        abis = [a["abi"] for a in rel["apks"]]
        if len(abis) != len(set(abis)):
            return "malformed"
    # The links, held to the folders (a bad one rejects the whole file).
    for rel in releases:
        desktop = rel.get("desktop", {})
        for entry in [desktop] if "version" in desktop else desktop.values():
            if "page" in entry and not any(entry["page"].startswith(p) for p in folders.pages):
                return "malformed"
            if "url" in entry and not _in_folder(entry["url"], folders.downloads):
                return "malformed"
        if folders.apks_in_downloads:
            if not all(_in_folder(a["url"], folders.downloads) for a in rel["apks"]):
                return "malformed"
    return None


def _in_folder(url: str, folder: str) -> bool:
    return url.startswith(folder) and _FILE_NAME_RE.fullmatch(url[len(folder):]) is not None


def _public_problem(obj) -> str | None:
    if not isinstance(obj, dict):
        return "malformed"
    if "schema" in obj:
        sch = obj["schema"]
        if type(sch) is int and sch != 1:  # exact int (bool/float are not ints here)
            return "unsupported_schema"
        if type(sch) is not int:
            return "malformed"
    if _validator("payload.schema.json").is_valid(obj) is False:
        return "malformed"
    # exact-int fields (jsonschema accepts 1.0 as an integer; we do not)
    if type(obj["serial"]) is not int:
        return "malformed"
    for r in obj["infrastructure"]["epicbox_relays"]:
        if "port" in r and type(r["port"]) is not int:
            return "malformed"
    for o in obj["infrastructure"].get("onions", []):
        if type(o["port"]) is not int or type(o["onion_port"]) is not int:
            return "malformed"
    try:
        issued = parse_ts(obj["issued_at"])
        expires = parse_ts(obj["expires_at"])
        for n in obj.get("notices", []):
            for k in ("starts_at", "ends_at"):
                if k in n:
                    parse_ts(n[k])
    except ValueError:
        return "malformed"
    if not (expires > issued) or expires - issued > MAX_VALIDITY:
        return "malformed"
    infra = obj["infrastructure"]
    for arr in (obj["donations"], obj["links"], infra["nodes"], infra["services"],
                infra.get("onions", []), obj.get("notices", [])):
        ids = [x["id"] for x in arr]
        if len(ids) != len(set(ids)):
            return "malformed"
    return None


def validate_payload_bytes(body: bytes, payload_type: str = PUBLIC_TYPE,
                           folders: UpdateFolders = OLD_FOLDERS) -> str | None:
    """Reason code ('malformed'/'unsupported_schema') or None if the payload is fine."""
    try:
        obj = strict_json_loads(body.decode("utf-8"))
    except (ValueError, RecursionError):
        return "malformed"
    return payload_problem(obj, payload_type, folders)


# --------------------------------------------------------------------------
# keyring
# --------------------------------------------------------------------------

def load_keyring(keyring: dict) -> dict:
    """Validate a keyring object; return {keyid: {"rank","raw","label"}}."""
    try:
        _validator("keyring.schema.json").validate(keyring)
    except jsonschema.ValidationError as e:
        raise KeyringError("keyring schema: " + e.message[:120]) from None
    out, ranks = {}, set()
    for k in keyring["keys"]:
        if type(k["rank"]) is not int:
            raise KeyringError("rank must be an integer")
        try:
            raw = b64d(k["public_key"])
        except ValueError:
            raise KeyringError("public_key is not valid base64") from None
        if len(raw) != 32:
            raise KeyringError("public_key must be 32 bytes")
        if keyid_of(raw) != k["keyid"]:
            raise KeyringError("keyid does not match public_key for %s" % k["label"])
        if k["keyid"] in out:
            raise KeyringError("duplicate keyid")
        if k["rank"] in ranks:
            raise KeyringError("duplicate rank")
        ranks.add(k["rank"])
        out[k["keyid"]] = {"rank": k["rank"], "raw": raw, "label": k["label"]}
    return out


# --------------------------------------------------------------------------
# sign
# --------------------------------------------------------------------------

def public_raw(priv: Ed25519PrivateKey) -> bytes:
    return priv.public_key().public_bytes(
        serialization.Encoding.Raw, serialization.PublicFormat.Raw)


def sign_envelope(payload: bytes, payload_type: str, private_keys) -> bytes:
    """Return the envelope file bytes. Payload bytes are signed exactly as given."""
    private_keys = list(private_keys)
    if not 1 <= len(private_keys) <= MAX_SIGNATURES:
        raise ToolError("need 1 to %d signing keys" % MAX_SIGNATURES)
    message = pae(payload_type, payload)
    sigs, seen = [], set()
    for k in private_keys:
        kid = keyid_of(public_raw(k))
        if kid in seen:
            raise ToolError("same key given twice")
        seen.add(kid)
        sigs.append({"keyid": kid, "sig": b64e(k.sign(message))})
    env = {"payloadType": payload_type, "payload": b64e(payload), "signatures": sigs}
    data = (json.dumps(env, indent=2) + "\n").encode("utf-8")
    if len(data) > MAX_ENVELOPE_BYTES:
        raise ToolError("envelope would be %d bytes, limit is %d" % (len(data), MAX_ENVELOPE_BYTES))
    return data


# --------------------------------------------------------------------------
# verify (FORMAT.md section 5)
# --------------------------------------------------------------------------

def _result(outcome, reason=None, state=None, signer=None, payload=None):
    return {"outcome": outcome, "reason": reason, "state": state,
            "signer": signer, "payload": payload}


def _reject(reason, signer=None, payload=None):
    return _result("rejected", reason, None, signer, payload)


def verify_envelope(data: bytes, payload_type: str, keyring: dict,
                    state: dict | None, now: datetime,
                    folders: UpdateFolders = OLD_FOLDERS) -> dict:
    ring = load_keyring(keyring)  # raises KeyringError on a bad bundled keyring

    # 1. size
    if len(data) > MAX_ENVELOPE_BYTES:
        return _reject("too_large")

    # 2. envelope shape
    try:
        env = strict_json_loads(data.decode("utf-8"))
    except (ValueError, RecursionError):
        return _reject("malformed")
    if not isinstance(env, dict):
        return _reject("malformed")
    ptype, b64payload, sigs = env.get("payloadType"), env.get("payload"), env.get("signatures")
    if not isinstance(ptype, str) or not isinstance(b64payload, str):
        return _reject("malformed")
    try:
        body = b64d(b64payload)
    except ValueError:
        return _reject("malformed")
    if not isinstance(sigs, list) or not 1 <= len(sigs) <= MAX_SIGNATURES:
        return _reject("malformed")
    parsed_sigs = []
    for s in sigs:
        if not isinstance(s, dict) or not isinstance(s.get("keyid"), str) \
                or not isinstance(s.get("sig"), str):
            return _reject("malformed")
        try:
            raw_sig = b64d(s["sig"])
        except ValueError:
            return _reject("malformed")
        if len(raw_sig) != 64:
            return _reject("malformed")
        parsed_sigs.append((s["keyid"], raw_sig))

    # 3. type
    if ptype != payload_type:
        return _reject("wrong_type")

    # 4. signature
    stored_revoked = set(state.get("revoked", [])) if state else set()
    trusted = {k: v for k, v in ring.items() if k not in stored_revoked}
    candidates = [(kid, sg) for kid, sg in parsed_sigs if kid in trusted]
    if not candidates:
        return _reject("unknown_key")
    message = pae(ptype, body)
    # The signer is the verifying signature of the highest rank, never simply the first: a
    # stolen lower-rank key must not be able to mask a higher-rank file's revocations.
    signer = None
    for kid, sg in candidates:
        try:
            Ed25519PublicKey.from_public_bytes(trusted[kid]["raw"]).verify(sg, message)
        except InvalidSignature:
            continue
        if signer is None or trusted[kid]["rank"] > trusted[signer]["rank"]:
            signer = kid
    if signer is None:
        return _reject("bad_signature")

    # 5. payload
    try:
        obj = strict_json_loads(body.decode("utf-8"))
    except (ValueError, RecursionError):
        return _reject("malformed", signer)
    problem = payload_problem(obj, ptype, folders)
    if problem:
        return _reject(problem, signer)

    # 6. expiry
    if parse_ts(obj["expires_at"]) <= now:
        return _reject("expired", signer, obj)

    # 7. revocations
    revoked = set(stored_revoked)
    signer_rank = ring[signer]["rank"]
    for k in obj.get("revoked_keys", []):
        if k in ring and ring[k]["rank"] < signer_rank:
            revoked.add(k)

    # 8. rollback
    digest = sha256_hex(body)
    # The serial is compared only while the stored file's signer is still trusted: a key that
    # was revoked or dropped from the keyring may have pushed it to the maximum.
    if state and state.get("keyid") in ring and state.get("keyid") not in revoked:
        if obj["serial"] < state["serial"]:
            return _reject("rollback", signer, obj)
        if obj["serial"] == state["serial"]:
            if digest != state["digest"]:
                return _reject("rollback", signer, obj)
            new_state = {"serial": state["serial"], "keyid": state["keyid"],
                         "digest": state["digest"], "revoked": sorted(revoked)}
            return _result("unchanged", None, new_state, signer, obj)

    # 9. accept
    new_state = {"serial": obj["serial"], "keyid": signer, "digest": digest,
                 "revoked": sorted(revoked)}
    return _result("accepted", None, new_state, signer, obj)


def check_state(state) -> dict:
    """Validate a stored-state object (raises ToolError)."""
    ok = (isinstance(state, dict)
          and type(state.get("serial")) is int and 1 <= state["serial"] <= MAX_SERIAL
          and isinstance(state.get("keyid"), str) and KEYID_RE.match(state["keyid"])
          and isinstance(state.get("digest"), str) and DIGEST_RE.match(state["digest"])
          and isinstance(state.get("revoked"), list)
          and all(isinstance(k, str) and KEYID_RE.match(k) for k in state["revoked"]))
    if not ok:
        raise ToolError("state file is not valid")
    return state


# --------------------------------------------------------------------------
# files
# --------------------------------------------------------------------------

def write_new_file(path: Path, data: bytes, mode: int) -> None:
    """Create path exclusively with the given mode; refuse to overwrite."""
    try:
        fd = os.open(str(path), os.O_WRONLY | os.O_CREAT | os.O_EXCL, mode)
    except FileExistsError:
        raise ToolError("refusing to overwrite existing file: %s" % path) from None
    with os.fdopen(fd, "wb") as f:
        f.write(data)


def write_file(path: Path, data: bytes) -> None:
    """Write via a temp file and rename, so a failure never leaves a truncated file."""
    fd, tmp = tempfile.mkstemp(dir=str(path.parent), prefix="." + path.name + ".", suffix=".tmp")
    try:
        with os.fdopen(fd, "wb") as f:
            f.write(data)
            f.flush()
            os.fsync(f.fileno())
        os.chmod(tmp, 0o644)
        os.replace(tmp, path)
    except BaseException:
        if os.path.exists(tmp):
            os.unlink(tmp)
        raise


def warn(msg: str) -> None:
    print("warning: " + msg, file=sys.stderr)


def load_private_key(path: str) -> Ed25519PrivateKey:
    p = Path(path)
    try:
        st = p.stat()
        pem = p.read_bytes()
    except OSError as e:
        raise ToolError("cannot read key file %s: %s" % (path, e.strerror)) from None
    if st.st_mode & 0o077:
        raise ToolError("key file %s is accessible by group/other (mode %o); chmod 600 it"
             % (path, st.st_mode & 0o777))
    try:
        key = serialization.load_pem_private_key(pem, password=None)
    except Exception:  # never include exception text: it could echo key bytes
        raise ToolError("key file %s is not a valid unencrypted PKCS#8 PEM key" % path) from None
    if not isinstance(key, Ed25519PrivateKey):
        raise ToolError("key file %s is not an Ed25519 key" % path)
    return key


def read_json_file(path: str, what: str):
    try:
        return strict_json_loads(Path(path).read_text(encoding="utf-8"))
    except OSError as e:
        raise ToolError("cannot read %s %s: %s" % (what, path, e.strerror)) from None
    except (ValueError, RecursionError):
        raise ToolError("%s %s is not valid JSON" % (what, path)) from None


# --------------------------------------------------------------------------
# commands
# --------------------------------------------------------------------------

def cmd_keygen(a) -> int:
    if not LABEL_RE.match(a.label):
        raise ToolError("label must match [a-z0-9][a-z0-9-]{0,31}")
    if a.rank < 1:
        raise ToolError("rank must be >= 1")
    d = Path(a.dir)
    if d.exists():
        if d.stat().st_mode & 0o077:
            warn("directory %s is accessible by group/other; consider chmod 700" % d)
    else:
        d.mkdir(mode=0o700, parents=True)
        os.chmod(d, 0o700)
    key_path, pub_path = d / (a.label + ".key"), d / (a.label + ".pub.json")
    if key_path.exists() or pub_path.exists():
        raise ToolError("refusing to overwrite existing key or pub file for label %s" % a.label)
    priv = Ed25519PrivateKey.generate()
    raw = public_raw(priv)
    pem = priv.private_bytes(serialization.Encoding.PEM,
                             serialization.PrivateFormat.PKCS8,
                             serialization.NoEncryption())
    write_new_file(key_path, pem, 0o600)
    pub = {"keyid": keyid_of(raw), "rank": a.rank, "public_key": b64e(raw), "label": a.label}
    write_new_file(pub_path, (json.dumps(pub, indent=2) + "\n").encode(), 0o644)
    print("label:      %s" % a.label)
    print("keyid:      %s" % pub["keyid"])
    print("public_key: %s" % pub["public_key"])
    print("key file:   %s" % key_path)
    print("pub file:   %s" % pub_path)
    return 0


def cmd_keyring(a) -> int:
    keys = []
    for p in a.pubs:
        k = read_json_file(p, "public key file")
        if not isinstance(k, dict) or set(k) != {"keyid", "rank", "public_key", "label"}:
            raise ToolError("%s: expected exactly keyid, rank, public_key, label" % p)
        if not isinstance(k["label"], str) or not LABEL_RE.match(k["label"]):
            raise ToolError("%s: invalid label" % p)
        keys.append(k)
    keys.sort(key=lambda k: k["rank"] if type(k["rank"]) is int else 0)
    ring = {"keys": keys}
    try:
        load_keyring(ring)  # schema, keyid derivation, unique ranks and keyids
    except KeyringError as e:
        raise ToolError("invalid keyring: %s" % e) from None
    write_file(Path(a.out), (json.dumps(ring, indent=2) + "\n").encode("utf-8"))
    print("wrote %s (%d keys)" % (a.out, len(keys)))
    return 0


def cmd_sign(a) -> int:
    try:
        payload = Path(a.payload).read_bytes()
    except OSError as e:
        raise ToolError("cannot read payload %s: %s" % (a.payload, e.strerror)) from None
    if a.type not in KNOWN_TYPES:
        raise ToolError("unknown --type %r; use public or update" % a.type)
    folders = update_folders(a)
    problem = validate_payload_bytes(payload, a.type, folders)
    if problem:
        raise ToolError("payload is not valid (%s)" % problem)
    if a.prev:
        check_newer_than(payload, a.prev)
    else:
        warn("no --prev given: make sure the serial is above the published file's")
    keys = [load_private_key(p) for p in a.key]
    try:
        ring = load_keyring(read_json_file(a.keyring, "keyring"))
    except KeyringError as e:
        raise ToolError("invalid keyring: %s" % e) from None
    for k in keys:
        kid = keyid_of(public_raw(k))
        if kid not in ring:
            raise ToolError("signing key %s is not in the keyring" % kid)
        if ring[kid]["rank"] != min(v["rank"] for v in ring.values()):
            warn("signing with %s (rank %d): a rotation key; use it only to replace the signing key"
                 % (ring[kid]["label"], ring[kid]["rank"]))
    data = sign_envelope(payload, a.type, keys)
    # Self-check: what clients will see, as a first-time client would, now.
    try:
        now = parse_ts(a.now) if a.now else datetime.now(timezone.utc)
    except ValueError:
        raise ToolError("--now must be YYYY-MM-DDTHH:MM:SSZ") from None
    r = verify_envelope(data, a.type, read_json_file(a.keyring, "keyring"), None, now, folders)
    if r["outcome"] != "accepted":
        raise ToolError("signed file does not verify (%s); nothing written" % r["reason"])
    write_file(Path(a.out), data)
    print("signed %s with %s -> %s (%d bytes)" % (
        a.payload, ",".join(keyid_of(public_raw(k)) for k in keys), a.out, len(data)))
    return 0


def check_newer_than(payload: bytes, prev_path: str) -> None:
    """Refuse a payload whose serial is not above the previously published file's."""
    try:
        env = strict_json_loads(Path(prev_path).read_text(encoding="utf-8"))
        prev = strict_json_loads(b64d(env["payload"]).decode("utf-8"))
        prev_serial = prev["serial"]
        serial = strict_json_loads(payload.decode("utf-8"))["serial"]
    except OSError as e:
        raise ToolError("cannot read previous envelope %s: %s" % (prev_path, e.strerror)) from None
    except (ValueError, KeyError, TypeError, RecursionError):
        raise ToolError("cannot read the serial of the payload or of %s" % prev_path) from None
    if type(serial) is not int or type(prev_serial) is not int or serial <= prev_serial:
        raise ToolError("serial %r is not above the published serial %r (clients would reject it "
                        "as rollback)" % (serial, prev_serial))


def cmd_verify(a) -> int:
    ring = read_json_file(a.keyring, "keyring")
    try:
        data = Path(a.envelope).read_bytes()
    except OSError as e:
        raise ToolError("cannot read envelope %s: %s" % (a.envelope, e.strerror)) from None
    if a.now:
        try:
            now = parse_ts(a.now)
        except ValueError:
            raise ToolError("--now must be YYYY-MM-DDTHH:MM:SSZ") from None
    else:
        now = datetime.now(timezone.utc)
    state = check_state(read_json_file(a.state, "state")) if a.state else None
    try:
        r = verify_envelope(data, a.type, ring, state, now, update_folders(a))
    except KeyringError as e:
        raise ToolError("invalid keyring: %s" % e) from None
    if r["outcome"] == "rejected":
        print("rejected:%s" % r["reason"])
    else:
        print(r["outcome"])
    if r["signer"]:
        print("signer:  %s" % r["signer"])
    if r["payload"]:
        print("serial:  %s" % r["payload"]["serial"])
        print("issued:  %s" % r["payload"]["issued_at"])
        print("expires: %s" % r["payload"]["expires_at"])
    if r["outcome"] != "rejected":
        if a.write_state:
            write_file(Path(a.write_state),
                       (json.dumps(r["state"], indent=2) + "\n").encode("utf-8"))
        return 0
    return 1


def cmd_show(a) -> int:
    try:
        env = strict_json_loads(Path(a.envelope).read_text(encoding="utf-8"))
        body = b64d(env["payload"])
        text = body.decode("utf-8")
    except OSError as e:
        raise ToolError("cannot read envelope: %s" % e.strerror) from None
    except (ValueError, KeyError, TypeError, RecursionError):
        raise ToolError("envelope is malformed; cannot decode payload") from None
    print("warning: payload shown WITHOUT verification", file=sys.stderr)
    # Unverified text: escape controls so a payload cannot drive the terminal.
    safe = "".join(c if c in "\n\t" or not (ord(c) < 0x20 or 0x7f <= ord(c) <= 0x9f)
                   else "\\u%04x" % ord(c) for c in text)
    sys.stdout.write(safe if safe.endswith("\n") else safe + "\n")
    return 0


def update_folders(a) -> UpdateFolders:
    """--app-config: update-v2.json's folders; without it update.json's (OLD_FOLDERS)."""
    return UpdateFolders.from_app_config(a.app_config) if a.app_config else OLD_FOLDERS


def type_arg(value: str) -> str:
    return TYPE_ALIASES.get(value, value)


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="btlabs_sign", description=__doc__.splitlines()[0])
    sub = p.add_subparsers(dest="cmd", required=True)

    k = sub.add_parser("keygen", help="generate an Ed25519 signing key")
    k.add_argument("--dir", required=True)
    k.add_argument("--label", required=True)
    k.add_argument("--rank", required=True, type=int)
    k.set_defaults(fn=cmd_keygen)

    r = sub.add_parser("keyring", help="build a keyring from .pub.json files")
    r.add_argument("pubs", nargs="+", metavar="PUB.json")
    r.add_argument("--out", required=True)
    r.set_defaults(fn=cmd_keyring)

    s = sub.add_parser("sign", help="sign a payload into a DSSE envelope")
    s.add_argument("--key", action="append", required=True)
    s.add_argument("--payload", required=True)
    s.add_argument("--type", type=type_arg, default=PUBLIC_TYPE,
                   help="public (default) or update, or the full payload type")
    s.add_argument("--out", required=True)
    s.add_argument("--keyring", required=True)
    s.add_argument("--prev", help="the published envelope; refuse unless the serial is higher")
    s.add_argument("--now", help="clock for the self-check (tests); default: the real time")
    s.add_argument("--app-config", dest="app_config",
                   help="update-v2.json: the links' folders from [updates] of this app-config.toml "
                        "(default: update.json's old folders)")
    s.set_defaults(fn=cmd_sign)

    v = sub.add_parser("verify", help="verify an envelope (FORMAT.md section 5)")
    v.add_argument("--keyring", required=True)
    v.add_argument("--envelope", required=True)
    v.add_argument("--type", type=type_arg, default=PUBLIC_TYPE,
                   help="public (default) or update, or the full payload type")
    v.add_argument("--now")
    v.add_argument("--app-config", dest="app_config",
                   help="update-v2.json: the links' folders from [updates] of this app-config.toml "
                        "(default: update.json's old folders)")
    v.add_argument("--state")
    v.add_argument("--write-state", dest="write_state")
    v.set_defaults(fn=cmd_verify)

    sh = sub.add_parser("show", help="print the decoded payload (NOT verified)")
    sh.add_argument("--envelope", required=True)
    sh.set_defaults(fn=cmd_show)
    return p


def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    try:
        return args.fn(args)
    except ToolError as e:
        print("error: %s" % e, file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
