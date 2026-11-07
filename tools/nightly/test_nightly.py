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
import alarm  # noqa: E402
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

    def test_step_end_lines_are_timings_not_steps(self):
        log = """\
02:31:05 == bot
02:31:09 == bot: ok 4s
02:31:09
02:31:09 == flutter test (all)
02:41:10 == flutter test (all): FAILED (exit 1) after 601s
"""
        r = nightly.parse_check_log(log.splitlines())
        self.assertEqual([(s["name"], s["status"], s["duration_s"]) for s in r["steps"]],
                         [("bot", "ok", 4), ("flutter test (all)", "failed", 601)])
        self.assertEqual(r["failing_step"], "flutter test (all)")

    def test_a_failed_cheap_check_lets_the_later_steps_run_and_stays_red(self):
        log = """\
02:31:05 == doc names (tools/doc-names.allow)
02:31:05 == doc names: FAILED (exit 1) after 0s
02:31:05
02:31:05 == LEPIC at the pin (tools/lepic.rev)
02:31:40 == LEPIC at the pin: ok 35s
02:31:40
02:31:40 == flutter analyze
02:32:10 == flutter analyze: ok 30s
02:32:10
02:32:10 check FAILED (full): doc names
"""
        r = nightly.parse_check_log(log.splitlines(), expected_steps=["flutter test (all)"])
        self.assertFalse(r["passed"])
        self.assertEqual(r["failing_step"], "doc names (tools/doc-names.allow)")
        self.assertEqual([(s["name"], s["status"]) for s in r["steps"]],
                         [("doc names (tools/doc-names.allow)", "failed"),
                          ("LEPIC at the pin (tools/lepic.rev)", "ok"), ("flutter analyze", "ok"),
                          ("flutter test (all)", "not_run")])

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


def hist(file, key, result, failing=()):
    return {"file": file, "key": key, "result": result, "failing": list(failing),
            "ts": "2026-11-02T01:00:00+0000", "epoch": 1}


class FlakyMarkTest(unittest.TestCase):
    RECORDS = [hist("test/a_test.dart", "k", "pass"), hist("test/a_test.dart", "k", "fail", ["wobbly"]),
               hist("test/b_test.dart", "k", "fail", ["solid"])]
    FAILING = [{"file": "app/test/a_test.dart", "name": "wobbly"},
               {"file": "app/test/a_test.dart", "name": "other test in a flaky file"},
               {"file": "app/test/b_test.dart", "name": "solid"}]

    def test_a_test_with_a_flake_record_is_marked_and_the_rest_are_kept(self):
        out = nightly.mark_flaky(self.FAILING, self.RECORDS)
        self.assertEqual(len(out), 3)
        self.assertEqual(out[0]["flaky"], {"fails": 1, "passes": 1, "last_fail": "2026-11-02", "scope": "test"})
        self.assertEqual(out[1]["flaky"]["scope"], "file")
        self.assertNotIn("flaky", out[2])  # fails every time: a real failure, not a flake

    def test_the_red_message_calls_out_a_flaky_test_and_keeps_its_cap(self):
        failing = nightly.mark_flaky(self.FAILING, self.RECORDS)
        failing[0]["name"] = "wobbly " + "x" * 300
        body = nightly.dm_body({**RED, "failing_tests": failing})
        self.assertIn("[flaky: 1 fails, 1 passes, last 2026-11-02]", body["tests"][0])
        self.assertIn("[flaky in its file:", body["tests"][1])
        self.assertNotIn("flaky", body["tests"][2])
        self.assertTrue(all(len(t) <= 160 for t in body["tests"]))

    def test_without_history_the_failing_tests_are_unchanged(self):
        self.assertEqual(nightly.mark_flaky(self.FAILING, []), self.FAILING)


class DecisionTest(unittest.TestCase):
    def test_first_run(self):
        self.assertEqual(nightly.decide({}, "a" * 40), ("run", None))

    def test_unchanged_after_green_or_red(self):
        for status in ("green", "red"):
            st = {"last_completed": {"sha": "s1", "status": status}}
            self.assertEqual(nightly.decide(st, "s1"), ("skip", "unchanged"))
            self.assertEqual(nightly.decide(st, "s2"), ("run", None))

    def test_green_record_skips(self):
        with tempfile.TemporaryDirectory() as d:
            Path(d, "s1.json").write_text(json.dumps({"sha": "s1", "status": "green", "clean": True,
                                                      "by": "release"}))
            Path(d, "s2.json").write_text(json.dumps({"sha": "s2", "status": "green", "clean": False}))
            self.assertEqual(nightly.decide({}, "s1", d)[0], "skip")
            self.assertEqual(nightly.decide({}, "s2", d), ("run", None))
            self.assertEqual(nightly.decide({}, "s3", d), ("run", None))

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


