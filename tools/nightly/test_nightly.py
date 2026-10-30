# SPDX-License-Identifier: Apache-2.0
# Unit tests for nightly.py: the check.sh output parser, the skip/retry/busy decisions and the DM
# (against a stubbed opener, never the real bot).
#   python3 -m unittest tools/nightly/test_nightly.py
import datetime as dt
import fcntl
import io
import json
import sys
import tempfile
import unittest
import urllib.error
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import nightly  # noqa: E402

GREEN_LOG = """\
02:31:00 nightly timer run of main abc
02:31:05
02:31:05 == version (https://docs.btlabs.uk/developers/releases/)
02:31:06 version 26.10.24 ok
02:31:06
02:31:06 == LEPIC at the pin (tools/lepic.rev)
02:32:10
02:32:10 == flutter test
02:32:20 00:00 +0: loading /home/user/wfe-worktrees/nightly/app/test/a_test.dart
02:44:00 11:40 +6331 ~45: /home/user/wfe-worktrees/nightly/app/test/z_test.dart: last one
02:44:01 11:41 +6331 ~45: All tests passed!
02:44:01
02:44:01 == integration tests on LEPIC (Linux, offline)
02:45:00 00:30 +1: All tests passed!
02:46:00 00:40 +2: All tests passed!
02:46:01
02:46:01 == bot
02:46:30
02:46:30 check passed (full)
"""

RED_LOG = """\
23:59:50 == flutter analyze
23:59:59 No issues found!
00:00:10 == flutter test
00:00:20 00:01 +5: /x/app/test/a_test.dart: group one fine
00:00:21 00:02 +5 -1: /x/app/test/a_test.dart: group two breaks [E]
00:00:21   Expected: true
00:00:22 00:03 +5 -2: loading /x/app/test/b_test.dart [E]
00:00:23 00:04 +6 ~1 -2: /x/app/test/a_test.dart: group two breaks [E]
00:00:40 00:20 +6300 ~45 -2: Some tests failed.
"""


class ParserTest(unittest.TestCase):
    def test_green_run(self):
        r = nightly.parse_check_log(GREEN_LOG.splitlines(), expected_steps=["bot", "web build"])
        self.assertTrue(r["passed"])
        self.assertIsNone(r["failing_step"])
        self.assertEqual([s["status"] for s in r["steps"]], ["ok"] * 5 + ["not_run"])
        self.assertEqual(r["steps"][2]["name"], "flutter test")
        self.assertEqual(r["steps"][2]["duration_s"], 711)  # 02:32:10 → 02:44:01
        self.assertEqual(r["tests"]["flutter test"], {"passed": 6331, "skipped": 45, "failed": 0})
        # two flutter runs in one step: their counts add up
        self.assertEqual(r["tests"]["integration tests on LEPIC (Linux, offline)"],
                         {"passed": 3, "skipped": 0, "failed": 0})
        self.assertEqual(r["failing_tests"], [])

    def test_red_run_across_midnight(self):
        r = nightly.parse_check_log(RED_LOG.splitlines(),
                                    expected_steps=["flutter analyze", "flutter test", "bot"])
        self.assertFalse(r["passed"])
        self.assertEqual(r["failing_step"], "flutter test")
        self.assertEqual([(s["name"], s["status"]) for s in r["steps"]],
                         [("flutter analyze", "ok"), ("flutter test", "failed"),
                          ("bot", "not_run")])
        self.assertEqual(r["steps"][0]["duration_s"], 20)
        self.assertEqual(r["steps"][1]["duration_s"], 30)
        self.assertEqual(r["tests"]["flutter test"], {"passed": 6300, "skipped": 45, "failed": 2})
        # deduplicated, paths from app/
        self.assertEqual(r["failing_tests"], [
            {"file": "app/test/a_test.dart", "name": "group two breaks"},
            {"file": "app/test/b_test.dart", "name": "loading the file"}])

    def test_log_without_time_prefix(self):
        r = nightly.parse_check_log(["== flutter test",
                                     "13:04 +6309 ~45 -22: Some tests failed."])
        self.assertEqual(r["tests"]["flutter test"]["failed"], 22)
        self.assertIsNone(r["steps"][0]["duration_s"])

    def test_no_steps(self):
        r = nightly.parse_check_log(["dbus-run-session: failed", "boom"])
        self.assertEqual(r["steps"], [])
        self.assertIsNone(r["failing_step"])

    def test_expected_steps_of_full_mode(self):
        with tempfile.TemporaryDirectory() as d:
            tmp = Path(d) / "check.sh"
            tmp.write_text('step "flutter analyze"\n  step "flutter test (all)"\n'
                           '  step "flutter test (affected: ${#tests[@]})"\nstep "bot"\n')
            self.assertEqual(nightly.expected_steps_of(tmp),
                             ["flutter analyze", "flutter test (all)", "bot"])


