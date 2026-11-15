#!/usr/bin/env python3
"""Signed wallet announcements: build, sign, verify and publish the feed.

Spec: the announcements design (sections 2, 6, 8). Envelope, keys and client rule:
btlabs-public FORMAT.md (section 1, 2, 3, 5). Run with `python3 -I`.
The functions for the envelope (pae, keyid_of, strict base64 and JSON, the text rule, the key
loader) follow btlabs-public/tool/btlabs_sign.py. Private key bytes are never printed.
"""
from __future__ import annotations

import argparse
import base64
import binascii
import hashlib
import json
import os
import re
import secrets
import shlex
import struct
import subprocess
import sys
import tempfile
import urllib.request
import zlib
from datetime import datetime, timedelta, timezone
from pathlib import Path

from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey, Ed25519PublicKey

PAYLOAD_TYPE = "application/vnd.btlabs.wallet-for-epic.announcements+json"
PUBLIC_TYPE = "application/vnd.btlabs.public+json"
MAX_ENVELOPE_BYTES = 65536
MAX_SIGNATURES = 8
MAX_SERIAL = 2**53 - 1
MAX_MESSAGES = 4
MAX_VALIDITY = timedelta(days=45)
MAX_TEXT, MAX_LABEL, MAX_URL = 140, 24, 512
MAX_PNG_BYTES = 8192
PNG_MIN_PX, PNG_MAX_PX = 32, 192

DEFAULT_TARGET = "test"
DEFAULT_DIR = "~/.config/btlabs/announcements-test"
SOURCE_NAME = "feed.payload.json"
ENVELOPE_NAME = "announcements.json"
KEY_NAME = "ann-test-a.key"
KEYRING_NAME = "announcements-keyring.json"
SERIAL_NAME = ".last-signed-serial"
TEST_FEED_URL = "https://examples.btlabs.uk/epic/announcements-test/announcements.json"
TEST_HOST = "demo-vps"
TEST_REMOTE_PATH = "/srv/examples/epic/announcements-test/announcements.json"
# Production (the owner 2026-11-11): key btlabs-ann-2026-a beside the release key, rank-2
# btlabs-ann-2026-b offline; the feed in the BT Labs Pages repository beside btlabs.json, read as
# the raw file on main (reachable through Tor exits).
PROD_DIR = "~/.config/btlabs/announcements"
PROD_KEY = "~/.config/btlabs/signing/btlabs-ann-2026-a.key"
PROD_SITE = "~/code/btlabs-epic.github.io"
PROD_REPO = "BTLabsUK/btlabs-epic.github.io"
PROD_FEED_URL = "https://raw.githubusercontent.com/%s/main/announcements.json" % PROD_REPO
TOOLS_DIR = Path(__file__).resolve().parent.parent

TS_RE = re.compile(
    r"([0-9]{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])"
    r"T([01][0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])Z\Z")
ID_RE = re.compile(r"[a-z0-9][a-z0-9-]{0,31}\Z")
KEYID_RE = re.compile(r"[0-9a-f]{16}\Z")
HTTPS_RE = re.compile(r"https://[a-z0-9.-]+(:[0-9]{1,5})?(/[\x21-\x7e]*)?\Z")
EPIC_RE = re.compile(r"epic:[\x21-\x7e]*\Z")
# FORMAT.md section 3: C0/C1 controls and DEL, zero-width and direction marks, bidi
# embeddings and isolates, line/paragraph separators, BOM.
BAD_TEXT_RE = re.compile("[\u0000-\u001f\u007f-\u009f​-‏  "
                         "‪-‮⁦-⁩﻿\ud800-\udfff]")
PLATFORMS = ("desktop", "phone")
PNG_SIG = b"\x89PNG\r\n\x1a\n"


class ToolError(Exception):
    """User-facing error. Never contains key material."""


# ---------------------------------------------------------------- primitives

def pae(payload_type: str, body: bytes) -> bytes:
    t = payload_type.encode("utf-8")
    return b"DSSEv1 %d %s %d %s" % (len(t), t, len(body), body)


def keyid_of(raw_pub: bytes) -> str:
    return hashlib.sha256(raw_pub).hexdigest()[:16]


def b64e(raw: bytes) -> str:
    return base64.b64encode(raw).decode("ascii")


def b64d(s) -> bytes:
    """Strict standard base64 with padding, canonical bits only."""
    if not isinstance(s, str) or len(s) % 4 != 0:
        raise ValueError("bad base64")
    try:
        raw = base64.b64decode(s, validate=True)
    except (binascii.Error, ValueError):
        raise ValueError("bad base64") from None
    if base64.b64encode(raw).decode("ascii") != s:
        raise ValueError("bad base64")
    return raw