def make_release(root, version, platforms=("linux", "android", "windows")):
    """A release folder; 26.10.24 and older by the names before bt-wallet, as they shipped."""
    run = Path(root) / version / "run-1"
    (run / "files").mkdir(parents=True)
    (run / "extra" / "emulator").mkdir(parents=True)
    old = nightly.version_key(version) <= nightly.version_key("26.10.24")
    if "linux" in platforms:
        name = f"EpicCashDesktop-{version}-x86_64.AppImage" if old else f"bt-wallet-{version}-linux-x86_64.AppImage"
        (run / "files" / name).write_text("x")
    if "windows" in platforms:
        name = f"epic-cash-desktop-{version}-windows-x64-setup.exe" if old else f"bt-wallet-{version}-windows-x64-setup.exe"
        (run / "files" / name).write_text("x")
    if "android" in platforms:
        name = f"epic-cash-mobile-{version}-x86_64.apk" if old else f"bt-wallet-{version}-android-x86_64.apk"
        (run / "extra" / "emulator" / name).write_text("x")
    return {"version": version, "run_id": "run-1", "run": str(run), "kind": "release"}


class TrustTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.prev = make_release(self.root / "rel", "26.10.24")
        self.cand = make_release(self.root / "rel", "26.10.25")
        self.drivers = self.root / "wt" / "tools" / "rellib" / "drivers"
        self.drivers.mkdir(parents=True)
        for p in nightly.TRUST_PLATFORMS:
            (self.drivers / f"trust-{p}.sh").write_text("#!/bin/sh\n")

    def tearDown(self):
        self.tmp.cleanup()

    def publish(self, *pubs):
        (self.root / "rel" / "published.json").write_text(json.dumps(list(pubs)))

    def runner(self, rc, checks=None, seen=None):
        def run(argv, env, log, timeout):
            if seen is not None:
                seen.append(env)
            if checks is not None:
                Path(env["REL_OUT"], "proof.json").write_text(json.dumps({"checks": checks}))
            return rc
        return run

    def trust(self, runner, notor=False, **kw):
        """The steps; the no-Tor leg is left out unless asked (the fixture releases have no -notor build)."""
        steps = nightly.run_trust(self.root / "run", {}, worktree=self.root / "wt",
                                  rel_root=self.root / "rel", runner=runner,
                                  busy=lambda: [], **kw)
        return steps if notor else [s for s in steps if s["platform"] != "linux-notor"]

    def test_the_no_tor_leg_follows_linux_and_sends_no_funds(self):
        for rel in (self.prev, self.cand):
            v = rel["version"]
            (Path(rel["run"]) / "files" / f"bt-wallet-{v}-notor-linux-x86_64.AppImage").write_text("x")
        self.publish(self.prev, self.cand)
        seen = []
        steps = self.trust(self.runner(0, {"a": True}, seen), notor=True)
        self.assertEqual([s["platform"] for s in steps], ["linux", "linux-notor", "android", "windows"])
        self.assertEqual([s["status"] for s in steps], ["ok"] * 4)
        legs = [(e["REL_VARIANT"], e["REL_FUNDS"]) for e in seen if e["REL_VARIANT"] != "tor" or e["REL_FUNDS"] == "1"]
        self.assertIn(("notor", "0"), legs)
        self.assertIn(("tor", "1"), legs)

    def test_the_no_tor_leg_is_skipped_when_a_release_has_no_notor_build(self):
        self.publish(self.prev, self.cand)
        steps = self.trust(self.runner(0, {"a": True}), notor=True)
        notor = next(s for s in steps if s["platform"] == "linux-notor")
        self.assertEqual(notor["status"], "skipped")

    def test_pair_is_the_last_two_published(self):
        old = make_release(self.root / "rel", "26.10.23")
        rebuilt = dict(self.cand, run="/elsewhere", run_id="run-2")
        self.publish(old, self.prev, self.cand, rebuilt)
        prev, cand = nightly.published_pair(self.root / "rel")
        self.assertEqual((prev["version"], cand["version"], cand["files"]),
                         ("26.10.24", "26.10.25", "/elsewhere/files"))
        self.publish(self.cand)
        prev, why = nightly.published_pair(self.root / "rel")
        self.assertIsNone(prev)
        self.assertIn("fewer than two", why)

    def test_hand_releases_fill_in_and_the_runner_wins(self):
        flat = self.root / "hand" / "26.10.24-r2"
        (flat / "emulator").mkdir(parents=True)
        (flat / "EpicCashDesktop-26.10.24-x86_64.AppImage").write_text("x")
        (flat / "emulator" / "epic-cash-mobile-26.10.24-x86_64.apk").write_text("x")
        hand = [{"version": "26.10.24", "dir": str(flat), "tag": "v26.10.24"},
                {"version": "26.10.25", "dir": "/hand/25", "tag": "v26.10.25"}]
        (self.root / "rel" / "published-by-hand.json").write_text(json.dumps(hand))
        self.publish(self.cand)  # the runner's 26.10.25 replaces the hand entry
        prev, cand = nightly.published_pair(self.root / "rel")
        self.assertEqual((prev["files"], cand["files"]),
                         (str(flat), str(Path(self.cand["run"]) / "files")))
        env, why = nightly.trust_inputs("android", prev, cand)
        self.assertEqual(env["REL_PREVIOUS_DIR"], str(flat))  # the flat folder: emulator/ inside
        self.assertTrue(env["REL_CANDIDATE_EXTRA"].endswith("26.10.25/run-1/extra"))
        env, why = nightly.trust_inputs("windows", prev, cand)
        self.assertIsNone(env)
        self.assertIn("binary missing", why)

    def test_no_published_json_skips_every_platform(self):
        steps = self.trust(self.runner(0))
        self.assertEqual([s["status"] for s in steps], ["skipped"] * 3)
        self.assertEqual(nightly.trust_summary(steps)["status"], "skipped")

    def test_green_pass_env_and_step_shape(self):
        self.publish(self.prev, self.cand)
        seen = []
        ok = {"wallet_opens": True, "send_ok": True}
        steps = self.trust(self.runner(0, ok, seen))
        self.assertEqual([s["status"] for s in steps], ["ok"] * 3)
        s = steps[0]
        self.assertEqual(s["name"], "G4 trust linux (26.10.24 \u2192 26.10.25)")
        self.assertEqual(set(s) - {"log"}, {"name", "group", "platform", "status", "duration_s", "proof"})
        self.assertTrue(s["proof"].endswith("trust-linux/proof.json"))
        env = [e for e in seen if e["REL_OUT"].endswith("trust-android")][0]
        self.assertEqual((env["REL_VARIANT"], env["REL_FUNDS"], env["REL_NODE"], env["REL_EPICBOX"]),
                         ("tor", "1", "https://node.btlabs.uk", "epicbox.stackwallet.com"))
        self.assertTrue(env["REL_PREVIOUS_DIR"].endswith("26.10.24/run-1/extra"))
        self.assertTrue(env["REL_CANDIDATE_DIR"].endswith("26.10.25/run-1/files"))
        self.assertTrue(env["REL_CANDIDATE_EXTRA"].endswith("26.10.25/run-1/extra"))
        self.assertEqual(nightly.trust_summary(steps)["status"], "green")

    def test_missing_binaries_skip_and_driver_exit_2_skips(self):
        self.publish(self.prev, self.cand)
        (Path(self.cand["run"]) / "files" / "bt-wallet-26.10.25-windows-x64-setup.exe").unlink()
        steps = self.trust(self.runner(2))
        by = {s["platform"]: s for s in steps}
        self.assertEqual(by["windows"]["status"], "skipped")
        self.assertIn("binary missing", by["windows"]["reason"])
        self.assertEqual(by["linux"]["status"], "skipped")
        self.assertIn("could not run", by["linux"]["reason"])
        self.assertEqual(nightly.trust_summary(steps)["status"], "skipped")

    def test_failed_checks_are_named_and_make_the_dm(self):
        self.publish(self.prev, self.cand)
        bad = {"wallet_opens": True, "balance_kept": False, "send_ok": False}
        steps = self.trust(self.runner(1, bad))
        self.assertEqual([s["status"] for s in steps], ["fail"] * 3)
        self.assertEqual(steps[0]["failing_checks"], ["balance_kept", "send_ok"])
        summary = nightly.trust_summary(steps)
        self.assertEqual(summary["status"], "red")
        self.assertEqual(summary["failed"][0], "linux: balance_kept, send_ok")
        result = {"status": "green", "sha": RED["sha"], "duration_s": 60, "trust": summary,
                  "steps": steps, "commits_since_green": ["abc subject"]}
        self.assertTrue(nightly.trust_red(result))
        body = nightly.dm_body(result)
        self.assertEqual(body["kind"], "red")
        self.assertEqual(body["key"], "nightly-7b2cc6ce-trust")
        self.assertEqual(body["step"], steps[0]["name"])
        self.assertEqual(body["tests"][0], "linux: balance_kept, send_ok")
        self.assertNotIn("commits", body)
        self.assertLessEqual(set(body), nightly.DM_FIELDS)
        line = nightly.summary_line(dict(result, ended="2026-10-31T03:00:00Z"))
        self.assertIn("G4 trust red: linux: balance_kept, send_ok", line)

    def test_timeout_and_no_proof_fail(self):
        self.publish(self.prev, self.cand)
        steps = self.trust(self.runner(None), )
        self.assertTrue(all(s["status"] == "fail" and "timed out" in s["reason"] for s in steps))
        steps = self.trust(self.runner(0))  # exit 0 without a proof.json is not proof
        self.assertEqual({s["status"] for s in steps}, {"fail"})

    def test_switches_and_busy(self):
        self.publish(self.prev, self.cand)
        import os
        old = dict(os.environ)
        try:
            os.environ["NIGHTLY_TRUST"] = "0"
            self.assertEqual(self.trust(self.runner(0)), [])
            os.environ["NIGHTLY_TRUST"] = "1"
            os.environ["NIGHTLY_TRUST_PLATFORMS"] = "linux,android"
            self.assertEqual([s["platform"] for s in self.trust(self.runner(0, {"a": True}))],
                             ["linux", "android"])
        finally:
            os.environ.clear()
            os.environ.update(old)
        steps = nightly.run_trust(self.root / "run", {}, worktree=self.root / "wt",
                                  rel_root=self.root / "rel", runner=self.runner(0),
                                  busy=lambda: ["lock"])
        self.assertEqual({s["reason"] for s in steps}, {"a release run is active"})

    def test_green_source_with_trust_green_sends_nothing(self):
        result = {"status": "green", "sha": RED["sha"], "trust": {"status": "green", "failed": []}}
        self.assertFalse(nightly.trust_red(result))
        self.assertEqual(nightly.report(result, {})["why"], "green sends nothing")


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


