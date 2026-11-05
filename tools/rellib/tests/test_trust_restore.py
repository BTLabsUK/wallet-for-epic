# SPDX-License-Identifier: Apache-2.0
"""A lane seed's wallet restored on the desktop (core/desktop.py restore_wallet) on a fake app: each word
typed as a secret into its own field, the scan started at the birth height, a failed restore the
product's fault, and no word in any log line or file. The surfaces' secret typing: Linux only through
focus and xdotool's stdin, Windows from a rig file the agent deletes. The create-wallet test's fresh
install of the candidate on both platforms."""
import calendar
import dataclasses
import os
import sys
import tempfile
import unittest
import unittest.mock

HERE = os.path.dirname(os.path.abspath(__file__))
DRIVERS = os.path.join(os.path.dirname(HERE), "drivers")
sys.path.insert(0, DRIVERS)

from core.desktop import Desktop, birth_height  # noqa: E402
from core.driver import Driver  # noqa: E402
from core.faults import HarnessFault, ProductFault  # noqa: E402
from core.labels import Labels  # noqa: E402
from core.recover import Recover  # noqa: E402
from core.surface import Node  # noqa: E402

WORDS = ["zq%s%s" % (a, b) for a in "abcdef" for b in "wxyz"]   # 24 made-up words, easy to look for


def n(i, role, name, value=None, states=("enabled",)):
    return Node(i=i, role=role, name=name, value=value, states=frozenset(states))


class RestoreApp:
    """welcome › the phrase grid › password and start block › restoring › Overview (or not restored). The
    start block as the planned final design has it: the button "Change the start" opens the Month | Block
    height panel; "Scan from the start" sits behind the info button "Scan start"."""
    platform, family = "linux", "desktop"

    def __init__(self, word="Word {number}", fails=False):
        self.word, self.fails = word, fails
        self.at, self.values, self.pw, self.height = "welcome", [""] * 24, ["", ""], None
        self.by_height = self.panel = self.info = self.from_start = False
        self.typed, self.pressed, self.keys, self.reads = [], [], [], 0

    def tree(self):
        if self.at == "welcome":
            return [n(0, "button", "Create a new wallet"), n(1, "button", "Restore from phrase")]
        if self.at == "words":
            fields = [n(i, "text_field", "%d\n%s" % (i, self.word.replace("{number}", str(i))), value=self.values[i - 1],
                        states=("enabled", "editable")) for i in range(1, 25)]
            done = self.values == WORDS
            return [n(30, "text", "Restore from phrase"), *fields, n(40, "button", "Paste"),
                    n(41, "button", "Continue", states=("enabled",) if done else ())]
        if self.at == "account":
            t = [n(50, "text", "Restore wallet"),
                 n(51, "text_field", "Password", value="", states=("enabled", "editable", "password")),
                 n(52, "text_field", "Confirm password", value="", states=("enabled", "editable", "password")),
                 n(57, "text", "Scanning from the start" if self.from_start else "Scanning from January 2025"),
                 n(53, "button", "Change the start"), n(58, "button", "Scan start")]
            if self.info:
                t.append(n(59, "button", "Scan from the start"))
            if self.panel:
                t += [n(54, "button", "Month", states=("enabled",) if self.by_height else ("enabled", "selected")),
                      n(55, "button", "Block height")]
                if self.by_height:
                    t.append(n(56, "text_field", "Start from block\nBlock height", value=self.height or "",
                               states=("enabled", "editable")))
            ready = self.pw[0] and self.pw[0] == self.pw[1]
            return t + [n(60, "button", "Restore wallet", states=("enabled",) if ready else ())]
        if self.at == "restoring":
            self.reads += 1
            if self.reads > 3:
                self.at = "failed" if self.fails else "home"
            return [n(70, "text", "Restoring the wallet"), n(71, "text", "Restoring the wallet")]
        if self.at == "failed":
            return [n(80, "text", "Wallet not restored"), n(81, "text", "The node did not answer.")]
        return [n(90, "other", "Main navigation"), n(91, "text", "Available to spend\n0.0400 EPIC")]

    def press(self, node):
        self.pressed.append(node.name)
        if self.at == "welcome" and node.name == "Restore from phrase":
            self.at = "words"
        elif self.at == "words" and node.name == "Continue" and "enabled" in node.states:
            self.at = "account"
        elif self.at == "account":
            if node.name == "Change the start":
                self.panel, self.from_start = True, False
            elif node.name == "Scan start":
                self.info = True
            elif node.name == "Scan from the start":
                self.info, self.panel, self.from_start = False, False, True
            elif node.name == "Block height":
                self.by_height = True
            elif node.name == "Restore wallet" and "enabled" in node.states:
                self.at = "restoring"

    def set_text(self, node, text, secret=False):
        self.typed.append((node.name, secret))
        if node.i <= 24:
            self.values[node.i - 1] = text
        elif node.i in (51, 52):
            self.pw[node.i - 51] = text
        elif node.i == 56:
            self.height = text

    def key(self, name):
        self.keys.append(name)

    def scroll(self, direction="down"):
        pass

    def screenshot(self, path):
        return False

    def alive(self):
        return True


class RestoreTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.out, self.logs = self.tmp.name, []
        nap = unittest.mock.patch("core.desktop.time.sleep")
        nap.start()
        self.addCleanup(nap.stop)
        self.addCleanup(self.tmp.cleanup)

    def desk(self, app, arb=None):
        rec = Recover(self.out, "linux", log=self.logs.append)
        d = Driver(app, Labels(arb=arb or {}), rec, out=self.out, log=self.logs.append, poll=0.01)
        return Desktop(d, "previous", self.logs.append)

    def assertNoWord(self):
        files = []
        for root, _dirs, names in os.walk(self.out):
            for name in names:
                with open(os.path.join(root, name), errors="replace") as f:
                    files.append(f.read())
        for text in ["\n".join(self.logs), *files]:
            for w in WORDS:
                self.assertNotIn(w, text)

    def test_words_typed_as_secrets_then_the_scan_from_the_birth_height(self):
        app = RestoreApp()
        with unittest.mock.patch.dict(os.environ, {"REL_AI": "0"}):
            got = self.desk(app).restore_wallet(" ".join(WORDS), {"height": 3412345, "month": "2026-11"})
        self.assertEqual(app.values, WORDS)
        words = [s for name, s in app.typed if name.split("\n")[0].isdigit()]
        self.assertEqual(words, [True] * 24)
        self.assertEqual(app.pw, [got["password"]] * 2)
        self.assertEqual(app.height, "3412345")
        self.assertEqual(app.at, "home")
        self.assertIn("Block height", app.pressed)
        self.assertNotIn("Scan from the start", app.pressed)
        self.assertEqual(app.keys, ["space"] * 23)   # each word committed, as a person typing moves on
        self.assertNoWord()

    def test_grid_named_in_the_builds_language(self):
        app = RestoreApp(word="Słowo {number}")
        with unittest.mock.patch.dict(os.environ, {"REL_AI": "0"}):
            self.desk(app, {"deskOnbWordN": "Słowo {number}"}).restore_wallet(" ".join(WORDS), {"height": None, "month": None})
        self.assertEqual(app.values, WORDS)
        self.assertNotIn("Block height", app.pressed)   # no birth: the whole chain
        self.assertEqual(app.pressed.count("Scan from the start"), 1)   # not left to the January 2025 default
        self.assertTrue(app.from_start)
        self.assertNoWord()

    def test_not_restored_is_the_products_fault(self):
        app = RestoreApp(fails=True)
        with unittest.mock.patch.dict(os.environ, {"REL_AI": "0"}), self.assertRaises(ProductFault) as c:
            self.desk(app).restore_wallet(" ".join(WORDS), {"height": 3412345})
        self.assertEqual(c.exception.step, "restore_ok")
        self.assertIn("did not answer", c.exception.what)
        self.assertNoWord()

    def test_a_field_that_never_holds_its_word_is_harness_without_the_word(self):
        class Deaf(RestoreApp):
            def set_text(self, node, text, secret=False):
                if node.i == 7:
                    return
                super().set_text(node, text, secret)
        with unittest.mock.patch.dict(os.environ, {"REL_AI": "0"}), \
                unittest.mock.patch("core.driver.SLOW", 0.01), self.assertRaises(HarnessFault) as c:
            self.desk(Deaf()).restore_wallet(" ".join(WORDS), {"height": 1})
        self.assertIn("field 7", c.exception.what)
        self.assertNoWord()

    def test_a_phrase_of_the_wrong_length_is_refused(self):
        with self.assertRaises(HarnessFault):
            self.desk(RestoreApp()).restore_wallet(" ".join(WORDS[:13]), None)

    def test_birth_height(self):
        self.assertEqual(birth_height({"height": 3412345, "month": "2026-11"}), 3412345)
        secs = calendar.timegm((2026, 11, 1, 0, 0, 0)) - 1567476608
        self.assertEqual(birth_height({"height": None, "month": "2026-11"}), 1 + secs // 60 - 2880)
        self.assertEqual(birth_height({"month": "2019-09"}), 1)
        self.assertIsNone(birth_height({"height": None, "month": None}))
        self.assertIsNone(birth_height(None))


# ---- Linux: AT-SPI focus, then xdotool with the text on stdin

sys.path.insert(0, os.path.join(DRIVERS, "linux"))
import atspi  # noqa: E402


class AtspiSecretTest(unittest.TestCase):
    def surface(self, focus_ok):
        s = atspi.AtspiSurface(tempfile.gettempdir(), log=lambda line: None)
        s.reqs, s.xdo = [], []
        s._call = lambda req, timeout=None: (s.reqs.append(req["op"]), {"ok": focus_ok if req["op"] == "focus" else True})[1]
        s._xdo = lambda *a, inp=None: s.xdo.append((a, inp))
        return s

    def node(self):
        return Node(i=3, role="text_field", name="Word 3", value="zqa", states=frozenset({"enabled"}),
                    ref={"path": [0, 3], "role": "text", "name": "Word 3"})

    def test_secret_typed_slowly_from_stdin(self):
        s = self.surface(True)
        s.set_text(self.node(), "zqbw", secret=True)
        args, inp = s.xdo[-1]
        self.assertEqual(inp, "zqbw")
        self.assertNotIn("zqbw", " ".join(args))
        self.assertEqual(args[:3], ("type", "--delay", "90"))

    def test_an_empty_field_is_not_cleared(self):
        """Backspace in an empty box of 26.10.25's phrase grid moves back a box: the word went into field 1 again."""
        s = self.surface(True)
        s.set_text(dataclasses.replace(self.node(), value=""), "zqbw", secret=True)
        self.assertEqual([a[:2] for a, _ in s.xdo], [("type", "--delay")])

    def test_secret_never_set_through_the_worker(self):
        s = self.surface(False)
        with unittest.mock.patch.object(atspi, "SECRET_FOCUS_S", 1), self.assertRaises(RuntimeError) as c:
            s.set_text(self.node(), "zqbw", secret=True)
        self.assertEqual(set(s.reqs), {"focus", "tree"})   # focus asked again, never set_text
        self.assertNotIn("zqa", str(c.exception))   # the field's current word is not named either
        self.assertNotIn("zqbw", str(c.exception))


# ---- Windows: the rig file the agent reads and deletes

WIN = os.path.join(DRIVERS, "windows")
sys.path.insert(0, WIN)
_other_uia = sys.modules.pop("uia", None)
import uia as wuia  # noqa: E402
import windows_platform as wp  # noqa: E402
sys.modules.pop("uia")
if _other_uia is not None:
    sys.modules["uia"] = _other_uia

VIEW = {"ct": "Custom", "name": "", "rect": [110, 35, 803, 691]}


class SecretRig:
    run, user = "C:\\rig\\run", "epicrig"

    def __init__(self, dropped=True):
        self.dropped, self.calls, self.put, self.ps = dropped, [], [], []

    def call(self, op, timeout=120, **kw):
        self.calls.append((op, kw))
        if op == "type":
            return {"ok": True, "dropped": self.dropped and kw.get("drop", False)}
        if op == "setup":
            return {"ok": True, "entry": {"version": "26.10.26", "location": "C:\\Users\\epicrig\\Apps\\BT",
                                          "exe": "C:\\Users\\epicrig\\Apps\\BT\\btwallet.exe"}}
        return {"ok": True}

    def put_secret(self, local, name):
        with open(local) as f:
            self.put.append(f.read())
        return self.run + "\\secret\\" + name

    def pwsh(self, script, check=True):
        self.ps.append(script)


class WinSecretTest(unittest.TestCase):
    def surface(self, rig, rect):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        s = wuia.WinSurface(rig, log=self.logs.append, secret_dir=self.tmp.name)
        s.last = [VIEW, {"ct": "Edit", "name": "Słowo 5", "val": "zqa", "pat": ["value"], "rect": rect}]
        return s, s._node(1, s.last[1])

    def setUp(self):
        self.logs = []
        nap = unittest.mock.patch.object(wuia.time, "sleep", lambda s: None)
        nap.start()
        self.addCleanup(nap.stop)

    def test_secret_goes_by_a_file_the_agent_drops(self):
        rig = SecretRig()
        s, node = self.surface(rig, [300, 300, 100, 30])
        s.set_text(node, "zqcx", secret=True)
        self.assertEqual(rig.put, ["zqcx"])
        self.assertEqual([op for op, _ in rig.calls], ["click_rect", "erase", "type"])
        self.assertEqual(rig.calls[-1][1], {"file": "C:\\rig\\run\\secret\\typed", "drop": True})
        self.assertEqual(rig.ps, [])
        self.assertEqual(os.listdir(self.tmp.name), [])   # the local copy went too
        for line in self.logs + [repr(c) for c in rig.calls]:
            self.assertNotIn("zqcx", line)
            self.assertNotIn("zqa", line)

    def test_a_file_the_agent_kept_is_removed_by_its_path(self):
        rig = SecretRig(dropped=False)
        s, node = self.surface(rig, [300, 300, 100, 30])
        s.set_text(node, "zqcx", secret=True)
        self.assertEqual(len(rig.ps), 1)
        self.assertIn("Remove-Item -LiteralPath 'C:\\rig\\run\\secret\\typed'", rig.ps[0])

    def test_a_field_below_the_view_is_focused_by_its_default_action(self):
        rig = SecretRig()
        s, node = self.surface(rig, [300, 1200, 100, 30])
        s.set_text(node, "zqcx", secret=True)
        self.assertEqual(rig.calls[0], ("ui_at", {"idx": 1, "name": "Słowo 5", "what": "press"}))
        self.assertNotIn("click_rect", [op for op, _ in rig.calls])

    def test_plain_text_still_inline(self):
        rig = SecretRig()
        s, node = self.surface(rig, [300, 300, 100, 30])
        s.set_text(node, "3412345")
        self.assertEqual(rig.calls[-1], ("type", {"text": "3412345"}))
        self.assertEqual(rig.put, [])


# ---- the create-wallet test's fresh install

import linux_platform as lp  # noqa: E402


class FreshCandidateTest(unittest.TestCase):
    def test_linux_needs_an_empty_sandbox(self):
        with tempfile.TemporaryDirectory() as sb:
            p = object.__new__(lp.LinuxPlatform)
            p.sb = sb
            p.install_candidate_fresh()
            os.makedirs(os.path.join(lp.data_root(sb), "wallets"))
            with self.assertRaises(HarnessFault):
                p.install_candidate_fresh()

    def test_windows_runs_the_candidates_setup(self):
        p = object.__new__(wp.WindowsPlatform)
        p.rig = SecretRig()
        p.surface = type("S", (), {"_call": lambda self_, op, timeout=120, **kw: p.rig.call(op, **kw)})()
        p.log = lambda line: None
        p.rig.call = (lambda orig: lambda op, timeout=120, **kw: {"ok": True, "entry": None} if op == "entry"
                      else orig(op, timeout, **kw))(p.rig.call)
        p.install_candidate_fresh()
        op, kw = next(c for c in p.rig.calls if c[0] == "setup")
        self.assertEqual(kw["exe"], "C:\\rig\\run\\cand-setup.exe")
        self.assertEqual(p.rig.calls[-1][0], "store_init")   # English in the app's store after Setup
        self.assertIn("/LOG=C:\\rig\\run\\setup-candidate.log", kw["args"])
        self.assertTrue(p.exe.endswith("btwallet.exe"))

    def test_windows_create_mode_leaves_the_previous_setup_out(self):
        env = {"REL_TRUST_MODE": "create", "REL_CANDIDATE_DIR": "/c", "REL_CANDIDATE_VERSION": "26.10.26",
               "REL_VARIANT": "tor", "REL_WORK": tempfile.gettempdir()}
        with unittest.mock.patch.dict(os.environ, env):
            p = object.__new__(wp.WindowsPlatform)
            p.create = True
            got = []
            p.setup_exe = lambda folder, ver: got.append(folder) or folder + "/setup.exe"
            p._pick_servers = lambda: None
            p._healthy_rig = lambda prev, cand: got.append((prev, cand))
            p.work, p.log = tempfile.mkdtemp(dir=os.environ.get("TMPDIR")), lambda line: None
            p.cand_dir, p.cand_ver, p.prev_dir, p.prev_ver = "/c", "26.10.26", "", ""
            try:
                p.prepare()
            except Exception:  # noqa: BLE001  (the rest of prepare needs a rig)
                pass
            os.rmdir(p.work)
        self.assertEqual(got[:2], ["/c", (None, "/c/setup.exe")])


if __name__ == "__main__":
    unittest.main()
