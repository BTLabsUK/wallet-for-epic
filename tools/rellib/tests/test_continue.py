# SPDX-License-Identifier: Apache-2.0
"""tools/rel continue (core/hold.py): a lane parks at a harness fault, the fix is reloaded into it, and it
goes on from the failed action. Here the real Lane runs on a fake app, with a driver module that a
second thread changes while the lane waits, and tools/rel runs a lane that parks."""
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import time
import types
import unittest
from unittest import mock

from test_repeats import GOOD, Repeats
from rellib import repeats

HERE = os.path.dirname(os.path.abspath(__file__))
DRV = os.path.join(os.path.dirname(HERE), "drivers")
sys.path.insert(0, DRV)

from core import checks, hold  # noqa: E402
from core import lane as core_lane  # noqa: E402
from core.driver import _Watched  # noqa: E402
from core.faults import Diverged, HarnessFault, HarnessGone, ProductFault  # noqa: E402

KEY = "trust-android-tor"


def read(path):
    try:
        return json.loads(pathlib.Path(path).read_text())
    except (OSError, ValueError):
        return {}


class App:
    """The app: what a press did stays done, and only this object knows how many times."""

    def __init__(self):
        self.presses, self.reads, self.screen = [], 0, ["ready"]

    def press(self, what):
        self.presses.append(what)
        return "pressed " + what

    def tree(self):
        self.reads += 1
        return list(self.screen)


class Plat(core_lane.Platform):
    name, variant = "linux", "tor"

    def __init__(self):
        self.up, self.installs = True, 0

    def alive(self):
        return self.up

    def install_previous(self):
        self.installs += 1
        return "installed"


class Funder:
    def __init__(self):
        self.sends = []
        self.slate = self.boom = None

    def send(self, to, amount):
        self.sends.append((to, amount))
        if self.boom:
            raise self.boom
        self.slate = "slate-%d" % len(self.sends)
        return self.slate


class Kit(unittest.TestCase):
    """A lane in this process on a fake app, and a module of steps a fix can change."""

    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix="relcont-", dir=os.environ.get("TMPDIR"))
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)
        self.addCleanup(hold.uninstall)
        self.root = os.path.join(self.tmp, "drivers")
        self.out = os.path.join(self.tmp, "out")
        os.makedirs(self.root)
        os.makedirs(self.out)
        sys.path.insert(0, self.root)
        self.addCleanup(sys.path.remove, self.root)
        self.addCleanup(sys.modules.pop, "steps", None)
        self.app, self.p, self.funder, self.said = App(), Plat(), Funder(), []
        self.fixes, self.answers = [], []

    def steps(self, text):
        path = os.path.join(self.root, "steps.py")
        pathlib.Path(path).write_text(text)
        # A rewrite within the same second and of the same size must still count: reload reads the source
        return path

    def lane(self, code, limit=60, funds=False):
        self.steps(code)
        sys.modules.pop("steps", None)
        import steps
        self.mod = steps
        lane = core_lane.Lane(self.p, None, checks, out=self.out, log=self.said.append, required=[], funds=funds, p=self.funder)
        with mock.patch.dict(os.environ, {"REL_TRUST_PARK": str(limit)}):
            self.assertTrue(hold.install(lane, Diverged))
        hold._held.root = self.root
        lane.s = _Watched(None, self.app)
        return lane

    def fix(self, *texts):
        """A second person: each park gets the next text, on disk, and tools/rel's question."""
        self.fixes = list(texts)
        self.person = threading.Thread(target=self._person, daemon=True)
        self.person.start()
        self.addCleanup(self.person.join, 5)

    def _person(self):
        parked = os.path.join(self.out, hold.PARKED)
        ask = os.path.join(self.out, hold.CONTINUE)
        done = os.path.join(self.out, hold.ANSWER)
        for n, text in enumerate(self.fixes):
            end = time.monotonic() + 20
            while not os.path.exists(parked) or os.path.exists(ask):
                if time.monotonic() > end:
                    return
                time.sleep(0.02)
            self.parks.append(read(parked))
            if text is None:
                data = {"token": n, "stop": True}
            else:
                self.steps(text)
                data = {"token": n, "driver": {"commit": "c%d" % n}}
            with open(ask + ".tmp", "w") as f:
                json.dump(data, f)
            os.replace(ask + ".tmp", ask)
            while time.monotonic() < end:
                a = read(done)
                if a.get("token") == n:
                    self.answers.append(a)
                    break
                time.sleep(0.02)

    parks = None

    def run(self, result=None):
        self.parks = []
        return super().run(result)


BROKEN = """
from core.faults import HarnessFault

def walk(lane):
    lane.s.press("a")
    lane.s.press("b")
    if "technical" not in lane.s.tree():
        raise HarnessFault("find-g4.advanced.technical", "no row")
    lane.s.press("technical")
    lane.s.press("c")
    return "walked"
"""
FIXED = BROKEN.replace('"technical" not in lane.s.tree()', '"ready" not in lane.s.tree()')


