# SPDX-License-Identifier: Apache-2.0
"""Backfill: events from a tools/rel run folder (run.json, events.jsonl, steps/*/status.json,
attempt-N.log, out/proof.json). Read-only on the run folder. Event ids are derived from the run, step
and attempt, so importing the same folder twice changes nothing."""
import json
import os

from . import client, writer

PLATFORMS = ("android", "linux", "windows", "macos", "ios")


def _read(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def _events(path):
    out = []
    try:
        with open(path, encoding="utf-8") as f:
            for line in f:
                try:
                    out.append(json.loads(line))
                except ValueError:
                    pass
    except OSError:
        pass
    return out


def _tokens(step):
    parts = step.split("-")
    plat = next((p for p in parts if p in PLATFORMS), None)
    variant = "notor" if "notor" in parts else ("tor" if "tor" in parts else None)
    return plat, variant


def _t(e):
    return e.get("t") or e.get("ts")


def build(run_dir):
    """Returns the list of (kind, ts, eid, fields) for the run folder."""
    info = _read(os.path.join(run_dir, "run.json")) or {}
    run = info.get("run_id") or os.path.basename(os.path.normpath(run_dir))
    evs = _events(os.path.join(run_dir, "events.jsonl"))
    out = []

    def add(ev_kind, ts, tag, **f):
        out.append((ev_kind, ts, "import-%s-%s-%s" % (run, tag, ev_kind), dict(f, run=run)))

    created = info.get("created") or (evs[0].get("ts") if evs else None)
    add("run.start", created, "run", run_kind=info.get("kind"), version=info.get("version"),
        note="imported from %s" % os.path.basename(os.path.normpath(run_dir)))
    last_ts = max([_t(e) for e in evs if _t(e)] or [created or 0], key=str)
    steps_dir = os.path.join(run_dir, "steps")
    for step in sorted(os.listdir(steps_dir)) if os.path.isdir(steps_dir) else []:
        sdir = os.path.join(steps_dir, step)
        st = _read(os.path.join(sdir, "status.json")) or {}
        plat, variant = _tokens(step)
        base = {"lane": step, "platform": plat, "variant": variant}
        if st.get("status") == "skipped" and not st.get("attempts"):
            add("lane.end", created, step, state="skipped", note=st.get("reason"), **base)
            continue
        attempts, cur = {}, None
        for e in evs:
            if e.get("step") != step:
                continue
            if e.get("event") == "start" and e.get("attempt"):
                cur = attempts.setdefault(int(e["attempt"]), {"start": _t(e)})
                cur["end"] = None
            elif e.get("event") == "end" and cur is not None:
                cur.update(end=_t(e), status=e.get("status"), rc=e.get("rc"), cause=e.get("cause"), note=e.get("note"))
        n_total = int(st.get("attempts") or 0)
        causes = st.get("attempt_causes") or []
        for n in range(1, n_total + 1):
            attempts.setdefault(n, {})
        if not attempts and st.get("status") in ("done", "failed"):
            attempts[1] = {}
        for n in sorted(attempts):
            a = attempts[n]
            last = n == max(attempts)
            status = a.get("status") or (st.get("status") if last else "failed")
            cause = a.get("cause") or (st.get("cause") if last and status == "failed" else None)
            if not cause and status == "failed" and n <= len(causes):
                cause = causes[n - 1]
            state = {"done": "ok"}.get(status, status or "unknown")
            started = a.get("start") or (st.get("started") if n == 1 else None) or created
            ended = a.get("end") or (st.get("ended") if last else None) or started
            log = os.path.join(sdir, "attempt-%d.log" % n)
            outd = os.path.join(sdir, "out")
            add("attempt.start", started, "%s-%d" % (step, n), n=n, **base)
            note = a.get("note") or (st.get("note") if last else None)
            add("attempt.end", ended, "%s-%d" % (step, n), n=n, state=state, rc=a.get("rc", st.get("rc") if last else None),
                cause=cause, cause_class=client.cause_class(cause), note=note,
                log_path=log if os.path.exists(log) else None, out_dir=outd if os.path.isdir(outd) else None, **base)
            if state == "failed":
                fault = ((_read(os.path.join(outd, "proof.json")) or {}).get("fault") if last else None) or {}
                what = fault.get("what") or note or cause
                cc = {"product": "PRODUCT", "infra": "INFRA", "harness": "HARNESS-ui"}.get(fault.get("kind")) or \
                    client.cause_class(cause)
                add("failure", ended, "%s-%d" % (step, n), n=n, step=fault.get("step") or step, cause=cause,
                    cause_class=cc, what=what, **base)
    add("run.end", info.get("published") or last_ts, "run", state="ok" if (info.get("relmsg") or {}).get("ended") == "ok" else "ended")
    return out


def import_run(run_dir, db):
    """Queues the run's events and applies them; returns the number of events."""
    inbox = client.inbox_dir(db)
    events = build(run_dir)
    for i, (kind, ts, eid, f) in enumerate(events):
        ev = client.make_event(kind, "import", dict(f, ts=ts, eid=eid))
        ev["_ns"] = ev["_ns"] + i
        client.drop(inbox, ev)
    writer.drain(db, wait=True)
    return len(events)
