# SPDX-License-Identifier: Apache-2.0
"""tools/testdb: queries, review commands and the writer, server, drain, push, migrate and import."""
import argparse
import json
import os
import sys

from . import client, importer, queries, server, writer


def table(rows, cols=None):
    if not rows:
        return "(none)"
    cols = cols or list(rows[0])
    cells = [[("" if r.get(c) is None else str(r.get(c)).replace("\n", " ")[:70]) for c in cols] for r in rows]
    w = [max(len(c), *(len(r[i]) for r in cells)) for i, c in enumerate(cols)]
    lines = ["  ".join(c.ljust(w[i]) for i, c in enumerate(cols)).rstrip()]
    lines += ["  ".join(v.ljust(w[i]) for i, v in enumerate(r)).rstrip() for r in cells]
    return "\n".join(lines)


COLS = {
    "last": ["lane", "run_id", "n", "state", "rc", "cause_class", "cause", "ended"],
    "failures": ["ts", "run_id", "lane", "n", "step", "cause_class", "cause", "what"],
    "playbook": ["id", "key", "state", "situation", "fix", "version_added"],
    "paths": ["id", "key", "platform", "goal", "state", "hits", "fails", "reviewed_by"],
}


def show(name, data, as_json, db):
    if as_json:
        print(json.dumps(data, indent=1, default=str))
    elif name == "live":
        print(table(data["running"], ["what", "run_id", "lane", "n", "step", "started", "age_s"]))
        print("inbox pending: %s   refused events: %s" % (data["pending"], data["refused"]))
    else:
        print(table(data, COLS[name]))


def query(name, args, db):
    try:
        conn = client.read(db)
    except FileNotFoundError:
        conn = None
    if conn is None:
        data = {"running": [], "pending": writer.pending(db), "refused": 0} if name == "live" else []
    else:
        try:
            data = queries.QUERIES[name](conn, db=db, **args)
        finally:
            conn.close()
    show(name, data, args.pop("json", False), db)


def resolve(db, table_name, ident):
    conn = client.read(db)
    try:
        row = conn.execute("SELECT key FROM %s WHERE id=? OR key=?" % table_name, (ident, ident)).fetchone()
    finally:
        conn.close()
    if row is None:
        sys.exit("testdb: no %s entry %s" % (table_name, ident))
    return row[0]


def main(argv=None):
    ap = argparse.ArgumentParser(prog="testdb", description="The BT Wallet test database (REL_TESTDB, TESTDB_URL).")
    ap.add_argument("--db", help="DB path (default REL_TESTDB or /tmp/epic-build/rel/tests.db)")
    sub = ap.add_subparsers(dest="cmd", required=True)

    def q(name, help_):
        p = sub.add_parser(name, help=help_)
        p.add_argument("--json", action="store_true")
        return p

    q("last", "the last attempt of each lane")
    p = q("failures", "failures, newest first")
    p.add_argument("--cause")
    p.add_argument("--run")
    q("live", "running attempts and steps, heartbeat age, inbox pending")
    p = q("playbook", "playbook entries")
    p.add_argument("--state")
    p.add_argument("--open", action="store_true", help="same as --state open")
    p = q("paths", "AI paths")
    p.add_argument("--state")
    pp = sub.add_parser("path", help="path review|promote|reject <id>")
    pp.add_argument("action", choices=["review", "promote", "reject"])
    pp.add_argument("id")
    pb = sub.add_parser("pb", help="pb accept|reject <id>")
    pb.add_argument("action", choices=["accept", "reject"])
    pb.add_argument("id")
    sub.add_parser("writer", help="the writer service: drain the inbox every second")
    p = sub.add_parser("serve", help="HTTP intake and read-only queries")
    p.add_argument("--bind", default=os.environ.get("TESTDB_BIND", "127.0.0.1:8765"))
    sub.add_parser("drain", help="apply the inbox once")
    sub.add_parser("push", help="resend the spool to TESTDB_URL")
    sub.add_parser("migrate", help="apply pending migrations")
    p = sub.add_parser("import", help="backfill from a tools/rel run folder")
    p.add_argument("run_dir")
    # `paths review|promote|reject <id>` and `playbook accept|reject <id>` are the same words as the
    # queries, so they are told apart by their first argument.
    argv = list(sys.argv[1:] if argv is None else argv)
    for i, a in enumerate(argv):
        if a in ("paths", "playbook") and i + 1 < len(argv):
            nxt = argv[i + 1]
            if a == "paths" and nxt in ("review", "promote", "reject"):
                argv[i:i + 1] = ["path"]
            elif a == "playbook" and nxt in ("accept", "reject"):
                argv[i:i + 1] = ["pb"]
            break
        if not a.startswith("-") and a not in ("paths", "playbook"):
            break
    ns = ap.parse_args(argv)
    db = client.db_path(ns.db)
    if ns.cmd in ("last", "failures", "live", "playbook", "paths"):
        args = {k: v for k, v in vars(ns).items() if k not in ("db", "cmd", "open") and v is not None}
        if getattr(ns, "open", False):
            args["state"] = "open"
        query(ns.cmd, args, db)
    elif ns.cmd == "path":
        key = resolve(db, "ai_paths", ns.id)
        state = {"review": "reviewed", "promote": "promoted", "reject": "rejected"}[ns.action]
        client.emit("aipath.set_state", source="cli", db=db, key=key, state=state, reviewed_by=os.environ.get("USER", "cli"))
        print("path %s -> %s" % (key, state))
    elif ns.cmd == "pb":
        key = resolve(db, "playbook", ns.id)
        state = "accepted" if ns.action == "accept" else "rejected"
        client.emit("playbook.set_state", source="cli", db=db, key=key, state=state)
        print("playbook %s -> %s" % (key, state))
    elif ns.cmd == "writer":
        writer.run_loop(db)
    elif ns.cmd == "serve":
        server.serve(db, ns.bind)
    elif ns.cmd == "drain":
        n = writer.drain(db, wait=True)
        print("drained %s event file(s); %d left" % (n, writer.pending(db)))
    elif ns.cmd == "push":
        sent, left = client.push(db)
        print("pushed %d, %d left (TESTDB_URL=%s)" % (sent, left, os.environ.get("TESTDB_URL", "unset")))
    elif ns.cmd == "migrate":
        conn = writer.connect(db)
        print("schema_version %d" % writer.schema_version(conn))
        conn.close()
    elif ns.cmd == "import":
        n = importer.import_run(ns.run_dir, db)
        print("imported %d events from %s" % (n, ns.run_dir))
    return 0
