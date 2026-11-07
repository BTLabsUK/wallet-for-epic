# SPDX-License-Identifier: Apache-2.0
"""The trust lanes on this host's hermetic node and relay (drivers/core/hermetic.py plan()): the plan's
decisions and why, each platform's servers from it (Linux loopback, Android adb reverses, the Windows
ssh remote forward on a fake ssh), P held to the local relay, live-servers only with funds, and the
evidence (details["hermetic"], details["non_local"], the saved state's meta). No app, emulator, rig,
node or relay."""
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

HERE = os.path.dirname(os.path.abspath(__file__))
DRIVERS = os.path.join(os.path.dirname(HERE), "drivers")
sys.path.insert(0, DRIVERS)

from core import checks, hermetic, lane as core_lane, state as st  # noqa: E402
from core.faults import HarnessFault  # noqa: E402

NODE, RELAY = "http://127.0.0.1:43413", "127.0.0.1:43423"
BOTH = {"node": NODE, "relay": RELAY}
P_PUBLIC, P_LOCAL = "esP@epicbox.stackwallet.com", "esP@127.0.0.1:43423"


def load(plat, mod):
    """drivers/<plat>/<mod>.py under a name of its own, with that folder's files.py and uia.py (each
    platform has its own) and the names left in sys.modules as they were found."""
    clash = ("files", "uia", "rig", "lane", "trust")
    kept = {k: sys.modules.pop(k) for k in clash if k in sys.modules}
    folder = os.path.join(DRIVERS, plat)
    sys.path.insert(0, folder)
    try:
        spec = importlib.util.spec_from_file_location("hw_%s_%s" % (plat, mod), os.path.join(folder, mod + ".py"))
        m = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(m)
        return m
    finally:
        sys.path.remove(folder)
        for k in clash:
            sys.modules.pop(k, None)
        sys.modules.update(kept)


lp = load("linux", "linux_platform")
ap = load("android", "android_platform")
wp = load("windows", "windows_platform")
wrig = load("windows", "rig")
pf = load("linux", "p_funder")


class PlanTest(unittest.TestCase):
    def test_both_local_when_p_posts_through_the_local_relay(self):
        h = hermetic.plan(P_LOCAL, env={}, svc=BOTH)
        self.assertTrue(h["on"])
        self.assertEqual((h["node"], h["relay"], h["ports"]), (NODE, RELAY, [43413, 43423]))
        self.assertIn("local node %s and local relay %s in use" % (NODE, RELAY), h["reason"])

    def test_node_alone_when_p_posts_through_a_public_relay(self):
        h = hermetic.plan(P_PUBLIC, env={}, svc=BOTH)
        self.assertFalse(h["on"])
        self.assertEqual((h["node"], h["relay"], h["ports"]), (NODE, None, [43413]))
        self.assertIn("P (the funder) posts through epicbox.stackwallet.com, not the local relay", h["reason"])

    def test_no_status_falls_back_to_the_stand_ins_and_says_why(self):
        h = hermetic.plan(P_LOCAL, env={}, svc={"node": None, "relay": None})
        self.assertEqual((h["on"], h["node"], h["relay"], h["ports"]), (False, None, None, []))
        self.assertIn("no healthy local node", h["reason"])
        self.assertIn("no healthy local relay", h["reason"])

    def test_rel_hermetic_0_uses_neither(self):
        h = hermetic.plan(P_LOCAL, env={"REL_HERMETIC": "0"}, svc=BOTH)
        self.assertEqual((h["on"], h["node"], h["relay"], h["ports"]), (False, None, None, []))
        self.assertIn("REL_HERMETIC=0", h["reason"])

    def test_rel_hermetic_1_with_one_missing_is_the_harness(self):
        for p_addr, svc in ((P_LOCAL, {"node": NODE, "relay": None}), (P_PUBLIC, BOTH)):
            with self.assertRaises(HarnessFault) as c:
                hermetic.plan(p_addr, env={"REL_HERMETIC": "1"}, svc=svc)
            self.assertEqual(c.exception.step, "prepare")
        self.assertTrue(hermetic.plan(P_LOCAL, env={"REL_HERMETIC": "1"}, svc=BOTH)["on"])

    def test_live_pair_from_the_env_or_the_first_that_answers(self):
        self.assertEqual(hermetic.pick_live(lambda u: u.endswith("b.test"), lambda h: True, ["a.test", "b.test"], ["r.test"], env={}),
                         ("https://b.test", "r.test"))
        self.assertEqual(hermetic.pick_live(lambda u: False, lambda h: False, [], [], env={"REL_NODE": "n.test", "REL_EPICBOX": "e.test"}),
                         ("https://n.test", "e.test"))
        with self.assertRaises(HarnessFault) as c:
            hermetic.pick_live(lambda u: False, lambda h: True, ["a.test"], ["r.test"], env={})
        self.assertEqual(c.exception.step, "live-servers")

    def test_hosts_a_log_line_names(self):
        self.assertEqual(hermetic.log_hosts("GET http://127.0.0.1:43413/v2/foreign 200"), ["127.0.0.1:43413"])
        self.assertEqual(hermetic.log_hosts("epicbox: relay=epic.example.org connected"), ["epic.example.org"])
        self.assertEqual(hermetic.log_hosts("balance 3.0000 EPIC"), [])


