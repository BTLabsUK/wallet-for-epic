# SPDX-License-Identifier: Apache-2.0
"""The checks and money of the TX lane (linux/tx_lane.py): two app wallets, A and B, pay each other
on mainnet by every method, and every coin P put in goes back to P in the same run.

Money (the owner, 2026-11-03): at most CAP_RUN EPIC out of P per run, every send of P's at most
CAP_SEND. A is funded only up to what its remaining payments need (AMOUNT + FEE_MAX each), split in
sends of at most CAP_SEND (four payments: 0.05 + 0.03). The sweeps send A's and B's balances to P
(Max; amounts of CAP_SEND first when a balance is larger). The ledger (what P sent, what came back,
the fees paid) goes into proof.json's details["money"].

Each payment check reads both wallets' data, never a screen: A has a new outgoing of exactly AMOUNT
by the method (its transport), its fee at most FEE_MAX, posted or confirmed; B has the new incoming
of exactly AMOUNT. The method the Activity detail names on A is read too (payments.history_method)
and must agree when it is read.

The pure parts (fund_plan, sweep_plan, Ledger, check_payment, paid_already) take plain values and
digests (walletdata's schema) and are unit-tested (tests/test_trust_tx.py)."""
import decimal
import time

from . import checks
from . import hermetic
from . import walletdata as wd
from .checks import CAP_SEND, FEE_MAX, P_ADDR, POLL_S, pay_to
from .faults import HarnessFault, InfraFault, ProductFault
from .payments import METHODS, method_of
from .walletdata import num

D = decimal.Decimal
NANO = wd.NANO
AMOUNT = D("0.01")         # each payment A -> B
CAP_RUN = D("0.1")         # out of P per run, every lane phase included
DUST = FEE_MAX             # a balance below this is not worth a send (its fee would eat it)
PAY_WAIT_S = {"epicbox": 900, "http": 600, "tor": 900, "file": 600}
SPEND_WAIT_S = 1800        # A's change and B's receipts confirmed (10 blocks and some)
CHECKS = ["tx_%s_ok" % m for m in METHODS] + ["returned_ok"]


def nano(x):
    return int((D(str(x)) * NANO).to_integral_value())


# ---- pure ---------------------------------------------------------------------------------------------

def per_pay():
    return AMOUNT + FEE_MAX


def fund_plan(spendable, remaining, cap_send=CAP_SEND):
    """[EPIC amounts P sends A] so A can make [remaining] payments; spendable in nanoEPIC. The need is
    rounded up to 0.01 and split into sends of at most cap_send, largest first."""
    need = per_pay() * remaining - D(spendable or 0) / NANO
    if need <= 0:
        return []
    need = need.quantize(D("0.01"), rounding=decimal.ROUND_UP)
    out = []
    while need > 0:
        a = min(need, cap_send)
        out.append(a)
        need -= a
    return out


def sweep_plan(spendable, cap_send=CAP_SEND):
    """[the sends that empty a wallet of [spendable] nanoEPIC to P]: CAP_SEND amounts while more than
    that and a fee is left, then Max (None). [] for a balance below DUST."""
    left = D(spendable or 0) / NANO
    if left < DUST:
        return []
    out = []
    while left > cap_send + FEE_MAX:
        out.append(cap_send)
        left -= cap_send + FEE_MAX
    return out + [None]


class Ledger:
    """What P sent this run, what came back to it, the fees the app wallets paid (EPIC Decimals)."""

    def __init__(self, cap_run=CAP_RUN, cap_send=CAP_SEND):
        self.cap_run, self.cap_send = cap_run, cap_send
        self.p_sent, self.returned, self.fees = [], [], []
        self.cancelled = []  # P's sends no wallet answered, cancelled: they never left P

    def charge(self, amount):
        """P is about to send [amount]: HarnessFault over a cap (nothing is sent then)."""
        a = D(str(amount))
        if a > self.cap_send or self.sent() + a > self.cap_run:
            raise HarnessFault("fund", "P sending %s EPIC is over the caps (%s per send, %s per run, %s sent)" % (
                a, self.cap_send, self.cap_run, self.sent()))
        self.p_sent.append(a)

    def sent(self):
        return sum(self.p_sent, D(0))

    def back(self):
        return sum(self.returned, D(0))

    def fee(self):
        return sum(self.fees, D(0))

    def kept(self):
        return sum(self.cancelled, D(0))

    def unaccounted(self, held=D(0)):
        """What P sent that neither came back, nor went in fees, nor was cancelled, nor is still [held]."""
        return self.sent() - self.back() - self.fee() - self.kept() - held

    def doc(self, p_before=None, p_after=None):
        f = lambda x: format(x, "f")  # noqa: E731
        d = {"p_sent": [f(a) for a in self.p_sent], "p_sent_total": f(self.sent()),
             "returned": [f(a) for a in self.returned], "returned_total": f(self.back()),
             "fees": [f(a) for a in self.fees], "fees_total": f(self.fee()),
             "cancelled": [f(a) for a in self.cancelled], "cancelled_total": f(self.kept()),
             "cap_run": f(self.cap_run), "cap_send": f(self.cap_send)}
        # P's info: EPIC text
        if p_before is not None:
            d["p_spendable_before"] = str(p_before)
        if p_after is not None:
            d["p_spendable_after"] = str(p_after)
        return d


