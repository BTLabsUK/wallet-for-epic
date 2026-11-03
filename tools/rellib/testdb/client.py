# SPDX-License-Identifier: Apache-2.0
"""Emitting events into the test DB queue, and reading the DB. Stdlib only.

emit(kind, source="engine", **fields) never raises and never blocks more than about 100 ms: it drops
one JSON file in the inbox (written to .tmp-*, then renamed) and drains the inbox opportunistically
when nobody else holds the writer lock. With TESTDB_URL set (a remote machine) it POSTs to
`testdb serve` instead (3 s timeout; TESTDB_TOKEN is sent as a bearer token) and on failure spools
the event to a local dir; `testdb push` resends the spool.

Paths: DB /tmp/epic-build/rel/tests.db; inbox tests.inbox/, lock tests.db.lock, spool tests.spool/
beside it. REL_TESTDB overrides the DB path (then wins over the `db=` argument too); REL_TESTDB=off
makes emit a no-op (so does running under unittest with no REL_TESTDB and no db=).

Events (fields besides these are kept in the event body; `ts` defaults to now, UTC ISO):
  run.start      run, kind, version, note
  run.end        run, state (ok|failed|waiting|...), note
  lane.start     run, lane, platform, variant
  lane.end       run, lane, state, cause_class, cause, note
  attempt.start  run, lane, n, platform, variant
  attempt.end    run, lane, n, state (ok|failed|...), rc, cause_class (PRODUCT|INFRA|HARNESS-ui),
                 cause, note, log_path, out_dir
  attempt.heartbeat  run, lane, n
  step.start     run, lane, n, step, detail
  step.end       run, lane, n, step, state (ok|skipped|failed|recovered), detail
  failure        run, lane, n, step, cause_class, cause, what, resolved_by
  bundle         run, lane, n, step, dir, screen_path, log_tail_path, shot_path
  playbook.propose  key, situation, fix, source_failure, version_added
  playbook.set_state  key, state (open|accepted|rejected)
  aipath.put     key, platform, goal, screen_sig, actions
  aipath.hit / aipath.fail   key
  aipath.set_state  key, state (new|replayed|reviewed|promoted|rejected), reviewed_by
Missing run/lane/n fall back to the env WFE_RELEASE_RUN, WFE_RELEASE_STEP, WFE_RELEASE_ATTEMPT.
Any field named password/passphrase/phrase/seed/mnemonic, or any text with 12+ short lower-case
words in a row, makes the writer refuse the whole event (counted, never stored).
"""
import itertools
import json
import os
import socket
import sqlite3
import sys
import time
import urllib.request

KINDS = frozenset("""run.start run.end lane.start lane.end attempt.start attempt.end attempt.heartbeat
step.start step.end failure bundle playbook.propose playbook.set_state aipath.put aipath.hit aipath.fail
aipath.set_state""".split())
MAX_EVENT = 256 * 1024
DRAIN_BUDGET = 0.1
HOST = socket.gethostname()
_seq = itertools.count(1)


def db_path(db=None):
    return os.path.abspath(os.path.expanduser(os.environ.get("REL_TESTDB") or db or "/tmp/epic-build/rel/tests.db"))


def sibling(db, suffix):
    base = db[:-3] if db.endswith(".db") else db
    return base + suffix


def inbox_dir(db):
    return sibling(db, ".inbox")


def spool_dir(db):
    return sibling(db, ".spool")


def lock_path(db):
    return db + ".lock"


def disabled(db=None):
    """REL_TESTDB=off turns emitting into a no-op. So does running under unittest/pytest with neither
    REL_TESTDB nor an explicit db: a test never writes to the real /tmp/epic-build/rel/tests.db."""
    env = os.environ.get("REL_TESTDB")
    if env is not None:
        return env.lower() in ("off", "none", "0")
    return db is None and ("unittest" in sys.modules or "pytest" in sys.modules)


def now_ts():
    t = time.time()
    return time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime(t)) + ".%06dZ" % int((t % 1) * 1e6)


def cause_class(cause):
    """The class of a window.cause_of cause: infra:* -> INFRA, product -> PRODUCT, harness* -> HARNESS-ui,
    anything else (step, check, timeout, error) -> None."""
    c = cause or ""
    if c.startswith("infra:") or c == "infra":
        return "INFRA"
    if c == "product":
        return "PRODUCT"
    if c.startswith("harness"):
        return "HARNESS-ui"
    return None


