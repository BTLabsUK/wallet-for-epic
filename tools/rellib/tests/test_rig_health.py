# SPDX-License-Identifier: Apache-2.0
"""Windows rig health (drivers/windows/rig.py): the judge on the facts rig-health.ps1 reads, the fallback
order, the fail-fast pickup, the platform's move to a healthy rig with one alert, G1 preflight and the
nightly's `rigs`. No rig: the box's answers are canned (rig 1 and rig 5 as read on 2026-11-01)."""
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(os.path.dirname(HERE))
WIN = os.path.join(os.path.dirname(HERE), "drivers", "windows")
sys.path.insert(0, WIN)
sys.path.insert(0, TOOLS)


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


# drivers/android has a uia.py too: windows_platform gets the Windows one and leaves the name as it found it.
_other_uia = sys.modules.pop("uia", None)
import rig  # noqa: E402
import windows_platform as wp  # noqa: E402
sys.modules.pop("uia", None)
if _other_uia is not None:
    sys.modules["uia"] = _other_uia
from core.faults import HarnessFault, InfraFault  # noqa: E402
nightly = load("nightly_rigs", os.path.join(TOOLS, "nightly", "nightly.py"))
from rellib import builtins  # noqa: E402

RIG1 = {"session": 1, "task": "EpicWalletRig", "work": "C:\\EpicRig", "exists": True, "enabled": True, "state": "Ready",
        "logon": "Password", "last_result": 0, "last_run": "2026-11-01T09:04:36Z", "next_run": "2026-11-01T09:06:35Z",
        "sid": "S-1-5-21-1-2-3-1002", "user": "epicrig", "account_enabled": True, "password_expires": None,
        "account_expires": None, "locked": False, "rights_error": "", "batch_right": True, "batch_denied": False,
        "profile": True, "queued": 0, "oldest_queued": None, "running_jobs": 0, "now": "2026-11-01T09:04:59Z"}
RIG5 = dict(RIG1, session=5, task="EpicWalletRig5", work="C:\\EpicRig5", last_result=267011, last_run=None,
            sid="S-1-5-21-1-2-3-1004", user="epicrig2", batch_right=False, profile=False)


def hosts(rigs):
    d = tempfile.mkdtemp()
    p = os.path.join(d, "hosts.toml")
    with open(p, "w") as f:
        f.write("[host.windows]\nssh = \"windows-pc\"\nrigs = { %s }\n" % ", ".join("%s = %d" % kv for kv in rigs.items()))
    return p


def read_notice(r):
    with open(os.path.join(r.out, "notice.json"), encoding="utf-8") as f:
        return json.load(f)


class JudgeTest(unittest.TestCase):
    def test_rig1_healthy(self):
        self.assertEqual(rig.judge(RIG1), [])

    def test_rig5_names_the_batch_right_first(self):
        p = rig.judge(RIG5)
        self.assertIn("SeBatchLogonRight", p[0])
        self.assertIn("epicrig2", p[0])
        self.assertTrue(any("never run" in x and "267011" in x for x in p))

    def test_account_states(self):
        for change, word in (({"enabled": False}, "disabled"), ({"account_enabled": False}, "account epicrig is disabled"),
                             ({"locked": True}, "locked out"), ({"password_expires": "2026-10-31T00:00:00Z"}, "password"),
                             ({"batch_denied": True}, "SeDenyBatchLogonRight"), ({"exists": False}, "no scheduled task"),
                             ({"last_result": 1}, "last run result 1 (0x1)")):
            with self.subTest(word):
                self.assertTrue(any(word in x for x in rig.judge(dict(RIG1, **change))), rig.judge(dict(RIG1, **change)))

    def test_password_expiring_later_is_fine(self):
        self.assertEqual(rig.judge(dict(RIG1, password_expires="2027-01-01T00:00:00Z")), [])

    def test_heartbeat(self):
        old = dict(RIG1, last_run="2026-11-01T08:30:00Z")
        self.assertTrue(any("has not run since" in x for x in rig.judge(old)))
        # a long job: the task is running, no new run for hours is expected
        self.assertEqual(rig.judge(dict(old, state="Running", last_result=0x41301)), [])

    def test_trigger_refused_while_running_is_busy_not_dead(self):
        # 0x800710E0: the 2-minute trigger refused because the task still runs a job
        self.assertEqual(rig.judge(dict(RIG1, state="Running", last_result=0x800710E0)), [])
        self.assertTrue(any("0x800710E0" in x for x in rig.judge(dict(RIG1, last_result=0x800710E0))))

    def test_stuck_queue(self):
        stuck = dict(RIG1, queued=1, oldest_queued="2026-11-01T08:00:00Z")
        self.assertTrue(any("waiting in C:\\EpicRig\\queue" in x for x in rig.judge(stuck)))
        self.assertEqual(rig.judge(dict(RIG1, queued=1, oldest_queued="2026-11-01T09:04:00Z")), [])

    def test_missing_record(self):
        self.assertEqual(rig.judge(None), ["not found on the box"])

    def test_parse(self):
        out = "noise\r\nRIG %s\r\nRIG %s\r\nRIG {bad\n" % (json.dumps(RIG1), json.dumps(RIG5))
        self.assertEqual(sorted(rig.parse_health(out)), [1, 5])

    def test_command_fits_cmd_exe(self):
        cmd = rig.ps_file_command(os.path.join(WIN, "rig-health.ps1"), "-Sessions 1,5")
        self.assertLess(len(cmd), 8000)
        self.assertTrue(cmd.endswith('-Sessions 1,5"'))


