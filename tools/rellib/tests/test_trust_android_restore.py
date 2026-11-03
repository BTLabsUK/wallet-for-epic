# SPDX-License-Identifier: Apache-2.0
"""A lane seed's wallet on Android: the phone recipe's restore from a phrase (core/phone.py) on a fake
surface, the phrase typed as a secret (android/uia.py: from a file on the emulator, never on adb's
command line), the Driver hushed while it is typed, and the candidate installed fresh for
REL_TRUST_MODE=create. No emulator; the test phrase is made of words no log line holds."""
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
from core import targets as tg  # noqa: E402
from core.driver import Driver  # noqa: E402
from core.faults import HarnessFault  # noqa: E402
from core.phone import PIN_FIELD, RESTORE_PHRASE, Phone  # noqa: E402
from core.recover import Recover  # noqa: E402
from core.surface import Node  # noqa: E402

WORDS = ["qvaxa", "qvbxb", "qvcxc", "qvdxd", "qvexe", "qvfxf", "qvgxg", "qvhxh", "qvixi", "qvjxj", "qvkxk", "qvlxl"]
PHRASE = " ".join(WORDS)
MONTHS = ("January", "February", "March", "April", "May", "June", "July", "August", "September", "October",
          "November", "December")


def btn(i, name, **kw):
    return Node(i=i, role="button", name=name, states=frozenset(kw.pop("states", ("enabled",))), actions=("press",), **kw)


def text(i, name):
    return Node(i=i, role="text", name=name, states=frozenset({"enabled"}))


def field(i, name, value="", password=False):
    st = {"enabled", "editable"} | ({"password"} if password else set())
    return Node(i=i, role="text_field", name=name, value=value, states=frozenset(st), actions=("press", "set_text"))


HOME = [btn(0, "Lock wallet"), btn(1, "Settings"), Node(i=2, role="tab", name="Send\nTab 1 of 3", actions=("press",)),
        Node(i=3, role="tab", name="Wallet\nTab 2 of 3", states=frozenset({"enabled", "selected"}), actions=("press",)),
        Node(i=4, role="tab", name="Receive\nTab 3 of 3", actions=("press",))]


