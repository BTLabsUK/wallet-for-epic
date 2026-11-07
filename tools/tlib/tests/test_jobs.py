"""tools/t's default flutter test concurrency."""
import os
import unittest
from unittest import mock

import support
from test_variants import load_t


class JobsTest(unittest.TestCase):
    def jobs(self, env, n=100, wanted=None, cpus=16):
        t = load_t()
        with mock.patch.dict(os.environ, env, clear=True), mock.patch("os.cpu_count", return_value=cpus):
            return t.jobs(n, wanted)

    def test_default_capped_at_the_budget(self):
        self.assertEqual(self.jobs({}), 10)
        self.assertEqual(self.jobs({}, cpus=4), 3)

    def test_flutter_test_jobs(self):
        self.assertEqual(self.jobs({"FLUTTER_TEST_JOBS": "6"}), 6)
        self.assertEqual(self.jobs({"FLUTTER_TEST_JOBS": "0"}), 10)

    def test_explicit_wins(self):
        self.assertEqual(self.jobs({"FLUTTER_TEST_JOBS": "6"}, wanted=2), 2)


if __name__ == "__main__":
    unittest.main()