def parse_ts(s) -> datetime:
    if not isinstance(s, str):
        raise ValueError("bad timestamp")
    m = TS_RE.match(s)
    if not m:
        raise ValueError("bad timestamp")
    y, mo, d, h, mi, se = (int(x) for x in m.groups())
    return datetime(y, mo, d, h, mi, se, tzinfo=timezone.utc)


def fmt_ts(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def now_utc() -> datetime:
    return datetime.now(timezone.utc).replace(microsecond=0)


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
    return json.loads(text, object_pairs_hook=_no_dupes, parse_constant=_no_const)


def public_raw(priv: Ed25519PrivateKey) -> bytes:
    return priv.public_key().public_bytes(serialization.Encoding.Raw, serialization.PublicFormat.Raw)


def load_private_key(path) -> Ed25519PrivateKey:
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
    except Exception:  # never echo exception text: it could contain key bytes
        raise ToolError("key file %s is not a valid unencrypted PKCS#8 PEM key" % path) from None
    if not isinstance(key, Ed25519PrivateKey):
        raise ToolError("key file %s is not an Ed25519 key" % path)
    return key


def load_keyring(keyring) -> dict:
    """Validate a keyring object; return {keyid: {rank, raw, label}}."""
    if not isinstance(keyring, dict) or not isinstance(keyring.get("keys"), list) or not keyring["keys"]:
        raise ToolError("keyring: needs a non-empty keys list")
    out, ranks = {}, set()
    for k in keyring["keys"]:
        if not isinstance(k, dict) or not isinstance(k.get("label"), str) \
                or not isinstance(k.get("keyid"), str) or type(k.get("rank")) is not int \
                or k["rank"] < 1:
            raise ToolError("keyring: bad entry")
        try:
            raw = b64d(k.get("public_key"))
        except ValueError:
            raise ToolError("keyring: public_key is not valid base64") from None
        if len(raw) != 32 or keyid_of(raw) != k["keyid"]:
            raise ToolError("keyring: keyid does not match public_key for %s" % k["label"])
        if k["keyid"] in out or k["rank"] in ranks:
            raise ToolError("keyring: duplicate keyid or rank")
        ranks.add(k["rank"])
        out[k["keyid"]] = {"rank": k["rank"], "raw": raw, "label": k["label"]}
    return out


def read_json_file(path, what):
    try:
        return strict_json_loads(Path(path).read_text(encoding="utf-8"))
    except OSError as e:
        raise ToolError("cannot read %s %s: %s" % (what, path, e.strerror)) from None
    except (ValueError, RecursionError):
        raise ToolError("%s %s is not valid JSON" % (what, path)) from None


def write_file(path: Path, data: bytes, mode: int = 0o644) -> None:
    """Write via a temp file and rename."""
    fd, tmp = tempfile.mkstemp(dir=str(path.parent), prefix="." + path.name + ".", suffix=".tmp")
    try:
        with os.fdopen(fd, "wb") as f:
            f.write(data)
            f.flush()
            os.fsync(f.fileno())
        os.chmod(tmp, mode)
        os.replace(tmp, path)
    except BaseException:
        if os.path.exists(tmp):
            os.unlink(tmp)
        raise


# ---------------------------------------------------------------- field rules (spec 2, 6)

def text_problem(s, max_len: int, what: str) -> str | None:
    if not isinstance(s, str):
        return "%s must be a string" % what
    if not 1 <= len(s) <= max_len:
        return "%s must be 1 to %d characters (it has %d)" % (what, max_len, len(s))
    if BAD_TEXT_RE.search(s):
        return "%s has a control, line break, zero-width, direction or separator character" % what
    if s != s.strip():
        return "%s has leading or trailing white space" % what
    return None


def url_problem(u) -> str | None:
    if not isinstance(u, str):
        return "link url must be a string"
    if len(u) > MAX_URL:
        return "link url is longer than %d characters" % MAX_URL
    if HTTPS_RE.match(u) or EPIC_RE.match(u):
        return None
    return "link url must be https (lower-case host, printable ASCII path) or an epic: URI " \
           "of printable ASCII without spaces"


def png_problem(raw: bytes) -> str | None:
    """PNG signature, IHDR square 32..192 px, at most 8192 bytes."""
    if len(raw) > MAX_PNG_BYTES:
        return "image is %d bytes, limit is %d" % (len(raw), MAX_PNG_BYTES)
    if len(raw) < 33 or raw[:8] != PNG_SIG:
        return "image is not a PNG"
    length, ctype = struct.unpack(">I4s", raw[8:16])
    if length != 13 or ctype != b"IHDR":
        return "image has no IHDR chunk first"
    if zlib.crc32(raw[12:29]) & 0xFFFFFFFF != struct.unpack(">I", raw[29:33])[0]:
        return "image IHDR checksum is wrong"
    w, h = struct.unpack(">II", raw[16:24])
    if w != h:
        return "image must be square (it is %dx%d)" % (w, h)
    if not PNG_MIN_PX <= w <= PNG_MAX_PX:
        return "image must be %d to %d px (it is %d)" % (PNG_MIN_PX, PNG_MAX_PX, w)
    return None


def png_px(raw: bytes) -> int:
    return struct.unpack(">I", raw[16:20])[0]


def message_problem(m) -> str | None:
    """Every rule of spec section 2 for one message; None if fine."""
    if not isinstance(m, dict):
        return "message must be an object"
    mid = m.get("id")
    if not isinstance(mid, str) or not ID_RE.match(mid):
        return "id must match [a-z0-9][a-z0-9-]{0,31}"
    p = text_problem(m.get("text"), MAX_TEXT, "text")
    if p:
        return p
    if "link" in m:
        link = m["link"]
        if not isinstance(link, dict):
            return "link must be an object"
        p = text_problem(link.get("label"), MAX_LABEL, "link label") or url_problem(link.get("url"))
        if p:
            return p
    if "image" in m:
        img = m["image"]
        if not isinstance(img, dict):
            return "image must be an object"
        try:
            raw = b64d(img.get("png"))
        except ValueError:
            return "image png is not valid base64"
        p = png_problem(raw)
        if p:
            return p
    starts = ends = None
    for k in ("starts_at", "ends_at"):
        if k in m:
            try:
                t = parse_ts(m[k])
            except ValueError:
                return "%s must be YYYY-MM-DDTHH:MM:SSZ" % k
            if k == "starts_at":
                starts = t
            else:
                ends = t
    if starts and ends and not starts < ends:
        return "starts_at must be before ends_at"
    if "platforms" in m:
        pl = m["platforms"]
        if not isinstance(pl, list) or not all(isinstance(x, str) and x in PLATFORMS for x in pl):
            return "platforms must be a subset of desktop, phone"
    return None


def message_state(m, now: datetime) -> str:
    if "ends_at" in m and parse_ts(m["ends_at"]) <= now:
        return "ended"
    if "starts_at" in m and parse_ts(m["starts_at"]) > now:
        return "scheduled"
    return "live"


def payload_problem(obj) -> str | None:
    """'malformed' / 'unsupported_schema' or None (client step 5, announcements payload)."""
    if not isinstance(obj, dict):
        return "malformed"
    sch = obj.get("schema")
    if type(sch) is not int:
        return "malformed"
    if sch != 1:
        return "unsupported_schema"
    ser = obj.get("serial")
    if type(ser) is not int or not 1 <= ser <= MAX_SERIAL:
        return "malformed"
    try:
        issued, expires = parse_ts(obj.get("issued_at")), parse_ts(obj.get("expires_at"))
    except ValueError:
        return "malformed"
    if not expires > issued or expires - issued > MAX_VALIDITY:
        return "malformed"
    msgs = obj.get("messages")
    if not isinstance(msgs, list) or len(msgs) > MAX_MESSAGES:
        return "malformed"
    ids = set()
    for m in msgs:
        if message_problem(m):
            return "malformed"
        if m["id"] in ids:
            return "malformed"
        ids.add(m["id"])
    if "revoked_keys" in obj:
        rk = obj["revoked_keys"]
        if not isinstance(rk, list) or not all(isinstance(k, str) and KEYID_RE.match(k) for k in rk):
            return "malformed"
    return None


# ---------------------------------------------------------------- sign / verify

def sign_envelope(payload: bytes, payload_type: str, private_keys) -> bytes:
    message = pae(payload_type, payload)
    sigs = [{"keyid": keyid_of(public_raw(k)), "sig": b64e(k.sign(message))} for k in private_keys]
    env = {"payloadType": payload_type, "payload": b64e(payload), "signatures": sigs}
    return (json.dumps(env, indent=2) + "\n").encode("utf-8")


def verify_envelope(data: bytes, keyring: dict, now: datetime, state: dict | None = None,
                    payload_type: str = PAYLOAD_TYPE) -> dict:
    """FORMAT.md section 5 steps 1-9. Returns {outcome, reason, payload, signer, state}."""
    ring = load_keyring(keyring)

    def rej(reason, signer=None, payload=None):
        return {"outcome": "rejected", "reason": reason, "payload": payload, "signer": signer,
                "state": None}

    if len(data) > MAX_ENVELOPE_BYTES:
        return rej("too_large")
    try:
        env = strict_json_loads(data.decode("utf-8"))
    except (ValueError, RecursionError):
        return rej("malformed")
    if not isinstance(env, dict):
        return rej("malformed")
    ptype, b64p, sigs = env.get("payloadType"), env.get("payload"), env.get("signatures")
    if not isinstance(ptype, str) or not isinstance(b64p, str):
        return rej("malformed")
    try:
        body = b64d(b64p)
    except ValueError:
        return rej("malformed")
    if not isinstance(sigs, list) or not 1 <= len(sigs) <= MAX_SIGNATURES:
        return rej("malformed")
    parsed = []
    for s in sigs:
        if not isinstance(s, dict) or not isinstance(s.get("keyid"), str) \
                or not isinstance(s.get("sig"), str):
            return rej("malformed")
        try:
            raw_sig = b64d(s["sig"])
        except ValueError:
            return rej("malformed")
        if len(raw_sig) != 64:
            return rej("malformed")
        parsed.append((s["keyid"], raw_sig))
    if ptype != payload_type:
        return rej("wrong_type")
    stored_revoked = set(state.get("revoked", [])) if state else set()
    trusted = {k: v for k, v in ring.items() if k not in stored_revoked}
    cands = [(kid, sg) for kid, sg in parsed if kid in trusted]
    if not cands:
        return rej("unknown_key")
    message = pae(ptype, body)
    signer = None
    for kid, sg in cands:
        try:
            Ed25519PublicKey.from_public_bytes(trusted[kid]["raw"]).verify(sg, message)
        except InvalidSignature:
            continue
        if signer is None or trusted[kid]["rank"] > trusted[signer]["rank"]:
            signer = kid
    if signer is None:
        return rej("bad_signature")
    try:
        obj = strict_json_loads(body.decode("utf-8"))
    except (ValueError, RecursionError):
        return rej("malformed", signer)
    problem = payload_problem(obj)
    if problem:
        return rej(problem, signer)
    if parse_ts(obj["expires_at"]) <= now:
        return rej("expired", signer, obj)
    revoked = set(stored_revoked)
    for k in obj.get("revoked_keys", []):
        if k in ring and ring[k]["rank"] < ring[signer]["rank"]:
            revoked.add(k)
    digest = hashlib.sha256(body).hexdigest()
    if state and state.get("keyid") in ring and state.get("keyid") not in revoked:
        if obj["serial"] < state["serial"]:
            return rej("rollback", signer, obj)
        if obj["serial"] == state["serial"]:
            if digest != state["digest"]:
                return rej("rollback", signer, obj)
            return {"outcome": "unchanged", "reason": None, "payload": obj, "signer": signer,
                    "state": {**state, "revoked": sorted(revoked)}}
    return {"outcome": "accepted", "reason": None, "payload": obj, "signer": signer,
            "state": {"serial": obj["serial"], "keyid": signer, "digest": digest,
                      "revoked": sorted(revoked)}}


def build_payload(source: dict, now: datetime, days: int, serial: int, revoke=()) -> bytes:
    """The payload bytes to sign: issued now, serial = Unix seconds, ended messages dropped."""
    if not 1 <= days <= 45:
        raise ToolError("--days must be 1 to 45")
    msgs = [m for m in source.get("messages", []) if message_state(m, now) != "ended"]
    for m in msgs:
        p = message_problem(m)
        if p:
            raise ToolError("message %r: %s" % (m.get("id") if isinstance(m, dict) else m, p))
    ids = [m["id"] for m in msgs]
    if len(ids) != len(set(ids)):
        raise ToolError("duplicate message id")
    if len(msgs) > MAX_MESSAGES:
        raise ToolError("%d messages, at most %d allowed" % (len(msgs), MAX_MESSAGES))
    revoked = list(source.get("revoked_keys", [])) + [k for k in revoke if k not in source.get("revoked_keys", [])]
    for k in revoked:
        if not isinstance(k, str) or not KEYID_RE.match(k):
            raise ToolError("revoked key id must be 16 lower-case hex characters")
    payload = {"schema": 1, "serial": serial, "issued_at": fmt_ts(now),
               "expires_at": fmt_ts(now + timedelta(days=days)), "messages": msgs,
               "revoked_keys": revoked}
    return (json.dumps(payload, indent=2, ensure_ascii=False) + "\n").encode("utf-8")


def sign_feed(d: Path, now: datetime, days: int, keyfile=None, revoke=(), source_path=None) -> bytes:
    """Whole sign step: validate, sign, verify (spec section 5), size check, write the envelope."""
    src_path = Path(source_path) if source_path else d / SOURCE_NAME
    source = read_json_file(src_path, "source")
    if not isinstance(source, dict) or not isinstance(source.get("messages", []), list):
        raise ToolError("source must be an object with a messages list")
    serial_path = d / SERIAL_NAME
    last = 0
    if serial_path.exists():
        try:
            last = int(serial_path.read_text().strip())
        except ValueError:
            raise ToolError("%s is not a number" % serial_path) from None
    serial = int(now.timestamp())
    if serial <= last:
        raise ToolError("serial %d is not above the last signed serial %d (wait a second or check "
                        "the clock)" % (serial, last))
    payload = build_payload(source, now, days, serial, revoke)
    live = sum(1 for m in json.loads(payload)["messages"] if message_state(m, now) == "live")
    if live > MAX_MESSAGES:
        raise ToolError("more than %d live messages" % MAX_MESSAGES)
    keyring = read_json_file(d / KEYRING_NAME, "keyring")
    ring = load_keyring(keyring)
    key = load_private_key(keyfile or d / KEY_NAME)
    kid = keyid_of(public_raw(key))
    if kid not in ring:
        raise ToolError("signing key %s is not in the keyring" % kid)
    if ring[kid]["rank"] != min(v["rank"] for v in ring.values()):
        raise ToolError("signing key %s is not the rank-1 key" % kid)
    data = sign_envelope(payload, PAYLOAD_TYPE, [key])
    if len(data) > MAX_ENVELOPE_BYTES:
        raise ToolError("envelope would be %d bytes, limit is %d" % (len(data), MAX_ENVELOPE_BYTES))
    r = verify_envelope(data, keyring, now)
    if r["outcome"] != "accepted":
        raise ToolError("signed file does not verify (%s); nothing written" % r["reason"])
    write_file(d / ENVELOPE_NAME, data)
    write_file(serial_path, (str(serial) + "\n").encode())
    # keep the source tidy: ended messages are gone from the feed
    source["messages"] = [m for m in source["messages"] if message_state(m, now) != "ended"]
    write_file(src_path, source_bytes(source))
    return data


def source_bytes(source: dict) -> bytes:
    return (json.dumps(source, indent=2, ensure_ascii=False) + "\n").encode("utf-8")


# ---------------------------------------------------------------- commands

def target_dir(a, target=None) -> Path:
    """--dir, else the folder of the target (--target, default test)."""
    if a.dir:
        return Path(os.path.expanduser(a.dir))
    return Path(os.path.expanduser(PROD_DIR if (target or a.target) == "prod" else DEFAULT_DIR))


def paths(a):
    d = target_dir(a)
    return d, Path(os.path.expanduser(a.source)) if a.source else d / SOURCE_NAME


def load_source(p: Path, create=False) -> dict:
    if not p.exists():
        if create:
            return {"messages": []}
        raise ToolError("source %s does not exist; add a message first" % p)
    s = read_json_file(p, "source")
    if not isinstance(s, dict) or not isinstance(s.get("messages"), list):
        raise ToolError("source %s needs a messages list" % p)
    return s


def cmd_add(a) -> int:
    d, src = paths(a)
    source = load_source(src, create=True)
    now = now_utc()
    if any(isinstance(m, dict) and m.get("id") == a.id for m in source["messages"]):
        raise ToolError("id %r is already in the source (a changed text needs a new id)" % a.id)
    if sum(1 for m in source["messages"] if message_state(m, now) != "ended") >= MAX_MESSAGES:
        raise ToolError("already %d live or scheduled messages; remove one first" % MAX_MESSAGES)
    if not 1 <= a.days <= 365:
        raise ToolError("--days must be 1 to 365")
    m: dict = {"id": a.id, "text": a.text}
    if a.link_label is not None or a.link_url is not None:
        if a.link_label is None or a.link_url is None:
            raise ToolError("--link-label and --link-url go together")
        m["link"] = {"label": a.link_label, "url": a.link_url}
    if a.image:
        try:
            raw = Path(os.path.expanduser(a.image)).read_bytes()
        except OSError as e:
            raise ToolError("cannot read image: %s" % e.strerror) from None
        m["image"] = {"png": b64e(raw)}
    try:
        start = parse_ts(a.starts) if a.starts else None
    except ValueError:
        raise ToolError("--starts must be YYYY-MM-DDTHH:MM:SSZ") from None
    if start:
        m["starts_at"] = fmt_ts(start)
    m["ends_at"] = fmt_ts((start or now) + timedelta(days=a.days))
    if a.platforms:
        pl = [x.strip() for x in a.platforms.split(",")]
        m["platforms"] = pl
    p = message_problem(m)
    if p:
        raise ToolError(p)
    source["messages"].append(m)
    d.mkdir(parents=True, exist_ok=True)
    write_file(src, source_bytes(source))
    print("added %s (%s, ends %s)" % (a.id, message_state(m, now), m["ends_at"]))
    return 0


def cmd_remove(a) -> int:
    d, src = paths(a)
    source = load_source(src)
    keep = [m for m in source["messages"] if not (isinstance(m, dict) and m.get("id") == a.id)]
    if len(keep) == len(source["messages"]):
        raise ToolError("id %r not found" % a.id)
    source["messages"] = keep
    write_file(src, source_bytes(source))
    print("removed %s" % a.id)
    return 0


def cmd_list(a) -> int:
    d, src = paths(a)
    source = load_source(src)
    now = now_utc()
    if not source["messages"]:
        print("(no messages)")
    for m in source["messages"]:
        link = m.get("link")
        img = "none"
        if "image" in m:
            try:
                raw = b64d(m["image"]["png"])
                img = "%d bytes, %d px" % (len(raw), png_px(raw)) if len(raw) >= 24 else "broken"
            except (ValueError, KeyError, TypeError):
                img = "broken"
        print("%s  [%s]" % (m.get("id"), message_state(m, now)))
        print("  text:  %s" % m.get("text"))
        print("  link:  %s" % ("%s -> %s" % (link.get("label"), link.get("url")) if link else "none"))
        print("  image: %s" % img)
        print("  time:  %s .. %s  platforms: %s" % (m.get("starts_at", "now"), m.get("ends_at", "-"),
                                                   ",".join(m.get("platforms", PLATFORMS))))
    return 0


def cmd_sign(a) -> int:
    d, src = paths(a)
    key = a.key or (os.path.expanduser(PROD_KEY) if a.target == "prod" else None)
    data = sign_feed(d, now_utc(), a.days, key, a.revoke or (), src)
    print("signed -> %s (%d bytes)" % (d / ENVELOPE_NAME, len(data)))
    return 0


def print_result(r) -> None:
    if r["outcome"] == "rejected":
        print("rejected: %s" % r["reason"])
        return
    p = r["payload"]
    print("%s, signer %s" % (r["outcome"], r["signer"]))
    print("serial %s, issued %s, expires %s, %d message(s)"
          % (p["serial"], p["issued_at"], p["expires_at"], len(p["messages"])))
    now = now_utc()
    for m in p["messages"]:
        link = m.get("link")
        img = ""
        if "image" in m:
            raw = b64d(m["image"]["png"])
            img = " image %dpx/%dB" % (png_px(raw), len(raw))
        print("  %s [%s] %s%s%s" % (m["id"], message_state(m, now), m["text"],
                                    " | %s %s" % (link["label"], link["url"]) if link else "", img))


def fetch(url: str) -> bytes:
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req, timeout=30) as resp:
        return resp.read(MAX_ENVELOPE_BYTES + 1)


