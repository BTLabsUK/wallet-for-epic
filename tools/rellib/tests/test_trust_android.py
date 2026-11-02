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


class OpenSheetTest(unittest.TestCase):
    """Home's Node icon: 26.10.24-r2 opens the Node sheet, 26.10.25 the Connections sheet first
    (a tap on any status icon), whose row (not clickable in the dump) opens the Node sheet."""
    HOME = [node(trust.facts.LOCK_WALLET, 100, clickable=True),
            node("Node, Synced | Up to date. | Node: node.example.org | Shows details", 400, clickable=True)]
    CONNECTIONS = [node("Scrim", 1000, clickable=True), node(trust.CONNECTIONS, 1200),
                   node("Node, Synced | Up to date · node.example.org", 1400),
                   node("Epicbox, Connected | Connected · box.epic.invalid", 1550)]
    NODE = [node("Scrim", 1000, clickable=True), node("Node", 900),
            node("node.lab.invalid, In use, Status unknown, BT Labs", 1300, clickable=True)]

    def run_open(self, screens):
        taps, seq = [], list(screens)

        def dump(serial=None):
            return seq.pop(0) if len(seq) > 1 else seq[0]

        def tapped(s, xy):
            taps.append(xy)

        for obj, name, fake in ((trust, "home", lambda: True), (trust, "nodes", dump), (trust.ph, "nodes", dump),
                                (trust, "tap_xy", tapped), (trust, "log", lambda *a: None),
                                (trust.time, "sleep", lambda s: None)):
            p = mock.patch.object(obj, name, fake)
            p.start()
            self.addCleanup(p.stop)
        trust.open_sheet("Node")
        return taps

    def test_candidate_goes_through_the_connections_row(self):
        self.assertEqual(self.run_open([self.HOME, self.CONNECTIONS, self.NODE]), [(540, 400), (540, 1400)])

    def test_previous_release_opens_the_sheet_directly(self):
        self.assertEqual(self.run_open([self.HOME, self.NODE]), [(540, 400)])

    def test_no_row_for_the_service_fails(self):
        conn = [n for n in self.CONNECTIONS if not n["label"].startswith("Node, ")]
        with mock.patch.object(trust, "dump_to_log", lambda t: None), self.assertRaises(RuntimeError):
            self.run_open([self.HOME, conn])


class SwitchingTest(unittest.TestCase):
    def test_connecting_and_connected_rows_are_a_switch_in_progress(self):
        row = lambda facts: node("epicbox.stackwallet.com, " + facts, 900, clickable=True)
        self.assertTrue(trust.switching([row("Connecting, Stack Wallet")]))
        self.assertTrue(trust.switching([row("Connected, 120 ms")]))
        self.assertFalse(trust.switching([row(trust.facts.CURRENT + ", 120 ms")]))
        self.assertFalse(trust.switching([node("Connecting to Tor", 900)]))  # not a server row


class NotPostedYetTest(unittest.TestCase):
    def test_posting_and_not_on_the_network_are_not_posted(self):
        # Activity rows as txSpokenRow says them: what, the status lower-cased, the date.
        for r in ("Sending 0.01 EPIC to esa57k…ZwzB4d, posting…, today, 12:01",
                  "Sending 0.01 EPIC to esa57k…ZwzB4d, not on the network, today, 12:01"):
            self.assertTrue(trust.not_posted_yet(r), r)
        self.assertFalse(trust.not_posted_yet("Sending 0.01 EPIC to esa57k…ZwzB4d, confirming 0/1, today, 12:01"))
        self.assertFalse(trust.not_posted_yet("Sent 0.01 EPIC to esa57k…ZwzB4d, sent, today, 12:01"))


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


