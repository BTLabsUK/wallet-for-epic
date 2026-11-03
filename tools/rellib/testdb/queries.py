# SPDX-License-Identifier: Apache-2.0
"""Read-only queries, shared by the CLI and `testdb serve` (GET /q/<name>)."""
from . import client, writer


def _rows(conn, sql, args=()):
    return [dict(r) for r in conn.execute(sql, args)]


def last(conn, **_):
    return _rows(conn, "SELECT * FROM last_per_lane ORDER BY lane")


def failures(conn, cause=None, run=None, **_):
    sql = ("SELECT f.ts, l.run_id AS run_id, l.name AS lane, a.n AS n, f.step, f.cause_class, f.cause, f.what, "
           "f.bundle_id, f.resolved_by FROM failures f JOIN attempts a ON a.id=f.attempt_id "
           "JOIN lanes l ON l.id=a.lane_id WHERE 1=1")
    args = []
    if cause:
        sql += " AND (f.cause_class=? OR f.cause=?)"
        args += [cause, cause]
    if run:
        sql += " AND l.run_id=?"
        args.append(run)
    return _rows(conn, sql + " ORDER BY f.ts DESC, f.id DESC", args)


def live(conn, db=None, **_):
    out = {"running": _rows(conn, "SELECT * FROM live ORDER BY started"),
           "pending": writer.pending(db) if db else None}
    row = conn.execute("SELECT value FROM meta WHERE key='refused'").fetchone()
    out["refused"] = int(row[0]) if row else 0
    return out


def playbook(conn, state=None, **_):
    sql, args = "SELECT * FROM playbook", []
    if state:
        sql, args = sql + " WHERE state=?", [state]
    return _rows(conn, sql + " ORDER BY id", args)


def paths(conn, state=None, **_):
    sql, args = "SELECT id, key, platform, goal, state, hits, fails, last_used, reviewed_by, screen_sig FROM ai_paths", []
    if state:
        sql, args = sql + " WHERE state=?", [state]
    return _rows(conn, sql + " ORDER BY id", args)


QUERIES = {"last": last, "failures": failures, "live": live, "playbook": playbook, "paths": paths}
