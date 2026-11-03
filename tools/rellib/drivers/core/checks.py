# SPDX-License-Identifier: Apache-2.0
"""The checks of the G4 update-trust lanes, the same on every platform, judged on the wallet's own data
(core/walletdata.py digests) and never on a screen.

lane.py calls, in this order:
    fund_before(lane, address)      P pays the previous release's wallet (with a top-up for a low lane seed);
                                    waits until the data shows it spendable
    settle(lane, before) -> after   the candidate's data, read again until it stops moving
    compare(lane, before, after, snap)   lane.ok / lane.fail per check
    funds_legs(lane, after)         receive on the candidate, send back to P through the UI: a lane seed's
                                    wallet this run's inflow (an amount), any other wallet everything (Max)
    public(digest)                  the digest without anything secret (it goes into a saved state)

A check that cannot be read says so in its detail ("NOT read: ..."); it is never passed by saying nothing.
The wording of the details follows windows/trust.py, which this replaces.
"""
import datetime
import decimal
import json
import os
import re
import sys
import time

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import facts  # noqa: E402
import migration  # noqa: E402
import seed  # noqa: E402
from . import hermetic  # noqa: E402
from . import walletdata as wd  # noqa: E402
from .faults import Fault, HarnessFault, HarnessGone, ProductFault  # noqa: E402

D = decimal.Decimal
NANO = wd.NANO
FUND_IN = "0.01"
FUND_AFTER = "0.01"
CAP_SEND = D("0.05")
CAP_JOB = D("1")
# A lane seed's wallet (lane.mode "seed") keeps its coins between runs: when its spendable is below
# TOPUP_BELOW, P's payment before the update carries TOPUP more, capped so the one payment stays within
# CAP_SEND (0.01 + 0.04). The top-up stays in the lane; only this run's inflow goes back to P.
TOPUP_BELOW = D("0.05")
TOPUP = D("0.05")
FEE_MAX = D("0.01")  # what the doctor allows for each payment's fee (0.003-0.007 seen; 0.006 in 26.11.0 run-4)
CREATE_CHECKS = ["create_ok"]
P_ADDR = os.environ.get("REL_P_ADDR") or "esa57kJmWkZyX8fSkKPW2Gu12ENhFF6MXfdsrsY4gqVK58ZwzB4d@epicbox.stackwallet.com"
POLL_S = 20
FUND_WAIT_S = 1800

MIGRATION_CHECKS = ["store_encrypted", "app_files_kept", "lan_nodes_kept", "contact_note_kept"]
# What the recipe sets on the previous release through its screens (lane._fresh), and what must read back.
WANT_SETTINGS = {"theme": "Light", "label": "Trust " + datetime.datetime.now().strftime("%m%d %H%M"),
                 "confirmations": facts.TEST_CONFIRMATIONS, "technical_details": True}
# The two payment checks in the names the lane requires them under.
RECEIVE = ("receive_ok", "receive_after_update")
SEND = ("send_ok", "send_after_update")
TOR = "tor_payment_ok"  # the Tor lanes' after-update legs went over Tor: never required (warns only)

num = wd.num
fmt = wd.fmt
short = wd.short
host = wd.host


# ---- helpers ----------------------------------------------------------------------------------------

def _cand_version():
    return os.environ.get("REL_CANDIDATE_VERSION", "")


def migrating():
    """(migrate, seed_files): the candidate keeps the store encrypted; the previous release had it plain."""
    m = facts.encrypts_store(_cand_version())
    return m, m and not facts.encrypts_store(os.environ.get("REL_PREVIOUS_VERSION", ""))


def _names(lane, pair):
    """The check names of [pair] the lane requires (both when it names neither: the first)."""
    hit = [c for c in pair if c in lane.required]
    return hit or [pair[0]]


def _set(lane, pair, ok, why):
    for c in _names(lane, pair):
        (lane.ok if ok else lane.fail)(c, why)


def _digest(lane, tag):
    try:
        d = lane.p.digest(tag, lane.secrets)
    except wd.ReadError as e:
        raise HarnessFault("digest-" + tag, "the wallet's data could not be read: %s" % e)
    lane.last_digest = d  # its log's hosts are the lane's evidence of the servers the app touched
    return d


def same_tx(t0, t1):
    """The same payment: its slate, else direction and amounts (states move on with confirmations)."""
    if t0.get("slate") and t1.get("slate"):
        return t0["slate"] == t1["slate"]
    return (t0["direction"], t0["credited"], t0["debited"]) == (t1["direction"], t1["credited"], t1["debited"])


def match_txs(t0, t1):
    """Each transaction of [t0] paired with a different one of [t1]: by slate first, then by direction and
    amounts (a restored wallet's scanned transactions have no slate and no counterparty, and two of them
    can have the same amounts). -> (pairs, unmatched of t0)."""
    free = list(range(len(t1)))
    pairs, rest = [], []
    for t in t0:
        i = next((i for i in free if t.get("slate") and t1[i].get("slate") == t["slate"]), None)
        if i is None:
            rest.append(t)
        else:
            free.remove(i)
            pairs.append((t, t1[i]))
    missing = []
    for t in rest:
        fits = [i for i in free if same_tx(t, t1[i])]
        i = next((i for i in fits if bool(t1[i].get("slate")) == bool(t.get("slate"))), fits[0] if fits else None)
        if i is None:
            missing.append(t)
        else:
            free.remove(i)
            pairs.append((t, t1[i]))
    return pairs, missing