class GoesOn(Kit):
    def test_a_fix_goes_on_from_the_failed_action(self):
        lane = self.lane(BROKEN)
        self.fix(FIXED)
        self.assertEqual(lane.run_phase("settings-ui-before", lambda: self.mod.walk(lane)), "walked")
        self.assertEqual(self.app.presses, ["a", "b", "technical", "c"])  # a and b once, though the phase ran twice
        self.assertEqual(lane.done, ["settings-ui-before"])
        self.person.join(5)
        self.assertEqual(self.parks[0]["step"], "find-g4.advanced.technical")
        self.assertEqual(self.parks[0]["acts"], 2)
        self.assertEqual(self.answers[0]["acts"], 2)
        self.assertEqual(lane.details["continues"][0]["step"], "find-g4.advanced.technical")
        self.assertFalse(os.path.exists(os.path.join(self.out, hold.PARKED)))

    def test_the_failed_action_itself_runs_live(self):
        code = BROKEN.replace('    lane.s.press("c")\n', '    lane.s.press("c")\n    raise HarnessFault("late", "x")\n')
        lane = self.lane(code)
        self.app.screen = ["technical"]
        self.fix(code.replace('    raise HarnessFault("late", "x")\n', ""))
        lane.run_phase("settings-ui-before", lambda: self.mod.walk(lane))
        self.assertEqual(self.app.presses, ["a", "b", "technical", "c"])

    def test_a_fault_in_prepare_ends_the_lane(self):
        lane = self.lane(BROKEN)
        with self.assertRaises(HarnessFault):
            hold.guard(lane, "prepare", lambda: self.mod.walk(lane))()
        self.assertFalse(os.path.exists(os.path.join(self.out, hold.PARKED)))

    def test_a_bug_in_the_driver_parks_like_a_fault(self):
        code = BROKEN.replace('lane.s.press("technical")', 'lane.s.prress("technical")')
        lane = self.lane(code)
        self.app.screen = ["technical"]
        self.fix(BROKEN.replace('"technical" not in', '"nothing" in'))
        self.assertEqual(lane.run_phase("address", lambda: self.mod.walk(lane)), "walked")
        self.assertEqual(self.app.presses, ["a", "b", "technical", "c"])

    def test_a_press_that_raised_runs_again(self):
        code = """
def walk(lane):
    lane.s.press("a")
    lane.s.press(lane.missing)
"""
        lane = self.lane(code)
        self.fix(code.replace("lane.missing", '"b"'))
        lane.run_phase("address", lambda: self.mod.walk(lane))
        self.assertEqual(self.app.presses, ["a", "b"])

    def test_a_second_fault_parks_again_and_keeps_all_that_was_done(self):
        code = BROKEN.replace('    lane.s.press("c")\n', '    lane.s.press("c")\n    if "z" not in lane.s.tree():\n'
                                                          '        raise HarnessFault("find-z", "no z")\n    lane.s.press("z")\n')
        lane = self.lane(code)
        one = code.replace('"technical" not in', '"nothing" in')
        two = one.replace('"z" not in', '"nothing" in')
        self.fix(one, two)
        lane.run_phase("settings-ui-before", lambda: self.mod.walk(lane))
        self.assertEqual(self.app.presses, ["a", "b", "technical", "c", "z"])
        self.assertEqual([p["step"] for p in self.parks], ["find-g4.advanced.technical", "find-z"])
        self.assertEqual(len(lane.details["continues"]), 2)

    def test_a_fix_that_does_not_load_stays_parked(self):
        lane = self.lane(BROKEN)
        self.fix("def walk(lane:\n", FIXED)
        self.assertEqual(lane.run_phase("address", lambda: self.mod.walk(lane)), "walked")
        self.person.join(5)
        self.assertFalse(self.answers[0]["ok"])
        self.assertIn("SyntaxError", self.answers[0]["note"])
        self.assertTrue(self.answers[1]["ok"])
        self.assertEqual(self.app.presses, ["a", "b", "technical", "c"])

    def test_a_kept_phase_parks_before_it_is_kept(self):
        lane = self.lane(BROKEN)
        self.fix(FIXED)
        self.assertEqual(lane.try_phase("settings-ui-before", lambda: self.mod.walk(lane)), "walked")
        self.assertEqual(lane.kept, [])
        self.assertEqual(self.app.presses, ["a", "b", "technical", "c"])

    def test_a_soft_part_inside_a_phase_goes_back_up_to_the_phase(self):
        lane = self.lane(BROKEN)
        self.fix(FIXED)

        def phase():
            lane.s.press("first")
            lane.soft("part", lambda: self.mod.walk(lane))
            lane.s.press("last")
        lane.run_phase("settings-ui-after", phase)
        self.assertEqual(self.app.presses, ["first", "a", "b", "technical", "c", "last"])
        self.assertEqual(lane.kept, [])

    def test_a_platform_call_is_one_action(self):
        code = """
def walk(lane):
    lane.p.install_previous()
    lane.s.press(lane.missing)
"""
        lane = self.lane(code)
        self.fix(code.replace("lane.missing", '"a"'))
        lane.run_phase("address", lambda: self.mod.walk(lane))
        self.assertEqual(self.p.installs, 1)
        self.assertEqual(self.app.presses, ["a"])

    def test_a_platform_call_that_faulted_runs_whole_again(self):
        fails = [True]
        real = self.p.install_previous

        def install():
            real()
            if fails.pop() if fails else False:
                raise HarnessFault("install", "the file was busy")
            return "ok"
        self.p.install_previous = install
        code = """
def walk(lane):
    lane.s.press("a")
    lane.p.install_previous()
"""
        lane = self.lane(code)
        self.fix(code + "\n# fixed\n")
        lane.run_phase("address", lambda: self.mod.walk(lane))
        self.assertEqual(self.p.installs, 2)
        self.assertEqual(self.app.presses, ["a"])