class LauncherTest(unittest.TestCase):
    """launch.py runs main's own nightly.py from a fresh worktree at main's sha, with --sha; the
    installed copy only when that commit's cannot run."""

    def setUp(self):
        import subprocess
        import launch
        self.launch, self.sp = launch, subprocess
        self.tmp = Path(tempfile.mkdtemp(prefix="nightly-launch-"))
        self.repo = self.tmp / "repo"
        (self.repo / "tools" / "nightly").mkdir(parents=True)
        self.git("init", "-q", "-b", "main")

    def tearDown(self):
        import shutil
        self.sp.run(["git", "-C", str(self.repo), "worktree", "prune"], capture_output=True)
        shutil.rmtree(self.tmp, ignore_errors=True)

    def git(self, *a):
        return self.sp.run(["git", "-C", str(self.repo), "-c", "user.email=t@t", "-c", "user.name=t", *a],
                           check=True, capture_output=True, text=True).stdout.strip()

    def commit(self, text):
        (self.repo / "tools" / "nightly" / "nightly.py").write_text(text)
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "x")
        return self.git("rev-parse", "HEAD")

    def choose(self, *argv):
        return self.launch.choose(list(argv), repo=self.repo, code=self.tmp / "code",
                                  fallback=self.tmp / "installed.py", base=self.tmp / "base")

    def test_main_code_at_the_sha(self):
        sha = self.commit("# knows --sha\nprint('main')\n")
        cmd, runner, note = self.choose("--by-hand")
        self.assertEqual(cmd[1:], [str(self.tmp / "code" / "tools" / "nightly" / "nightly.py"), "--by-hand", "--sha", sha])
        self.assertEqual((runner, note), (f"worktree:{sha}", None))
        (self.tmp / "code" / "stray").write_text("x")
        sha2 = self.commit("# knows --sha\nprint('newer')\n")
        cmd, runner, _ = self.choose()
        self.assertEqual(runner, f"worktree:{sha2}")
        self.assertFalse((self.tmp / "code" / "stray").exists(), "the code worktree is fresh")
        self.assertIn("newer", Path(cmd[1]).read_text())

    def test_an_older_commit_without_sha_runs_without_it(self):
        self.commit("print('old')\n")
        cmd, runner, _ = self.choose()
        self.assertNotIn("--sha", cmd)
        self.assertTrue(runner.startswith("worktree:"))

    def test_a_broken_nightly_falls_back_to_the_installed_copy(self):
        self.commit("def broken(:\n")
        cmd, runner, note = self.choose("--by-hand")
        self.assertEqual(cmd[1:], [str(self.tmp / "installed.py"), "--by-hand"])
        self.assertTrue(runner.startswith("installed:"))
        self.assertIn("fallback", note)

    def test_runner_is_recorded(self):
        self.assertEqual(nightly.runner_info({"WFE_NIGHTLY_RUNNER": "worktree:abc"}),
                         {"kind": "worktree", "detail": "abc"})
        self.assertEqual(nightly.runner_info({})["kind"], "direct")


