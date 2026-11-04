# SPDX-License-Identifier: Apache-2.0
"""The next synced node: drivers/nodehealth.py, and P's move off a node its listener pauses on (p_service)."""
import os
import sys
import tempfile
import unittest
from unittest import mock

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "drivers"))
sys.path.insert(0, os.path.dirname(HERE))

import nodehealth  # noqa: E402
import p_service  # noqa: E402

A, B, C = "https://a.test", "https://b.test:3413", "https://c.test"


def probe(table):
    return lambda u: table.get(u, ("down", None))


class JudgeTest(unittest.TestCase):
    def test_reasons(self):
        why = nodehealth.judge([A, B, C, "https://d.test"], probe({
            A: ("ok", 100), B: ("ok", 90), C: ("syncing body_sync", 80), "https://d.test": ("unknown", None)}))
        self.assertIsNone(why[A])
        self.assertEqual(why[B], "not synced (height 90, the others at 100)")
        self.assertEqual(why[C], "not synced (body_sync, height 80)")
        self.assertIsNone(why["https://d.test"])  # answers without a status: left where it is

    def test_a_few_blocks_behind_is_synced(self):
        self.assertIsNone(nodehealth.judge([A, B], probe({A: ("ok", 100), B: ("ok", 96)}))[B])

    def test_synced_first_keeps_the_order_and_logs_the_move(self):
        logs = []
        order = nodehealth.synced_first([A, B, C], logs.append, probe({B: ("ok", 5), C: ("ok", 5)}))
        self.assertEqual(order, [B, C, A])
        self.assertEqual(logs, ["node %s not reachable: using %s, the next synced one" % (A, B)])

    def test_first_fit_is_not_logged(self):
        logs = []
        self.assertEqual(nodehealth.synced_first([A, B], logs.append, probe({A: ("ok", 5)})), [A, B])
        self.assertEqual(logs, [])

    def test_none_fit_tries_all_in_order(self):
        logs = []
        self.assertEqual(nodehealth.synced_first([A, B], logs.append, probe({})), [A, B])
        self.assertIn("no node is synced", logs[0])


class PNodeTest(unittest.TestCase):
    """Service with P's side faked: the listener log is a local file, P's toml a string."""

    def service(self, node, health, listener_tail):
        s = p_service.Service.__new__(p_service.Service)
        d = tempfile.TemporaryDirectory()
        self.addCleanup(d.cleanup)
        tmp = d.name
        s.dir, s.paused_at, s.moved_at, s.pdir = tmp, None, 0.0, r"C:\P"
        lp = os.path.join(tmp, "listener.log")
        with open(lp, "w") as f:
            f.write(listener_tail)
        s.procs = {"listener": (None, lp)}
        s.toml = 'check_node_api_http_addr = "%s"\n' % node
        s.killed = []
        s._p_toml = lambda: s.toml
        s._set_p_node = lambda url: setattr(s, "toml", 'check_node_api_http_addr = "%s"\n' % url) or True
        s.kill_remote = lambda kinds=("listen", "owner_api"): s.killed.append(kinds) or True
        p = mock.patch.object(p_service.nodehealth, "status", probe(health))
        p.start()
        self.addCleanup(p.stop)
        p = mock.patch.object(p_service.facts, "NODE_PICK", [A, B, C])
        p.start()
        self.addCleanup(p.stop)
        return s

    def logs(self, s):
        with open(os.path.join(s.dir, "service.log")) as f:
            return f.read()

    PAUSED = "2026-11-03 22:34:15.697 WARN Node not synced, pausing Epicbox message processing...\n"

    def test_paused_on_an_unsynced_node_moves_to_the_next_synced_one(self):
        s = self.service(A, {A: ("syncing header_sync", 90), B: ("ok", 100), C: ("ok", 100)}, "x\n" + self.PAUSED)
        self.assertIsNone(s.watch_node(now=1000))          # the pause starts counting
        self.assertIsNone(s.watch_node(now=1030))
        self.assertEqual(s.watch_node(now=1061), B)
        self.assertIn('"%s"' % B, s.toml)
        self.assertEqual(s.killed, [("listen", "owner_api")])
        self.assertIn("P node moved: %s -> %s (the listener paused 61 s on 'Node not synced'; %s not synced" % (A, B, A),
                      self.logs(s))
        self.assertIsNone(s.watch_node(now=1200))          # one move per MOVE_EVERY_S

    def test_paused_on_a_synced_node_restarts_the_listener_only(self):
        s = self.service(A, {A: ("ok", 100), B: ("ok", 100)}, self.PAUSED)
        s.watch_node(now=1000)
        self.assertEqual(s.watch_node(now=1060), A)
        self.assertEqual(s.killed, [("listen",)])
        self.assertIn('"%s"' % A, s.toml)

    def test_no_synced_node_leaves_p_alone(self):
        s = self.service(A, {}, self.PAUSED)
        s.watch_node(now=1000)
        self.assertIsNone(s.watch_node(now=1100))
        self.assertEqual(s.killed, [])
        self.assertIn("no node is synced", self.logs(s))

    def test_a_listener_that_goes_on_is_not_paused(self):
        s = self.service(A, {B: ("ok", 1)}, self.PAUSED + "2026-11-03 22:35:00.000 INFO Reconnect to epicbox\n")
        s.watch_node(now=1000)
        self.assertIsNone(s.watch_node(now=2000))
        self.assertIsNone(s.paused_at)
        self.assertEqual(s.killed, [])