class CandidatesTest(unittest.TestCase):
    def test_order(self):
        with mock.patch.dict(os.environ, {"REL_WIN_RIG": ""}):
            self.assertEqual(rig.candidate_sessions("notor", hosts({"tor": 1, "notor": 5})), [5, 1])
            self.assertEqual(rig.candidate_sessions("tor", hosts({"tor": 2, "notor": 5})), [2, 5, 1])
            self.assertEqual(rig.candidate_sessions("tor", hosts({"tor": 1, "notor": 1})), [1])


class FakeRig(rig.Rig):
    """A Rig whose box is a dict: the queue holds our job until `picks` checks have passed."""

    def __init__(self, picks=None, problems=()):
        super().__init__("box", "run", lambda s: self.logs.append(s), tempfile.mkdtemp(), session=5)
        self.logs, self.picks, self.probs, self.removed = [], picks, list(problems), []
        self.checks = 0

    def pwsh(self, script, timeout=120, check=True):
        if "queue-script.ps1" in script:
            return "queued C:\\EpicRig5\\queue\\20261101-1-trust.json; log: x\n"
        if script.startswith("Remove-Item"):
            self.removed.append(script)
        return ""

    def queued(self):
        self.checks += 1
        return self.picks is None or self.checks <= self.picks

    def problems(self):
        return self.probs

    def call(self, op, timeout=120, **kw):
        return {"ok": True, "user": "epicrig2", "profile": "p"}


class OrphanRig(FakeRig):
    """The rig's done folder holds running marks; a stop file ends the agent `stops` checks later."""

    def __init__(self, marks, stops=1):
        super().__init__()
        self.marks, self.stops, self.stopped = list(marks), stops, []

    def pwsh(self, script, timeout=120, check=True):
        if script.startswith("New-Item"):
            assert "-Path '" in script, script   # New-Item has no -LiteralPath
            self.stopped.append(script.split("'")[1])
            return "True\r\n"
        if "running.json" in script:
            if self.stopped:
                self.stops -= 1
                if self.stops < 0:
                    self.marks = [m for m in self.marks if m + "\\stop" not in self.stopped]
            if "agent.ps1" in script:
                return "".join("ORPHAN %s\r\n" % m for m in self.marks)
            return "".join("ORPHAN %s\r\n" % m for m in self.marks + ["C:\\EpicRig5\\other\\job"])
        return super().pwsh(script, timeout, check)


class OrphanTest(unittest.TestCase):
    OLD = "C:\\EpicRig5\\trust\\runs\\notor-26.10.26-to-26.11.0-20261103-224413"

    def stop(self, r, **kw):
        c = Clock()
        with mock.patch.object(rig.time, "time", c.time), mock.patch.object(rig.time, "sleep", c.sleep):
            return r.stop_orphans(**kw)

    def test_none(self):
        r = OrphanRig([])
        self.assertEqual(self.stop(r), [])
        self.assertEqual(r.stopped, [])

    def test_a_killed_runs_agent_is_stopped_and_waited_for(self):
        r = OrphanRig([self.OLD], stops=2)
        self.assertEqual(self.stop(r), [self.OLD])
        self.assertEqual(r.stopped, [self.OLD + "\\stop"])
        self.assertTrue(any("leftover agent(s) stopped" in x for x in r.logs))

    def test_our_own_run_and_other_folders_are_left_alone(self):
        r = OrphanRig([r"C:\EpicRig5\trust\runs\run", r"C:\EpicRig5\elsewhere\x"])
        self.assertEqual(self.stop(r), [])
        self.assertEqual(r.stopped, [])

    def test_an_agent_that_does_not_stop_makes_the_session_dead(self):
        r = OrphanRig([self.OLD], stops=10 ** 6)
        with self.assertRaises(rig.RigDead):
            self.stop(r, wait_s=60)


