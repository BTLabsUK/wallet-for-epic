# SPDX-License-Identifier: Apache-2.0
"""P's free outputs before G4 (p_outputs): counted with one confirmation, split below LOW by a self-send."""
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(os.path.dirname(HERE)))

from rellib import p_outputs  # noqa: E402


def outputs_text(tip, heights, status="Unspent"):
    rows = ["%s  %d  %d  0  %s  false  1  0.10000000  None" % ("09" + "a" * 64, 9000000 + i, h, status)
            for i, h in enumerate(heights)]
    return "\n".join(["____ Wallet Outputs - Account 'default' - Block Height: %d ____" % tip, ""] + rows)


class FakeP:
    def __init__(self, text, send_out="Command 'send' completed successfully"):
        self.text, self.send_out, self.calls = text, send_out, []

    def run(self, args):
        self.calls.append(args)
        return 0, self.text if args == ["outputs"] else self.send_out


class POutputsTest(unittest.TestCase):
    def test_counts_with_one_confirmation(self):
        text = outputs_text(100, [90, 99, 100]) + "\n" + outputs_text(100, [80], "Locked").splitlines()[-1]
        self.assertEqual(p_outputs.spendable(text), 3)
        self.assertEqual(p_outputs.spendable(text, 10), 1)
        self.assertIsNone(p_outputs.spendable("no height here"))

    def test_enough_outputs_sends_nothing(self):
        p = FakeP(outputs_text(100, [50] * p_outputs.LOW))
        good, note = p_outputs.ensure(p, lambda m: None)
        self.assertTrue(good)
        self.assertEqual(p.calls, [["outputs"]])

    def test_below_low_splits_with_a_self_send(self):
        p = FakeP(outputs_text(100, [50] * 5))
        good, note = p_outputs.ensure(p, lambda m: None)
        self.assertTrue(good, note)
        send = p.calls[1]
        self.assertEqual(send[:5], ["send", "-m", "self", "-d", "default"])
        added = 2 * int(send[send.index("-o") + 1])
        self.assertTrue(p_outputs.LOW <= 5 + added <= p_outputs.HIGH, send)

    def test_failed_split_fails(self):
        p = FakeP(outputs_text(100, [50]), send_out="ERROR: Not enough funds")
        good, note = p_outputs.ensure(p, lambda m: None)
        self.assertFalse(good)
        self.assertIn("Not enough funds", note)


if __name__ == "__main__":
    unittest.main()