class Replays(Kit):
    def test_a_wait_takes_no_time_the_second_time_and_a_deadline_ignores_the_park(self):
        code = """
import time

def walk(lane):
    end = time.monotonic() + 30
    n = 0
    while "go" not in lane.s.tree():
        time.sleep(0.2)
        if time.monotonic() > end:
            raise AssertionError("waited out")
        n += 1
        if n == 3:
            lane.s.screen = None
    lane.s.press("a")
    lane.again = lane.missing
    if time.monotonic() > end:
        raise AssertionError("the park counted")
    lane.s.press("b")
"""
        lane = self.lane(code)
        polls = [["wait"], ["wait"], ["go"]]
        self.app.tree = lambda: polls.pop(0) if polls else ["go"]
        self.fix(code.replace("lane.again = lane.missing", "lane.again = 1"))
        began = time.monotonic()
        lane.run_phase("address", lambda: self.mod.walk(lane))
        self.assertEqual(self.app.presses, ["a", "b"])
        self.assertLess(time.monotonic() - began, 4)

    def test_a_loop_past_the_record_goes_live(self):
        code = """
def walk(lane):
    lane.s.press("a")
    while "wait" in lane.s.tree():
        lane.polls = getattr(lane, "polls", 0) + 1
        if lane.polls > 6000:
            raise AssertionError("a replay that never ends")
    lane.s.press("b")
"""
        lane = self.lane(code.replace('lane.s.press("b")', "lane.missing"))
        self.app.screen = ["wait"]
        reads = [["wait"], ["go"]]
        self.app.tree = lambda: reads.pop(0) if reads else ["go"]
        self.fix(code.replace('"wait" in', '"wait" in'))
        lane.run_phase("address", lambda: self.mod.walk(lane))
        self.assertEqual(self.app.presses, ["a", "b"])

    def test_a_changed_path_goes_live_on_the_screen_of_the_park(self):
        lane = self.lane(BROKEN)
        self.fix(FIXED.replace('lane.s.press("b")', 'lane.s.press("other")'))
        lane.run_phase("settings-ui-before", lambda: self.mod.walk(lane))
        self.assertEqual(self.app.presses, ["a", "b", "other", "technical", "c"])
        self.assertTrue(any("left the recorded path" in s for s in self.said))

    def test_a_changed_path_in_a_funds_phase_ends_the_lane(self):
        code = BROKEN.replace('lane.s.press("b")', 'lane.funder.send("w", 1)')
        lane = self.lane(code)
        self.fix(code.replace('lane.funder.send("w", 1)', 'lane.funder.send("w", 2)'))
        with self.assertRaises(Diverged) as e:
            lane.run_phase("pay-send", lambda: self.mod.walk(lane))
        self.assertIn("could pay twice", str(e.exception.what))
        self.assertEqual(self.funder.sends, [("w", 1)])

    def test_a_changed_path_before_a_send_in_any_phase_ends_the_lane(self):
        code = BROKEN.replace('lane.s.press("a")', 'lane.s.press("a")\n    lane.funder.send("w", 1)')
        lane = self.lane(code)
        self.fix(code.replace('lane.s.press("a")', 'lane.s.press("z")'))
        with self.assertRaises(Diverged):
            lane.run_phase("address", lambda: self.mod.walk(lane))
        self.assertEqual(self.funder.sends, [("w", 1)])

    def test_an_app_press_that_pays_in_an_invoice_or_link_phase_ends_the_lane(self):
        for phase in ("pair-invoice", "link-end"):
            with self.subTest(phase):
                lane = self.lane(BROKEN)
                self.fix(BROKEN.replace('lane.s.press("a")', 'lane.s.press("z")'))
                with self.assertRaises(Diverged):
                    lane.run_phase(phase, lambda: self.mod.walk(lane))
                self.assertNotIn("z", self.app.presses)
                self.person.join(5)
                self.app.presses.clear()
                hold.uninstall()

    def test_a_catch_all_cannot_carry_a_refused_replay_on_to_the_next_send(self):
        code = """
from core.faults import Fault, HarnessFault

def walk(lane):
    try:
        lane.s.press("a")
    except Exception as e:
        lane.said = e
    lane.funder.send("w", 1)
    if "technical" not in lane.s.tree():
        raise HarnessFault("find-x", "no row")
"""
        lane = self.lane(code)
        self.fix(code.replace('lane.s.press("a")', 'lane.s.press("z")'))
        with self.assertRaises(Diverged):
            lane.run_phase("pay-send", lambda: self.mod.walk(lane))
        self.assertIsInstance(lane.said, Diverged)
        self.assertEqual(self.funder.sends, [("w", 1)])

    def test_a_refused_replay_swallowed_to_the_end_of_the_phase_still_ends_the_lane(self):
        lane = self.lane(BROKEN)
        self.fix('def walk(lane):\n    try:\n        lane.s.press("z")\n    except Exception:\n        pass\n')
        with self.assertRaises(Diverged):
            lane.run_phase("pay-send", lambda: self.mod.walk(lane))

    def test_a_refused_replay_swallowed_then_a_fault_does_not_park_again(self):
        fixed = """
from core.faults import Fault, HarnessFault

def walk(lane):
    try:
        lane.s.press("z")
    except Fault:
        raise HarnessFault("tor", "the fallback failed too")
"""
        lane = self.lane(BROKEN)
        self.fix(fixed)
        with self.assertRaises(Diverged):
            lane.run_phase("pay-send", lambda: self.mod.walk(lane))
        self.assertEqual(len(self.parks), 1)

    def test_a_funds_phase_that_ends_short_of_the_record_ends_the_lane(self):
        lane = self.lane(BROKEN)
        self.fix('def walk(lane):\n    lane.s.press("a")\n')
        with self.assertRaises(Diverged) as e:
            lane.run_phase("pay-send", lambda: self.mod.walk(lane))
        self.assertIn("not reached", str(e.exception.what))

    def test_elsewhere_a_phase_may_end_short_of_the_record(self):
        lane = self.lane(BROKEN)
        self.fix('def walk(lane):\n    lane.s.press("a")\n    return "short"\n')
        self.assertEqual(lane.run_phase("settings", lambda: self.mod.walk(lane)), "short")
        self.assertTrue(any("not reached" in s for s in self.said))

    def test_a_wallet_that_came_later_replays_with_the_others(self):
        code = """
from core.faults import HarnessFault

def walk(lane):
    lane.w.p.digest("before")
    lane.s.press("a")
    if "technical" not in lane.s.tree():
        raise HarnessFault("find-x", "no row")
    return lane.w.p.digest("after")
"""
        lane = self.lane(code)
        calls = []
        lane.w = types.SimpleNamespace(p=types.SimpleNamespace(digest=lambda tag: calls.append(tag) or len(calls)))
        hold.join(lane.w, "a2")
        self.fix(code.replace('"technical" not in lane.s.tree()', '"ready" not in lane.s.tree()'))
        self.assertEqual(lane.run_phase("link-end", lambda: self.mod.walk(lane)), 2)
        self.assertEqual(calls, ["before", "after"])

    def test_a2_joins_the_journal_in_link_up(self):
        class Up(Exception):
            pass

        def restore(_w, put):
            raise Up()
        from linux import tx_lane
        self.lane(BROKEN)
        plat = types.SimpleNamespace()
        tx = types.SimpleNamespace(w={"a": types.SimpleNamespace(seed="s")}, p=types.SimpleNamespace(add_a2=lambda: plat),
                                   _restore_one=restore)
        with self.assertRaises(Up):
            tx_lane.TxLane._link_up(tx)
        self.assertIsInstance(tx.w["a2"].p, hold.Held)
        self.assertIs(tx.w["a2"].p._t, plat)
        self.assertEqual(tx.w["a2"].p._tag, "p:a2")

    def test_coins_go_once_and_what_the_send_left_comes_back(self):
        code = """
from core.faults import HarnessFault

def walk(lane):
    slate = lane.funder.send("w", 1)
    lane.seen = (slate, lane.funder.slate)
    lane.s.press(slate)
    if lane.s.tree() == ["ready"]:
        raise HarnessFault("find-pending", "no row")
    lane.s.press("done")
"""
        lane = self.lane(code)
        self.fix(code.replace('== ["ready"]', '== ["no"]'))
        lane.run_phase("pay-send", lambda: self.mod.walk(lane))
        self.assertEqual(self.funder.sends, [("w", 1)])
        self.assertEqual(self.app.presses, ["slate-1", "done"])
        self.assertEqual(lane.seen, ("slate-1", "slate-1"))

    def test_the_funders_exchange_is_not_opened_twice(self):
        opened = []

        class Service(Funder):
            def exchange(self, what, wait_s=None):
                import contextlib

                @contextlib.contextmanager
                def go():
                    opened.append(what)
                    yield self
                return go()
        self.funder = Service()
        code = """
def walk(lane):
    with lane.funder.exchange("receive") as x:
        x.send("w", 1)
    lane.s.press(lane.missing)
"""
        lane = self.lane(code)
        self.fix(code.replace("lane.missing", '"a"'))
        lane.run_phase("pay-receive", lambda: self.mod.walk(lane))
        self.assertEqual(opened, ["receive"])
        self.assertEqual(self.funder.sends, [("w", 1)])

    def test_a_generated_value_stays_the_same(self):
        code = """
import secrets
from core import hold

def walk(lane):
    word = hold.value("password", lambda: secrets.token_hex(8))
    lane.s.press(word)
    if lane.s.tree() == ["ready"]:
        raise HarnessFault
    lane.s.press(word)
"""
        lane = self.lane(code.replace("raise HarnessFault", 'raise ValueError("no")'))
        self.fix(code.replace('== ["ready"]', '== ["no"]'))
        lane.run_phase("address", lambda: self.mod.walk(lane))
        self.assertEqual(self.app.presses[0], self.app.presses[1])

    def test_the_lane_is_as_it_was_when_the_phase_began(self):
        code = """
def walk(lane):
    lane.results["ran"] = lane.results.get("ran", 0) + 1
    lane.touched.append("x")
    lane.s.press("a")
    lane.s.press(lane.missing)
"""
        lane = self.lane(code)
        self.fix(code.replace("lane.missing", '"b"'))
        lane.run_phase("address", lambda: self.mod.walk(lane))
        self.assertEqual(lane.results["ran"], 1)
        self.assertEqual(lane.touched, ["x"])

    def test_nothing_is_said_twice(self):
        code = """
def walk(lane):
    lane.log("once")
    lane.s.press("a")
    lane.s.press(lane.missing)
"""
        lane = self.lane(code)
        self.fix(code.replace("lane.missing", '"b"'))
        lane.run_phase("address", lambda: self.mod.walk(lane))
        self.assertEqual(self.said.count("once"), 1)

    def test_a_fault_in_the_replay_keeps_the_whole_record(self):
        lane = self.lane(BROKEN)
        one = FIXED.replace('    lane.s.press("a")\n', '    lane.s.press("a")\n    lane.missing\n')
        self.fix(one, FIXED)
        lane.run_phase("settings-ui-before", lambda: self.mod.walk(lane))
        self.assertEqual(self.app.presses, ["a", "b", "technical", "c"])


