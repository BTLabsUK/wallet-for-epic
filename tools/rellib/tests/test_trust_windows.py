# SPDX-License-Identifier: Apache-2.0
"""The Windows update-trust driver (drivers/windows/trust.py): the click map by release and the checks
it makes from the candidate's own files (wfe.log, desk store) without the rig; and the v2 lane's surface
(uia.py) and platform (windows_platform.py) on a fake rig."""
import importlib.util
import os
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
from core.faults import HarnessFault  # noqa: E402

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
        s.last = [VIEW, {"ct": "Button", "name": "Mniej potwierdzeń", "pat": ["invoke"], "rect": rect}]
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


if __name__ == "__main__":
    unittest.main()