class LinuxServersTest(unittest.TestCase):
    def platform(self, plan, node="https://node.pub", relay="box.pub"):
        p = object.__new__(lp.LinuxPlatform)
        p.out, p.log, p.standins, p.hermetic = tempfile.mkdtemp(prefix="hw-linux-"), lambda line: None, [], plan
        p.node, p.relay, p.ports = node, relay, {}
        return p

    def standins(self, p):
        started = []
        with mock.patch.object(lp.subprocess, "Popen", lambda args, **kw: started.append(args[-3]) or object()), \
                mock.patch.object(lp, "free_port", lambda: 5101), mock.patch.object(lp, "node_up", lambda u: True), \
                mock.patch.object(lp.time, "sleep", lambda s: None):
            p._standins()
        return started

    def test_the_local_node_is_its_own_custom_server_and_the_relay_gets_a_stand_in(self):
        p = self.platform(hermetic.plan(P_PUBLIC, env={}, svc=BOTH))
        p.node = p.relay = ""
        with mock.patch.object(lp, "relay_up", lambda h: True):
            p._pick_servers()
        self.assertEqual((p.node, p.relay), (NODE, lp.facts.RELAY_PICK[0]))
        self.assertEqual(self.standins(p), ["relay"])
        self.assertEqual((p.custom_node, p.custom_relay), ("127.0.0.1:43413", "127.0.0.1:5101"))

    def test_both_local_start_no_stand_in(self):
        p = self.platform(hermetic.plan(P_LOCAL, env={}, svc=BOTH))
        p._pick_servers()
        self.assertEqual((p.node, p.relay), (NODE, RELAY))
        self.assertEqual(self.standins(p), [])
        self.assertEqual((p.custom_node, p.custom_relay), ("127.0.0.1:43413", RELAY))

    def test_a_state_saved_on_public_servers_does_not_fit_a_local_node(self):
        p = self.platform(None, node=NODE, relay="box.pub")
        p.variant = "tor"
        ok, why = p.fits({"platform": "linux", "variant": "tor"})
        self.assertFalse(ok)
        self.assertIn("saved with node public, relay public in use, this run uses node local, relay public", why)
        self.assertEqual(p.fits({"platform": "linux", "variant": "tor", "hermetic": {"node": True, "relay": False}}), (True, ""))


class AndroidServersTest(unittest.TestCase):
    def platform(self, plan):
        p = object.__new__(ap.AndroidPlatform)
        p.out, p.log, p.standins, p.hermetic = tempfile.mkdtemp(prefix="hw-android-"), lambda line: None, [], plan
        p.node, p.relay = (plan.get("node") or "https://node.pub"), (plan.get("relay") or "box.pub")
        p.dev, p.resume_ports = mock.Mock(), {}
        return p

    def standins(self, p):
        with mock.patch.object(ap.subprocess, "Popen", lambda *a, **kw: object()), \
                mock.patch.object(ap, "free_port", lambda: 5201), mock.patch.object(ap, "node_up", lambda u: True), \
                mock.patch.object(ap.time, "sleep", lambda s: None):
            p._standins()

    def reverses(self, p):
        p._reverse()
        return [c.args for c in p.dev.run.call_args_list]

    def test_the_local_ports_go_to_adb_reverse(self):
        p = self.platform(hermetic.plan(P_LOCAL, env={}, svc=BOTH))
        self.standins(p)
        self.assertEqual(p.ports, [43413, 43423])
        self.assertEqual(self.reverses(p), [("reverse", "tcp:43413", "tcp:43413"), ("reverse", "tcp:43423", "tcp:43423")])
        self.assertEqual((p.custom_node, p.custom_relay), ("127.0.0.1:43413", RELAY))

    def test_the_local_node_beside_the_relays_stand_in(self):
        p = self.platform(hermetic.plan(P_PUBLIC, env={}, svc=BOTH))
        self.standins(p)
        self.assertEqual(sorted(p.ports), [5201, 43413])
        self.assertEqual((p.custom_node, p.custom_relay), ("127.0.0.1:43413", "127.0.0.1:5201"))


