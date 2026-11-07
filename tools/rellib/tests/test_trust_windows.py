# SPDX-License-Identifier: Apache-2.0
"""The Windows lane's surface (uia.py) and platform (windows_platform.py) on a fake rig."""
import os
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
WIN = os.path.join(os.path.dirname(HERE), "drivers", "windows")
sys.path.insert(0, WIN)

# drivers/android has a uia.py too: these modules get the Windows one and leave the name as they found it.
_other_uia = sys.modules.pop("uia", None)
import rig as wrig  # noqa: E402
import uia  # noqa: E402
import windows_platform as wp  # noqa: E402
sys.modules.pop("uia")
if _other_uia is not None:
    sys.modules["uia"] = _other_uia
from core.faults import HarnessFault, InfraFault  # noqa: E402
from core.labels import Labels  # noqa: E402

T = "2026-11-01T10:00:00.000Z INFO  "


class FakeRig:
    run, user = "C:\\rig\\run", "epicrig"

    def __init__(self, files=None):
        self.files, self.calls = dict(files or {}), []

    def call(self, op, timeout=120, **kw):
        self.calls.append((op, kw))
        if op == "write_file":
            self.files[kw["file"]] = kw["text"]
        return {"ok": True}

    def text(self, path):
        return self.files.get(path)


VIEW = {"ct": "Custom", "name": "", "rect": [110, 35, 803, 691]}


class PressTest(unittest.TestCase):
    """26.10.26 on rig 1: the confirmations stepper lay below the window (y 1238, the window ends at 726) and
    a second press within 30 s was a click there, which reached nothing."""

    def surface(self, rect):
        s = uia.WinSurface(FakeRig(), log=lambda line: None)
        s.last = [VIEW, {"ct": "Button", "name": "Fewer confirmations", "pat": ["invoke"], "rect": rect}]
        s._unchanged = lambda node: False
        return s, s._node(1, s.last[1])

    def ops(self, s):
        return [op for op, _ in s.rig.calls]

    def test_a_node_below_the_window_is_never_clicked(self):
        s, node = self.surface([726, 1238, 38, 39])
        s.press(node)
        s.press(node)   # again within 30 s: still its default action
        self.assertEqual(self.ops(s), ["ui_at", "ui_at"])

    def test_a_node_in_view_pressed_again_is_clicked(self):
        s, node = self.surface([726, 400, 38, 39])
        s.press(node)
        s.press(node)
        self.assertEqual(self.ops(s), ["ui_at", "click_rect"])


class SshMasterTest(unittest.TestCase):
    def test_each_rig_session_has_its_own_ssh_master(self):
        """A lane that ends closes its ssh master; one on another rig, run at the same time, must keep its own."""
        ctl = tempfile.mkdtemp()
        paths = [next(o for o in wrig.Rig("win", "run", print, ctl, session=n).ssh_opts if o.startswith("ControlPath="))
                 for n in (1, 4, 5)]
        self.assertEqual(len(set(paths)), 3, paths)
        self.assertTrue(all(p.startswith("ControlPath=%s/" % ctl) for p in paths))


