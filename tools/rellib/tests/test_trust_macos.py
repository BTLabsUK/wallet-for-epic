# SPDX-License-Identifier: Apache-2.0
"""The macOS lane (drivers/trust-macos.sh, drivers/macos/): its plan, env contract, build finding,
fail-closed proof, signing decision, dialog guard and the AX tree on a recorded window."""
import json
import os
import pathlib
import re
import subprocess
import sys
import tempfile
import types
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
DRIVERS = os.path.join(os.path.dirname(HERE), "drivers")
TRUST = os.path.join(DRIVERS, "trust-macos.sh")
LANE = os.path.join(DRIVERS, "macos", "lane.py")
FIXTURE = os.path.join(DRIVERS, "fixtures", "macos-ax-welcome-26.11.3.json")
sys.path.insert(0, DRIVERS)

# ios/ and linux/ have a files.py too: these modules get the macOS one and leave the names as they found them.
_saved = {k: sys.modules.pop(k, None) for k in ("files", "ax", "mac")}
sys.path.insert(0, os.path.join(DRIVERS, "macos"))
import macos_platform as mp  # noqa: E402
import ax  # noqa: E402
sys.path.remove(os.path.join(DRIVERS, "macos"))
for k, v in _saved.items():
    sys.modules.pop(k, None)
    if v is not None:
        sys.modules[k] = v
from core.faults import HarnessFault  # noqa: E402

DEVID = ('identifier "uk.btlabs.btwallet.macos" and anchor apple generic and certificate 1[field.1.2.840.113635.100.6.2.6] '
         '/* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate '
         'leaf[subject.OU] = AM8YPW9P6T')


def run_trust(env, *args):
    base = {k: v for k, v in os.environ.items() if not k.startswith("REL_")}
    base.update(env)
    return subprocess.run(["bash", TRUST] + list(args), env=base, capture_output=True, text=True, timeout=90)


