# SPDX-License-Identifier: Apache-2.0
"""One run = one folder: <state_root>/<version>/run-<n>/.

  run.json        inputs: version, commit, scope, test, target, relmsg release id, kind, taint
  release.toml    the resolved scope
  plan.json       the expanded steps, every command filled in
  events.jsonl    one line per event (start, end, gate, alert, metric, note)
  steps/<id>/     status.json, attempt-<n>.log (log.txt = the latest), out/ (the step's stage)
  files/          the release's published files + SHA256SUMS + provenance.json
  extra/          kept, never published (emulator APKs, Play bundle)
  manifests/      update.json, update-v2.json and their payloads
  handoff/<id>/   job/ (what the Mac gets) and results/ (what it sends back)
  summary.md, report.html
<state_root>/metrics.jsonl gathers every step's numbers across runs; published.json lists the
published runs (the current release and the previous one, kept for rollback).
"""
import datetime as dt
import fcntl
import json
import os
import time

from .graph import Step

STATUSES = ("pending", "running", "waiting", "done", "failed", "skipped", "held", "closed")
SETTLED = ("done", "skipped")


def now_iso():
    return dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def write_json(path, data):
    tmp = f"{path}.tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, sort_keys=False)
        f.write("\n")
    os.replace(tmp, path)


def read_json(path, default=None):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return default


class Busy(Exception):
    pass


class Run:
    def __init__(self, path):
        self.path = path
        self.info = read_json(os.path.join(path, "run.json"))
        if self.info is None:
            raise FileNotFoundError(f"{path}: not a run folder (no run.json)")
        self.steps = [Step.from_dict(d) for d in read_json(os.path.join(path, "plan.json"), [])]
        self._lock = None

    # ---- creation and lookup ----

    @classmethod
    def create(cls, state_root, version, info, scope_text, steps):
        vdir = os.path.join(state_root, version)
        os.makedirs(vdir, exist_ok=True)
        n = 1 + max([int(d[4:]) for d in os.listdir(vdir) if d.startswith("run-") and d[4:].isdigit()] or [0])
        path = os.path.join(vdir, f"run-{n}")
        os.makedirs(path)
        for d in ("steps", "files", "extra", "manifests", "handoff"):
            os.makedirs(os.path.join(path, d))
        info = dict(info, run_id=f"{version}-run{n}", run=path, created=now_iso())
        write_json(os.path.join(path, "run.json"), info)
        with open(os.path.join(path, "release.toml"), "w", encoding="utf-8") as f:
            f.write(scope_text)
        write_json(os.path.join(path, "plan.json"), [s.to_dict() for s in steps])
        r = cls(path)
        for s in steps:
            os.makedirs(r.step_dir(s.id), exist_ok=True)
            r.set_status(s.id, status="pending", attempts=0)
        r.event("run", "created", version=version, commit=info.get("commit"), test=info.get("test"))
        return r

    @staticmethod
    def next_path(state_root, version):
        vdir = os.path.join(state_root, version)
        n = 1
        if os.path.isdir(vdir):
            n += max([int(d[4:]) for d in os.listdir(vdir) if d.startswith("run-") and d[4:].isdigit()] or [0])
        return os.path.join(vdir, f"run-{n}"), f"{version}-run{n}"

    @staticmethod
    def find(state_root, ref=None):
        """ref: a run folder, a run id (26.10.25-run2), a version (its newest run), or None (the
        newest run of any version)."""
        if ref and os.path.isfile(os.path.join(ref, "run.json")):
            return Run(os.path.abspath(ref))
        runs = Run.all(state_root)
        if ref:
            runs = [r for r in runs if r[1] == ref or r[0] == ref]
        if not runs:
            raise FileNotFoundError(f"no run{' ' + ref if ref else ''} under {state_root}")
        return Run(runs[-1][2])

    @staticmethod
    def all(state_root):
        """[(version, run_id, path, created)] sorted by creation."""
        out = []
        if not os.path.isdir(state_root):
            return out
        for v in os.listdir(state_root):
            vdir = os.path.join(state_root, v)
            if v.startswith(".") or not os.path.isdir(vdir):
                continue
            for d in os.listdir(vdir):
                info = read_json(os.path.join(vdir, d, "run.json"))
                if info:
                    out.append((v, info["run_id"], os.path.join(vdir, d), info.get("created", "")))
        return sorted(out, key=lambda r: r[3])

    # ---- locking: one tools/rel process per run ----

    def lock(self):
        f = open(os.path.join(self.path, ".lock"), "w")
        try:
            fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            f.close()
            raise Busy(f"another tools/rel is working on {self.info['run_id']}")
        self._lock = f

    def unlock(self):
        if self._lock:
            self._lock.close()
            self._lock = None

    # ---- paths ----

    def step(self, sid):
        for s in self.steps:
            if s.id == sid:
                return s
        bases = [s for s in self.steps if s.base == sid]
        if len(bases) == 1:
            return bases[0]
        raise KeyError(sid)

    def step_dir(self, sid):
        return os.path.join(self.path, "steps", sid)

    @property
    def files(self):
        return os.path.join(self.path, "files")

    @property
    def extra(self):
        return os.path.join(self.path, "extra")

    # ---- status ----

    def status(self, sid):
        return read_json(os.path.join(self.step_dir(sid), "status.json"), {"status": "pending", "attempts": 0})

    def set_status(self, sid, **kw):
        os.makedirs(self.step_dir(sid), exist_ok=True)
        st = self.status(sid)
        st.update(kw)
        write_json(os.path.join(self.step_dir(sid), "status.json"), st)
        return st

    def save_info(self):
        write_json(os.path.join(self.path, "run.json"), self.info)

    def event(self, step, event, **kw):
        line = {"ts": now_iso(), "t": round(time.time(), 3), "run": self.info["run_id"], "step": step, "event": event}
        line.update({k: v for k, v in kw.items() if v is not None})
        with open(os.path.join(self.path, "events.jsonl"), "a", encoding="utf-8") as f:
            f.write(json.dumps(line, sort_keys=False) + "\n")
        return line

    def events(self):
        out = []
        try:
            with open(os.path.join(self.path, "events.jsonl"), encoding="utf-8") as f:
                for line in f:
                    if line.strip():
                        out.append(json.loads(line))
        except FileNotFoundError:
            pass
        return out

    def taint(self, reason):
        self.info.setdefault("tainted", []).append({"at": now_iso(), "reason": reason})
        self.save_info()
        self.event("run", "tainted", reason=reason)

    def summary_rows(self):
        rows = []
        for s in self.steps:
            st = self.status(s.id)
            rows.append({"id": s.id, "title": s.title, "phase": s.phase, "kind": s.kind, "host": s.host,
                         "status": st.get("status"), "attempts": st.get("attempts", 0),
                         "duration_s": st.get("duration_s"), "note": st.get("note"), "reason": st.get("reason"),
                         "hint": st.get("hint"), "bytes": st.get("bytes")})
        return rows