class FakeRestore:
    """The phone's restore screens as a small state machine, pressed and typed into by name."""
    platform, family = "android", "phone"

    def __init__(self, scan_reads=2, card_reads=3, problem=False):
        self.cur, self.phrase, self.height, self.month, self.year = "welcome", "", "", None, 2024
        self.start_open, self.by_height, self.problem = False, False, problem
        self.scan_reads, self.card_reads = scan_reads, card_reads
        self.typed, self.pressed, self.shots = [], [], []

    def tree(self):
        c = self.cur
        if c == "welcome":
            return [btn(0, "Create a new wallet"), btn(1, "Restore from phrase")]
        if c == "restore":
            t = [text(0, "Restore wallet"), field(1, "Recovery phrase", self.phrase)]
            if not self.start_open:
                t.append(btn(2, "Start from a month or height"))
            else:
                t += [text(3, "Where to start scanning"), btn(4, "Month"), btn(5, "Block height")]
                if self.by_height:
                    t.append(field(6, "Start height (optional)", self.height))
                else:
                    t.append(btn(6, "%s %d" % (MONTHS[self.month[1] - 1], self.month[0]) if self.month
                                 else "Pick the month you created the wallet"))
                if self.month and not self.by_height:
                    t.append(text(7, "Scanning starts from block 2,345,678."))
            if self.problem and self.phrase:
                t.append(text(8, "Every word is in the word list, but the phrase does not check out. A word is wrong or out of order."))
            return t + [btn(9, "Continue")]
        if c == "months":
            t = [text(0, "When did you create the wallet?"), btn(1, "Earlier year"), text(2, str(self.year)), btn(3, "Later year")]
            return t + [btn(4 + m, "%s %d" % (MONTHS[m], self.year)) for m in range(12)]
        if c in ("pin1", "pin2"):
            return [text(0, "Choose a 6-digit PIN" if c == "pin1" else "Enter the PIN again"), field(1, "PIN", password=True)]
        if c == "scan":
            self.scan_reads -= 1
            if self.scan_reads < 0:
                self.cur = "done"
                return self.tree()
            return [text(0, "Looking for this wallet’s coins on the chain. Keep the app open until this finishes."), btn(1, "Stop")]
        if c == "done":
            return [text(0, "Your wallet is restored"), btn(1, "Import wallet data"), btn(2, "Not now")]
        if c == "home-card":
            self.card_reads -= 1
            if self.card_reads < 0:
                self.cur = "home"
            else:
                return HOME + [text(5, "Restore not finished"),
                               text(6, "Looking for this wallet’s coins from block 0. Receiving and sending open when this ends.")]
        return list(HOME)

    def press(self, n):
        self.pressed.append(n.name)
        c, name = self.cur, n.name
        if c == "welcome" and name == "Restore from phrase":
            self.cur = "restore"
        elif c == "restore" and name == "Start from a month or height":
            self.start_open = True
        elif c == "restore" and name == "Block height":
            self.by_height = True
        elif c == "restore" and name == "Pick the month you created the wallet":
            self.cur = "months"
        elif c == "restore" and name == "Continue" and self.phrase and not self.problem:
            self.phrase, self.cur = "", "pin1"
        elif c == "months" and name == "Later year":
            self.year += 1
        elif c == "months" and name == "Earlier year":
            self.year -= 1
        elif c == "months" and name.endswith(str(self.year)):
            self.month, self.cur = (self.year, MONTHS.index(name.split()[0]) + 1), "restore"
        elif c == "done" and name == "Not now":
            self.cur = "home-card"

    def set_text(self, n, text, secret=False):
        self.typed.append((n.name, len(text), secret))
        if self.cur == "restore" and n.name == "Recovery phrase":
            self.phrase = text
        elif self.cur == "restore":
            self.height = text
        elif self.cur == "pin1":
            self.cur = "pin2"
        elif self.cur == "pin2":
            self.cur = "scan"

    def hide_keyboard(self):
        pass

    def key(self, name):
        pass

    def scroll(self, direction="down"):
        pass

    def screenshot(self, path):
        self.shots.append("PHRASE" if self.phrase else self.cur)
        return False

    def alive(self):
        return True

    def in_front(self):
        return True

    def foreground(self):
        pass