class Clock:
    def __init__(self):
        self.t = 1000.0

    def time(self):
        return self.t

    def sleep(self, s):
        self.t += s


class PickupTest(unittest.TestCase):
    def run_agent(self, r, **kw):
        c = Clock()
        with mock.patch.object(rig.time, "time", c.time), mock.patch.object(rig.time, "sleep", c.sleep):
            try:
                return r.start_agent(**kw), c.t - 1000
            except rig.RigDead as e:
                return e, c.t - 1000

    def test_picked_up(self):
        r = FakeRig(picks=2)
        res, _ = self.run_agent(r)
        self.assertTrue(res["ok"])
        self.assertEqual(r.removed, [])

    def test_dead_rig_fails_in_three_minutes_and_takes_its_job_back(self):
        r = FakeRig(picks=None, problems=["epicrig2 lacks 'Log on as a batch job' (SeBatchLogonRight)"])
        res, took = self.run_agent(r)
        self.assertIsInstance(res, rig.RigDead)
        self.assertLessEqual(took, rig.PICKUP_S + 15)
        self.assertIn("SeBatchLogonRight", str(res))
        self.assertEqual(len(r.removed), 1)
        self.assertIn("20261101-1-trust.json", r.removed[0])

    def test_behind_other_jobs_a_dead_rig_is_seen_early(self):
        r = FakeRig(picks=None, problems=["task EpicWalletRig5 has not run since 2026-11-01T08:00:00Z"])
        res, took = self.run_agent(r, wait_s=1800, waiting=1)
        self.assertIsInstance(res, rig.RigDead)
        self.assertLess(took, 300)

    def test_behind_other_jobs_a_live_rig_may_take_longer(self):
        r = FakeRig(picks=20)  # 20 checks of 15 s: 5 min, past PICKUP_S
        res, _ = self.run_agent(r, wait_s=1800, waiting=1)
        self.assertTrue(res["ok"])


