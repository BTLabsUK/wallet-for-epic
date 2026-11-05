# SPDX-License-Identifier: Apache-2.0
"""The iOS lane on the shared core: WebDriverAgent sources read as core Nodes (ios/wda.py), the phone's
Back on a fake WDA, the device type and the Simulator zip's app, and trust-ios.sh's plan and its
fail-closed starts. No Mac, no Simulator."""
import json
import os
import plistlib
import subprocess
import sys
import tempfile
import unittest
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
DRIVERS = os.path.join(os.path.dirname(HERE), "drivers")
sys.path.insert(0, DRIVERS)
sys.path.insert(0, os.path.join(DRIVERS, "ios"))

import ios_platform  # noqa: E402
import wda  # noqa: E402

TRUST = os.path.join(DRIVERS, "trust-ios.sh")


def el(t, x, y, w, h, children=(), **kw):
    e = {"type": "XCUIElementType" + t, "rect": {"x": x, "y": y, "width": w, "height": h}, "isEnabled": "1"}
    e.update(kw)
    if children:
        e["children"] = list(children)
    return e


def app(*children, kb=None):
    kids = list(children) + ([el("Keyboard", 0, kb, 400, 874 - kb, [el("Key", 10, kb + 10, 30, 40, label="q")])] if kb else [])
    return el("Application", 0, 0, 402, 874, [el("Window", 0, 0, 402, 874, kids)], label="BT Wallet")


class ParseTest(unittest.TestCase):
    def test_roles_names_ids_and_states(self):
        t = wda.parse(app(el("Button", 10, 10, 80, 40, label="Lock wallet", traits="Button"),
                          el("Other", 0, 800, 130, 60, label="Send\nTab 1 of 3", traits="Selected"),
                          el("StaticText", 10, 100, 200, 20, label="Balance", rawIdentifier="home.balance"),
                          el("SecureTextField", 10, 200, 380, 44, label="PIN", value="••••"),
                          el("Other", 0, 0, 402, 874)))
        self.assertEqual([(n.role, n.name) for n in t],
                         [("button", "Lock wallet"), ("tab", "Send\nTab 1 of 3"), ("text", "Balance"), ("text_field", "PIN")])
        self.assertIn("selected", t[1].states)
        self.assertEqual(t[2].id, "home.balance")
        self.assertIn("password", t[3].states)
        self.assertIn("set_text", t[3].actions)
        self.assertEqual(t[3].value, "••••")

    def test_a_placeholder_is_an_empty_field(self):
        t = wda.parse(app(el("TextField", 10, 200, 380, 44, placeholderValue="Node address", value="Node address"),
                          el("TextView", 10, 300, 380, 120, label="Note", value="hello", isFocused="1")))
        self.assertEqual((t[0].name, t[0].value), ("Node address", ""))
        self.assertEqual(t[1].value, "hello")
        self.assertIn("focused", t[1].states)
        self.assertTrue(t[1].ref["multiline"])

    def test_an_unnamed_switch_takes_its_row_label_and_its_value(self):
        t = wda.parse(app(el("Other", 0, 100, 402, 70, label="Technical details\nShows more"),
                          el("Switch", 330, 115, 50, 30, value="1"),
                          el("Switch", 330, 215, 50, 30, value="0", label="Hide balance")))
        sw = [n for n in t if n.role == "toggle"]
        self.assertEqual([n.name for n in sw], ["Technical details", "Hide balance"])
        self.assertIn("checked", sw[0].states)
        self.assertNotIn("checked", sw[1].states)

    def test_the_keyboard_and_what_is_off_screen_are_left_out(self):
        src = app(el("Button", 10, 10, 80, 40, label="Next", traits="Button"),
                  el("Button", 10, 900, 80, 40, label="Below the screen", traits="Button"),
                  el("Button", 10, 50, 0, 40, label="No size", traits="Button"), kb=540)
        self.assertEqual([n.name for n in wda.parse(src)], ["Next"])
        self.assertEqual(wda.keyboard_frame(src), (0, 540, 400, 874))
        self.assertIsNone(wda.keyboard_frame(app(el("Button", 10, 10, 80, 40, label="Next"))))

    def test_a_disabled_button_is_not_enabled(self):
        t = wda.parse(app(el("Button", 10, 10, 80, 40, label="Continue", traits="Button, NotEnabled")))
        self.assertNotIn("enabled", t[0].states)


class FakeWda:
    def __init__(self, src):
        self.src, self.calls = src, []

    def source(self):
        return self.src

    def tap(self, x, y):
        self.calls.append(("tap", x, y))

    def swipe(self, *a):
        self.calls.append(("swipe",) + a)

    def size(self):
        return 402, 874

    def keys(self, text):
        self.calls.append(("keys", text))

    def dismiss_keyboard(self, names):
        self.calls.append(("dismiss",))


class FakeSim:
    def running(self):
        return True


class BackTest(unittest.TestCase):
    def test_back_presses_the_pages_back_button(self):
        w = FakeWda(app(el("Button", 0, 50, 44, 44, label="Back", traits="Button"), el("StaticText", 60, 60, 200, 20, label="Settings")))
        wda.WdaSurface(w, FakeSim(), "b").key("back")
        self.assertEqual(w.calls, [("tap", 22, 72)])

    def test_back_with_no_button_swipes_from_the_left_edge(self):
        w = FakeWda(app(el("StaticText", 60, 60, 200, 20, label="Settings")))
        wda.WdaSurface(w, FakeSim(), "b").key("back")
        self.assertEqual(w.calls[0][0], "swipe")
        self.assertEqual(w.calls[0][1:3], (1, 437))

    def test_a_press_under_the_keyboard_hides_it_first(self):
        src = app(el("Button", 10, 600, 80, 40, label="Next", traits="Button"), el("TextField", 10, 100, 380, 44, label="Name", isFocused="1"), kb=540)
        w = FakeWda(src)
        s = wda.WdaSurface(w, FakeSim(), "b")
        n = next(n for n in s.tree() if n.name == "Next")
        s.press(n)
        self.assertEqual([c[0] for c in w.calls], ["dismiss", "keys", "tap"])
        self.assertEqual(w.calls[1], ("keys", "\n"))