def txs_text(ts, most=8):
    text = "; ".join("%s %s EPIC %s, %s" % (t["direction"], num(t["credited"] or t["debited"]), t["state"],
                                             short(t.get("counterparty")) if t.get("counterparty") else "no counterparty")
                     for t in ts[:most])
    return text + ("; and %d more" % (len(ts) - most) if len(ts) > most else "")


def _budget(lane, amount):
    a = D(str(amount))
    spent = getattr(lane, "_p_spent", D(0))
    if a > CAP_SEND or spent + a > CAP_JOB:
        raise HarnessFault("fund", "amount %s over the P caps (%s per send, %s per job, %s used)" % (amount, CAP_SEND, CAP_JOB, spent))
    lane._p_spent = spent + a


def _save(lane, name, doc):
    try:
        with open(os.path.join(lane.out, name), "w") as f:
            json.dump(doc, f, indent=1, default=str)
    except OSError as e:
        lane.log("could not write %s: %s" % (name, e))


def _txs(d):
    return (d or {}).get("txs") or []


def _spendable(d):
    return ((d or {}).get("balance") or {}).get("spendable")


def _unlock(lane):
    """A locked wallet does not listen on Epicbox, so P's payment would wait for nothing."""
    f = getattr(getattr(lane, "ui", None), "ensure_unlocked", None)
    if callable(f):
        f()


# ---- funding ----------------------------------------------------------------------------------------

def _p_ready(lane):
    p = lane.funder
    if p is None:
        raise HarnessFault("fund", "no P (the funded CLI wallet) was given to the lane")
    why = p.ready()
    if why:
        raise HarnessFault("fund", "P is not ready: %s" % why)
    return p


def _relay_with_p(lane, p):
    """The relay in use, which P must post through too. A local relay (core/hermetic.py plan) works only
    when P's own listener and sender are on it: P is on another host and reaches no relay but its
    address's. This is the one place that says so."""
    relay = host(getattr(lane.p, "relay", "") or "")
    if hermetic.local(relay):
        p_relay = getattr(p, "relay", lambda: None)()
        if host(p_relay or "") != relay:
            raise HarnessFault("fund", "the relay in use is the local %s but P posts through %s" % (
                relay, p_relay or "a relay its service does not name"))
    return relay


def pay_to(address, relay):
    """[address] at the relay in use, whatever domain it came with; as given when no relay is known."""
    return "%s@%s" % (address.split("@", 1)[0], relay) if relay else address


def _again(fallback, e):
    """A leg's next deadline after [fallback] (a leg over Tor: Tor off, then the same payment waited for
    again in the clear); [e] raised when there is none."""
    if fallback is None:
        raise e
    fallback(e.what)
    return time.time() + 900


def _pay(lane, address, amount, tag, what, count_dir="incoming", fallback=None):
    """P sends [amount] to [address]; the wallet's data must show the new incoming transaction confirmed
    (P's confirmed payment is the proof of receipt). [fallback](why) is called once when it does not
    (see _again). -> (txs before, the new transaction)."""
    p = _p_ready(lane)
    _budget(lane, amount)
    d0 = _digest(lane, tag)
    n0 = len([t for t in _txs(d0) if t["direction"] == count_dir])
    with p.exchange(what):
        _unlock(lane)
        if not p.start_listener():
            raise HarnessFault("fund", "P's listener did not start (3 tries)")
        relay = _relay_with_p(lane, p)
        # the wallet listens on the relay in use only: a bare address, or one with the LEPIC CLI's default
        # domain, would go to another relay
        full = pay_to(address, relay)
        ok, out = p.send(full, amount)
        lane.log("P -> %s %s: %s (%s)" % (short(address), amount, "sent" if ok else "FAILED", out))
        if not ok:
            raise HarnessFault("fund", "P send failed: %s" % out)
        fault = HarnessFault if tag == "previous" else ProductFault
        end = time.time() + 900
        last, posted = None, False
        while not posted:
            while time.time() < end:
                d = _digest(lane, tag)
                new = [t for t in _txs(d) if t["direction"] == count_dir][n0:]
                state = [(t["state"], num(t["credited"])) for t in new]
                if state != last:
                    lane.log("%s: wallet records %s" % (what, state or "nothing yet"))
                    last = state
                if new and new[-1]["state"] == "confirmed":
                    return d0, new[-1]
                if new and p.finalized():
                    posted = True
                    break
                time.sleep(POLL_S)
            if not posted:
                end, fallback = _again(fallback, fault(what, "P sent %s EPIC and the wallet's data shows no incoming transaction in 15 min (wallet records %s)" % (amount, last))), None
    while True:
        while time.time() < end:
            d = _digest(lane, tag)
            new = [t for t in _txs(d) if t["direction"] == count_dir][n0:]
            if new and new[-1]["state"] == "confirmed":
                return d0, new[-1]
            time.sleep(POLL_S)
        end, fallback = _again(fallback, fault(what, "posted by P, not confirmed in the wallet's data in 15 min (wallet records %s)" % last)), None