def _txs(d):
    return (d or {}).get("txs") or []


def _key(t):
    return t.get("slate") or ("id", t.get("id"))


def new_txs(d0, d1, direction):
    """The [direction] transactions in d1 that d0 does not have, oldest first."""
    seen = {_key(t) for t in _txs(d0)}
    return [t for t in _txs(d1) if t["direction"] == direction and _key(t) not in seen]


def sent_of(t):
    return (t.get("debited") or 0) - (t.get("credited") or 0) - (t.get("fee") or 0)


def paid_already(base, d, method, amount=AMOUNT):
    """A's outgoing of [amount] by [method] made this run (not in [base], A's data when the lane began),
    posted or confirmed: the payment phase is done. -> the transaction or None."""
    return next((t for t in new_txs(base, d, "outgoing") if t.get("transport") == method
                 and sent_of(t) == nano(amount) and t["state"] in ("posted", "confirmed")), None)


def check_payment(method, a0, a1, b0, b1, amount=AMOUNT):
    """(ok, why, facts) for one payment A -> B by [method] from both wallets' data before and after.
    ok None: not there yet (read again); False: what is there is wrong."""
    want = nano(amount)
    outs = [t for t in new_txs(a0, a1, "outgoing") if t.get("transport") == method]
    if not outs:
        other = new_txs(a0, a1, "outgoing")
        if other:
            return False, "A's new outgoing has transport %s, not %s (wallet data)" % (
                ", ".join(str(t.get("transport")) for t in other), method), {}
        return None, "A's data shows no new outgoing", {}
    t = outs[-1]
    facts = {"method": method, "a_state": t["state"], "a_transport": t.get("transport"), "sent": num(sent_of(t)),
             "fee": num(t.get("fee") or 0)}
    if sent_of(t) != want:
        return False, "A's outgoing by %s sent %s EPIC, not %s (wallet data)" % (method, num(sent_of(t)), num(want)), facts
    if (t.get("fee") or 0) > nano(FEE_MAX):
        return False, "A's fee %s EPIC is over %s (wallet data)" % (num(t["fee"]), FEE_MAX), facts
    ins = new_txs(b0, b1, "incoming")
    mine = [x for x in ins if t.get("slate") and x.get("slate") == t["slate"]] or ins
    if t["state"] not in ("posted", "confirmed") or not mine:
        return None, "A's outgoing is %s; B's data shows %s" % (
            t["state"], "no new incoming" if not mine else "the incoming %s" % mine[-1]["state"]), facts
    r = mine[-1]
    facts.update(b_state=r["state"], b_transport=r.get("transport"), received=num(r.get("credited") or 0))
    if (r.get("credited") or 0) != want:
        return False, "B received %s EPIC, not %s (wallet data)" % (num(r.get("credited") or 0), num(want)), facts
    return True, "A -> B %s EPIC by %s: A's outgoing %s (fee %s), B's incoming %s EPIC %s (B's transport %s; wallet data)" % (
        num(want), method, t["state"], num(t.get("fee") or 0), num(r["credited"]), r["state"], r.get("transport")), facts


