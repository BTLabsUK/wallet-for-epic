# SPDX-License-Identifier: Apache-2.0
"""The single writer: whoever holds the flock on tests.db.lock applies inbox files to the DB, in name
order, one transaction each. Migrations (numbered .sql files in migrations/) are applied here."""
import fcntl
import json
import os
import re
import shutil
import sqlite3
import time

from . import client

HERE = os.path.dirname(os.path.abspath(__file__))
# Same shape as drivers/core/recover.py PHRASE: 12+ short lower-case words in a row, maybe a recovery phrase.
PHRASE = re.compile(r"(\b[a-z]{3,8}\b[\s|,]+){12,}")
SECRET_KEY = re.compile(r"password|passphrase|phrase|seed|mnemonic", re.I)
PLAYBOOK_STATES = ("open", "accepted", "rejected")
PATH_STATES = ("new", "replayed", "reviewed", "promoted", "rejected")


class Refused(Exception):
    """An event holding something secret-shaped: counted, never stored."""


class Bad(Exception):
    """An event that cannot be applied: moved to inbox/bad/ with the reason."""


def connect(path, migrate=True):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    conn = sqlite3.connect(path, timeout=5, isolation_level=None)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA busy_timeout=5000")
    conn.execute("PRAGMA foreign_keys=ON")
    if migrate:
        migrate_db(conn)
    return conn


def schema_version(conn):
    try:
        row = conn.execute("SELECT value FROM meta WHERE key='schema_version'").fetchone()
        return int(row[0]) if row else 0
    except sqlite3.OperationalError:
        return 0


def migrate_db(conn):
    """Applies the migrations above the stored schema_version, each in one transaction."""
    have = schema_version(conn)
    d = os.path.join(HERE, "migrations")
    for name in sorted(os.listdir(d)):
        m = re.match(r"(\d+)_.*\.sql$", name)
        if not m or int(m.group(1)) <= have:
            continue
        with open(os.path.join(d, name), encoding="utf-8") as f:
            sql = f.read()
        version = int(m.group(1))
        conn.executescript("BEGIN;\nCREATE TABLE IF NOT EXISTS meta(key TEXT PRIMARY KEY, value TEXT);\n%s\n"
                           "INSERT OR REPLACE INTO meta VALUES('schema_version','%d');\nCOMMIT;" % (sql, version))
        have = version
    return have


def check_secrets(value):
    """`value` with phrase-shaped text cut out, and how many cuts. A field named like a secret refuses
    the whole event (Refused); phrase-shaped text in a note is cut, so the event (an attempt's end)
    still lands and no attempt stays "running" for a false match."""
    if isinstance(value, dict):
        out, cuts = {}, 0
        for k, v in value.items():
            if SECRET_KEY.search(str(k)):
                raise Refused("field %s" % k)
            out[k], c = check_secrets(v)
            cuts += c
        return out, cuts
    if isinstance(value, (list, tuple)):
        out, cuts = [], 0
        for v in value:
            x, c = check_secrets(v)
            out.append(x)
            cuts += c
        return out, cuts
    if isinstance(value, str) and PHRASE.search(value.lower() + " "):
        return PHRASE.sub("[phrase-shaped text removed] ", value.lower() + " ").strip(), 1
    return value, 0


def norm_ts(ts):
    if isinstance(ts, (int, float)):
        return time.strftime("%Y-%m-%dT%H:%M:%S", time.gmtime(ts)) + ".%06dZ" % int((ts % 1) * 1e6)
    ts = str(ts)
    if re.fullmatch(r"\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ", ts):
        return ts[:-1] + ".000000Z"
    return ts


def _need(body, *names):
    for n in names:
        if body.get(n) in (None, ""):
            raise Bad("missing field %s" % n)


def _fill_and_set(conn, table, id_col, key, ts, sets, fill=None):
    """Sets columns only when ts is not older than the row's state_ts; fill columns only when still null."""
    for col, v in (fill or {}).items():
        if v is not None:
            conn.execute("UPDATE %s SET %s=COALESCE(%s,?) WHERE %s=?" % (table, col, col, id_col), (v, key))
    sets = {c: v for c, v in sets.items() if v is not None}
    cols = "".join("%s=?, " % c for c in sets)
    conn.execute("UPDATE %s SET %sstate_ts=? WHERE %s=? AND (state_ts IS NULL OR state_ts<=?)" % (table, cols, id_col),
                 (*sets.values(), ts, key, ts))


def _ids(body):
    _need(body, "run", "lane")
    run, lane = str(body["run"]), str(body["lane"])
    return run, "%s/%s" % (run, lane), lane


