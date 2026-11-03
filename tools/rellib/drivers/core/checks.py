# SPDX-License-Identifier: Apache-2.0
"""The checks of the G4 update-trust lanes, the same on every platform, judged on the wallet's own data
(core/walletdata.py digests) and never on a screen.

lane.py calls, in this order:
    fund_before(lane, address)      P pays the previous release's wallet; waits until the data shows it spendable
    settle(lane, before) -> after   the candidate's data, read again until it stops moving
    compare(lane, before, after, snap)   lane.ok / lane.fail per check
    funds_legs(lane, after)         receive on the candidate, send everything back to P through the UI
    public(digest)                  the digest without anything secret (it goes into a saved state)

A check that cannot be read says so in its detail ("NOT read: ..."); it is never passed by saying nothing.
The wording of the details follows windows/trust.py, which this replaces.
"""
import datetime
import decimal
import json
import os
import sys
import time

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import facts  # noqa: E402
import migration  # noqa: E402
import seed  # noqa: E402
from . import walletdata as wd  # noqa: E402
from .faults import HarnessFault, ProductFault  # noqa: E402

D = decimal.Decimal
NANO = wd.NANO
FUND_IN = "0.03"
FUND_AFTER = "0.01"
CAP_SEND = D("0.05")
CAP_JOB = D("1")
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
        return lane.p.digest(tag, lane.secrets)
    except wd.ReadError as e:
        raise HarnessFault("digest-" + tag, "the wallet's data could not be read: %s" % e)


def same_tx(t0, t1):
    """The same payment: its slate, else direction and amounts (states move on with confirmations)."""
    if t0.get("slate") and t1.get("slate"):
        return t0["slate"] == t1["slate"]
    return (t0["direction"], t0["credited"], t0["debited"]) == (t1["direction"], t1["credited"], t1["debited"])


def txs_text(ts):
    return "; ".join("%s %s EPIC %s, %s" % (t["direction"], num(t["credited"] or t["debited"]), t["state"],
                                             short(t.get("counterparty")) if t.get("counterparty") else "no counterparty")
                     for t in ts)


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


def _pay(lane, address, amount, tag, what, count_dir="incoming"):
    """P sends [amount] to [address]; the wallet's data must show the new incoming transaction confirmed
    (P's confirmed payment is the proof of receipt). -> (txs before, the new transaction)."""
    p = _p_ready(lane)
    _budget(lane, amount)
    d0 = _digest(lane, tag)
    n0 = len([t for t in _txs(d0) if t["direction"] == count_dir])
    with p.exchange(what):
        _unlock(lane)
        if not p.start_listener():
            raise HarnessFault("fund", "P's listener did not start (3 tries)")
        relay = host(getattr(lane.p, "relay", "") or "")
        # the wallet listens on the relay in use only: a bare address would go to P's own default
        full = address if "@" in address or not relay else "%s@%s" % (address, relay)
        ok, out = p.send(full, amount)
        lane.log("P -> %s %s: %s (%s)" % (short(address), amount, "sent" if ok else "FAILED", out))
        if not ok:
            raise HarnessFault("fund", "P send failed: %s" % out)
        end = time.time() + 900
        last, posted = None, False
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
            raise (HarnessFault if tag == "previous" else ProductFault)(what, "P sent %s EPIC and the wallet's data shows no incoming transaction in 15 min (wallet records %s)" % (amount, last))
    while time.time() < end:
        d = _digest(lane, tag)
        new = [t for t in _txs(d) if t["direction"] == count_dir][n0:]
        if new and new[-1]["state"] == "confirmed":
            return d0, new[-1]
        time.sleep(POLL_S)
    raise (HarnessFault if tag == "previous" else ProductFault)(what, "posted by P, not confirmed in the wallet's data in 15 min (wallet records %s)" % last)


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


