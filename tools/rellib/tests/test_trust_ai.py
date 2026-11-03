# SPDX-License-Identifier: Apache-2.0
"""The AI side of the trust drivers' recovery (core/recover.py, core/ailoop.py) with a scripted
fake model: a two-turn way past a screen; an invalid answer and a refused action each cost a turn;
no destructive press and no typing into a secret field; a secret screen never reaches the model;
a path that worked is stored and replayed without the model, and a replay that fails falls back to
the model, counts a fail and is rejected after two; the playbook loads with its version."""
import json
import os
import sqlite3
import sys
import tempfile
import unittest
import unittest.mock

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "drivers"))

from core import ailoop  # noqa: E402
from core import targets as tg  # noqa: E402
from core.driver import Driver  # noqa: E402
from core.recover import Recover  # noqa: E402
from core.surface import Node  # noqa: E402


def n(i, role, name, **kw):
    return Node(i=i, role=role, name=name, states=frozenset(kw.pop("states", ("enabled",))), **kw)


# A notice whose Continue shows only once its details are expanded.
SCREENS = {
    "notice": [n(0, "text", "Something new"), n(1, "button", "Details"), n(2, "button", "Send 0.01 EPIC")],
    "open": [n(0, "text", "Something new"), n(1, "button", "Details", states=("enabled", "expanded")),
             n(2, "button", "Send 0.01 EPIC"), n(3, "button", "Continue")],
    "home": [n(0, "text", "Available to spend")],
}
MOVES = {("notice", "Details"): "open", ("open", "Continue"): "home"}


class Fake:
    platform, family = "linux", "desktop"

    def __init__(self, screens=SCREENS, start="notice", moves=MOVES):
        self.screens, self.cur, self.moves = screens, start, moves
        self.pressed, self.typed, self.scrolled = [], [], []

    def tree(self):
        return list(self.screens[self.cur])

    def press(self, node):
        self.pressed.append(node.name)
        self.cur = self.moves.get((self.cur, node.name), self.cur)

    def set_text(self, node, text, secret=False):
        self.typed.append((node.name, text))

    def scroll(self, direction="down"):
        self.scrolled.append(direction)

    def key(self, name):
        pass

    def screenshot(self, path):
        return False

    def alive(self):
        return True


class Script:
    """A model that gives these answers in turn (a dict is sent as JSON, a str as it is)."""

    def __init__(self, *answers):
        self.answers, self.prompts = list(answers), []

    def __call__(self, prompt):
        self.prompts.append(prompt)
        a = self.answers.pop(0) if self.answers else {"do": "give_up"}
        return a if isinstance(a, str) else json.dumps(a)


def never(prompt):
    raise AssertionError("the model was asked")


class AiTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.out = self.tmp.name
        self.logs = []
        self.events = []
        p = unittest.mock.patch("core.record.emit", lambda kind, **f: self.events.append((kind, f)))
        p.start()
        self.addCleanup(p.stop)
        r = unittest.mock.patch("core.record.read", lambda: None)
        r.start()
        self.addCleanup(r.stop)
        e = unittest.mock.patch.dict(os.environ, {"REL_AI": "1"})
        e.start()
        self.addCleanup(e.stop)
        os.environ.pop("REL_AI_CMD", None)
        os.environ.pop("REL_AI_TURNS", None)

    def tearDown(self):
        self.tmp.cleanup()

    def rec(self, ask, surface=None):
        rec = Recover(self.out, "linux", log=self.logs.append, ask=ask)
        d = None
        if surface is not None:
            d = Driver(surface, None, rec, out=self.out, log=self.logs.append, poll=0.01)
            rec.bind(d)
        return rec, d

    def kinds(self, kind):
        return [f for k, f in self.events if k == kind]

    def paths(self):
        with open(os.path.join(self.out, "ai-paths.json")) as f:
            return json.load(f)

    # ---- the loop

    def test_two_turns_through_the_cli_command(self):
        """REL_AI_CMD as the model: turn 1 expands Details, turn 2 names Continue, which the driver presses."""
        script = os.path.join(self.out, "model.py")
        with open(script, "w") as f:
            f.write("import sys, os\nsys.stdin.read()\np = os.path.join(os.path.dirname(__file__), 'turn')\n"
                    "t = int(open(p).read()) if os.path.exists(p) else 0\nopen(p, 'w').write(str(t + 1))\n"
                    "print(['{\"do\": \"expand\", \"i\": 1, \"why\": \"shows the rest\"}',\n"
                    "       'Here: {\"do\": \"click\", \"i\": 3, \"why\": \"continues\"}'][t])\n")
        s = Fake()
        rec, d = self.rec(None, s)
        with unittest.mock.patch.dict(os.environ, {"REL_AI_CMD": "%s %s" % (sys.executable, script)}):
            node = rec.advance("the home screen", s.tree(), step="notice")
        self.assertEqual(node.name, "Continue")
        self.assertEqual(s.pressed, ["Details"])   # the expand; Continue is the caller's to press
        with open(os.path.join(self.out, "turn")) as f:
            self.assertEqual(f.read(), "2")
        self.assertEqual(rec.used[0]["kind"], "advance")

    def test_invalid_answer_is_a_wasted_turn(self):
        s = Fake(start="open")
        ask = Script("sorry, I cannot help", "", {"do": "click", "i": 3, "why": "continues"})
        rec, _ = self.rec(ask, s)
        self.assertEqual(rec.advance("the home screen", s.tree(), step="x").name, "Continue")
        self.assertEqual(len(ask.prompts), 3)
        self.assertEqual(sum("no valid JSON" in line for line in self.logs), 2)
        self.assertIn("Turn 3 of 4", ask.prompts[2])
        self.assertIn("wasted: no valid JSON", ask.prompts[2])   # the model sees its wasted turns

    def test_destructive_press_refused(self):
        s = Fake(start="open")
        ask = Script(*[{"do": "click", "i": 2, "why": "go on"}] * 3 + [{"do": "expand", "i": 2}])
        rec, _ = self.rec(ask, s)
        self.assertIsNone(rec.advance("the home screen", s.tree(), step="x"))
        self.assertEqual(len(ask.prompts), 4)   # REL_AI_TURNS default
        self.assertEqual(s.pressed, [])
        self.assertEqual(sum("reads as destructive" in line for line in self.logs), 4)
        for name in ("Confirm", "Pay invoice", "Delete wallet", "Reset", "Restore", "Forget this wallet",
                     "Remove server", "Show recovery phrase", "Accept invoice"):
            self.assertIsNotNone(ailoop.DESTRUCTIVE.search(name), name)
        self.assertIsNone(ailoop.DESTRUCTIVE.search("Not now"))

    def test_type_into_a_secret_field_refused(self):
        tree = [n(0, "text_field", "PIN"), n(1, "text_field", "Recovery phrase"), n(2, "text_field", "Server address"),
                n(3, "button", "Add")]
        for i in (0, 1):
            node, why = ailoop.check({"do": "type", "i": i, "text": "node.example:3413"}, tree)
            self.assertIsNone(node)
            self.assertIn("not a plain text field", why)
        for text in ("ghost apple river", "123456", ""):
            self.assertIsNone(ailoop.check({"do": "type", "i": 2, "text": text}, tree)[0], text)
        s = Fake({"form": tree}, "form", {})
        ask = Script({"do": "type", "i": 0, "text": "1234"}, {"do": "type", "i": 2, "text": "node.example:3413"},
                     {"do": "click", "i": 3})
        rec, _ = self.rec(ask, s)
        self.assertEqual(rec.advance("the server added", s.tree(), step="add").name, "Add")
        self.assertEqual(s.typed, [("Server address", "node.example:3413")])
        self.assertTrue(any("type into text_field 'PIN' refused" in line for line in self.logs))

    def test_secret_screen_never_asks(self):
        ask = unittest.mock.Mock()
        rec, _ = self.rec(ask)
        pw = [n(0, "text_field", "Password", value="x", states=("enabled", "password")), n(1, "button", "Unlock")]
        phrase = [n(0, "text", " ".join(["abandon"] * 12)), n(1, "button", "Next")]
        for tree in (pw, phrase):
            self.assertIsNone(rec.advance("home", tree, step="lock"))
            self.assertIsNone(rec.pick(tg.Target(id="g4.unlock.submit"), tree, step="lock", texts=["unlock"]))
        ask.assert_not_called()
        # the screen turning secret after an action stops the loop before the next turn
        s = Fake({"a": [n(0, "button", "More")], "b": pw}, "a", {("a", "More"): "b"})
        ask = Script({"do": "expand", "i": 0})
        rec, _ = self.rec(ask, s)
        self.assertIsNone(rec.advance("home", s.tree(), step="y"))
        self.assertEqual(len(ask.prompts), 1)

    def test_pick_finds_the_target_after_an_expand(self):
        """A pick: expanding a section shows the target under its id, which the driver's own lookup sees."""
        t = tg.Target(id="g4.server.use", role="button", names=("Use node.example",))
        s = Fake({"a": [n(0, "button", "Node")], "b": [n(0, "button", "Node"), n(1, "button", "Pick", id="g4.server.use")]},
                 "a", {("a", "Node"): "b"})
        ask = Script({"do": "expand", "i": 0, "pb": "section-button-noop"})
        rec, _ = self.rec(ask, s)
        self.assertEqual(rec.pick(t, s.tree(), step="use", texts=["use node.example"]).id, "g4.server.use")
        self.assertEqual(len(ask.prompts), 1)
        self.assertIn("[section-button-noop]", ask.prompts[0])   # the playbook slice for linux
        rec.reached("use")
        self.assertEqual(self.kinds("playbook.propose"), [])     # it followed a playbook entry

    # ---- the cache

    def test_path_stored_then_replayed_without_the_model(self):
        s = Fake()
        rec, _ = self.rec(Script({"do": "expand", "i": 1}, {"do": "click", "i": 3}), s)
        node = rec.advance("the home screen", s.tree(), step="notice")
        s.press(node)
        rec.reached("notice")
        put = self.kinds("aipath.put")
        self.assertEqual(len(put), 1)
        self.assertEqual([a["do"] for a in put[0]["actions"]], ["expand", "click"])
        self.assertEqual(put[0]["platform"], "linux")
        self.assertTrue(put[0]["key"].startswith("linux|the home screen|"))
        prop = self.kinds("playbook.propose")
        self.assertEqual(len(prop), 1)
        self.assertIn("expand button 'details' → click button 'continue'", prop[0]["fix"])
        self.assertEqual(self.paths()[put[0]["key"]]["state"], "new")

        s2 = Fake()   # the next lane, same screen
        rec2, _ = self.rec(never, s2)
        node = rec2.advance("the home screen", s2.tree(), step="notice")
        self.assertEqual(node.name, "Continue")
        self.assertEqual(s2.pressed, ["Details"])
        rec2.reached("notice")
        self.assertEqual(len(self.kinds("aipath.hit")), 1)
        self.assertEqual(self.paths()[put[0]["key"]]["hits"], 1)
        self.assertIn("replay", rec2.used[0]["why"])

    def test_replay_from_the_db(self):
        s = Fake()
        key = ailoop.path_key("linux", "the home screen", ailoop.screen_sig(s.tree()))
        db = sqlite3.connect(":memory:")
        self.addCleanup(db.close)
        db.execute("CREATE TABLE ai_paths (key TEXT, actions TEXT, state TEXT, hits INT, fails INT)")
        db.execute("INSERT INTO ai_paths VALUES (?, ?, 'promoted', 3, 0)", (key, json.dumps([
            {"do": "expand", "node": {"role": "button", "id": None, "name": "details"}},
            {"do": "click", "node": {"role": "button", "id": None, "name": "continue"}}])))
        rec, _ = self.rec(never, s)
        with unittest.mock.patch("core.record.read", lambda: _NoClose(db)):
            self.assertEqual(rec.advance("the home screen", s.tree(), step="n").name, "Continue")
            self.assertIn("d.press(T('g4.TODO', role='button', names=('continue',)), step='the home screen'),",
                          ailoop.promote_report())

    def test_replay_fail_falls_back_and_counts(self):
        s = Fake(start="open")
        key = ailoop.path_key("linux", "the home screen", ailoop.screen_sig(s.tree()))
        with open(os.path.join(self.out, "ai-paths.json"), "w") as f:
            json.dump({key: {"actions": [{"do": "click", "node": {"role": "button", "id": None, "name": "go on"}}],
                             "state": "reviewed", "hits": 0, "fails": 0}}, f)
        for run in (1, 2):
            ask = Script({"do": "click", "i": 3})
            rec, _ = self.rec(ask, Fake(start="open"))
            self.assertEqual(rec.advance("the home screen", s.tree(), step="n").name, "Continue")
            self.assertEqual(len(ask.prompts), 1)
            self.assertEqual(self.paths()[key]["fails"], run)
        self.assertEqual(self.paths()[key]["state"], "rejected")
        self.assertEqual(len(self.kinds("aipath.fail")), 2)
        rec, _ = self.rec(Script({"do": "click", "i": 3}), Fake(start="open"))
        rec.advance("the home screen", s.tree(), step="n")
        self.assertEqual(len(self.kinds("aipath.fail")), 2)   # rejected: not replayed again

    def test_replay_whose_rule_did_not_hold_counts_a_fail(self):
        """The replay named a node, the driver pressed it, and the step asked again: a fail, then the model."""
        s = Fake(start="open")
        key = ailoop.path_key("linux", "the home screen", ailoop.screen_sig(s.tree()))
        with open(os.path.join(self.out, "ai-paths.json"), "w") as f:
            json.dump({key: {"actions": [{"do": "click", "node": {"role": "button", "id": None, "name": "details"}}],
                             "state": "new", "hits": 0, "fails": 0}}, f)
        ask = Script({"do": "click", "i": 3})
        rec, _ = self.rec(ask, s)
        self.assertEqual(rec.advance("the home screen", s.tree(), step="n").name, "Details")
        self.assertEqual(rec.advance("the home screen", s.tree(), step="n").name, "Continue")
        self.assertEqual(self.paths()[key]["fails"], 1)
        self.assertEqual(len(ask.prompts), 1)

    def test_screen_signature_ignores_values_order_and_numbers(self):
        a = [n(0, "button", "Use node.example, 812 ms"), n(1, "text_field", "Server", value="a"), n(2, "text", "Balance 1.0")]
        b = [n(5, "text", "Balance 2.0"), n(3, "text_field", "Server", value="b"), n(4, "button", "Use node.example, 93 ms")]
        self.assertEqual(ailoop.screen_sig(a), ailoop.screen_sig(b))
        self.assertNotEqual(ailoop.screen_sig(a), ailoop.screen_sig(a + [n(6, "button", "Close")]))

    # ---- the playbook

    def test_playbook_loads_with_its_version(self):
        version, entries = ailoop.load_playbook()
        self.assertEqual(version, 1)
        self.assertGreaterEqual(len(entries), 10)
        self.assertEqual(len({e["key"] for e in entries}), len(entries))
        for e in entries:
            self.assertTrue(all(e.get(k) for k in ("situation", "fix", "platforms", "source")), e["key"])
        keys = {e["key"] for e in ailoop.for_platform(entries, "android")}
        self.assertIn("first-run-tour", keys)
        self.assertNotIn("node-already-active", keys)
        self.assertEqual(Recover(self.out, "linux").playbook_version, 1)

    def test_real_cli_flags(self):
        """No tools and one turn: the answer cannot be cut by 'Reached max turns'."""
        with unittest.mock.patch("subprocess.run") as run:
            run.return_value = unittest.mock.Mock(returncode=0, stdout='{"do":"give_up"}', stderr="")
            from core import recover
            recover._ask("p", 5)
        argv = run.call_args[0][0]
        self.assertEqual(argv[argv.index("--tools") + 1], "")
        self.assertEqual(argv[argv.index("--max-turns") + 1], "1")
        self.assertIn("--system-prompt", argv)


class _NoClose:
    """An in-memory DB that survives the caller's close()."""

    def __init__(self, db):
        self.db = db

    def execute(self, *a):
        return self.db.execute(*a)

    def close(self):
        pass


if __name__ == "__main__":
    unittest.main()
