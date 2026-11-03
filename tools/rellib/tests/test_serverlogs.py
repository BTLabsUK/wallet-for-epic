# SPDX-License-Identifier: Apache-2.0
"""Server-side log lines for a failed G4 lane (tools/rellib/serverlogs.py): window, parsing, the
lane's relay connections, node selection, redaction, the remote node filter and the gate lines."""
import gzip
import json
import os
import subprocess
import sys
import tempfile
import time
import types
import unittest
from datetime import datetime, timezone

from support import Base
from rellib import builtins, serverlogs as sl
from rellib.engine import Engine

LANE = "esAbCdEf" + "x" * 40 + "Qr12St"          # a made-up 54-character address
OTHER = "esZzZzZz" + "y" * 40 + "Uv34Wx"
T = datetime(2026, 11, 3, 10, 0, 0, tzinfo=timezone.utc).timestamp()


def iso(t):
    return datetime.fromtimestamp(t, timezone.utc).strftime("%Y-%m-%dT%H:%M:%S+00:00")


def node_line(t, level, text, utc=True, module="epic_chain::pipe"):
    d = datetime.fromtimestamp(t, timezone.utc) if utc else datetime.fromtimestamp(t)
    return d.strftime("%Y%m%d %H:%M:%S.000 ") + f"{level} {module} - {text}\n"


JOURNAL = [
    f"{iso(T + 10)} srv epic-floonet-epicbox[1]: [10:00:10 AM] [Ab1Cd] New connection from  81.2.3.4\n",
    f"{iso(T + 11)} srv epic-floonet-epicbox[1]: [10:00:11 AM] - [Ab1Cd][81.2.3.4] -> [Subscribe]\n",
    f"{iso(T + 11)} srv epic-floonet-epicbox[1]: subscribed {LANE}\n",
    f"{iso(T + 12)} srv epic-floonet-epicbox[1]: [10:00:12 AM] [Zz9Yy] New connection from  90.1.1.1\n",
    f"{iso(T + 13)} srv epic-floonet-epicbox[1]: [10:00:13 AM] - [Zz9Yy][90.1.1.1] -> [Error] error: boom\n",
    f"{iso(T + 14)} srv epic-floonet-epicbox[1]: [10:00:14 AM] - [Ab1Cd][81.2.3.4] -> [PostSlate]\n",
    f"{iso(T + 14)} srv epic-floonet-epicbox[1]: postslate from  {OTHER} to  {LANE}\n",
    f"{iso(T + 15)} srv epic-floonet-epicbox[1]: Error insert to db MongoError\n",
    f"{iso(T + 16)} srv epic-floonet-epicbox[1]: [10:00:16 AM] - [Ab1Cd][81.2.3.4] -> [Close connection] code: 1000, reason:\n",
    f"{iso(T + 9999)} srv epic-floonet-epicbox[1]: [late] - [Ab1Cd][81.2.3.4] -> [Subscribe]\n",
]


def relay_json(t, level, conn, msg):
    return json.dumps({"text": msg, "record": {"time": {"timestamp": t}, "level": {"name": level},
                                               "extra": {"conn": conn}, "message": msg}}) + "\n"


