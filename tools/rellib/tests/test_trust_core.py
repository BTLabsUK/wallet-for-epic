# SPDX-License-Identifier: Apache-2.0
"""The shared driver core (drivers/core) on a fake surface: targets found by id, by a build's own
label and after a rename by the model; obstacles pressed away; a secret screen never sent; the app
quitting is the product's fault; a failed step's tree kept
without a password's value and never a phrase screen's; saved states written and picked; the confirmations stepper set and read
whichever way the build names its field; the dialog break's button found by its label; a moved setting
found by walking the sections when a narrow window folds their list into one selector; a cached AI path
replayed without the model."""
import pathlib
import json
import os
import stat
import sys
import tempfile
import unittest
import unittest.mock

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "drivers"))

from core import state as st  # noqa: E402
from core import targets as tg  # noqa: E402
from core.desktop import TECHNICAL, Desktop  # noqa: E402
from core.driver import Driver, shows  # noqa: E402
from core.faults import HarnessFault, ProductFault  # noqa: E402
from core.labels import ROOT, Labels  # noqa: E402
from core.recover import Recover  # noqa: E402
from core.surface import Node  # noqa: E402

UNLOCK = tg.Target(id="g4.unlock.submit", role="button", keys=("deskOnbUnlockButton",))
SKIP = tg.Target(id="g4.tour.skip", role="button", keys=("deskTourSkip",))
HOME = tg.Target(id="g4.home.available", role="text", keys=("deskOvAvailable",), match="starts")


def n(i, role, name, **kw):
    return Node(i=i, role=role, name=name, states=frozenset(kw.pop("states", ("enabled",))), **kw)


class Fake:
    platform, family = "linux", "desktop"

    def __init__(self, screens, start, moves):
        self.screens, self.cur, self.moves, self.pressed, self.up = screens, start, moves, [], True

    def tree(self):
        return list(self.screens[self.cur])

    def press(self, node):
        self.pressed.append(node.name)
        self.cur = self.moves.get((self.cur, node.name), self.cur)

    def set_text(self, node, text, secret=False):
        pass

    def key(self, name):
        pass

    def scroll(self, direction="down"):
        pass

    def screenshot(self, path):
        return False

    def alive(self):
        return self.up


ARB = {"deskOnbUnlockButton": "Unlock", "deskTourSkip": "Skip tour", "deskOvAvailable": "Available to spend"}


class CoreTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.out = self.tmp.name
        self.logs = []

    def tearDown(self):
        self.tmp.cleanup()

    def driver(self, fake, arb=ARB):
        rec = Recover(self.out, "linux", log=self.logs.append)
        return Driver(fake, Labels(arb=arb), rec, out=self.out, log=self.logs.append, poll=0.01)

    def test_label_from_the_builds_own_strings(self):
        f = Fake({"lock": [n(0, "button", "Unlock")], "home": [n(0, "text", "Available to spend\n0.03 EPIC")]},
                 "lock", {("lock", "Unlock"): "home"})
        d = self.driver(f)
        d.press(UNLOCK, step="unlock", then=shows(HOME), timeout=1)
        self.assertEqual(f.cur, "home")
        # the same target on a build that renamed the button: its ARB says the new text
        f2 = Fake({"lock": [n(0, "button", "Open wallet")], "home": [n(0, "text", "Available to spend")]},
                  "lock", {("lock", "Open wallet"): "home"})
        self.driver(f2, dict(ARB, deskOnbUnlockButton="Open wallet")).press(UNLOCK, step="unlock", then=shows(HOME), timeout=1)
        self.assertEqual(f2.pressed, ["Open wallet"])

    def test_label_only_matches_listed_once(self):
        f = Fake({"lock": [n(0, "button", "Unlock")], "home": [n(0, "text", "Available to spend")]},
                 "lock", {("lock", "Unlock"): "home"})
        d = self.driver(f)
        d.locate(UNLOCK)
        d.locate(UNLOCK)
        d.press(UNLOCK, step="unlock", then=shows(HOME), timeout=1)
        with open(os.path.join(self.out, "by-label.txt")) as fh:
            self.assertEqual(fh.read(), "g4.unlock.submit button 'Unlock'\n")

    def test_id_wins_over_label(self):
        f = Fake({"lock": [n(0, "button", "Unlock"), n(1, "button", "Something else", id="g4.unlock.submit")],
                  "home": [n(0, "text", "Available to spend")]}, "lock", {("lock", "Something else"): "home"})
        self.driver(f).press(UNLOCK, step="unlock", then=shows(HOME), timeout=1)
        self.assertEqual(f.pressed, ["Something else"])

    def test_id_on_the_row_of_a_switch_finds_the_switch(self):
        sw = tg.Target(id="g4.advanced.technical", role="toggle", keys=("advTechnical",))
        row = Node(0, "button", "Technical details\nShows more", id="g4.advanced.technical", ref={"bounds": (0, 900, 1080, 1100)})
        on = Node(1, "toggle", "Technical details", states=frozenset({"checked"}), ref={"bounds": (860, 960, 1000, 1060)})
        other = Node(2, "toggle", "Outputs", ref={"bounds": (860, 820, 1000, 900)})
        self.assertEqual(tg.find(sw, [row, on, other]), [on])
        self.assertEqual(tg.find(sw, [row]), [row])  # no switch inside: the row, as before
        self.assertEqual(tg.find(UNLOCK, [Node(0, "button", "Unlock", id="g4.unlock.submit", ref={"bounds": (0, 0, 9, 9)})])[0].name, "Unlock")

    def test_obstacle_pressed_away(self):
        f = Fake({"tour": [n(0, "button", "Skip tour")], "home": [n(0, "text", "Available to spend")]}, "tour",
                 {("tour", "Skip tour"): "home"})
        d = self.driver(f)
        d.obstacles.append((SKIP, "the tour"))
        self.assertTrue(d.wait(shows(HOME), 1))

    def test_last_line_of_a_merged_row(self):
        row = "Lane A\nNo message\n23 h 48 min left\nYou pay\n0.01\xa0EPIC\nReview"
        self.assertTrue(tg._fits(row, "review", "last"))
        self.assertFalse(tg._fits(row, "review", "line"))
        self.assertFalse(tg._fits("Review invoice", "review", "last"))

    def test_in_place_change_counts_as_the_press_taking(self):
        """A switch that only flips its checked state, or a stepper that only changes its value, is
        pressed once: the default wait sees the change instead of timing out and pressing again."""
        sw = tg.Target(id="g4.settings.switch", role="button", keys=("deskTourSkip",))
        f = Fake({"off": [n(0, "button", "Skip tour")], "on": [n(0, "button", "Skip tour", states=("enabled", "checked"))]},
                 "off", {("off", "Skip tour"): "on", ("on", "Skip tour"): "off"})
        self.driver(f).press(sw, step="switch", timeout=1)
        self.assertEqual((f.cur, f.pressed), ("on", ["Skip tour"]))
        f = Fake({"1": [n(0, "button", "Skip tour", value="1")], "2": [n(0, "button", "Skip tour", value="2")]},
                 "1", {("1", "Skip tour"): "2", ("2", "Skip tour"): "3"})
        self.driver(f).press(sw, step="stepper", timeout=1)
        self.assertEqual(f.pressed, ["Skip tour"])

    def test_focus_alone_is_not_a_change(self):
        sw = tg.Target(id="g4.settings.switch", role="button", keys=("deskTourSkip",))
        f = Fake({"a": [n(0, "button", "Skip tour")], "b": [n(0, "button", "Skip tour", states=("enabled", "focused"))]},
                 "a", {("a", "Skip tour"): "b"})
        with self.assertRaises(HarnessFault):
            self.driver(f).press(sw, step="switch", timeout=0.1)
        self.assertGreater(len(f.pressed), 1)  # pressed again: the focus ring did not count

    def test_failure_dump_keeps_a_password_screen_without_its_value_and_never_a_phrase(self):
        """A step that fails on a password screen leaves its tree for the report, the field's value
        left out; a phrase screen leaves none."""
        d = self.driver(Fake({}, "s", {}))
        d.dump("pw", [n(0, "text", "Unlock wallet"), n(1, "text_field", "Password", value="hunter2", states=("password",))])
        with open(os.path.join(self.out, "tree-000-pw.txt")) as f:
            text = f.read()
        self.assertIn("Unlock wallet", text)
        self.assertNotIn("hunter2", text)
        d.dump("phrase", [n(0, "text", " ".join(["abandon"] * 24)), n(1, "text_field", "Password", states=("password",))])
        self.assertFalse(os.path.exists(os.path.join(self.out, "tree-000-phrase.txt")))

    def test_labels_from_this_checkout_are_english(self):
        """A candidate given no source tree or ref reads this checkout's English strings, whatever REL_TRUST_LOCALE says."""
        with unittest.mock.patch.dict(os.environ, {"REL_TRUST_LOCALE": "pl"}):
            l = Labels()
        self.assertEqual(l.origin, "this checkout")
        self.assertEqual(l.text("deskOnbUnlockTitle"), l.en.get("deskOnbUnlockTitle"))

    def test_app_quit_is_product(self):
        f = Fake({"lock": [n(0, "text", "Loading")]}, "lock", {})
        f.up = False
        with self.assertRaises(ProductFault):
            self.driver(f).wait(shows(HOME), 1)

    def test_state_save_and_pick(self):
        class P:
            name, variant = "linux", "tor"

            def save_state(self, folder):
                pathlib.Path(os.path.join(folder, "home.tar")).write_text("x")

        env = {"REL_TRUST_STATE_ROOT": self.out, "REL_CANDIDATE_VERSION": "26.10.26", "REL_TRUST_START": "auto"}
        with unittest.mock.patch.dict(os.environ, env):
            for v in ("26.10.24", "26.10.25", "26.10.26"):
                with unittest.mock.patch.dict(os.environ, {"REL_CANDIDATE_VERSION": v}):
                    st.save(P(), {"password": "pw", "phrase": "a b c"}, {"balance": "0"}, log=self.logs.append)
            s = st.pick("linux", "tor", "26.10.26")
            self.assertEqual(s.secrets(), {"password": "pw", "phrase": "a b c"})
            self.assertEqual(stat.S_IMODE(os.stat(os.path.join(s.folder, "secrets", "password")).st_mode), 0o600)
            self.assertIsNone(st.pick("linux", "tor", "26.10.24"))  # pruned: two kept
            with unittest.mock.patch.dict(os.environ, {"REL_TRUST_START": "fresh"}):
                self.assertIsNone(st.pick("linux", "tor", "26.10.26"))


    def _unlock(self, field):
        f = Fake({"lock": [n(0, "text", "Unlock wallet"), field, n(2, "button", "Unlock")]}, "lock", {})
        d = self.driver(f, arb={"deskOnbStepPassword": "Password", "deskOnbUnlockTitle": "Unlock wallet"})
        desk = Desktop(d, "candidate", self.logs.append)
        desk.password = "x"
        d.wait = lambda expect, timeout=30, **kw: expect.test(d, f.tree()) or None
        return desk

    def test_update_strip_hidden_before_a_step(self):
        """A newer release out: the strip above the page is hidden (×) so a step never meets its Update."""
        f = Fake({"strip": [n(0, "text", "Version 26.11.99 is available."), n(1, "button", "Update"),
                            n(2, "button", "Hide until the next version"), n(3, "text", "Available to spend")],
                  "home": [n(0, "text", "Available to spend")]}, "strip", {("strip", "Hide until the next version"): "home"})
        d = self.driver(f, arb={"deskUpdStripHide": "Hide until the next version", "deskOvAvailable": "Available to spend"})
        Desktop(d, "candidate", self.logs.append)
        d._clear()
        self.assertEqual((f.cur, f.pressed), ("home", ["Hide until the next version"]))

    def test_password_field_without_the_flag_is_product(self):
        # 26.10.26 b1e4540 on Windows: the unlock field had its Semantics id and no IsPassword
        desk = self._unlock(n(1, "text_field", "Password", states=("enabled", "editable", "focused")))
        with self.assertRaises(ProductFault) as c:
            desk._fill_passwords("unlock-password", 1)
        self.assertIn("not exposed as a password", str(c.exception))
        self.assertTrue([f for f in os.listdir(self.out) if f.endswith("-fail-unlock-password.txt")])

    def test_password_field_with_the_flag_is_typed(self):
        desk = self._unlock(n(1, "text_field", "Password", states=("enabled", "editable", "password")))
        self.assertEqual(desk._fill_passwords("unlock-password", 1), 1)

    def test_no_password_field_at_all_is_harness(self):
        desk = self._unlock(n(1, "text_field", "Search", states=("enabled", "editable")))
        with self.assertRaises(HarnessFault) as c:
            desk._fill_passwords("unlock-password", 1)
        self.assertNotIsInstance(c.exception, ProductFault)

    def test_stepper_set_both_ways_and_read(self):
        class Stepper(Fake):
            def __init__(self, v, field):
                super().__init__({}, "p", {})
                self.v, self.field = v, field

            def tree(self):
                return [n(0, "button", "Fewer confirmations"), n(1, "text_field", self.field, value=str(self.v)),
                        n(2, "button", "More confirmations")]

            def press(self, node):
                self.pressed.append(node.name)
                self.v += -1 if node.name.startswith("Fewer") else 1

        arb = {"deskSetAdvConfirmations": "Confirmations", "deskSetAdvConfirmationsFewer": "Fewer confirmations",
               "deskSetAdvConfirmationsMore": "More confirmations"}
        # 26.10.26 named the field with the − button's tooltip after it; the build after it, the label alone
        for field in ("Confirmations. Fewer confirmations", "Confirmations"):
            with self.subTest(field):
                f = Stepper(6, field)
                desk = Desktop(self.driver(f, arb), "candidate", self.logs.append)
                self.assertEqual(desk._confirmations(), 6)
                self.assertEqual(desk.set_confirmations(1), 1)
                self.assertEqual(f.pressed, ["Fewer confirmations"] * 5)
                self.assertEqual(desk.set_confirmations(2), 2)
                self.assertEqual(f.pressed[-1], "More confirmations")

    def test_moved_setting_found_through_the_folded_section_list(self):
        search = n(9, "text_field", "Search settings")
        page = lambda name, *rest: [n(0, "button", name, value=name), search, *rest]  # noqa: E731
        f = Fake({"pay": page("Payments", n(1, "button", "Fewer confirmations")),
                  "list": [search, n(1, "row", "Payments"), n(2, "row", "Advanced"), n(3, "row", "Appearance")],
                  "adv": page("Advanced", n(1, "toggle", "Technical details")),
                  "app": page("Appearance")}, "pay",
                 {("pay", "Payments"): "list", ("adv", "Advanced"): "list", ("app", "Appearance"): "list",
                  ("list", "Payments"): "pay", ("list", "Advanced"): "adv", ("list", "Appearance"): "app"})
        d = self.driver(f)
        desk = Desktop(d, "previous", self.logs.append)
        with unittest.mock.patch("core.desktop.time.sleep"):   # the recipe names Payments; the setting is under Advanced
            self.assertTrue(desk.find_setting(TECHNICAL, ("payments",), "Technical details"))
        self.assertEqual(f.cur, "adv")
        self.assertTrue(any("found under Settings › g4.settings.section.advanced" in line for line in self.logs), self.logs)
        # listed as a recovery (proof.json, recovered.json) with a drafted fix to the recipe
        self.assertEqual([(r["kind"], r["target"], r["picked"]["name"]) for r in d.rec.used],
                         [("moved", "g4.advanced.technical", "g4.settings.section.advanced")])
        with open(os.path.join(self.out, "recovered.json")) as fh:
            self.assertEqual(json.load(fh)[0]["kind"], "moved")
        with open(os.path.join(self.out, "selector-fixes.md")) as fh:
            self.assertIn("found under Settings › g4.settings.section.advanced", fh.read())



if __name__ == "__main__":
    unittest.main()
