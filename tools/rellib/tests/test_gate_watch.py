# SPDX-License-Identifier: Apache-2.0
"""The gate watcher: publishes once on an approval, never on anything else; a hold, a new gate
question or a finished run ends it; a relay error or a busy run does not; one watcher per gate
question; the gate starts one when it waits (never in a dry run) and its answer does not change."""
import os
import unittest

from support import Base
from rellib import gatewatch
from rellib.engine import EXIT_BUSY, EXIT_DENIED, EXIT_OK, EXIT_WAITING
from rellib.run import Run


class Clock:
    """A fake clock and sleep: each sleep moves time on and may change the world (then)."""

    def __init__(self, then=None):
        self.t = 1000.0
        self.slept = []
        self.then = then or (lambda n: None)

    def clock(self):
        return self.t

    def sleep(self, s):
        self.slept.append(s)
        self.t += s
        self.then(len(self.slept))


class GateWatchTest(Base):
    def asked_run(self):
        """A run whose publish gate was asked (gate 3 on relay release 7), as publish_gate leaves it."""
        run = self.make_run(only="android", sets=["publish.manifests=false"])
        run.info["relmsg"] = {"release_id": 7}
        run.info["gates"] = {"publish": {"gate_id": 3, "state": "pending"}}
        run.save_info()
        run.set_status("publish-gate", status="waiting")
        return run

    def watcher(self, run, codes=(), then=None, hours=None):
        self.rel_calls = []
        codes = list(codes)

        def rel(args):
            self.rel_calls.append(args[0])
            return codes.pop(0) if codes else EXIT_OK

        if hours is not None:
            self.pipeline.data["gate"] = {"watch_hours": hours}
        self.clk = Clock(then)
        return gatewatch.Watcher(run, self.pipeline, rel, every=60, sleep=self.clk.sleep, clock=self.clk.clock)

    def set_gate(self, answer):
        os.environ["REL_FAKE_GATE"] = answer

    def test_approved_publishes_once(self):
        run = self.asked_run()
        self.set_gate("approved")
        code, msg = self.watcher(run).loop()
        self.assertEqual(code, EXIT_OK, msg)
        self.assertEqual(self.rel_calls, ["publish"])
        self.assertIn("gate-status 3", self.relmsg_calls())
        self.assertNotIn("approve", self.relmsg_calls().replace("approved", ""))
        self.assertIn("published", [e.get("state") for e in Run(run.path).events() if e["event"] == "gate-watch"])
        self.assertIn("tools/rel publish exit 0", open(gatewatch.log_path(run)).read())

    def test_hosted_builds_source_mark_is_not_a_publish(self):
        # 26.11.2 run-3: the hosted preflight's record of the GitHub commit once stopped the watcher
        # as "already published".
        run = self.asked_run()
        run.info["source_published"] = {"commit": "6" * 40, "short": "6" * 7}
        run.save_info()
        self.set_gate("approved")
        code, msg = self.watcher(run).loop()
        self.assertEqual(code, EXIT_OK, msg)
        self.assertEqual(self.rel_calls, ["publish"])

    def test_pending_never_publishes(self):
        run = self.asked_run()
        code, msg = self.watcher(run, hours=0.1).loop()  # 6 minutes of fake time at 60 s
        self.assertEqual(code, EXIT_OK)
        self.assertEqual(self.rel_calls, [])
        self.assertIn("no decision", msg)
        self.assertGreaterEqual(len(self.clk.slept), 5)

    def test_held_is_recorded_and_ends_the_watch(self):
        run = self.asked_run()
        self.set_gate("held")
        code, msg = self.watcher(run, codes=[EXIT_DENIED]).loop()
        self.assertEqual(self.rel_calls, ["gate"])  # tools/rel gate records the hold; nothing published
        self.assertIn("held by the owner", msg)

    def test_relay_error_keeps_watching_with_backoff(self):
        run = self.asked_run()
        self.set_gate("error")
        code, msg = self.watcher(run, then=lambda n: n == 3 and self.set_gate("approved")).loop()
        self.assertEqual(self.rel_calls, ["publish"])
        self.assertEqual(len(self.clk.slept), 3)
        self.assertGreater(self.clk.slept[1], self.clk.slept[0] + 30)  # less often after each error

    def test_busy_run_is_tried_again(self):
        run = self.asked_run()
        self.set_gate("approved")
        # 75: another tools/rel holds the run; 10 with the gate not done: publish found its gate check busy.
        code, msg = self.watcher(run, codes=[EXIT_BUSY, EXIT_WAITING, EXIT_OK]).loop()
        self.assertEqual(self.rel_calls, ["publish", "publish", "publish"])
        self.assertEqual(code, EXIT_OK)

    def test_publish_waiting_after_the_gate_is_done_stops(self):
        run = self.asked_run()
        run.set_status("publish-gate", status="done")
        self.set_gate("approved")
        code, msg = self.watcher(run, codes=[EXIT_WAITING]).loop()
        self.assertEqual(self.rel_calls, ["publish"])
        self.assertEqual(code, EXIT_WAITING)

    def test_new_gate_question_stops_it(self):
        run = self.asked_run()

        def reask(n):
            r = Run(run.path)
            r.info["gates"]["publish"]["gate_id"] = 4
            r.save_info()

        code, msg = self.watcher(run, then=reask).loop()
        self.assertEqual(self.rel_calls, [])
        self.assertIn("new gate question (4)", msg)

    def test_finished_runs_stop_it(self):
        for key, val in (("tainted", [{"reason": "x"}]), ("published", "2026-11-03T08:00:00Z"),
                         ("relmsg", {"release_id": 7, "superseded_by": "26.10.25-run9"})):
            with self.subTest(key=key):
                run = self.asked_run()
                run.info[key] = val
                run.save_info()
                self.set_gate("approved")
                code, msg = self.watcher(run).loop()
                self.assertEqual(self.rel_calls, [])

    def test_one_watcher_per_gate_question(self):
        run = self.asked_run()
        held = gatewatch.take_lock(run, "publish", 3)
        self.set_gate("approved")
        code, msg = self.watcher(run).loop()
        self.assertEqual(code, EXIT_OK)
        self.assertIn("already watching", msg)
        self.assertEqual(self.rel_calls, [])
        held.close()  # the first watcher died: a new one watches
        code, msg = self.watcher(run).loop()
        self.assertEqual(self.rel_calls, ["publish"])

    def test_gate_waiting_starts_a_watcher_dry_run_does_not(self):
        started = []

        def fake_spawn(argv, unit, log, max_s):
            started.append((argv, unit))
            return {"how": "systemd", "unit": unit}

        real = gatewatch.spawn
        gatewatch.spawn = fake_spawn
        self.addCleanup(setattr, gatewatch, "spawn", real)
        os.environ.pop("REL_GATEWATCH")
        run = self.make_run(only="android", sets=["publish.manifests=false"])
        eng = self.engine(run)
        eng.drive(self.build_ids(run))
        st = run.status("publish-gate")
        self.assertEqual(st["status"], "waiting")
        self.assertEqual(len(started), 1)
        argv, unit = started[0]
        self.assertEqual(argv[-4:], ["gate-watch", "--run", run.path, "--foreground"])
        self.assertIn("--state-root", argv)
        self.assertEqual(unit, "rel-gatewatch-26-10-25-run1-publish-3")
        self.assertEqual(run.info["gates"]["publish"]["watch"]["unit"], unit)
        self.assertIn("gate watcher", st["note"])
        self.assertTrue(any(e["event"] == "gate-watch" and e.get("state") == "started" for e in run.events()))

        # A watcher that fails to start leaves the gate's answer as it was.
        def broken(*a):
            raise OSError("no way")
        gatewatch.spawn = broken
        st = eng.execute(run.step("publish-gate"))
        self.assertEqual(st["status"], "waiting")
        self.assertIn("gate watcher not started", st["note"])

        started.clear()
        gatewatch.spawn = fake_spawn
        dry = self.make_run(version="26.10.26", only="android", sets=["publish.manifests=false"])
        deng = self.engine(dry)
        deng.dry = True
        deng.drive(self.build_ids(dry))
        self.assertEqual(started, [])


if __name__ == "__main__":
    unittest.main()