class FakeRig:
    def __init__(self, forward_error=None):
        self.forwards, self.calls, self.forward_error = [], [], forward_error

    def forward(self, ports):
        self.forwards.append(list(ports))
        if self.forward_error:
            raise wp.RigError(self.forward_error)
        return True

    def call(self, op, timeout=120, **kw):
        self.calls.append((op, kw))
        return {"ok": True, "node": 6001, "relay": 6002}


class WindowsServersTest(unittest.TestCase):
    def platform(self, plan, rig=None):
        p = object.__new__(wp.WindowsPlatform)
        p.rig, p.hermetic, p.ports, p.log = rig or FakeRig(), plan, {}, lambda line: None
        p.node, p.relay = (plan.get("node") or "https://node.pub"), (plan.get("relay") or "box.pub")
        return p

    def test_both_local_are_forwarded_and_the_agents_stand_ins_skipped(self):
        p = self.platform(hermetic.plan(P_LOCAL, env={}, svc=BOTH))
        p._servers()
        self.assertEqual((p.rig.forwards, p.rig.calls), ([[43413, 43423]], []))
        self.assertEqual((p.custom_node, p.custom_relay), ("127.0.0.1:43413", RELAY))

    def test_the_local_node_forwarded_and_the_relays_stand_in_on_the_rig(self):
        p = self.platform(hermetic.plan(P_PUBLIC, env={}, svc=BOTH))
        p._servers()
        self.assertEqual(p.rig.forwards, [[43413]])
        self.assertEqual([op for op, _ in p.rig.calls], ["standins"])
        self.assertEqual((p.custom_node, p.custom_relay), ("127.0.0.1:43413", "127.0.0.1:6002"))
        p._servers(again=True)  # a recovery asks the agent for the same ports
        self.assertEqual(p.rig.calls[-1][1]["relay_port"], 6002)

    def test_nothing_local_is_the_stand_ins_as_before(self):
        p = self.platform(hermetic.plan(P_PUBLIC, env={"REL_HERMETIC": "0"}, svc=BOTH))
        p._servers()
        self.assertEqual(p.rig.forwards, [[]])
        self.assertEqual((p.custom_node, p.custom_relay), ("127.0.0.1:6001", "127.0.0.1:6002"))

    def test_a_refused_forward_is_the_harness(self):
        p = self.platform(hermetic.plan(P_LOCAL, env={}, svc=BOTH), FakeRig("administratively prohibited"))
        with self.assertRaises(HarnessFault) as c:
            p._servers(again=True)
        self.assertEqual(c.exception.step, "recover")


class WindowsHermeticOffTest(unittest.TestCase):
    """The Windows lanes leave the hermetic plan off unless REL_HERMETIC_WINDOWS=1 (26.11.0 run-4)."""

    def test_off_by_default(self):
        self.assertFalse(hermetic.plan(P_LOCAL, env=wp.windows_env({}), svc=BOTH)["node"])
        self.assertFalse(hermetic.plan(P_LOCAL, env=wp.windows_env({"REL_HERMETIC": "1"}), svc=BOTH)["node"])

    def test_on_when_asked(self):
        self.assertTrue(hermetic.plan(P_LOCAL, env=wp.windows_env({"REL_HERMETIC_WINDOWS": "1"}), svc=BOTH)["on"])