def wait_spendable(lane, tag, at_least, what, timeout=FUND_WAIT_S):
    """The digest once its spendable balance is at least [at_least] nanoEPIC and equals the total."""
    end = time.time() + timeout
    last = None
    while time.time() < end:
        d = _digest(lane, tag)
        b = d.get("balance")
        if b != last:
            lane.log("%s: %s" % (what, fmt(b)))
            last = b
        if b and b["spendable"] >= at_least and b["spendable"] == b["total"]:
            return d
        time.sleep(POLL_S)
    raise ProductFault(what, "not spendable in %d s (last %s)" % (timeout, fmt(last)))


def _nano(s):
    return int((D(str(s)) * NANO).to_integral_value())


def seeded(lane):
    return getattr(lane, "mode", None) == "seed"


def p_pays(spendable, seed):
    """(what P pays before the update as EPIC text, the top-up in it) for a wallet whose spendable is
    [spendable] nanoEPIC (None: not known, counted as low). Only a lane seed's wallet gets a top-up."""
    if not seed or (spendable is not None and D(spendable) / NANO >= TOPUP_BELOW):
        return FUND_IN, D(0)
    top = min(TOPUP, CAP_SEND - D(FUND_IN))
    return format(D(FUND_IN) + top, "f"), top


def _funded(lane, amount, tx):
    """A payment from P the wallet's data shows: kept on the lane seed's record (lane.on_funding)."""
    f = getattr(lane, "on_funding", None)
    if callable(f):
        f(amount, tx)


def _funded_at(lane, tx, d):
    """The height P's payment [tx] confirmed at, from the data [d] that shows it spendable: kept on the lane
    seed's record (lane.on_funding_height), so the wallet's birth can be its first output."""
    f = getattr(lane, "on_funding_height", None)
    t = next((t for t in _txs(d) if tx and tx.get("slate") and t.get("slate") == tx["slate"]), None)
    if callable(f) and t and t.get("height") is not None:
        f(tx, t["height"])


def fund_before(lane, address):
    """P pays the previous release's wallet FUND_IN and the data shows it spendable, on every lane: the
    update must keep a balance and a history (as v1). REL_FUNDS only adds the candidate's legs. A lane
    seed's wallet below TOPUP_BELOW gets the top-up in the same payment."""
    lane.address = address
    d0 = _digest(lane, "previous")
    start = _spendable(d0) or 0
    amount, top = p_pays(start, seeded(lane))
    _, tx = _pay(lane, address, amount, "previous", "fund the previous release")
    lane.fund_tx, lane.inflow = tx, D(FUND_IN)
    _funded(lane, amount, tx)
    d = wait_spendable(lane, "previous", start + _nano(amount), "fund spendable")
    _funded_at(lane, tx, d)
    why = ""
    if top:
        why = " (%s this run's inflow and a %s top-up that stays in the lane: spendable was %s, below %s; capped by the %s per-send cap)" % (
            FUND_IN, top, num(start), TOPUP_BELOW, CAP_SEND)
    lane.details["fund"] = "P -> %s %s EPIC%s: incoming confirmed, spendable %s (wallet data)" % (
        short(address), amount, why, num(_spendable(d)))
    lane.log(lane.details["fund"])


# ---- reading after the update -----------------------------------------------------------------------

def settle(lane, before, wait_s=150):
    """The candidate may still be refreshing (or migrating): the wallet's data is read again, up to [wait_s],
    until the balance and every transaction from before are there. The first read is kept as evidence."""
    a = _digest(lane, "candidate")
    first_balance, first_txs = a.get("balance"), a.get("txs")
    t0 = time.time()
    while time.time() - t0 < wait_s and not _same_state(before, a):
        time.sleep(15)
        try:
            a = _digest(lane, "candidate")
        except HarnessFault as e:
            lane.log("settle: %s" % e.what)
    a["first_balance"], a["first_txs"] = first_balance, first_txs
    a["settled_after_s"] = int(time.time() - t0)
    _save(lane, "digest-previous.json", before)
    _save(lane, "digest-candidate.json", a)
    return a


def _same_state(b, a):
    if (a.get("balance") or {}).get("total") != (b.get("balance") or {}).get("total"):
        return False
    return not match_txs(_txs(b), _txs(a))[1]


# ---- compare ----------------------------------------------------------------------------------------

def compare(lane, before, after, snap):
    b_list, b_hash = snap if snap else ([], {})
    _wallet_opens(lane, before, after)
    _balance(lane, before, after)
    _history(lane, before, after)
    _servers(lane, "node", before, after)
    _servers(lane, "relay", before, after)
    _settings(lane, before, after)
    _data_folder(lane, before, after, b_list)
    _migration(lane, before, after, b_list, b_hash)


def _how(a):
    if a.get("source") == "cli":
        return " (the encrypted store read through the LEPIC CLI at the candidate's pin; outputs by commitment and counterparties are not in its reports)"
    return " (from the wallet's own database, %s)" % (a.get("store_dir") or "?")


