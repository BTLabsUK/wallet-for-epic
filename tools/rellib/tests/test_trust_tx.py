# SPDX-License-Identifier: Apache-2.0
"""The TX lane's pure parts (drivers/core/txchecks.py, core/payments.py): what P funds and the caps,
what the sweeps send, when a payment phase is done already, the payment check on fake wallet data,
the invoice check, the pairing words, the method a history detail names, the transaction file found by its slate, the stand-in portal's
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
from core import linking as lk  # noqa: E402
from core.pairing import invite_link, words_in  # noqa: E402
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

    def test_returned_counts_every_coin_p_sent(self):
        class Lane:
            ledger = tx.Ledger()
            w = {"a": None, "b": None}
            results = {}

            def ok(self, k, why):
                self.results[k] = (True, why)

            def fail(self, k, why):
                self.results[k] = (False, why)
        lane = Lane()
        led = lane.ledger
        led.charge("0.05")
        led.charge("0.05")
        held = {"a": digest(spendable=0.002), "b": digest()}
        with unittest.mock.patch.object(tx, "digest", lambda lane, w, tag: held[[k for k in lane.w if lane.w[k] is w][0]]):
            lane.w = {"a": object(), "b": object()}
            tx.returned(lane)
            self.assertFalse(lane.results["returned_ok"][0])  # 0.048 not accounted for (run-f3: P's send unanswered)
            self.assertIn("not accounted for", lane.results["returned_ok"][1])
            led.cancelled.append(D("0.05"))
            led.returned.append(D("0.041"))
            led.fees.append(D("0.007"))
            tx.returned(lane)
            self.assertTrue(lane.results["returned_ok"][0], lane.results["returned_ok"][1])
        self.assertEqual(led.doc()["cancelled_total"], "0.05")

    def test_ledger_counts_what_runs_before_left(self):
        """run-f6: sweep-start sent B's 0.04 back and A spent its 0.009: not P's coins this run."""
        led = tx.Ledger()
        led.carried.update(a=D("0.009"), b=D("0.04"))
        led.charge("0.05")
        led.charge("0.03")
        led.returned += [D("0.039"), D("0.017"), D("0.051")]
        led.fees += [D("0.001"), D("0.007"), D("0.008"), D("0.003"), D("0.003")]
        self.assertEqual(led.unaccounted(), 0)
        self.assertEqual(led.doc()["carried_in_total"], "0.049")

    def test_ledger_p_fees_and_the_change_p_should_see(self):
        """run-f6: P 2.13925 -> 2.15225 is +0.107 back - 0.08 out - P's own two fees of 0.007."""
        class P:
            slate, fee = None, None
        led, p = tx.Ledger(), P()
        for slate, amount in (("S1", "0.05"), ("S2", "0.03")):
            led.charge(amount)
            p.slate, p.fee = slate, "0.007"
            led.p_sent_by(p)
        led.returned += [D("0.039"), D("0.017"), D("0.051")]
        doc = led.doc("2.13925115", "2.15225115")
        self.assertEqual(doc["p_fees_total"], "0.014")
        self.assertEqual(doc["p_change_expected"], doc["p_change_actual"])
        led.charge("0.01")
        p.slate, p.fee = "S3", None  # a service that does not give the fee
        led.p_sent_by(p)
        led.cancelled.append(D("0.01"))
        led.p_fees.pop("S3")
        self.assertEqual(led.doc()["p_change_expected"], "0.013")

    def test_a_send_to_p_unanswered_kicks_p_then_is_infra(self):
        """run-f8: B's send to P unanswered while P's listener was silent: P kicked once, then P's (infra)."""
        from core.faults import InfraFault

        class Lane:
            logs = []

            def log(self, m):
                self.logs.append(m)

        class P:
            kicks = 0

            def kick(self, why):
                self.kicks += 1
                raise OSError("unknown op")  # an older service: harmless

        calls = []

        def never(lane, w, what, ok, timeout):
            calls.append(timeout)
            raise tx.ProductFault(what, "B: not reached in %d s" % timeout)

        lane, p = Lane(), P()
        with unittest.mock.patch.object(tx, "wait_for", never):
            with self.assertRaises(InfraFault) as cm:
                tx.wait_p(lane, p, None, "sweep-start B to P", lambda d: False, 900, "sweep-start")
        self.assertEqual(p.kicks, 1)
        self.assertEqual(calls, [tx.KICK_AFTER_S, 900 - tx.KICK_AFTER_S])
        self.assertEqual(cm.exception.sub, "p")
        answers = iter([tx.ProductFault("x", "late"), {"balance": {}}])

        def late(lane, w, what, ok, timeout):
            a = next(answers)
            if isinstance(a, Exception):
                raise a
            return a
        with unittest.mock.patch.object(tx, "wait_for", late):
            self.assertEqual(tx.wait_p(lane, p, None, "x", None, 900, "sweep-end"), {"balance": {}})

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


class FundToTest(unittest.TestCase):
    def test_the_apps_own_relay_is_kept(self):
        # a fresh 26.11.0 lists epicbox.epiccash.com first: its address is there, whatever the lane picked
        self.assertEqual(tx.fund_to("es1@epicbox.epiccash.com", "epicbox.stackwallet.com"), "es1@epicbox.epiccash.com")

    def test_a_local_relay_readdresses(self):
        self.assertEqual(tx.fund_to("es1@epicbox.epiccash.com", "127.0.0.1:43423"), "es1@127.0.0.1:43423")

    def test_a_bare_address_takes_the_relay(self):
        self.assertEqual(tx.fund_to("es1", "epicbox.stackwallet.com"), "es1@epicbox.stackwallet.com")