class Refuses(Kit):
    def faulting(self, boom, limit=60, phase="address"):
        lane = self.lane("def walk(lane):\n    lane.s.press('a')\n    raise lane.boom\n", limit)
        lane.boom = boom
        return lane, lambda: lane.run_phase(phase, lambda: self.mod.walk(lane))

    def assert_no_park(self, boom):
        lane, go = self.faulting(boom)
        with self.assertRaises(type(boom)):
            go()
        self.assertEqual(self.parks, [])
        self.assertFalse(any(s.startswith("PARKED") for s in self.said))

    def test_a_send_on_the_funder_that_raised_does_not_park(self):
        code = """
from core.faults import HarnessFault

def walk(lane):
    lane.s.press("a")
    try:
        lane.funder.send("w", 1)
    except OSError as e:
        raise HarnessFault("fund", "P did not answer: %s" % e)
"""
        lane = self.lane(code)
        self.funder.boom = TimeoutError("timed out")
        with self.assertRaises(HarnessFault):
            lane.run_phase("fund", lambda: self.mod.walk(lane))
        self.assertEqual(self.parks, [])
        self.assertEqual(self.funder.sends, [("w", 1)])
        self.assertTrue(any("may have gone" in s for s in self.said))

    def test_the_same_when_the_driver_lets_it_through(self):
        lane = self.lane('def walk(lane):\n    lane.funder.send("w", 1)\n')
        self.funder.boom = TimeoutError("timed out")
        with self.assertRaises(Exception):
            lane.run_phase("fund", lambda: self.mod.walk(lane))
        self.assertEqual(self.parks, [])

    def test_a_park_whose_file_was_taken_ends(self):
        lane, go = self.faulting(HarnessFault("x", "no row"))
        park = os.path.join(self.out, hold.PARKED)

        def take():
            end = time.monotonic() + 20
            while not os.path.exists(park) and time.monotonic() < end:
                time.sleep(0.02)
            os.remove(park)
        t = threading.Thread(target=take, daemon=True)
        t.start()
        with self.assertRaises(HarnessFault):
            go()
        t.join(5)
        self.assertTrue(any("a new attempt took this stage" in s for s in self.said))

    def test_a_product_fault_does_not_park(self):
        self.assert_no_park(ProductFault("find-x", "the app said no"))

    def test_harness_gone_does_not_park(self):
        lane, go = self.faulting(HarnessGone("rig", "gone"))
        self.p.recover = lambda: None
        with self.assertRaises(HarnessGone):
            go()
        self.assertFalse(any(s.startswith("PARKED") for s in self.said))

    def test_a_dead_app_does_not_park(self):
        lane, go = self.faulting(HarnessFault("find-x", "no row"))
        self.p.up = False
        with self.assertRaises(HarnessFault):
            go()
        self.assertFalse(any(s.startswith("PARKED") for s in self.said))

    def test_a_park_nobody_answers_ends_as_the_fault_would(self):
        lane, go = self.faulting(HarnessFault("find-x", "no row"), limit=1)
        with self.assertRaises(HarnessFault):
            go()
        self.assertTrue(any("PARK over" in s for s in self.said))
        self.assertFalse(os.path.exists(os.path.join(self.out, hold.PARKED)))
        with self.assertRaises(HarnessFault):  # and no later fault waits on anybody
            go()

    def test_stop_ends_the_park_and_the_fault_takes_its_way(self):
        lane, go = self.faulting(HarnessFault("find-x", "no row"))
        self.fix(None)
        with self.assertRaises(HarnessFault):
            go()
        self.assertEqual(self.app.presses, ["a"])

    def test_a_probe_never_parks(self):
        lane = self.lane("x = 1\n")
        hold.uninstall()
        lane.probe = {"step": "a", "phase": "b"}
        with mock.patch.dict(os.environ, {"REL_TRUST_PARK": "60"}):
            self.assertFalse(hold.install(lane, Diverged))

    def test_off_without_the_word_from_tools_rel(self):
        lane = self.lane("x = 1\n")
        hold.uninstall()
        os.environ.pop("REL_TRUST_PARK", None)
        self.assertFalse(hold.install(lane, Diverged))
        fn = lambda: 1  # noqa: E731
        self.assertIs(hold.guard(lane, "x", fn), fn)