def make_event(kind, source, fields):
    seq = next(_seq)
    ns = time.time_ns()
    ev = {"eid": "%s-%s-%d-%d-%d" % (HOST, source, os.getpid(), ns, seq), "ts": fields.pop("ts", None) or now_ts(),
          "host": HOST, "source": source, "seq": seq, "kind": kind, "_ns": ns}
    for field, env in (("run", "WFE_RELEASE_RUN"), ("lane", "WFE_RELEASE_STEP"), ("n", "WFE_RELEASE_ATTEMPT")):
        if fields.get(field) is None and os.environ.get(env):
            fields[field] = int(os.environ[env]) if field == "n" and os.environ[env].isdigit() else os.environ[env]
    if "eid" in fields:  # a caller's own id (the importer's): the same event twice is one event
        ev["eid"] = str(fields.pop("eid"))
    ev["body"] = {k: v for k, v in fields.items() if v is not None}
    return ev


def drop(inbox, ev):
    """Writes one event into an inbox dir: .tmp-* first, then the atomic rename to its final name."""
    os.makedirs(inbox, exist_ok=True)
    name = "%019d-%s-%d-%d.json" % (ev.get("_ns") or time.time_ns(), ev.get("host", HOST), os.getpid(), ev.get("seq") or 0)
    tmp = os.path.join(inbox, ".tmp-" + name)
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(ev, f, default=str)
    os.rename(tmp, os.path.join(inbox, name))
    return name


def post(url, payload, timeout=3):
    headers = {"Content-Type": "application/json"}
    if os.environ.get("TESTDB_TOKEN"):
        headers["Authorization"] = "Bearer " + os.environ["TESTDB_TOKEN"]
    req = urllib.request.Request(url.rstrip("/") + "/events", data=json.dumps(payload, default=str).encode(), headers=headers)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.status


def emit(kind, source="cli", db=None, **fields):
    """Queues one event; returns its eid, or None when it could not be queued. Never raises."""
    try:
        if disabled(db):
            return None
        path = db_path(db)
        ev = make_event(kind, source, fields)
        url = os.environ.get("TESTDB_URL")
        if url:
            try:
                post(url, ev)
            except Exception:  # noqa: BLE001 - offline: keep it for `testdb push`
                drop(spool_dir(path), ev)
            return ev["eid"]
        drop(inbox_dir(path), ev)
        try:
            from . import writer
            writer.drain(path, budget=DRAIN_BUDGET)
        except Exception:  # noqa: BLE001 - the writer service drains it later
            pass
        return ev["eid"]
    except Exception:  # noqa: BLE001
        return None


def push(db=None, timeout=3):
    """Resends the spool to TESTDB_URL; returns (sent, left)."""
    url = os.environ.get("TESTDB_URL")
    d = spool_dir(db_path(db))
    if not url or not os.path.isdir(d):
        return 0, 0
    sent = 0
    names = sorted(n for n in os.listdir(d) if n.endswith(".json"))
    for n in names:
        p = os.path.join(d, n)
        try:
            with open(p, encoding="utf-8") as f:
                post(url, json.load(f), timeout)
            os.remove(p)
            sent += 1
        except Exception:  # noqa: BLE001
            break
    return sent, len(names) - sent


def read(db=None):
    """A read-only connection (rows are sqlite3.Row), or raises when there is no DB."""
    path = db_path(db)
    if not os.path.exists(path):
        raise FileNotFoundError(path)
    conn = sqlite3.connect("file:%s?mode=ro" % path, uri=True, timeout=5)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA busy_timeout=5000")
    return conn


def path_lookup(key, db=None):
    """The cached AI path stored under key as a dict (actions decoded), or None when there is none, it
    is rejected, or the DB cannot be read. Read-only."""
    try:
        conn = read(db)
        try:
            row = conn.execute("SELECT * FROM ai_paths WHERE key=?", (key,)).fetchone()
        finally:
            conn.close()
        if row is None or row["state"] == "rejected":
            return None
        out = dict(row)
        out["actions"] = json.loads(out["actions"]) if out.get("actions") else None
        return out
    except Exception:  # noqa: BLE001
        return None
