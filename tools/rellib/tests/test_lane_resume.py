# SPDX-License-Identifier: Apache-2.0
"""A lane's rerun from its resume point, on fake platforms: the plan core/lane.py makes from a failed
attempt's proof, and Linux's and Android's save_point, load_point and resume_from (Windows:
test_rig_health.py). A phase fault the lane goes on after, and how it decides the exit code."""
import importlib.util
import json
import os
import sys
import tempfile
import unittest
from unittest import mock

HERE = os.path.dirname(os.path.abspath(__file__))
DRV = os.path.join(os.path.dirname(HERE), "drivers")
sys.path.insert(0, DRV)

from core import checks  # noqa: E402
from core import lane as core_lane  # noqa: E402
from core.faults import HarnessFault, ProductFault, RefusedStart  # noqa: E402


def load(sub, name):
    """A platform module from its own folder, under a name of its own (each folder has a files.py)."""
    saved = list(sys.path)
    was = {k: sys.modules.pop(k) for k in ("files", "uia", "sandbox", "surface", "standin") if k in sys.modules}
    sys.path.insert(0, os.path.join(DRV, sub))
    try:
        spec = importlib.util.spec_from_file_location("resume_%s" % name, os.path.join(DRV, sub, name + ".py"))
        mod = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = mod
        spec.loader.exec_module(mod)
        return mod
    finally:
        sys.path[:] = saved
        sys.modules.update(was)


lp = load("linux", "linux_platform")
ap = load("android", "android_platform")


class Fake(core_lane.Platform):
    name, variant = "linux", "tor"

    def __init__(self, folder, handle=None, takes=(True, "taken")):
        self.folder, self.handle, self.takes, self.given = folder, handle, takes, None

    def resume_dir(self):
        return self.folder

    def resume_handle(self):
        return self.handle

    def resume_from(self, handle):
        self.given = handle
        return self.takes


class PlanTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.out = os.path.join(self.tmp.name, "flow-linux-tor", "out")
        self.keep = os.path.join(self.tmp.name, "keep")
        os.makedirs(self.out)
        os.makedirs(self.keep)
        patch = mock.patch.dict(os.environ)
        patch.start()
        self.addCleanup(patch.stop)
        for name in ("REL_TRUST_RESUME", "REL_TRUST_FRESH", "REL_PRIOR_CAUSE", "REL_TRUST_PROBE"):
            os.environ.pop(name, None)
        self.logs = []

    def lane(self, plat):
        return core_lane.Lane(plat, None, checks, out=self.out, log=self.logs.append, required=["update_ok"], funds=False)

    def attempt(self, failed, kind="harness", done=("previous", "resume-point", "update"), point=True, name="proof.before-attempt-1.json",
                details=None):
        secrets = os.path.join(self.keep, "lane-resume.json")
        with open(secrets, "w") as f:
            json.dump({"secrets": {"password": "x"}, "point": {"before": {}} if point else None}, f)
        with open(os.path.join(self.out, name), "w") as f:
            json.dump({"fault": {"kind": kind}, "phases": {"failed": failed, "done": list(done)}, "details": details or {},
                       "resume": {"handle": {"run": "r"}, "mode": "seed", "secrets": secrets, "point": point}}, f)

    def test_a_retry_resumes_with_nothing_set(self):
        self.attempt("candidate")
        p = Fake(self.keep)
        plan = self.lane(p)._resume_plan()
        self.assertEqual(plan["failed"], "candidate")
        self.assertEqual(plan["secrets"], {"password": "x"})
        self.assertEqual(p.given, {"run": "r"})
        self.assertTrue(os.path.exists(os.path.join(self.keep, "lane-resume.json")))  # a probe reads it, then the retry

    def test_a_fault_on_the_way_back_goes_back_to_the_same_phase(self):
        for phase, at in (("resume-install", "address"), ("previous-open", "address"), ("point-load", "candidate")):
            self.attempt(phase, details={"resume": {"resumed": True, "at": at}})
            self.assertEqual(self.lane(Fake(self.keep))._resume_plan()["failed"], at, phase)

    def test_a_first_attempt_that_could_not_open_the_wallet_resumes_at_its_setup(self):
        self.attempt("previous-open", details={"resume": {"resumed": False, "why": "the first attempt"}})
        self.assertEqual(self.lane(Fake(self.keep))._resume_plan()["failed"], "previous-setup")

    def refused(self, lane):
        with self.assertRaises(RefusedStart) as ctx:
            lane._resume_plan()
        self.assertTrue(lane.details["resume"]["refused"])
        return str(ctx.exception)

    def test_a_silent_start_from_the_beginning_is_refused(self):
        self.attempt("previous-setup", done=("prepare", "install"))
        line = self.refused(self.lane(Fake(self.keep)))
        self.assertIn("the failed attempt stopped in phase previous-setup and cannot be resumed", line)
        self.assertIn('tools/rel retry flow-linux-tor --fresh "<reason>"', line)

    def test_the_refusal_names_the_failing_step(self):
        self.attempt("previous-setup")
        with open(os.path.join(self.out, "proof.before-attempt-1.json"), "r+") as f:
            proof = json.load(f)
            proof["fault"]["step"], proof["resume"] = "find-g4.advanced.technical", None
            f.seek(0), f.truncate(), json.dump(proof, f)
        self.assertIn("in phase previous-setup at step find-g4.advanced.technical and cannot be resumed: it left no state to "
                      "resume from (linux)", self.refused(self.lane(Fake(self.keep))))

    def test_a_reason_starts_it_and_says_so(self):
        self.attempt("candidate", point=False)
        os.environ["REL_TRUST_FRESH"] = "the kept wallet is damaged"
        lane = self.lane(Fake(self.keep))
        self.assertIsNone(lane._resume_plan())
        self.assertEqual(lane.details["resume"], {"resumed": False, "why": "--fresh", "forced": "the kept wallet is damaged",
                                                  "repeat": True})

    def test_a_reason_means_the_start_even_with_a_point(self):
        self.attempt("candidate")
        os.environ["REL_TRUST_FRESH"] = "the point is the suspect"
        p = Fake(self.keep)
        self.assertIsNone(self.lane(p)._resume_plan())
        self.assertIsNone(p.given)

    def test_off_when_asked_is_no_way_past(self):
        self.attempt("candidate")
        os.environ["REL_TRUST_RESUME"] = "0"
        self.assertIn("REL_TRUST_RESUME=0", self.refused(self.lane(Fake(self.keep))))

    def test_a_machine_failure_may_start_over(self):
        self.attempt("candidate", kind="infra", point=False)
        lane = self.lane(Fake(self.keep))
        self.assertIsNone(lane._resume_plan())
        self.assertEqual(lane.details["resume"]["why"], "the machine failed and it kept no resume point")

    def test_no_proof_after_a_machine_failure_may_start_over(self):
        os.environ["REL_PRIOR_CAUSE"] = "infra:sigkill"
        lane = self.lane(Fake(self.keep))
        self.assertIsNone(lane._resume_plan())
        self.assertEqual(lane.details["resume"]["why"], "the machine failed and left no proof (infra:sigkill)")

    def test_no_proof_after_a_driver_failure_is_refused(self):
        os.environ["REL_PRIOR_CAUSE"] = "harness:crash"
        self.assertIn("it left no proof (harness:crash)", self.refused(self.lane(Fake(self.keep))))

    def test_a_failure_before_the_wallet_starts_over(self):
        self.attempt("prepare", done=())
        self.assertIsNone(self.lane(Fake(self.keep))._resume_plan())

    def test_a_refused_start_is_passed_over_when_the_next_one_looks_back(self):
        self.attempt("candidate")
        with open(os.path.join(self.out, "proof.json"), "w") as f:
            json.dump({"refused": True, "fault": {"kind": "refused"}}, f)
        self.assertEqual(self.lane(Fake(self.keep))._resume_plan()["failed"], "candidate")

    def test_first_attempt_starts_fresh(self):
        lane = self.lane(Fake(self.keep))
        self.assertIsNone(lane._resume_plan())
        self.assertFalse(lane.details["resume"]["resumed"])

    def test_a_product_fault_is_a_result(self):
        self.attempt("candidate", kind="product")
        p = Fake(self.keep)
        self.assertIsNone(self.lane(p)._resume_plan())
        self.assertIsNone(p.given)

    def test_no_point_is_refused(self):
        self.attempt("candidate", point=False)
        self.assertIn("it kept no resume point", self.refused(self.lane(Fake(self.keep))))

    def test_funds_are_not_rerun(self):
        self.attempt("funds")
        lane = self.lane(Fake(self.keep))
        self.assertIn("a lane resumes only at", self.refused(lane))
        self.assertIn("fund", lane.details["resume"]["why"])

    def test_a_platform_that_cannot_take_it_is_refused(self):
        self.attempt("candidate")
        lane = self.lane(Fake(self.keep, takes=(False, "the snapshot is gone")))
        self.assertIn("the snapshot is gone", self.refused(lane))

    def test_a_point_not_kept_goes_on_and_a_fatal_fault_does_not(self):
        p = Fake(self.keep)
        lane = self.lane(p)
        p.save_point = mock.Mock(side_effect=HarnessFault("resume-point", "no room"))
        lane._save_point({}, {})
        self.assertIsNone(lane.point)
        p.save_point = mock.Mock(return_value=True)
        lane._save_point({"a": 1}, {})
        self.assertEqual(lane.point["before"], {"a": 1})