def cmd_verify(a) -> int:
    d = target_dir(a)
    keyring = read_json_file(Path(os.path.expanduser(a.keyring)) if a.keyring else d / KEYRING_NAME,
                             "keyring")
    if a.url:
        try:
            data = fetch(a.url)
        except OSError as e:
            raise ToolError("cannot fetch %s: %s" % (a.url, e)) from None
    elif a.envelope:
        try:
            data = Path(os.path.expanduser(a.envelope)).read_bytes()
        except OSError as e:
            raise ToolError("cannot read envelope: %s" % e.strerror) from None
    else:
        raise ToolError("give --envelope FILE or --url URL")
    r = verify_envelope(data, keyring, now_utc())
    print_result(r)
    return 1 if r["outcome"] == "rejected" else 0


def cmd_publish(a) -> int:
    if a.target != DEFAULT_TARGET and a.target != a.publish_target:
        raise ToolError("--target %s before the command and publish --target %s differ"
                        % (a.target, a.publish_target))
    d = target_dir(a, a.publish_target)
    env_path = d / ENVELOPE_NAME
    try:
        local = env_path.read_bytes()
    except OSError as e:
        raise ToolError("no signed envelope (%s): run sign first" % e.strerror) from None
    keyring = read_json_file(d / KEYRING_NAME, "keyring")
    r = verify_envelope(local, keyring, now_utc())
    if r["outcome"] == "rejected":
        raise ToolError("local envelope does not verify (%s); not publishing" % r["reason"])
    if a.publish_target == "prod":
        return publish_prod(local, keyring, a)
    tmp = "announcements-%s.json" % secrets.token_hex(6)
    subprocess.run(["scp", "-q", str(env_path), "%s:%s" % (TEST_HOST, tmp)], check=True, timeout=120)
    remote = "sudo install -D -m 644 -o root -g root %s %s && rm %s" % (
        shlex.quote(tmp), shlex.quote(TEST_REMOTE_PATH), shlex.quote(tmp))
    subprocess.run(["ssh", TEST_HOST, remote], check=True, timeout=120)
    try:
        got = fetch(TEST_FEED_URL)
    except OSError as e:
        raise ToolError("copied, but cannot fetch %s: %s" % (TEST_FEED_URL, e)) from None
    if got != local:
        raise ToolError("fetched bytes differ from the local envelope")
    r = verify_envelope(got, keyring, now_utc())
    if r["outcome"] == "rejected":
        raise ToolError("fetched file does not verify (%s)" % r["reason"])
    print("published %s (%d bytes), fetched copy identical and verified" % (TEST_FEED_URL, len(got)))
    return 0