def _ensure_run(conn, run, host):
    conn.execute("INSERT OR IGNORE INTO runs(run_id, host) VALUES(?,?)", (run, host))


def _ensure_lane(conn, body, host):
    run, lid, lane = _ids(body)
    _ensure_run(conn, run, host)
    conn.execute("INSERT OR IGNORE INTO lanes(id, run_id, name) VALUES(?,?,?)", (lid, run, lane))
    fill = {"platform": body.get("platform"), "variant": body.get("variant")}
    for col, v in fill.items():
        if v is not None:
            conn.execute("UPDATE lanes SET %s=COALESCE(%s,?) WHERE id=?" % (col, col), (v, lid))
    return lid


def _ensure_attempt(conn, body, host):
    lid = _ensure_lane(conn, body, host)
    _need(body, "n")
    n = int(body["n"])
    aid = "%s#%d" % (lid, n)
    conn.execute("INSERT OR IGNORE INTO attempts(id, lane_id, n) VALUES(?,?,?)", (aid, lid, n))
    conn.execute("UPDATE lanes SET attempts=MAX(attempts, ?) WHERE id=?", (n, lid))
    return lid, aid


def _json(v):
    return v if v is None or isinstance(v, str) else json.dumps(v, sort_keys=True)


def apply_event(conn, ev):
    """Applies one validated event inside the caller's transaction."""
    kind, ts, host, body = ev["kind"], ev["ts"], ev["host"], ev["body"]
    if kind == "run.start":
        _need(body, "run")
        _ensure_run(conn, str(body["run"]), host)
        _fill_and_set(conn, "runs", "run_id", str(body["run"]), ts,
                      {"state": "running", "kind": body.get("run_kind"), "version": body.get("version"), "host": host,
                       "note": body.get("note"), "ended": None}, {"started": ts})
    elif kind == "run.end":
        _need(body, "run")
        _ensure_run(conn, str(body["run"]), host)
        _fill_and_set(conn, "runs", "run_id", str(body["run"]), ts,
                      {"state": body.get("state") or "ended", "ended": ts, "note": body.get("note")})
    elif kind in ("lane.start", "lane.end"):
        lid = _ensure_lane(conn, body, host)
        if kind == "lane.start":
            _fill_and_set(conn, "lanes", "id", lid, ts, {"state": "running"}, {"started": ts})
        else:
            _fill_and_set(conn, "lanes", "id", lid, ts,
                          {"state": body.get("state") or "ended", "ended": ts, "cause_class": body.get("cause_class"),
                           "cause": body.get("cause")}, {"started": body.get("started")})
    elif kind == "attempt.start":
        lid, aid = _ensure_attempt(conn, body, host)
        _fill_and_set(conn, "attempts", "id", aid, ts, {"state": "running", "ended": None}, {"started": ts})
        _fill_and_set(conn, "lanes", "id", lid, ts, {"state": "running"}, {"started": ts})
    elif kind == "attempt.end":
        lid, aid = _ensure_attempt(conn, body, host)
        state = body.get("state") or "ended"
        _fill_and_set(conn, "attempts", "id", aid, ts,
                      {"state": state, "ended": ts, "rc": body.get("rc"), "cause_class": body.get("cause_class"),
                       "cause": body.get("cause"), "note": body.get("note"), "log_path": body.get("log_path"),
                       "out_dir": body.get("out_dir")}, {"started": body.get("started")})
        _fill_and_set(conn, "lanes", "id", lid, ts,
                      {"state": state, "ended": ts, "cause_class": body.get("cause_class"), "cause": body.get("cause")})
    elif kind == "attempt.heartbeat":
        _, aid = _ensure_attempt(conn, body, host)
        conn.execute("UPDATE attempts SET heartbeat=? WHERE id=? AND (heartbeat IS NULL OR heartbeat<?)", (ts, aid, ts))
    elif kind in ("step.start", "step.end"):
        _need(body, "step")
        _, aid = _ensure_attempt(conn, body, host)
        sid = "%s/%s" % (aid, body["step"])
        conn.execute("INSERT OR IGNORE INTO steps(id, attempt_id, name) VALUES(?,?,?)", (sid, aid, body["step"]))
        if kind == "step.start":
            _fill_and_set(conn, "steps", "id", sid, ts, {"state": "running", "detail": _json(body.get("detail"))},
                          {"started": ts})
        else:
            state = body.get("state") or "ok"
            if state not in ("ok", "skipped", "failed", "recovered"):
                raise Bad("bad step state %s" % state)
            _fill_and_set(conn, "steps", "id", sid, ts,
                          {"state": state, "ended": ts, "skipped": 1 if state == "skipped" else 0,
                           "detail": _json(body.get("detail"))})
    elif kind == "failure":
        _, aid = _ensure_attempt(conn, body, host)
        step = body.get("step")
        row = conn.execute("SELECT id FROM bundles WHERE attempt_id=? AND step IS ? ORDER BY id DESC LIMIT 1",
                           (aid, step)).fetchone()
        conn.execute("INSERT INTO failures(eid, attempt_id, step, cause_class, cause, what, bundle_id, resolved_by, ts) "
                     "VALUES(?,?,?,?,?,?,?,?,?)",
                     (ev["eid"], aid, step, body.get("cause_class"), body.get("cause"), body.get("what"),
                      row[0] if row else None, body.get("resolved_by"), ts))
    elif kind == "bundle":
        _, aid = _ensure_attempt(conn, body, host)
        step = body.get("step")
        cur = conn.execute("INSERT INTO bundles(eid, attempt_id, step, dir, screen_path, log_tail_path, shot_path) "
                           "VALUES(?,?,?,?,?,?,?)",
                           (ev["eid"], aid, step, body.get("dir"), body.get("screen_path"), body.get("log_tail_path"),
                            body.get("shot_path")))
        conn.execute("UPDATE failures SET bundle_id=? WHERE attempt_id=? AND step IS ? AND bundle_id IS NULL",
                     (cur.lastrowid, aid, step))
    elif kind == "playbook.propose":
        _need(body, "key")
        conn.execute("INSERT OR IGNORE INTO playbook(key, situation, fix, source_failure, state, version_added, created) "
                     "VALUES(?,?,?,?,'open',?,?)",
                     (body["key"], body.get("situation"), body.get("fix"), body.get("source_failure"),
                      body.get("version_added"), ts))
        conn.execute("UPDATE playbook SET updated=? WHERE key=? AND (updated IS NULL OR updated<?)", (ts, body["key"], ts))
    elif kind == "playbook.set_state":
        _need(body, "key", "state")
        if body["state"] not in PLAYBOOK_STATES:
            raise Bad("bad playbook state %s" % body["state"])
        conn.execute("INSERT OR IGNORE INTO playbook(key, state, created) VALUES(?, 'open', ?)", (body["key"], ts))
        _fill_and_set(conn, "playbook", "key", body["key"], ts, {"state": body["state"], "updated": ts})
    elif kind == "aipath.put":
        _need(body, "key")
        conn.execute("INSERT OR IGNORE INTO ai_paths(key, platform, goal, screen_sig, actions, state, created) "
                     "VALUES(?,?,?,?,?,'new',?)",
                     (body["key"], body.get("platform"), body.get("goal"), body.get("screen_sig"),
                      _json(body.get("actions")), ts))
    elif kind in ("aipath.hit", "aipath.fail"):
        _need(body, "key")
        conn.execute("INSERT OR IGNORE INTO ai_paths(key, state, created) VALUES(?, 'new', ?)", (body["key"], ts))
        col = "hits" if kind == "aipath.hit" else "fails"
        conn.execute("UPDATE ai_paths SET %s=%s+1, last_used=MAX(COALESCE(last_used,''), ?) WHERE key=?" % (col, col),
                     (ts, body["key"]))
        if kind == "aipath.hit":
            conn.execute("UPDATE ai_paths SET state='replayed', state_ts=? WHERE key=? AND state='new'", (ts, body["key"]))
        else:  # a replay that fails twice is not trusted again
            conn.execute("UPDATE ai_paths SET state='rejected', state_ts=? WHERE key=? AND fails>=2 "
                         "AND state IN ('new','replayed')", (ts, body["key"]))
    elif kind == "aipath.set_state":
        _need(body, "key", "state")
        if body["state"] not in PATH_STATES:
            raise Bad("bad path state %s" % body["state"])
        conn.execute("INSERT OR IGNORE INTO ai_paths(key, state, created) VALUES(?, 'new', ?)", (body["key"], ts))
        _fill_and_set(conn, "ai_paths", "key", body["key"], ts,
                      {"state": body["state"], "reviewed_by": body.get("reviewed_by")})
    else:
        raise Bad("unknown kind %s" % kind)


