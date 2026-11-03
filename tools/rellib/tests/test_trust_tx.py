# SPDX-License-Identifier: Apache-2.0
"""The TX lane's pure parts (drivers/core/txchecks.py, core/payments.py): what P funds and the caps,
what the sweeps send, when a payment phase is done already, the payment check on fake wallet data,
the method a history detail names, the transaction file found by its slate, the stand-in portal's
refusal of paths outside the sandbox, and REL_TRUST_UNTIL on the TX lane's phases."""
import decimal
import os
import sys
import tempfile
import time
import unittest
import unittest.mock

HERE = os.path.dirname(os.path.abspath(__file__))
DRV = os.path.join(os.path.dirname(HERE), "drivers")
sys.path.insert(0, DRV)
sys.path.insert(0, os.path.join(DRV, "linux"))

from core import lane as core_lane  # noqa: E402
from core import txchecks as tx  # noqa: E402
from core.faults import HarnessFault  # noqa: E402
from core.payments import METHOD_LABEL, ONION_RX, file_for, method_of  # noqa: E402
import portal_stub  # noqa: E402

D = decimal.Decimal
N = tx.NANO


def nn(x):
    return int(round(x * N))


def t(direction, state="confirmed", transport="epicbox", credited=0, debited=0, fee=None, slate=None, id=None):
    return dict(id=id, direction=direction, state=state, transport=transport, credited=nn(credited),
                debited=nn(debited), fee=None if fee is None else nn(fee), height=None, counterparty=None, slate=slate)


def out(sent, fee=0.007, change=0.0, **kw):
    """An outgoing that sent [sent]: debited = sent + fee + change, credited = change."""
    return t("outgoing", debited=sent + fee + change, credited=change, fee=fee, **kw)


def digest(*txs, spendable=0.0, total=None):
    return {"balance": {"spendable": nn(spendable), "total": nn(spendable if total is None else total)},
            "txs": list(txs)}


class MoneyTest(unittest.TestCase):
    def test_fund_four_payments_from_empty_is_005_and_003(self):
        self.assertEqual(tx.fund_plan(0, 4), [D("0.05"), D("0.03")])

    def test_fund_counts_what_a_holds_and_rounds_up(self):
        self.assertEqual(tx.fund_plan(int(0.025 * N), 2), [D("0.02")])
        self.assertEqual(tx.fund_plan(int(0.04 * N), 2), [])
        self.assertEqual(tx.fund_plan(int(0.0349 * N), 2), [D("0.01")])

    def test_every_fund_send_within_cap_send_and_the_run_within_cap_run(self):
        for left in range(0, 6):
            plan = tx.fund_plan(0, left)
            self.assertTrue(all(a <= tx.CAP_SEND for a in plan), plan)
            self.assertLessEqual(sum(plan, D(0)), tx.per_pay() * left + D("0.01"))
        self.assertLessEqual(sum(tx.fund_plan(0, 4), D(0)), tx.CAP_RUN)

    def test_ledger_refuses_over_the_caps_and_sends_nothing(self):
        led = tx.Ledger()
        led.charge("0.05")
        led.charge("0.03")
        with self.assertRaises(HarnessFault):
            led.charge("0.06")  # over the per-send cap
        led.charge("0.02")
        with self.assertRaises(HarnessFault):
            led.charge("0.01")  # 0.11 out of P this run
        self.assertEqual(led.sent(), D("0.1"))
        doc = led.doc("5.0", "4.95")
        self.assertEqual(doc["p_sent_total"], "0.10")
        self.assertEqual(doc["p_spendable_before"], "5.0")

    def test_sweep_plan(self):
        self.assertEqual(tx.sweep_plan(0), [])
        self.assertEqual(tx.sweep_plan(int(0.009 * N)), [])  # below DUST: its fee would eat it
        self.assertEqual(tx.sweep_plan(int(0.04 * N)), [None])
        self.assertEqual(tx.sweep_plan(int(0.12 * N)), [D("0.05"), None])
        self.assertTrue(all(a is None or a <= tx.CAP_SEND for a in tx.sweep_plan(int(0.5 * N))))