def git(*args, cwd=None, capture=False) -> str:
    r = subprocess.run(["git", *args], cwd=cwd, check=True, timeout=300, text=True,
                       stdout=subprocess.PIPE if capture else None,
                       env=dict(os.environ, GIT_TERMINAL_PROMPT="0"))
    return (r.stdout or "").strip()


def check_fetched(url: str, local: bytes, keyring) -> str | None:
    """None when url serves exactly `local` and it verifies; else why not."""
    try:
        got = fetch(url)
    except OSError as e:
        return "cannot fetch: %s" % e
    if got != local:
        return "serves other bytes (cache?)"
    r = verify_envelope(got, keyring, now_utc())
    return "does not verify (%s)" % r["reason"] if r["outcome"] == "rejected" else None


def publish_prod(local: bytes, keyring, a) -> int:
    """Commit announcements.json to the Pages repository and push it to GitHub the way
    tools/publish-update-json.sh does: a cleaned bare copy (mailmap addresses, no co-author or
    generated-with trailers) through tools/push-github.sh, fast-forward only. Then read it back."""
    site = Path(os.path.expanduser(a.site or PROD_SITE))
    if not (site / "btlabs.json").is_file():
        raise ToolError("%s is not the Pages repository (no btlabs.json)" % site)
    if git("status", "--porcelain", "--", "announcements.json", cwd=site, capture=True):
        raise ToolError("%s/announcements.json has uncommitted changes" % site)
    serial = json.loads(b64d(json.loads(local)["payload"]))["serial"]
    write_file(site / "announcements.json", local)
    git("add", "announcements.json", cwd=site)
    if git("status", "--porcelain", "--", "announcements.json", cwd=site, capture=True):
        git("commit", "-q", "-m", "announcements.json serial %d" % serial, cwd=site)
    with tempfile.TemporaryDirectory() as work:
        pub = Path(work) / "pub.git"
        git("clone", "-q", "--bare", "--no-local", str(site), str(pub))
        callback = ('import re\n'
                    'keep = [l for l in message.split(b"\\n") if not re.match('
                    'rb"(?i)(co-authored-by:|.*generated with )", l.strip())]\n'
                    'return b"\\n".join(keep).rstrip(b"\\n") + b"\\n"')
        git("-C", str(pub), "filter-repo", "--force", "--quiet", "--mailmap",
            str(TOOLS_DIR / "publish" / "mailmap"), "--message-callback", callback)
        commit = git("-C", str(pub), "rev-parse", "main", capture=True)
        subprocess.run([str(TOOLS_DIR / "push-github.sh"), PROD_REPO.split("/")[1], str(pub)],
                       check=True, timeout=600)
    # raw.githubusercontent.com caches main for a few minutes: the pushed commit's own URL shows
    # whether the push landed.
    why = check_fetched(PROD_FEED_URL, local, keyring)
    if why is None:
        print("published %s (%d bytes), fetched copy identical and verified" % (PROD_FEED_URL, len(local)))
        return 0
    at = "https://raw.githubusercontent.com/%s/%s/announcements.json" % (PROD_REPO, commit)
    why2 = check_fetched(at, local, keyring)
    if why2 is not None:
        raise ToolError("pushed, but %s %s" % (at, why2))
    print("pushed commit %s: %s identical and verified; %s %s, check again in a few minutes"
          % (commit[:12], at, PROD_FEED_URL, why))
    return 0


