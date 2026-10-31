# SPDX-License-Identifier: Apache-2.0
"""The signer service: requests, the owner's approval, and its two HTTP listeners.

Tailnet listener (config listen/port; never 0.0.0.0): the release tools' API.
  GET  /info                          version, key ids, public keys, Android certificate SHA-256
  POST /requests                      {version, jobs, files: [{name, size, sha256}]} -> id
  PUT  /requests/<id>/in/<name>       one file's bytes; the signer hashes its own copy
  POST /requests/<id>/submit          all files in: ask the owner (Telegram, TOTP); for a follow-up, sign
  POST /requests/<id>/continue        {jobs, files}: the follow-up a request declared (`then`)
  GET  /requests/<id>                 state, hashes, outputs
  GET  /requests/<id>/out/<name>      a signed output
  POST /requests/<id>/cancel
  POST /selftest                      key identity, no approval, nothing usable made
Every route but /info needs the client token (Authorization: Bearer).

Loopback listener (127.0.0.1:admin_port), for whoever sits at the signer's machine:
  GET/POST /enrol                     the one-time TOTP enrolment page
  POST /admin/import                  a bundle and its key, once, into an empty store
  POST /admin/secret                  the bot token or the client token
  GET  /admin/status

Approval: one request at a time; it expires 30 min after it was made. The bot posts the request
to the owner; he replies with a 6-digit code; the bot keeps it for that request; the signer reads
it and checks it (RFC 6238, SHA-1, 30 s, ±1 step), and never takes a time step it already took.
Three wrong codes reject the request; five failures within an hour lock the signer for an hour.

One code per release: a request of Android jobs (apk, aab) may declare `then`, the update
manifests and SHA256SUMS signature that follow once the runner has the signed APKs (their hashes
go into the manifests, so they cannot be in the same upload). the owner's message says so; after
his code the Android files are signed and the request waits (`continuing`) up to
continue_minutes for exactly the declared jobs (op and output name). The request also declares
(`expect`: name, size, SHA-256) the release's other files the manifests will name, the desktop
builds, and the owner's message lists them. The follow-up is checked as any request's (payload
schema, links, --prev serial, self-verify) and also bound to what he approved: the manifests
are for the request's version, name only APKs signed in this request and desktop files declared
in it or already in the live manifest (--prev), each by name, SHA-256 and size; a SHA256SUMS
lists them all, and its line for a file signed or declared here carries that hash
(ops.check_follow). Then they are signed without a second code. Anything else, or too late, and the follow-up is refused;
the runner then asks for a new request (and code) as before.
"""
from __future__ import annotations

import base64
import hmac
import html
import http.server
import ipaddress
import json
import logging
import logging.handlers
import os
import re
import secrets as _secrets
import shutil
import socketserver
import threading
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone

from . import crypto, ops
from .store import Store, StoreError, atomic_write

VERSION = "1.1.0"
log = logging.getLogger("btsign")

FINAL = ("done", "rejected", "expired", "failed", "cancelled")
FOLLOW = ("continuing", "uploading2")          # the Android half signed; the follow-up may come
THEN_OPS = ("update-manifest", "minisign")
FIRST_OPS = ("apk", "aab")                     # what a request that declares `then` may sign first
VERSION_RE = re.compile(r"[0-9A-Za-z][0-9A-Za-z.+-]{0,39}\Z")
ID_RE = re.compile(r"r[0-9a-f]{16}\Z")
MAX_JSON = 64 * 1024
WRONG_PER_REQUEST = 3
FAILS_PER_HOUR = 5
LOCK_SECONDS = 3600

DEFAULTS = {
    "listen": "", "port": 8797, "admin_port": 8796, "bot_url": "",
    "max_file_mb": 600, "max_total_mb": 2048, "max_files": 24, "expiry_minutes": 30,
    "poll_seconds": 3, "keep_done_minutes": 30, "continue_minutes": 60, "totp_account": "the owner",
    "totp_issuer": "BT Labs signer",
}


class Refused(Exception):
    def __init__(self, status: int, msg: str):
        super().__init__(msg)
        self.status = status


def load_config(path: str) -> dict:
    import tomllib
    cfg = dict(DEFAULTS)
    if os.path.isfile(path):
        with open(path, "rb") as f:
            cfg.update(tomllib.load(f))
    return cfg