def validate(ev, size=0):
    if not isinstance(ev, dict):
        raise Bad("not an object")
    if ev.get("kind") not in client.KINDS:
        raise Bad("unknown kind %r" % (ev.get("kind"),))
    if size > client.MAX_EVENT:
        raise Bad("event too large")
    if not isinstance(ev.get("body", {}), dict):
        raise Bad("body is not an object")
    return {"eid": str(ev.get("eid") or ""), "ts": norm_ts(ev.get("ts") or client.now_ts()),
            "host": str(ev.get("host") or "?"), "source": str(ev.get("source") or "?"), "seq": ev.get("seq"),
            "kind": ev["kind"], "body": ev.get("body") or {}}


def ingest(conn, ev, size=0):
    """Validates and applies one event in one transaction; a repeated eid is a no-op. Returns True when
    applied, False for a repeat. Raises Refused (secret-shaped) or Bad."""
    ev = validate(ev, size)
    if not ev["eid"]:
        raise Bad("missing eid")
    ev["body"], cuts = check_secrets(ev["body"])
    if cuts:
        _count_refused(conn)
    conn.execute("BEGIN IMMEDIATE")
    try:
        cur = conn.execute("INSERT OR IGNORE INTO events(eid, ts, host, source, seq, kind, body, received) "
                           "VALUES(?,?,?,?,?,?,?,?)",
                           (ev["eid"], ev["ts"], ev["host"], ev["source"], ev["seq"], ev["kind"],
                            json.dumps(ev["body"], sort_keys=True), client.now_ts()))
        if cur.rowcount == 0:
            conn.execute("ROLLBACK")
            return False
        apply_event(conn, ev)
        conn.execute("COMMIT")
        return True
    except BaseException:
        conn.execute("ROLLBACK")
        raise