class BesideTest(unittest.TestCase):
    """Two APKs with different package names (the 26.10.25 app id change): the candidate goes in
    beside the previous app, the wallet is restored there, and the carried-over checks are not
    applicable and not required."""

    def run_beside(self, total_after, level_three=True):
        d = ServersKeptTest().digest("node.btlabs.uk")
        after = dict(d, balance={"total": total_after, "spendable": total_after})
        calls, pkgs, order = [], [], []

        def adb(serial, *args, **kw):
            calls.append(args)
            return "Success" if args[0] == "install" else ""

        out = tempfile.mkdtemp()
        env = {"REL_PREVIOUS_APK": "/prev.apk", "REL_CANDIDATE_APK": "/cand.apk",
               "REL_PREVIOUS_PKG": "uk.btlabs.epiccash.mobile", "REL_CANDIDATE_PKG": "uk.btlabs.btwallet",
               "REL_CHECKS": ",".join(trust.CHECKS)}
        digests = iter([d, after])
        with mock.patch.dict(os.environ, env), mock.patch.dict(trust.CUSTOM, {"Node": "n", "Epicbox": "r"}), \
                mock.patch.multiple(trust, OUT=out, FUNDS=False, MIGRATE=True, SEED_FILES=True, adb=adb,
                                    read_secret=lambda n: "w " * 12, restore=lambda w: pkgs.append(trust.ph.PKG),
                                    unlock=lambda s=0: True, start_standins=lambda: None,
                                    add_custom=lambda k, h: True, use_server=lambda k, h: True,
                                    change_settings=lambda: None, address=lambda: d["address"],
                                    history=lambda *a: ["x"], has_sender=lambda r: True,
                                    server_list=lambda k: {"rows": [{"current": True, "host": "h"}]},
                                    same_host=lambda a, b: True,
                                    digest=lambda *a: order.append(a[0]) or dict(next(digests)),
                                    set_level_three=lambda: order.append("level3") or level_three,
                                    balance=lambda *a: after["balance"], shot=lambda n: None), \
                mock.patch.object(trust.ph, "version", lambda s: ("26.10.25", "261025000")), \
                mock.patch.object(trust.ph, "PKG", trust.ph.PKG), mock.patch.object(trust, "BESIDE", False), \
                mock.patch.object(trust.time, "sleep"):
            code = trust.run()
            with open(os.path.join(out, "proof.json")) as f:
                proof = __import__("json").load(f)
            return code, proof, calls, pkgs, trust.ph.PKG, order

    def test_the_candidate_goes_in_beside_and_restores(self):
        code, proof, calls, pkgs, pkg, order = self.run_beside("1")
        self.assertEqual(code, 0)
        self.assertEqual(pkgs, ["uk.btlabs.epiccash.mobile", "uk.btlabs.btwallet"])
        self.assertEqual(pkg, "uk.btlabs.btwallet")
        # A fresh install opens at level 1: Deep end is set before the candidate's digest.
        self.assertEqual(order[-2:], ["level3", "after"])
        self.assertIn(("install", "/cand.apk"), calls)
        self.assertNotIn(("install", "-r", "/cand.apk"), calls)
        self.assertIn(("shell", "am", "force-stop", "uk.btlabs.epiccash.mobile"), calls)
        self.assertEqual(proof["required"], ["wallet_opens", "balance_kept"])
        self.assertTrue(proof["packages"]["beside"])
        self.assertIn("beside", proof["update_method"])
        for k in trust.NOT_CARRIED:
            self.assertIn("not applicable", proof["details"][k])

    def test_another_total_after_the_restore_is_not_proven(self):
        code, proof, *_ = self.run_beside("0.5")
        self.assertEqual(code, 1)
        self.assertFalse(proof["checks"]["balance_kept"])


    def test_no_level_three_after_the_restore_is_not_proven(self):
        code, proof, *_ = self.run_beside("1", level_three=False)
        self.assertEqual(code, 1)
        self.assertFalse(proof["checks"]["wallet_opens"])
        self.assertIn("level 3", proof["details"]["wallet_opens"])


if __name__ == "__main__":
    unittest.main()