class ListenerStallTest(unittest.TestCase):
    """A listener that lost its Epicbox subscription in silence is started again for an unanswered send."""

    def service(self, spoke, sends):
        s = p_service.Service.__new__(p_service.Service)
        d = tempfile.TemporaryDirectory()
        self.addCleanup(d.cleanup)
        lp = os.path.join(d.name, "listener.log")
        open(lp, "w").close()
        os.utime(lp, (spoke, spoke))
        s.dir, s.moved_at, s.state_mu, s.sends = d.name, 0.0, p_service.threading.Lock(), sends
        s.procs = {"listener": (None, lp)}
        s.killed = []
        s.kill_remote = lambda kinds=("listen", "owner_api"): s.killed.append(kinds) or True
        return s

    def test_an_unanswered_send_and_a_silent_listener_restart_it(self):
        s = self.service(1000, {"aaaaaaaa-1": {"state": "sent", "at": 2000}})
        self.assertIsNone(s.watch_listener(now=2000 + p_service.STALL_S - 10))
        self.assertEqual(s.watch_listener(now=2000 + p_service.STALL_S), ["aaaaaaaa-1"])
        self.assertEqual(s.killed, [("listen",)])
        self.assertIn("P listener silent", open(os.path.join(s.dir, "service.log")).read())

    def test_a_listener_that_spoke_after_the_send_is_left_alone(self):
        s = self.service(2100, {"x": {"state": "sent", "at": 2000}})
        self.assertIsNone(s.watch_listener(now=3000))
        self.assertEqual(s.killed, [])

    def test_answered_sends_are_left_alone(self):
        s = self.service(1000, {"x": {"state": "posted", "at": 2000}, "y": {"state": "confirmed", "at": 2000}})
        self.assertIsNone(s.watch_listener(now=3000))

    def test_at_most_stall_tries_per_send(self):
        s = self.service(1000, {"x": {"state": "sent", "at": 2000}})
        t = 2000 + p_service.STALL_S
        for _ in range(5):
            s.watch_listener(now=t)
            t += p_service.MOVE_EVERY_S
        self.assertEqual(len(s.killed), p_service.STALL_TRIES)

    def test_a_kick_restarts_a_silent_listener_once_per_move_every(self):
        s = self.service(1000, {})
        self.assertFalse(s.kick(now=1000 + p_service.STALL_S - 1)["restarted"])  # it spoke just now
        self.assertTrue(s.kick("B 0.04", now=1000 + p_service.STALL_S)["restarted"])
        self.assertFalse(s.kick(now=1000 + p_service.STALL_S + 60)["restarted"])
        self.assertEqual(s.killed, [("listen",)])
        self.assertIn("a send to P unanswered (B 0.04)", open(os.path.join(s.dir, "service.log")).read())


class CancelTest(unittest.TestCase):
    """A send of P that can never finalize is cancelled through the service's owner API."""

    def service(self, entry):
        s = p_service.Service.__new__(p_service.Service)
        d = tempfile.TemporaryDirectory()
        self.addCleanup(d.cleanup)
        s.dir, s.send_mu, s.state_mu, s.calls = d.name, p_service.threading.Lock(), p_service.threading.Lock(), []
        s.sends = {"sl": {"state": "sent"}}
        s.tx_entry = lambda slate_id=None, tx_id=None: entry if slate_id == "sl" else None
        s.rpc = lambda method, params, timeout=180: s.calls.append((method, params))
        return s

    def test_an_unconfirmed_send_is_cancelled(self):
        s = self.service({"id": 466, "tx_type": "TxSent", "confirmed": False})
        self.assertEqual(s.cancel("sl", "wrong relay"), {"ok": True, "tx": 466})
        self.assertEqual(s.calls, [("cancel_tx", [None, "sl"])])
        self.assertEqual(s.sends["sl"]["state"], "cancelled")

    def test_a_confirmed_or_unknown_send_is_refused(self):
        s = self.service({"id": 1, "tx_type": "TxSent", "confirmed": True})
        self.assertFalse(s.cancel("sl")["ok"])
        self.assertFalse(s.cancel("other")["ok"])
        self.assertEqual(s.calls, [])


if __name__ == "__main__":
    unittest.main()