class InstallTest(unittest.TestCase):
    """_install: the app's store gets English before the first start; a leftover install is removed only
    when it is an earlier attempt of this same run."""
    BASE = "C:\\EpicRig1\\trust"

    def platform(self, entry, uninstall_ok=True):
        p = object.__new__(wp.WindowsPlatform)
        p.name_run = "tor-26.10.24-to-26.11.0-20261103-101010"
        p.step, p.logs = "rig", []
        p.log = p.logs.append
        state = {"entry": entry}
        p.rig = FakeRig()
        p.rig.base, p.rig.run = self.BASE, self.BASE + "\\runs\\" + p.name_run
        p.rig.state = state

        def call(op, timeout=120, **kw):
            p.rig.calls.append((op, kw))
            if op == "entry":
                return {"ok": True, "entry": state["entry"]}
            if op == "uninstall_leftover":
                if uninstall_ok:
                    state["entry"] = None
                return {"ok": uninstall_ok, "exit": 0 if uninstall_ok else 5, "error": None if uninstall_ok else "boom"}
            if op == "setup":
                return {"ok": True, "entry": {"version": "26.10.24", "location": p.rig.run + "\\home\\app", "exe": "x\\btwallet.exe,0"}}
            return {"ok": True}
        p.rig.call = call
        p.surface = type("S", (), {"_call": lambda self_, op, timeout=120, **kw: call(op, **kw)})()
        return p

    def ops(self, p):
        return [op for op, _ in p.rig.calls]

    def test_store_init_comes_right_after_the_previous_install(self):
        p = self.platform(None)
        p.install_previous()
        self.assertEqual(self.ops(p), ["entry", "setup", "store_init"])
        kw = p.rig.calls[-1][1]
        self.assertEqual(kw["file"], p.rig.run + "\\home\\.epic_cash_desktop\\flutter_secure_storage.dat")
        self.assertEqual(kw["set"], {"desk.settings": '{"language":"en"}'})

    def test_leftover_of_this_run_is_uninstalled(self):
        mine = self.BASE + "\\runs\\tor-26.10.24-to-26.11.0-20261103-090000\\home\\AppData\\Local\\Programs\\BT Wallet"
        p = self.platform({"name": "BT Wallet", "version": "26.10.24", "location": mine})
        p.install_previous()
        self.assertEqual(self.ops(p), ["entry", "uninstall_leftover", "entry", "setup", "store_init"])
        self.assertEqual(p.rig.calls[1][1], {"prefix": "tor-26.10.24-to-26.11.0"})
        self.assertTrue(any("leftover" in line for line in p.logs))

    def test_another_install_is_left_alone(self):
        for loc in (self.BASE + "\\runs\\notor-26.10.24-to-26.11.0-20261103-090000\\home\\app",
                    self.BASE + "\\runs\\tor-26.10.23-to-26.11.0-20261103-090000\\home\\app",
                    "C:\\Users\\epicrig\\AppData\\Local\\Programs\\BT Wallet",
                    self.BASE + "\\runs\\tor-26.10.24-to-26.11.0-20261103-090000x\\home"):
            with self.subTest(loc):
                p = self.platform({"name": "BT Wallet", "version": "26.10.24", "location": loc})
                with self.assertRaises(InfraFault) as e:
                    p.install_previous()
                self.assertEqual(e.exception.sub, "leftover")
                self.assertIn("left alone", e.exception.what)
                self.assertEqual(self.ops(p), ["entry"])

    def test_a_failed_uninstall_is_a_leftover_fault(self):
        mine = self.BASE + "\\runs\\tor-26.10.24-to-26.11.0-20261103-090000\\home\\app"
        p = self.platform({"name": "BT Wallet", "version": "26.10.24", "location": mine}, uninstall_ok=False)
        with self.assertRaises(InfraFault) as e:
            p.install_previous()
        self.assertEqual(e.exception.sub, "leftover")
        self.assertNotIn("setup", self.ops(p))


class SshRetryTest(unittest.TestCase):
    def rig(self, fails):
        calls, logs = [], []

        class R:
            host = "windows-pc"

            def ssh(self, command, timeout=120, check=True):
                calls.append(command)
                if len(calls) <= fails:
                    raise subprocess.TimeoutExpired("ssh", timeout)
                return "out"

            def put(self, local, remote):
                return None

            get = put
        return wp.retry_ssh(R(), logs.append, lambda: "start"), calls, logs

    def test_two_timeouts_are_retried_in_place(self):
        r, calls, logs = self.rig(2)
        self.assertEqual(r.ssh("x"), "out")
        self.assertEqual(len(calls), 3)
        self.assertEqual(len(logs), 2)

    def test_the_third_timeout_is_an_infra_fault(self):
        r, calls, logs = self.rig(9)
        with self.assertRaises(InfraFault) as e:
            r.ssh("x")
        self.assertEqual((e.exception.sub, e.exception.step), ("ssh", "start"))
        self.assertIn("timed out 3 times", e.exception.what)
        self.assertEqual(len(calls), 3)
        self.assertTrue(e.exception.line().startswith("INFRA start:"))


class EnglishLabelsTest(unittest.TestCase):
    def test_lanes_read_english_whatever_the_environment_says(self):
        import unittest.mock
        with unittest.mock.patch.dict(os.environ, {"REL_TRUST_LOCALE": "pl"}):
            l = Labels()
        self.assertEqual(l.locale, "en")
        self.assertEqual(l.arb, l.en)

    def test_for_locale_is_for_the_audit(self):
        pl, en = Labels.for_locale("pl"), Labels()
        self.assertEqual(pl.locale, "pl")
        self.assertNotEqual(pl.text("deskOnbUnlockTitle"), en.text("deskOnbUnlockTitle"))


if __name__ == "__main__":
    unittest.main()