class RigForwardTest(unittest.TestCase):
    """rig.py forward() on a fake ssh: the commands it would give the rig's ControlMaster."""

    def rig(self, check_rc=0, forward=(0, "")):
        self.ran, self.logs = [], []
        r = wrig.Rig("win", "run", self.logs.append, tempfile.mkdtemp(prefix="hw-rig-"), session=1)

        def run(args, **kw):
            self.ran.append(args)
            rc, err = (check_rc, "") if "check" in args else forward if "forward" in args else (0, "up")
            return subprocess.CompletedProcess(args, rc, stdout="up\n" if rc == 0 else "", stderr=err)
        patch = mock.patch.object(wrig.subprocess, "run", run)
        patch.start()
        self.addCleanup(patch.stop)
        return r

    def test_the_ports_ride_this_sessions_master(self):
        r = self.rig()
        self.assertTrue(r.forward([43413, 43423]))
        fwd = self.ran[-1]
        self.assertEqual(fwd[fwd.index("-O"):], ["-O", "forward", "-R", "43413:127.0.0.1:43413", "-R", "43423:127.0.0.1:43423", "win"])
        self.assertIn(next(o for o in r.ssh_opts if o.startswith("ControlPath=")), fwd)
        self.assertEqual(len(self.ran), 2)  # -O check, then the forward: no new master

    def test_no_master_yet_makes_one_first(self):
        r = self.rig(check_rc=255)
        r.forward([43413])
        self.assertEqual(self.ran[1][-1], "echo up")
        self.assertIn("forward", self.ran[2])

    def test_a_port_another_lanes_master_holds_is_taken_and_logged(self):
        r = self.rig(forward=(255, "Error: remote port forwarding failed for listen port 43413"))
        self.assertTrue(r.forward([43413]))
        self.assertIn("another lane's forward", self.logs[-1])

    def test_any_other_refusal_is_a_rig_error(self):
        r = self.rig(forward=(255, "mux_client_forward: forwarding request failed: Port forwarding is disabled"))
        with self.assertRaises(wrig.RigError):
            r.forward([43413])

    def test_no_ports_no_ssh(self):
        r = self.rig()
        self.assertTrue(r.forward([]))
        self.assertEqual(self.ran, [])


class PRelayTest(unittest.TestCase):
    def p(self, answer):
        p = object.__new__(pf.P)
        p.client = mock.Mock()
        p.client.call.side_effect = answer
        return p

    def test_ps_relay_is_its_address_domain(self):
        self.assertEqual(self.p(lambda *a, **kw: {"address": P_LOCAL}).relay(), RELAY)
        self.assertIsNone(self.p(OSError("refused")).relay())

    def lane(self, relay):
        return type("L", (), {"p": type("P", (), {"relay": relay})()})()

    def test_a_local_relay_in_use_needs_p_on_it(self):
        on_local = type("FP", (), {"relay": lambda self: RELAY})()
        on_public = type("FP", (), {"relay": lambda self: "epicbox.stackwallet.com"})()
        self.assertEqual(checks._relay_with_p(self.lane(RELAY), on_local), RELAY)
        with self.assertRaises(HarnessFault) as c:
            checks._relay_with_p(self.lane(RELAY), on_public)
        self.assertEqual(c.exception.step, "fund")
        self.assertIn("P posts through epicbox.stackwallet.com", c.exception.what)
        # a public relay in use is P's business as before
        self.assertEqual(checks._relay_with_p(self.lane("epicbox.stackwallet.com"), on_public), "epicbox.stackwallet.com")


class FakePlatform:
    name, variant = "linux", "tor"

    def __init__(self, node=NODE, relay="epicbox.stackwallet.com"):
        self.node, self.relay = node, relay
        self.custom_node, self.custom_relay = "127.0.0.1:43413", "127.0.0.1:5101"
        self.hermetic = hermetic.plan(P_PUBLIC, env={}, svc=BOTH)

    def live_servers(self):
        return "https://node.pub", "box.pub"

    def save_state(self, folder):
        with open(os.path.join(folder, "home.tar"), "w") as f:
            f.write("x")

    # the phases the lane names (run_phase is faked: none of them runs)
    prepare = install_previous = stop = files_snapshot = update = lambda self: None
    seed_previous_files = digest = lambda self, *a: None


