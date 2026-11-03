# SPDX-License-Identifier: Apache-2.0
"""The test DB: parallel emitters, ordering rules, the secret guard, the HTTP intake, the views, the import."""
import json
import os
import subprocess
import sys
import tempfile
import threading
import unittest
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
RELLIB = os.path.dirname(HERE)
sys.path.insert(0, RELLIB)

from testdb import client, importer, queries, server, writer  # noqa: E402

EMITTER = """
import sys
sys.path.insert(0, sys.argv[1])
from testdb import client
p = sys.argv[2]
for i in range(200):
    client.emit("attempt.heartbeat", source="t" + p, run="r", lane="lane" + p, n=i + 1)
"""


class TdbCase(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix="testdb-", dir=os.environ.get("TMPDIR") or None)
        self.db = os.path.join(self.tmp, "tests.db")
        self.saved = {k: os.environ.get(k) for k in ("REL_TESTDB", "TESTDB_URL", "TESTDB_TOKEN", "REL_RUN_ID", "REL_STAGE")}
        os.environ["REL_TESTDB"] = self.db
        for k in ("TESTDB_URL", "TESTDB_TOKEN", "REL_RUN_ID", "REL_STAGE"):
            os.environ.pop(k, None)

    def tearDown(self):
        for k, v in self.saved.items():
            if v is None:
                os.environ.pop(k, None)
            else:
                os.environ[k] = v
        import shutil
        shutil.rmtree(self.tmp, ignore_errors=True)

    def drain(self):
        writer.drain(self.db, wait=True)

    def q(self, sql, *a):
        conn = client.read(self.db)
        try:
            return [dict(r) for r in conn.execute(sql, a)]
        finally:
            conn.close()


class QueueTest(TdbCase):
    def test_parallel_emitters_lose_and_double_nothing(self):
        procs = [subprocess.Popen([sys.executable, "-c", EMITTER, RELLIB, str(i)], env=dict(os.environ)) for i in range(8)]
        for p in procs:
            self.assertEqual(p.wait(timeout=300), 0)
        self.drain()
        self.assertEqual(self.q("SELECT COUNT(*) c FROM events")[0]["c"], 1600)
        self.assertEqual(self.q("SELECT COUNT(DISTINCT eid) c FROM events")[0]["c"], 1600)
        self.assertEqual(self.q("SELECT COUNT(*) c FROM attempts")[0]["c"], 1600)
        self.assertEqual(writer.pending(self.db), 0)

    def test_older_event_does_not_overwrite_newer_state(self):
        base = dict(run="r1", lane="L", n=1)
        client.emit("attempt.end", ts="2026-01-01T00:00:10.000000Z", state="failed", rc=1, cause="product",
                    cause_class="PRODUCT", **base)
        client.emit("attempt.end", ts="2026-01-01T00:00:05.000000Z", state="ok", rc=0, **base)
        client.emit("attempt.start", ts="2026-01-01T00:00:01.000000Z", **base)
        client.emit("attempt.start", ts="2026-01-01T00:00:02.000000Z", **base)
        self.drain()
        a = self.q("SELECT * FROM attempts")[0]
        self.assertEqual((a["state"], a["rc"], a["cause_class"]), ("failed", 1, "PRODUCT"))
        self.assertTrue(a["started"].startswith("2026-01-01T00:00:01"))  # the earliest start is kept
        self.assertEqual(self.q("SELECT state FROM lanes")[0]["state"], "failed")

    def test_same_event_twice_is_one_event(self):
        client.emit("run.start", eid="fixed-1", run="r")
        client.emit("run.start", eid="fixed-1", run="r")
        self.drain()
        self.assertEqual(self.q("SELECT COUNT(*) c FROM events")[0]["c"], 1)

    def test_bad_file_goes_to_bad_with_reason(self):
        inbox = client.inbox_dir(self.db)
        os.makedirs(inbox)
        with open(os.path.join(inbox, "0001-x.json"), "w") as f:
            f.write("{not json")
        client.emit("attempt.end", run="r", lane="L")  # no n: cannot be applied
        self.drain()
        bad = os.listdir(os.path.join(inbox, "bad"))
        self.assertEqual(len([b for b in bad if b.endswith(".reason")]), 2)
        self.assertEqual(writer.pending(self.db), 0)

    def test_off_and_unittest_default_write_nothing(self):
        os.environ["REL_TESTDB"] = "off"
        self.assertIsNone(client.emit("run.start", run="r"))
        del os.environ["REL_TESTDB"]
        self.assertIsNone(client.emit("run.start", run="r"))  # under unittest, no path given: a no-op
        self.assertFalse(os.path.exists(self.db))

    def test_unbindable_event_does_not_stall_the_queue(self):
        client.emit("failure", run="r", lane="L", n=1, what=["a list is not text"])
        client.emit("attempt.end", run="r", lane="L", n=1, rc=2 ** 70)
        client.emit("run.start", run="good")
        self.drain()
        self.assertEqual(writer.pending(self.db), 0)
        self.assertEqual(len(os.listdir(os.path.join(client.inbox_dir(self.db), "bad"))), 4)
        self.assertEqual(self.q("SELECT run_id FROM runs WHERE state='running'")[0]["run_id"], "good")

    def test_context_from_the_tools_rel_env(self):
        stage = os.path.join(self.tmp, "run", "steps", "trust-x", "out")
        os.makedirs(stage)
        for n in (1, 2):
            open(os.path.join(os.path.dirname(stage), "attempt-%d.log" % n), "w").close()
        os.environ.update(REL_RUN_ID="rid", REL_STAGE=stage)
        client.emit("step.start", step="open")
        self.drain()
        self.assertEqual(self.q("SELECT id FROM steps")[0]["id"], "rid/trust-x#2/open")

    def test_emit_never_raises(self):
        os.environ["REL_TESTDB"] = "/proc/nope/tests.db"
        self.assertIsNone(client.emit("run.start", run="r"))