class RestoreTest(unittest.TestCase):
    def setUp(self):
        self.out = tempfile.mkdtemp(prefix="trust-restore-")
        env = mock.patch.dict(os.environ, {"REL_AI": "0"})
        env.start()
        self.addCleanup(env.stop)
        self.lines = []

    def recipe(self, s):
        log = self.lines.append
        d = Driver(s, None, Recover(self.out, "android", log=log), out=self.out, log=log, poll=0.01)
        return Phone(d, "previous", log=log)

    def leaks(self):
        """Every log line and every file the lane wrote: none may hold a word of the phrase."""
        texts = list(self.lines)
        for root, _, files in os.walk(self.out):
            for f in files:
                with open(os.path.join(root, f), "rb") as fh:
                    texts.append(fh.read().decode("utf-8", "replace"))
        return [w for w in WORDS if any(w in t for t in texts)]

    def test_restore_with_a_month_reaches_home_then_waits_for_the_full_scan(self):
        s = FakeRestore()
        r = self.recipe(s)
        got = r.restore_wallet(PHRASE, {"height": 2345678, "month": "2026-11"})
        self.assertEqual(sorted(got), ["password", "pin"])
        self.assertRegex(got["pin"], r"^\d{6}$")
        self.assertEqual(s.cur, "home-card")   # back at Home after the month scan: the scan from block 0 goes on
        self.assertFalse(any("scan from block 0 finished" in line for line in self.lines))
        r.restore_finish()   # what address() and send() do first
        self.assertEqual(s.cur, "home")
        self.assertIsNone(r.restoring)
        self.assertEqual(s.month, (2026, 11))
        self.assertIn(("Recovery phrase", len(PHRASE), True), s.typed)
        self.assertEqual([t for t in s.typed if t[0] == "PIN"], [("PIN", 6, True), ("PIN", 6, True)])
        self.assertNotIn("PHRASE", s.shots)
        self.assertTrue(any("scan from block 0 finished" in line for line in self.lines))
        self.assertEqual(self.leaks(), [])

    def test_the_month_is_picked_before_the_phrase_is_typed(self):
        s = FakeRestore()
        self.recipe(s).restore_wallet(PHRASE, {"height": None, "month": "2025-03"})
        order = s.pressed.index("March 2025"), [i for i, n in enumerate(s.pressed) if n == "Continue"][0]
        self.assertLess(*order)
        self.assertEqual(s.month, (2025, 3))

    def test_a_height_alone_goes_in_block_height(self):
        s = FakeRestore()
        self.recipe(s).restore_wallet(PHRASE, {"height": 1234567, "month": None})
        self.assertIn("Block height", s.pressed)
        self.assertEqual(s.month, None)

    def test_no_birth_scans_the_whole_chain(self):
        s = FakeRestore()
        self.recipe(s).restore_wallet(PHRASE, {"height": None, "month": None})
        self.assertNotIn("Start from a month or height", s.pressed)
        self.assertIn(s.cur, ("home", "home-card"))

    def test_a_phrase_problem_fails_hushed(self):
        s = FakeRestore(problem=True)
        with self.assertRaises(HarnessFault) as c:
            self.recipe(s).restore_wallet(PHRASE, {"month": "2026-11"})
        self.assertIn("did not take the phrase", c.exception.what)
        self.assertIsNone(c.exception.shot)
        self.assertNotIn("PHRASE", s.shots)  # no shot of the screen holding the phrase
        self.assertEqual([f for f in os.listdir(self.out) if f.startswith("tree-")], [])
        self.assertEqual(self.leaks(), [])

    def test_restore_targets_are_secret(self):
        import core.phone as ph
        names = [n for n in dir(ph) if n.startswith(("RESTORE", "MONTH_")) and isinstance(getattr(ph, n), tg.Target)]
        self.assertGreater(len(names), 10)
        self.assertEqual([n for n in names if not getattr(ph, n).secret], [])


class HushTest(unittest.TestCase):
    def test_no_shot_nor_dump_while_hushed(self):
        out = tempfile.mkdtemp(prefix="trust-hush-")
        s = FakeRestore()
        s.cur = "restore"
        d = Driver(s, None, Recover(out, "android", log=lambda *_: None), out=out, log=lambda *_: None, poll=0.01)
        with d.hush():
            self.assertIsNone(d.shot("x"))
            d.dump("x", s.tree())
        self.assertEqual((s.shots, os.listdir(out)), ([], []))
        d.shot("after")
        self.assertEqual(s.shots, ["restore"])

    def test_fill_passes_secret_only_for_a_secret_target(self):
        out = tempfile.mkdtemp(prefix="trust-hush-")
        s = FakeRestore()
        s.cur = "restore"
        d = Driver(s, None, Recover(out, "android", log=lambda *_: None), out=out, log=lambda *_: None, poll=0.01)
        d.fill(RESTORE_PHRASE, PHRASE, step="phrase")
        plain = tg.T("g4.test.plain", role="text_field", names=("Recovery phrase",), match="starts")
        d.fill(plain, "abc", step="plain")
        self.assertEqual([t[2] for t in s.typed], [True, False])
        self.assertTrue(PIN_FIELD.secret)


class FakeDevice:
    serial = "emulator-5580"

    def __init__(self):
        self.calls = []

    def run(self, *args, timeout=60, text=True, check_gone=True, inp=None):
        self.calls.append((args, inp))
        return mock.Mock(returncode=0, stdout="Success\n", stderr="")

    def sh(self, cmd, timeout=60):
        return self.run("shell", cmd, timeout=timeout).stdout

    def online(self):
        return True