def _wallet_opens(lane, b, a):
    w0, w1 = b.get("wallet"), a.get("wallet")
    if not w0 and not w1 and not b.get("wallet_ids") and a.get("source") != "none":
        # the phone app has one wallet and no wallets.json: its store, read after the update, is the wallet
        lane.ok("wallet_opens", "the app's one wallet (%s) opened with the candidate; its store was read (%s)" % (
            a.get("store_dir"), a["source"]))
    elif not w1 or a.get("source") == "none":
        lane.fail("wallet_opens", "the wallet's data shows no wallet after the update (wallets.json: %s, database: %s)" % (
            w1 and w1.get("id"), a.get("source")))
    elif w0 and w0.get("id") != w1.get("id"):
        lane.fail("wallet_opens", "a different wallet is in use: %s, was %s" % (w1.get("id"), w0.get("id")))
    else:
        lane.ok("wallet_opens", "wallet %s (%r) opened with the candidate; its store was read (%s)" % (w1.get("id"), w1.get("label"), a["source"]))


def _balance(lane, b, a):
    b0, b1 = b.get("balance"), a.get("balance")
    how = _how(a)
    if b0 is None or b1 is None:
        lane.fail("balance_kept", "the balance could not be read %s (no wallet database was read)" % (
            "before the update" if b0 is None else "after the update"))
        return
    keep0 = sorted((o["commit"], o["amount"]) for o in (b.get("outputs") or []) if o["status"] == "unspent")
    keep1 = sorted((o["commit"], o["amount"]) for o in (a.get("outputs") or []) if o["status"] == "unspent")
    if b.get("store_dir") and a.get("store_dir") and b["store_dir"] != a["store_dir"]:
        lane.fail("balance_kept", "the candidate keeps the wallet in another folder: %s, was %s" % (a["store_dir"], b["store_dir"]))
    elif b1["total"] == b0["total"] and a.get("outputs") is None:
        lane.ok("balance_kept", "total %s EPIC before and after%s" % (num(b0["total"]), how))
    elif b1["total"] == b0["total"] and keep0 == keep1:
        lane.ok("balance_kept", "total %s EPIC before and after, the same %d unspent outputs%s" % (num(b0["total"]), len(keep0), how))
    else:
        lane.fail("balance_kept", "before %s, after %s (read for %d s); unspent outputs %d -> %d%s" % (
            fmt(b0), fmt(b1), a.get("settled_after_s", 0), len(keep0), len(keep1), how))


def _history(lane, b, a):
    """Every transaction from before is there after (a different one each); those with a counterparty
    keep it. A restored wallet's scanned transactions have neither slate nor counterparty, so the sender
    that must be recorded is this run's payment from P's (lane.fund_tx), else any."""
    t0, t1 = _txs(b), _txs(a)
    how = _how(a)
    pairs, missing = match_txs(t0, t1)
    cp_read = a.get("counterparties_read", True)
    lost = [] if not cp_read else [t for t, x in pairs if t.get("counterparty") and x.get("counterparty") != t["counterparty"]]
    fund = getattr(lane, "fund_tx", None)
    ours = [t for t in t0 if fund and fund.get("slate") and t.get("slate") == fund["slate"]]
    senders = sum(1 for t in (ours or t0) if t.get("counterparty"))
    scanned = sum(1 for t in t0 if not t.get("slate") and not t.get("counterparty"))
    note = "; %d of them from the restore's scan, without slate or counterparty" % scanned if scanned else ""
    if b.get("txs") is None or a.get("txs") is None:
        lane.fail("history_kept", "the transactions could not be read %s" % ("before the update" if b.get("txs") is None else "after the update"))
    elif missing:
        lane.fail("history_kept", "%d of %d transactions missing after the update: %s" % (len(missing), len(t0), txs_text(missing)))
    elif lost:
        lane.fail("history_kept", "transactions kept but who paid or was paid lost: %s" % txs_text(lost))
    elif not t0:
        lane.fail("history_kept", "the wallet has no transaction before the update: nothing to compare")
    elif cp_read and not senders:
        lane.fail("history_kept", "%s has no sender recorded: nothing to compare" % (
            "this run's payment from P" if ours else "the payment before the update"))
    elif not cp_read:
        lane.ok("history_kept", "%d transactions kept by slate, direction, state and amounts (%s); who paid or was paid NOT compared "
                "(the LEPIC CLI does not report counterparties)%s%s" % (len(t0), txs_text(t0), note, how))
    else:
        lane.ok("history_kept", "%d transactions kept with their counterparties (%s)%s%s" % (len(t0), txs_text(t0), note, how))


def setup_took(lane, b):
    """The previous release's files show the servers the driver set (read before the update): a choice
    that did not take is the driver's fault, never counted against the update."""
    bad = []
    for kind, key, use in (("node", "nodes", "node_in_use"), ("relay", "relays", "relay_in_use")):
        sv = b.get("servers") or {}
        custom = host(getattr(lane.p, "custom_%s" % kind, "") or "")
        chosen = host(getattr(lane.p, kind, "") or "")
        listed = [host(x) for x in sv.get(key) or []]
        if not listed:
            continue  # not readable before the update: the check itself says so
        if custom and custom not in listed:
            bad.append("the added %s %s is not in the previous release's list" % (kind, custom))
        if chosen and host(sv.get(use) or "") != chosen:
            bad.append("the %s in use is %s, the driver chose %s" % (kind, host(sv.get(use) or "") or "none", chosen))
    if bad:
        from .faults import HarnessFault
        raise HarnessFault("digest-before", "the driver's setup did not take: %s" % "; ".join(bad))
    lane.log("setup confirmed in the previous release's files: node and Epicbox in use and added as set")


