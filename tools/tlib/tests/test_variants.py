# SPDX-License-Identifier: Apache-2.0
"""Test files that need the second, no-Tor pass of `tools/t full` (tlib/variants.py), and the
`tools/t flaky` command.
    python3 -m unittest discover -s tools/tlib/tests"""
import contextlib
import importlib.machinery
import importlib.util
import io
import os
import shutil
import tempfile
import unittest

import support
from tlib import history, variants


def load_t():
    path = os.path.join(support.TOOLS, "t")
    loader = importlib.machinery.SourceFileLoader("wfe_t", path)
    spec = importlib.util.spec_from_loader("wfe_t", loader)
    mod = importlib.util.module_from_spec(spec)
    loader.exec_module(mod)
    return mod


class NotorTestsTest(unittest.TestCase):
    def setUp(self):
        self.root = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.root, True)
        self.files = {
            "app/test/tor_test.dart": "import 'package:x/tor_build.dart';\nvoid main() { torBuilt; }\n",
            "app/test/uses_flag_test.dart": "void main() { if (!torBuilt) {} }\n",
            "app/test/support/signed_update.dart": "import 'package:x/tor_build.dart';\nconst a = torBuilt;\n",
            "app/test/update_test.dart": "import 'support/signed_update.dart';\nvoid main() {}\n",
            "app/test/sub/deep_test.dart": "import '../support/signed_update.dart';\nvoid main() {}\n",
            "app/test/plain_test.dart": "import 'support/other.dart';\nvoid main() {}\n",
            "app/test/support/other.dart": "const b = 1;\n",
            "app/lib/src/tor_build.dart": "const torBuilt = true;\n",
        }
        for rel, text in self.files.items():
            support.write(self.root, rel, text)

    def test_files_that_read_torbuilt_directly_or_through_a_helper_are_found(self):
        self.assertEqual(variants.notor_tests(self.root, list(self.files)),
                         ["app/test/sub/deep_test.dart", "app/test/tor_test.dart",
                          "app/test/update_test.dart", "app/test/uses_flag_test.dart"])

    def test_a_test_that_never_reads_it_is_left_out(self):
        self.assertNotIn("app/test/plain_test.dart", variants.notor_tests(self.root, list(self.files)))

    def test_a_new_test_file_is_found_without_a_list_to_edit(self):
        support.write(self.root, "app/test/new_test.dart", "void main() { torBuilt; }\n")
        found = variants.notor_tests(self.root, [*self.files, "app/test/new_test.dart"])
        self.assertIn("app/test/new_test.dart", found)


class FlakyCommandTest(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.dir, True)
        self.hist = os.path.join(self.dir, "h.jsonl")
        self.old = os.environ.get("WFE_TEST_HISTORY")
        os.environ["WFE_TEST_HISTORY"] = self.hist
        self.addCleanup(self.restore)
        self.t = load_t()

    def restore(self):
        if self.old is None:
            os.environ.pop("WFE_TEST_HISTORY", None)
        else:
            os.environ["WFE_TEST_HISTORY"] = self.old

    def run_flaky(self, days=14):
        class Args:
            pass
        a = Args()
        a.days = days
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            rc = self.t.cmd_flaky(a)
        return rc, out.getvalue()

    def test_an_empty_history_says_so(self):
        rc, out = self.run_flaky()
        self.assertEqual(rc, 0)
        self.assertIn("no flake in 0 file results", out)

    def test_same_inputs_with_both_results_are_listed_and_others_are_not(self):
        import time
        now = time.time()
        recs = [history.record(now, "/w", "s", "full", "k1", "test/a_test.dart", "pass", 1),
                history.record(now, "/w", "s", "full", "k1", "test/a_test.dart", "fail", 1, ["t one"]),
                history.record(now, "/w", "s", "full", "k2", "test/b_test.dart", "fail", 1, ["t"]),
                history.record(now, "/w", "s", "full", "k3", "test/c_test.dart", "infra", 1)]
        history.append(recs, self.hist)
        rc, out = self.run_flaky()
        self.assertEqual(rc, 0)
        self.assertIn("app/test/a_test.dart", out)
        self.assertIn("t one", out)
        self.assertNotIn("b_test", out)
        self.assertNotIn("c_test", out)

    def test_old_results_are_outside_the_window(self):
        import time
        old = time.time() - 40 * 86400
        history.append([history.record(old, "/w", "s", "full", "k", "test/a_test.dart", "pass", 1),
                        history.record(old, "/w", "s", "full", "k", "test/a_test.dart", "fail", 1)], self.hist)
        _, out = self.run_flaky(days=14)
        self.assertIn("no flake", out)
        _, out = self.run_flaky(days=60)
        self.assertIn("app/test/a_test.dart", out)


if __name__ == "__main__":
    unittest.main()
