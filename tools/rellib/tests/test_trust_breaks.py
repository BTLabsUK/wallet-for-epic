# SPDX-License-Identifier: Apache-2.0
"""The break kinds (core/breaks.py) on fake surfaces, each ending in a logged recovery or a named cause:
fold expanded by the "folded" rule, an overlay waited out and never pressed, a stale picker opened again,
a server already chosen SKIPs its goal, an app quit is PRODUCT (HarnessGone when its display went), a
node down moves the LEPIC CLI to the next node (INFRA node when none answers), ssh-timeout a one-shot
hook; all refused in a release run. The lane's side: the cause class and the fault bundle, the stop
after REL_TRUST_UNTIL (refused in a release run), the resume of a failed attempt, and the INFRA cause
tools/rel retries."""
import json
import os
import stat
import subprocess
import sys
import tempfile
import types
import unittest
import unittest.mock

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "drivers"))
sys.path.insert(0, os.path.dirname(os.path.dirname(HERE)))

from core import breaks  # noqa: E402
from core import driver as drv  # noqa: E402
from core import lane as ln  # noqa: E402
from core import targets as tg  # noqa: E402
from core import walletdata as wd  # noqa: E402
from core.desktop import NODE_PICKER, Desktop  # noqa: E402
from core.driver import Driver, Goal, shows  # noqa: E402
from core.faults import HarnessFault, HarnessGone, InfraFault, ProductFault  # noqa: E402
from core.labels import Labels  # noqa: E402
from core.recover import Recover  # noqa: E402
from core.surface import Node  # noqa: E402
from rellib import window  # noqa: E402

UNLOCK = tg.Target(id="g4.unlock.submit", role="button", keys=("deskOnbUnlockButton",))
HOME = tg.Target(id="g4.home.available", role="text", keys=("deskOvAvailable",), match="starts")
ARB = {"deskOnbUnlockButton": "Unlock", "deskOvAvailable": "Available to spend"}
PHRASE = " ".join(["abandon"] * 23 + ["art"])


def n(i, role, name, **kw):
    return Node(i=i, role=role, name=name, states=frozenset(kw.pop("states", ("enabled",))), **kw)


class Fake:
    platform, family = "linux", "desktop"

    def __init__(self, screens, start, moves=None):
        self.screens, self.cur, self.moves, self.pressed, self.up = screens, start, moves or {}, [], True

    def tree(self):
        return list(self.screens[self.cur])

    def press(self, node):
        self.pressed.append(node.name)
        self.cur = self.moves.get((self.cur, node.name), self.cur)

    def set_text(self, node, text, secret=False):
        pass

    def key(self, name):
        pass

    def scroll(self, direction="down"):
        pass

    def screenshot(self, path):
        with open(path, "wb") as f:
            f.write(b"png")
        return True

    def alive(self):
        return self.up


class Picker(Fake):
    """Settings › Node: the node picker, closed (its label names the node in use) or open (its search
    field and a Use row per server)."""

    def __init__(self, in_use="node.old"):
        super().__init__({}, "page")
        self.in_use, self.open, self.typed = in_use, False, []

    def tree(self):
        t = [n(0, "button", "Node server\n%s" % self.in_use)]
        if self.open:
            t += [n(1, "text_field", "Search or add a server", states=("enabled", "editable", "focused")),
                  n(2, "button", "Use node.old"), n(3, "button", "Use node.btlabs.uk")]
        return t

    def press(self, node):
        self.pressed.append(node.name)
        if node.name.startswith("Node server"):
            self.open = True
        elif node.name.startswith("Use "):
            self.in_use, self.open = node.name[4:], False

    def set_text(self, node, text, secret=False):
        self.typed.append(text)

    def key(self, name):
        if name == "escape":
            self.open = False


