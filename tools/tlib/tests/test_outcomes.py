# SPDX-License-Identifier: Apache-2.0
"""Which failed test files are infrastructure failures (tlib/report.py file_outcomes), from events
recorded off real `flutter test --reporter json` runs of files that exited, were killed, threw in
main, threw in setUpAll, did not compile and failed an expect (2026-11-03).
    python3 -m unittest discover -s tools/tlib/tests"""
import unittest

import support  # noqa: F401
from tlib import report

APP = "/w/app"


def suite(sid, name, t=0):
    return {"type": "suite", "suite": {"id": sid, "path": f"{APP}/test/{name}"}, "time": t}


def start(tid, sid, name, t=0):
    return {"type": "testStart", "test": {"id": tid, "name": name, "suiteID": sid, "line": 3}, "time": t}


def done(tid, result="success", hidden=False, t=0):
    return {"type": "testDone", "testID": tid, "result": result, "hidden": hidden, "time": t}


def err(tid, text, failure=False):
    return {"type": "error", "testID": tid, "error": text, "stackTrace": "", "isFailure": failure}


def load(sid, tid, name, ok=True, error=None, t=0):
    ev = [suite(sid, name, t), start(tid, sid, f"loading {APP}/test/{name}", t)]
    if error:
        ev.append(err(tid, error))
    ev.append(done(tid, "success" if ok else "error", hidden=ok, t=t + 1000))
    return ev


def outcomes(events, files, rc=1):
    run = report.Run(APP)
    for e in events:
        run.feed(e)
    return run.file_outcomes(files, rc), run


class OutcomeTest(unittest.TestCase):
    def test_a_green_file_passes_with_its_duration(self):
        out, _ = outcomes([*load(0, 1, "a_test.dart", t=1000), start(2, 0, "adds", 1500),
                           done(2, t=3500)], ["test/a_test.dart"], rc=0)
        self.assertEqual(out["test/a_test.dart"]["result"], "pass")
        self.assertEqual(out["test/a_test.dart"]["duration_s"], 2.5)

    def test_a_process_that_exits_or_is_killed_inside_a_test_is_infra(self):
        # exit(3) and SIGKILL in a test: testDone "error" with no error event at all
        ev = [*load(0, 1, "exit_test.dart"), start(2, 0, "ok first"), done(2),
              start(3, 0, "exits"), done(3, "error"), start(4, 0, "never"), done(4, "error")]
        out, run = outcomes(ev, ["test/exit_test.dart"])
        self.assertEqual(out["test/exit_test.dart"]["result"], "infra")
        self.assertEqual(out["test/exit_test.dart"]["failing"], ["exits", "never"])
        self.assertIn("without a result", out["test/exit_test.dart"]["reason"])
        self.assertIn("test process ended", run.failures()[0]["message"])

    def test_a_failed_expect_is_a_failure(self):
        ev = [*load(0, 1, "assert_test.dart"), start(2, 0, "wrong"),
              err(2, "Expected: <2>\n  Actual: <1>\n", failure=True), done(2, "failure")]
        out, _ = outcomes(ev, ["test/assert_test.dart"])
        self.assertEqual(out["test/assert_test.dart"]["result"], "fail")

    def test_code_that_does_not_compile_or_throws_in_main_or_setupall_is_a_failure(self):
        compile_err = ('Failed to load "/w/app/test/c_test.dart":\nCompilation failed for testPath=/w/app/'
                       "test/c_test.dart: test/c_test.dart:2:23: Error: A value of type 'String' can't be "
                       "assigned to a variable of type 'int'.")
        ev = [*load(0, 1, "c_test.dart", ok=False, error=compile_err),
              *load(2, 3, "m_test.dart", ok=False,
                    error='Failed to load "/w/app/test/m_test.dart": Bad state: boom in main'),
              suite(4, "s_test.dart"), start(5, 4, "(setUpAll)"), err(5, "Bad state: setupall boom"),
              done(5, "error")]
        out, _ = outcomes(ev, ["test/c_test.dart", "test/m_test.dart", "test/s_test.dart"])
        self.assertEqual({f: o["result"] for f, o in out.items()},
                         {"test/c_test.dart": "fail", "test/m_test.dart": "fail", "test/s_test.dart": "fail"})
        self.assertEqual(out["test/c_test.dart"]["failing"], ["loading the file"])

    def test_the_compiler_dying_is_infra_but_a_real_failure_in_the_same_file_wins(self):
        crash = "Error: The Dart compiler exited unexpectedly."
        out, _ = outcomes(load(0, 1, "a_test.dart", ok=False, error=crash), ["test/a_test.dart"])
        self.assertEqual(out["test/a_test.dart"]["result"], "infra")
        ev = [*load(0, 1, "a_test.dart", ok=False, error=crash), start(2, 0, "wrong"),
              err(2, "Expected: <2>\n  Actual: <1>\n", failure=True), done(2, "failure")]
        out, _ = outcomes(ev, ["test/a_test.dart"])
        self.assertEqual(out["test/a_test.dart"]["result"], "fail")

    def test_infra_shaped_messages(self):
        for text in ('Failed to load "x": Shell subprocess cleanup', "SocketException: Connection reset by peer",
                     "flutter_tester process exited (signal 9)", "Cannot allocate memory",
                     "Unable to start the test process", "frontend_server crashed",
                     "Could not read /tmp/x.dill: No such file"):
            self.assertEqual(report.classify_error(text), "infra", text)
        for text in ("Expected: true\n  Actual: false", "test/x_test.dart:1:1: Error: Undefined name 'q'.",
                     "Bad state: no element", 'Golden "a.png": Pixel test failed',
                     "SocketException: Failed host lookup\nExpected: a TimeoutException"):
            self.assertEqual(report.classify_error(text), "fail", text)

    def test_files_that_never_finished_in_an_aborted_run_are_infra_not_the_finished_ones(self):
        # flutter itself was killed (rc 137): file a finished, b started and has no result, c never started
        ev = [*load(0, 1, "a_test.dart"), start(2, 0, "ok"), done(2),
              *[e for e in load(3, 4, "b_test.dart")[:2]], start(5, 3, "hangs")]
        out, _ = outcomes(ev, ["test/a_test.dart", "test/b_test.dart", "test/c_test.dart"], rc=137)
        self.assertEqual(out["test/a_test.dart"]["result"], "pass")
        self.assertEqual(out["test/b_test.dart"]["result"], "infra")
        self.assertEqual(out["test/c_test.dart"]["result"], "infra")

    def test_a_retry_replaces_the_first_attempt_in_the_run(self):
        first = [*load(0, 1, "a_test.dart"), start(2, 0, "t"), done(2, "error")]
        run = report.Run(APP)
        for e in first:
            run.feed(e)
        self.assertEqual(run.counts()["failed"], 1)
        run.drop_files(["test/a_test.dart"])
        run.offset = 1_000_000
        for e in [*load(0, 1, "a_test.dart"), start(2, 0, "t"), done(2)]:
            run.feed(e)
        self.assertEqual(run.counts(), {"passed": 1, "skipped": 0, "failed": 0})
        self.assertEqual(run.failures(), [])
        self.assertEqual(run.file_outcomes(["test/a_test.dart"], 0)["test/a_test.dart"]["result"], "pass")


if __name__ == "__main__":
    unittest.main()
