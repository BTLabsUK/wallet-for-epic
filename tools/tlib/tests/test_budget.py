# SPDX-License-Identifier: Apache-2.0
"""tools/t's budgets (tlib/budget.py): python3 -m unittest discover -s tools/tlib/tests"""
import os
import shutil
import tempfile
import unittest

import support  # noqa: F401
from tlib import budget as b

BAD = {"file": "test/bad_test.dart", "wall_s": 45.0, "peak_mb": 900}


class BudgetTest(unittest.TestCase):
    def setUp(self):
        self.d = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.d)

    def test_a_changed_file_over_budget_fails_naming_file_and_limit(self):
        got = b.gate(self.d, [BAD], {"app/test/bad_test.dart"}, {})
        self.assertEqual(got, ["app/test/bad_test.dart: wall 45 s, limit 30 s"])

    def test_a_cached_run_measures_nothing_and_still_fails(self):
        b.gate(self.d, [BAD], set(), {})
        self.assertEqual(len(b.gate(self.d, [], {"app/test/bad_test.dart"}, {})), 1)

    def test_a_cheaper_measure_clears_it(self):
        b.gate(self.d, [BAD], set(), {})
        ok = {**BAD, "wall_s": 3.0}
        self.assertEqual(b.gate(self.d, [ok], {"app/test/bad_test.dart"}, {}), [])

    def test_an_unchanged_file_over_budget_does_not_fail(self):
        self.assertEqual(b.gate(self.d, [BAD], {"app/test/other_test.dart"}, {}), [])

    def test_peak_memory_fails_even_with_a_wall_ceiling(self):
        s = {**BAD, "peak_mb": 2000}
        got = b.gate(self.d, [s], {"app/test/bad_test.dart"}, {"test/bad_test.dart": (60, "keep", "r")})
        self.assertEqual(got, ["app/test/bad_test.dart: peak memory 2000 MB, limit 1500 MB"])

    def test_an_allow_line_needs_its_reason(self):
        os.makedirs(os.path.join(self.d, "tools"))
        with open(os.path.join(self.d, b.ALLOW), "w") as f:
            f.write("test/a_test.dart 60 keep\n")
        with self.assertRaises(ValueError):
            b.read_allow(self.d)

    def test_slow_files_leave_the_selection_unless_changed_themselves(self):
        allow = {"test/s_test.dart": (90, "slow", "r"), "test/k_test.dart": (90, "keep", "r")}
        tests = ["app/test/s_test.dart", "app/test/k_test.dart"]
        self.assertEqual(b.drop_slow(tests, set(), allow), (["app/test/k_test.dart"], ["app/test/s_test.dart"]))
        self.assertEqual(b.drop_slow(tests, {"app/test/s_test.dart"}, allow), (tests, []))

    def test_the_run_limit_fires_once_naming_the_largest_file(self):
        msgs = []
        s = b.Sampler("/app", msgs.append, rss_limit_mb=100, proc=self.d)
        s._read = lambda: {1: ("test/a_test.dart", 80, 80), 2: ("test/b_test.dart", 60, 60)}
        s.tick()
        s.tick()
        self.assertEqual(len(msgs), 1)
        self.assertIn("test/a_test.dart", msgs[0])
        self.assertIn("limit of 100 MB", msgs[0])

    def test_a_file_is_measured_when_its_tester_ends(self):
        s = b.Sampler("/app", print, proc=self.d)
        s._read = lambda: {1: ("test/a_test.dart", 80, 70)}
        s.tick()
        s._read = lambda: {}
        s.tick()
        self.assertEqual(s.seen[0]["file"], "test/a_test.dart")
        self.assertEqual(s.seen[0]["peak_mb"], 80)


if __name__ == "__main__":
    unittest.main()
