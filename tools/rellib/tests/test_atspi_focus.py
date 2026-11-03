"""AtspiSurface.set_text: a secret field that takes focus late is asked again; never set_text."""
import os
import sys
import unittest
import unittest.mock

HERE = os.path.dirname(os.path.abspath(__file__))
DRIVERS = os.path.join(os.path.dirname(HERE), "drivers")
sys.path.insert(0, os.path.join(DRIVERS, "linux"))
sys.path.insert(0, DRIVERS)

import atspi  # noqa: E402
from core.surface import Node  # noqa: E402


class Fake(atspi.AtspiSurface):
    def __init__(self, focus_after):
        self.calls, self.typed, self.focus_after = [], [], focus_after

    def _req(self, node, op, **kw):
        return {"op": op}

    def _call(self, req, timeout=None):
        self.calls.append(req["op"])
        return {"ok": req["op"] == "set_text" or self.calls.count("focus") > self.focus_after}

    def _focused_is(self, node):
        return False

    def _xdo(self, *a, inp=None):
        if a[0] == "type":
            self.typed.append(inp)


WORD = Node(0, "text_field", "Word 1", value="", states=frozenset({"editable"}))


class FocusTest(unittest.TestCase):
    def test_secret_field_focused_late_is_typed(self):
        s = Fake(focus_after=2)
        with unittest.mock.patch.object(atspi.time, "sleep"):
            s.set_text(WORD, "abandon", secret=True)
        self.assertEqual(s.typed, ["abandon"])
        self.assertNotIn("set_text", s.calls)

    def test_secret_field_never_focused_fails_without_set_text(self):
        s = Fake(focus_after=10 ** 6)
        with unittest.mock.patch.object(atspi, "SECRET_FOCUS_S", 0.01), unittest.mock.patch.object(atspi.time, "sleep"):
            with self.assertRaisesRegex(RuntimeError, "took no focus"):
                s.set_text(WORD, "abandon", secret=True)
        self.assertNotIn("set_text", s.calls)
        self.assertEqual(s.typed, [])

    def test_plain_field_falls_back_at_once(self):
        s = Fake(focus_after=10 ** 6)
        s.set_text(Node(0, "text_field", "Label", value=""), "x")
        self.assertEqual(s.calls, ["focus", "set_text"])


if __name__ == "__main__":
    unittest.main()
