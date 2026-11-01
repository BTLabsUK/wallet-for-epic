# SPDX-License-Identifier: Apache-2.0
"""The Android update-trust driver (drivers/android/trust.py): what it answers over the candidate's
Home and how it judges the servers, on uiautomator dumps written by hand (no emulator)."""
import os
import sys
import tempfile
import unittest
from unittest import mock

HERE = os.path.dirname(os.path.abspath(__file__))
ANDROID = os.path.join(os.path.dirname(HERE), "drivers", "android")
sys.path.insert(0, ANDROID)

import importlib.util  # noqa: E402

# Loaded under its own name: every platform's driver is a trust.py, and discover runs them in one process.
_spec = importlib.util.spec_from_file_location("android_trust", os.path.join(ANDROID, "trust.py"))
trust = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(trust)


def node(label, y, clickable=False, cls="android.view.View"):
    return dict(label=label, cls=cls, clickable=clickable, checked=False,
                bounds=[0, y - 20, 1080, y + 20], center=(540, y))


class AnswerOffersTest(unittest.TestCase):
    def setUp(self):
        self.taps = []
        trust.SEEN.clear()
        out = tempfile.mkdtemp()
        self.addCleanup(lambda: __import__("shutil").rmtree(out))
        for name, fake in (("tap_xy", lambda s, xy: self.taps.append(xy)), ("shot", lambda n: None),
                           ("OUT", out)):
            p = mock.patch.object(trust, name, fake)
            p.start()
            self.addCleanup(p.stop)
        p = mock.patch.object(trust.time, "sleep", lambda s: None)
        p.start()
        self.addCleanup(p.stop)

    def test_last_session_offer_gets_its_own_not_now(self):
        ns = [node("Not now", 300, clickable=True),  # another Not now, far from the notice
              node("Info: " + trust.LAST_SESSION[0], 1900),
              node(trust.LAST_SESSION_NOT_NOW, 1980, clickable=True),
              node("Send", 1980, clickable=True)]
        self.assertTrue(trust.answer_offers(ns))
        self.assertEqual(self.taps, [(540, 1980)])
        self.assertEqual(trust.SEEN["last_session"], trust.LAST_SESSION[0])

    def test_nothing_to_answer_on_home(self):
        ns = [node(trust.facts.LOCK_WALLET, 100, clickable=True), node("Tab 2 of 3", 2200, clickable=True)]
        self.assertFalse(trust.answer_offers(ns))
        self.assertEqual(self.taps, [])
        self.assertEqual(trust.SEEN, {})

    def test_use_pin_only_on_the_system_prompt(self):
        pin_screen = [node(trust.USE_PIN, 1500, clickable=True), node("", 900, cls="android.widget.EditText")]
        self.assertFalse(trust.answer_offers(pin_screen))
        prompt = [node(trust.USE_PIN, 1500, clickable=True), node("Unlock wallet", 1200)]
        self.assertTrue(trust.answer_offers(prompt))
        self.assertEqual(trust.SEEN["biometric_prompt"], 1)


class SwitchingTest(unittest.TestCase):
    def test_connecting_and_connected_rows_are_a_switch_in_progress(self):
        row = lambda facts: node("epicbox.stackwallet.com, " + facts, 900, clickable=True)
        self.assertTrue(trust.switching([row("Connecting, Stack Wallet")]))
        self.assertTrue(trust.switching([row("Connected, 120 ms")]))
        self.assertFalse(trust.switching([row(trust.facts.CURRENT + ", 120 ms")]))
        self.assertFalse(trust.switching([node("Connecting to Tor", 900)]))  # not a server row


class ServersKeptTest(unittest.TestCase):
    def digest(self, node_in_use):
        nodes = {"rows": [{"host": "node.btlabs.uk", "current": node_in_use == "node.btlabs.uk", "added": False},
                          {"host": "127.0.0.1:4000", "current": node_in_use == "127.0.0.1:4000", "added": True}],
                 "removed": None}
        relays = {"rows": [{"host": "epicbox.stackwallet.com", "current": True, "added": False},
                           {"host": "127.0.0.1:4001", "current": False, "added": True}], "removed": None}
        return {"address": "esABCDEFGHIJKLMNOPQRSTUVWXYZ@epicbox.stackwallet.com", "opened": True,
                "balance": {"total": "1", "spendable": "1"}, "history": [], "nodes": nodes, "relays": relays,
                "settings": {}}

    def test_a_moved_server_in_use_is_lost_and_said(self):
        with mock.patch.dict(trust.CUSTOM, {"Node": "http://127.0.0.1:4000", "Epicbox": "127.0.0.1:4001"}):
            res, det = trust.compare(self.digest("node.btlabs.uk"), self.digest("node.btlabs.uk"))
            self.assertTrue(res["custom_nodes_kept"])
            self.assertTrue(res["custom_relays_kept"])
            res, det = trust.compare(self.digest("node.btlabs.uk"), self.digest("127.0.0.1:4000"))
        self.assertFalse(res["custom_nodes_kept"])
        self.assertIn("the update moved the Node in use", det["custom_nodes_kept"])


if __name__ == "__main__":
    unittest.main()