class Base(unittest.TestCase):
    def setUp(self):
        breaks.reset()
        self.addCleanup(breaks.reset)
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.out = self.tmp.name
        self.logs = []
        self.events = []
        for target, new in (("core.record.emit", lambda event, /, **f: self.events.append((event, f))),
                            ("core.record.read", lambda: None), ("core.driver.SLOW", 0.02),
                            ("core.desktop.time.sleep", lambda s: None), ("core.breaks.time.sleep", lambda s: None),
                            ("core.walletdata.node_status", lambda u: ("ok", 100))):
            p = unittest.mock.patch(target, new)
            p.start()
            self.addCleanup(p.stop)
        env = unittest.mock.patch.dict(os.environ, {"REL_AI": "0", "REL_TRUST_BREAK": ""})
        env.start()
        self.addCleanup(env.stop)
        for k in ("REL_RUN_KIND", "REL_TRUST_UNTIL", "REL_TRUST_RESUME"):
            os.environ.pop(k, None)

    def breaks(self, value):
        os.environ["REL_TRUST_BREAK"] = value

    def driver(self, fake, arb=ARB):
        rec = Recover(self.out, "linux", log=self.logs.append)
        return Driver(fake, Labels(arb=arb), rec, out=self.out, log=self.logs.append, poll=0.01)

    def logged(self, text):
        return [line for line in self.logs if text in line]