def _servers(lane, kind, b, a):
    check = "custom_nodes_kept" if kind == "node" else "custom_relays_kept"
    custom = host(getattr(lane.p, "custom_node" if kind == "node" else "custom_relay", ""))
    chosen = host(getattr(lane.p, "node" if kind == "node" else "relay", ""))
    lb, la = b["servers"], a["servers"]
    key = "nodes" if kind == "node" else "relays"
    use = "node_in_use" if kind == "node" else "relay_in_use"
    before_list = [host(x) for x in lb[key]]
    before_use = host(lb[use])
    own = [host(x) for x in lb[key + "_added"]]
    after_list = [host(x) for x in la[key]]
    after_use = after_list[0] if (a.get("settings_toml") is not None and after_list) else host(la[use])
    src = "settings.toml (first entry in use)" if a.get("settings_toml") is not None else "the desk store"
    problems = []
    if not after_list and not before_list:
        problems.append("no %s list could be read before or after the update" % kind)
    else:
        if custom not in before_list:
            problems.append("the stand-in %s %s was not in the previous list" % (kind, custom))
        elif custom not in after_list:
            problems.append("added %s %s gone" % (kind, custom))
        if after_use != chosen:
            problems.append("in use was %s, now %s" % (before_use, after_use))
        lost = [x for x in own if x not in after_list and x != custom]
        if lost:
            problems.append("own entries gone: %s" % ", ".join(lost))
    since = (b.get("log") or {}).get("lines", 0)
    picks = [t for i, t in ((a.get("log") or {}).get("first_start") or []) if i >= since and "first run" in t]
    if picks:
        problems.append("first run's server pick ran on the existing install (wfe.log: %s)" % "; ".join(picks[:2]))
    extra = ""
    if kind == "relay":
        if a.get("log") is None:
            extra = "; the relay the candidate's listener subscribed to NOT read (no wfe.log)"
        else:
            subs = [r for i, r in a["log"]["subscribed"] if i >= since]
            extra = "; the candidate's listener subscribed to %s (wfe.log)" % (", ".join(sorted(set(subs))) or "nothing")
    if problems:
        lane.fail(check, "; ".join(problems) + "; after (%s): %s%s" % (src, ", ".join(after_list), extra))
    else:
        lane.ok(check, "%s in use and %s kept; list %s (%s)%s" % (chosen, custom, ", ".join(after_list), src, extra))


FIELDS = (("theme", "theme"), ("technical_details", "Technical details"), ("label", "label"), ("confirmations", "confirmations"))


def _same(k, x, y):
    return str(x).lower() == str(y).lower() if k == "theme" else x == y


def _ui_read(lane, s0, s1):
    """The confirmations count the app's Settings page showed (lane._ui_settings) in place of a value the
    files do not give (the encrypted store's, not in the LEPIC CLI's reports); and what setting it in the
    candidate did, when it went wrong."""
    ui = getattr(lane, "ui_settings", None) or {}
    used = []
    for s, when in ((s0, "before"), (s1, "after")):
        v = (ui.get(when) or {}).get("confirmations")
        if s.get("confirmations") is None and v is not None:
            s["confirmations"] = v
            used.append(when)
    st, wrong = ui.get("set"), None
    if st and (st["read"] != st["to"] or st["back"] != st["from"] or st["refused"]):
        wrong = "confirmations set in the candidate's Settings › Payments did not keep: %d → %d read back %s, back to %d read back %s%s" % (
            st["from"], st["to"], st["read"], st["from"], st["back"], "; the app said it was not saved" if st["refused"] else "")
    note = ""
    if used:
        note = "; confirmations read on the app's Settings › Payments page %s the update (the encrypted store's value is not in the LEPIC CLI's reports)" % " and ".join(used)
    if st and not wrong:
        note += "; in the candidate set to %d and back to %d through the stepper, each read back on the page opened again" % (st["to"], st["from"])
    return note, wrong