class SecretTypingTest(unittest.TestCase):
    def setUp(self):
        self.dev = FakeDevice()
        self.u = uia.Uia(self.dev, "uk.btlabs.btwallet", log=lambda *_: None)
        self.node = Node(i=0, role="text_field", name="Recovery phrase", value="", states=frozenset({"editable"}),
                         actions=("set_text",), ref={"bounds": (0, 0, 100, 100)})

    def test_secret_text_never_on_adbs_command_line(self):
        with mock.patch.object(self.u, "_fresh", return_value=Node(i=0, role="text_field", name="Recovery phrase", value=PHRASE)):
            self.u.set_text(self.node, PHRASE, secret=True)
        argv = " ".join(" ".join(a) for a, _ in self.dev.calls)
        self.assertEqual([w for w in WORDS if w in argv], [])
        fed = [inp for _, inp in self.dev.calls if inp]
        self.assertEqual(len(fed), 1)
        self.assertEqual(fed[0].split("\n")[:-1], self.u._parts(PHRASE, self.u.chunk))
        files = {a[1].split()[-1] for a, _ in self.dev.calls if a[0] == "shell" and "/data/local/tmp/wfe-in-" in a[1]}
        self.assertEqual(len(files), 1)  # one file: written (umask 077), typed from, removed
        f = files.pop()
        shells = [a[1] for a, _ in self.dev.calls if a[0] == "shell" and f in a[1]]
        self.assertTrue(shells[0].startswith("umask 077; cat > "))
        self.assertIn('input text "$c"', shells[1])
        self.assertEqual(shells[-1], "rm -f %s" % f)

    def test_a_retype_is_secret_too_and_the_file_goes_on_failure(self):
        fresh = iter([Node(i=0, role="text_field", name="Recovery phrase", value=PHRASE[:-3])] * 2)
        with mock.patch.object(self.u, "_fresh", side_effect=lambda n: next(fresh)):
            self.u.set_text(self.node, PHRASE, secret=True)
        argv = " ".join(" ".join(a) for a, _ in self.dev.calls)
        self.assertEqual([w for w in WORDS if w in argv], [])
        self.assertEqual(len([inp for _, inp in self.dev.calls if inp]), 2)
        bad = FakeDevice()
        bad.run = lambda *a, inp=None, **k: (bad.calls.append((a, inp)),
                                             mock.Mock(returncode=1 if inp else 0, stdout="", stderr=""))[1]
        u = uia.Uia(bad, "uk.btlabs.btwallet", log=lambda *_: None)
        with self.assertRaises(RuntimeError):
            u._type_secret(PHRASE, 10)
        self.assertTrue(bad.calls[-1][0][1].startswith("rm -f /data/local/tmp/wfe-in-"))

    def test_plain_text_keeps_the_command_line_path(self):
        with mock.patch.object(self.u, "_fresh", return_value=Node(i=0, role="text_field", name="Amount", value="0.5")):
            self.u.set_text(self.node, "0.5")
        self.assertIn((("shell", "input text '0.5'"), None), self.dev.calls)


class CreateModeTest(unittest.TestCase):
    def test_install_candidate_fresh(self):
        import android_platform as ap
        out = tempfile.mkdtemp(prefix="trust-create-")
        with mock.patch.dict(os.environ, {"REL_CANDIDATE_APK": "/x/cand.apk", "REL_PREVIOUS_APK": "/x/prev.apk"}):
            p = ap.AndroidPlatform(out, lambda *_: None)
        p.dev = FakeDevice()
        p.running = "previous"
        p.install_candidate_fresh()
        args = [a for a, _ in p.dev.calls]
        self.assertEqual(args[0], ("uninstall", ap.PKG))
        self.assertEqual(args[1], ("install", "-g", "--no-incremental", "/x/cand.apk"))
        self.assertIsNone(p.running)

    def test_create_mode_checks_and_no_funds(self):
        import importlib.util
        spec = importlib.util.spec_from_file_location("android_lane", os.path.join(DRIVERS, "android", "lane.py"))
        lane = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(lane)
        with mock.patch.dict(os.environ, {"REL_TRUST_MODE": "create", "REL_CHECKS": ""}):
            self.assertTrue(lane.create_mode())
            self.assertEqual(lane.required(False), list(getattr(lane.checks, "CREATE_CHECKS", ["create_ok"])))
        with mock.patch.dict(os.environ, {"REL_TRUST_MODE": "", "REL_CHECKS": "wallet_opens,restore_ok"}):
            self.assertFalse(lane.create_mode())
            self.assertEqual(lane.required(True), ["wallet_opens", "restore_ok"])


if __name__ == "__main__":
    unittest.main()