class BreakKindsTest(Base):
    def test_fold_expanded_by_the_folded_rule(self):
        self.breaks("fold:g4.unlock.submit")
        f = Fake({"lock": [n(0, "button", "Unlock", id="g4.unlock.submit")], "home": [n(0, "text", "Available to spend")]},
                 "lock", {("lock", "Unlock"): "home"})
        d = self.driver(f)
        d.press(UNLOCK, step="unlock", then=shows(HOME), timeout=1)
        self.assertEqual((f.cur, f.pressed), ("home", ["Unlock"]))   # Show more never reached the app
        self.assertTrue(self.logged("known trouble folded: expanded 'Show more'"), self.logs)
        self.assertTrue(self.logged("found after folded"), self.logs)

    def test_fold_without_trust_ids_hides_the_control_by_label(self):
        # a Windows UIA tree: no trust ids, the control matched by the recipe's label
        self.breaks("fold:g4.unlock.submit")
        f = Fake({"lock": [n(0, "button", "Unlock")], "home": [n(0, "text", "Available to spend")]},
                 "lock", {("lock", "Unlock"): "home"})
        d = self.driver(f)
        self.assertEqual([x.name for x in d.s.tree()], [breaks.FOLD_BUTTON])
        d.press(UNLOCK, step="unlock", then=shows(HOME), timeout=1)
        self.assertEqual((f.cur, f.pressed), ("home", ["Unlock"]))
        self.assertTrue(self.logged("known trouble folded: expanded 'Show more'"), self.logs)

    def test_overlay_waited_out_and_never_pressed(self):
        self.breaks("overlay@address:5")
        lane = types.SimpleNamespace(log=self.logs.append, p=None, retried=set())
        breaks.at_phase(lane, "address")
        f = Fake({"home": [n(0, "text", "Available to spend")], "sync": [n(0, "text", "Syncing")]}, "sync")
        reads = [0]
        tree = f.tree

        def later():   # the home screen shows after the first reads, under the overlay
            reads[0] += 1
            f.cur = "home" if reads[0] > 2 else "sync"
            return tree()
        f.tree = later
        d = self.driver(f)
        self.assertTrue(d.wait(shows(HOME), 5))
        self.assertEqual(f.pressed, [])
        self.assertTrue(self.logged("covers the page; waiting"), self.logs)
        left = breaks._overlay[0]
        breaks.at_phase(lane, "address")   # once per run: not armed again
        self.assertEqual(breaks._overlay[0], left)

    def test_stale_picker_opened_again(self):
        self.breaks("stale:g4.server.node")
        f = Picker()
        desk = Desktop(self.driver(f), "previous", self.logs.append)
        desk.use_server(NODE_PICKER, "https://node.btlabs.uk", "node.btlabs.uk", use=True)
        self.assertEqual(f.in_use, "node.btlabs.uk")
        self.assertTrue(self.logged("rows read stale"), self.logs)
        self.assertTrue(self.logged("known trouble stale: closed"), self.logs)
        self.assertEqual(f.typed, ["https://node.btlabs.uk"] * 2)

    def test_selected_server_skips_the_goal(self):
        self.breaks("selected:g4.server.node")
        f = Picker()
        desk = Desktop(self.driver(f), "previous", self.logs.append)
        self.assertEqual(desk.use_server(NODE_PICKER, "https://node.btlabs.uk", "node.btlabs.uk", use=True), "skipped")
        self.assertTrue(self.logged("SKIP use-node.btlabs.uk: already done"), self.logs)
        self.assertEqual(f.pressed.count("Use node.btlabs.uk"), 1)
        self.assertIn(("step.end", {"step": "use-node.btlabs.uk", "state": "skipped"}), self.events)

    def test_server_in_use_already_skips_without_a_break(self):
        f = Picker(in_use="node.btlabs.uk")
        desk = Desktop(self.driver(f), "previous", self.logs.append)
        self.assertEqual(desk.use_server(NODE_PICKER, "https://node.btlabs.uk", "node.btlabs.uk", use=True), "skipped")
        self.assertEqual(f.pressed, [])

    def test_quit_is_product_unless_the_display_went(self):
        self.breaks("quit@address")
        killed = []
        lane = types.SimpleNamespace(log=self.logs.append, p=types.SimpleNamespace(break_quit=lambda: killed.append(1), name="linux"),
                                     retried=set())
        breaks.at_phase(lane, "address")
        self.assertEqual(killed, [1])
        f = Fake({"home": [n(0, "text", "Loading")]}, "home")
        f.up = False
        with self.assertRaises(ProductFault) as c:
            self.driver(f).wait(shows(HOME), 1)
        self.assertEqual(c.exception.cause_class, "PRODUCT")
        f.display_alive = lambda: False
        with self.assertRaises(HarnessGone):
            self.driver(f).wait(shows(HOME), 1)

    def test_quit_on_a_platform_that_cannot_is_harness(self):
        self.breaks("quit@address")
        lane = types.SimpleNamespace(log=self.logs.append, p=types.SimpleNamespace(name="x"), retried=set())
        with self.assertRaises(HarnessFault):
            breaks.at_phase(lane, "address")

    def test_ssh_timeout_hook_fires_once(self):
        self.breaks("ssh-timeout@update")
        self.assertFalse(breaks.ssh_timeout("candidate"))
        self.assertTrue(breaks.ssh_timeout("update"))
        self.assertFalse(breaks.ssh_timeout("update"))

    def test_refused_in_a_release_run_and_unknown_kinds(self):
        for kind in ("fold:x", "overlay@address", "stale:g4.server.node", "selected:g4.server.node", "quit@address",
                     "node-down", "ssh-timeout@update"):
            with self.subTest(kind):
                self.breaks(kind)
                breaks.refuse_in_release()   # a --test run takes it
                with unittest.mock.patch.dict(os.environ, {"REL_RUN_KIND": "release"}):
                    with self.assertRaises(breaks.BreakRefused):
                        breaks.refuse_in_release()
        self.breaks("folds:x")
        with self.assertRaises(breaks.BreakRefused):
            breaks.refuse_in_release()

    def test_goal_done_already_is_skipped(self):
        d = self.driver(Fake({"p": [n(0, "text", "x")]}, "p"))
        did = []
        self.assertEqual(d.achieve(Goal("theme", lambda tree: True, lambda: did.append(1))), "skipped")
        self.assertEqual(did, [])
        self.assertTrue(self.logged("SKIP theme: already done"))

    def test_failure_names_the_rules_tried(self):
        d = self.driver(Fake({"p": [n(0, "text", "Nothing here")]}, "p"))
        d.overlay_wait = 0.1
        with self.assertRaises(HarnessFault) as c:
            d.press(UNLOCK, step="unlock", timeout=0.1)
        self.assertIn("tried scroll (scrolled down 3 and back)", c.exception.what)
        self.assertEqual(c.exception.cause_class, "HARNESS-ui")
        self.assertIn("scroll (scrolled down 3 and back)", c.exception.tried)


class RecordTest(unittest.TestCase):
    def test_emit_takes_a_field_named_kind(self):
        from core import record
        with unittest.mock.patch.dict(os.environ, {"REL_TESTDB": "off"}):
            record.emit("wallet.address", name="w", role="lane", kind="epicbox", address="a@b")