def check_invoice(a0, a1, b0, b1, amount=AMOUNT):
    """(ok, why, facts) for an invoice A issued and B paid (B -> A, Epicbox) from both wallets' data.
    ok None: not there yet; False: what is there is wrong."""
    want = nano(amount)
    outs = new_txs(b0, b1, "outgoing")
    if not outs:
        return None, "B's data shows no new outgoing", {}
    t = outs[-1]
    facts = {"method": "invoice", "b_state": t["state"], "b_transport": t.get("transport"), "sent": num(sent_of(t)),
             "fee": num(t.get("fee") or 0)}
    if sent_of(t) != want:
        return False, "B's outgoing for the invoice sent %s EPIC, not %s (wallet data)" % (num(sent_of(t)), num(want)), facts
    if (t.get("fee") or 0) > nano(FEE_MAX):
        return False, "B's fee %s EPIC is over %s (wallet data)" % (num(t["fee"]), FEE_MAX), facts
    ins = new_txs(a0, a1, "incoming")
    mine = [x for x in ins if t.get("slate") and x.get("slate") == t["slate"]]
    if not mine or mine[-1]["state"] not in ("posted", "confirmed"):
        return None, "B's outgoing is %s; A's data shows %s" % (
            t["state"], "no incoming of that slate" if not mine else "the incoming %s" % mine[-1]["state"]), facts
    r = mine[-1]
    facts.update(a_state=r["state"], a_transport=r.get("transport"), received=num(r.get("credited") or 0))
    if (r.get("credited") or 0) != want:
        return False, "A received %s EPIC for its invoice, not %s (wallet data)" % (num(r.get("credited") or 0), num(want)), facts
    return True, "invoice: A asked %s EPIC, B paid it: B's outgoing %s (fee %s), A's incoming %s EPIC %s (transport %s; wallet data)" % (
        num(want), t["state"], num(t.get("fee") or 0), num(r["credited"]), r["state"], r.get("transport")), facts


# ---- on the lane --------------------------------------------------------------------------------------
# lane: linux/tx_lane.py's TxLane: lane.w["a"|"b"] (Wallet: ui, pay, secrets, digest), lane.funder (P),
# lane.ledger, lane.base (A's and B's data when the lane began), lane.log, lane.ok/fail.

def digest(lane, w, tag):
    try:
        d = w.digest(tag)
    except wd.ReadError as e:
        raise HarnessFault("digest-%s" % w.key, "%s's data could not be read: %s" % (w.key.upper(), e))
    lane.last_digest = d
    return d


def spendable(d):
    return ((d or {}).get("balance") or {}).get("spendable") or 0


def held(d):
    """spendable, or the total when larger (P's payment on its way counts: a phase run again sends no more)."""
    b = (d or {}).get("balance") or {}
    return max(b.get("spendable") or 0, b.get("total") or 0)


def wait_for(lane, w, what, ok, timeout, poll=POLL_S):
    """w's data once ok(d) holds; ProductFault after [timeout] s."""
    end = time.time() + timeout
    last = None
    while True:
        _awake(lane)
        d = digest(lane, w, what)
        if ok(d):
            return d
        b = (d or {}).get("balance")
        if b != last:
            lane.log("%s: %s %s" % (what, w.key.upper(), wd.fmt(b)))
            last = b
        if time.time() >= end:
            raise ProductFault(what, "%s: not reached in %d s (%s)" % (w.key.upper(), timeout, wd.fmt(last)))
        time.sleep(poll)


def _awake(lane):
    f = getattr(lane, "awake", None)
    if callable(f):
        f()


def remaining(lane):
    """The methods A has not paid B by in this run (its data)."""
    a = digest(lane, lane.w["a"], "remaining")
    return [m for m in lane.methods if not paid_already(lane.base["a"], a, m)]


def fund_to(address, relay):
    """An app wallet's Epicbox address for a send to it: as the app shows it (its relay is settings.toml's first server, which
    need not be the lane's pick); moved to [relay] only when that is a local hermetic relay."""
    if "@" in address and not hermetic.local(relay):
        return address
    return pay_to(address, relay)


