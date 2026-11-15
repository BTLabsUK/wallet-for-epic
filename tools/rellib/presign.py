# SPDX-License-Identifier: Apache-2.0
"""Pre-signed manifests for a rollback and a roll-forward (docs/RELEASING.md, "Rollback").

Installed apps keep the highest manifest serial they accepted and refuse a lower one, so a release
put back on the server needs a manifest pair with a serial above whatever is live. The signer is
the slow, remote part: so it signs ahead. Every version folder on the server holds a ladder of
spare pairs in versions/<v>/spare/<serial>/ (0700, root): the version's own published payloads
with only serial, issued_at and expires_at replaced. A rollback signs nothing: relsrv.py switch
picks the spare of the target with the lowest serial above the live one.

The ladder has two versions, the live one and the one a rollback or roll-forward goes to (the
other). Their rungs alternate, the other version first, so each switch back and forth finds a
rung above the one just installed:   live L < other base+1 < live base+2 < other base+3 ...
The serial is an integer only (the apps and the signer do not tie it to issued_at); issued_at is
the signing time and expires_at is [manifest] validity_days after it, so a ladder is as fresh as
its last refresh. `tools/rel resign` and every release refresh it (this module), a rollback
refuses when no rung is above the live serial and says so.

Also here: the pre-signed update-v2.json of the other version goes onto its GitHub release
(tools/release-files.py github-put), so the GitHub flip needs no upload while it is current."""
import json
import os
import pathlib
import subprocess
import sys
import tarfile
import time

from .resign import NAMES, Resign, ResignError, differences, iso, payload_bytes

RUNGS = 4  # round trips (rollback + roll-forward) before the next refresh


def spare_payload(raw, serial, now, days):
    """The payload bytes with serial, issued_at and expires_at replaced (as resign.resigned
    writes them), the serial free of issued_at."""
    p = json.loads(raw)
    p["serial"], p["issued_at"], p["expires_at"] = serial, iso(now), iso(now + days * 86400)
    return (json.dumps(p, indent=2, ensure_ascii=False) + "\n").encode("utf-8")


def neighbours(state):
    """(previous, next) of the live version in the publish history (None where there is none)."""
    live, hist = state.get("live"), [v for v in state.get("history", []) if state.get("versions", {}).get(v)]
    if live not in hist:
        return None, None
    i = hist.index(live)
    return (hist[i - 1] if i > 0 else None), (hist[i + 1] if i + 1 < len(hist) else None)


def other_version(state):
    """The version the ladder prepares next to the live one: the release a roll-forward goes to
    when live is not the newest (the undo of the last rollback), else the previous release."""
    prev, nxt = neighbours(state)
    return nxt or prev


def plan(serials_floor, live, other, now, rungs=RUNGS):
    """[(version, serial)] in the order of the ladder: the other version first, then the live one."""
    base = max(int(now), int(serials_floor))
    out = []
    for k in range(1, rungs + 1):
        out.append((other, base + 2 * k - 1))
        out.append((live, base + 2 * k))
    return out


class Presign:
    def __init__(self, repo, state_root, pipeline, hosts, server, say=print, test=False):
        self.repo, self.server, self.say, self.test = repo, server, say, test
        self.signer = Resign(repo, state_root, pipeline, hosts, say=say, test=test, live_dir=None)
        self.days = self.signer.days
        self.state_root = state_root

    def refresh(self, work, dry=False, github=True, other=None):
        """Signs and installs the ladder of the live version and the other one. -> summary dict."""
        st = self.server.state()
        live = st["live"]
        if not live:
            raise ResignError("the server has no versions/current yet: run tools/rel migrate-layout first")
        other = other or other_version(st)
        if other is None:
            self.say("only one release on the server: no rollback target, nothing to pre-sign")
            return {"live": live, "other": None, "pairs": 0}
        floor = max(s for s in st["live_serial"].values() if s is not None)
        now = int(time.time())
        steps = plan(floor, live, other, now)
        os.makedirs(work, exist_ok=True)
        self.signer.work = work
        jobs, expect = [], {}
        sources = {}
        for v in (live, other):
            for name, _ in NAMES:
                sources[(v, name)] = self.server.read_remote(os.path.join(self.server.R, "versions", v, name))
        live_files = {name: self.server.read_remote(path) for name, path in
                      (("update.json", os.path.join(self.server.R, "update.json")), ("update-v2.json", self.server.API))}
        prevs = {}
        for name, _ in NAMES:
            prevs[name] = os.path.join(work, f"live-{name}")
            pathlib.Path(prevs[name]).write_bytes(live_files[name])
        for v, serial in steps:
            for name, _ in NAMES:
                raw = payload_bytes(sources[(v, name)])
                body = spare_payload(raw, serial, now, self.days)
                out = f"{v}.{serial}.{name}"
                pp = os.path.join(work, out + ".payload")
                pathlib.Path(pp).write_bytes(body)
                job = {"payload": pp, "out": out, "prev": prevs[name]}
                if name == "update-v2.json":
                    job["app_config"] = self.signer.cfg
                jobs.append(job)
                expect[out] = (v, serial, name, body, raw)
        self.say(f"pre-signing {len(jobs)} manifests: {live} (live) and {other}, serials {steps[0][1]}..{steps[-1][1]}"
                 f" (live serial {floor})")
        if dry:
            return {"live": live, "other": other, "pairs": len(steps), "dry": True}
        signed = os.path.join(work, "signed")
        os.makedirs(signed, exist_ok=True)
        t0 = time.monotonic()
        self.signer.sign(live, signed, jobs)
        self.say(f"signed in {time.monotonic() - t0:.1f} s")
        tars = {live: [], other: []}
        for out, (v, serial, name, body, raw) in expect.items():
            path = os.path.join(signed, out)
            if not os.path.isfile(path):
                raise ResignError(f"the signer returned no {out}")
            self.signer.verify(name, path)
            got = payload_bytes(pathlib.Path(path).read_bytes())
            if got != body:
                raise ResignError(f"signed {out} carries another payload than the one sent")
            if differences(json.loads(raw), json.loads(got)):
                raise ResignError(f"signed {out} differs from {v}'s own manifest in more than dates and serial")
            tars[v].append((f"{serial}/{name}", path))
        for v, members in tars.items():
            tpath = os.path.join(work, f"spares-{v}.tar")
            with tarfile.open(tpath, "w") as t:
                for arcname, path in members:
                    t.add(path, arcname=arcname)
            remote = self.server.put(tpath, f"spares-{v}.tar")
            self.say("  " + self.server.relsrv("spares", v, remote).strip())
        gh = None
        if github:
            gh = self.github_spare(other, work, steps)
        return {"live": live, "other": other, "pairs": len(steps), "github": gh,
                "first_serial": steps[0][1], "last_serial": steps[-1][1]}

    def github_spare(self, other, work, steps):
        """The first rung of `other` (update-v2.json) onto its GitHub release. A mirror: a failure
        is a warning, the website does not depend on it."""
        serial = min(s for v, s in steps if v == other)
        f = os.path.join(work, "signed", f"{other}.{serial}.update-v2.json")
        cmd = [sys.executable, os.path.join(self.repo, "tools/release-files.py"), "github-put", f"v{other}", f]
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        out = (p.stdout + p.stderr).strip()
        if p.returncode != 0:
            self.say(f"  warning: not on the GitHub release v{other}: {out[-300:]}")
            return "failed"
        self.say("  " + out.splitlines()[-1])
        return "ok"