class OverlayPhaseTest(Base):
    def test_overlay_fires_at_its_own_phase_only(self):
        self.breaks("overlay@previous-setup:5")
        lane = types.SimpleNamespace(log=self.logs.append, ui=None)
        breaks.at_phase(lane, "previous")
        self.assertEqual(self.logged("BREAK: a scan overlay"), [])
        breaks.at_phase(lane, "previous-setup")
        self.assertEqual(len(self.logged("BREAK: a scan overlay covers the page for 5 reads as previous-setup")), 1)


class NodeDownTest(Base):
    SETTINGS = '[node]\nservers = ["http://127.0.0.1:9999"]\n'

    def cli(self, answers):
        cli = wd.LepicCli(exe="lepic", log=self.logs.append)
        ran = []

        def run(args, stdin, timeout=600):
            with open(cli.settings) as f:
                node = wd.toml_servers(f.read())["node"][0]
            ran.append(node)
            ok = node in answers
            return subprocess.CompletedProcess(args, 0 if ok else 9, "", "" if ok else "could not connect to the node")
        cli._run = run
        return cli, ran

    def test_with_node_puts_the_host_first(self):
        text = wd.with_node('[node]\nservers = [\n  "a:1",\n  "b:2",\n]\n[epicbox]\nservers = ["r"]\n', "c:3")
        self.assertEqual(wd.toml_servers(text)["node"][0], "c:3")
        self.assertEqual(wd.toml_servers(text)["epicbox"], ["r"])
        self.assertEqual(wd.toml_servers(wd.with_node("", "c:3"))["node"], ["c:3"])

    def test_node_down_moves_to_the_next_node(self):
        self.breaks("node-down")
        cli, ran = self.cli({"https://node.btlabs.uk"})
        try:
            cli._restore(PHRASE, "pw", self.SETTINGS)
        finally:
            cli.close()
        # the CLI's node.servers needs the scheme (lepic NodeEndpoint::parse)
        self.assertEqual(ran, [wd.UNREACHABLE_NODE, "http://127.0.0.1:9999", "https://node.btlabs.uk"])
        self.assertEqual(len(self.logged("not reachable (exit 9); trying")), 2, self.logs)
        self.assertTrue(self.logged("BREAK: the CLI's first node is http://127.0.0.1:9"))

    def test_a_node_without_scheme_gets_one(self):
        cli, ran = self.cli({"http://10.0.0.1:3413"})
        try:
            cli._restore(PHRASE, "pw", '[node]\nservers = ["10.0.0.1:3413", "https://node.btlabs.uk"]\n')
        finally:
            cli.close()
        self.assertEqual(ran, ["http://10.0.0.1:3413"])

    def test_an_unsynced_node_is_moved_past_before_the_first_read(self):
        health = {"http://127.0.0.1:9999": ("syncing body_sync", 90), "https://node.btlabs.uk": ("ok", 100)}
        cli, ran = self.cli({"http://127.0.0.1:9999", "https://node.btlabs.uk"})
        with unittest.mock.patch.object(wd, "node_status", lambda u: health.get(u, ("down", None))):
            try:
                cli._restore(PHRASE, "pw", self.SETTINGS)
            finally:
                cli.close()
        self.assertEqual(ran, ["https://node.btlabs.uk"])
        self.assertTrue(self.logged("LEPIC CLI: node http://127.0.0.1:9999 not synced (body_sync, height 90): "
                                    "using https://node.btlabs.uk, the next synced one"), self.logs)

    def test_all_nodes_down_is_infra_node(self):
        cli, ran = self.cli(set())
        try:
            with self.assertRaises(InfraFault) as c:
                cli._restore(PHRASE, "pw", self.SETTINGS)
        finally:
            cli.close()
        self.assertEqual((c.exception.sub, c.exception.cause_class, c.exception.kind), ("node", "INFRA", "infra"))
        self.assertIn("node.epiccash.com", c.exception.what)
        self.assertNotIn("abandon", c.exception.what + "".join(self.logs))


# ---- the lane

class Checks:
    P_ADDR = ""
    WANT_SETTINGS = {}

    def __init__(self):
        self.funded = []

    def fund_before(self, lane, address):
        self.funded.append(address)


