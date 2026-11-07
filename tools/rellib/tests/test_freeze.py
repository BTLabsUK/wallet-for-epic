# SPDX-License-Identifier: Apache-2.0
"""A frozen app is the product's fault (core/freeze.py, Driver.alive_check): the platform's own sign that its UI
stopped (an unanswered AT-SPI question, a hung Windows window, Android's ANR), a StackOverflowError or an unhandled
error in the app's own log for this run. Each ends PRODUCT "the app froze" with the evidence for the bundle; the app
quitting stays app_quit(), the surface gone stays HarnessGone. The Android ANR dialog is no longer an obstacle."""
import os
import sys
import tempfile
import unittest
import unittest.mock

HERE = os.path.dirname(os.path.abspath(__file__))
DRIVERS = os.path.join(os.path.dirname(HERE), "drivers")
sys.path.insert(0, DRIVERS)
for sub in ("linux", "android", "windows"):
    sys.path.insert(1, os.path.join(DRIVERS, sub))

from core import freeze  # noqa: E402
from core.driver import Driver, Expect  # noqa: E402
from core.faults import HarnessGone, ProductFault  # noqa: E402
from core.labels import Labels  # noqa: E402
from core.recover import Recover  # noqa: E402
from core.surface import Node  # noqa: E402

import importlib.util  # noqa: E402


# the three drivers each have a uia.py: loaded by path under their own names
def load(name, rel):
    spec = importlib.util.spec_from_file_location(name, os.path.join(DRIVERS, rel))
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


android_uia = load("android_uia", "android/uia.py")
atspi = load("atspi_under_test", "linux/atspi.py")
win_uia = load("win_uia", "windows/uia.py")

PKG = "uk.btlabs.btwallet"
SO = "11-04 07:01:02.345  4242  4242 E flutter : [ERROR:flutter/runtime/dart_vm_initializer.cc(41)] Unhandled Exception: Stack Overflow"
BTN = Node(i=0, role="button", name="Unlock", states=frozenset({"enabled", "showing"}))


class Fake:
    """A surface with the optional freeze hooks."""
    platform, family = "linux", "desktop"

    def __init__(self, froze=None, lines=None, evidence=None, up=True, gone=False):
        self.why, self.lines, self.ev, self.up, self.gone = froze, lines or [], evidence or {}, up, gone
        self.asked = 0

    def tree(self):
        return [BTN]

    def press(self, node):
        pass

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

    def display_alive(self):
        return not self.gone

    def froze(self):
        self.asked += 1
        return self.why

    def log_lines(self):
        out, self.lines = self.lines, []
        return out

    def evidence(self):
        return self.ev


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.logs = []

    def tearDown(self):
        self.tmp.cleanup()

    def driver(self, fake):
        rec = Recover(self.tmp.name, "linux", log=self.logs.append)
        d = Driver(fake, Labels(arb={}), rec, out=self.tmp.name, log=self.logs.append, poll=0.01)
        d._begin("unlock")
        return d


class ClassifyTest(unittest.TestCase):
    def test_stack_overflow_and_unhandled_lines(self):
        self.assertEqual(freeze.log_problem(["a", "12:00 INFO dart.net: ok", "x StackOverflowError at y"])[0], "stack overflow")
        self.assertEqual(freeze.log_problem(["Unhandled exception:", "Stack Overflow"])[0], "stack overflow")
        self.assertEqual(freeze.log_problem(["2026 ERROR dart.flutter: boom"])[0], "unhandled error")
        self.assertEqual(freeze.log_problem(["2026 ERROR dart.platform: boom"])[0], "unhandled error")
        # a stack overflow outranks an unhandled error written earlier
        self.assertEqual(freeze.log_problem(["2026 ERROR dart.flutter: x", "StackOverflowError"])[0], "stack overflow")

    def test_ordinary_log_lines_are_not_problems(self):
        self.assertIsNone(freeze.log_problem(["12:00:00 INFO dart.net: node synced", "12:00:01 WARN dart.sync: slow",
                                              "12:00:02 ERROR rust.lepic: retry"]))

    def test_logcat_anr_for_the_package_only(self):
        mine = "11-04 07:00:00.000  1000  1100 E ActivityManager: ANR in %s (%s/.MainActivity)" % (PKG, PKG)
        other = "11-04 07:00:00.000  1000  1100 E ActivityManager: ANR in com.other.app (com.other.app/.Main)"
        events = "11-04 07:00:00.000  1000  1100 I am_anr : [0,4242,%s,953,Input dispatching timed out]" % PKG
        self.assertEqual(freeze.logcat_problem(mine, PKG, set())[0], "ANR")
        self.assertEqual(freeze.logcat_problem(events, PKG, set())[0], "ANR")
        self.assertIsNone(freeze.logcat_problem(other, PKG, set()))

    def test_logcat_overflow_from_the_apps_pid_only(self):
        sys_line = SO.replace("4242  4242", "999  999")
        self.assertEqual(freeze.logcat_problem(SO, PKG, {"4242"})[0], "stack overflow")
        self.assertIsNone(freeze.logcat_problem(sys_line, PKG, {"4242"}))

    def test_anr_dialog_text(self):
        self.assertTrue(freeze.anr_dialog(["BT Wallet isn't responding"]))
        self.assertTrue(freeze.anr_dialog(["BT Wallet isn\u2019t responding"]))
        self.assertIsNone(freeze.anr_dialog(["Unlock wallet", "Wait"]))

    def test_log_cursor_gives_new_lines_and_survives_rotation(self):
        text = ["old 1", "old 2"]
        c = freeze.LogCursor(lambda: "\n".join(text) if text is not None else None)
        c.mark()
        self.assertEqual(c.new(), [])
        text += ["new 1"]
        self.assertEqual(c.new(), ["new 1"])
        self.assertEqual(c.new(), [])
        text[:] = ["fresh"]   # the file rotated: smaller, all of it is this run's
        self.assertEqual(c.new(), ["fresh"])