def _settings(lane, b, a):
    s0, s1 = dict(b["settings"]), dict(a["settings"])
    ui_note, ui_wrong = _ui_read(lane, s0, s1)
    u0, u1 = b.get("unread") or {}, a.get("unread") or {}
    want = getattr(lane, "want_settings", None) or WANT_SETTINGS
    state_label = getattr(lane, "mode", None) == "state"
    diff, unread = {}, []
    for k, name in FIELDS:
        if s0.get(k) is None or s1.get(k) is None:
            unread.append("%s (%s)" % (name, "before: %s" % u0.get(k, "not stored") if s0.get(k) is None else "after: %s" % u1.get(k, "not stored")))
        elif not _same(k, s0[k], s1[k]):
            diff[k] = (s0[k], s1[k])
    unset = {k: s0.get(k) for k in ("theme", "technical_details", "confirmations", "label")
             if s0.get(k) is not None and k in want and not (k == "label" and state_label) and not _same(k, s0[k], want[k])}
    src = " (%s%s)" % (a.get("settings_source") or "desk store desk.settings, wallets.json label, the wallet database's minimum confirmations", ui_note)
    note = "; NOT read: %s" % "; ".join(unread) if unread else ""
    lv, why = facts.level_after_update(a.get("level"), before=b.get("level"))
    if lv is None and facts.LEVELS_BUILT:
        if a.get("level") is None and "level" in u1:
            why += "; NOT read: %s" % u1["level"]
        else:
            lv, why = False, "no wallet level stored after the update, though the candidate has levels: an existing install must be stored as level 3"
    since = (b.get("log") or {}).get("lines", 0)
    firsts = [t for i, t in ((a.get("log") or {}).get("first_start") or []) if i >= since]
    if firsts:
        lv, why = False, "%s; the first-start step ran on the existing install (wfe.log: %s)" % (why, "; ".join(firsts[:3]))
    lane.details["level"] = why + " (desk store %s, wfe.log)" % facts.LEVEL_KEY
    if all(s1.get(k) is None for k, _ in FIELDS):
        lane.fail("settings_kept", "no setting could be read after the update%s" % note)
    elif unset and "settings_kept" in lane.required:  # the driver's setup did not take: nothing to compare
        raise HarnessFault("digest-after", "the test could not set them on the previous release: %s" % unset)
    elif diff:
        lane.fail("settings_kept", "changed by the update (before, after): %s%s%s" % (diff, src, note))
    elif ui_wrong:
        lane.fail("settings_kept", "%s%s%s" % (ui_wrong, src, note))
    elif lv is False:
        lane.fail("settings_kept", "%s; settings otherwise as before%s" % (why, note))
    else:
        read = ["theme %s" % s1["theme"] if s1.get("theme") is not None else None,
                "label %r" % s1["label"] if s1.get("label") is not None else None,
                "%s confirmations" % s1["confirmations"] if s1.get("confirmations") is not None else None,
                ("Technical details %s" % ("on" if s1["technical_details"] else "off")) if s1.get("technical_details") is not None else None]
        lane.ok("settings_kept", "%s%s%s" % (", ".join(x for x in read if x), src, note))


def _data_folder(lane, b, a, b_list):
    migrate, _ = migrating()
    after = a.get("files") or []
    gone = [f for f in migration.norm(b_list) if f not in after
            and not (migrate and os.path.basename(f).startswith(facts.STORE_PLAIN))]
    lane.details["data_folder"] = ("all %d files of the previous data folder still there; %d new" % (
        len(b_list), len(set(after) - set(migration.norm(b_list))))) if not gone else (
        "files gone after the update: %s" % ", ".join(gone[:10]))
    lane.log("data folder: %s" % lane.details["data_folder"])


def _lan_before(lane, b_hash):
    t = getattr(lane.p, "lan_before", None)
    if t is not None:
        return t
    node = getattr(lane.p, "custom_node", None)
    if node and facts.LAN_NODES_FILE in b_hash:
        t = seed.lan_nodes_json(["http://%s" % node])
        if wd.sha256(t.encode("utf-8")) == b_hash[facts.LAN_NODES_FILE]:
            return t
    return None


def _settings_text(toml):
    if toml is None:
        return None
    q = lambda xs: "[%s]" % ", ".join(json.dumps(x) for x in xs)  # noqa: E731
    return "[node]\nservers = %s\nplain_http = %s\n" % (q(toml.get("node") or []), q(toml.get("plain_http") or []))


def _migration(lane, b, a, b_list, b_hash):
    migrate, seed_files = migrating()
    if not migrate:
        for c in MIGRATION_CHECKS:
            lane.ok(c, "not applicable: candidate %s keeps the plain database" % _cand_version())
        return
    a_list, a_hash = a.get("files") or [], a.get("hashes") or {}
    r = migration.store_files(b_list, a_list)
    (lane.ok if r[0] else lane.fail)("store_encrypted", r[1])
    if not seed_files:
        for c in MIGRATION_CHECKS[1:]:
            lane.ok(c, "not applicable: the previous release already encrypts (nothing plain to carry over)")
        return
    r = migration.app_files(b_list, b_hash, a_list, a_hash, a.get("wallet_ids") or [])
    (lane.ok if r[0] else lane.fail)("app_files_kept", r[1])
    r = migration.lan_nodes(_lan_before(lane, b_hash), b_hash.get(facts.LAN_NODES_FILE), a_hash.get(facts.LAN_NODES_FILE),
                            _settings_text(a.get("settings_toml")))
    (lane.ok if r[0] else lane.fail)("lan_nodes_kept", r[1])
    book, notes = a.get("address_book"), a.get("notes")
    shown_c = None if book is None else any(c.get("name") == seed.CONTACT["name"] for c in book["contacts"])
    shown_n = None if notes is None else seed.NOTE in notes
    r = migration.contact_note(seed.CONTACT["name"], seed.NOTE, b_hash, a_hash, shown_c, shown_n,
                               "read from the app's plain files, byte-identical beside their sealed copies; the sealed copies' "
                               "contents are not read (only the app opens them)")
    (lane.ok if r[0] else lane.fail)("contact_note_kept", r[1])