class Reload(Kit):
    def module(self, text):
        self.steps(text)
        sys.modules.pop("steps", None)
        import steps
        return steps

    def reload(self, text):
        self.steps(text)
        return hold.reload_drivers(self.root)

    def test_classes_and_functions_keep_who_they_are(self):
        code = """
class Base:
    def name(self):
        return "base"

class Fault(Exception):
    pass

class One(Base):
    limit = 1
    def name(self):
        return "one+" + super().name()
    def gone(self):
        return 1
    @staticmethod
    def st():
        return "s1"
    @property
    def prop(self):
        return "p1"

def top():
    return "t1"

def helper():
    return top()
"""
        m = self.module(code)
        one, cls, fault, top, bound = m.One(), m.One, m.Fault, m.top, m.One().name
        self.assertEqual(self.reload(code.replace('"t1"', '"t2"').replace('"one+"', '"two+"').replace('"s1"', '"s2"')
                                     .replace('"p1"', '"p2"').replace("limit = 1", "limit = 2")
                                     .replace("    def gone(self):\n        return 1\n", "    def fresh(self):\n        return 3\n")), 1)
        self.assertIs(m.One, cls)
        self.assertIs(m.Fault, fault)
        self.assertIs(m.top, top)
        self.assertEqual(top(), "t2")
        self.assertEqual(m.helper(), "t2")
        self.assertEqual(bound(), "two+base")
        self.assertEqual(one.name(), "two+base")
        self.assertEqual(one.fresh(), 3)
        self.assertFalse(hasattr(one, "gone"))
        self.assertEqual((one.st(), one.prop, one.limit), ("s2", "p2", 2))

    def test_a_new_base_class_reaches_a_live_instance(self):
        code = "class A:\n    def go(self):\n        return 'a'\n\nclass B(A):\n    pass\n"
        m = self.module(code)
        b = m.B()
        self.reload(code.replace("class B(A):\n    pass\n", "class C(A):\n    def go(self):\n        return 'c'\n\nclass B(C):\n    pass\n"))
        self.assertEqual(b.go(), "c")

    def test_a_decorated_method_takes_the_new_code(self):
        code = """
import functools

def deco(fn):
    @functools.wraps(fn)
    def inner(*a):
        return fn(*a)
    return inner

class A:
    @deco
    def go(self):
        return 1
"""
        m = self.module(code)
        a = m.A()
        self.reload(code.replace("return 1", "return 2"))
        self.assertEqual(a.go(), 2)

    def test_a_module_that_does_not_load_changes_nothing(self):
        m = self.module("value = 1\ndef f():\n    return 1\n")
        with self.assertRaises(ZeroDivisionError):
            self.reload("value = 2\n1 / 0\ndef f():\n    return 2\n")
        self.assertEqual((m.value, m.f()), (1, 1))

    def test_a_new_target_shows_up_in_a_cache_built_from_a_file(self):
        code = "_REG = None\ndef reg():\n    global _REG\n    if _REG is None:\n        _REG = {'a': 1}\n    return _REG\n"
        m = self.module(code)
        m.reg()
        self.reload(code.replace("{'a': 1}", "{'b': 2}"))
        self.assertEqual(m.reg(), {"b": 2})


ENTRY = """
import os, sys
path = sys.argv[1]
sys.path[:0] = [os.path.dirname(os.path.dirname(path)), os.path.dirname(path)]
sys.path.insert(2, os.path.join(os.path.dirname(os.path.dirname(path)), "linux"))
if len(sys.argv) > 2:
    main = sys.modules["__main__"]
    main.__file__ = path
    ns = main.__dict__
    ns["__name__"] = "not-yet"
    exec(compile(open(path).read(), path, "exec"), ns)
    ns["__name__"] = "__main__"
else:
    import importlib.util
    spec = importlib.util.spec_from_file_location("the_lane", path)
    m = importlib.util.module_from_spec(spec)
    sys.modules["the_lane"] = m
    spec.loader.exec_module(m)
from core import hold, faults, lane, driver
fault, lanes, drv = faults.HarnessFault, lane.Lane, driver.Driver
n = hold.reload_drivers()
n2 = hold.reload_drivers()
assert faults.HarnessFault is fault and lane.Lane is lanes and driver.Driver is drv
assert issubclass(faults.Diverged, fault)
print(n, n2)
"""


