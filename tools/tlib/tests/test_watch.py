# SPDX-License-Identifier: Apache-2.0
"""What tools/t checks before and while a run (tlib/watch.py): the clones at their pins, the
files that failed to load, the progress line.
    python3 -m unittest discover -s tools/tlib/tests"""
import os
import shutil
import subprocess
import tempfile
import unittest

import support
from tlib import watch

APP = "/w/app"


def suite(sid, name):
    return {"type": "suite", "suite": {"id": sid, "path": f"{APP}/test/{name}"}}


def start(tid, sid, name):
    return {"type": "testStart", "test": {"id": tid, "name": name, "suiteID": sid}}


def done(tid, result="success", hidden=False):
    return {"type": "testDone", "testID": tid, "result": result, "hidden": hidden}


def err(tid, text):
    return {"type": "error", "testID": tid, "error": text, "stackTrace": "", "isFailure": False}


def load_failed(sid, name, text=None):
    """A file that never loaded, as flutter's json reporter tells it."""
    tid = sid * 100
    text = text or (f'Failed to load "{APP}/test/{name}": Compilation failed for testPath={APP}/test/{name}: '
                    f"test/{name}:3:1: Error: Expected ';' after this.")
    return [suite(sid, name), start(tid, sid, f"loading {APP}/test/{name}"), err(tid, text),
            done(tid, "error")]


def assertion_failed(sid, name):
    """A file that loaded, then one test failed an expect."""
    lt, t = sid * 100, sid * 100 + 1
    return [suite(sid, name), start(lt, sid, f"loading {APP}/test/{name}"), done(lt, hidden=True),
            start(t, sid, "shows the balance"),
            err(t, "Expected: 'a'\n  Actual: 'b'\n\nFailed to load nothing: just a message that says so"),
            done(t, "failure")]


def feed(w, events):
    return [e for e in events if w.feed(e)]


class FailFastTest(unittest.TestCase):
    def test_trips_once_on_the_third_file(self):
        w = watch.Watch(10, 3)
        events = load_failed(1, "a_test.dart") + load_failed(2, "b_test.dart")
        self.assertEqual(feed(w, events), [])
        tripped = feed(w, load_failed(3, "c_test.dart"))
        self.assertEqual([e["type"] for e in tripped], ["error"])
        self.assertTrue(w.tripped)
        self.assertEqual(w.load_failures[0][0], f"{APP}/test/a_test.dart")
        self.assertEqual(feed(w, load_failed(4, "d_test.dart")), [])  # once

    def test_the_compiler_dying_counts(self):
        w = watch.Watch(10, 2)
        text = "Error: The Dart compiler exited unexpectedly."
        self.assertEqual(len(feed(w, load_failed(1, "a_test.dart", text) + load_failed(2, "b_test.dart", text))), 1)

    def test_assertion_failures_never_trip(self):
        w = watch.Watch(10, 1)
        events = [e for i in range(1, 6) for e in assertion_failed(i, f"f{i}_test.dart")]
        self.assertEqual(feed(w, events), [])
        self.assertEqual(w.load_failures, [])
        self.assertEqual(len(w.failed), 5)

    def test_one_file_counts_once(self):
        w = watch.Watch(10, 2)
        events = load_failed(1, "a_test.dart") + [err(100, "Failed to load again")]
        self.assertEqual(feed(w, events), [])
        self.assertEqual(len(w.load_failures), 1)

    def test_zero_never_trips(self):
        w = watch.Watch(10, 0)
        events = [e for i in range(1, 6) for e in load_failed(i, f"f{i}_test.dart")]
        self.assertEqual(feed(w, events), [])
        self.assertEqual(len(w.load_failures), 5)

    def test_threshold_from_the_environment(self):
        self.assertEqual(watch.failfast_threshold({}), 3)
        self.assertEqual(watch.failfast_threshold({"WFE_T_FAILFAST": "0"}), 0)
        self.assertEqual(watch.failfast_threshold({"WFE_T_FAILFAST": " 7 "}), 7)
        with self.assertRaises(ValueError):
            watch.failfast_threshold({"WFE_T_FAILFAST": "many"})


class ProgressTest(unittest.TestCase):
    def test_line(self):
        w = watch.Watch(468, 0)
        feed(w, assertion_failed(1, "a_test.dart") + load_failed(2, "b_test.dart"))
        feed(w, [suite(3, "c_test.dart"), start(300, 3, "loading c"), done(300, hidden=True),
                 start(301, 3, "still running")])
        self.assertEqual(w.line(250), "tools/t: 2/468 files done, 2 failed, 4m10s")

    def test_clock(self):
        self.assertEqual([watch.clock(s) for s in (0, 45, 60, 250, 3725)], ["0s", "45s", "1m00s", "4m10s", "1h02m"])


def git(cwd, *args):
    return subprocess.run(["git", "-C", cwd, *args], check=True, capture_output=True, text=True).stdout.strip()


class StalePinsTest(unittest.TestCase):
    def setUp(self):
        self.root = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.root, True)
        self.heads = {}
        for rev_file, rel in watch.PINS:
            clone = os.path.join(self.root, rel)
            os.makedirs(clone)
            git(clone, "init", "-q")
            shas = []
            for n in (1, 2):
                git(clone, "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "--allow-empty",
                    "-m", f"c{n}")
                shas.append(git(clone, "rev-parse", "HEAD"))
            self.heads[rel] = shas
            support.write(self.root, rev_file, shas[1] + "\n")

    def test_at_the_pins(self):
        self.assertEqual(watch.stale_pins(self.root), [])

    def test_a_clone_behind_its_pin(self):
        clone = os.path.join(self.root, "app/third_party/lepic-flutter")
        old, pin = self.heads["app/third_party/lepic-flutter"]
        git(clone, "checkout", "-q", "--detach", old)
        msgs = watch.stale_pins(self.root)
        self.assertEqual(len(msgs), 1)
        for part in ("app/third_party/lepic-flutter", old[:12], pin[:12], "tools/lepic-flutter.rev",
                     "tools/lepic.sh sync"):
            self.assertIn(part, msgs[0])

    def test_a_missing_clone(self):
        shutil.rmtree(os.path.join(self.root, "app/third_party/lepic"))
        msgs = watch.stale_pins(self.root)
        self.assertEqual(len(msgs), 1)
        self.assertIn("no clone at app/third_party/lepic", msgs[0])

    def test_no_third_party_is_left_to_the_sync(self):
        shutil.rmtree(os.path.join(self.root, "app/third_party"))
        self.assertEqual(watch.stale_pins(self.root), [])


if __name__ == "__main__":
    unittest.main()