class Ui:
    which = "previous"

    def __init__(self, test, surface, fail_at=None):
        self.test, self.fail_at = test, fail_at
        self.d = test.driver(surface)
        self.opened = []

    def create_wallet(self):
        self.test.created += 1
        return {"password": "pw-test", "phrase": PHRASE}

    def open_wallet(self, secrets, after_update=False):
        self.opened.append(dict(secrets))

    def set_servers(self, *a):
        pass

    def change_settings(self, want):
        pass

    def address(self):
        if self.fail_at == "address":
            raise HarnessFault("receive", "the address never showed")
        return "esAddressForTheLaneWallet1234567890@epicbox.example"


class P(ln.Platform):
    name, family, variant = "linux", "desktop", "tor"
    node = relay = custom_node = custom_relay = None

    def __init__(self, test):
        self.test = test
        self.resumed = None

    def prepare(self):
        pass

    def install_previous(self):
        pass

    def start(self, which):
        return Fake({"p": [n(0, "text", "Receive"), n(1, "text_field", "Password", value="pw-test", states=("password",))]}, "p")

    def stop(self):
        pass

    def digest(self, tag, secrets):
        return {"balance": {"total": 0, "spendable": 0, "unconfirmed": 0, "locked": 0}, "txs": []}

    def shutdown(self):
        pass

    def resume_dir(self):
        return self.test.private

    def resume_handle(self):
        return {"work": "sandbox-1"}

    def resume_from(self, handle):
        self.resumed = handle
        return True, "sandbox %s" % handle["work"]