# ---- payments on the candidate ----------------------------------------------------------------------

def funds_legs(lane, after):
    """Receive on the candidate (P sends FUND_AFTER), then back to P through the recipe's Send: a lane
    seed's wallet this run's inflow (lane.inflow), any other wallet everything."""
    res = lane.results
    if after is None or not res.get("wallet_opens") or not res.get("balance_kept"):
        why = ("the wallet did not open with the candidate" if after is None or not res.get("wallet_opens")
               else "the candidate does not keep the wallet's balance")
        if lane.funds:
            _set(lane, RECEIVE, False, "not run: %s" % why)
            _set(lane, SEND, False, "not run: %s" % why)
        lane.log("funds left in the test wallet: %s (data folder and password kept)" % why)
        return
    address = after.get("address") or getattr(lane, "address", None)
    if lane.funds:
        start = _spendable(after) or 0
        try:
            _, tx = _pay(lane, address, FUND_AFTER, "candidate", "receive with the candidate",
                         fallback=_over_tor(lane, "the receive"))
            _funded(lane, FUND_AFTER, tx)
            lane.inflow = getattr(lane, "inflow", D(FUND_IN)) + D(FUND_AFTER)
            d = wait_spendable(lane, "candidate", start + _nano(FUND_AFTER), "receive spendable")
            _funded_at(lane, tx, d)
            _set(lane, RECEIVE, True, "P -> %s %s EPIC via Epicbox: incoming %s EPIC confirmed (wallet data); spendable %s" % (
                short(address), FUND_AFTER, num(tx["credited"]), num(_spendable(d))))
        except ProductFault as e:  # a HarnessFault (P, the display) is the lane's, not a false check
            _set(lane, RECEIVE, False, e.what)
    _send_back(lane, SEND if lane.funds else None)
    if tor_on(lane):
        _tor_proof(lane)


# ---- over Tor (the Tor lanes, core/lane.py's tor-on phase) -------------------------------------------

def tor_on(lane):
    """True while the candidate's legs run over Tor (lane.tor, set by the tor-on phase)."""
    return bool((getattr(lane, "tor", None) or {}).get("on"))


def tor_failed(lane, why, cause):
    """Tor, or a leg over it, failed: tor_payment_ok false with [why] and its cause class (the check is
    never required), Tor off; the legs go on in the clear and gate as ever."""
    lane.fail(TOR, "%s [%s]" % (why, cause))
    info = lane.details.setdefault("tor", {})
    info["cause_class"] = cause
    lane.tor = {"on": False}
    try:
        lane.ui.tor_off()
        info["off"] = "Normal: the rest in the clear"
    except HarnessGone:
        raise
    except Fault as e:
        lane.log("Tor off: %s" % e.line())
        info["off"] = "not turned off: %s" % e.line()


def _over_tor(lane, leg):
    """The fallback of a leg (see _again) while Tor is on, else None. The cause class: INFRA when the
    app no longer shows Tor connected, else PRODUCT (Tor up, the payment did not go)."""
    if not tor_on(lane):
        return None

    def fallback(why):
        try:
            state = lane.ui.tor_status()
        except HarnessGone:
            raise
        except Fault as e:
            state = {"up": False, "read": e.line()}
        lane.details.setdefault("tor", {})["at_failure"] = state
        lane.log("%s over Tor: %s (Tor %s); Tor off, the leg goes on in the clear" % (leg, why, state))
        tor_failed(lane, "%s over Tor: %s" % (leg, why), "PRODUCT" if state.get("up") else "INFRA")
    return fallback


def _tor_proof(lane):
    """Both legs ended over Tor: tor_payment_ok from the app's own Tor state after them and the app log's
    Tor lines (no Tor failure while the legs ran)."""
    info = lane.details.setdefault("tor", {})
    try:
        state = lane.ui.tor_status()
    except HarnessGone:
        raise
    except Fault as e:
        state = {"up": False, "read": e.line()}
    info["after_legs"] = state
    log = ((lane.last_digest or {}).get("log") or {})
    lines = [l for i, l in log.get("tor") or [] if lane.split is None or i >= lane.split]
    info["log"] = lines[-12:]
    bad = [l for l in lines if re.search(r"tor(?::)? (?:failed|ended|stop)", l, re.I)]
    legs = [lane.results.get(_names(lane, pair)[0]) for pair in (RECEIVE, SEND)]
    if not all(legs):
        return tor_failed(lane, "the legs over Tor did not both pass (receive %s, send %s)" % tuple(legs), "PRODUCT")
    if not state.get("up"):
        return tor_failed(lane, "the app no longer shows Tor connected after the legs (%s)" % state, "INFRA")
    if bad:
        return tor_failed(lane, "the app log shows Tor stopping during the legs: %s" % bad[-1], "INFRA")
    lane.ok(TOR, "receive and send in Connection mode Tor only; after them the app shows %s; app log Tor lines: %d, none failed" % (
        state, len(lines)))


