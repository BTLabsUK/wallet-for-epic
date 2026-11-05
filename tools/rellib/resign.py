# SPDX-License-Identifier: Apache-2.0
"""`tools/rel resign`: the live update manifests (update.json and update-v2.json) signed again
unchanged, with only a new serial (= issued_at) and a new expiry ([manifest] validity_days of
release/pipeline.toml), so a short validity does not need a release to stay fresh (WAL-01).

The live files are the source: each must verify against the shipped keyring and name the
current release (the newest one tools/rel published: its kept payloads) in everything but
serial, issued_at and expires_at. Both are signed in one request to the release signer (one
approval in Telegram; the job carries the live file as `prev`, so the signer's tool refuses a
serial that is not higher), verified against the shipped keyring, checked again to differ from
the live files only in those three fields, and published the way the manifests step does
(tools/publish-update-json.sh) after a second read of the live files: anything changed on the
server in the meantime, or anything that no longer matches the current release, stops it.
Then every copy is read back. Its record stays in <state root>/resign/<UTC time>/.

--test signs with the test key of app/test/fixtures/btlabs/ and reads and writes a folder
(--live-dir) instead of the server: nothing leaves this machine."""
import pathlib
import base64
import datetime as dt
import hashlib
import json
import os
import shutil
import subprocess
import time
import tomllib
import types

from .run import write_json

# The only payload fields a re-sign may change.
DATES = ("serial", "issued_at", "expires_at")
NAMES = (("update.json", "update.payload.json"), ("update-v2.json", "update-v2.payload.json"))
FIXTURES = "app/test/fixtures/btlabs"


class ResignError(Exception):
    """Refused: the message says why. Nothing was published."""


def iso(t):
    return dt.datetime.fromtimestamp(t, dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def parse_iso(s):
    return int(dt.datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=dt.timezone.utc).timestamp())


def payload_bytes(envelope):
    return base64.b64decode(json.loads(envelope)["payload"], validate=True)


def without_dates(payload):
    return {k: v for k, v in payload.items() if k not in DATES}


def differences(old, new):
    """The top-level fields of two payloads that differ, other than DATES (sorted)."""
    a, b = without_dates(old), without_dates(new)
    gone = object()
    return sorted(k for k in set(a) | set(b) if a.get(k, gone) != b.get(k, gone))


def resigned(payload_raw, serial, days):
    """The payload bytes with only serial, issued_at and expires_at replaced (fields in their
    order; written as release_android.sh's jq writes it: 2-space indent, UTF-8, newline)."""
    p = json.loads(payload_raw)
    for k in DATES:
        if k not in p:
            raise ResignError(f"the live payload has no {k}")
    p["serial"], p["issued_at"], p["expires_at"] = serial, iso(serial), iso(serial + days * 86400)
    return (json.dumps(p, indent=2, ensure_ascii=False) + "\n").encode("utf-8")


def check_only_dates(old_raw, new_raw, days):
    """Problems (a list; empty = fine) of a re-signed payload against the one it replaces."""
    old, new = json.loads(old_raw), json.loads(new_raw)
    out = [f"{k} changed" for k in differences(old, new)]
    if not isinstance(new.get("serial"), int) or not isinstance(old.get("serial"), int) or new["serial"] <= old["serial"]:
        out.append(f"serial {new.get('serial')} is not above {old.get('serial')}")
    elif new.get("issued_at") != iso(new["serial"]):
        out.append(f"issued_at {new.get('issued_at')} is not the serial {new['serial']}")
    elif new.get("expires_at") != iso(new["serial"] + days * 86400):
        out.append(f"expires_at {new.get('expires_at')} is not {days} days after issued_at")
    return out


def new_serial(*floors):
    return max([int(time.time())] + [int(f) + 1 for f in floors if f is not None])