def _count_refused(conn):
    conn.execute("INSERT INTO meta VALUES('refused','1') ON CONFLICT(key) DO UPDATE SET value=CAST(value AS INTEGER)+1")


def _bad(inbox, name, reason):
    bad = os.path.join(inbox, "bad")
    os.makedirs(bad, exist_ok=True)
    src = os.path.join(inbox, name)
    with open(os.path.join(bad, name + ".reason"), "w", encoding="utf-8") as f:
        f.write(reason + "\n")
    try:
        shutil.move(src, os.path.join(bad, name))
    except OSError:
        pass


def pending(db):
    d = client.inbox_dir(db)
    try:
        return sum(1 for n in os.listdir(d) if n.endswith(".json") and not n.startswith("."))
    except OSError:
        return 0


def _drain_locked(db, budget):
    inbox = client.inbox_dir(db)
    try:
        names = sorted(n for n in os.listdir(inbox) if n.endswith(".json") and not n.startswith("."))
    except FileNotFoundError:
        return 0
    if not names:
        return 0
    deadline = time.monotonic() + budget if budget else None
    conn = connect(db)
    n = 0
    try:
        for name in names:
            if deadline and time.monotonic() > deadline:
                break
            path = os.path.join(inbox, name)
            try:
                size = os.path.getsize(path)
                if size > client.MAX_EVENT:
                    raise Bad("event too large")
                with open(path, encoding="utf-8") as f:
                    ev = json.load(f)
                ingest(conn, ev, size)
            except Refused:
                _count_refused(conn)  # counted, never stored: the file goes away
            except sqlite3.OperationalError:
                raise  # busy, locked, disk: the file stays and the next drain tries again
            except FileNotFoundError:
                continue
            except Exception as e:  # noqa: BLE001 - one unusable event must never stall the queue behind it
                _bad(inbox, name, "%s: %s" % (type(e).__name__, e))
            try:
                os.remove(path)
            except FileNotFoundError:
                pass
            n += 1
    finally:
        conn.close()
    return n


def drain(db, budget=None, wait=False):
    """Applies the inbox while holding the writer lock. Returns the number of files handled, or None when
    another process holds the lock (it drains them). budget: stop after about this many seconds."""
    os.makedirs(os.path.dirname(db), exist_ok=True)
    fd = os.open(client.lock_path(db), os.O_CREAT | os.O_RDWR, 0o644)
    try:
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | (0 if wait else fcntl.LOCK_NB))
        except BlockingIOError:
            return None
        return _drain_locked(db, budget)
    finally:
        os.close(fd)  # releases the lock


def run_loop(db, interval=1.0, stop=lambda: False):
    """The `testdb writer` service: drain, wait, repeat."""
    while not stop():
        try:
            drain(db)
        except Exception as e:  # noqa: BLE001 - a bad moment (disk full, a locked DB): try again
            print("testdb writer: %s: %s" % (type(e).__name__, e), flush=True)
        time.sleep(interval)
