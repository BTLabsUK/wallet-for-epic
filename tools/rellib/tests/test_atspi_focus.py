"""AtspiSurface.set_text: a secret field that takes focus late is asked again; never set_text.
AtspiSurface.press: a button still disabled at the press is pressed once it is enabled."""
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


class LateButton(atspi.AtspiSurface):
    """A button with no action (disabled) at the first press, enabled from the second tree read."""
    REF = {"path": [0], "role": "push button", "name": "Review"}

    def __init__(self):
        self.calls, self.keys, self.reads = [], [], 0

    def _call(self, req, timeout=None):
        self.calls.append(req["op"])
        return {"ok": self.reads >= 2} if req["op"] == "press" else {"ok": False, "how": "no action"}

    def tree(self):
        self.reads += 1
        st = frozenset({"showing", "enabled"} if self.reads >= 2 else {"showing"})
        return [Node(0, "button", "Review", states=st, ref=self.REF)]

    def key(self, k):
        self.keys.append(k)

    def log(self, line):
        pass


class PressTest(unittest.TestCase):
    def test_a_button_disabled_at_the_press_is_pressed_once_enabled(self):
        s = LateButton()
        with unittest.mock.patch.object(atspi.time, "sleep"):
            s.press(Node(0, "button", "Review", states=frozenset({"showing"}), ref=LateButton.REF))
        self.assertEqual(s.calls, ["press", "press"])
        self.assertEqual(s.keys, [])   # no Tab walk


class ServicesTest(unittest.TestCase):
    def test_a_dead_keyring_daemon_is_a_sandbox_gone(self):
        import subprocess
        import tempfile
        import sandbox
        dead = subprocess.Popen(["true"])
        dead.wait()
        with tempfile.TemporaryDirectory() as sb:
            os.makedirs(os.path.join(sb, "pids"))
            for name, pid in (("xvfb", os.getpid()), ("dbus", os.getpid()), ("keyring", os.getpid())):
                with open(os.path.join(sb, "pids", name), "w") as f:
                    f.write(str(pid))
            self.assertTrue(sandbox.services_alive(sb))
            with open(os.path.join(sb, "pids", "keyring"), "w") as f:
                f.write(str(dead.pid))
            self.assertFalse(sandbox.services_alive(sb))


if __name__ == "__main__":
    unittest.main()