def now_iso(ts: float | None = None) -> str:
    return datetime.fromtimestamp(time.time() if ts is None else ts, timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


# ---------------------------------------------------------------- the bot

class Bot:
    """@BTLABS_BOT's signer routes (gui-feedback-bot, SIGNER_TOKEN; docs/release-relay.md § 8)."""

    def __init__(self, url: str, token_fn):
        self.url = url.rstrip("/")
        self.token_fn = token_fn

    def call(self, method: str, path: str, body: dict | None = None, timeout: float = 20) -> dict:
        token = self.token_fn()
        if not self.url or not token:
            raise Refused(503, "the bot is not configured (bot_url, bot token)")
        data = None if body is None else json.dumps(body).encode()
        req = urllib.request.Request(self.url + path, data=data, method=method,
                                     headers={"Authorization": f"Bearer {token}",
                                              "Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return json.loads(r.read() or b"{}")
        except urllib.error.HTTPError as e:
            raise Refused(502, f"bot answered {e.code}") from None
        except (urllib.error.URLError, OSError, ValueError) as e:
            raise Refused(502, f"bot unreachable ({e.__class__.__name__})") from None


# ---------------------------------------------------------------- the signer

class Signer:
    def __init__(self, data_dir: str, cfg: dict, clock=time.time, bot: Bot | None = None):
        self.cfg = cfg
        self.clock = clock
        self.store = Store(data_dir, cfg.get("backend"))
        self.dir = data_dir
        self.reqdir = os.path.join(data_dir, "requests")
        os.makedirs(self.reqdir, exist_ok=True)
        self.tools = ops.Tools(cfg, data_dir)
        self.bot = bot or Bot(cfg.get("bot_url", ""), lambda: self.store.secrets().get("bot_token"))
        self.lock = threading.RLock()
        self.wake = threading.Event()
        self.stop = threading.Event()
        self._enrol_secret = None          # the secret shown on the enrolment page (memory only)
        self._enrol_csrf = _secrets.token_urlsafe(24)
        self._last_selftest = 0.0
        self._recover()

    # ---- request files
    def _path(self, rid: str, *parts) -> str:
        if not ID_RE.match(rid):
            raise Refused(404, "no such request")
        return os.path.join(self.reqdir, rid, *parts)

    def _meta(self, rid: str) -> dict:
        try:
            with open(self._path(rid, "meta.json"), encoding="utf-8") as f:
                return json.load(f)
        except FileNotFoundError:
            raise Refused(404, "no such request") from None

    def _save(self, meta: dict) -> None:
        atomic_write(self._path(meta["id"], "meta.json"), json.dumps(meta, indent=1).encode())

    def _all(self) -> list[dict]:
        out = []
        for rid in sorted(os.listdir(self.reqdir)):
            if ID_RE.match(rid):
                try:
                    out.append(self._meta(rid))
                except (Refused, ValueError):
                    continue
        return out

    def _recover(self) -> None:
        """After a restart nothing is signed half-way: a request that was signing has failed."""
        for m in self._all():
            if m["state"] in ("approved", "signing"):
                self._finish(m, "failed", "the signer restarted while signing; send it again", notify=False)

    # ---- info
    def info(self) -> dict:
        s = self.store.secrets()
        keys = []
        ring = (s.get("keyring") or {}).get("keys", [])
        held = set()
        for pem in (s.get("ed25519") or {}).values():
            held.add(crypto.keyid_of(crypto.raw_public(crypto.load_ed25519_pem(pem))))
        for k in ring:
            keys.append({"keyid": k["keyid"], "label": k["label"], "rank": k["rank"],
                         "public_key": k["public_key"], "held": k["keyid"] in held})
        st = self.store.state()
        active = [m["id"] for m in self._all() if m["state"] not in FINAL]
        return {"service": "btsign", "version": VERSION, "keys": keys,
                "android_cert_sha256": (s.get("android") or {}).get("cert_sha256"),
                "enrolled": bool(s.get("totp")), "locked_until": now_iso(st["locked_until"])
                if st.get("locked_until", 0) > self.clock() else None,
                "active_request": active[0] if active else None,
                "apk_schemes": self.tools.schemes, "ops": list(ops.OPS),
                "follow_up": True}   # a request may declare `then` (the client asks before it does)

    def ledger(self) -> set:
        p = os.path.join(self.dir, "signed.jsonl")
        out = set()
        if os.path.isfile(p):
            with open(p, encoding="utf-8") as f:
                for line in f:
                    try:
                        out.add(json.loads(line)["sha256"])
                    except (ValueError, KeyError):
                        continue
        return out

    def _ledger_add(self, rows: list[dict]) -> None:
        with open(os.path.join(self.dir, "signed.jsonl"), "a", encoding="utf-8") as f:
            for r in rows:
                f.write(json.dumps(r) + "\n")

    # ---- creating a request
    def _check_files(self, files) -> tuple[dict, int]:
        if not isinstance(files, list) or len(files) > int(self.cfg["max_files"]):
            raise Refused(400, f"files: a list of at most {self.cfg['max_files']}")
        declared, total = {}, 0
        cap = int(self.cfg["max_file_mb"]) * 1024 * 1024
        for f in files:
            if not isinstance(f, dict) or set(f) != {"name", "size", "sha256"}:
                raise Refused(400, "each file is {name, size, sha256}")
            if not isinstance(f["name"], str) or not ops.NAME_RE.match(f["name"]) or f["name"] in declared:
                raise Refused(400, f"bad or repeated file name {f['name']!r}")
            if type(f["size"]) is not int or not 0 < f["size"] <= cap:
                raise Refused(413, f"{f['name']}: size must be 1..{self.cfg['max_file_mb']} MB")
            if not isinstance(f["sha256"], str) or not re.fullmatch(r"[0-9a-f]{64}", f["sha256"]):
                raise Refused(400, f"{f['name']}: sha256 is 64 lowercase hex")
            declared[f["name"]] = f
            total += f["size"]
        if total > int(self.cfg["max_total_mb"]) * 1024 * 1024:
            raise Refused(413, f"files total more than {self.cfg['max_total_mb']} MB")
        return declared, total

    def _check_jobs(self, jobs, declared: dict, total: int) -> list[dict]:
        if not isinstance(jobs, list) or not 1 <= len(jobs) <= int(self.cfg["max_files"]):
            raise Refused(400, "jobs: 1 or more")
        try:
            jobs = [ops.check_job(j, declared) for j in jobs]
        except ops.OpError as e:
            raise Refused(400, str(e)) from None
        outs = [j["out"] for j in jobs]
        if len(set(outs)) != len(outs):
            raise Refused(400, "two jobs write the same output")
        free = shutil.disk_usage(self.dir).free
        if free < 2 * total + 512 * 1024 * 1024:
            raise Refused(507, "not enough disk space on the signer")
        return jobs

    @staticmethod
    def _check_then(then, jobs: list[dict]) -> list[dict]:
        """The follow-up a request declares: [{op, out}], manifests and minisign only, after
        Android jobs only."""
        if not isinstance(then, list) or not 1 <= len(then) <= 8:
            raise Refused(400, "then: a list of 1-8 {op, out}")
        if any(j["op"] not in FIRST_OPS for j in jobs):
            raise Refused(400, f"then: only after {', '.join(FIRST_OPS)} jobs")
        outs = {j["out"] for j in jobs}
        out = []
        for t in then:
            if not isinstance(t, dict) or set(t) != {"op", "out"} or t["op"] not in THEN_OPS \
                    or not isinstance(t["out"], str) or not ops.NAME_RE.match(t["out"]) or t["out"] in outs:
                raise Refused(400, f"then: each is {{op: {' | '.join(THEN_OPS)}, out}}, a new output name")
            outs.add(t["out"])
            out.append({"op": t["op"], "out": t["out"]})
        return out

    def _check_expect(self, expect, jobs: list[dict], declared: dict) -> dict:
        """The release's other files a follow-up's manifests may name: {name: {size, sha256}}."""
        if expect is None:
            return {}
        if not isinstance(expect, list) or len(expect) > int(self.cfg["max_files"]):
            raise Refused(400, f"expect: a list of at most {self.cfg['max_files']}")
        taken = {j["out"] for j in jobs} | set(declared)
        out = {}
        for f in expect:
            if not isinstance(f, dict) or set(f) != {"name", "size", "sha256"} \
                    or not isinstance(f["name"], str) or not ops.NAME_RE.match(f["name"]) \
                    or f["name"] in out or f["name"] in taken or type(f["size"]) is not int or f["size"] < 1 \
                    or not isinstance(f["sha256"], str) or not re.fullmatch(r"[0-9a-f]{64}", f["sha256"]):
                raise Refused(400, "expect: each is {name, size, sha256}, a name of no job or input")
            out[f["name"]] = {"size": f["size"], "sha256": f["sha256"]}
        return out

    def create(self, spec: dict) -> dict:
        if not isinstance(spec, dict) or set(spec) - {"version", "jobs", "files", "label", "then", "expect"}:
            raise Refused(400, "body: {version, jobs, files[, label][, then[, expect]]}")
        version, jobs, files = spec.get("version"), spec.get("jobs"), spec.get("files")
        if not isinstance(version, str) or not VERSION_RE.match(version):
            raise Refused(400, "version: 1-40 of [0-9A-Za-z.+-]")
        label = spec.get("label") or ""
        if not isinstance(label, str) or not re.fullmatch(r"[ -~]{0,80}", label):
            raise Refused(400, "label: up to 80 printable ASCII characters")
        declared, total = self._check_files(files)
        jobs = self._check_jobs(jobs, declared, total)
        then = self._check_then(spec["then"], jobs) if spec.get("then") is not None else None
        expect = self._check_expect(spec.get("expect"), jobs, declared) if then else None
        if spec.get("expect") and not then:
            raise Refused(400, "expect: only with then")
        with self.lock:
            self.expire()
            if self._locked():
                raise Refused(423, "the signer is locked after too many wrong codes; try later")
            busy = [m for m in self._all() if m["state"] not in FINAL]
            if busy:
                raise Refused(409, f"request {busy[0]['id']} is still {busy[0]['state']}: one at a time")
            if not self.store.secrets().get("totp"):
                raise Refused(409, "TOTP is not enrolled yet: the owner enrols at the signer's machine first")
            rid = "r" + _secrets.token_hex(8)
            os.makedirs(self._path(rid, "in"))
            os.makedirs(self._path(rid, "out"))
            now = self.clock()
            meta = {"id": rid, "version": version, "label": label, "jobs": jobs,
                    "files": {n: {"size": f["size"], "sha256": f["sha256"], "got": None}
                              for n, f in declared.items()},
                    "state": "uploading", "created": now, "expires": now + 60 * int(self.cfg["expiry_minutes"]),
                    "wrong": 0, "seen": 0, "outputs": {}, "note": None, "message_id": None,
                    "then": then, "expect": expect, "jobs2": None, "files2": {}, "continue_by": None}
            self._save(meta)
            log.info("request %s: %d job(s), %d file(s), %d bytes, %s%s", rid, len(jobs), len(declared), total,
                     version, f", then {len(then)} job(s)" if then else "")
            return self.public(meta)

    def follow(self, rid: str, spec: dict) -> dict:
        """The follow-up of a request that declared `then`: exactly those jobs, on new files."""
        if not isinstance(spec, dict) or set(spec) - {"jobs", "files"}:
            raise Refused(400, "body: {jobs, files}")
        declared, total = self._check_files(spec.get("files"))
        jobs = self._check_jobs(spec.get("jobs"), declared, total)
        with self.lock:
            self.expire()
            meta = self._meta(rid)
            if meta["state"] != "continuing":
                raise Refused(409, f"request is {meta['state']}, not waiting for its follow-up")
            if self._locked():
                raise Refused(423, "the signer is locked after too many wrong codes; try later")
            want = sorted((t["op"], t["out"]) for t in meta["then"])
            got = sorted((j["op"], j["out"]) for j in jobs)
            if got != want:
                raise Refused(400, "the follow-up is not the one the owner approved: "
                                   + ", ".join(f"{o} {n}" for o, n in want))
            os.makedirs(self._path(rid, "in2"), exist_ok=True)
            meta["jobs2"] = jobs
            meta["files2"] = {n: {"size": f["size"], "sha256": f["sha256"], "got": None} for n, f in declared.items()}
            meta["state"] = "uploading2"
            self._save(meta)
            log.info("request %s: follow-up of %d job(s), %d file(s)", rid, len(jobs), len(declared))
            return self.public(meta)

    def upload(self, rid: str, name: str, stream, length: int) -> dict:
        with self.lock:
            meta = self._meta(rid)
            if meta["state"] not in ("uploading", "uploading2"):
                raise Refused(409, f"request is {meta['state']}")
            key, sub = ("files2", "in2") if meta["state"] == "uploading2" else ("files", "in")
            f = meta[key].get(name)
            if f is None:
                raise Refused(404, f"{name} is not one of the request's files")
            if length != f["size"]:
                raise Refused(400, f"{name}: Content-Length {length} is not the declared {f['size']}")
        import hashlib
        h = hashlib.sha256()
        dst = self._path(rid, sub, name)
        tmp = dst + ".part"
        left = length
        with open(tmp, "wb") as out:
            while left > 0:
                chunk = stream.read(min(1 << 20, left))
                if not chunk:
                    break
                out.write(chunk)
                h.update(chunk)
                left -= len(chunk)
        if left:
            os.unlink(tmp)
            raise Refused(400, f"{name}: the upload ended early")
        got = h.hexdigest()
        if got != f["sha256"]:
            os.unlink(tmp)
            raise Refused(422, f"{name}: the signer's SHA-256 {got} is not the declared one")
        os.replace(tmp, dst)
        with self.lock:
            meta = self._meta(rid)
            if meta["state"] != ("uploading2" if key == "files2" else "uploading"):
                raise Refused(409, f"request is {meta['state']}")
            meta[key][name]["got"] = got
            self._save(meta)
        return {"name": name, "sha256": got, "size": length}

    def submit(self, rid: str) -> dict:
        with self.lock:
            self.expire()
            meta = self._meta(rid)
            if meta["state"] == "uploading2":
                return self._submit_follow(meta)
            if meta["state"] != "uploading":
                raise Refused(409, f"request is {meta['state']}")
            missing = [n for n, f in meta["files"].items() if not f["got"]]
            if missing:
                raise Refused(409, "files not uploaded yet: " + ", ".join(missing))
            if self._locked():
                raise Refused(423, "the signer is locked after too many wrong codes; try later")
            indir = self._path(rid, "in")
            ledger = self.ledger()
            lines = []
            try:
                for j in meta["jobs"]:
                    lines += ops.describe(j, indir, meta["files"], ledger)
            except (ops.OpError, ValueError, OSError) as e:
                self._finish(meta, "failed", f"refused before asking: {e}", notify=False)
                raise Refused(422, str(e)) from None
            if meta.get("then"):
                # First, so the bot never cuts it: what this one code also signs, later.
                lines[:0] = ["then, on this code, no other: " + ", ".join(
                    f"{t['out']} ({t['op']})" for t in meta["then"])
                    + f", within {self.cfg['continue_minutes']} min, naming only the Android files signed "
                    "here" + (" and these:" if meta.get("expect") else "")] \
                    + [f"  {n} {e['size']} bytes {e['sha256']}" for n, e in sorted((meta.get("expect") or {}).items())]
            body = {"request_id": rid, "version": meta["version"], "label": meta["label"],
                    "ops": sorted({j["op"] for j in meta["jobs"]} | {t["op"] for t in meta.get("then") or []}),
                    "files": [{"name": n, "size": f["size"], "sha256": f["got"]} for n, f in sorted(meta["files"].items())],
                    "lines": lines[:60], "expires_at": now_iso(meta["expires"])}
            res = self.bot.call("POST", "/signer/requests", body)
            meta["message_id"] = res.get("message_id")
            meta["state"] = "pending_approval"
            self._save(meta)
            log.info("request %s: asked the owner (bot message %s)", rid, meta["message_id"])
        self.wake.set()
        return self.public(meta)

    def _submit_follow(self, meta: dict) -> dict:
        """Called with self.lock held: checks the follow-up and signs it on the request's code."""
        rid = meta["id"]
        missing = [n for n, f in meta["files2"].items() if not f["got"]]
        if missing:
            raise Refused(409, "files not uploaded yet: " + ", ".join(missing))
        if self._locked():
            raise Refused(423, "the signer is locked after too many wrong codes; try later")
        indir = self._path(rid, "in2")
        lines = []
        try:
            ledger = self.ledger()
            for j in meta["jobs2"]:
                lines += ops.describe(j, indir, meta["files2"], ledger)
            ops.check_follow(meta["jobs2"], indir, meta["outputs"], meta.get("expect") or {}, meta["version"])
        except (ops.OpError, ValueError, OSError) as e:
            self._finish(meta, "failed", f"follow-up refused: {e}", notify=False)
            self._tell_bot(meta, "then-failed", f"follow-up refused: {e}")
            raise Refused(422, str(e)) from None
        meta["follow_lines"] = lines[:60]
        meta["state"] = "signing"
        self._save(meta)
        log.info("request %s: signing the follow-up on the request's code", rid)
        self.sign(meta, follow=True)
        return self.public(self._meta(rid))

    def _tell_bot(self, meta: dict, status: str, note: str) -> None:
        if meta.get("message_id") is None:
            return
        try:
            self.bot.call("POST", f"/signer/requests/{meta['id']}/result", {"status": status, "note": note[:300]})
        except Refused as e:
            log.warning("request %s: could not tell the bot (%s)", meta["id"], e)

    def cancel(self, rid: str) -> dict:
        with self.lock:
            meta = self._meta(rid)
            if meta["state"] in FINAL:
                return self.public(meta)
            if meta["state"] == "signing":
                raise Refused(409, "already signing")
            self._finish(meta, "cancelled", "cancelled by the client", notify=meta["state"] == "pending_approval")
            return self.public(meta)

    def public(self, meta: dict) -> dict:
        out = {"id": meta["id"], "state": meta["state"], "version": meta["version"], "note": meta.get("note"),
               "created": now_iso(meta["created"]), "expires": now_iso(meta["expires"]),
               "files": {n: {"size": f["size"], "sha256": f["got"] or None} for n, f in meta["files"].items()},
               "jobs": meta["jobs"], "outputs": meta.get("outputs", {})}
        if meta.get("then"):
            out["then"] = meta["then"]
            out["expect"] = meta.get("expect") or {}
            out["continue_by"] = now_iso(meta["continue_by"]) if meta.get("continue_by") else None
            out["jobs2"] = meta.get("jobs2")
            out["files2"] = {n: {"size": f["size"], "sha256": f["got"] or None}
                             for n, f in (meta.get("files2") or {}).items()}
        return out

    def status(self, rid: str) -> dict:
        with self.lock:
            self.expire()
            return self.public(self._meta(rid))

    def output(self, rid: str, name: str) -> str:
        meta = self.status(rid)
        if meta["state"] not in ("done",) + FOLLOW or name not in meta["outputs"]:
            raise Refused(404, "no such output (yet)")
        return self._path(rid, "out", name)

    # ---- lifecycle
    def _finish(self, meta: dict, state: str, note: str, notify: bool = True) -> None:
        meta["state"], meta["note"], meta["ended"] = state, note, self.clock()
        self._save(meta)
        if state != "done":
            shutil.rmtree(self._path(meta["id"], "out"), ignore_errors=True)
            os.makedirs(self._path(meta["id"], "out"), exist_ok=True)
        log.info("request %s: %s (%s)", meta["id"], state, note)
        if notify and meta.get("message_id") is not None:
            try:
                self.bot.call("POST", f"/signer/requests/{meta['id']}/result", {"status": state, "note": note[:300]})
            except Refused as e:
                log.warning("request %s: could not tell the bot (%s)", meta["id"], e)

    def expire(self) -> None:
        now = self.clock()
        keep = 60 * int(self.cfg["keep_done_minutes"])
        for m in self._all():
            if m["state"] in ("uploading", "pending_approval") and now > m["expires"]:
                self._finish(m, "expired", "not approved within 30 minutes",
                             notify=m["state"] == "pending_approval")
            elif m["state"] in FOLLOW and now > (m.get("continue_by") or 0):
                # The Android half stands (signed, in the ledger, fetched by the runner); a later
                # follow-up is a new request with its own code.
                self._finish(m, "expired", f"the follow-up did not come within {self.cfg['continue_minutes']} "
                             "minutes after the Android files were signed", notify=False)
            elif m["state"] in FINAL and now > max(m.get("ended", 0) + keep, m["expires"]):
                shutil.rmtree(self._path(m["id"]), ignore_errors=True)

    def _locked(self) -> bool:
        return self.store.state().get("locked_until", 0) > self.clock()

    def _fail(self, what: str) -> bool:
        """Record a failure; True when it locks the signer."""
        st = self.store.state()
        now = self.clock()
        fails = [t for t in st.get("failures", []) if now - t < 3600] + [now]
        st["failures"] = fails
        locked = len(fails) >= FAILS_PER_HOUR
        if locked:
            st["locked_until"] = now + LOCK_SECONDS
        self.store.save_state(st)
        log.warning("failure: %s (%d within the hour%s)", what, len(fails), "; LOCKED for an hour" if locked else "")
        return locked

    def check_code(self, code: str) -> str:
        """'ok', 'wrong', 'reused' or 'locked'. On ok the time step is recorded as used before
        anything is signed."""
        with self.store.lock:
            if self._locked():
                return "locked"
            secret = (self.store.secrets().get("totp") or {}).get("secret")
            if not secret:
                return "wrong"
            step = crypto.totp_match(secret, code, self.clock())
            st = self.store.state()
            if step is not None and step > st.get("totp_last_step", -1):
                st["totp_last_step"] = step
                self.store.save_state(st)
                return "ok"
            locked = self._fail("reused TOTP step" if step is not None else "wrong TOTP code")
            return "locked" if locked else ("reused" if step is not None else "wrong")

    def poll_once(self) -> None:
        with self.lock:
            self.expire()
            pending = [m for m in self._all() if m["state"] == "pending_approval"]
        for meta in pending:
            try:
                res = self.bot.call("GET", f"/signer/requests/{meta['id']}/codes?after={meta['seen']}")
            except Refused as e:
                log.warning("request %s: reading codes failed (%s)", meta["id"], e)
                continue
            for c in res.get("codes", []):
                seq, code = c.get("seq"), str(c.get("code", ""))
                if type(seq) is not int or seq <= meta["seen"]:
                    continue
                meta["seen"] = seq
                verdict = self.check_code(code)
                if verdict == "ok":
                    meta["state"] = "approved"
                    self._save(meta)
                    log.info("request %s: approved", meta["id"])
                    self.sign(meta)
                    break
                meta["wrong"] += 1
                self._save(meta)
                if verdict == "locked":
                    self._finish(meta, "rejected", "too many failures: the signer is locked for an hour")
                    break
                if meta["wrong"] >= WRONG_PER_REQUEST:
                    self._finish(meta, "rejected", f"{WRONG_PER_REQUEST} wrong codes")
                    break
                left = WRONG_PER_REQUEST - meta["wrong"]
                why = "that time step was already used" if verdict == "reused" else "wrong code"
                try:
                    self.bot.call("POST", f"/signer/requests/{meta['id']}/result",
                                  {"status": "wrong", "note": f"{why}; {left} attempt(s) left"})
                except Refused:
                    pass

    def sign(self, meta: dict, follow: bool = False) -> None:
        meta["state"] = "signing"
        self._save(meta)
        secrets = self.store.secrets()
        indir, outdir = self._path(meta["id"], "in2" if follow else "in"), self._path(meta["id"], "out")
        outputs, rows = dict(meta.get("outputs") or {}) if follow else {}, []
        try:
            for j in meta["jobs2"] if follow else meta["jobs"]:
                sha = ops.run_job(j, indir, outdir, secrets, self.tools)
                outputs[j["out"]] = {"sha256": sha, "size": os.path.getsize(os.path.join(outdir, j["out"]))}
                rows.append({"at": now_iso(), "request": meta["id"], "version": meta["version"],
                             "op": j["op"], "name": j["out"], "sha256": sha})
        except (ops.OpError, OSError, ValueError) as e:
            self._finish(meta, "failed", f"signing failed: {e}", notify=not follow)
            if follow:
                self._tell_bot(meta, "then-failed", f"signing failed: {e}")
            return
        finally:
            del secrets
        meta["outputs"] = outputs
        self._ledger_add(rows)
        shutil.rmtree(indir, ignore_errors=True)
        if follow:
            self._finish(meta, "done", f"signed {len(rows)} follow-up file(s) on the request's code", notify=False)
            self._tell_bot(meta, "then-done", "; ".join([f"{len(rows)} file(s) on the same code"]
                                                         + meta.get("follow_lines", [])[:12]))
            return
        if meta.get("then"):
            meta["state"], meta["note"] = "continuing", f"signed {len(outputs)} file(s); waiting for the follow-up"
            meta["continue_by"] = self.clock() + 60 * int(self.cfg["continue_minutes"])
            self._save(meta)
            log.info("request %s: signed %d file(s); the follow-up may come until %s", meta["id"], len(outputs),
                     now_iso(meta["continue_by"]))
            # The code is used up: the bot closes its request (no code is routed to it again).
            self._tell_bot(meta, "done", f"signed {len(outputs)} file(s); "
                           + ", ".join(t["out"] for t in meta["then"]) + " follow on this code")
            return
        self._finish(meta, "done", f"signed {len(outputs)} file(s)")

    def loop(self) -> None:
        while not self.stop.is_set():
            try:
                self.poll_once()
            except Exception:
                log.exception("approval loop")
            self.wake.wait(float(self.cfg["poll_seconds"]))
            self.wake.clear()

    # ---- selftest
    def selftest(self) -> dict:
        with self.lock:
            if self.clock() - self._last_selftest < 10:
                raise Refused(429, "one selftest per 10 seconds")
            self._last_selftest = self.clock()
        try:
            return ops.selftest(self.store.secrets(), self.tools)
        except ops.OpError as e:
            raise Refused(500, str(e)) from None

    # ---- admin (loopback)
    def import_bundle(self, bundle: bytes, bundle_key: str) -> dict:
        with self.store.lock:
            if (self.store.secrets().get("ed25519")):
                raise Refused(409, "the store already holds keys; a second import needs the store "
                                   "removed by an administrator first")
            try:
                content = crypto.open_bundle(bundle, bundle_key)
                ops.check_bundle_content(content)
            except (crypto.CryptoError, ops.OpError) as e:
                raise Refused(400, str(e)) from None
            s = self.store.secrets()
            s.update({k: content[k] for k in ("ed25519", "keyring", "android")})
            s["bundle_key"] = bundle_key.strip()
            if content.get("totp"):
                s["totp"] = content["totp"]
            self.store.save_secrets(s)
        log.info("imported a bundle (keys %s)", ", ".join(k["keyid"] for k in content["keyring"]["keys"]))
        return self.info()

    def set_secret(self, name: str, value: str) -> dict:
        if name not in ("bot_token", "client_token"):
            raise Refused(400, "name is bot_token or client_token")
        if not isinstance(value, str) or len(value.strip()) < 32:
            raise Refused(400, "a token is at least 32 characters")
        self.store.update_secrets(**{name: value.strip()})
        log.info("%s set", name)
        return {"ok": True}

    def client_ok(self, header: str) -> bool:
        want = (self.store.secrets().get("client_token") or "").encode()
        given = header[7:].strip().encode() if header.lower().startswith("bearer ") else b""
        return bool(want) and bool(given) and hmac.compare_digest(given, want)

    # ---- enrolment
    def enrolled(self) -> bool:
        return bool(self.store.secrets().get("totp"))

    def enrol_secret(self) -> str:
        with self.lock:
            if self._enrol_secret is None:
                self._enrol_secret = crypto.new_totp_secret()
            return self._enrol_secret

    def enrol_confirm(self, code: str, csrf: str) -> str:
        """'ok', 'enrolled' (already), 'wrong', 'locked', 'csrf'."""
        with self.lock:
            if self.enrolled():
                return "enrolled"
            if not hmac.compare_digest(csrf.encode(), self._enrol_csrf.encode()):
                return "csrf"
            if self._locked():
                return "locked"
            secret = self.enrol_secret()
            step = crypto.totp_match(secret, code, self.clock())
            if step is None:
                return "locked" if self._fail("wrong enrolment code") else "wrong"
            self.store.update_secrets(totp={"secret": secret, "enrolled_at": now_iso()})
            st = self.store.state()
            st["totp_last_step"] = step
            self.store.save_state(st)
            self._enrol_secret = None
        log.info("TOTP enrolled")
        try:
            self.bot.call("POST", "/signer/notice", {"kind": "enrolled"})
        except Refused as e:
            log.warning("could not tell the bot about the enrolment (%s)", e)
        return "ok"


# ---------------------------------------------------------------- HTTP

class _Server(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True
    allow_reuse_address = False


def check_listen(host: str, loopback_only: bool = False) -> None:
    try:
        ip = ipaddress.ip_address(host)
    except ValueError:
        raise ValueError(f"listen must be an IP address, got {host!r}") from None
    if loopback_only:
        if not ip.is_loopback:
            raise ValueError("the admin listener is loopback only")
        return
    if not (ip in ipaddress.ip_network("100.64.0.0/10") or ip.is_loopback):
        raise ValueError(f"listen {host}: a tailnet (100.64.0.0/10) address only, never a LAN or 0.0.0.0")


class Handler(http.server.BaseHTTPRequestHandler):
    signer: Signer = None
    admin = False
    server_version = "btsign"
    sys_version = ""
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):  # the access log, without query strings
        log.info("%s %s %s", self.client_address[0], self.command, self.path.split("?")[0][:120])

    def _json(self, status: int, obj) -> None:
        data = (json.dumps(obj, indent=1) + "\n").encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(data)

    def _html(self, status: int, body: str) -> None:
        data = body.encode()
        self.send_response(status)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Frame-Options", "DENY")
        self.send_header("Content-Security-Policy", "default-src 'none'; img-src data:; style-src 'unsafe-inline'; form-action 'self'")
        self.send_header("Referrer-Policy", "no-referrer")
        self.end_headers()
        self.wfile.write(data)

    def _body(self, cap: int = MAX_JSON) -> bytes:
        n = int(self.headers.get("Content-Length") or 0)
        if n > cap:
            raise Refused(413, "body too large")
        return self.rfile.read(n) if n else b""

    def _jbody(self) -> dict:
        try:
            return json.loads(self._body() or b"{}")
        except ValueError:
            raise Refused(400, "body is not JSON") from None

    def _dispatch(self):
        try:
            if self.admin:
                host = self.headers.get("Host", "")
                if host.split(":")[0] not in ("127.0.0.1", "localhost"):
                    raise Refused(403, "loopback only")
                return self._admin()
            return self._api()
        except Refused as e:
            if self.headers.get("Content-Length") and self.command in ("POST", "PUT"):
                self.close_connection = True
            return self._json(e.status, {"error": str(e)})
        except StoreError as e:
            return self._json(500, {"error": str(e)})
        except Exception:
            log.exception("handler %s %s", self.command, self.path.split("?")[0])
            return self._json(500, {"error": "internal error (see the signer's log)"})

    do_GET = do_POST = do_PUT = _dispatch

    # ---- tailnet API
    def _api(self):
        s, path, method = self.signer, self.path.split("?")[0], self.command
        if path == "/info" and method == "GET":
            return self._json(200, s.info())
        if not s.client_ok(self.headers.get("Authorization", "")):
            raise Refused(401, "missing or wrong client token")
        if path == "/requests" and method == "POST":
            return self._json(201, s.create(self._jbody()))
        if path == "/selftest" and method == "POST":
            return self._json(200, s.selftest())
        m = re.fullmatch(r"/requests/(r[0-9a-f]{16})(?:/(in|out)/([A-Za-z0-9][A-Za-z0-9._-]{0,127})|/(submit|cancel|continue))?", path)
        if not m:
            raise Refused(404, "no such route")
        rid, kind, name, action = m.groups()
        if kind == "in" and method == "PUT":
            n = int(self.headers.get("Content-Length") or -1)
            if n < 0:
                raise Refused(411, "Content-Length required")
            return self._json(200, s.upload(rid, name, self.rfile, n))
        if kind == "out" and method == "GET":
            p = s.output(rid, name)
            size = os.path.getsize(p)
            self.send_response(200)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Length", str(size))
            self.end_headers()
            with open(p, "rb") as f:
                shutil.copyfileobj(f, self.wfile, 1 << 20)
            return None
        if action == "submit" and method == "POST":
            return self._json(200, s.submit(rid))
        if action == "cancel" and method == "POST":
            return self._json(200, s.cancel(rid))
        if action == "continue" and method == "POST":
            return self._json(200, s.follow(rid, self._jbody()))
        if not kind and not action and method == "GET":
            return self._json(200, s.status(rid))
        raise Refused(405, "method not allowed")

    # ---- loopback
    def _admin(self):
        s, path, method = self.signer, self.path.split("?")[0], self.command
        if path == "/admin/status" and method == "GET":
            return self._json(200, s.info())
        if path == "/admin/import" and method == "POST":
            body = json.loads(self._body(4 * 1024 * 1024) or b"{}")
            try:
                bundle = base64.b64decode(body.get("bundle", ""), validate=True)
            except ValueError:
                raise Refused(400, "bundle: base64") from None
            return self._json(200, s.import_bundle(bundle, str(body.get("bundle_key", ""))))
        if path == "/admin/secret" and method == "POST":
            body = self._jbody()
            return self._json(200, s.set_secret(str(body.get("name")), body.get("value")))
        if path in ("/", "/enrol") and method == "GET":
            return self._enrol_page()
        if path == "/enrol" and method == "POST":
            if self.headers.get("Origin") not in (None, "null") and not re.match(
                    r"http://(127\.0\.0\.1|localhost):\d+\Z", self.headers.get("Origin", "")):
                raise Refused(403, "cross-origin")
            from urllib.parse import parse_qs
            form = parse_qs(self._body(4096).decode("ascii", "replace"))
            verdict = s.enrol_confirm((form.get("code") or [""])[0].strip(), (form.get("csrf") or [""])[0])
            msg = {"ok": "Enrolled. This page is now closed for good; the signer asks for a code from "
                         "this authenticator entry for every signature.",
                   "enrolled": "Already enrolled.",
                   "wrong": "That code does not match. Check the phone's time and try the current code.",
                   "locked": "Too many wrong codes: the signer is locked for an hour.",
                   "csrf": "This form has expired: reload the page."}[verdict]
            if verdict in ("ok", "enrolled"):
                return self._html(200, _page("BT Labs signer", f"<p>{html.escape(msg)}</p>"))
            return self._enrol_page(error=msg)
        raise Refused(404, "no such route")

    def _enrol_page(self, error: str | None = None):
        s = self.signer
        if s.enrolled():
            return self._html(200, _page("BT Labs signer", "<p>Already enrolled. This page is closed for good.</p>"))
        if not s.store.secrets().get("ed25519"):
            return self._html(200, _page("BT Labs signer", "<p>Import the key bundle first.</p>"))
        secret = s.enrol_secret()
        uri = crypto.otpauth_uri(secret, s.cfg["totp_account"], s.cfg["totp_issuer"])
        qr = _qr_svg(uri)
        grouped = " ".join(secret[i:i + 4] for i in range(0, len(secret), 4))
        body = (f"<p>Scan this in Google Authenticator (+ → Scan a QR code), or enter the setup key by hand "
                f"(time based).</p>{qr}<p class=k>{html.escape(grouped)}</p>"
                + (f"<p class=e>{html.escape(error)}</p>" if error else "")
                + "<form method=post action=/enrol><label>Then type the 6-digit code it shows: "
                  f"<input name=code inputmode=numeric autocomplete=one-time-code pattern=[0-9]{{6}} maxlength=6 required autofocus></label>"
                  f"<input type=hidden name=csrf value={html.escape(s._enrol_csrf)}> <button>Confirm</button></form>"
                  "<p>Once confirmed, this page closes for good. The secret never leaves this machine "
                  "except inside the encrypted key bundle.</p>")
        return self._html(200, _page("Enrol the signer's authenticator", body))


def _page(title: str, body: str) -> str:
    return ("<!doctype html><meta charset=utf-8><meta name=viewport content='width=device-width'>"
            f"<title>{html.escape(title)}</title><style>body{{font:16px system-ui;max-width:36em;margin:2em auto;"
            "padding:0 16px;background:#111;color:#eee}}.k{{font:20px monospace;letter-spacing:.1em}}"
            ".e{{color:#f88}}svg{{background:#fff;padding:12px}}input{{font-size:18px;width:7em}}</style>"
            f"<h1>{html.escape(title)}</h1>{body}")


def _qr_svg(text: str) -> str:
    try:
        import segno
    except ImportError:
        return "<p>(QR codes need the segno package; enter the setup key below instead.)</p>"
    import io
    buf = io.BytesIO()
    segno.make(text, error="m").save(buf, kind="svg", scale=6, border=2, xmldecl=False, svgns=True)
    return buf.getvalue().decode()


def serve(signer: Signer, stop: threading.Event | None = None) -> list:
    """Starts both listeners and the approval loop on threads; returns the servers. The tailnet
    address is retried every 15 s until it is up (the service can start before Tailscale)."""
    cfg = signer.cfg
    check_listen(cfg["listen"])
    servers = []

    def make(host, port, admin):
        h = type("H", (Handler,), {"signer": signer, "admin": admin})
        srv = _Server((host, int(port)), h)
        threading.Thread(target=srv.serve_forever, name=f"http-{host}", daemon=True).start()
        servers.append(srv)
        log.info("listening on %s:%s (%s)", host, port, "loopback admin" if admin else "tailnet API")

    make("127.0.0.1", cfg["admin_port"], True)

    def tailnet():
        while not signer.stop.is_set():
            try:
                make(cfg["listen"], cfg["port"], False)
                return
            except OSError as e:
                log.warning("cannot listen on %s:%s yet (%s); retrying in 15 s", cfg["listen"], cfg["port"], e)
                signer.stop.wait(15)

    threading.Thread(target=tailnet, name="tailnet-bind", daemon=True).start()
    threading.Thread(target=signer.loop, name="approval", daemon=True).start()
    return servers


def setup_logging(data_dir: str, stderr: bool = False) -> None:
    root = logging.getLogger()
    root.setLevel(logging.INFO)
    fh = logging.handlers.RotatingFileHandler(os.path.join(data_dir, "btsign.log"), maxBytes=2_000_000,
                                              backupCount=5, encoding="utf-8")
    fh.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(name)s: %(message)s"))
    root.addHandler(fh)
    if stderr:
        root.addHandler(logging.StreamHandler())