class CatchupTest(unittest.TestCase):
    def test_stale_after_24h_or_never(self):
        now = nightly.parse_iso("2026-11-04T10:00:00Z")
        self.assertEqual(nightly.stale_hours({"last_completed": {"ended": "2026-11-03T12:00:00Z"}}, now), (False, 22))
        self.assertEqual(nightly.stale_hours({"last_completed": {"ended": "2026-11-02T03:40:00Z"}}, now), (True, 54))

    def test_catchup_skips_only_for_a_rel_run(self):
        noon = dt.datetime(2026, 10, 30, 12, 0)
        busy = "slot 1: x since 1: y\n"
        self.assertEqual(nightly.refusal(False, noon, busy, "/nonexistent/*", catchup=False), "daytime")
        self.assertIsNone(nightly.refusal(False, noon, busy, "/nonexistent/*", catchup=True))

    def test_stale_note_goes_into_the_summary(self):
        with tempfile.TemporaryDirectory() as d:
            old = nightly.BASE
            nightly.BASE = Path(d)
            try:
                nightly.stale_note({}, "busy (tools/rel run active: x)", 30)
                text = (Path(d) / "summary.txt").read_text()
                self.assertIn("no nightly finished for 30 h", text)
                self.assertIn("tools/rel run active", text)
                nightly.stale_note({}, "busy (y)", 31)
                self.assertEqual((Path(d) / "summary.txt").read_text().count("no nightly finished"), 1)
                nightly.stale_note({}, "unchanged", 32)
                self.assertIn("busy (y)", (Path(d) / "summary.txt").read_text())
            finally:
                nightly.BASE = old