class AliveCheckTest(Base):
    def test_unanswering_ui_is_a_product_fault_with_evidence(self):
        d = self.driver(Fake(froze="no AT-SPI answer from the app in 5 s", evidence={"threads.txt": "T"}))
        with self.assertRaises(freeze.Frozen) as cm:
            d.alive_check()
        f = cm.exception
        self.assertIsInstance(f, ProductFault)
        self.assertEqual(f.cause_class, "PRODUCT")
        self.assertEqual(f.step, "unlock")
        self.assertIn("the app froze: no AT-SPI answer", f.what)
        self.assertEqual(f.evidence, {"threads.txt": "T"})

    def test_stack_overflow_in_the_apps_log_is_a_freeze(self):
        d = self.driver(Fake(lines=["12:00 INFO dart.x: ok", "12:00:01 E StackOverflowError in unlock()"]))
        with self.assertRaises(freeze.Frozen) as cm:
            d.alive_check()
        self.assertIn("the app's log has a stack overflow", cm.exception.what)
        self.assertIn("StackOverflowError", cm.exception.what)

    def test_unhandled_error_in_the_apps_log(self):
        d = self.driver(Fake(lines=["2026-11-04 12:00:00 ERROR dart.flutter: Bad state"]))
        with self.assertRaises(freeze.Frozen) as cm:
            d.alive_check()
        self.assertIn("unhandled error", cm.exception.what)

    def test_a_healthy_app_passes(self):
        f = Fake(lines=["12:00 INFO dart.net: ok"])
        self.driver(f).alive_check()
        self.assertEqual(f.asked, 1)

    def test_a_surface_without_hooks_is_never_frozen(self):
        f = Fake()
        del Fake.froze, Fake.log_lines, Fake.evidence
        try:
            self.driver(f).alive_check()
        finally:
            Fake.froze, Fake.log_lines, Fake.evidence = _KEEP

    def test_the_app_quitting_is_not_a_freeze(self):
        with self.assertRaises(ProductFault) as cm:
            self.driver(Fake(up=False)).alive_check()
        self.assertNotIsInstance(cm.exception, freeze.Frozen)
        self.assertIn("quit", cm.exception.what)

    def test_a_gone_display_is_the_harness_not_the_product(self):
        with self.assertRaises(HarnessGone):
            self.driver(Fake(up=False, gone=True)).alive_check()

    def test_a_freeze_inside_a_tree_read_becomes_the_steps_product_fault(self):
        f = Fake()

        def tree():
            raise freeze.Frozen("ui", "the app window gave no answer", evidence={"processes.txt": "p"})
        f.tree = tree
        d = self.driver(f)
        with self.assertRaises(freeze.Frozen) as cm:
            d.tree()
        self.assertEqual(cm.exception.step, "unlock")
        self.assertEqual(cm.exception.evidence, {"processes.txt": "p"})

    def test_a_wait_loop_asks_while_it_waits(self):
        f = Fake()
        d = self.driver(f)
        with unittest.mock.patch.object(freeze, "FREEZE_S", 0):
            f.why = None
            seen = []
            orig = f.froze

            def froze():
                seen.append(1)
                if len(seen) == 3:
                    f.why = "stopped"
                return orig()
            f.froze = froze
            with self.assertRaises(freeze.Frozen):
                d.wait(Expect("never", lambda dd, tree: False), timeout=30)
        self.assertGreaterEqual(len(seen), 3)

    def test_the_end_of_a_step_asks(self):
        f = Fake(froze="stopped")
        d = self.driver(f)
        with unittest.mock.patch.object(freeze, "FREEZE_S", 0):
            with self.assertRaises(freeze.Frozen):
                d._reached()