class Pieces(unittest.TestCase):
    def test_window_from_status_with_padding(self):
        t0, t1 = sl.window({"started": iso(T), "ended": iso(T + 600)}, 60)
        self.assertEqual((t0, t1), (T - 60, T + 660))

    def test_lane_step(self):
        step = lambda sid, proof=True: types.SimpleNamespace(id=sid, proof=proof)
        self.assertTrue(sl.is_lane_step(step("trust-linux-tor")))
        self.assertFalse(sl.is_lane_step(step("trust-manifest")))
        self.assertFalse(sl.is_lane_step(step("trust-linux-tor", proof=False)))
        self.assertFalse(sl.is_lane_step(step("build-linux")))

    def test_redaction(self):
        marks = [("esAbCdEf", "Qr12St")]
        r = sl.redact(f"from 81.2.3.4 and 127.0.0.1 and 203.0.113.10 to {LANE} by {OTHER}", marks,
                      {"203.0.113.10": "server"})
        self.assertEqual(r, "from <ip> and 127.0.0.1 and <server> to esAbCdEf…Qr12St by <other address>")
        self.assertEqual(sl.redact("subscribed as esAbCdEfxxxx… (0 waiting)", marks, {}),
                         "subscribed as esAbCdEf… (0 waiting)")
        self.assertIn("left out", sl.redact("abandon ability able about above absent absorb abstract absurd "
                                            "abuse access accident", marks, {}))
        self.assertTrue(sl.redact('{"slate": "' + "a" * 500 + '"}', marks, {}).endswith("…<cut>"))
        self.assertEqual(sl.redact("fe80::1:2:3 said", marks, {}), "<ip> said")
        self.assertEqual(sl.redact("2001:db8:0:0:1:2:3:4 at 10:00:12 in epic_pool::pool", marks, {}),
                         "<ip> at 10:00:12 in epic_pool::pool")

    def test_relay_picks_the_lanes_connection_and_server_errors(self):
        marks = [("esAbCdEf", "Qr12St")]
        entries = [(ts, None, c, x) for ts, c, x in sl.parse_journal(JOURNAL)]
        kept, other = sl.pick_relay(sl._within(entries, T, T + 100), marks)
        texts = [x for _, _, x in kept]
        self.assertEqual(len(kept), 7, texts)          # 5 of Ab1Cd, the postslate, the db error
        self.assertTrue(any("Error insert to db" in x for x in texts))
        self.assertFalse(any("Zz9Yy" in x for x in texts))
        self.assertEqual(other, 1)

    def test_relay_json_lines(self):
        lines = [relay_json(T + 1, "INFO", "c1", "subscribed as esAbCdEfxxxx… (0 slate(s) waiting)"),
                 relay_json(T + 2, "DEBUG", "c1", "→ Slate abc from esZzZzZzyyyy… (attempt 1)"),
                 relay_json(T + 3, "WARNING", "c2", "Subscribe rejected: signature does not match"),
                 relay_json(T + 4, "ERROR", "sweep", "sweep failed: x"), "not json\n"]
        kept, other = sl.pick_relay(sl.parse_relay_json(lines), [("esAbCdEf", "Qr12St")])
        self.assertEqual([x for _, _, x in kept][:2], ["subscribed as esAbCdEfxxxx… (0 slate(s) waiting)",
                                                       "→ Slate abc from esZzZzZzyyyy… (attempt 1)"])
        self.assertEqual(kept[-1][2], "sweep failed: x")
        self.assertEqual(other, 1)

    def test_node_keeps_warnings_and_pool_lines_never_trace(self):
        lines = [node_line(T, "TRACE", "transaction in pool"), node_line(T, "DEBUG", "header head updated"),
                 node_line(T, "INFO", "add_to_pool: tx abc"), node_line(T, "WARN", "peer banned"),
                 node_line(T, "DEBUG", "Received tx kernel: abc", module="epic_p2p::protocol"),
                 node_line(T, "WARN", "Output for commitment 09ab, Message: Not found.", module="epic_api::handlers::chain_api"),
                 node_line(T, "DEBUG", "Transaction 1de rejected: DuplicateTx", module="epic_servers::common::adapters")]
        kept = sl.pick_node(sl.parse_node(lines, 0))
        self.assertEqual([e for _, e, _ in kept], [False, True])

    def test_cap_keeps_errors_then_latest(self):
        kept = [(i, i == 1, str(i)) for i in range(10)]
        shown, more = sl.cap(kept, 3)
        self.assertEqual([x for _, _, x in shown], ["1", "8", "9"])
        self.assertEqual(more, 7)

    def test_remote_node_filter_runs(self):
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "epic-server.log")
            now = time.time()
            with gzip.open(path + ".0.gz", "wt") as f:
                f.write(node_line(now - 50, "INFO", "old file line", utc=False))
            with open(path, "w") as f:
                f.write(node_line(now - 3000, "INFO", "too early", utc=False))
                f.write(node_line(now - 20, "TRACE", "trace", utc=False))
                f.write(node_line(now - 10, "WARN", "in window", utc=False))
            r = subprocess.run([sys.executable, "-I", "-", path, str(now - 100), str(now)], input=sl.REMOTE_NODE,
                               capture_output=True, text=True, timeout=30)
            self.assertEqual(r.returncode, 0, r.stderr)
            body = [x for x in r.stdout.splitlines() if not x.startswith("#")]
            self.assertEqual(len(body), 2, r.stdout)
            self.assertIn("old file line", body[0])
            self.assertIn("in window", body[1])
            offset = int(r.stdout.splitlines()[-1].split()[1])
            got = sl.parse_node(r.stdout.splitlines(True), offset)
            self.assertAlmostEqual(got[-1][0], now - 10, delta=1.5)