class RealDrivers(unittest.TestCase):
    """The reload on the kit's own modules, each lane as the process tools/rel starts."""

    def entry(self, rel, *main):
        r = subprocess.run([sys.executable, "-I", "-c", ENTRY, os.path.join(DRV, rel), *main], capture_output=True, text=True, timeout=120)
        self.assertEqual(r.returncode, 0, r.stderr[-2000:])
        n, n2 = r.stdout.split()[-2:]
        self.assertEqual(n, n2)
        self.assertGreater(int(n), 8)

    def test_the_windows_lane_reloads(self):
        self.entry("windows/lane.py")

    def test_the_linux_lane_reloads(self):
        self.entry("linux/lane.py")

    def test_the_android_lane_reloads(self):
        self.entry("android/lane.py")

    def test_the_tx_lane_reloads_as_main(self):
        self.entry("linux/tx_lane.py", "main")


REAL_LANE = r"""
import json, os, sys, threading, time
root, out, code, funds = sys.argv[1:5]
sys.path.insert(0, root)
os.environ["REL_TRUST_PARK"] = "60"
open(os.path.join(root, "walk.py"), "w").write(code)
import walk
from core import checks, driver, hold
from core.driver import Driver
from core.faults import Diverged
from core.labels import Labels
from core.lane import Lane, Platform
from core.recover import Recover
from core.surface import Node


def n(i, role, name):
    return Node(i=i, role=role, name=name, states=frozenset(("enabled",)))


class Surface:
    platform, family = "linux", "desktop"

    def __init__(self):
        self.screen, self.acts, self.offset = "home", [], 0

    def tree(self):
        if self.screen == "home":
            return [n(0, "button", "Open")]
        rows = [n(1, "button", "Pay")] if self.offset else [n(2, "text", "Page")]
        return rows + [n(3, "button", "Done")]

    def press(self, node):
        self.acts.append(node.name)
        self.screen = "page" if node.name == "Open" else self.screen

    def set_text(self, node, text, secret=False):
        pass

    def key(self, name):
        pass

    def scroll(self, direction="down"):
        self.acts.append("scroll " + direction)
        self.offset += 1 if direction == "down" else -1

    def screenshot(self, path):
        return False

    def alive(self):
        return True


class Plat(Platform):
    platform = "linux"

    def alive(self):
        return True


s = Surface()
lane = Lane(Plat(), None, checks, out=out, log=lambda line: None, required=[], funds=False, p=None)
assert hold.install(lane, Diverged)
arb = {"o": "Open", "p": "Pay", "d": "Done", "wrong": "Nowhere"}
arb.update({k: k + "!" for k in driver.OVERLAY_KEYS + driver.OVERLAY_CLOSE_KEYS + driver.FOLD_KEYS})
lane.d = Driver(s, Labels(arb=arb), Recover(out, "linux", log=lambda line: None), out=out, log=lambda line: None, poll=0.001)


def person():
    while not os.path.exists(os.path.join(out, hold.PARKED)):
        time.sleep(0.01)
    p = os.path.join(root, "walk.py")
    text = open(p).read().replace('"wrong"', '"p"')
    open(p, "w").write(text)
    p = os.path.join(root, "core/driver.py")
    text = open(p).read().replace("    def tree(self):", "    def fixed(self):\n        return 'new'\n\n    def tree(self):", 1)
    open(p, "w").write(text)
    open(os.path.join(out, hold.CONTINUE), "w").write(json.dumps({"token": 1, "driver": {"commit": "c"}}))


threading.Thread(target=person, daemon=True).start()
name = "pay-out" if funds == "1" else "settings-ui-before"
lane.run_phase(name, lambda: walk.walk(lane))
print(json.dumps({"acts": s.acts, "fixed": lane.d.fixed(), "continues": len(lane.details["continues"])}))
"""

REAL_WALK = """
from core import targets as tg
from core.driver import shows

OPEN = tg.Target(id="o", role="button", keys=("o",))
PAGE = tg.Target(id="page", role="text", names=("Page",))
PAY = tg.Target(id="pay", role="button", keys=("wrong",))
DONE = tg.Target(id="d", role="button", keys=("d",))


def walk(lane):
    d = lane.d
    d.press(OPEN, step="open", then=shows(PAGE), timeout=1)
    d.press(PAY, step="find-pay", then=shows(DONE), timeout=0.1)
    d.press(DONE, step="done", then=shows(DONE), timeout=0.2)
"""


class RealDriver(unittest.TestCase):
    """The Driver itself in a copy of the kit, as the process tools/rel starts: a real miss, scrolls and all."""

    def walk(self, funds):
        tmp = tempfile.mkdtemp(prefix="relreal-", dir=os.environ.get("TMPDIR"))
        self.addCleanup(shutil.rmtree, tmp, ignore_errors=True)
        root, out = os.path.join(tmp, "drivers"), os.path.join(tmp, "out")
        shutil.copytree(DRV, root, ignore=shutil.ignore_patterns("__pycache__"))
        os.makedirs(out)
        r = subprocess.run([sys.executable, "-I", "-c", REAL_LANE, root, out, REAL_WALK, funds], capture_output=True, text=True, timeout=40)
        self.assertEqual(r.returncode, 0, r.stderr[-3000:] + r.stdout[-1000:])
        return json.loads(r.stdout.strip().splitlines()[-1])

    def test_a_miss_goes_on_from_that_press_on_a_real_driver(self):
        got = self.walk("0")
        self.assertEqual(got["fixed"], "new")  # the fix in core/driver.py reached the Driver already running
        self.assertEqual(got["continues"], 1)
        self.assertEqual(got["acts"].count("Open"), 1)
        self.assertEqual(got["acts"][-2:], ["Pay", "Done"])

    def test_a_miss_in_a_funds_phase_goes_on_too(self):
        got = self.walk("1")
        self.assertEqual(got["acts"].count("Open"), 1)
        self.assertEqual(got["acts"][-2:], ["Pay", "Done"])


class Search(Kit):
    def test_the_search_of_a_miss_is_not_replayed(self):
        code = """
from core.faults import HarnessFault
from core import hold

def walk(lane):
    lane.s.press("a")
    lane.s.scroll("down")
    with hold.searching():
        lane.s.press("fold")
    if "x" not in lane.s.tree():
        raise HarnessFault("find", "no x")
    lane.s.press("x")
"""
        lane = self.lane(code)
        self.app.screen = ["y"]
        self.fix("""
def walk(lane):
    lane.s.press("a")
    lane.s.press("y")
""")
        lane.run_phase("pay-out", lambda: self.mod.walk(lane))
        self.assertEqual(self.app.presses, ["a", "y"])  # the fold press went with the failed search