_KEEP = (Fake.froze, Fake.log_lines, Fake.evidence)


class AndroidTest(unittest.TestCase):
    class Dev:
        serial, adb = "emulator-5582", "adb"

        def __init__(self, answers):
            self.answers, self.cmds = answers, []

        def sh(self, cmd, timeout=60):
            self.cmds.append(cmd)
            for k, v in self.answers.items():
                if k in cmd:
                    return v
            return ""

        def online(self):
            return True

    def uia(self, answers):
        return android_uia.Uia(self.Dev(answers), PKG, log=lambda *_: None, since="11-04 07:00:00.000")

    def test_the_anr_window_for_the_package(self):
        u = self.uia({"pidof": "4242\n", "dumpsys window": "  Window{1a2b u0 Application Not Responding: %s}\n@@wfe@@\n" % PKG})
        self.assertIn("'not responding' window is up for " + PKG, u.froze())

    def test_the_anr_record_in_the_log(self):
        rec = "11-04 07:00:00.000  1000  1100 E ActivityManager: ANR in %s (%s/.MainActivity)" % (PKG, PKG)
        u = self.uia({"pidof": "4242\n", "dumpsys window": "\n@@wfe@@\n" + rec + "\n"})
        self.assertIn("logged an ANR", u.froze())

    def test_another_apps_anr_is_not_ours(self):
        u = self.uia({"pidof": "4242\n", "dumpsys window": "  Window{1 u0 Application Not Responding: com.other}\n@@wfe@@\n"})
        self.assertIsNone(u.froze())

    def test_a_quit_app_is_not_asked_about_anr(self):
        self.assertIsNone(self.uia({"pidof": "", "dumpsys window": "Not Responding %s" % PKG}).froze())

    def test_log_lines_are_the_apps_own_pids_only(self):
        u = self.uia({"pidof": "4242\n", "logcat": SO + "\n" + SO.replace("4242  4242", "999  999") + "\n"})
        got = u.log_lines()
        self.assertEqual(len(got), 1)
        self.assertEqual(freeze.log_problem(got)[0], "stack overflow")

    def test_the_anr_obstacle_is_gone(self):
        with open(os.path.join(DRIVERS, "core", "phone.py")) as f:
            src = f.read()
        self.assertNotIn("ANR_WAIT", src)
        self.assertNotIn("g4.system.anr.wait", src)