class Resign:
    """One re-sign. The I/O is in small methods (read_live, sign, publish) that --test and the
    tests replace; the checks around them are the same in every mode."""

    def __init__(self, repo, state_root, pipeline, hosts, say=print, test=False, live_dir=None):
        self.repo, self.state_root, self.pipeline, self.hosts, self.say = repo, state_root, pipeline, hosts, say
        self.test, self.live_dir = test, live_dir
        self.days = pipeline.manifest_days()
        signer = hosts["host"].get("signer", {})
        self.bp = signer.get("btlabs_public", os.path.expanduser("~/code/btlabs-public"))
        self.tool = os.path.join(self.bp, "tool/btlabs_sign.py")
        self.cfg = os.path.join(repo, "app/assets/config/app-config.toml")
        if test:
            self.keyring = os.path.join(repo, FIXTURES, "test-keyring.json")
        else:
            self.keyring = os.path.join(self.bp, "keys/btlabs-keyring.json")
        old = tomllib.loads(pathlib.Path(os.path.join(repo, "app/tool/config/old-update.toml")).read_text(encoding="utf-8"))["old_update"]
        new = tomllib.loads(pathlib.Path(self.cfg).read_text(encoding="utf-8"))["updates"]
        self.urls = {"update.json": old["manifest"], "update-v2.json": new["manifests"][0]}

    # ---- I/O ----

    def read_live(self):
        """{name: bytes} of both live manifests."""
        out = {}
        for name, _ in NAMES:
            if self.live_dir:
                with open(os.path.join(self.live_dir, name), "rb") as f:
                    out[name] = f.read()
            else:
                from .builtins import fetch
                try:
                    out[name] = fetch(self.urls[name])
                except Exception as e:
                    raise ResignError(f"live {name} ({self.urls[name]}) unreadable: {e}")
        return out

    def sign(self, version, work, jobs):
        """Signs every job ({payload, out, prev[, app_config]}) into work/<out>."""
        if self.test:
            # btlabs_sign.py takes a key file only when it is private: a 0600 copy of the fixture.
            key = os.path.join(self.work, "test-a.key")
            shutil.copyfile(os.path.join(self.repo, FIXTURES, "test-a.key"), key)
            os.chmod(key, 0o600)
            for j in jobs:
                cmd = ["python3", self.tool, "sign", "--type", "update", "--key", key, "--keyring", self.keyring,
                       "--payload", j["payload"], "--prev", j["prev"], "--out", os.path.join(work, j["out"])]
                if j.get("app_config"):
                    cmd += ["--app-config", j["app_config"]]
                self._run(cmd, f"signing {j['out']}")
            return
        from . import signer as btsign
        if not btsign.endpoint(self.hosts):
            raise ResignError("no signer: set endpoint under [host.signer] (docs/RELEASING.md, \"Signer\"); "
                              "a re-sign never reads a key file on this machine")
        engine = types.SimpleNamespace(hosts=self.hosts)
        try:
            btsign.client(engine, self.say).sign(version, [dict(j, op="update-manifest") for j in jobs], work,
                                                 label=f"RE-SIGN {version}: new serial and expiry only")
        except Exception as e:
            raise ResignError(f"signer: {e}")

    def publish(self, files):
        if self.live_dir:
            for name, path in files.items():
                shutil.copyfile(path, os.path.join(self.live_dir, name))
            return
        self._run([os.path.join(self.repo, "tools/publish-update-json.sh"), files["update.json"], files["update-v2.json"]],
                  "tools/publish-update-json.sh", cwd=self.repo, timeout=900)

    def _run(self, cmd, what, cwd=None, timeout=300):
        p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=timeout)
        out = (p.stdout + p.stderr).strip()
        if out:
            self.say(out[-3000:])
        if p.returncode != 0:
            raise ResignError(f"{what} failed (exit {p.returncode})")
        return p.stdout

    def verify(self, name, path, at=None):
        """The envelope at path verifies against the keyring (as of `at`, an ISO time: a live file
        that already expired still proves its signature)."""
        cmd = ["python3", self.tool, "verify", "--type", "update", "--keyring", self.keyring, "--envelope", path]
        if name == "update-v2.json":
            cmd += ["--app-config", self.cfg]
        if at:
            cmd += ["--now", at]
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        if p.returncode != 0:
            raise ResignError(f"{name} does not verify against {self.keyring}: {(p.stdout + p.stderr).strip()[-300:]}")

    # ---- the checks ----

    def current_release(self):
        """(version, {name: payload bytes}) of the newest release tools/rel published."""
        from .retention import published
        pubs = [p for p in published(self.state_root) if os.path.isdir(p["run"])]
        if not pubs:
            raise ResignError(f"nothing published by tools/rel in {self.state_root}: no current release to compare "
                              "the live manifests with")
        cur = pubs[-1]
        out = {}
        for name, pname in NAMES:
            p = os.path.join(cur["run"], "manifests", pname)
            if not os.path.isfile(p):
                raise ResignError(f"the current release {cur['version']} ({cur['run_id']}) kept no {pname}")
            with open(p, "rb") as f:
                out[name] = f.read()
        return cur["version"], out

    def check_live(self, live, release_version, release):
        """Both live files verify, name the current release and share one serial: their payloads."""
        payloads = {}
        for name, _ in NAMES:
            try:
                raw = payload_bytes(live[name])
                pl = json.loads(raw)
            except Exception as e:
                raise ResignError(f"live {name} is not a signed manifest: {e}")
            tmp = os.path.join(self.work, f"live-{name}")
            with open(tmp, "wb") as f:
                f.write(live[name])
            self.verify(name, tmp, at=pl.get("issued_at"))
            diff = differences(json.loads(release[name]), pl)
            if diff:
                raise ResignError(f"live {name} is not the current release {release_version} "
                                  f"(differs in {', '.join(diff)}): run a release or a rollback instead")
            payloads[name] = raw
        serials = {json.loads(p)["serial"] for p in payloads.values()}
        if len(serials) != 1:
            raise ResignError(f"the live files carry different serials ({sorted(serials)}): publish them together first")
        return payloads

    # ---- the whole re-sign ----

    def run(self, dry=False):
        current = self.current_release()  # refused before anything is written
        stamp = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
        self.work = os.path.join(self.state_root, "resign", stamp + ("-test" if self.test else ""))
        os.makedirs(self.work, exist_ok=True)
        record = {"started": iso(int(time.time())), "test": self.test, "days": self.days, "status": "started"}
        try:
            res = self._run_checked(dry, record, *current)
            record.update(res, status="dry" if dry else "published")
            return res
        except ResignError as e:
            record.update(status="refused", reason=str(e))
            raise
        finally:
            write_json(os.path.join(self.work, "resign.json"), record)

    def _run_checked(self, dry, record, version, release):
        live = self.read_live()
        old = self.check_live(live, version, release)
        old_serial = json.loads(old["update.json"])["serial"]
        old_expiry = json.loads(old["update.json"])["expires_at"]
        serial = new_serial(old_serial)
        self.say(f"live: {version}, serial {old_serial}, expires {old_expiry}")
        jobs, payloads = [], {}
        for name, pname in NAMES:
            raw = resigned(old[name], serial, self.days)
            problems = check_only_dates(old[name], raw, self.days)
            if problems:
                raise ResignError(f"{name}: " + "; ".join(problems))
            pp = os.path.join(self.work, pname)
            with open(pp, "wb") as f:
                f.write(raw)
            payloads[name] = raw
            job = {"payload": pp, "out": name, "prev": os.path.join(self.work, f"live-{name}")}
            if name == "update-v2.json":
                job["app_config"] = self.cfg
            jobs.append(job)
        new_expiry = iso(serial + self.days * 86400)
        record.update(version=version, old_serial=old_serial, old_expires=old_expiry, serial=serial, expires=new_expiry)
        self.say(f"new: serial {serial}, expires {new_expiry} ({self.days} days); nothing else changes")
        if dry:
            return {"version": version, "serial": serial, "expires": new_expiry, "work": self.work}
        out = os.path.join(self.work, "signed")
        os.makedirs(out, exist_ok=True)
        self.sign(version, out, jobs)
        files = {}
        for name, _ in NAMES:
            path = os.path.join(out, name)
            if not os.path.isfile(path):
                raise ResignError(f"the signer returned no {name}")
            self.verify(name, path)
            with open(path, "rb") as f:
                got = payload_bytes(f.read())
            if got != payloads[name]:
                raise ResignError(f"signed {name} carries another payload than the one sent")
            problems = check_only_dates(old[name], got, self.days)
            if problems:
                raise ResignError(f"signed {name}: " + "; ".join(problems))
            files[name] = path
        # Read the live files again just before publishing: still the current release, and
        # exactly the bytes this re-sign started from.
        again = self.read_live()
        for name, _ in NAMES:
            if again[name] != live[name]:
                raise ResignError(f"live {name} changed while re-signing: nothing published; run tools/rel resign again")
        self.check_live(again, version, release)
        self.publish(files)
        back = self.read_live()
        bad = [n for n, p in files.items() if back[n] != pathlib.Path(p).read_bytes()]
        if bad:
            raise ResignError(f"published, but {', '.join(bad)} does not read back as signed (a cache, or another "
                              f"publisher): check {', '.join(self.urls[n] for n in bad)}")
        for n, p in files.items():
            record.setdefault("sha256", {})[n] = hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
        return {"version": version, "serial": serial, "expires": new_expiry, "work": self.work}


def live_expiry_warning(repo, warn_days, fetch=None, now=None):
    """None, or a warning when a live manifest expires within warn_days (or cannot be read)."""
    if fetch is None:
        from .builtins import fetch
    old = tomllib.loads(pathlib.Path(os.path.join(repo, "app/tool/config/old-update.toml")).read_text(encoding="utf-8"))["old_update"]
    new = tomllib.loads(pathlib.Path(os.path.join(repo, "app/assets/config/app-config.toml")).read_text(encoding="utf-8"))["updates"]
    now = int(time.time()) if now is None else now
    soonest = None
    for name, url in (("update.json", old["manifest"]), ("update-v2.json", new["manifests"][0])):
        try:
            exp = parse_iso(json.loads(payload_bytes(fetch(url)))["expires_at"])
        except Exception as e:
            return f"live {name} unreadable ({e}): its expiry is not checked"
        if soonest is None or exp < soonest[1]:
            soonest = (name, exp)
    name, exp = soonest
    days = (exp - now) / 86400
    if days < warn_days:
        when = f"expired {iso(exp)}" if days <= 0 else f"expires {iso(exp)} (in {days:.1f} days)"
        return f"live {name} {when}: run tools/rel resign (or release)"
    return None
