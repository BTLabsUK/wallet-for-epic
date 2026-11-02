# SPDX-License-Identifier: Apache-2.0
"""tools/t's reading of flutter's json reporter, and its summary (tlib/report.py).
    python3 -m unittest discover -s tools/tlib/tests"""
import json
import os
import sys
import unittest

import support
from tlib import report

sys.path.insert(0, os.path.join(support.TOOLS, "nightly"))
import nightly  # noqa: E402

APP = "/w/app"
EXCEPTION = ("══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞═════\n"
             "The following TestFailure was thrown running a test:\n"
             "Expected: exactly one matching candidate\n  Actual: _TextWidgetFinder:<Found 0 widgets>\n\n"
             "When the exception was thrown, this was the stack:\n"
             "#4      main.<anonymous closure> (file:///w/app/test/home_test.dart:88:7)\n\n"
             "The test description was:\n  shows the balance\n════════\n")
EVENTS = [
    {"type": "start"},
    {"type": "suite", "suite": {"id": 0, "path": f"{APP}/test/a_test.dart"}},
    {"type": "suite", "suite": {"id": 1, "path": f"{APP}/test/home_test.dart"}},
    {"type": "suite", "suite": {"id": 2, "path": f"{APP}/test/broken_test.dart"}},
    {"type": "testStart", "test": {"id": 10, "suiteID": 0, "name": "loading /w/app/test/a_test.dart"}},
    {"type": "testDone", "testID": 10, "result": "success", "hidden": True},
    {"type": "testStart", "test": {"id": 11, "suiteID": 0, "name": "adds", "line": 5}},
    {"type": "testDone", "testID": 11, "result": "success", "hidden": False},
    {"type": "testStart", "test": {"id": 12, "suiteID": 0, "name": "later", "line": 9}},
    {"type": "testDone", "testID": 12, "result": "success", "skipped": True, "hidden": False},
    {"type": "testStart", "test": {"id": 20, "suiteID": 1, "name": "home shows the balance", "line": 80}},
    {"type": "print", "testID": 20, "messageType": "print", "message": EXCEPTION},
    {"type": "error", "testID": 20, "error": "Test failed. See exception logs above.\nThe test description was: x",
     "stackTrace": ""},
    {"type": "testDone", "testID": 20, "result": "failure", "hidden": False},
    {"type": "testStart", "test": {"id": 21, "suiteID": 1, "name": "home golden", "line": 120}},
    {"type": "error", "testID": 21, "error": 'Golden "goldens/h.png": Pixel test failed, 1% diff.\n'
     "If the new look is intended, redraw it (Linux only): tools/t goldens --update app/test/goldens/h.png",
     "stackTrace": "test/home_test.dart 125:5  main.<fn>"},
    {"type": "testDone", "testID": 21, "result": "error", "hidden": False},
    {"type": "testStart", "test": {"id": 30, "suiteID": 2, "name": "loading /w/app/test/broken_test.dart"}},
    {"type": "error", "testID": 30, "error": "Failed to load: Error: Undefined name 'x'.", "stackTrace": ""},
    {"type": "testDone", "testID": 30, "result": "error", "hidden": True},
    {"type": "done", "success": False},
]


def fed():
    run = report.Run(APP)
    run.feed_line("Resolving dependencies...")
    for e in EVENTS:
        run.feed_line(json.dumps(e))
    return run


class ReportTest(unittest.TestCase):
    def test_counts(self):
        self.assertEqual(fed().counts(), {"passed": 1, "skipped": 1, "failed": 3})

    def test_failures_have_file_line_message_and_fix(self):
        f = {(x["file"], x["name"]): x for x in fed().failures()}
        w = f[("test/home_test.dart", "home shows the balance")]
        self.assertEqual(w["line"], 88)  # the expect, from the printed exception's stack
        self.assertTrue(w["message"].startswith("Expected: exactly one matching candidate"))
        gold = f[("test/home_test.dart", "home golden")]
        self.assertEqual(gold["line"], 125)
        self.assertEqual(gold["fix"], "tools/t goldens --update app/test/goldens/h.png")
        broken = [x for x in f.values() if x["file"] == "test/broken_test.dart"][0]
        self.assertIn("does not compile", broken["name"])
        self.assertIn("Undefined name", broken["message"])

    def test_files_green(self):
        self.assertEqual(fed().files_green(["test/a_test.dart", "test/home_test.dart", "test/never_test.dart"]),
                         ["test/a_test.dart"])

    def test_message_is_cut(self):
        run = report.Run(APP)
        for e in ({"type": "suite", "suite": {"id": 0, "path": f"{APP}/test/a_test.dart"}},
                  {"type": "testStart", "test": {"id": 1, "suiteID": 0, "name": "long"}},
                  {"type": "error", "testID": 1, "error": "\n".join(f"line {i}" for i in range(100))},
                  {"type": "testDone", "testID": 1, "result": "failure"}):
            run.feed(e)
        self.assertEqual(len(run.failures()[0]["message"].splitlines()), report.MESSAGE_LINES)

    def test_summary_is_short_and_failures_first(self):
        fails = [{"file": f"test/t{i}_test.dart", "line": i, "name": f"n{i}", "message": "boom\nmore\nmore",
                  "fix": None} for i in range(30)]
        lines = report.summary("head", "red", {"passed": 5, "skipped": 0, "failed": 30}, fails, 61)
        self.assertLessEqual(len(lines), 25)
        self.assertEqual(lines[1], "01:01 +5 -30: test/t0_test.dart: n0 [E]")
        self.assertEqual(lines[-1], "01:01 +5 -30: Some tests failed.")

    def test_the_nightly_reads_the_summary(self):
        """tools/nightly/nightly.py reads check.sh's log: the counts and every failing test."""
        run = fed()
        lines = ["== flutter test (all)"]
        lines += report.summary("tools/t full: RED", "red", run.counts(), run.failures(), 600, list_all=True)
        parsed = nightly.parse_check_log(lines)
        self.assertEqual(parsed["tests"]["flutter test (all)"], {"passed": 1, "skipped": 1, "failed": 3})
        self.assertIn({"file": "test/home_test.dart", "name": "home golden"}, parsed["failing_tests"])
        self.assertEqual(len(parsed["failing_tests"]), 3)
        green = report.summary("tools/t full: GREEN", "green", {"passed": 7, "skipped": 0, "failed": 0}, [], 5)
        parsed = nightly.parse_check_log(["== flutter test (all)", *green, "check passed (full)"])
        self.assertTrue(parsed["passed"])
        self.assertEqual(parsed["tests"]["flutter test (all)"]["passed"], 7)


if __name__ == "__main__":
    unittest.main()