class SecretTest(TdbCase):
    def test_refused_events_are_counted_not_stored(self):
        phrase = " ".join("word" for _ in range(12))
        client.emit("step.end", run="r", lane="L", n=1, step="ok11", detail=" ".join("word" for _ in range(11)))
        client.emit("step.end", run="r", lane="L", n=1, step="s", detail={"password": "x"})
        client.emit("step.end", run="r", lane="L", n=1, step="s", detail="typed " + phrase)
        client.emit("step.end", run="r", lane="L", n=1, step="s", seed="abc")
        client.emit("step.end", run="r", lane="L", n=1, step="s", detail="short words only here")
        self.drain()
        self.assertEqual(self.q("SELECT COUNT(*) c FROM events")[0]["c"], 2)  # the 11-word text and the short one
        self.assertEqual(self.q("SELECT value FROM meta WHERE key='refused'")[0]["value"], "3")
        self.assertNotIn(" ".join(["word"] * 12), json.dumps(self.q("SELECT body FROM events")))
        self.assertEqual(writer.pending(self.db), 0)
        self.assertFalse(os.path.exists(os.path.join(client.inbox_dir(self.db), "bad")))


class ServerTest(TdbCase):
    def serve(self):
        srv = server.make_server(self.db, "127.0.0.1:0")
        threading.Thread(target=srv.serve_forever, daemon=True).start()
        self.addCleanup(srv.server_close)
        self.addCleanup(srv.shutdown)
        return "http://127.0.0.1:%d" % srv.server_address[1]

    def req(self, url, data=None, headers=None):
        r = urllib.request.Request(url, data=json.dumps(data).encode() if data is not None else None, headers=headers or {})
        try:
            with urllib.request.urlopen(r, timeout=5) as resp:
                return resp.status, json.loads(resp.read())
        except urllib.error.HTTPError as e:
            return e.code, json.loads(e.read())

    def test_non_loopback_bind_needs_a_token(self):
        with self.assertRaises(SystemExit):
            server.make_server(self.db, "0.0.0.0:0")

    def test_post_then_drain_then_query(self):
        url = self.serve()
        evs = [client.make_event("run.start", "remote", {"run": "r9", "version": "1"}),
               client.make_event("attempt.end", "remote", {"run": "r9", "lane": "trust", "n": 1, "state": "failed",
                                                            "cause_class": "INFRA", "cause": "infra:ssh"})]
        code, out = self.req(url + "/events", evs)
        self.assertEqual((code, out["accepted"]), (202, 2))
        code, out = self.req(url + "/events", {"kind": "nope", "eid": "x"})
        self.assertEqual(code, 400)
        code, out = self.req(url + "/events", {"kind": "run.start", "eid": "y", "pad": "x" * (client.MAX_EVENT + 10)})
        self.assertEqual(code, 400)
        self.drain()
        code, rows = self.req(url + "/q/last")
        self.assertEqual((code, rows[0]["cause_class"]), (200, "INFRA"))
        code, rows = self.req(url + "/q/failures?cause=INFRA")
        self.assertEqual(code, 200)
        self.assertEqual(self.req(url + "/q/nothing")[0], 404)

    def test_token_when_set(self):
        os.environ["TESTDB_TOKEN"] = "s3cret"
        url = self.serve()
        self.assertEqual(self.req(url + "/events", {"kind": "run.start"})[0], 401)
        ev = client.make_event("run.start", "remote", {"run": "r"})
        code, _ = self.req(url + "/events", ev, {"Authorization": "Bearer s3cret"})
        self.assertEqual(code, 202)

    def test_remote_emit_posts_and_spools_when_down(self):
        url = self.serve()
        os.environ["TESTDB_URL"] = url
        client.emit("run.start", run="viaurl")
        self.assertEqual(writer.pending(self.db), 1)
        os.environ["TESTDB_URL"] = "http://127.0.0.1:1"
        client.emit("run.start", run="offline")
        self.assertEqual(len(os.listdir(client.spool_dir(self.db))), 1)
        os.environ["TESTDB_URL"] = url
        self.assertEqual(client.push(), (1, 0))
        self.drain()
        self.assertEqual(sorted(r["run_id"] for r in self.q("SELECT run_id FROM runs")), ["offline", "viaurl"])