# ---------------------------------------------------------------- test vectors

def padded_png(raw: bytes, total: int) -> bytes:
    """A valid PNG grown to exactly `total` bytes with a tEXt chunk before IEND."""
    if raw[-12:-8] != b"\x00\x00\x00\x00" or raw[-8:-4] != b"IEND":
        raise ToolError("PNG does not end with IEND")
    need = total - len(raw) - 12
    if need < 1:
        raise ToolError("image already larger than %d" % total)
    body = b"x" + b"\x00" + b"a" * (need - 2) if need >= 2 else b"x"
    chunk = struct.pack(">I", len(body)) + b"tEXt" + body + struct.pack(">I", zlib.crc32(b"tEXt" + body))
    out = raw[:-12] + chunk + raw[-12:]
    assert len(out) == total
    return out


def make_vectors(d: Path, out: Path, png_path: Path, now: datetime) -> list:
    """Fixtures for the Dart tests: good envelope, keyring, three bad files."""
    out.mkdir(parents=True, exist_ok=True)
    keyring = read_json_file(d / KEYRING_NAME, "keyring")
    key = load_private_key(d / KEY_NAME)
    good = (d / ENVELOPE_NAME).read_bytes()
    if verify_envelope(good, keyring, now)["outcome"] != "accepted":
        raise ToolError("current envelope does not verify")
    write_file(out / "announcements.json", good)
    write_file(out / "keyring.json", (json.dumps({"keys": keyring["keys"]}, indent=2) + "\n").encode())
    env = json.loads(good)
    body = bytearray(b64d(env["payload"]))
    i = body.index(b'"text": "') + len(b'"text": "')
    body[i] ^= 0x01  # one payload byte changed, signature untouched
    bad = dict(env, payload=b64e(bytes(body)))
    write_file(out / "bad-signature.json", (json.dumps(bad, indent=2) + "\n").encode())
    payload = b64d(env["payload"])
    write_file(out / "wrong-type.json", sign_envelope(payload, PUBLIC_TYPE, [key]))
    big = padded_png(png_path.read_bytes(), 9000)
    obj = json.loads(payload)
    for m in obj["messages"]:
        if "image" in m:
            m["image"] = {"png": b64e(big)}
    if not any("image" in m for m in obj["messages"]):
        raise ToolError("no message with an image in the feed")
    p2 = (json.dumps(obj, indent=2, ensure_ascii=False) + "\n").encode("utf-8")
    write_file(out / "oversized-image.json", sign_envelope(p2, PAYLOAD_TYPE, [key]))
    return ["announcements.json", "keyring.json", "bad-signature.json", "wrong-type.json",
            "oversized-image.json"]