class DriverFallbackTest(unittest.TestCase):
    def make_run(self):
        r = object.__new__(wp.WindowsPlatform)
        r.out = tempfile.mkdtemp()
        r.variant, r.host, r.name_run = "notor", "box", "run"
        r.session = None
        r.step, r.rig = "prepare", None
        r.logs = []
        r.log = r.logs.append
        return r

    def fake_rig_class(self, dead_on_pickup=()):
        made = []

        class R:
            def __init__(self, host, name, log, ctl, session=1):
                self.host = host
                self.session, self.run = session, "C:\\EpicRig%d\\trust\\runs\\run" % session
                made.append(self)

            def prepare(self):
                pass

            def put(self, *a):
                pass

            get = ssh = put

            def stop_orphans(self):
                pass

            def put_secret(self, *a):
                return "secret"

            def busy(self):
                return 0

            def start_agent(self, **kw):
                if self.session in dead_on_pickup:
                    raise rig.RigDead("rig session %d did not pick up the job within 180 s" % self.session)

            def close(self):
                pass
        return R, made

    def test_dead_rig_skipped_with_one_alert(self):
        r = self.make_run()
        R, made = self.fake_rig_class()
        report = {5: (RIG5, rig.judge(RIG5)), 1: (RIG1, [])}
        with mock.patch.object(wp, "Rig", R), mock.patch.object(wp, "candidate_sessions", lambda v: [5, 1]), \
                mock.patch.object(wp, "health", lambda host, s, **kw: report):
            r._healthy_rig("prev", "cand")
        self.assertEqual(r.rig.session, 1)
        self.assertEqual([m.session for m in made], [1])
        notice = read_notice(r)
        self.assertIn("rig 5 dead", notice["title"])
        self.assertIn("used rig 1", notice["title"])
        self.assertIn("SeBatchLogonRight", notice["detail"])

    def test_no_pickup_moves_on(self):
        r = self.make_run()
        R, made = self.fake_rig_class(dead_on_pickup=(5,))
        with mock.patch.object(wp, "Rig", R), mock.patch.object(wp, "candidate_sessions", lambda v: [5, 1]), \
                mock.patch.object(wp, "health", lambda host, s, **kw: {5: (RIG5, []), 1: (RIG1, [])}):
            r._healthy_rig("prev", "cand")
        self.assertEqual([m.session for m in made], [5, 1])
        self.assertEqual(r.rig.session, 1)
        self.assertTrue(os.path.isfile(os.path.join(r.out, "notice.json")))

    def test_healthy_rig_no_alert(self):
        r = self.make_run()
        R, _ = self.fake_rig_class()
        with mock.patch.object(wp, "Rig", R), mock.patch.object(wp, "candidate_sessions", lambda v: [1]), \
                mock.patch.object(wp, "health", lambda host, s, **kw: {1: (RIG1, [])}):
            r._healthy_rig("prev", "cand")
        self.assertFalse(os.path.exists(os.path.join(r.out, "notice.json")))

    def test_all_dead_cannot_run(self):
        r = self.make_run()
        R, _ = self.fake_rig_class()
        report = {5: (RIG5, rig.judge(RIG5)), 1: (RIG1, ["account epicrig is locked out"])}
        with mock.patch.object(wp, "Rig", R), mock.patch.object(wp, "candidate_sessions", lambda v: [5, 1]), \
                mock.patch.object(wp, "health", lambda host, s, **kw: report):
            with self.assertRaises(InfraFault) as e:
                r._healthy_rig("prev", "cand")
        self.assertIn("no healthy Windows rig", str(e.exception))
        self.assertIn("no healthy rig left", read_notice(r)["title"])

    def test_health_unanswered_is_infra_before_any_rig_work(self):
        for trouble in (rig.RigError("box asleep"), subprocess.TimeoutExpired("ssh", wp.HEALTH_S)):
            r = self.make_run()
            R, made = self.fake_rig_class()

            def boom(host, s, timeout):
                raise trouble
            with mock.patch.object(wp, "Rig", R), mock.patch.object(wp, "candidate_sessions", lambda v: [5, 1]), \
                    mock.patch.object(wp, "health", boom):
                with self.assertRaises(InfraFault) as e:
                    r._healthy_rig("prev", "cand")
            self.assertEqual(e.exception.sub, "rig")
            self.assertEqual(made, [])

    def test_a_resume_stays_on_its_rig(self):
        r = self.make_run()
        r.session = 1
        R, _ = self.fake_rig_class()
        with mock.patch.object(wp, "Rig", R), mock.patch.object(wp, "candidate_sessions", lambda v: [5, 1]), \
                mock.patch.object(wp, "health", lambda host, s, **kw: {k: (RIG1, []) for k in s}):
            r._healthy_rig("prev", "cand")
        self.assertEqual(r.rig.session, 1)

    def test_prepare_asks_the_rig_before_the_servers(self):
        r = self.make_run()
        r.create, r.work, r.seen = True, tempfile.mkdtemp(), []
        r.cand_dir, r.cand_ver = "", ""
        r.setup_exe = lambda d, v: "cand.exe"
        r._healthy_rig = lambda prev, cand: r.seen.append("rig")
        r._pick_servers = lambda: r.seen.append("servers")
        r._servers = lambda: None
        r.rig = mock.Mock(run="C:\\run")
        with mock.patch.object(wp, "WinSurface"), mock.patch.object(wp.hermetic, "plan", lambda *a, **kw: {"reason": "x"}):
            r.prepare()
        self.assertEqual(r.seen, ["rig", "servers"])