class DriftTest(unittest.TestCase):
    def _run(self, rc, out, lepic_text="  xtask)\n"):
        with tempfile.TemporaryDirectory() as d:
            wt = Path(d) / "wt"
            (wt / "tools").mkdir(parents=True)
            (wt / "tools" / "lepic.sh").write_text(lepic_text)

            def runner(argv, log, env, cwd, timeout=None, slot_wait=False):
                log.write(out)
                log.flush()
                return rc, []
            return nightly.run_drift(d, {}, worktree=wt, runner=runner)

    def test_clean_drift_and_outage(self):
        self.assertEqual(self._run(0, "upstream-drift: no upstream changes\n")["status"], "clean")
        d = self._run(2, "epic core/src/ser.rs\n  abc123 change\nError: 1 of 40 module(s) have upstream changes to review\n")
        self.assertEqual(d["status"], "drift")
        self.assertEqual(nightly.drift_step(d)["status"], "ok")
        o = self._run(1, "fatal: unable to access\n")
        self.assertEqual(o["status"], "unknown")
        self.assertEqual(nightly.drift_step(o)["status"], "skipped")

    def test_old_commit_without_xtask_is_unknown(self):
        self.assertEqual(self._run(0, "", lepic_text="nothing\n")["status"], "unknown")

    def test_summary_names_the_drift_but_stays_green(self):
        r = {"ended": "2026-11-04T03:00:00Z", "status": "green", "sha": "a" * 40, "tests": {}, "duration_s": 5,
             "steps": [], "drift": {"status": "drift", "lines": ["Error: 3 of 40 module(s) have upstream changes to review"]}}
        line = nightly.summary_line(r)
        self.assertIn("green", line)
        self.assertIn("3 of 40 module(s)", line)