class LiveSide(Kit):
    def test_a_surface_and_the_like_keep_their_state(self):
        (pathlib.Path(self.root) / "held_kit.py").write_text("""
class Wallet:
    def __init__(self):
        self.n = 0

class WinSurface:
    def __init__(self):
        self.n = 0

class Rig:
    def __init__(self):
        self.n = 0
""")
        self.addCleanup(sys.modules.pop, "held_kit", None)
        lane = self.lane(BROKEN)
        import held_kit
        lane.parts = [held_kit.Wallet(), held_kit.WinSurface(), held_kit.Rig()]
        saved = hold._snapshot(lane)
        for o in lane.parts:
            o.n = 1
        hold._restore(saved)
        self.assertEqual([o.n for o in lane.parts], [0, 1, 1])

    def test_every_class_with_a_handle_on_the_app_is_named(self):
        for f in ("linux/atspi.py", "windows/uia.py", "android/uia.py", "ios/wda.py", "windows/rig.py"):
            src = pathlib.Path(DRV, f).read_text()
            for c in re.findall(r"^class (\w+):", src, re.M):
                self.assertIn(c, hold.OUT, f)


PARKING = r"""
import json, os, sys
drivers = os.path.join(os.environ["REL_RUNNER"], "tools/rellib/drivers")
sys.path.insert(0, drivers)
from core import hold
import a


class App:
    alive = staticmethod(lambda: True)
    def press(self, what):
        with open(os.path.join(os.environ["REL_SRC"], "presses"), "a") as f:
            f.write(what + "\n")


class Lane:
    log = staticmethod(print)
    funder = probe = None
    details = {}
    out = os.environ["REL_OUT"]
    p = App()


lane = Lane()
os.environ.get("REL_TRUST_PARK") and hold.install(lane, RuntimeError)
try:
    hold.guard(lane, "settings", lambda: a.walk(lane))()
    proof = dict(json.load(open(os.path.join(os.environ["REL_SRC"], "good.json"))))
    code = 0
except Exception as e:
    proof = {"fault": {"kind": "harness", "cause_class": "harness", "step": "find-x", "what": str(e), "line": "HARNESS find-x"},
             "phases": {"done": [], "failed": "settings", "kept": []}, "checks": {}}
    code = 2
json.dump(proof, open(os.path.join(os.environ["REL_OUT"], "proof.json"), "w"))
sys.exit(code)
"""
BROKEN_A = """
def walk(lane):
    lane.p.press("a")
    lane.p.press(lane.missing)
"""
FIXED_A = BROKEN_A.replace("lane.missing", '"b"')