class WrongRelayTest(unittest.TestCase):
    def test_another_relay_is_the_harness(self):
        self.assertIn("epicbox.epiccash.com", tx.wrong_relay("es1@epicbox.stackwallet.com", "epicbox.epiccash.com"))

    def test_the_same_relay_or_unknown_is_the_app(self):
        self.assertIsNone(tx.wrong_relay("es1@epicbox.epiccash.com", "epicbox.epiccash.com"))
        self.assertIsNone(tx.wrong_relay("es1@epicbox.epiccash.com", None))


class InvoiceCheckTest(unittest.TestCase):
    def setUp(self):
        self.a0 = digest(t("incoming", credited=0.04, slate="F1"))
        self.b0 = digest(t("incoming", credited=0.01, slate="AB"))

    def test_paid(self):
        b1 = digest(*self.b0["txs"], out(0.01, fee=0.006, change=0.02, state="posted", slate="IV"))
        a1 = digest(*self.a0["txs"], t("incoming", state="posted", credited=0.01, slate="IV"))
        ok, why, facts = tx.check_invoice(self.a0, a1, self.b0, b1)
        self.assertTrue(ok, why)
        self.assertEqual((facts["sent"], facts["fee"], facts["received"]), ("0.01", "0.006", "0.01"))

    def test_not_yet_and_wrong(self):
        self.assertIsNone(tx.check_invoice(self.a0, self.a0, self.b0, self.b0)[0])
        b1 = digest(*self.b0["txs"], out(0.01, state="waiting", slate="IV"))
        self.assertIsNone(tx.check_invoice(self.a0, self.a0, self.b0, b1)[0])  # A has not posted it
        a_other = digest(*self.a0["txs"], t("incoming", state="posted", credited=0.01, slate="ZZ"))
        self.assertIsNone(tx.check_invoice(self.a0, a_other, self.b0, b1)[0])  # matched by slate only
        b2 = digest(*self.b0["txs"], out(0.02, state="posted", slate="IV"))
        self.assertIs(tx.check_invoice(self.a0, self.a0, self.b0, b2)[0], False)
        a_less = digest(*self.a0["txs"], t("incoming", state="posted", credited=0.009, slate="IV"))
        b3 = digest(*self.b0["txs"], out(0.01, state="posted", slate="IV"))
        ok, why, _ = tx.check_invoice(self.a0, a_less, self.b0, b3)
        self.assertIs(ok, False)
        self.assertIn("received 0.009", why)


class PairingTest(unittest.TestCase):
    def test_words_in(self):
        self.assertEqual(words_in("The four words\n1 apple\n2 Bridge\n3 canal\n4 delta"), ["apple", "bridge", "canal", "delta"])
        self.assertEqual(words_in("apple, bridge, canal, delta"), ["apple", "bridge", "canal", "delta"])
        self.assertEqual(words_in(""), [])

    def test_invite_link(self):
        self.assertEqual(invite_link("Pair with me in BT Wallet: https://x.example/p#abc"), "https://x.example/p#abc")
        self.assertIsNone(invite_link("no link here"))


class LinkAnswersTest(unittest.TestCase):
    """LINK-1: P pays the address A and A2 share; exactly one install's answer takes."""
    S = "04D4C4FE-1111-2222-3333-444455556666"

    def rx(self, state="confirmed", amount=0.01, slate=None):
        return t("incoming", state=state, credited=amount, slate=slate or self.S.lower())

    def check(self, a, a2, settled=False):
        return lk.check_answers(self.S, {"a": digest(*a), "a2": digest(*a2)}, nn(0.01), settled=settled)

    def test_slate_key(self):
        self.assertEqual(lk.slate_key(self.S), lk.slate_key(self.S.lower().replace("-", "")))
        self.assertEqual(lk.slate_key(None), "")

    def test_one_answer_confirmed(self):
        ok, why, facts = self.check([self.rx()], [])
        self.assertTrue(ok, why)
        self.assertEqual(facts["answered"], "a")
        self.assertTrue(facts["confirmed"])

    def test_loser_cancelled(self):
        ok, why, facts = self.check([self.rx(state="cancelled")], [self.rx()])
        self.assertTrue(ok, why)
        self.assertEqual(facts["answered"], "a2")

    def test_both_took(self):
        ok, why, _ = self.check([self.rx()], [self.rx(state="posted")])
        self.assertIs(ok, False)
        self.assertIn("a and a2", why)

    def test_loser_open(self):
        ok, _, facts = self.check([self.rx()], [self.rx(state="pending")])
        self.assertIsNone(ok)
        self.assertTrue(facts["confirmed"])
        ok, why, _ = self.check([self.rx()], [self.rx(state="pending")], settled=True)
        self.assertIs(ok, False)
        self.assertIn("still holds", why)

    def test_not_yet(self):
        self.assertIsNone(self.check([self.rx(state="pending")], [])[0])
        ok, _, facts = self.check([self.rx(state="posted")], [])
        self.assertIsNone(ok)
        self.assertNotIn("confirmed", facts)

    def test_wrong_amount(self):
        self.assertIs(self.check([self.rx(amount=0.02)], [])[0], False)

    def test_other_slate(self):
        self.assertIsNone(self.check([self.rx(slate="ffff")], [])[0])


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