class DecisionTest(unittest.TestCase):
    def test_first_run(self):
        self.assertEqual(nightly.decide({}, "a" * 40), ("run", None))

    def test_unchanged_after_green_or_red(self):
        for status in ("green", "red"):
            st = {"last_completed": {"sha": "s1", "status": status}}
            self.assertEqual(nightly.decide(st, "s1"), ("skip", "unchanged"))
            self.assertEqual(nightly.decide(st, "s2"), ("run", None))

    def test_error_retried_twice(self):
        st = {"last_completed": {"sha": "s1", "status": "error"}, "errors": {"s1": 1}}
        self.assertEqual(nightly.decide(st, "s1")[0], "run")
        st["errors"]["s1"] = 2
        self.assertEqual(nightly.decide(st, "s1")[0], "run")
        st["errors"]["s1"] = 3
        self.assertEqual(nightly.decide(st, "s1")[0], "skip")
        self.assertEqual(nightly.decide(st, "s2")[0], "run")

    def test_busy_slots(self):
        st = "slot 1: free\nslot 2: release-pipeline-build since 12:36:14: bash -c x\n" \
             "tools/check.sh\nslot 3: free\nwaiting 1: foo: cargo test\n"
        self.assertEqual(len(nightly.busy_slots(st)), 1)
        self.assertEqual(nightly.busy_slots("slot 1: free\nslot 2: free\n"), [])

    def test_daytime_refused_for_the_timer_only(self):
        no_rel = str(Path(tempfile.gettempdir()) / "no-such-rel" / "*" / ".lock")
        free = "slot 1: free\nslot 2: free\n"
        noon = dt.datetime(2026, 10, 30, 12, 0)
        self.assertEqual(nightly.refusal(False, noon, free, no_rel), "daytime")
        self.assertEqual(nightly.refusal(False, dt.datetime(2026, 10, 30, 6, 0), free, no_rel),
                         "daytime")
        self.assertIsNone(nightly.refusal(False, dt.datetime(2026, 10, 30, 2, 30), free, no_rel))
        self.assertIsNone(nightly.refusal(True, noon, "slot 1: someone\n", no_rel))

    def test_active_rel_run_is_busy(self):
        with tempfile.TemporaryDirectory() as d:
            lock = Path(d) / "26.10.24" / "run-1" / ".lock"
            lock.parent.mkdir(parents=True)
            lock.write_text("")
            pattern = str(Path(d) / "*" / "run-*" / ".lock")
            night = dt.datetime(2026, 10, 30, 3, 30)
            free = "slot 1: free\n"
            self.assertEqual(nightly.rel_busy(pattern), [])
            self.assertIsNone(nightly.refusal(False, night, free, pattern))
            with open(lock) as held:
                fcntl.flock(held, fcntl.LOCK_EX)
                self.assertEqual(nightly.rel_busy(pattern), [str(lock)])
                for by_hand in (False, True):
                    self.assertTrue(nightly.refusal(by_hand, night, free, pattern)
                                    .startswith("busy (tools/rel run active"))
            self.assertEqual(nightly.rel_busy(pattern), [])

    def test_busy_slot_refused_for_the_timer(self):
        no_rel = str(Path(tempfile.gettempdir()) / "no-such-rel" / "*" / ".lock")
        night = dt.datetime(2026, 10, 30, 3, 30)
        self.assertTrue(nightly.refusal(False, night, "slot 1: x since 1: y\n", no_rel)
                        .startswith("busy (slot 1"))


RED = {
    "status": "red", "sha": "7b2cc6ce7cc5f52c26c1332a45b62b8a2661b0fd", "duration_s": 1500,
    "failing_step": "flutter test (all)",
    "tests": {"flutter test (all)": {"passed": 6300, "skipped": 45, "failed": 2}},
    "failing_tests": [{"file": "app/test/a_test.dart", "name": f"case {i} " + "x" * 200}
                      for i in range(20)],
    "commits_since_green": [f"{i:08x} " + "subject " * 30 for i in range(20)],
    "log": "/tmp/epic-build/nightly/runs/x/check.log",
}


class FakeResponse:
    def __init__(self, status, body=b"{}"):
        self.status, self.body = status, body

    def read(self, n=-1):
        return self.body

    def __enter__(self):
        return self

    def __exit__(self, *a):
        return False


class FakeOpener:
    """Stands in for urllib.request.urlopen: answers from a list, records the requests."""

    def __init__(self, answers):
        self.answers = list(answers)
        self.requests = []

    def __call__(self, req, timeout=None):
        self.requests.append((req, timeout))
        a = self.answers.pop(0)
        if isinstance(a, FakeResponse):
            return a
        if isinstance(a, Exception):
            raise a
        if a >= 400:
            raise urllib.error.HTTPError(req.full_url, a, "err", {}, io.BytesIO(b"{}"))
        return FakeResponse(a)