class ViewsTest(TdbCase):
    def test_views_and_queries(self):
        t = lambda s: "2026-02-01T00:00:%02d.000000Z" % s  # noqa: E731
        client.emit("run.start", ts=t(0), run="r1", version="9")
        client.emit("attempt.start", ts=t(1), run="r1", lane="trust-linux-tor", n=1)
        client.emit("attempt.end", ts=t(2), run="r1", lane="trust-linux-tor", n=1, state="failed", rc=1,
                    cause_class="PRODUCT", cause="product", note="boom")
        client.emit("failure", ts=t(2), run="r1", lane="trust-linux-tor", n=1, step="send", cause_class="PRODUCT",
                    cause="product", what="send failed")
        client.emit("bundle", ts=t(3), run="r1", lane="trust-linux-tor", n=1, step="send", dir="/b/1")
        client.emit("attempt.start", ts=t(4), run="r1", lane="trust-linux-tor", n=2)
        client.emit("step.start", ts=t(5), run="r1", lane="trust-linux-tor", n=2, step="open")
        client.emit("attempt.heartbeat", ts=t(6), run="r1", lane="trust-linux-tor", n=2)
        client.emit("attempt.start", ts=t(2), run="r1", lane="build-linux", n=1)
        client.emit("attempt.end", ts=t(3), run="r1", lane="build-linux", n=1, state="ok", rc=0)
        client.emit("playbook.propose", ts=t(1), key="k1", situation="s", fix="f")
        client.emit("aipath.put", ts=t(1), key="p1", platform="linux", goal="g", actions=[{"click": 3}])
        client.emit("aipath.hit", ts=t(2), key="p1")
        client.emit("aipath.fail", ts=t(3), key="p1")
        client.emit("aipath.fail", ts=t(4), key="p1")
        self.drain()
        conn = client.read(self.db)
        try:
            last = {r["lane"]: r for r in queries.last(conn)}
            self.assertEqual(last["trust-linux-tor"]["n"], 2)
            self.assertEqual(last["trust-linux-tor"]["state"], "running")
            self.assertEqual(last["build-linux"]["state"], "ok")
            live = queries.live(conn, db=self.db)
            self.assertEqual({(r["what"], r["step"]) for r in live["running"]}, {("attempt", None), ("step", "open")})
            self.assertTrue(all(r["age_s"] > 0 for r in live["running"]))
            self.assertEqual(live["pending"], 0)
            f = queries.failures(conn, cause="PRODUCT")
            self.assertEqual((len(f), f[0]["bundle_id"] is not None), (1, True))
            self.assertEqual(queries.failures(conn, cause="INFRA"), [])
            self.assertEqual(queries.failures(conn, run="r1")[0]["lane"], "trust-linux-tor")
            self.assertEqual([r["n"] for r in conn.execute("SELECT n FROM failures_by_cause")], [1])
            self.assertEqual(len(queries.playbook(conn, state="open")), 1)
            p = queries.paths(conn)[0]
            self.assertEqual((p["hits"], p["fails"], p["state"]), (1, 2, "rejected"))
        finally:
            conn.close()
        self.assertIsNone(client.path_lookup("p1"))  # rejected: not offered for replay
        client.emit("aipath.put", key="p2", platform="linux", goal="g", actions=[1, 2])
        self.drain()
        self.assertEqual(client.path_lookup("p2")["actions"], [1, 2])