class LinuxTest(unittest.TestCase):
    def surface(self, answer, alive=True, display=True):
        tmp = tempfile.mkdtemp()
        self.addCleanup(lambda: __import__("shutil").rmtree(tmp, ignore_errors=True))
        s = atspi.AtspiSurface(tmp, log=lambda *_: None)
        s.display_alive = lambda: display
        s.alive = lambda: alive
        s.asked = []
        s._call = lambda req, timeout=45, once=False: (s.asked.append((req["op"], timeout, once)), answer)[1]
        s._state = lambda: "stopped"
        return s

    def test_no_answer_from_the_app_is_a_freeze(self):
        s = self.surface(None)
        why = s.froze()
        self.assertIn("no AT-SPI answer from the app", why)
        self.assertIn("stopped", why)
        self.assertEqual(s.asked[0][0], "ping_app")
        self.assertTrue(s.asked[0][2])

    def test_an_answering_app_is_not_frozen(self):
        self.assertIsNone(self.surface({"ok": True, "app": True}).froze())

    def test_an_error_answer_for_the_whole_limit_is_a_freeze(self):
        s = self.surface({"ok": False, "error": "GLib.Error: no reply"})
        with unittest.mock.patch.object(freeze, "FREEZE_S", 0.6), unittest.mock.patch.object(atspi.time, "sleep"):
            why = s.froze()
        self.assertIn("no AT-SPI answer from the app", why)
        self.assertIn("no reply", why)
        self.assertGreater(len(s.asked), 1)   # asked again, not judged on one failed ping

    def test_one_failed_ping_while_the_app_starts_is_not_a_freeze(self):
        s = self.surface(None)
        answers = [{"ok": False, "error": "starting"}, {"ok": True, "app": True}]
        s._call = lambda req, timeout=45, once=False: answers.pop(0)
        self.assertIsNone(s.froze())

    def test_an_app_that_answered_and_left_the_bus_while_its_process_is_up_is_a_freeze(self):
        # a stopped app: the registry cannot read its name, so the worker finds no app at all
        s = self.surface({"ok": True, "app": False})
        s.seen_pid = 4242
        with unittest.mock.patch.object(freeze, "FREEZE_S", 0.6), unittest.mock.patch.object(atspi.time, "sleep"), \
                unittest.mock.patch.object(atspi.sandbox, "_pid", return_value=4242):
            self.assertIn("gone from the accessibility bus", s.froze())

    def test_an_app_not_yet_on_the_bus_is_not_a_freeze(self):
        s = self.surface({"ok": True, "app": False})
        self.assertIsNone(s.froze())

    def test_a_gone_display_or_app_is_not_a_freeze(self):
        self.assertIsNone(self.surface(None, display=False).froze())
        self.assertIsNone(self.surface(None, alive=False).froze())

    def test_log_lines_are_this_runs(self):
        s = self.surface({"ok": True})
        os.makedirs(os.path.dirname(s._log_path()))
        with open(s._log_path(), "w") as f:
            f.write("old ERROR dart.flutter: from an earlier run\n")
        s.cursor.mark()
        with open(s._log_path(), "a") as f:
            f.write("12:00:00 INFO dart.x: fine\n12:00:01 ERROR dart.flutter: boom\n")
        got = s.log_lines()
        self.assertEqual(len(got), 2)
        self.assertEqual(freeze.log_problem(got)[0], "unhandled error")
        self.assertEqual(s.log_lines(), [])


class WindowsTest(unittest.TestCase):
    class Rig:
        def __init__(self, answers):
            self.answers, self.calls = list(answers), []

        def call(self, op, timeout=120, **kw):
            self.calls.append((op, kw))
            return self.answers.pop(0)

    def surface(self, answers):
        return win_uia.WinSurface(self.Rig(answers), log=lambda *_: None, app_log="C:\\run\\home\\logs\\wfe.log")

    def test_a_hung_window_is_a_freeze(self):
        s = self.surface([{"ok": True, "app": True, "hung": 2, "offset": 10, "lines": []}])
        self.assertIn("gave no answer to a WM_NULL", s.froze())
        s = self.surface([{"ok": True, "app": True, "hung": 1, "offset": 10, "lines": []}])
        self.assertIn("IsHungAppWindow", s.froze())

    def test_a_window_that_answers_or_is_not_there_is_not_frozen(self):
        self.assertIsNone(self.surface([{"ok": True, "app": True, "hung": 0, "offset": 5, "lines": []}]).froze())
        self.assertIsNone(self.surface([{"ok": True, "app": False, "hung": 0, "offset": 5, "lines": []}]).froze())

    def test_log_offset_marks_then_reads_on(self):
        s = self.surface([{"ok": True, "app": True, "hung": 0, "offset": 100, "lines": []},
                          {"ok": True, "app": True, "hung": 0, "offset": 180, "lines": ["x ERROR dart.platform: boom"]}])
        self.assertEqual(s.log_lines(), [])
        self.assertEqual(s.rig.calls[0][1]["offset"], -1)   # the first read only marks the end
        self.assertEqual(s.log_lines(), ["x ERROR dart.platform: boom"])
        self.assertEqual(s.rig.calls[1][1]["offset"], 100)

    def test_froze_and_log_lines_share_one_agent_call(self):
        s = self.surface([{"ok": True, "app": True, "hung": 0, "offset": 9, "lines": ["StackOverflowError"]}])
        self.assertIsNone(s.froze())
        self.assertEqual(s.log_lines(), ["StackOverflowError"])
        self.assertEqual(len(s.rig.calls), 1)

    def test_a_tree_read_the_agent_refuses_for_a_hung_window_is_a_freeze(self):
        s = self.surface([{"ok": False, "hung": 2, "error": "app window hung"},
                          {"ok": True, "app": True, "hung": 2, "offset": 1, "procs": ["btwallet 1 responding=False"], "tail": "t"}])
        with self.assertRaises(freeze.Frozen) as cm:
            s.tree()
        self.assertIn("WM_NULL", cm.exception.what)
        self.assertIn("processes.txt", cm.exception.evidence)




if __name__ == "__main__":
    unittest.main()