class PaymentCheckTest(unittest.TestCase):
    def setUp(self):
        self.a0 = digest(t("incoming", credited=0.08, slate="F1"))
        self.b0 = digest()

    def test_good_payment(self):
        a1 = digest(*self.a0["txs"], out(0.01, change=0.06, transport="http", state="posted", slate="AB"))
        b1 = digest(t("incoming", state="confirmed", transport="http", credited=0.01, slate="AB"))
        ok, why, facts = tx.check_payment("http", self.a0, a1, self.b0, b1)
        self.assertTrue(ok, why)
        self.assertEqual(facts["sent"], "0.01")
        self.assertEqual(facts["fee"], "0.007")

    def test_not_there_yet_is_none(self):
        self.assertIsNone(tx.check_payment("tor", self.a0, self.a0, self.b0, self.b0)[0])
        a1 = digest(*self.a0["txs"], out(0.01, transport="tor", state="waiting", slate="AB"))
        self.assertIsNone(tx.check_payment("tor", self.a0, a1, self.b0, self.b0)[0])
        a2 = digest(*self.a0["txs"], out(0.01, transport="tor", state="posted", slate="AB"))
        self.assertIsNone(tx.check_payment("tor", self.a0, a2, self.b0, self.b0)[0])  # B shows nothing yet

    def test_wrong_amount_fee_transport_received(self):
        b1 = digest(t("incoming", credited=0.01, slate="AB"))
        bad = [
            (out(0.02, transport="epicbox", state="posted", slate="AB"), b1, "sent 0.02"),
            (out(0.01, fee=0.02, transport="epicbox", state="posted", slate="AB"), b1, "fee 0.02"),
            (out(0.01, transport="http", state="posted", slate="AB"), b1, "transport http"),
            (out(0.01, transport="epicbox", state="posted", slate="AB"), digest(t("incoming", credited=0.009, slate="AB")),
             "received 0.009"),
        ]
        for a_tx, b, want in bad:
            ok, why, _ = tx.check_payment("epicbox", self.a0, digest(*self.a0["txs"], a_tx), self.b0, b)
            self.assertIs(ok, False, want)
            self.assertIn(want, why)

    def test_b_matched_by_slate(self):
        a1 = digest(out(0.01, transport="file", state="posted", slate="AB"))
        b1 = digest(t("incoming", credited=0.01, transport="file", slate="AB"), t("incoming", credited=0.5, slate="ZZ"))
        self.assertTrue(tx.check_payment("file", self.b0, a1, self.b0, b1)[0])

    def test_paid_already_only_this_run(self):
        base = digest(out(0.01, transport="epicbox", slate="OLD"))
        d = digest(*base["txs"])
        self.assertIsNone(tx.paid_already(base, d, "epicbox"))
        d = digest(*base["txs"], out(0.01, transport="epicbox", state="posted", slate="NEW"))
        self.assertIsNotNone(tx.paid_already(base, d, "epicbox"))
        self.assertIsNone(tx.paid_already(base, d, "http"))
        d = digest(*base["txs"], out(0.01, transport="tor", state="waiting", slate="T"))
        self.assertIsNone(tx.paid_already(base, d, "tor"))  # not posted: the phase is not done

    def test_held_counts_a_payment_on_its_way(self):
        self.assertEqual(tx.held(digest(spendable=0.01, total=0.06)), int(0.06 * N))


class RecipesTest(unittest.TestCase):
    def test_method_labels(self):
        for m, label in METHOD_LABEL.items():
            self.assertEqual(method_of(label), m)
            self.assertEqual(method_of("  %s " % label.upper()), m)
        self.assertIsNone(method_of("Slatepack"))

    def test_onion(self):
        o = "a" * 52 + "2345"
        self.assertEqual(ONION_RX.match("http://%s.onion/" % o).group(1), o)
        self.assertIsNone(ONION_RX.match("http://127.0.0.1:3415"))

    def test_file_for_by_slate(self):
        with tempfile.TemporaryDirectory() as d:
            for n in ("abcdef12.tx", "abcdef12-1.tx", "abcdef12.response", "ffff0000.tx"):
                open(os.path.join(d, n), "w").close()
            os.utime(os.path.join(d, "abcdef12.tx"), (time.time() - 60,) * 2)
            self.assertEqual(os.path.basename(file_for([d], "ABCDEF12-3456-7890", wait_s=0)), "abcdef12-1.tx")
            self.assertEqual(os.path.basename(file_for([d], "abcdef1234567890", ".response", wait_s=0)), "abcdef12.response")
            self.assertIsNone(file_for([d], "00000000ffff", wait_s=0))
            self.assertIsNone(file_for([d], "", wait_s=0))


class PortalTest(unittest.TestCase):
    def test_answers_only_inside_the_sandbox(self):
        with tempfile.TemporaryDirectory() as root:
            sb = os.path.join(root, "sb")
            os.makedirs(os.path.join(sb, "home", "inbox"))
            inside = os.path.join(sb, "home", "inbox", "x.tx")
            portal_stub.answer(sb, inside)
            with open(os.path.join(sb, "portal", "next")) as f:
                self.assertEqual(f.read(), inside)
            for bad in (os.path.join(root, "x.tx"), os.path.join(sb, "..", "x.tx"), "/etc/passwd"):
                with self.assertRaises(ValueError):
                    portal_stub.answer(sb, bad)
            os.symlink(root, os.path.join(sb, "out"))
            with self.assertRaises(ValueError):
                portal_stub.answer(sb, os.path.join(sb, "out", "x.tx"))  # a link out of it
            portal_stub.answer(sb, None)
            self.assertFalse(os.path.exists(os.path.join(sb, "portal", "next")))

    def test_refuses_the_accounts_own_bus(self):
        with tempfile.TemporaryDirectory() as sb, unittest.mock.patch.object(portal_stub.sandbox, "guard"):
            with self.assertRaises(SystemExit):
                portal_stub._own_bus(sb, {"DBUS_SESSION_BUS_ADDRESS": "unix:path=/run/user/%d/bus" % os.getuid()})


class UntilTest(unittest.TestCase):
    def test_until_takes_the_lanes_own_phases(self):
        from linux import tx_lane  # noqa: F401 — PHASES only; nothing starts
        with unittest.mock.patch.dict(os.environ, {"REL_TRUST_UNTIL": "pay-http", "REL_RUN_KIND": "test"}):
            self.assertEqual(core_lane.until_phase(tx_lane.PHASES), "pay-http")
            with self.assertRaises(core_lane.UntilRefused):
                core_lane.until_phase()  # not a phase of the update lane
        with unittest.mock.patch.dict(os.environ, {"REL_TRUST_UNTIL": "fund", "REL_RUN_KIND": "release"}):
            with self.assertRaises(core_lane.UntilRefused):
                core_lane.until_phase(tx_lane.PHASES)


if __name__ == "__main__":
    unittest.main()
