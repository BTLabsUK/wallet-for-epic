# SPDX-License-Identifier: Apache-2.0
"""The Android lane on the shared core: uiautomator dumps read as core Nodes (android/uia.py), and the
phone recipe (core/phone.py) on a fake surface: unlock with the PIN, a fresh-install screen after the
update is the product's fault, the phrase read off one node per word. No emulator."""
import os
import sys
import tempfile
import unittest
from unittest import mock

HERE = os.path.dirname(os.path.abspath(__file__))
DRIVERS = os.path.join(os.path.dirname(HERE), "drivers")
sys.path.insert(0, DRIVERS)
sys.path.insert(0, os.path.join(DRIVERS, "android"))

import uia  # noqa: E402
from core.driver import Driver  # noqa: E402
from core.faults import ProductFault  # noqa: E402
from core.phone import Phone, phrase_words  # noqa: E402
from core.recover import Recover, secret_screen  # noqa: E402
from core.surface import Node  # noqa: E402

PKG = "uk.btlabs.btwallet"


def xml(*nodes):
    rows = "".join('<node index="0" text="%s" resource-id="%s" class="%s" package="%s" content-desc="%s" checkable="%s" '
                   'checked="%s" clickable="%s" enabled="true" focused="false" scrollable="false" long-clickable="false" '
                   'password="%s" selected="false" bounds="%s" />' % (
                       n.get("text", ""), n.get("rid", ""), n.get("cls", "android.view.View"), n.get("pkg", PKG),
                       n.get("desc", "").replace("\n", "&#10;"), n.get("checkable", "false"), n.get("checked", "false"),
                       n.get("clickable", "false"), n.get("password", "false"), n["b"]) for n in nodes)
    return "<?xml version='1.0' encoding='UTF-8' standalone='yes' ?><hierarchy rotation=\"0\">%s</hierarchy>" % rows


class ParseTest(unittest.TestCase):
    def test_roles_names_and_values(self):
        t = uia.parse(xml({"desc": "Lock wallet", "clickable": "true", "cls": "android.widget.Button", "b": "[0,0][100,100]"},
                          {"desc": "Send\nTab 1 of 3", "clickable": "true", "b": "[0,200][100,300]"},
                          {"desc": "PIN", "text": "••••", "cls": "android.widget.EditText", "password": "true", "b": "[0,400][500,500]"},
                          {"desc": "12:01", "pkg": "com.android.systemui", "b": "[0,0][50,20]"}), PKG)
        self.assertEqual([(n.role, n.name) for n in t], [("button", "Lock wallet"), ("tab", "Send\nTab 1 of 3"), ("text_field", "PIN")])
        self.assertIn("password", t[2].states)
        self.assertEqual(t[2].value, "••••")
        self.assertIn("set_text", t[2].actions)

    def test_an_unnamed_switch_takes_its_row_label(self):
        t = uia.parse(xml({"desc": "Technical details\nShows more", "clickable": "true", "b": "[0,100][1080,250]"},
                          {"cls": "android.widget.Switch", "checkable": "true", "checked": "true", "b": "[900,120][1050,230]"},
                          {"desc": "Advanced", "b": "[0,0][1080,1000]"}), PKG)
        sw = [n for n in t if n.role == "toggle"][0]
        self.assertEqual(sw.name, "Technical details")
        self.assertIn("checked", sw.states)

    def test_a_phrase_shown_word_by_word_is_secret(self):
        words = ["abandon", "ability", "able", "about", "above", "absent", "absorb", "abstract", "absurd", "abuse", "access", "accident"]
        t = uia.parse(xml(*({"desc": "Word %d: %s" % (i + 1, w), "b": "[0,%d][500,%d]" % (i * 50, i * 50 + 40)}
                            for i, w in enumerate(words))), PKG)
        self.assertTrue(secret_screen(t))
        self.assertEqual(phrase_words([n.name for n in reversed(t)]), words)
        self.assertEqual(phrase_words([n.name for n in t[:11]]), [])


def node(i, role, name, **kw):
    return Node(i=i, role=role, name=name, states=frozenset(kw.pop("states", ("enabled",))), actions=("press",), **kw)


HOME = [node(0, "button", "Lock wallet"), node(1, "button", "Settings"), node(2, "tab", "Send\nTab 1 of 3"),
        node(3, "tab", "Wallet\nTab 2 of 3", states=("enabled", "selected")), node(4, "tab", "Receive\nTab 3 of 3")]
UNLOCK = [node(0, "text", "Unlock wallet"), Node(i=1, role="text_field", name="PIN", value="", actions=("press", "set_text"),
                                                 states=frozenset({"enabled", "password", "editable"})), node(2, "button", "Forgot PIN?")]
WELCOME = [node(0, "button", "Create a new wallet"), node(1, "button", "Restore from phrase")]


class FakePhone:
    platform, family = "android", "phone"

    def __init__(self, screens, cur):
        self.screens, self.cur, self.typed = screens, cur, []

    def tree(self):
        return list(self.screens[self.cur])

    def press(self, n):
        pass

    def set_text(self, n, text):
        self.typed.append(len(text))  # the length only: a test log never holds a PIN either
        if self.cur == "unlock":
            self.cur = "home"

    def key(self, name):
        pass

    def scroll(self, direction="down"):
        pass

    def screenshot(self, path):
        return False

    def alive(self):
        return True

    def in_front(self):
        return True


class PhoneTest(unittest.TestCase):
    def setUp(self):
        self.out = tempfile.mkdtemp(prefix="trust-android-")
        env = mock.patch.dict(os.environ, {"REL_AI": "0"})
        env.start()
        self.addCleanup(env.stop)

    def recipe(self, s):
        d = Driver(s, None, Recover(self.out, "android", log=lambda *_: None), out=self.out, log=lambda *_: None, poll=0.01)
        return Phone(d, "candidate", log=lambda *_: None)

    def test_unlock_with_the_pin_reaches_home(self):
        s = FakePhone({"unlock": UNLOCK, "home": HOME}, "unlock")
        self.recipe(s).open_wallet({"pin": "135790", "password": "x", "phrase": "y"}, after_update=True)
        self.assertEqual((s.cur, s.typed), ("home", [6]))

    def test_welcome_after_the_update_is_the_products_fault(self):
        s = FakePhone({"welcome": WELCOME}, "welcome")
        with self.assertRaises(ProductFault) as c:
            self.recipe(s).open_wallet({"pin": "135790"}, after_update=True)
        self.assertEqual(c.exception.step, "wallet_opens")


if __name__ == "__main__":
    unittest.main()