class ResumePointTest(unittest.TestCase):
    def run_(self):
        r = object.__new__(wp.WindowsPlatform)
        r.variant, r.running, r.point_saved, r.session = "tor", None, False, None
        r.work_root, r.name_run = "/w", "tor-26.11.1-to-26.11.2-20261107-010101"
        r.ports, r.log, r.calls = {"node": 40001}, lambda s: None, []
        r.rig = mock.Mock(run="C:\\r", session=5)
        r._call = lambda op, timeout=120, **kw: r.calls.append((op, kw)) or {"ok": True}
        return r

    def test_no_handle_before_the_point(self):
        r = self.run_()
        self.assertIsNone(r.resume_handle())
        self.assertTrue(r.save_point())
        self.assertEqual(r.calls, [("copy_tree", {"from": r.data, "to": "C:\\r\\point"})])
        self.assertEqual(r.resume_handle(), {"session": 5, "run": r.name_run, "ports": {"node": 40001}})

    def test_a_copy_that_failed_keeps_no_point(self):
        r = self.run_()
        r._call = lambda op, timeout=120, **kw: {"ok": False, "error": "the app is running"}
        with self.assertRaises(HarnessFault):
            r.save_point()
        self.assertIsNone(r.resume_handle())

    def test_load_installs_the_previous_release_and_puts_the_data_back(self):
        r = self.run_()
        order = []
        r._install = lambda which, setup: order.append(which)
        r._call = lambda op, timeout=120, **kw: order.append((op, kw["to"])) or {"ok": True}
        r.load_point()
        self.assertEqual(order, ["previous", ("copy_tree", r.data)])

    def test_resume_takes_the_failed_attempts_folder_rig_and_ports(self):
        r = self.run_()
        old = "tor-26.11.1-to-26.11.2-20261107-000000"
        ok, _ = r.resume_from({"session": 1, "run": old, "ports": {"node": 40002}})
        self.assertTrue(ok)
        self.assertEqual((r.name_run, r.session, r.ports), (old, 1, {"node": 40002}))
        self.assertEqual(r.work, os.path.join("/w", old))

    def test_resume_refuses_another_run_or_a_strange_name(self):
        r = self.run_()
        for run in ("notor-26.11.1-to-26.11.2-20261107-000000", "tor-26.11.1-to-26.11.2-20261107-000000\\..\\x", ""):
            self.assertFalse(r.resume_from({"session": 1, "run": run})[0])
        self.assertFalse(r.resume_from({"run": "tor-26.11.1-to-26.11.2-20261107-000000"})[0])


class PreflightTest(unittest.TestCase):
    def run_pf(self, rigs, report, variants=("tor", "notor")):
        lines = []
        with mock.patch.dict(os.environ, {"REL_WIN_RIG": ""}):
            warns = builtins.rig_preflight("box", list(variants), hosts(rigs), lambda m: lines.append(("ok", m)),
                                           lambda m: lines.append(("FAIL", m)), lambda k, m: lines.append((k, m)),
                                           rig=rig, report=report)
        return lines, warns

    def test_all_healthy(self):
        lines, warns = self.run_pf({"tor": 1, "notor": 1}, {1: (RIG1, [])})
        self.assertEqual([k for k, _ in lines], ["ok", "ok"])
        self.assertEqual(warns, [])

    def test_dead_rig_with_fallback_warns_by_name(self):
        lines, warns = self.run_pf({"tor": 1, "notor": 5}, {1: (RIG1, []), 5: (RIG5, rig.judge(RIG5))})
        self.assertFalse(any(k == "FAIL" for k, _ in lines))
        self.assertTrue(any("notor is dead, the run falls back to rig 1" in w and "SeBatchLogonRight" in w for w in warns))

    def test_no_healthy_rig_fails(self):
        lines, _ = self.run_pf({"tor": 5, "notor": 5}, {1: (RIG1, ["x"]), 5: (RIG5, rig.judge(RIG5))}, variants=("tor",))
        self.assertTrue(any(k == "FAIL" and "no healthy Windows rig for tor" in m for k, m in lines))

    def test_unused_dead_rig_is_named(self):
        _, warns = self.run_pf({"tor": 1, "notor": 1}, {1: (RIG1, []), 5: (RIG5, rig.judge(RIG5))})
        self.assertTrue(any("rig 5" in w and "not used by this run" in w for w in warns))


class NightlyTest(unittest.TestCase):
    def test_dead_rig_flagged(self):
        h = hosts({"tor": 1})
        r = nightly.rig_health(hosts_file=h, probe=lambda host: {1: (RIG1, []), 5: (RIG5, rig.judge(RIG5))})
        self.assertEqual(r["status"], "dead")
        self.assertEqual(r["checked"], [1, 5])
        self.assertTrue(r["dead"][0].startswith("rig 5: "))
        self.assertEqual(nightly.rig_step(r)["status"], "fail")

    def test_ok_and_unknown(self):
        h = hosts({"tor": 1})
        self.assertEqual(nightly.rig_health(hosts_file=h, probe=lambda host: {1: (RIG1, [])})["status"], "ok")

        def boom(host):
            raise OSError("no route")
        r = nightly.rig_health(hosts_file=h, probe=boom)
        self.assertEqual(r["status"], "unknown")
        self.assertEqual(nightly.rig_step(r)["status"], "skipped")

    def test_summary_names_dead_rig(self):
        res = {"ended": "2026-11-02T03:00:00Z", "status": "green", "sha": "0" * 40, "tests": {}, "duration_s": 60,
               "steps": [], "rigs": {"status": "dead", "dead": ["rig 5: no batch right"]}}
        self.assertIn("Windows rig dead: rig 5: no batch right", nightly.summary_line(res))


if __name__ == "__main__":
    unittest.main()