def fund(lane, methods):
    """P pays A what [methods] need (fund_plan), each send waited for in A's data, then A spendable for
    the first payment. -> what P sent ([EPIC])."""
    a = lane.w["a"]
    d0 = digest(lane, a, "fund")
    plan = fund_plan(held(d0), len(methods))
    if not plan:
        lane.log("fund: A's spendable %s covers %d payments" % (num(spendable(d0)), len(methods)))
        return []
    p = checks._p_ready(lane)
    for amount in plan:
        lane.ledger.charge(amount)
        before = digest(lane, a, "fund")
        with p.exchange("fund A"):
            relay = checks._relay_with_p(lane, p)
            ok, out = p.send(fund_to(lane.address["a"]["epicbox"], relay), amount)
            lane.log("P -> A %s EPIC: %s (%s)" % (amount, "sent" if ok else "FAILED", out))
            if not ok:
                lane.ledger.p_sent.pop()
                raise HarnessFault("fund", "P send failed: %s" % out)
        mine = lambda d: [t for t in new_txs(before, d, "incoming") if (t.get("credited") or 0) == nano(amount)]  # noqa: E731
        try:
            wait_for(lane, a, "fund", lambda d: bool(mine(d)), 900)
        except ProductFault:
            unanswered(lane, p, amount, "fund: A did not answer")
            raise
        # A answered; P finalizes and posts. P that does not (its node not synced, its listener paused) is
        # the infrastructure's, never the app's
        end = time.time() + 900
        while not any(t["state"] in ("posted", "confirmed") for t in mine(digest(lane, a, "fund"))):
            if p.finalized():
                break
            if time.time() >= end:
                raise InfraFault("fund", "P sent %s EPIC, A answered, P did not finalize it in 900 s (P's node or "
                                 "listener)" % amount, sub="node")
            time.sleep(POLL_S)
    wait_for(lane, a, "fund spendable", lambda d: spendable(d) >= nano(per_pay()), SPEND_WAIT_S)
    lane.details["fund"] = "P -> A %s EPIC in %d sends (A's spendable was %s, %d payments left)" % (
        "+".join(format(x, "f") for x in plan), len(plan), num(spendable(d0)), len(methods))
    return plan


def pay(lane, method, send):
    """One payment A -> B by [method]: A spendable for it, send(a0, b0) -> (ok, why) does the sending
    (the File round trip included), then both wallets' data until check_payment says. Sets tx_<m>_ok;
    a Tor send that does not go through is tried once more, then it is the network's (InfraFault)."""
    a, b = lane.w["a"], lane.w["b"]
    check = "tx_%s_ok" % method
    pending = lane.pending.get(method)
    if pending and new_txs(pending[0], digest(lane, a, "pay-" + method), "outgoing"):
        a0, b0 = pending  # the phase runs again after the send: its payment is read, not made again
        lane.log("pay-%s: the send went before the phase ran again; reading it" % method)
    else:
        wait_for(lane, a, "pay-%s spendable" % method, lambda d: spendable(d) >= nano(per_pay()), SPEND_WAIT_S)
        tries = 2 if method == "tor" else 1
        for i in range(tries):
            a0, b0 = digest(lane, a, "pay-" + method), digest(lane, b, "pay-" + method)
            lane.pending[method] = (a0, b0)
            ok, why = send(a0, b0)
            if ok:
                break
            lane.log("pay-%s: the send did not go through: %s%s" % (method, why, "; once more" if i + 1 < tries else ""))
        else:
            if method == "tor":
                raise InfraFault("pay-tor", "the send over Tor did not go through twice: %s" % why, sub="tor")
            lane.fail(check, "the send did not go through: %s" % why)
            return
    end = time.time() + PAY_WAIT_S[method]
    while True:
        a1, b1 = digest(lane, a, "pay-" + method), digest(lane, b, "pay-" + method)
        res, why, facts = check_payment(method, a0, a1, b0, b1)
        if res is not None or time.time() >= end:
            break
        lane.log("pay-%s: %s" % (method, why))
        time.sleep(POLL_S)
    if res is None:
        if method == "tor":
            raise InfraFault("pay-tor", "not there in %d s: %s" % (PAY_WAIT_S[method], why), sub="tor")
        res, why = False, "not there in %d s: %s" % (PAY_WAIT_S[method], why)
    if facts.get("fee") and res is not None:
        lane.ledger.fees.append(D(facts["fee"]))
    lane.details.setdefault("payments", {})[method] = facts
    if res:
        label = lane.history_label(method)
        facts["a_history"] = label
        if label is not None and method_of(label) != method:
            res, why = False, "%s; but A's Activity detail names the method %r" % (why, label)
        elif label is not None:
            why += "; A's Activity detail: Method %s" % label
    (lane.ok if res else lane.fail)(check, why)