def cmd_fixtures(a) -> int:
    d = target_dir(a)
    names = make_vectors(d, Path(a.out), Path(os.path.expanduser(a.png)), now_utc())
    print("wrote %s into %s" % (", ".join(names), a.out))
    return 0


# ---------------------------------------------------------------- CLI

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="announce", description=__doc__.splitlines()[0])
    p.add_argument("--target", choices=["test", "prod"], default=DEFAULT_TARGET,
                   help="which feed: picks --dir (%s or %s) and the sign key" % (DEFAULT_DIR, PROD_DIR))
    p.add_argument("--dir", help="folder of the source, keyring and envelope (default: by --target)")
    p.add_argument("--source", help="source payload (default: DIR/%s)" % SOURCE_NAME)
    sub = p.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("add", help="add a message to the source")
    s.add_argument("--id", required=True)
    s.add_argument("--text", required=True)
    s.add_argument("--link-label")
    s.add_argument("--link-url")
    s.add_argument("--image", help="PNG file")
    s.add_argument("--days", type=int, default=14)
    s.add_argument("--starts", help="YYYY-MM-DDTHH:MM:SSZ")
    s.add_argument("--platforms", help="desktop,phone")
    s.set_defaults(fn=cmd_add)

    s = sub.add_parser("remove", help="remove a message")
    s.add_argument("--id", required=True)
    s.set_defaults(fn=cmd_remove)

    s = sub.add_parser("list", help="list the source messages")
    s.set_defaults(fn=cmd_list)

    s = sub.add_parser("sign", help="check, sign and verify the feed")
    s.add_argument("--days", type=int, default=30)
    s.add_argument("--key", help="private key file (default: DIR/%s)" % KEY_NAME)
    s.add_argument("--revoke", action="append", metavar="KEYID", help="add a key id to revoked_keys")
    s.set_defaults(fn=cmd_sign)

    s = sub.add_parser("verify", help="verify an envelope (FORMAT.md section 5)")
    s.add_argument("--envelope")
    s.add_argument("--url")
    s.add_argument("--keyring")
    s.set_defaults(fn=cmd_verify)

    s = sub.add_parser("publish", help="copy the signed envelope to a target and read it back")
    s.add_argument("--target", dest="publish_target", required=True, choices=["test", "prod"])
    s.add_argument("--site", help="prod: Pages repository checkout (default %s)" % PROD_SITE)
    s.set_defaults(fn=cmd_publish)

    s = sub.add_parser("fixtures", help="write the test vectors for the app's tests")
    s.add_argument("--out", required=True)
    s.add_argument("--png", required=True, help="PNG of a message in the feed, padded for the big one")
    s.set_defaults(fn=cmd_fixtures)
    return p


def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    try:
        return args.fn(args)
    except ToolError as e:
        print("error: %s" % e, file=sys.stderr)
        return 2
    except subprocess.SubprocessError as e:
        print("error: remote command failed: %s" % type(e).__name__, file=sys.stderr)
        return 3


if __name__ == "__main__":
    sys.exit(main())
