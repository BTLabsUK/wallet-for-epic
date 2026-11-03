# SPDX-License-Identifier: Apache-2.0
"""The run history of tools/t and `tools/t flaky` (tlib/history.py).
    python3 -m unittest discover -s tools/tlib/tests"""
import json
import os
import tempfile
import unittest

import support  # noqa: F401  (puts tools/ on sys.path)
from tlib import history


def rec(file, key, result, ts="2026-11-03T01:00:00+0000", failing=(), mode="full", **kw):
    r = history.record(0, "/w", "abc", mode, key, file, result, 1.5, failing, **kw)
    r["ts"] = ts
    return r


class AppendTest(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.mkdtemp()
        self.path = os.path.join(self.dir, "sub", "hist.jsonl")

    def tearDown(self):
        import shutil
        shutil.rmtree(self.dir, ignore_errors=True)

    def test_one_line_per_record_and_all_fields(self):
        history.append([rec("test/a_test.dart", "k1", "fail", failing=["x breaks"], reason="r"),
                        rec("test/b_test.dart", "k2", "pass")], self.path)
        with open(self.path, encoding="utf-8") as f:
            lines = f.read().splitlines()
        self.assertEqual(len(lines), 2)
        first = json.loads(lines[0])
        for k in ("ts", "worktree", "sha", "mode", "key", "file", "result", "duration_s", "failing",
                  "attempt"):
            self.assertIn(k, first)
        self.assertEqual(first["failing"], ["x breaks"])
        self.assertEqual([r["file"] for r in history.read(self.path)], ["test/a_test.dart", "test/b_test.dart"])

    def test_rotation_keeps_the_last_lines(self):
        old = (history.KEEP_LINES, history.SLACK_LINES, history.MIN_LINE_BYTES)
        history.KEEP_LINES, history.SLACK_LINES, history.MIN_LINE_BYTES = 10, 5, 1
        try:
            for i in range(20):
                history.append([rec(f"test/f{i}_test.dart", "k", "pass")], self.path)
            files = [r["file"] for r in history.read(self.path)]
        finally:
            history.KEEP_LINES, history.SLACK_LINES, history.MIN_LINE_BYTES = old
        self.assertLessEqual(len(files), 15)
        self.assertEqual(files[-1], "test/f19_test.dart")
        self.assertGreaterEqual(len(files), 10)

    def test_a_bad_line_and_an_unwritable_path_do_not_raise(self):
        os.makedirs(os.path.dirname(self.path))
        with open(self.path, "w") as f:
            f.write("not json\n[1]\n")
        history.append([rec("test/a_test.dart", "k", "pass")], self.path)
        self.assertEqual(len(history.read(self.path)), 1)
        history.append([rec("test/a_test.dart", "k", "pass")], "/proc/nope/hist.jsonl")


class FlakyTest(unittest.TestCase):
    def test_same_key_with_both_results_is_a_flake(self):
        rs = [rec("test/a_test.dart", "k1", "pass", ts="2026-11-01T01:00:00"),
              rec("test/a_test.dart", "k1", "fail", ts="2026-11-02T01:00:00", failing=["t one"]),
              rec("test/a_test.dart", "k1", "pass"),
              rec("test/b_test.dart", "k2", "fail", failing=["t two"]),  # fails always: not a flake
              rec("test/c_test.dart", "k3", "pass"),
              rec("test/c_test.dart", "k4", "fail", failing=["t three"])]  # inputs changed: not a flake
        out = history.flaky(rs)
        self.assertEqual([(e["file"], e["test"]) for e in out],
                         [("test/a_test.dart", None), ("test/a_test.dart", "t one")])
        self.assertEqual((out[0]["fails"], out[0]["passes"]), (1, 2))
        self.assertEqual(out[1]["last_fail"], "2026-11-02T01:00:00")

    def test_infra_results_are_not_test_results(self):
        rs = [rec("test/a_test.dart", "k1", "infra", reason="flutter_tester died"),
              rec("test/a_test.dart", "k1", "pass")]
        self.assertEqual(history.flaky(rs), [])

    def test_a_retry_that_passed_makes_the_infra_failure_visible_not_a_flake(self):
        rs = [rec("test/a_test.dart", "k1", "infra", attempt=1), rec("test/a_test.dart", "k1", "pass", attempt=2)]
        self.assertEqual(history.flaky(rs), [])
        idx = history.flaky_index([rec("test/a_test.dart", "k", "fail", failing=["t"]),
                                   rec("test/a_test.dart", "k", "pass")])
        self.assertIn(("test/a_test.dart", "t"), idx)


if __name__ == "__main__":
    unittest.main()