GREEN = {"status": "green", "sha": "9" * 40, "duration_s": 60, "ended": "2026-11-07T03:00:00Z",
         "tests": {}, "trust": None}


class LanesTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.wt = self.root / "wt"
        (self.wt / "tools").mkdir(parents=True)
        self.rel = self.wt / "tools" / "rel"
        self.rel.write_text("#!/bin/sh\n# start --night\n")
        self.lanes = self.root / "lanes"
        self.lanes.mkdir()
        self.run_dir = self.root / "run"
        self.run_dir.mkdir()
        self.sha = "a" * 40

    def tearDown(self):
        self.tmp.cleanup()

    def fake(self, record, rc=0, seen=None):
        def run(argv, env, log, timeout, cwd=None):
            if seen is not None:
                seen.append((argv, timeout, cwd))
            if record is not None:
                (self.lanes / f"{self.sha}.json").write_text(json.dumps(record))
            return rc
        return run

    def go(self, runner, by_hand=False, catchup=False, hour=3, busy=lambda: [], **kw):
        return nightly.run_night_lanes(self.sha, self.run_dir, {}, by_hand, catchup, worktree=self.wt,
                                       runner=runner, busy=busy, lanes_dir=self.lanes,
                                       now_local=dt.datetime(2026, 11, 7, hour, 0), **kw)

    def test_the_command_is_rel_start_night_commit_without_build_slot(self):
        seen = []
        out = self.go(self.fake({"sha": self.sha, "lanes": {"x": {"class": "blocks", "status": "ok"}}}, seen=seen))
        self.assertEqual(out["status"], "ok")
        argv, timeout, cwd = seen[0]
        self.assertEqual(argv, [str(self.rel), "start", "--night", "--commit", self.sha])
        self.assertNotIn("build-slot", argv)
        self.assertEqual((timeout, cwd), (nightly.NIGHT_TIMEOUT_S, str(self.wt)))

    def test_a_failed_blocks_lane_is_red_and_a_warns_lane_is_not(self):
        rec = {"sha": self.sha, "lanes": {"a": {"class": "blocks", "status": "fail", "note": "boom"},
                                          "b": {"class": "warns", "status": "fail"}}}
        out = self.go(self.fake(rec))
        self.assertEqual(out["status"], "red")
        self.assertEqual([b for b, _ in nightly.blocks_failed(out["record"])], ["a"])

    def test_skips_without_night_support_when_busy_or_too_late(self):
        self.rel.write_text("#!/bin/sh\n")
        self.assertIn("no --night", self.go(self.fake(None))["reason"])
        self.rel.write_text("--night")
        self.assertIn("release run", self.go(self.fake(None), busy=lambda: ["x"])["reason"])
        late = self.go(self.fake(None), hour=7)
        self.assertEqual(late["status"], "skipped")
        for kw in ({"by_hand": True}, {"catchup": True}):  # by hand and catch-up start at any hour
            self.assertEqual(self.go(self.fake({"sha": self.sha, "lanes": {}}), hour=9, **kw)["status"], "ok")

    def test_time_limit_and_missing_file_are_unknown_not_red(self):
        self.assertIn("stopped", self.go(self.fake(None, rc=None))["reason"])
        out = self.go(self.fake(None, rc=1))
        self.assertEqual(out["status"], "unknown")
        self.assertIsNone(out["record"])

    def test_a_lanes_file_from_an_earlier_run_is_not_read(self):
        (self.lanes / f"{self.sha}.json").write_text(json.dumps({"sha": self.sha, "lanes": {}}))
        old = Path(self.lanes / f"{self.sha}.json")
        import os
        os.utime(old, (1, 1))
        self.assertEqual(self.go(self.fake(None))["status"], "unknown")

    def test_dm_for_green_source_with_red_lanes(self):
        rec = {"status": "red", "sha": self.sha, "lanes": {"a": {"class": "blocks", "status": "fail", "note": "boom"}}}
        result = dict(GREEN, sha=self.sha, lanes=rec)
        self.assertTrue(nightly.lanes_red(result))
        body = nightly.dm_body(result)
        self.assertEqual(body["key"], f"nightly-{self.sha[:8]}-lanes")
        self.assertEqual(body["step"], "night lanes")
        self.assertEqual(body["tests"], ["lane a: fail boom"])
        self.assertNotIn("commits", body)
        self.assertFalse(nightly.lanes_red(dict(GREEN, lanes={"lanes": {}})))
        self.assertIn("night lanes red: a", nightly.summary_line(dict(result, ended=GREEN["ended"])))

    def test_by_commit_record_keeps_green_and_red(self):
        path = self.root / "by-commit.json"
        nightly.record_by_commit("a" * 40, "green", "2026-11-07T03:00:00Z", path=path)
        nightly.record_by_commit("b" * 40, "red", "2026-11-08T03:00:00Z", path=path)
        data = json.loads(path.read_text())
        self.assertEqual((data["a" * 40]["status"], data["b" * 40]["status"]), ("green", "red"))


class AcceptanceTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "tools").mkdir()
        (self.root / "tools" / "lepic.sh").write_text("case $1 in\n  smoke)\n")

    def tearDown(self):
        self.tmp.cleanup()

    def acc(self, runner=None, busy=lambda: [], taken=lambda: False):
        return nightly.run_acceptance(self.root, {}, worktree=self.root, runner=runner, busy=busy, taken=taken)

    def test_runs_smoke_and_reports_ok_or_fail(self):
        seen = []

        def run(argv, log, env, cwd, timeout=None, slot_wait=False):
            seen.append(argv)
            return 0, []
        self.assertEqual(self.acc(run)["status"], "ok")
        self.assertTrue(seen[0][-2].endswith("lepic.sh") and seen[0][-1] == "smoke")
        out = self.acc(lambda *a, **k: (3, ["bad"]))
        self.assertEqual(out["status"], "fail")
        self.assertEqual(nightly.acceptance_lane(1)["status"], "fail")

    def test_skips_while_rel_is_active_or_the_port_is_taken(self):
        def never(*a, **k):
            raise AssertionError("must not run")
        self.assertIn("release run", self.acc(never, busy=lambda: ["x"])["reason"])
        self.assertIn("43413", self.acc(never, taken=lambda: True)["reason"])


class AlarmTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.base = Path(self.tmp.name)
        self.conf = self.base / "conf"
        self.conf.mkdir()
        (self.conf / "notify_url").write_text("https://bot.invalid:1\n")
        (self.conf / "notify_token").write_text("t0ken\n")
        self.now = dt.datetime(2026, 11, 7, 7, 15, tzinfo=dt.timezone.utc)

    def tearDown(self):
        self.tmp.cleanup()

    def run_alarm(self, answers=(200,)):
        opener = FakeOpener(answers)
        rc = alarm.run(now=self.now, base=self.base, conf_dir=self.conf, opener=opener, sleep=lambda s: None)
        return rc, opener

    def test_a_fresh_result_means_alive_and_records_the_commit(self):
        (self.base / "latest.json").write_text(json.dumps({"sha": "c" * 40, "status": "red", "ended": "2026-11-07T03:00:00Z"}))
        rc, opener = self.run_alarm()
        self.assertEqual(rc, 0)
        self.assertEqual(opener.requests, [])
        self.assertEqual(json.loads((self.base / "by-commit.json").read_text())["c" * 40]["status"], "red")

    def test_an_unchanged_main_skip_counts_as_alive(self):
        (self.base / "attempts.log").write_text("2026-11-07T03:30:00Z timer cccccccc skipped: unchanged\n")
        self.assertEqual(self.run_alarm()[0], 0)

    def test_nothing_in_26_hours_sends_one_message_a_day(self):
        (self.base / "latest.json").write_text(json.dumps({"sha": "c" * 40, "status": "green", "ended": "2026-11-05T03:00:00Z"}))
        (self.base / "attempts.log").write_text("2026-11-06T03:30:00Z timer cccccccc skipped: busy (slot 1)\n")
        rc, opener = self.run_alarm()
        self.assertEqual(rc, 1)
        self.assertEqual(json.loads(opener.requests[0][0].data)["key"], "nightly-alarm-20261107")
        self.assertEqual(json.loads((self.base / "alarm.json").read_text())["sent_keys"], ["nightly-alarm-20261107"])
        rc2, opener2 = self.run_alarm()
        self.assertEqual(rc2, 1)
        self.assertEqual(opener2.requests, [])

    def test_no_files_at_all_alarms(self):
        self.assertEqual(self.run_alarm()[0], 1)


if __name__ == "__main__":
    unittest.main()
