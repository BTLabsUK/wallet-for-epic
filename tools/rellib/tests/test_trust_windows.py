# SPDX-License-Identifier: Apache-2.0
"""The Windows update-trust driver (drivers/windows/trust.py): the click map by release and the checks
it makes from the candidate's own files (wfe.log, desk store) without the rig; and the v2 lane's surface
(uia.py) and platform (windows_platform.py) on a fake rig."""
import importlib.util
import os
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
WIN = os.path.join(os.path.dirname(HERE), "drivers", "windows")
sys.path.insert(0, WIN)
_spec = importlib.util.spec_from_file_location("win_trust", os.path.join(WIN, "trust.py"))
wt = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(wt)

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


def run_with(lines):
    """A Run without the rig: its log and wfe.log in memory."""
    r = object.__new__(wt.Run)
    r.out = tempfile.mkdtemp()
    r.details, r.checks = {}, {c: False for c in wt.CHECKS}
    r.log_mark = 0
    r.first_start_lines = []
    r.custom_node, r.custom_relay = "127.0.0.1:4001", "127.0.0.1:4002"
    r.node, r.relay = "https://node.example.org", "epicbox.example.org"
    r.applog = lambda: list(lines)
    r.log = lambda s: None
    return r


class ClickMapTest(unittest.TestCase):
    def test_version(self):
        self.assertEqual(wt.version_tuple("26.10.24-r2"), (26, 10, 24))
        self.assertEqual(wt.version_tuple("26.10.25"), (26, 10, 25))
        self.assertEqual(wt.version_tuple(""), ())

    def test_previous_release_keeps_its_proven_points_only(self):
        self.assertEqual(wt.copy_points("26.10.24-r2"), ((487, 285), (487, 260)))
        self.assertEqual(wt.copy_points("26.10.23"), ((487, 285), (487, 260)))

    def test_narrow_layout_copies_beside_the_address_first(self):
        for v in ("26.10.25", "26.10.26-rc1", "27.1.0", ""):
            with self.subTest(v):
                pts = wt.copy_points(v)
                self.assertEqual(pts[0], (721, 249))
                self.assertIn((487, 285), pts)  # lands on the address text there: harmless

    def test_send_points_by_release(self):
        self.assertEqual(wt.send_points("26.10.24-r2"), ((380, 433), (716, 557), (705, 655)))
        for v in ("26.10.25", "26.10.26-rc1", ""):
            with self.subTest(v):
                self.assertEqual(wt.send_points(v), ((380, 195), (726, 348), (705, 655)))

    def test_installed_exe_from_the_uninstall_entry(self):
        loc = "C:\\Users\\epicrig\\Apps\\EpicWallet"
        self.assertEqual(wt.installed_exe({"location": loc, "exe": loc + "\\btwallet.exe"}), loc + "\\btwallet.exe")
        self.assertEqual(wt.installed_exe({"location": loc, "exe": '"%s\\btwallet.exe",0' % loc}), loc + "\\btwallet.exe")
        self.assertEqual(wt.installed_exe({"location": loc + "\\", "exe": None}), loc + "\\epic_wallet.exe")

    def test_points_inside_the_client(self):
        w, h = wt.CLIENT
        for p in [*wt.RAIL.values(), *wt.COPY_ADDRESS_NARROW, *wt.COPY_ADDRESS_OLD, *wt.SEND_OLD, *wt.SEND_NARROW]:
            self.assertTrue(0 < p[0] < w and 0 < p[1] < h, p)


class CandidateStartTest(unittest.TestCase):
    def test_clean_start(self):
        r = run_with([T + "dart.app: desktop start 26.10.25 (d341411), windows", T + "dart.unlock: wallet opened"])
        r.after_start_notes()
        self.assertEqual(r.first_start_lines, [])
        self.assertIn("ended cleanly", r.details["last_session"])

    def test_last_session_kept_as_a_fact(self):
        r = run_with([T + "dart.session: last session did not end cleanly: not closed"])
        r.after_start_notes()
        self.assertIn("not cleanly closed", r.details["last_session"])

    def test_first_start_and_server_pick_seen(self):
        r = run_with([T + "dart.levels: first start: no connection until the level is chosen",
                      T + "dart.network: first run: node https://a -> https://b"])
        r.after_start_notes()
        self.assertEqual(len(r.first_start_lines), 2)
        self.assertTrue(r.first_start_lines[0].startswith("first start"))

    def test_server_pick_fails_the_lists(self):
        r = run_with([])
        r.first_start_lines = ["first run: node https://a -> https://b"]
        lists = {"nodes": [r.custom_node, "node.example.org"], "node_in_use": "node.example.org", "nodes_added": [],
                 "relays": [], "relay_in_use": "", "relays_added": []}
        b = {"servers": lists}
        a = {"settings_toml": {"node": ["node.example.org", r.custom_node], "epicbox": []}}
        r.compare_list("node", b, a)
        self.assertFalse(r.checks["custom_nodes_kept"])
        self.assertIn("first run's server pick", r.details["custom_nodes_kept"])
        r.first_start_lines = []
        r.compare_list("node", b, a)
        self.assertTrue(r.checks["custom_nodes_kept"], r.details["custom_nodes_kept"])


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


class LoseNodeTest(unittest.TestCase):
    def platform(self, text):
        p = object.__new__(wp.WindowsPlatform)
        p.rig = FakeRig({})
        p.rig.files[p.data + "\\settings.toml"] = text
        p.surface = type("S", (), {"_call": lambda self_, op, timeout=120, **kw: p.rig.call(op, **kw)})()
        p.custom_node, p.log = "192.168.1.50:3413", lambda line: None
        return p

    def test_the_custom_node_line_goes(self):
        p = self.platform('[node]\nservers = ["node.example.org",\n "http://192.168.1.50:3413"]\nplain_http = []\n')
        p.break_lose_node()
        kept = p.rig.files[p.data + "\\settings.toml"]
        self.assertNotIn("192.168.1.50", kept)
        self.assertIn('servers = ["node.example.org",', kept)

    def test_no_custom_node_is_harness(self):
        p = self.platform('[node]\nservers = ["node.example.org"]\n')
        with self.assertRaises(HarnessFault):
            p.break_lose_node()


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