class ThroughRel(Repeats):
    """tools/rel on a lane that really parks: hold.py in a process of its own, on the driver repo's commit."""

    def setUp(self):
        super().setUp()
        self.write("lane.py", PARKING)
        self.write("good.json", json.dumps(GOOD))
        self.write("driver.sh", 'REL_RUNNER=%s exec python3 "$REL_SRC/lane.py"\n' % self.repo)
        core = pathlib.Path(self.repo, "tools/rellib/drivers/core")
        core.mkdir()
        shutil.copy(os.path.join(DRV, "core/hold.py"), core / "hold.py")
        (core / "__init__.py").write_text("")
        self.driver_fix(BROKEN_A)
        self.result = []

    def start(self, step=None):
        t = threading.Thread(target=lambda: self.result.append(self.eng.execute(step or self.android)), daemon=True)
        t.start()
        self.addCleanup(self.stop_it, t)
        return t

    def stop_it(self, t):
        if t.is_alive():
            self.rel("continue", KEY, "--stop")
        t.join(20)

    def stage(self):
        return os.path.join(self.run_.step_dir(KEY), "out")

    def left_parked(self, first=""):
        """A lane in this stage that a dead tools/rel left at its park."""
        stage = self.stage()
        os.makedirs(stage, exist_ok=True)
        p = subprocess.Popen([sys.executable, "-c", first + "import time\nprint(1, flush=True)\ntime.sleep(60)"],
                             env=dict(os.environ, REL_STAGE=stage), start_new_session=True, stdout=subprocess.PIPE)
        self.addCleanup(p.stdout.close)
        self.addCleanup(p.wait)
        self.addCleanup(p.kill)
        p.stdout.readline()
        threading.Thread(target=p.wait, daemon=True).start()  # reaps it: a zombie still has its pid
        with open(os.path.join(stage, repeats.PARKED), "w") as f:
            json.dump({"pid": p.pid, "step": "x", "phase": "settings"}, f)
        return p

    def until_parked(self):
        end = time.monotonic() + 20
        while time.monotonic() < end:
            st = self.st()
            if st.get("parked"):
                return st
            time.sleep(0.05)
        self.fail_now()

    def fail(self, kind="harness", rc=2, step=None):  # Repeats.fail is a failing lane; an assert ends here too
        if kind in ("harness", "infra", "product"):
            return super().fail(kind, rc, step)
        raise self.failureException(kind)

    def fail_now(self):
        raise self.failureException("the lane did not park: %s" % self.st())

    def presses(self):
        return pathlib.Path(self.src, "presses").read_text().split()

    def test_a_parked_lane_is_fixed_where_it_stands(self):
        t = self.start()
        st = self.until_parked()
        self.assertEqual(st["status"], "running")
        self.assertEqual(st["parked"]["phase"], "settings")
        self.assertEqual(len(self.events("parked")), 1)
        self.assertIn("parked", repr(self.rel("status")).lower())
        self.driver_fix(FIXED_A)
        fixed = self.git("rev-parse", "HEAD")
        code, out, err = self.rel("continue", KEY)
        self.assertEqual(code, 0, err + out)
        self.assertIn("1 actions of phase settings replayed", (out + err).replace("  ", " "))
        t.join(20)
        self.assertEqual(self.result[0]["status"] if isinstance(self.result[0], dict) else self.st()["status"], "done")
        st = self.st()
        self.assertEqual(st["status"], "done")
        self.assertEqual(st["attempts"], 1)  # one attempt, whatever it took to go on
        self.assertEqual(st["driver"]["commit"], fixed)
        self.assertEqual(st["continues"][0]["acts"], 1)
        self.assertFalse(st.get("parked"))
        self.assertEqual(self.presses(), ["a", "b"])
        self.assertEqual(len(self.events("continue")), 1)
        self.assertEqual(len(self.events("continued")), 1)

    def test_an_uncommitted_fix_is_refused(self):
        self.start()
        self.until_parked()
        pathlib.Path(self.repo, "tools/rellib/drivers/a.py").write_text(FIXED_A)
        code, out, err = self.rel("continue", KEY)
        self.assertEqual(code, 40, err + out)
        self.assertIn("uncommitted driver changes", out + err)
        self.commit()

    def test_a_fix_that_does_not_load_is_told_and_stays_parked(self):
        t = self.start()
        self.until_parked()
        self.driver_fix("def walk(lane:\n")
        code, out, err = self.rel("continue", KEY)
        self.assertEqual(code, 20, err + out)
        self.assertIn("the drivers do not load", out + err)
        self.assertTrue(self.st().get("parked"))
        self.driver_fix(FIXED_A)
        code, out, err = self.rel("continue", KEY)
        self.assertEqual(code, 0, err + out)
        t.join(20)
        self.assertEqual(self.st()["status"], "done")

    def test_stop_gives_the_fault_back(self):
        t = self.start()
        self.until_parked()
        code, out, err = self.rel("continue", KEY, "--stop")
        self.assertEqual(code, 0, err + out)
        t.join(20)
        st = self.st()
        self.assertEqual(st["status"], "failed")
        self.assertEqual(st["failures"][-1]["kind"], "harness")
        self.assertEqual(self.presses(), ["a"])

    def test_a_lane_left_parked_ends_before_a_new_attempt(self):
        self.start()
        park = self.until_parked()["parked"]
        stage = self.stage()
        pid = repeats.parked(stage)["pid"]
        self.assertTrue(repeats.lane_of(pid, stage))
        self.assertEqual(repeats.end_park(stage)["step"], park["step"])
        self.assertFalse(repeats.lane_of(pid, stage))

    def test_a_new_attempt_ends_what_is_left_parked_before_it_starts(self):
        p = self.left_parked()
        self.driver_fix(FIXED_A)
        self.eng.execute(self.android)
        self.assertEqual(p.wait(5), -15)
        self.assertEqual(self.st()["status"], "done")
        self.assertEqual(len(self.events("park-ended")), 1)

    def test_a_pid_that_is_no_lane_of_this_stage_is_left_alone(self):
        stage = self.stage()
        os.makedirs(stage, exist_ok=True)
        p = subprocess.Popen(["sleep", "60"])
        self.addCleanup(p.wait)
        self.addCleanup(p.kill)
        with open(os.path.join(stage, repeats.PARKED), "w") as f:
            json.dump({"pid": p.pid, "step": "x"}, f)
        self.assertIsNone(repeats.end_park(stage))
        self.assertIsNone(p.poll())

    def test_a_lane_that_ignores_the_stop_is_killed(self):
        p = self.left_parked("import signal,time\nsignal.signal(signal.SIGTERM, signal.SIG_IGN)\n")
        self.assertEqual(repeats.end_park(self.stage(), wait_s=0.5)["pid"], p.pid)
        self.assertEqual(p.wait(5), -9)

    def test_a_parked_lane_does_not_time_out(self):
        code = self.eng.spawn(["bash", "-c", "sleep 3"], self.tmp, dict(os.environ), os.path.join(self.tmp, "log"), 1, held=lambda: True)
        self.assertEqual(code, 0)

    def test_a_lane_that_does_not_park_still_times_out(self):
        code = self.eng.spawn(["bash", "-c", "sleep 9"], self.tmp, dict(os.environ), os.path.join(self.tmp, "log"), 2, held=lambda: False)
        self.assertIsNone(code)

    def test_a_parked_lane_gives_its_slot_back(self):
        self.start()
        self.until_parked()
        policy = self.eng.policy
        running = [self.android]
        with mock.patch.object(policy, "counts", return_value=True), mock.patch.object(policy, "max_heavy", 1):
            self.assertIsNotNone(policy.why_not(self.linux, running))
            self.assertIsNone(policy.why_not(self.linux, running, running))

    def test_not_parked_and_running_is_nothing_to_continue(self):
        self.run_.set_status(KEY, status="running")
        code, out, err = self.rel("continue", KEY)
        self.assertEqual(code, 75, err + out)
        self.assertIn("nothing to continue yet", out + err)

    def test_a_gone_lane_needs_a_changed_driver(self):
        self.write("driver.sh", 'cat "$REL_SRC/attempt.json" > "$REL_OUT/proof.json"; exit 2\n')
        self.fail()
        self.assertEqual(self.st()["failures"][-1]["kind"], "harness")
        code, out, err = self.rel("continue", KEY)
        self.assertEqual(code, 40, err + out)
        self.assertIn("the drivers have not changed since it failed at", out + err)

    def test_a_gone_lane_goes_back_to_its_resume_point_with_no_probe(self):
        self.write("driver.sh", 'if [[ -e "$REL_SRC/pass" ]]; then cat "$REL_SRC/good.json" > "$REL_OUT/proof.json"; exit 0; fi\n'
                                'cat "$REL_SRC/attempt.json" > "$REL_OUT/proof.json"; exit 2\n')
        self.fail()
        self.assertEqual(self.st()["failures"][-1]["kind"], "harness")
        self.driver_fix(FIXED_A)
        self.write("pass", "")
        code, out, err = self.rel("continue", KEY)
        self.assertEqual(code, 0, err + out)
        self.assertIn("nearest resume point", out + err)
        self.assertEqual(self.st()["status"], "done")

    def test_a_dry_lane_does_not_park(self):
        self.eng.dry = True
        env = repeats.attempt_env(self.eng, self.android, {})
        self.assertNotIn("REL_TRUST_PARK", env)


del Repeats


if __name__ == "__main__":
    unittest.main()