def _send_back(lane, pair):
    if not lane.funds and os.environ.get("REL_KEEP_FUNDS") == "1":
        lane.log("funds kept in the test wallet (REL_KEEP_FUNDS=1)")
        return
    amount = getattr(lane, "inflow", None) if seeded(lane) else None
    try:
        d0 = wait_spendable(lane, "candidate", _nano(amount) if amount else _nano("0.001"), "before sending back", 900)
        ok, why = _send_to_p(lane, d0, amount, fallback=_over_tor(lane, "the send"))
        how = "an amount of %s EPIC (this run's inflow; the rest stays in the lane seed's wallet)" % amount if amount else "Max"
        if pair:
            _set(lane, pair, ok, ("to P via Epicbox, the Send page with %s: %s" % (how, why)) if ok else why)
        else:
            lane.log("returned to P: %s" % why)
    except ProductFault as e:
        if pair:
            _set(lane, pair, False, "%s: %s" % (e.kind, e.what))
        else:
            lane.log("could not return the funds: %s" % e.what)


def _send_to_p(lane, d0, amount=None, fallback=None):
    """[amount] (EPIC, a Decimal) to P through the recipe's Send page, or everything (Max) when None; True
    when the data shows the payment posted and confirmed (and of that amount). [fallback](why) is called
    once at the first miss (see _again): a Send that did not go is tried again, a payment waited for."""
    n0 = len([t for t in _txs(d0) if t["direction"] == "outgoing"])
    avail = _spendable(d0) or 0
    a = D(str(amount)) if amount is not None else D(avail) / NANO
    if a > CAP_SEND:
        return False, "%s %s over the per-send cap %s" % ("amount" if amount is not None else "available", num(_nano(a)), CAP_SEND)
    _budget(lane, a)
    p = _p_ready(lane)
    with p.exchange("send back to P"):
        _unlock(lane)
        if not p.start_listener():
            raise HarnessFault("send", "P's listener did not start (3 tries)")
        lane.send_pending = a  # until the data shows it confirmed: the lane seed's record counts it gone
        ok, why = lane.ui.send(P_ADDR, format(a, "f") if amount is not None else None)
        if not ok and fallback:
            fallback("the Send did not go through: %s" % why)
            fallback = None
            ok, why = lane.ui.send(P_ADDR, format(a, "f") if amount is not None else None)
        if not ok:
            lane.send_pending = None
            return False, "the Send did not go through: %s" % why
        end = time.time() + 900
        last, posted = None, False
        while not posted:
            while time.time() < end:
                out = [t for t in _txs(_digest(lane, "candidate")) if t["direction"] == "outgoing"][n0:]
                state = [(t["state"], num(t["debited"]), num(t["fee"] or 0)) for t in out]
                if state != last:
                    lane.log("send back: wallet records %s" % state)
                    last = state
                if out and out[-1]["state"] in ("posted", "confirmed"):
                    posted = True  # P answered: the confirmation is waited for below
                    break
                time.sleep(POLL_S)
            if not posted:
                if fallback is None:
                    return False, "not posted in 15 min (wallet records %s)" % last
                fallback("not posted in 15 min (wallet records %s)" % last)
                fallback, end = None, time.time() + 900
    while fallback is not None or time.time() < end:
        if time.time() >= end:
            fallback("posted, not confirmed in 15 min (wallet records %s)" % last)
            fallback, end = None, time.time() + 900
        out = [t for t in _txs(_digest(lane, "candidate")) if t["direction"] == "outgoing"][n0:]
        if out and out[-1]["state"] == "confirmed":
            t = out[-1]
            lane.send_pending = None
            sent = (t["debited"] or 0) - (t["credited"] or 0) - (t["fee"] or 0)
            if amount is not None and sent != _nano(a):
                return False, "outgoing %s EPIC (fee %s) to P confirmed, the Send page was given %s EPIC (wallet data)" % (
                    num(sent), num(t["fee"] or 0), a)
            return True, "outgoing %s EPIC (fee %s) to P, posted and confirmed (wallet data)" % (num(sent), num(t["fee"] or 0))
        time.sleep(POLL_S)
    return False, "posted, not confirmed in 15 min (wallet records %s)" % last


# ---- public -----------------------------------------------------------------------------------------

def public(d):
    """The digest without anything secret: addresses shortened, no counterparty addresses, no hashes, no
    contact addresses. Amounts in nanoEPIC."""
    if not d:
        return d
    keep = ("source", "store_dir", "balance", "balance_how", "tip", "servers", "settings_toml", "settings", "unread", "level",
            "wallet_ids", "migrate", "read_at", "counterparties_read", "settled_after_s")
    out = {k: d[k] for k in keep if k in d}
    w = d.get("wallet") or {}
    out["wallet"] = {"id": w.get("id"), "label": w.get("label")} if w else None
    out["address"] = short(d.get("address")) if d.get("address") else None
    out["txs"] = [{k: t.get(k) for k in ("id", "direction", "state", "transport", "credited", "debited", "fee")}
                  | {"slate": (t.get("slate") or "")[:8] or None} for t in _txs(d)] if d.get("txs") is not None else None
    out["address_book"] = {"contacts": [c.get("name") for c in (d.get("address_book") or {}).get("contacts", [])]} if d.get("address_book") else None
    out["files"] = len(d.get("files") or [])
    return out