class Collect(Base):
    def test_collect_writes_files_and_quotes(self):
        stage = os.path.join(self.tmp, "out")
        os.makedirs(stage)
        with open(os.path.join(stage, "proof.json"), "w") as f:
            json.dump({"details": {"address": "esAbCdEf…Qr12St"}}, f)
        node_log = os.path.join(self.tmp, "epic-server.log")
        relay_log = os.path.join(self.tmp, "relay.log")
        with open(node_log, "w") as f:
            f.write(node_line(T + 30, "ERROR", "push_transaction failed from 192.168.1.9", utc=False))
        with open(relay_log, "w") as f:
            f.write(relay_json(T + 31, "INFO", "c1", "subscribed as esAbCdEfxxxx… (0 slate(s) waiting)"))
        for p in (node_log, relay_log):
            os.utime(p, (T + 40, T + 40))

        def ssh(conf, args, stdin=None):
            if args.startswith("journalctl"):
                self.assertIn(f"--since @{int(T - 60)}", args)
                return JOURNAL, None
            return None, "ssh demo-vps: TimeoutExpired"

        step = types.SimpleNamespace(id="trust-linux-tor", proof=True)
        conf = {"local_node_log": node_log, "local_relay_log": relay_log}
        sm = sl.collect(step, {"started": iso(T), "ended": iso(T + 100)}, stage, conf, ssh=ssh)
        self.assertEqual(sm["sources"]["remote relay"]["lines"], 7)
        self.assertEqual(sm["sources"]["remote relay"]["other_errors"], 1)
        self.assertFalse(sm["sources"]["remote node"]["read"])
        self.assertEqual(sm["sources"]["local node"]["errors"], 1)
        self.assertEqual(sm["sources"]["local relay"]["lines"], 1)
        with open(os.path.join(stage, "server-logs.txt")) as f:
            text = f.read()
        for leak in ("81.2.3.4", "192.168.1.9", LANE, OTHER):
            self.assertNotIn(leak, text)
        self.assertIn("esAbCdEf…Qr12St", text)
        with open(os.path.join(stage, "server-logs.json")) as f:
            self.assertEqual(json.load(f), sm)
        q = sl.quote_lines(sm)
        self.assertEqual(q[0], "remote relay: 7 lines, 1 error (+1 error of other connections)")
        self.assertTrue(any(x.startswith("remote node: not read") for x in q))
        self.assertTrue(any("push_transaction failed from <ip>" in x for x in q))


class Hooks(Base):
    """The failure alert's detail and the gate's lines, on stand-ins for the engine and the run."""

    def stand_in(self, status):
        step = types.SimpleNamespace(id="trust-linux-tor", proof=True)
        out = os.path.join(self.tmp, "steps", step.id, "out")
        os.makedirs(out, exist_ok=True)
        run = types.SimpleNamespace(steps=[step], status=lambda sid: status, step_dir=lambda sid: os.path.dirname(out))
        echoed = []
        eng = types.SimpleNamespace(dry=False, run=run, echo=echoed.append,
                                    pipeline=types.SimpleNamespace(serverlogs={"ssh": "nowhere.invalid",
                                                                               "local_node_log": "/nonexistent/x.log",
                                                                               "local_relay_log": "/nonexistent/y.log",
                                                                               "ssh_timeout_s": 5}))
        return eng, step, out, echoed

    def test_alert_detail_has_server_lines_above_the_log_tail(self):
        st = {"status": "failed", "started": iso(T), "ended": iso(T + 60)}
        eng, step, out, echoed = self.stand_in(st)
        log = os.path.join(self.tmp, "attempt-1.log")
        with open(log, "w") as f:
            f.write("".join(f"log line {i}\n" for i in range(100)))
        detail = Engine.server_logs(eng, step, st, log)
        self.assertTrue(detail.startswith("Server logs "), detail)
        self.assertIn("local node: not read (no local node log)", detail)
        self.assertTrue(detail.endswith("log line 99"))
        self.assertNotIn("log line 59\n", detail)
        self.assertLessEqual(len(detail), 3000)
        self.assertTrue(os.path.exists(os.path.join(out, "server-logs.txt")))
        eng.dry = True
        self.assertIsNone(Engine.server_logs(eng, step, st, log))

    def test_gate_lines_for_a_lane_that_failed_a_try(self):
        eng, step, out, _ = self.stand_in({"status": "done", "attempt_causes": ["harness"]})
        self.assertEqual(builtins.server_log_lines(eng), [])
        sm = {"window": ["10:00:00", "10:02:00"], "sources": {
            "remote relay": {"read": True, "lines": 2, "errors": 1, "other_errors": 0,
                                "quote": ["10:00:15 Error insert to db"]},
            "local node": {"read": False, "note": "no local node log"}}}
        with open(os.path.join(out, "server-logs.json"), "w") as f:
            json.dump(sm, f)
        self.assertEqual(builtins.server_log_lines(eng), [
            "Server logs for lanes that failed a try:",
            "- trust-linux-tor at its failure, 10:00:00–10:02:00 UTC:",
            "  remote relay: 2 lines, 1 error",
            "    10:00:15 Error insert to db",
            "  local node: not read (no local node log)"])
        eng.run.status = lambda sid: {"status": "done"}
        self.assertEqual(builtins.server_log_lines(eng), [])


if __name__ == "__main__":
    unittest.main()
