# SPDX-License-Identifier: Apache-2.0
"""The shared driver core (drivers/core) on a fake surface: targets found by id, by a build's own
label and after a rename by the model; obstacles pressed away; a secret screen never sent; the app
quitting is the product's fault; a failed step's tree kept
without a password's value and never a phrase screen's; saved states written and picked; the confirmations stepper set and read
on a build in Polish; the dialog break's button found in the build's language; a moved setting found
by walking the sections when a narrow window folds their list into one selector."""
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
from core.labels import Labels  # noqa: E402
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

    def set_text(self, node, text):
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

    def test_id_wins_over_label(self):
        f = Fake({"lock": [n(0, "button", "Unlock"), n(1, "button", "Something else", id="g4.unlock.submit")],
                  "home": [n(0, "text", "Available to spend")]}, "lock", {("lock", "Something else"): "home"})
        self.driver(f).press(UNLOCK, step="unlock", then=shows(HOME), timeout=1)
        self.assertEqual(f.pressed, ["Something else"])

    def test_obstacle_pressed_away(self):
        f = Fake({"tour": [n(0, "button", "Skip tour")], "home": [n(0, "text", "Available to spend")]}, "tour",
                 {("tour", "Skip tour"): "home"})
        d = self.driver(f)
        d.obstacles.append((SKIP, "the tour"))
        self.assertTrue(d.wait(shows(HOME), 1))

    def test_renamed_button_found_by_the_model_and_recorded(self):
        f = Fake({"lock": [n(0, "text", "Welcome back"), n(1, "button", "Open my wallet")],
                  "home": [n(0, "text", "Available to spend")]}, "lock", {("lock", "Open my wallet"): "home"})
        with unittest.mock.patch.dict(os.environ, {"REL_AI_CMD": "printf '{\"i\": 1, \"why\": \"opens the wallet\"}'"}):
            self.driver(f).press(UNLOCK, step="unlock", then=shows(HOME), timeout=0.2)
        rec = json.load(open(os.path.join(self.out, "recovered.json")))
        self.assertEqual(rec[0]["picked"]["name"], "Open my wallet")
        self.assertIn("g4.unlock.submit", open(os.path.join(self.out, "selector-fixes.md")).read())

    def test_secret_screen_never_sent(self):
        phrase = " ".join(["abandon"] * 24)
        f = Fake({"s": [n(0, "text", phrase), n(1, "button", "Next")]}, "s", {})
        with unittest.mock.patch.dict(os.environ, {"REL_AI_CMD": "false"}), \
                unittest.mock.patch("core.recover._ask") as ask:
            with self.assertRaises(HarnessFault):
                self.driver(f).press(UNLOCK, step="phrase", timeout=0.1)
            ask.assert_not_called()

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

    def test_destructive_pick_refused(self):
        f = Fake({"s": [n(0, "button", "Delete wallet")]}, "s", {})
        with unittest.mock.patch.dict(os.environ, {"REL_AI_CMD": "printf '{\"i\": 0, \"why\": \"x\"}'"}):
            with self.assertRaises(HarnessFault) as e:
                self.driver(f).press(UNLOCK, step="unlock", timeout=0.1)
        self.assertIn("HARNESS unlock", e.exception.line())

    def test_app_quit_is_product(self):
        f = Fake({"lock": [n(0, "text", "Loading")]}, "lock", {})
        f.up = False
        with self.assertRaises(ProductFault):
            self.driver(f).wait(shows(HOME), 1)

    def test_state_save_and_pick(self):
        class P:
            name, variant = "linux", "tor"

            def save_state(self, folder):
                open(os.path.join(folder, "home.tar"), "w").write("x")

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
        f = Fake({"lock": [n(0, "text", "Odblokuj portfel"), field, n(2, "button", "Odblokuj")]}, "lock", {})
        d = self.driver(f, arb={"deskOnbStepPassword": "Hasło", "deskOnbUnlockTitle": "Odblokuj portfel"})
        desk = Desktop(d, "candidate", self.logs.append)
        desk.password = "x"
        d.wait = lambda expect, timeout=30, **kw: expect.test(d, f.tree()) or None
        return desk

    def test_password_field_without_the_flag_is_product(self):
        # 26.10.26 b1e4540 on Windows: the unlock field had its Semantics id and no IsPassword
        desk = self._unlock(n(1, "text_field", "Hasło", states=("enabled", "editable", "focused")))
        with self.assertRaises(ProductFault) as c:
            desk._fill_passwords("unlock-password", 1)
        self.assertIn("not exposed as a password", str(c.exception))
        self.assertTrue([f for f in os.listdir(self.out) if f.endswith("-fail-unlock-password.txt")])

    def test_password_field_with_the_flag_is_typed(self):
        desk = self._unlock(n(1, "text_field", "Hasło", states=("enabled", "editable", "password")))
        self.assertEqual(desk._fill_passwords("unlock-password", 1), 1)

    def test_no_password_field_at_all_is_harness(self):
        desk = self._unlock(n(1, "text_field", "Szukaj", states=("enabled", "editable")))
        with self.assertRaises(HarnessFault) as c:
            desk._fill_passwords("unlock-password", 1)
        self.assertNotIsInstance(c.exception, ProductFault)
    def test_stepper_set_both_ways_and_read_in_the_builds_language(self):
        class Stepper(Fake):
            def __init__(self, v, field):
                super().__init__({}, "p", {})
                self.v, self.field = v, field

            def tree(self):
                return [n(0, "button", "Mniej potwierdzeń"), n(1, "text_field", self.field, value=str(self.v)),
                        n(2, "button", "Więcej potwierdzeń")]

            def press(self, node):
                self.pressed.append(node.name)
                self.v += -1 if node.name.startswith("Mniej") else 1

        arb = {"deskSetAdvConfirmations": "Potwierdzenia", "deskSetAdvConfirmationsFewer": "Mniej potwierdzeń",
               "deskSetAdvConfirmationsMore": "Więcej potwierdzeń"}
        # 26.10.26 named the field with the − button's tooltip after it; the build after it, the label alone
        for field in ("Potwierdzenia. Mniej potwierdzeń", "Potwierdzenia"):
            with self.subTest(field):
                f = Stepper(6, field)
                desk = Desktop(self.driver(f, arb), "candidate", self.logs.append)
                self.assertEqual(desk._confirmations(), 6)
                self.assertEqual(desk.set_confirmations(1), 1)
                self.assertEqual(f.pressed, ["Mniej potwierdzeń"] * 5)
                self.assertEqual(desk.set_confirmations(2), 2)
                self.assertEqual(f.pressed[-1], "Więcej potwierdzeń")

    def test_dialog_break_presses_the_builds_own_info_button(self):
        f = Fake({"p": [n(0, "button", "Więcej informacji"), n(1, "button", "Unlock")]}, "p", {})
        d = self.driver(f, dict(ARB, deskKitInfoLabel="Więcej informacji"))
        with unittest.mock.patch.dict(os.environ, {"REL_TRUST_BREAK": "dialog:g4.unlock.submit"}), \
                unittest.mock.patch("core.driver.time.sleep"):
            d._clear(UNLOCK)
        self.assertEqual(f.pressed, ["Więcej informacji"])

    def test_moved_setting_found_through_the_folded_section_list(self):
        search = n(9, "text_field", "Search settings")
        page = lambda name, *rest: [n(0, "button", name, value=name), search, *rest]  # noqa: E731
        f = Fake({"pay": page("Payments", n(1, "button", "Fewer confirmations")),
                  "list": [search, n(1, "row", "Payments"), n(2, "row", "Advanced"), n(3, "row", "Appearance")],
                  "adv": page("Advanced", n(1, "toggle", "Technical details")),
                  "app": page("Appearance")}, "pay",
                 {("pay", "Payments"): "list", ("adv", "Advanced"): "list", ("app", "Appearance"): "list",
                  ("list", "Payments"): "pay", ("list", "Advanced"): "adv", ("list", "Appearance"): "app"})
        desk = Desktop(self.driver(f), "previous", self.logs.append)
        with unittest.mock.patch.dict(os.environ, {"REL_TRUST_BREAK": "move:g4.advanced.technical", "REL_AI": "0"}), \
                unittest.mock.patch("core.desktop.time.sleep"):
            self.assertTrue(desk.find_setting(TECHNICAL, ("advanced",), "Technical details"))
        self.assertEqual(f.cur, "adv")
        self.assertTrue(any("found under Settings › Advanced" in line for line in self.logs), self.logs)


if __name__ == "__main__":
    unittest.main()