class ImportTest(TdbCase):
    def make_run(self):
        run = os.path.join(self.tmp, "run-1")
        for step, st in (("trust-linux-tor", {"status": "done", "attempts": 2, "rc": 0, "attempt_causes": ["harness"],
                                              "started": "2026-03-01T10:00:00Z", "ended": "2026-03-01T10:20:00Z"}),
                         ("build-linux-tor", {"status": "done", "attempts": 1, "rc": 0}),
                         ("store-play", {"status": "skipped", "attempts": 0, "reason": "release.toml [skip]"})):
            os.makedirs(os.path.join(run, "steps", step, "out"))
            with open(os.path.join(run, "steps", step, "status.json"), "w") as f:
                json.dump(st, f)
        with open(os.path.join(run, "steps", "trust-linux-tor", "out", "proof.json"), "w") as f:
            json.dump({"fault": {"kind": "harness", "step": "open", "what": "HARNESS open: not found"}}, f)
        with open(os.path.join(run, "run.json"), "w") as f:
            json.dump({"run_id": "9.9.9-run1", "version": "9.9.9", "kind": "release", "created": "2026-03-01T09:00:00Z"}, f)
        evs = [{"ts": "2026-03-01T10:00:00Z", "t": 1772359200.0, "step": "trust-linux-tor", "event": "start", "attempt": 1},
               {"ts": "2026-03-01T10:05:00Z", "t": 1772359500.0, "step": "trust-linux-tor", "event": "end",
                "status": "failed", "rc": 2, "cause": "harness", "note": "HARNESS open: not found"},
               {"ts": "2026-03-01T10:06:00Z", "t": 1772359560.0, "step": "trust-linux-tor", "event": "start", "attempt": 2},
               {"ts": "2026-03-01T10:20:00Z", "t": 1772360400.0, "step": "trust-linux-tor", "event": "end",
                "status": "done", "rc": 0}]
        with open(os.path.join(run, "events.jsonl"), "w") as f:
            f.write("\n".join(json.dumps(e) for e in evs) + "\n")
        return run

    def test_import_synthetic_run_twice(self):
        run = self.make_run()
        n = importer.import_run(run, self.db)
        importer.import_run(run, self.db)
        self.assertEqual(self.q("SELECT COUNT(*) c FROM events")[0]["c"], n)
        att = self.q("SELECT n, state, rc, cause_class FROM attempts WHERE id LIKE '%trust-linux-tor#%' ORDER BY n")
        self.assertEqual([(a["n"], a["state"], a["rc"], a["cause_class"]) for a in att],
                         [(1, "failed", 2, "HARNESS-ui"), (2, "ok", 0, None)])
        f = self.q("SELECT what, cause_class FROM failures")
        self.assertEqual(len(f), 1)
        self.assertEqual(f[0]["cause_class"], "HARNESS-ui")
        self.assertEqual(self.q("SELECT state FROM lanes WHERE name='store-play'")[0]["state"], "skipped")
        self.assertEqual(self.q("SELECT platform, variant FROM lanes WHERE name='trust-linux-tor'")[0],
                         {"platform": "linux", "variant": "tor"})

    def test_cli_last_and_failures(self):
        importer.import_run(self.make_run(), self.db)
        tool = os.path.join(os.path.dirname(RELLIB), "testdb")
        out = subprocess.run([tool, "last"], capture_output=True, text=True, env=dict(os.environ), timeout=60).stdout
        self.assertIn("trust-linux-tor", out)
        out = subprocess.run([tool, "failures", "--json"], capture_output=True, text=True, env=dict(os.environ), timeout=60).stdout
        self.assertEqual(json.loads(out)[0]["cause_class"], "HARNESS-ui")
        subprocess.run([tool, "paths"], capture_output=True, text=True, env=dict(os.environ), timeout=60, check=True)


if __name__ == "__main__":
    unittest.main()