class Files(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.d = self.tmp.name

    def tearDown(self):
        self.tmp.cleanup()

    def put(self, *parts):
        p = os.path.join(self.d, *parts)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        pathlib.Path(p).touch()
        return p


class BuildFileTest(Files):
    def test_the_release_dmg_by_its_exact_name(self):
        f = self.put("bt-wallet-26.11.3-macos.dmg")
        self.put("bt-wallet-26.11.3-notor-macos.dmg")
        self.assertEqual(mp.build_file(self.d, "26.11.3", "tor"), f)

    def test_the_notor_dmg_in_the_macos_folder(self):
        f = self.put("macos", "bt-wallet-26.11.3-notor-macos.dmg")
        self.put("macos", "bt-wallet-26.11.3-macos.dmg")
        self.assertEqual(mp.build_file(self.d, "26.11.3", "notor"), f)

    def test_a_test_builds_tar_of_the_variant(self):
        f = self.put("tor", "bt-wallet-f1c2d50ad614-tor-macos.tar")
        self.assertEqual(mp.build_file(os.path.join(self.d, "tor"), "26.11.4", "tor"), f)
        self.assertIsNone(mp.build_file(os.path.join(self.d, "tor"), "26.11.4", "notor"))

    def test_a_tor_dmg_is_not_taken_for_notor(self):
        self.put("bt-wallet-26.11.3-macos.dmg")
        self.assertIsNone(mp.build_file(self.d, "26.11.3", "notor"))

    def test_two_test_builds_of_one_variant_are_refused(self):
        self.put("bt-wallet-aaaa-tor-macos.tar")
        self.put("bt-wallet-bbbb-tor-macos.zip")
        with self.assertRaises(HarnessFault):
            mp.build_file(self.d, "", "tor")

    def test_a_missing_folder_is_none(self):
        self.assertIsNone(mp.build_file(os.path.join(self.d, "nothing"), "26.11.3", "tor"))
        self.assertIsNone(mp.build_file("", "26.11.3", "tor"))

    def test_kinds(self):
        os.makedirs(os.path.join(self.d, "BT Wallet.app"))
        self.assertEqual(mp.kind_of(os.path.join(self.d, "BT Wallet.app")), "app")
        self.assertEqual(mp.kind_of(self.put("x.dmg")), "dmg")
        self.assertEqual(mp.kind_of("mac:/Users/x/BT Wallet.app"), "mac-app")
        self.assertIsNone(mp.kind_of(os.path.join(self.d, "missing.tar")))


class EnvTest(Files):
    """The REL_* contract as macos_platform reads it, with no Mac touched."""

    def platform(self, env):
        keep = {k: os.environ.pop(k) for k in list(os.environ) if k.startswith("REL_")}
        os.environ.update({"REL_HOSTS": os.path.join(self.d, "no-hosts.toml"), "REL_MAC_SSH": "a-mac",
                           "REL_MAC_TERM": "/x/term", **env})
        try:
            return mp.MacosPlatform(self.d, lambda s: None)
        finally:
            for k in list(os.environ):
                if k.startswith("REL_"):
                    del os.environ[k]
            os.environ.update(keep)

    def test_contract(self):
        prev = self.put("prev", "bt-wallet-26.11.3-macos.dmg")
        cand = self.put("cand", "bt-wallet-f1c2d50ad614-tor-macos.tar")
        p = self.platform({"REL_PREVIOUS_DIR": os.path.dirname(prev), "REL_PREVIOUS_VERSION": "26.11.3",
                           "REL_CANDIDATE_DIR": os.path.dirname(cand), "REL_CANDIDATE_VERSION": "26.11.4",
                           "REL_VARIANT": "tor", "REL_MAC_SSH": "a-mac", "REL_NODE": "n.example", "REL_EPICBOX": "r.example"})
        self.assertEqual(p.find_builds(), {"previous": prev, "candidate": cand})
        self.assertEqual(p.mac.host, "a-mac")
        self.assertEqual((p.node, p.relay), ("n.example", "r.example"))
        self.assertTrue(mp.RUN_NAME.match(p.name_run))
        self.assertTrue(p.name_run.startswith("tor-26.11.3-to-26.11.4-"))
        self.assertFalse(p.keep)

    def test_the_mac_has_this_lanes_own_ssh_master(self):
        p = self.platform({})
        cp = [o for o in p.mac.opts if o.startswith("ControlPath=")]
        self.assertEqual(cp, ["ControlPath=%s/cm-%%C" % mp.CACHE])
        self.assertIn("rel-trust-macos", cp[0])

    def test_the_mac_and_its_terminal_come_from_the_hosts_file(self):
        hosts = os.path.join(self.d, "hosts.toml")
        with open(hosts, "w") as f:
            f.write('[host.apple]\nssh = "mac-b"\nmac_term = "/opt/t"\n')
        p = self.platform({"REL_HOSTS": hosts, "REL_MAC_SSH": "", "REL_MAC_TERM": ""})
        self.assertEqual((p.mac.host, p.term), ("mac-b", "/opt/t"))
        p = self.platform({"REL_HOSTS": hosts, "REL_MAC_SSH": "mac-c", "REL_MAC_TERM": "/env/t"})
        self.assertEqual((p.mac.host, p.term), ("mac-c", "/env/t"))

    def test_no_mac_or_terminal_named_is_a_harness_fault(self):
        for env in ({"REL_MAC_SSH": ""}, {"REL_MAC_TERM": ""}):
            with self.assertRaises(mp.HarnessFault) as c:
                self.platform(env)
            self.assertIn("REL_MAC_SSH" if "REL_MAC_SSH" in env else "REL_MAC_TERM", str(c.exception))

    def test_an_app_given_by_path_wins_over_the_folder(self):
        self.put("cand", "bt-wallet-f1c2d50ad614-tor-macos.tar")
        p = self.platform({"REL_TRUST_MODE": "create", "REL_CANDIDATE_DIR": os.path.join(self.d, "cand"),
                           "REL_CANDIDATE_APP": "mac:/Users/x/BT Wallet.app"})
        self.assertEqual(p.find_builds(), {"candidate": "mac:/Users/x/BT Wallet.app"})

    def test_a_missing_candidate_is_a_harness_fault(self):
        self.put("prev", "bt-wallet-26.11.3-macos.dmg")
        p = self.platform({"REL_PREVIOUS_DIR": os.path.join(self.d, "prev"), "REL_PREVIOUS_VERSION": "26.11.3",
                           "REL_CANDIDATE_DIR": os.path.join(self.d, "nothing")})
        with self.assertRaises(HarnessFault) as c:
            p.find_builds()
        self.assertIn("no candidate tor macOS build", str(c.exception))


class SigningTest(unittest.TestCase):
    def test_requirements(self):
        out = "Executable=/x/BT Wallet.app/Contents/MacOS/btwallet\ndesignated => %s\n" % DEVID
        self.assertEqual(mp.designated(out), DEVID)
        self.assertEqual(mp.devid_team(DEVID), "AM8YPW9P6T")
        self.assertFalse(mp.adhoc(DEVID))
        self.assertTrue(mp.adhoc("cdhash H\"0123abcd\""))
        self.assertIsNone(mp.devid_team("cdhash H\"0123abcd\""))
        self.assertIsNone(mp.designated("code object is not signed at all"))
        adhoc_out = "Executable=/x/BT Wallet.app/Contents/MacOS/btwallet\n# designated => cdhash H\"3af812\"\n"
        self.assertTrue(mp.adhoc(mp.designated(adhoc_out)))

    def plat(self, prev, cand):
        p = mp.MacosPlatform.__new__(mp.MacosPlatform)
        p.create, p.log, p.health = False, lambda s: None, {}
        p.info = {"previous": {"requirement": prev, "signer": "p"}, "candidate": {"requirement": cand, "signer": "c"}}
        p.signed = []
        p.apps = {"candidate": "/c/BT Wallet.app"}
        p._devid_sign = lambda app: p.signed.append(app)
        p._app_info = lambda app: {"requirement": DEVID, "signer": "Developer ID AM8YPW9P6T"}
        return p

    def test_the_same_requirement_is_left_as_it_is(self):
        p = self.plat(DEVID, DEVID)
        p._signing()
        self.assertEqual(p.signed, [])

    def test_an_ad_hoc_candidate_after_a_developer_id_release_is_signed(self):
        p = self.plat(DEVID, 'cdhash H"0123"')
        p._signing()
        self.assertEqual(p.signed, ["/c/BT Wallet.app"])
        self.assertIn("Developer ID", p.health["resigned"])

    def test_another_signer_refuses_the_run(self):
        other = DEVID.replace("AM8YPW9P6T", "ZZZZZZZZZZ")
        p = self.plat(DEVID, other)
        with self.assertRaises(HarnessFault):
            p._signing()
        p = self.plat('cdhash H"01"', 'cdhash H"02"')
        with self.assertRaises(HarnessFault):
            p._signing()


class FakeMac:
    def __init__(self, answers):
        self.answers, self.cmds = list(answers), []

    def run(self, cmd, timeout=120, inp=None, text=True, check=False):
        self.cmds.append((cmd, inp))
        out = json.dumps(self.answers.pop(0)) if " call " in cmd and self.answers else ""
        return types.SimpleNamespace(returncode=0, stdout=out, stderr="")


class GuardTest(unittest.TestCase):
    DIALOG = {"owner": "SecurityAgent", "pid": 77, "layer": 0}

    def surface(self, answers, pid):
        return ax.MacSurface(FakeMac(answers), "/h", "/s", pid, log=lambda s: None)

    def test_a_dialog_on_screen_before_the_start_refuses_it_and_is_not_touched(self):
        s = self.surface([{"ok": True, "windows": [self.DIALOG]}], 5)
        with self.assertRaises(ax.SystemDialog):
            s.guard_start()
        self.assertEqual(len(s.mac.cmds), 1)

    def test_a_dialog_that_names_the_lane_stops_the_app_and_is_cancelled(self):
        dialog_tree = {"ok": True, "nodes": [
            {"role": "AXStaticText", "value": "BT Wallet wants to use the lane.keychain keychain.", "path": [0, 0]},
            {"role": "AXButton", "title": "Cancel", "path": [0, 1]}]}
        s = self.surface([{"ok": True, "windows": []}, {"ok": True, "windows": [self.DIALOG]}, dialog_tree,
                          {"ok": True}, {"ok": True, "windows": []}], 4242)
        s.guard_start()
        with self.assertRaises(ax.SystemDialog) as c:
            s.guard(force=True)
        cmds = [c for c, _ in s.mac.cmds]
        self.assertIn("kill -TERM 4242 2>/dev/null; true", cmds)
        press = [json.loads(i) for c, i in s.mac.cmds if i and json.loads(i)["op"] == "press"]
        self.assertEqual(press[0]["pid"], 77)
        self.assertIn("It is gone", c.exception.what)

    def test_a_helper_only_guard_kills_nothing(self):
        s = self.surface([{"ok": True, "windows": []}, {"ok": True, "windows": [self.DIALOG]},
                          {"ok": True, "nodes": []}, {"ok": True, "windows": []}], 0)
        s.guard_start()
        with self.assertRaises(ax.SystemDialog):
            s.guard(force=True)
        self.assertFalse(any(c.startswith("kill") for c, _ in s.mac.cmds))

    def test_a_dialog_of_something_else_is_left_alone(self):
        tree = {"ok": True, "nodes": [{"role": "AXStaticText", "value": "Mail wants to use login", "path": [0, 0]},
                                      {"role": "AXButton", "title": "Cancel", "path": [0, 1]}]}
        s = self.surface([{"ok": True, "windows": []}, {"ok": True, "windows": [self.DIALOG]}, tree,
                          {"ok": True, "windows": [self.DIALOG]}], 9)
        s.guard_start()
        with self.assertRaises(ax.SystemDialog) as c:
            s.guard(force=True)
        self.assertFalse(any(i and json.loads(i)["op"] == "press" for _, i in s.mac.cmds))
        self.assertIn("STILL ON SCREEN", c.exception.what)


class TreeTest(unittest.TestCase):
    """The 26.11.3 welcome window as the helper read it on the Mac."""

    def setUp(self):
        with open(FIXTURE) as f:
            self.nodes = ax.parse(json.load(f)["nodes"])

    def by(self, name):
        return next(n for n in self.nodes if n.name.startswith(name))

    def test_the_windows_chrome_and_layout_groups_are_left_out(self):
        names = [(n.role, n.name.split("\n")[0]) for n in self.nodes]
        # the Flutter view, then the page: no window, title, close/zoom/minimise or nameless group
        self.assertEqual(names[:3], [("other", "BT Wallet"), ("text", "BT Wallet"), ("text", names[2][1])])
        self.assertEqual(len(names), 9)
        self.assertFalse(any(n.role == "other" and not n.name for n in self.nodes))

    def test_buttons_switch_and_texts(self):
        create = self.by("Create a new wallet")
        self.assertEqual(create.role, "button")
        self.assertIn("press", create.actions)
        self.assertIn("enabled", create.states)
        tor = self.by("Tor only")
        self.assertEqual(tor.role, "toggle")
        self.assertNotIn("checked", tor.states)
        self.assertEqual(self.by("BT Wallet 26.11.3").role, "text")
        self.assertEqual(self.by("Keys and coins").role, "text")

    def test_each_node_keeps_its_path_for_the_press(self):
        create = self.by("Create a new wallet")
        self.assertEqual(create.ref["path"], [0, 0, 0, 0, 0, 0, 0, 2])
        self.assertTrue(create.ref["key"].startswith("AXButton\x01Create a new wallet"))
        self.assertIn("showing", create.states)


class RestoreTreeTest(unittest.TestCase):
    """26.11.3's restore screen as the helper read it on the Mac (run-16): 24 word fields with no name."""

    def setUp(self):
        with open(os.path.join(DRIVERS, "fixtures", "macos-ax-restore-26.11.3.json")) as f:
            self.nodes = ax.parse(json.load(f)["nodes"])

    def test_the_grid_fields_are_named_word_n_row_by_row(self):
        fields = [n for n in self.nodes if n.role == "text_field"]
        self.assertEqual(len(fields), 24)
        self.assertEqual([f.name for f in fields], ["Word %d" % k for k in range(1, 25)])
        f5 = fields[4].ref["frame"]   # Word 5 opens the second row, under Word 1
        self.assertEqual(f5[0], fields[0].ref["frame"][0])
        self.assertGreater(f5[1], fields[3].ref["frame"][1])

    def test_the_drivers_word_targets_find_their_field(self):
        from core import targets as tg
        from dataclasses import replace
        for i in (1, 2, 13, 24):
            name = "re:(?:.* )?%s(?: .*)?" % re.escape(tg._norm("Word %d" % i))
            t = tg.T("g4.restore.phrase").at(None, names=(name,)) if i == 1 else \
                replace(tg.T("g4.restore.word.*").at(i, names=(name,)), kind="named")
            hits = tg.find(t, self.nodes)
            self.assertTrue(hits, "Word %d" % i)
            self.assertEqual(hits[0].name, "Word %d" % i)

    def test_a_short_run_of_unnamed_fields_is_left_alone(self):
        raw = [{"path": [0], "role": "AXWindow", "frame": [0, 0, 900, 700]}] + [
            {"path": [0, 0, k], "role": "AXTextField", "value": "", "frame": [10, 10 + 40 * k, 100, 30]} for k in range(3)]
        self.assertEqual([n.name for n in ax.parse(raw)], ["", "", ""])


class TrustShTest(Files):
    def test_dry_run_names_the_builds_and_the_checks(self):
        prev = self.put("prev", "bt-wallet-26.11.3-macos.dmg")
        cand = self.put("cand", "bt-wallet-f1c2d50ad614-tor-macos.tar")
        out = os.path.join(self.d, "out")
        r = run_trust({"REL_DRY_RUN": "1", "REL_OUT": out, "REL_PREVIOUS_DIR": os.path.dirname(prev),
                       "REL_PREVIOUS_VERSION": "26.11.3", "REL_CANDIDATE_DIR": os.path.dirname(cand),
                       "REL_CANDIDATE_VERSION": "26.11.4", "REL_FUNDS": "0"})
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("PLAN previous tor: " + prev, r.stdout)
        self.assertIn("PLAN candidate tor: " + cand, r.stdout)
        checks = [l for l in r.stdout.splitlines() if l.startswith("PLAN macos lane, checks: ")][0]
        self.assertIn("balance_kept", checks)
        self.assertNotIn("send_ok", checks)
        self.assertFalse(os.path.exists(out))

    def test_dry_run_with_funds_lists_the_payments(self):
        r = run_trust({"REL_DRY_RUN": "1", "REL_OUT": os.path.join(self.d, "out"), "REL_FUNDS": "1"})
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("send_ok", r.stdout)
        self.assertIn("PLAN candidate tor: NONE", r.stdout)

    def test_without_rel_out_it_cannot_run(self):
        r = run_trust({})
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("REL_OUT", r.stderr)

    def test_an_unreachable_mac_fails_closed(self):
        out = os.path.join(self.d, "out")
        r = run_trust({"REL_OUT": out, "REL_MAC_SSH": "no-such-mac.invalid", "REL_FUNDS": "0"})
        self.assertEqual(r.returncode, 2)
        with open(os.path.join(out, "proof.json")) as f:
            proof = json.load(f)
        self.assertTrue(proof["checks"])
        self.assertFalse(any(proof["checks"].values()))
        with open(os.path.join(out, "result.txt")) as f:
            self.assertIn("does not answer", f.read())

    def test_checks_lists_the_required_checks(self):
        r = subprocess.run([sys.executable, "-I", LANE, "checks"], capture_output=True, text=True, timeout=60,
                           env={k: v for k, v in os.environ.items() if not k.startswith("REL_")})
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("settings_kept", r.stdout.strip().split(","))


if __name__ == "__main__":
    unittest.main()
