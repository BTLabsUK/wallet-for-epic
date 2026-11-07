# SPDX-License-Identifier: Apache-2.0
"""tools/ui-targets: the tree as it stands is clean; a driver's ARB key is read wherever it asserts
copy; the walk names a target no shot showed; the Linux id mark comes off the name."""
import contextlib
import importlib.machinery
import importlib.util
import io
import json
import os
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path[:0] = [os.path.join(os.path.dirname(HERE), "drivers"), os.path.join(os.path.dirname(HERE), "drivers", "linux")]

from core import targets as tg  # noqa: E402
from core.labels import Labels  # noqa: E402
from atspi import _marked  # noqa: E402

TOOL = os.path.abspath(os.path.join(HERE, "..", "..", "ui-targets"))
loader = importlib.machinery.SourceFileLoader("ui_targets", TOOL)
spec = importlib.util.spec_from_loader("ui_targets", loader)
ut = importlib.util.module_from_spec(spec)
loader.exec_module(ut)


def quiet(fn, *args):
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        rc = fn(*args)
    return rc, out.getvalue()


class UiTargetsTest(unittest.TestCase):
    def test_this_tree_is_clean(self):
        rc, out = quiet(ut.check)
        self.assertEqual(rc, 0, out)

    def test_copy_keys_are_found_in_calls_and_tables(self):
        src = ('A = tg.copy(self.labels, "oneKey")\nB = tg.regex(None, "twoKey")\nC = labels.text("threeKey")\n'
               'NOPE = tg.other("fourKey")\nX_KEYS = ("fiveKey",\n          "sixKey")\nM_KEYS = {"plain": "sevenKey"}\n')
        with tempfile.TemporaryDirectory() as d:
            f = os.path.join(d, "x.py")
            with open(f, "w") as out:
                out.write(src)
            got = {k: no for _, no, k in ut.driver_copy([f])}
        self.assertEqual(got, {"oneKey": 1, "twoKey": 2, "threeKey": 3, "fiveKey": 5, "sixKey": 6, "sevenKey": 7})

    def test_every_key_the_drivers_read_is_in_the_arb(self):
        keys = {k for _, _, k in ut.driver_copy(list(ut.driver_files()))}
        self.assertGreater(len(keys), 20)
        self.assertLessEqual(keys, set(json.loads(ut.read(ut.ARB))))

    def test_a_control_key_gone_from_the_arb_is_named(self):
        real = ut.load
        controls = real()
        controls[0]["keys"] = ["noSuchArbKey"]
        ut.load = lambda: controls
        try:
            rc, out = quiet(ut.check)
        finally:
            ut.load = real
        self.assertEqual(rc, 1)
        self.assertIn("key noSuchArbKey is not in", out)

    def test_walk_names_a_target_no_shot_showed(self):
        with tempfile.TemporaryDirectory() as d:
            os.makedirs(os.path.join(d, "phone"))
            with open(os.path.join(d, "phone", "a.json"), "w") as f:
                json.dump({"ids": []}, f)
            rc, out = quiet(ut.walk, d)
        self.assertEqual(rc, 1)
        self.assertIn("no screen of the tour shows it", out)
        self.assertIn("fix:", out)

    def test_walk_refuses_an_empty_folder(self):
        with tempfile.TemporaryDirectory() as d:
            rc, out = quiet(ut.walk, d)
        self.assertEqual(rc, 1)
        self.assertIn("no shots", out)


class CopyTest(unittest.TestCase):
    def test_copy_is_the_builds_then_this_checkouts(self):
        self.assertEqual(tg.copy(Labels(arb={"netStatusConnected": "Up"}), "netStatusConnected"), "Up")
        self.assertEqual(tg.copy(Labels(arb={}), "netStatusConnected"), Labels().text("netStatusConnected"))
        self.assertEqual(tg.copy(None, "netStatusConnected"), Labels().text("netStatusConnected"))

    def test_regex_matches_a_placeholder(self):
        self.assertRegex("Signed. Response saved to /x/y", tg.regex(None, "deskTfSigned"))


class MarkTest(unittest.TestCase):
    def test_the_mark_gives_the_id_and_leaves_the_name(self):
        self.assertEqual(_marked("⟦g4.send.confirm⟧\nConfirm"), ("g4.send.confirm", "Confirm"))
        self.assertEqual(_marked("Confirm"), (None, "Confirm"))
        self.assertEqual(_marked(None), (None, ""))


if __name__ == "__main__":
    unittest.main()