def invoice(lane, amount, names, check="pair_invoice_ok"):
    """pair-invoice: A issues an invoice for [amount] to B (paired, invoices allowed); B approves and
    pays it from what A paid it this run; checked in both wallets' data (check_invoice)."""
    a, b = lane.w["a"], lane.w["b"]
    wait_for(lane, b, "pair-invoice: B spendable", lambda d: spendable(d) >= nano(D(amount) + FEE_MAX), SPEND_WAIT_S)
    _awake(lane)
    b.pair.allow_invoices(names["a"])  # the payer allows the issuer's invoices
    a0, b0 = digest(lane, a, "pair-invoice"), digest(lane, b, "pair-invoice")
    ok, why = a.pair.issue_invoice(names["b"], amount)
    if not ok:
        lane.fail(check, "A's invoice was not sent: %s" % why)
        return
    b.pair.pay_invoice(b.ui.password)
    end = time.time() + PAY_WAIT_S["epicbox"]
    while True:
        a1, b1 = digest(lane, a, "pair-invoice"), digest(lane, b, "pair-invoice")
        res, why, facts = check_invoice(a0, a1, b0, b1, D(amount))
        if res is not None or time.time() >= end:
            break
        lane.log("pair-invoice: %s" % why)
        time.sleep(POLL_S)
    if res is None:
        res, why = False, "not there in %d s: %s" % (PAY_WAIT_S["epicbox"], why)
    if facts.get("fee"):
        lane.ledger.fees.append(D(facts["fee"]))
    lane.details.setdefault("payments", {})["invoice"] = facts
    (lane.ok if res else lane.fail)(check, why)


def sweep(lane, keys, tag, settle=True):
    """Every coin of the wallets [keys] to P (sweep_plan), each send waited for until P posted it.
    settle: first wait until the wallet's balance is all spendable (its receipts and change confirmed).
    -> what went back ([EPIC])."""
    p = checks._p_ready(lane)
    back = []
    for k in keys:
        w = lane.w[k]
        d = digest(lane, w, tag)
        if settle and ((d.get("balance") or {}).get("total") or 0) >= nano(DUST):
            d = wait_for(lane, w, "%s %s settled" % (tag, k.upper()),
                         lambda x: ((x.get("balance") or {}).get("total") or 0) == spendable(x), SPEND_WAIT_S)
        for amount in sweep_plan(spendable(d)):
            d0 = digest(lane, w, tag)
            if amount is None and spendable(d0) < nano(DUST):
                break
            with p.exchange("%s: %s back to P" % (tag, k.upper())):
                if not p.start_listener():
                    raise HarnessFault(tag, "P's listener did not start (3 tries)")
                _awake(lane)
                ok, why = w.ui.send(P_ADDR, format(amount, "f") if amount is not None else None)
                if not ok:
                    raise ProductFault(tag, "%s's send to P did not go through: %s" % (k.upper(), why))
                d1 = wait_for(lane, w, "%s %s to P" % (tag, k.upper()),
                              lambda x: any(t["state"] in ("posted", "confirmed") for t in new_txs(d0, x, "outgoing")), 900)
            t = [t for t in new_txs(d0, d1, "outgoing") if t["state"] in ("posted", "confirmed")][-1]
            got = D(sent_of(t)) / NANO
            lane.ledger.returned.append(got)
            lane.ledger.fees.append(D(t.get("fee") or 0) / NANO)
            back.append(got)
            lane.log("%s: %s -> P %s EPIC (fee %s), %s" % (tag, k.upper(), num(sent_of(t)), num(t.get("fee") or 0), t["state"]))
            if amount is not None:  # the next send waits for the change
                wait_for(lane, w, "%s %s change" % (tag, k.upper()), lambda x: spendable(x) >= nano(DUST), SPEND_WAIT_S)
    return back


def unanswered(lane, p, amount, why):
    """P's last send, which no wallet answered, cancelled: its coins never left P (the ledger's cancelled)."""
    slate = p.slate
    with p.exchange("cancel %s" % (slate or "")[:8]):
        ok, note = p.cancel(slate, why)
    lane.log("P's send %s of %s EPIC: %s (%s)" % ((slate or "")[:8], amount, "cancelled" if ok else "NOT cancelled", note))
    if ok:
        lane.ledger.cancelled.append(D(str(amount)))
    return ok


def returned(lane):
    """returned_ok: A and B hold less than DUST (all sent to P, wallet data) and what came back is what P
    sent less the fees the wallets paid."""
    left = {k: (digest(lane, w, "returned").get("balance") or {}) for k, w in lane.w.items()}
    held = {k: (b.get("total") or 0) for k, b in left.items()}
    led = lane.ledger
    lost = led.unaccounted(D(sum(held.values())) / NANO)
    why = "P sent %s EPIC, %s came back, fees %s, %s cancelled unanswered; %s (wallet data)%s" % (
        led.sent(), led.back(), led.fee(), led.kept(), ", ".join("%s holds %s" % (k.upper(), num(v)) for k, v in held.items()),
        "; %s EPIC not accounted for" % lost if lost else "")
    if all(v < nano(DUST) for v in held.values()) and not lost:
        lane.ok("returned_ok", why)
    else:
        lane.fail("returned_ok", why)
    return held