class LaneServersTest(unittest.TestCase):
    def setUp(self):
        patch = mock.patch.object(checks, "P_ADDR", P_PUBLIC)
        patch.start()
        self.addCleanup(patch.stop)

    def lane(self, funds, platform=None):
        self.logs = []
        return core_lane.Lane(platform or FakePlatform(), None, checks, out=tempfile.mkdtemp(prefix="hw-lane-"),
                              log=self.logs.append, required=[], funds=funds)

    def phases(self, funds):
        lane, names = self.lane(funds), []
        after = {"log": {"lines": 3}}
        with mock.patch.object(core_lane.Lane, "run_phase", lambda self_, name, fn: names.append(name) or (after if name == "digest-after" else "es1")), \
                mock.patch.object(core_lane.st, "pick", lambda *a, **kw: None), \
                mock.patch.object(core_lane.Lane, "_ui_settings", lambda self_, d: None), \
                mock.patch.object(checks, "compare", lambda *a: None), \
                mock.patch.object(checks, "setup_took", lambda *a: None), \
                mock.patch.dict(os.environ, {"REL_TRUST_SAVE_STATE": "0", "REL_TRUST_START": "fresh"}):  # not this host's lane seed
            lane._main()
        return lane, names

    def test_live_servers_runs_with_funds_only_and_before_the_funds_legs(self):
        _, names = self.phases(funds=True)  # FakePlatform is a Tor lane: Tor goes on before the legs
        self.assertEqual(names[names.index("digest-after") + 1:], ["live-servers", "tor-on", "funds"])
        _, names = self.phases(funds=False)
        self.assertNotIn("live-servers", names)

    def test_the_proof_says_what_was_local_and_why(self):
        lane, _ = self.phases(funds=False)
        h = lane.details["hermetic"]
        self.assertEqual((h["on"], h["node"], h["relay"]), (False, NODE, "epicbox.stackwallet.com"))
        self.assertIn("P (the funder) posts through", h["reason"])

    def test_live_servers_replaces_only_the_local_ones(self):
        lane = self.lane(True)
        lane._hermetic()
        lane.ui = mock.Mock()
        lane.results.update(wallet_opens=True, balance_kept=True)
        lane._live_servers({"log": {"lines": 10}})
        lane.ui.use_servers.assert_called_once_with("https://node.pub", "epicbox.stackwallet.com")
        self.assertEqual((lane.p.node, lane.p.relay), ("https://node.pub", "epicbox.stackwallet.com"))
        self.assertEqual(lane.details["live_servers"], {"node": "https://node.pub", "relay": "epicbox.stackwallet.com"})

        lane.last_digest = {"log": {"hosts": [(2, "127.0.0.1:43413"), (4, "tor.example.net"), (12, "node.pub")]}}
        lane._non_local()
        nl = lane.details["non_local"]
        self.assertEqual(nl["before"], ["epicbox.stackwallet.com", "tor.example.net"])  # the relay stand-in's upstream, P's relay
        self.assertEqual(nl["after"], ["node.pub", "epicbox.stackwallet.com"])
        self.assertTrue(nl["app_log"])
        self.assertTrue(any("logged, not failed" in line for line in self.logs))
        self.assertNotIn("non_local", lane.results)

    def test_live_servers_leaves_a_lane_whose_funds_legs_do_not_run(self):
        lane = self.lane(True)
        lane.ui = mock.Mock()
        lane._live_servers({"log": {"lines": 1}})  # wallet_opens never passed
        lane.ui.use_servers.assert_not_called()
        self.assertEqual(lane.p.node, NODE)

    def test_public_servers_in_use_need_no_switch(self):
        lane = self.lane(True, FakePlatform(node="https://node.pub"))
        lane.ui = mock.Mock()
        lane.results.update(wallet_opens=True, balance_kept=True)
        lane._live_servers(None)
        lane.ui.use_servers.assert_not_called()


class StateMetaTest(unittest.TestCase):
    def test_saved_meta_says_which_servers_in_use_were_local(self):
        root = tempfile.mkdtemp(prefix="hw-state-")
        env = {"REL_TRUST_STATE_ROOT": root, "REL_CANDIDATE_VERSION": "26.11.03"}
        with mock.patch.dict(os.environ, env):
            st.save(FakePlatform(), {"password": "pw"}, {"balance": "0"}, log=lambda line: None)
        metas = [os.path.join(d, f) for d, _, fs in os.walk(root) for f in fs if f == "meta.json"]
        self.assertEqual(len(metas), 1)
        with open(metas[0]) as f:
            self.assertEqual(json.load(f)["hermetic"], {"node": True, "relay": False})


if __name__ == "__main__":
    unittest.main()
