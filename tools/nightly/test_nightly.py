# SPDX-License-Identifier: Apache-2.0
# Unit tests for nightly.py: the check.sh output parser and the skip/retry decisions.
#   python3 -m unittest tools/nightly/test_nightly.py
import datetime as dt
import sys
import tempfile
import unittest
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

    def test_green_note_weekly(self):
        now = dt.datetime(2026, 10, 30, 3, tzinfo=dt.timezone.utc)
        self.assertTrue(nightly.green_note_due({}, now))
        self.assertFalse(nightly.green_note_due({"last_green_note": "2026-10-25T03:00:00Z"}, now))
        self.assertTrue(nightly.green_note_due({"last_green_note": "2026-10-23T03:00:00Z"}, now))

    def test_step_ids(self):
        taken = set()
        ids = [nightly.step_id(n, taken) for n in
               ["flutter test (all)", "version (https://docs.btlabs.uk/developers/releases/)", "flutter test (all)"]]
        self.assertEqual(ids, ["flutter-test-all", "version-docs-VERSIONING.md",
                               "flutter-test-all-2"])
        for i in ids:
            self.assertRegex(i, nightly.STEP_ID_RE)


if __name__ == "__main__":
    unittest.main()
