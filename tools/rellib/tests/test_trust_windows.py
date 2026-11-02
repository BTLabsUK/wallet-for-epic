# SPDX-License-Identifier: Apache-2.0
"""The Windows update-trust driver (drivers/windows/trust.py): the click map by release and the checks
it makes from the candidate's own files (wfe.log, desk store) without the rig."""
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

    def test_installed_exe_from_the_uninstall_entry(self):
        loc = "C:\\Users\\epicrig\\Apps\\EpicWallet"
        self.assertEqual(wt.installed_exe({"location": loc, "exe": loc + "\\btwallet.exe"}), loc + "\\btwallet.exe")
        self.assertEqual(wt.installed_exe({"location": loc, "exe": '"%s\\btwallet.exe",0' % loc}), loc + "\\btwallet.exe")
        self.assertEqual(wt.installed_exe({"location": loc + "\\", "exe": None}), loc + "\\epic_wallet.exe")

    def test_points_inside_the_client(self):
        w, h = wt.CLIENT
        for p in [*wt.RAIL.values(), *wt.COPY_ADDRESS_NARROW, *wt.COPY_ADDRESS_OLD, wt.SEND_TO, wt.SEND_MAX, wt.SEND_REVIEW]:
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


if __name__ == "__main__":
    unittest.main()