class PlatformBitsTest(unittest.TestCase):
    def test_pick_device_type_skips_iphone_duo(self):
        rt = {"supportedDeviceTypes": [{"name": "iPhone Duo", "identifier": "duo"}, {"name": "iPhone 17", "identifier": "17"},
                                       {"name": "iPhone 18 Pro", "identifier": "18p"}, {"name": "iPhone 18 Pro Max", "identifier": "18pm"},
                                       {"name": "iPad Pro", "identifier": "ipad"}]}
        self.assertEqual(ios_platform.pick_device_type(rt), "18p")
        self.assertEqual(ios_platform.pick_device_type({"supportedDeviceTypes": rt["supportedDeviceTypes"][:2]}), "17")
        self.assertIsNone(ios_platform.pick_device_type({"supportedDeviceTypes": [rt["supportedDeviceTypes"][0]]}))

    def test_app_info_reads_the_zips_runner_app(self):
        with tempfile.TemporaryDirectory() as d:
            z = os.path.join(d, "a.zip")
            with zipfile.ZipFile(z, "w") as f:
                f.writestr("Runner.app/Info.plist", plistlib.dumps({"CFBundleIdentifier": "uk.btlabs.btwallet.ios",
                                                                    "CFBundleShortVersionString": "26.11.3", "CFBundleVersion": "7"}))
                f.writestr("Runner.app/Frameworks/X.framework/Info.plist", plistlib.dumps({"CFBundleIdentifier": "x"}))
            self.assertEqual(ios_platform.app_info(z), ("uk.btlabs.btwallet.ios", "26.11.3", "7"))
            bad = os.path.join(d, "b.zip")
            with open(bad, "wb") as f:
                f.write(b"not a zip")
            self.assertEqual(ios_platform.app_info(bad), (None, None, None))


def run_trust(env, *args):
    base = {k: v for k, v in os.environ.items() if not k.startswith("REL_")}
    base.update(env)
    return subprocess.run(["bash", TRUST] + list(args), env=base, capture_output=True, text=True, timeout=60)


class TrustIosShTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.d = self.tmp.name
        self.out = os.path.join(self.d, "out")

    def tearDown(self):
        self.tmp.cleanup()

    def zip_in(self, folder, version):
        p = os.path.join(self.d, folder, "ios")
        os.makedirs(p, exist_ok=True)
        f = os.path.join(p, "bt-wallet-%s-notor-ios-simulator.zip" % version)
        open(f, "wb").close()
        return f

    def test_dry_run_names_both_zips(self):
        prev = self.zip_in("prev", "26.11.2")
        cand = self.zip_in("cand", "26.11.3")
        r = run_trust({"REL_DRY_RUN": "1", "REL_OUT": self.out, "REL_PREVIOUS_DIR": os.path.join(self.d, "prev"),
                       "REL_PREVIOUS_VERSION": "26.11.2", "REL_CANDIDATE_EXTRA": os.path.join(self.d, "cand"),
                       "REL_CANDIDATE_VERSION": "26.11.3"})
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("simctl install " + prev, r.stdout)
        self.assertIn("simctl install " + cand + " over it", r.stdout)
        self.assertFalse(os.path.exists(self.out))

    def test_without_rel_out_it_cannot_run(self):
        r = run_trust({})
        self.assertEqual(r.returncode, 2)
        self.assertIn("REL_OUT is not set", r.stderr)

    def test_tor_is_refused_with_a_failed_proof(self):
        r = run_trust({"REL_OUT": self.out, "REL_VARIANT": "tor"})
        self.assertEqual(r.returncode, 2)
        with open(os.path.join(self.out, "proof.json")) as f:
            proof = json.load(f)
        self.assertTrue(proof["checks"])
        self.assertFalse(any(proof["checks"].values()))
        with open(os.path.join(self.out, "result.txt")) as f:
            self.assertIn("without Tor", f.read())

    def test_a_missing_candidate_fails_closed(self):
        self.zip_in("prev", "26.11.2")
        r = run_trust({"REL_OUT": self.out, "REL_PREVIOUS_DIR": os.path.join(self.d, "prev"), "REL_PREVIOUS_VERSION": "26.11.2",
                       "REL_CANDIDATE_DIR": os.path.join(self.d, "nothing")})
        self.assertEqual(r.returncode, 2)
        self.assertIn("no candidate", r.stderr)
        self.assertTrue(os.path.exists(os.path.join(self.out, "proof.json")))

    def test_a_break_in_a_release_run_is_refused(self):
        r = run_trust({"REL_OUT": self.out, "REL_RUN_KIND": "release", "REL_TRUST_BREAK": "x"})
        self.assertEqual(r.returncode, 2)
        self.assertIn("break tests", r.stderr)

    def test_checks_lists_the_required_checks(self):
        r = subprocess.run([sys.executable, "-I", os.path.join(DRIVERS, "ios", "lane.py"), "checks"],
                           capture_output=True, text=True, timeout=60)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("balance_kept", r.stdout.split(","))


if __name__ == "__main__":
    unittest.main()