class LaneTest(Base):
    def setUp(self):
        super().setUp()
        self.private = os.path.join(self.out, "..", os.path.basename(self.out) + "-private")
        self.private = tempfile.mkdtemp(prefix="resume-", dir=os.path.dirname(self.out))
        self.addCleanup(lambda: __import__("shutil").rmtree(self.private, True))
        self.created = 0
        env = unittest.mock.patch.dict(os.environ, {"REL_TRUST_START": "fresh", "REL_TRUST_STATE_ROOT": self.out,
                                                    "REL_PREVIOUS_VERSION": "26.10.26", "REL_CANDIDATE_VERSION": "26.11.1",
                                                    "REL_TRUST_SEED_DIR": self.out})
        env.start()
        self.addCleanup(env.stop)

    def log(self, line):
        self.logs.append(line)
        with open(os.path.join(self.out, "trust.log"), "a") as f:
            f.write(line + "\n")

    def lane(self, fail_at=None):
        self.checks = Checks()
        lane = ln.Lane(P(self), lambda lane, which, s: Ui(self, s, fail_at), self.checks, out=self.out, log=self.log,
                       required=["balance_kept"], funds=False)
        return lane

    def proof(self):
        with open(os.path.join(self.out, "proof.json")) as f:
            return json.load(f)

    def test_until_stops_cleanly_before_the_payment(self):
        os.environ["REL_TRUST_UNTIL"] = "previous-setup"
        self.assertEqual(self.lane().main(), 0)
        self.assertEqual(self.checks.funded, [])   # fund (P paid back) never ran
        self.assertTrue(self.logged("STOP after previous-setup (REL_TRUST_UNTIL)"))
        self.assertEqual(self.logged("at or after fund"), [])
        p = self.proof()
        self.assertEqual(p["until"], {"phase": "previous-setup", "stopped": True})
        self.assertEqual(p["phases"]["done"], ["prepare", "install", "previous", "previous-setup"])
        self.assertNotIn("fault", p)
        puts = [f for k, f in self.events if k == "wallet.put"]
        self.assertEqual((puts[0]["role"], puts[0]["phrase"], puts[0]["password"]), ("sandbox", PHRASE, "pw-test"))
        # each attempt's fresh wallet keeps its own row: a retry never overwrites a phrase that may hold coins
        self.assertRegex(puts[0]["name"], r"-\d{8}-\d{6}-sandbox$")
        with open(os.path.join(self.out, "trust.log")) as f:
            self.assertNotIn("abandon", f.read())

    def test_until_after_fund_says_coins_move(self):
        os.environ["REL_TRUST_UNTIL"] = "digest-before"
        self.lane()
        self.assertTrue(self.logged("REL_TRUST_UNTIL=digest-before is at or after fund: P pays"), self.logs)

    def test_until_refused_in_a_release_run(self):
        os.environ.update(REL_TRUST_UNTIL="digest-before", REL_RUN_KIND="release")
        with self.assertRaises(ln.UntilRefused):
            self.lane()
        os.environ.update(REL_TRUST_UNTIL="digest-befor", REL_RUN_KIND="test")
        with self.assertRaises(ln.UntilRefused):   # a typo would run the whole lane
            self.lane()

    def test_fault_bundle_and_cause_class(self):
        self.assertEqual(self.lane(fail_at="address").main(), 2)
        fault = self.proof()["fault"]
        self.assertEqual((fault["kind"], fault["cause_class"], fault["step"]), ("harness", "HARNESS-ui", "receive"))
        b = os.path.join(self.out, "bundles", "1-receive")
        with open(os.path.join(b, "step.txt")) as f:
            text = f.read()
        self.assertIn("cause class: HARNESS-ui", text)
        self.assertIn("the address never showed", text)
        with open(os.path.join(b, "screen.txt")) as f:
            self.assertIn("'Receive'", f.read())
        with open(os.path.join(b, "log-tail.txt")) as f:
            self.assertIn("== phase address", f.read())
        self.assertTrue(os.path.exists(os.path.join(b, "shot.png")))
        kinds = [k for k, _ in self.events]
        self.assertIn("bundle", kinds)
        failure = next(f for k, f in self.events if k == "failure")
        self.assertEqual((failure["step"], failure["cause_class"]), ("receive", "HARNESS-ui"))
        self.assertIn(("step.end", "address", "failed"), [(k, f["step"], f.get("state")) for k, f in self.events if k == "step.end"])
        # what a resume needs: in the private folder, 0600, never in REL_OUT
        kept = os.path.join(self.private, "lane-resume.json")
        self.assertEqual(stat.S_IMODE(os.stat(kept).st_mode), 0o600)
        self.assertEqual(self.proof()["resume"]["secrets"], kept)

    def test_resume_at_the_failed_phase(self):
        self.lane(fail_at="address").main()
        os.rename(os.path.join(self.out, "proof.json"), os.path.join(self.out, "proof.before-attempt-2.json"))
        os.environ.update(REL_TRUST_RESUME="1", REL_TRUST_UNTIL="address")
        lane = self.lane()
        self.assertEqual(lane.main(), 0)
        self.assertEqual(self.created, 1)   # the wallet was made once, by the first attempt
        self.assertEqual(lane.p.resumed, {"work": "sandbox-1"})
        self.assertEqual(lane.ui.opened[0]["password"], "pw-test")
        self.assertTrue(self.logged("RESUME: from proof.before-attempt-2.json, at phase address"), self.logs)
        self.assertTrue(self.logged("SKIP previous-setup: done in the previous attempt"))
        self.assertEqual(self.proof()["details"]["resume"]["at"], "address")
        self.assertFalse(os.path.exists(os.path.join(self.private, "lane-resume.json")))   # read once

    def test_resume_starts_fresh_and_says_why(self):
        os.environ.update(REL_TRUST_RESUME="1", REL_TRUST_UNTIL="previous")
        self.assertEqual(self.lane().main(), 0)
        self.assertTrue(self.logged("RESUME: starting fresh: no proof of a previous attempt"), self.logs)
        with open(os.path.join(self.out, "proof.json"), "w") as f:
            json.dump({"phases": {"done": ["prepare"], "failed": "install"}, "fault": {"kind": "harness"}}, f)
        self.lane().main()
        self.assertTrue(self.logged("RESUME: starting fresh: the previous attempt failed in install"), self.logs)


class InfraCauseTest(unittest.TestCase):
    def test_proof_infra_fault_is_an_infra_cause(self):
        step = types.SimpleNamespace(kind="script", heavy=False, proof=True)
        log = os.path.join(tempfile.gettempdir(), "no-such-log-%d" % os.getpid())
        res = {"rc": 2, "proof": {"fault": {"kind": "infra", "sub": "node"}}}
        self.assertEqual(window.cause_of(step, res, log), "infra:driver-node")
        self.assertEqual(window.cause_of(step, {"rc": 2, "proof": {"fault": {"kind": "infra"}}}, log), "infra:driver-rig")
        self.assertEqual(window.cause_of(step, {"rc": 2, "proof": {"fault": {"kind": "harness"}}}, log), "harness")


if __name__ == "__main__":
    unittest.main()
