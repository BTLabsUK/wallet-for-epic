# SPDX-License-Identifier: Apache-2.0
"""The Linux update-trust driver (drivers/linux/trust.py) finds its way through the candidate's
narrow-window Settings, waits out the last-session toast and flags a first-run server pick, on a
fake AT-SPI tree (no sandbox, no app)."""
import os
import re
import shutil
import sys
import tempfile
import unittest
import unittest.mock

HERE = os.path.dirname(os.path.abspath(__file__))
DRIVERS = os.path.join(os.path.dirname(HERE), "drivers")
sys.path.insert(0, os.path.join(DRIVERS, "linux"))
sys.path.insert(0, DRIVERS)

import importlib.util  # noqa: E402

# Loaded under its own name: every platform's driver is a trust.py, and discover runs them in one process.
_spec = importlib.util.spec_from_file_location("linux_trust", os.path.join(os.path.join(DRIVERS, "linux"), "trust.py"))
trust = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(trust)


class N:
    def __init__(self, name, role="button", states=(), actions=("Tap",)):
        self.name, self.role, self.states, self.actions = name, role, set(states), list(actions)


class FakeUi:
    """Screens as lists of nodes; a click on a name may move to another screen."""

    def __init__(self, screen, moves):
        self.screen, self.moves, self.clicked = screen, moves, []

    def nodes(self):
        return list(self.screen)

    def find(self, pattern, role=None, all_nodes=None):
        # ui.find's matching (ui.py refuses to load outside a sandbox)
        if hasattr(pattern, "search"):
            m = pattern.search
        elif pattern.startswith("re:"):
            m = re.compile(pattern[3:], re.S).search
        else:
            m = lambda name: name == pattern
        return [n for n in (self.nodes() if all_nodes is None else all_nodes)
                if n.name and (not role or n.role == role) and m(n.name)]

    def has(self, pattern, role=None):
        return bool(self.find(pattern, role))

    def click(self, pattern, role=None, nth=0, timeout=20.0):
        found = [n for n in self.find(pattern, role) if n.actions]
        if not found:
            raise LookupError(pattern)
        self.clicked.append(found[0].name)
        self.screen = self.moves.get(found[0].name, self.screen)
        return found[0].name

    def wait(self, pattern, timeout=30.0, gone=False, role=None):
        if gone:
            self.screen = [n for n in self.screen if not self.find(pattern, all_nodes=[n])]
        return []

    def key(self, *names):
        self.clicked += list(names)


class TrustLinuxTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix="trust-linux-test-", dir=os.environ.get("TMPDIR"))
        os.environ["REL_OUT"] = self.tmp
        os.environ["REL_WORK"] = self.tmp
        self.run_ = trust.Run()
        self.run_.log = lambda s: None
        self.run_.shot = lambda name: None
        nap = unittest.mock.patch.object(trust.time, "sleep", lambda s: None)
        nap.start()
        self.addCleanup(nap.stop)
        self.addCleanup(shutil.rmtree, self.tmp, True)

    def test_section_list_or_chips_click_by_name(self):
        page = [N("Settings"), N("Node", states={"selected"}), N("Transactions"), N("About")]
        ui = FakeUi(page, {})
        self.run_.ui = ui
        self.run_.settings_page("About")
        self.assertEqual(ui.clicked, ["Settings", "About"])

    def test_dropdown_opens_then_picks(self):
        closed = [N("Settings"), N("Node")]  # the dropdown names only the section shown
        open_ = closed + [N("Transactions"), N("Appearance"), N("About")]
        ui = FakeUi(closed, {"Node": open_, "About": [N("Settings"), N("About")]})
        self.run_.ui = ui
        self.run_.settings_page("About")
        self.assertEqual(ui.clicked, ["Settings", "Node", "About"])
        # already on the section the dropdown names: nothing more to press
        ui.clicked = []
        self.run_.settings_page("About")
        self.assertEqual(ui.clicked, ["Settings"])

    def test_dropdown_without_the_section(self):
        closed = [N("Settings"), N("Node")]
        ui = FakeUi(closed, {"Node": closed + [N("About")]})
        self.run_.ui = ui
        with self.assertRaises(LookupError):
            self.run_.settings_page("Receiving")
        self.assertIn("Escape", ui.clicked)

    def test_last_session_toast_waited_out_and_noted(self):
        toast = N(trust.LAST_SESSION, role="label", actions=())
        ui = FakeUi([N("Main navigation", role="panel"), toast, N("Send")], {})
        self.run_.ui = ui
        self.run_.last_session_toast()
        self.assertFalse(ui.has("re:^The app closed"))
        self.assertIn("last_session", self.run_.details)
        self.assertEqual(ui.clicked, [])  # never pressed Send

    def test_first_run_line_in_the_log_is_a_finding(self):
        logs = os.path.join(self.run_.sb, "home", ".epic_cash_desktop", "logs")
        os.makedirs(logs)
        with open(os.path.join(logs, "wfe.log"), "w") as f:
            f.write("12:00:00 INFO network: first run: node node.example in use, the first of the list that answers here\n")
        self.assertEqual(len(self.run_.first_run_lines()), 1)
        self.assertIn("ran", self.run_.details["first_run"])

    def test_no_log_no_finding(self):
        self.assertEqual(self.run_.first_run_lines(), [])


if __name__ == "__main__":
    unittest.main()
