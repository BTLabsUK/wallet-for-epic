# SPDX-License-Identifier: Apache-2.0
"""One tools/rel per lane, not per run: a lane is one rig, so retries on different rigs run side by
side; [concurrency] and run.json stay safe across the processes. Another Run object on the same folder
stands in for the other process: flock is held per open file."""
import json
import os
from types import SimpleNamespace

from test_repeats import GOOD, Repeats
from rellib import window
from rellib.run import Busy, Run


class LaneLockTest(Repeats):
    def setUp(self):
        super().setUp()
        path = os.path.join(self.run_.path, "plan.json")  # the fake pipeline has one lane; the real one a lane per rig
        with open(path, encoding="utf-8") as f:
            plan = json.load(f)
        for d in plan:
            d["lane"] = "rig-android" if d["id"] == self.android.id else "rig-linux" if d["id"] == self.linux.id else d["lane"]
        with open(path, "w", encoding="utf-8") as f:
            json.dump(plan, f)
        self.android.lane, self.linux.lane = "rig-android", "rig-linux"

    def other(self):
        r = Run(self.run_.path)
        self.addCleanup(lambda: [r.release_lane(s.lane) for s in r.steps])
        return r

    def test_a_retry_runs_while_another_lane_is_held(self):
        self.fail("product", rc=1)
        self.other().claim_lanes([self.linux])
        self.lane("attempt", GOOD, 0)
        self.assertEqual(self.rel("retry", self.android.id)[0], 0)
        self.assertEqual(self.run_.status(self.android.id)["status"], "done")

    def test_a_retry_on_a_held_lane_is_refused_and_changes_nothing(self):
        self.fail("product", rc=1)
        self.other().claim_lanes([self.android])
        code, out, err = self.rel("retry", self.android.id)
        self.assertEqual(code, 75, out + err)
        self.assertIn(f"lane {self.android.lane} ({self.android.id})", out + err)
        self.assertEqual(self.run_.status(self.android.id)["status"], "failed")

    def test_a_probe_is_held_off_by_its_lane_only(self):
        self.fail()
        self.driver_fix()
        o = self.other()
        o.claim_lanes([self.android])
        self.assertEqual(self.probe()[0], 75)
        o.release_lanes([self.android])
        o.claim_lanes([self.linux])
        self.assertEqual(self.probe()[0], 0)

    def test_a_lane_is_free_again_after_the_retry(self):
        self.fail("product", rc=1)
        self.rel("retry", self.android.id)
        self.other().claim_lanes([self.android])

    def test_all_or_none(self):
        o = self.other()
        o.claim_lanes([self.linux])
        with self.assertRaises(Busy):
            self.run_.claim_lanes([self.android, self.linux])
        self.assertEqual(self.run_._lanes, {})

    def test_the_owner_is_no_other_process(self):
        self.run_.claim_lane(self.android.lane, self.android.id)
        self.run_.claim_lane(self.android.lane, self.android.id)
        self.run_.release_lane(self.android.lane)
        o = self.other()
        self.assertEqual(o.lane_user(self.android.lane), self.android.id)
        self.assertEqual([s.id for s in o.elsewhere()], [self.android.id])
        self.assertIsNone(self.run_.lane_user(self.android.lane))
        self.run_.release_lane(self.android.lane)
        self.assertIsNone(o.lane_user(self.android.lane))

    def test_the_cap_and_apart_count_the_other_process(self):
        self.eng.policy = window.Policy({"max_heavy": 1, "apart": [["trust-android", "trust-linux"]]})
        self.assertIn("heavy-step cap", self.eng.may_start(self.android, {}, 0, [self.linux]) or "")
        self.eng.policy = window.Policy({"max_heavy": 5, "apart": [[self.android.base, self.linux.base]]})
        self.assertIn(f"kept apart from {self.linux.id}", self.eng.may_start(self.android, {}, 0, [self.linux]) or "")

    def test_a_drive_leaves_a_step_running_elsewhere_alone(self):
        o = self.other()
        o.claim_lanes([self.android])
        self.run_.set_status(self.android.id, status="running")
        self.assertTrue(self.eng.running_elsewhere(self.run_.steps, {s.id: self.run_.status(s.id)["status"]
                                                                     for s in self.run_.steps}))
        o.release_lanes([self.android])
        self.assertFalse(self.eng.running_elsewhere(self.run_.steps, {s.id: self.run_.status(s.id)["status"]
                                                                      for s in self.run_.steps}))

    def test_a_drive_waits_for_a_held_lane(self):
        self.eng.policy.poll = 0.01
        o = self.other()
        o.claim_lanes([self.android])
        seen = []
        slept = SimpleNamespace(n=0)

        def later(_):
            slept.n += 1
            if slept.n == 2:
                seen.append(self.run_.status(self.android.id)["status"])
                o.release_lanes([self.android])
        import rellib.engine as e
        real = e.time.sleep
        e.time.sleep = later
        self.addCleanup(setattr, e.time, "sleep", real)
        self.lane("attempt", GOOD, 0)
        self.eng.drive([self.android.id], stop_on_fail=False)
        self.assertEqual(seen, ["pending"])
        self.assertEqual(self.run_.status(self.android.id)["status"], "done")


class RunJsonTest(Repeats):
    def test_two_processes_keep_each_others_keys(self):
        a, b = Run(self.run_.path), Run(self.run_.path)
        a.info["one"] = 1
        a.save_info()
        b.info["two"] = 2
        b.save_info()
        with open(os.path.join(self.run_.path, "run.json"), encoding="utf-8") as f:
            disk = json.load(f)
        self.assertEqual((disk["one"], disk["two"]), (1, 2))
        self.assertEqual(b.info["one"], 1)

    def test_a_deleted_key_goes(self):
        a = Run(self.run_.path)
        a.info["gone"] = 1
        a.save_info()
        b = Run(self.run_.path)
        del b.info["gone"]
        b.save_info()
        self.assertNotIn("gone", Run(self.run_.path).info)

    def test_taints_add_up(self):
        a, b = Run(self.run_.path), Run(self.run_.path)
        a.taint("one")
        b.taint("two")
        self.assertEqual([t["reason"] for t in Run(self.run_.path).info["tainted"]], ["one", "two"])