class KeptFaultTest(unittest.TestCase):
    def lane(self, required, alive=True):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        p = Fake(self.tmp.name)
        p.alive = lambda: alive
        return core_lane.Lane(p, None, checks, out=self.tmp.name, log=lambda s: None, required=required, funds=False)

    def fail(self, fault):
        raise fault

    def test_the_lane_goes_on(self):
        lane = self.lane(["a"])
        self.assertIsNone(lane.try_phase("one", lambda: self.fail(HarnessFault("one", "x"))))
        self.assertEqual(lane.try_phase("two", lambda: 2), 2)
        self.assertTrue(lane.failed("one"))
        self.assertFalse(lane.failed("two"))

    def test_a_dead_app_stops_it(self):
        lane = self.lane(["a"], alive=False)
        with self.assertRaises(HarnessFault):
            lane.try_phase("one", lambda: self.fail(HarnessFault("one", "x")))

    def test_required_checks_decide(self):
        lane = self.lane(["a"])
        lane.try_phase("one", lambda: self.fail(HarnessFault("one", "x")))
        lane.results["a"] = True
        self.assertEqual(lane._settle_kept(), 0)

    def test_a_check_that_never_ran_fails(self):
        lane = self.lane(["a"])
        lane.try_phase("one", lambda: self.fail(HarnessFault("one", "x")))
        self.assertEqual(lane._settle_kept(), 2)

    def test_a_product_fault_is_exit_1(self):
        lane = self.lane(["a"])
        lane.try_phase("one", lambda: self.fail(ProductFault("one", "x")))
        self.assertEqual(lane._settle_kept(), 1)


class LinuxPointTest(unittest.TestCase):
    def test_the_point_is_the_state_kept_in_the_work_folder(self):
        with tempfile.TemporaryDirectory() as d:
            p = object.__new__(lp.LinuxPlatform)
            p.work, p.calls = d, []
            p.save_state = lambda folder: p.calls.append(("save", folder))
            p.restore_state = lambda folder: p.calls.append(("load", folder))
            self.assertTrue(p.save_point())
            p.load_point()
            point = os.path.join(d, "point")
            self.assertEqual(p.calls, [("save", point), ("load", point)])
            self.assertEqual(os.stat(point).st_mode & 0o777, 0o700)


class AndroidPointTest(unittest.TestCase):
    def phone(self, snapshots=()):
        p = object.__new__(ap.AndroidPlatform)
        p.variant, p.avd, p.running, p.log = "tor", "wfe_trust_tor", None, lambda s: None
        p.point_saved, p.state_saved, p.resume_snapshot = False, False, None
        p.standin_ports, p.resume_ports = {"node": 40001}, {}
        p.snaps = set(snapshots)
        p._snapshots = lambda: p.snaps

        def emu(*args, timeout=120):
            if args[:3] == ("avd", "snapshot", "save") and not p.fail_save:
                p.snaps.add(args[3])
            if args[:3] == ("avd", "snapshot", "delete"):
                p.snaps.discard(args[3])
            return mock.Mock(stdout="OK", stderr="")
        p.fail_save, p._emu_cmd = False, emu
        return p

    def test_no_handle_before_the_point(self):
        p = self.phone()
        self.assertIsNone(p.resume_handle())
        self.assertTrue(p.save_point())
        self.assertEqual(p.resume_handle(), {"avd": p.avd, "snapshot": "trust-point-tor", "ports": {"node": 40001}})

    def test_a_fault_before_the_point_keeps_a_snapshot_of_its_own(self):
        p = self.phone()
        p.running = "old"
        p.stop = lambda: setattr(p, "running", None)
        p._kept_up = lambda: True
        p.keep_state()
        self.assertEqual(p.resume_handle()["snapshot"], p._fault_state())

    def test_a_resumed_attempt_can_be_resumed(self):
        p = self.phone(["trust-point-tor"])
        p._load = lambda name: None
        p.load_point()
        self.assertEqual(p.resume_handle()["snapshot"], "trust-point-tor")

    def test_an_old_point_never_passes_for_a_new_one(self):
        p = self.phone(["trust-point-tor"])
        p.fail_save = True
        with self.assertRaises(HarnessFault):
            p.save_point()
        self.assertIsNone(p.resume_handle())

    def test_the_point_stays_out_of_the_pruned_names(self):
        self.assertFalse(self.phone()._point().startswith(ap.SNAP_PREFIX + "tor-"))

    def test_resume_takes_the_same_ports(self):
        p = self.phone(["trust-point-tor"])
        with mock.patch.object(ap.socket, "socket"):
            ok, _ = p.resume_from({"avd": p.avd, "snapshot": "trust-point-tor", "ports": {"node": 40001}})
        self.assertTrue(ok)
        self.assertEqual(p.resume_ports, {"node": 40001})

    def test_resume_refuses_another_lanes_point_a_lost_one_or_a_taken_port(self):
        p = self.phone(["trust-point-tor"])
        self.assertFalse(p.resume_from({"avd": "other", "snapshot": "trust-point-tor"})[0])
        self.assertFalse(p.resume_from({"avd": p.avd, "snapshot": "trust-point-notor"})[0])
        p.snaps.clear()
        self.assertFalse(p.resume_from({"avd": p.avd, "snapshot": "trust-point-tor"})[0])
        p.snaps.add("trust-point-tor")
        with mock.patch.object(ap.socket, "socket") as s:
            s.return_value.__enter__.return_value.bind.side_effect = OSError("in use")
            ok, why = p.resume_from({"avd": p.avd, "snapshot": "trust-point-tor", "ports": {"node": 40001}})
        self.assertFalse(ok)
        self.assertIn("taken", why)
        self.assertEqual(p.resume_ports, {})


if __name__ == "__main__":
    unittest.main()