class DmTest(unittest.TestCase):
    def setUp(self):
        self.conf = tempfile.TemporaryDirectory()
        Path(self.conf.name, "notify_url").write_text("https://bot.invalid:1\n")
        Path(self.conf.name, "notify_token").write_text("t0ken-for-tests\n")

    def tearDown(self):
        self.conf.cleanup()

    def send(self, result, state, answers=(200,), test=False):
        opener = FakeOpener(answers)
        out = nightly.report(result, state, test=test, conf_dir=self.conf.name, opener=opener,
                             sleep=lambda s: None)
        return out, opener

    def test_body_shape_and_caps(self):
        body = nightly.dm_body(RED)
        self.assertLessEqual(set(body), nightly.DM_FIELDS)
        self.assertEqual(body["kind"], "red")
        self.assertEqual(body["sha"], RED["sha"])
        self.assertEqual(body["key"], "nightly-7b2cc6ce-red")
        self.assertEqual(body["step"], "flutter test (all)")
        self.assertEqual(body["counts"], "+6300 ~45 -2")
        self.assertEqual(body["duration"], "25m00s")
        self.assertNotIn("reason", body)
        self.assertNotIn("test", body)
        self.assertEqual(len(body["tests"]), 15)
        self.assertTrue(all(len(t) <= 160 for t in body["tests"]))
        self.assertTrue(body["tests"][0].startswith("app/test/a_test.dart: case 0 "))
        self.assertEqual(len(body["commits"]), 15)
        self.assertTrue(all(len(c) <= 120 for c in body["commits"]))
        broken = nightly.dm_body({"status": "error", "sha": RED["sha"], "error": "git failed"})
        self.assertEqual(broken, {"kind": "broken", "sha": RED["sha"],
                                  "key": "nightly-7b2cc6ce-broken", "reason": "git failed"})
        test = nightly.dm_body(RED, test=True)
        self.assertIs(test["test"], True)
        self.assertEqual(test["step"], "TEST flutter test (all)")

    def test_request(self):
        out, opener = self.send(RED, {})
        self.assertTrue(out["sent"])
        req, timeout = opener.requests[0]
        self.assertEqual(timeout, 20)
        self.assertEqual(req.full_url, "https://bot.invalid:1/nightly/notify")
        self.assertEqual(req.get_method(), "POST")
        self.assertEqual(req.get_header("Authorization"), "Bearer t0ken-for-tests")
        self.assertEqual(json.loads(req.data), nightly.dm_body(RED))
        self.assertNotIn("t0ken", json.dumps(out))

    def test_one_send_per_key(self):
        state = {}
        out, opener = self.send(RED, state)
        self.assertTrue(out["sent"])
        self.assertEqual(state["sent_keys"], ["nightly-7b2cc6ce-red"])
        out, opener = self.send(RED, state)
        self.assertEqual(out["why"], "already sent")
        self.assertEqual(opener.requests, [])
        # a broken run of the same sha is its own key
        out, opener = self.send({"status": "error", "sha": RED["sha"], "error": "x"}, state)
        self.assertTrue(out["sent"])

    def test_green_sends_nothing(self):
        state = {}
        out, opener = self.send(dict(RED, status="green"), state)
        self.assertFalse(out["sent"])
        self.assertEqual(opener.requests, [])
        self.assertEqual(state, {})

    def test_missing_config_sends_nothing(self):
        state = {}
        with tempfile.TemporaryDirectory() as empty:
            opener = FakeOpener([200])
            out = nightly.report(RED, state, conf_dir=empty, opener=opener)
        self.assertEqual((out["sent"], out["why"]), (False, "not configured"))
        self.assertEqual(opener.requests, [])
        self.assertEqual(state.get("sent_keys"), [])

    def test_retries_then_gives_up_or_succeeds(self):
        state = {}
        net = urllib.error.URLError("refused")
        out, opener = self.send(RED, state, answers=[net, 502, 429, 200])
        self.assertTrue(out["sent"])
        self.assertEqual(out["tries"], [None, 502, 429, 200])
        state = {}
        out, opener = self.send(RED, state, answers=[502, 502, 502, 502])
        self.assertFalse(out["sent"])
        self.assertEqual(len(opener.requests), 4)
        self.assertEqual(state["sent_keys"], [])
        out, opener = self.send(RED, {}, answers=[400])
        self.assertEqual((out["sent"], len(opener.requests)), (False, 1))
        out, opener = self.send(RED, {}, answers=[FakeResponse(200, b'{"duplicate": true}')])
        self.assertEqual((out["sent"], out["duplicate"]), (True, True))


if __name__ == "__main__":
    unittest.main()
