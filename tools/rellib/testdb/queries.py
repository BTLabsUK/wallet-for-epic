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


def bugs(conn, cause=None, run=None, **_):
    sql = ("SELECT b.ts, l.run_id AS run_id, l.name AS lane, a.n AS n, b.step, b.class, b.cause, b.note, b.warned, "
           "b.commit_sha, b.version, b.log_path FROM bugs b JOIN attempts a ON a.id=b.attempt_id "
           "JOIN lanes l ON l.id=a.lane_id WHERE 1=1")
    args = []
    if cause:
        sql += " AND (b.class=? OR b.cause=?)"
        args += [cause, cause]
    if run:
        sql += " AND l.run_id=?"
        args.append(run)
    return _rows(conn, sql + " ORDER BY b.ts DESC, b.id DESC", args)


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


def wallets(conn, role=None, **_):
    """Every test wallet with its first address and last balance. Never the phrase or the password."""
    sql = ("SELECT w.name, w.role, w.platform, w.lane, w.state, "
           "(SELECT address FROM wallet_addresses a WHERE a.wallet_id=w.id ORDER BY (kind='epicbox') DESC, first_seen LIMIT 1) AS address, "
           "(SELECT spendable FROM wallet_snapshots s WHERE s.wallet_id=w.id ORDER BY ts DESC, id DESC LIMIT 1) AS spendable, "
           "(SELECT total FROM wallet_snapshots s WHERE s.wallet_id=w.id ORDER BY ts DESC, id DESC LIMIT 1) AS total, "
           "(SELECT ts FROM wallet_snapshots s WHERE s.wallet_id=w.id ORDER BY ts DESC, id DESC LIMIT 1) AS balance_at "
           "FROM wallets w")
    args = []
    if role:
        sql, args = sql + " WHERE w.role=?", [role]
    return _rows(conn, sql + " ORDER BY w.role, w.name", args)


def wallet(conn, name=None, secrets=False, snapshots=10, **_):
    """One wallet, its addresses and recent snapshots. phrase and password only with secrets=True, which
    only the local CLI passes (the server never does)."""
    row = conn.execute("SELECT * FROM wallets WHERE name=?", (name,)).fetchone()
    if row is None:
        return {}
    out = dict(row)
    out.pop("state_ts", None)
    for k in ("phrase", "password"):
        if not secrets:
            out[k] = "(set)" if out.get(k) else None
    out["addresses"] = _rows(conn, "SELECT kind, address, first_seen, last_seen FROM wallet_addresses "
                                   "WHERE wallet_id=? ORDER BY first_seen", (row["id"],))
    out["snapshots"] = _rows(conn, "SELECT ts, run, lane, n, spendable, total, unconfirmed, locked, source "
                                   "FROM wallet_snapshots WHERE wallet_id=? ORDER BY ts DESC, id DESC LIMIT ?",
                             (row["id"], int(snapshots)))
    return out


QUERIES = {"last": last, "failures": failures, "bugs": bugs, "live": live, "playbook": playbook, "paths": paths,
           "wallets": wallets, "wallet": wallet}