def fund_before(lane, address):
    """P pays the previous release's wallet FUND_IN and the data shows it spendable, on every lane: the
    update must keep a balance and a history (as v1). REL_FUNDS only adds the candidate's legs."""
    lane.address = address
    d0 = _digest(lane, "previous")
    start = _spendable(d0) or 0
    _, tx = _pay(lane, address, FUND_IN, "previous", "fund the previous release")
    d = wait_spendable(lane, "previous", start + _nano(FUND_IN), "fund spendable")
    lane.details["fund"] = "P -> %s %s EPIC: incoming confirmed, spendable %s (wallet data)" % (
        short(address), FUND_IN, num(_spendable(d)))
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
    return all(any(same_tx(t, x) for x in _txs(a)) for t in _txs(b))


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
    t0, t1 = _txs(b), _txs(a)
    how = _how(a)
    missing = [t for t in t0 if not any(same_tx(t, x) for x in t1)]
    cp_read = a.get("counterparties_read", True)
    lost = [] if not cp_read else [t for t in t0 if t not in missing and t.get("counterparty")
                                  and not any(same_tx(t, x) and x.get("counterparty") == t["counterparty"] for x in t1)]
    senders = sum(1 for t in t0 if t.get("counterparty"))
    if b.get("txs") is None or a.get("txs") is None:
        lane.fail("history_kept", "the transactions could not be read %s" % ("before the update" if b.get("txs") is None else "after the update"))
    elif missing:
        lane.fail("history_kept", "%d of %d transactions missing after the update: %s" % (len(missing), len(t0), txs_text(missing)))
    elif lost:
        lane.fail("history_kept", "transactions kept but who paid or was paid lost: %s" % txs_text(lost))
    elif not t0:
        lane.fail("history_kept", "the wallet has no transaction before the update: nothing to compare")
    elif cp_read and not senders:
        lane.fail("history_kept", "the payment before the update has no sender recorded: nothing to compare")
    elif not cp_read:
        lane.ok("history_kept", "%d transactions kept by slate, direction, state and amounts (%s); who paid or was paid NOT compared "
                "(the LEPIC CLI does not report counterparties)%s" % (len(t0), txs_text(t0), how))
    else:
        lane.ok("history_kept", "%d transactions kept with their counterparties (%s)%s" % (len(t0), txs_text(t0), how))


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


def _settings(lane, b, a):
    s0, s1 = b["settings"], a["settings"]
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
    src = " (desk store desk.settings, wallets.json label, the wallet database's minimum confirmations)"
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
    """Receive on the candidate (P sends FUND_AFTER), then everything back to P through the recipe's Send."""
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
            _, tx = _pay(lane, address, FUND_AFTER, "candidate", "receive with the candidate")
            d = wait_spendable(lane, "candidate", start + _nano(FUND_AFTER), "receive spendable")
            _set(lane, RECEIVE, True, "P -> %s %s EPIC via Epicbox: incoming %s EPIC confirmed (wallet data); spendable %s" % (
                short(address), FUND_AFTER, num(tx["credited"]), num(_spendable(d))))
        except ProductFault as e:  # a HarnessFault (P, the display) is the lane's, not a false check
            _set(lane, RECEIVE, False, e.what)
    _send_back(lane, SEND if lane.funds else None)


def _send_back(lane, pair):
    if not lane.funds and os.environ.get("REL_KEEP_FUNDS") == "1":
        lane.log("funds kept in the test wallet (REL_KEEP_FUNDS=1)")
        return
    try:
        d0 = wait_spendable(lane, "candidate", _nano("0.001"), "before sending back", 900)
        ok, why = _send_to_p(lane, d0)
        if pair:
            _set(lane, pair, ok, ("to P via Epicbox, the Send page with Max: %s" % why) if ok else why)
        else:
            lane.log("returned to P: %s" % why)
    except ProductFault as e:
        if pair:
            _set(lane, pair, False, "%s: %s" % (e.kind, e.what))
        else:
            lane.log("could not return the funds: %s" % e.what)


def _send_to_p(lane, d0):
    """Everything (Max) to P through the recipe; True when the data shows the payment posted and confirmed."""
    n0 = len([t for t in _txs(d0) if t["direction"] == "outgoing"])
    avail = _spendable(d0) or 0
    if D(avail) / NANO > CAP_SEND:
        return False, "available %s over the per-send cap %s" % (num(avail), CAP_SEND)
    _budget(lane, D(avail) / NANO)
    p = _p_ready(lane)
    with p.exchange("send back to P"):
        _unlock(lane)
        if not p.start_listener():
            raise HarnessFault("send", "P's listener did not start (3 tries)")
        ok, why = lane.ui.send(P_ADDR, None)
        if not ok:
            return False, "the Send did not go through: %s" % why
        end = time.time() + 900
        last = None
        while time.time() < end:
            out = [t for t in _txs(_digest(lane, "candidate")) if t["direction"] == "outgoing"][n0:]
            state = [(t["state"], num(t["debited"]), num(t["fee"] or 0)) for t in out]
            if state != last:
                lane.log("send back: wallet records %s" % state)
                last = state
            if out and out[-1]["state"] in ("posted", "confirmed"):
                break  # P answered: the confirmation is waited for below
            time.sleep(POLL_S)
        else:
            return False, "not posted in 15 min (wallet records %s)" % last
    while time.time() < end:
        out = [t for t in _txs(_digest(lane, "candidate")) if t["direction"] == "outgoing"][n0:]
        if out and out[-1]["state"] == "confirmed":
            t = out[-1]
            return True, "outgoing %s EPIC (fee %s) to P, posted and confirmed (wallet data)" % (
                num((t["debited"] or 0) - (t["credited"] or 0) - (t["fee"] or 0)), num(t["fee"] or 0))
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
