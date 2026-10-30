#!/usr/bin/env python3
"""Update trust on Android (gate G4): a user on the previous release updates to the candidate and
keeps everything. Called by ../trust-android.sh, which resolves the APKs, starts the emulator and
passes everything in the environment (see that script for the contract).

    python3 -I trust.py run       the whole flow; writes $REL_OUT/proof.json; exit 0/1/2
    python3 -I trust.py <step>    one step on the running app, for debugging:
                                  digest | unlock | servers | settings | history | phrase-check

Flow: fresh install of the previous APK → restore the test wallet from its phrase (first run:
create it, keep its phrase, fund it from P) → typed-in node REL_NODE and relay REL_EPICBOX in
use → change stored, visible settings → history shows a payment → digest → `adb install -r`
candidate → launch, unlock → digest again and compare → with REL_FUNDS=1 a send to P and a
receive from P through Epicbox on the candidate.

Secrets (the phrase, the PIN) live in mode-600 files in REL_TRUST_STATE (default
~/.config/btlabs/rel-trust-android); they are never printed, logged or screenshotted.
"""
import json, os, re, secrets, sys, time, traceback
from decimal import Decimal, InvalidOperation

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ph  # noqa: E402
from ph import PKG, adb, find, key, launch, mask, nodes, secret_words, tap, tap_xy, type_text, wait  # noqa: E402

E = os.environ.get
S = E("REL_ANDROID_SERIAL", "")
OUT = E("REL_OUT", ".")
STATE = os.path.expanduser(E("REL_TRUST_STATE", "~/.config/btlabs/rel-trust-android"))
NODE = E("REL_NODE", "")              # https://host[:port]
EPICBOX = E("REL_EPICBOX", "")        # host[:port]
FUNDS = E("REL_FUNDS", "1") == "1"
CONFIRMATIONS = int(E("REL_TRUST_CONFIRMATIONS", "4"))  # the stored setting the test moves to
THEME = E("REL_TRUST_THEME", "Dark")
RECEIVE_AMOUNT = E("REL_TRUST_RECEIVE", "0.02")   # P → wallet
SEND_AMOUNT = E("REL_TRUST_SEND", "0.01")         # wallet → P
FUND_AMOUNT = E("REL_TRUST_FUND", "0.05")         # P → a new (or empty) test wallet
PREP_AMOUNT = E("REL_TRUST_PREP", "0.01")         # P → the restored wallet, for its history
CHECKS = ("wallet_opens", "balance_kept", "history_kept", "custom_nodes_kept",
          "custom_relays_kept", "settings_kept", "send_ok", "receive_ok")
# Activity rows: "Received 0.05 EPIC from esa57k…ZwzB4d, …", and after a restore
# "Found on the chain: 0.02 EPIC, received, …".
TX_RE = re.compile(r"^(Received|Receiving|Sent|Sending|Cancelled|Canceled|Failed|Paid|Payment|Found on the chain)\b.*?\b([0-9]+(?:\.[0-9]+)?) EPIC\b")
HOST_ROW = re.compile(r"^([a-z0-9-]+(?:\.[a-z0-9-]+)+(?::\d+)?), ")


def log(*a):
    line = time.strftime("%H:%M:%S ") + " ".join(str(x) for x in a)
    print(line, flush=True)
    with open(os.path.join(OUT, "driver.log"), "a") as f:
        f.write(line + "\n")


def shot(name):
    """Screenshot for the proof; never called on a phrase or PIN screen."""
    d = os.path.join(OUT, "shots")
    os.makedirs(d, exist_ok=True)
    try:
        ph.shot(S, os.path.join(d, f"{len(os.listdir(d)):02d}-{name}.png"))
    except Exception as e:  # noqa: BLE001
        log("screenshot failed:", e)


def dump_to_log(title):
    with open(os.path.join(OUT, "screens.log"), "a") as f:
        f.write(f"== {time.strftime('%H:%M:%S')} {title}\n")
        ph.show(nodes(S), out=f)


# ---------------------------------------------------------------- secrets

def _secret_path(name):
    os.makedirs(STATE, mode=0o700, exist_ok=True)
    os.chmod(STATE, 0o700)
    return os.path.join(STATE, name)


def read_secret(name):
    p = _secret_path(name)
    if not os.path.exists(p):
        return None
    return open(p).read().strip() or None


def write_secret(name, value):
    p = _secret_path(name)
    fd = os.open(p, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        f.write(value + "\n")
    os.chmod(p, 0o600)


def pin():
    p = read_secret("pin")
    if not p:
        p = "".join(secrets.choice("0123456789") for _ in range(6))
        write_secret("pin", p)
    return p


# ---------------------------------------------------------------- basic screens

def home():
    """Back to the wallet's home (Lock wallet in the bar, Wallet tab)."""
    for _ in range(8):
        ph.hide_keyboard(S)
        ns = nodes(S)
        w = find(S, "Tab 2 of 3", ns=ns)
        if w and find(S, "Lock wallet", ns=ns):
            if find(S, "Recent activity", ns=ns) or find(S, "No payments yet", ns=ns):
                return True
            tap_xy(S, w["center"])
            time.sleep(2)
            if find(S, "Recent activity") or find(S, "No payments yet"):
                return True
        key(S, 4)
        time.sleep(1.5)
    return bool(find(S, "Tab 2 of 3"))


def pin_step(prompt, nxt, tries=4):
    """Type the PIN on the screen showing `prompt` until a label from `nxt` shows."""
    for _ in range(tries):
        if not wait(S, prompt, 20):
            break
        time.sleep(1.5)
        f = [n for n in nodes(S) if "EditText" in n["cls"]]
        if f:
            tap_xy(S, f[0]["center"])
            time.sleep(1)
            for _ in range(8):
                key(S, 67)
        type_text(S, pin())
        end = time.time() + 15
        while time.time() < end:
            labels = [n["label"] for n in nodes(S)]
            if any(any(x in l for x in nxt) for l in labels):
                return True
            time.sleep(1.5)
    return any(any(x in n["label"] for x in nxt) for n in nodes(S))


def unlock(secs=120):
    end = time.time() + secs
    while time.time() < end:
        ns = nodes(S)
        if find(S, "Lock wallet", ns=ns):
            return True
        if find(S, "Skip tour", ns=ns):
            tap(S, "Skip tour")
            continue
        if any("EditText" in n["cls"] for n in ns) and any("PIN" in n["label"] for n in ns):
            f = [n for n in ns if "EditText" in n["cls"]][0]
            tap_xy(S, f["center"])
            time.sleep(0.8)
            type_text(S, pin())
            time.sleep(5)
            continue
        time.sleep(2)
    dump_to_log("unlock failed")
    return False


def start_app(expect, secs=180):
    """Launch the app and wait for a label; relaunch and answer Android's "isn't responding"
    dialog (a fresh emulator is slow for its first minutes)."""
    end = time.time() + secs
    while time.time() < end:
        launch(S)
        t = time.time() + 30
        while time.time() < t:
            ns = nodes(S)
            if find(S, expect, ns=ns):
                return True
            w = find(S, "Wait", exact=True, clickable=True, ns=ns)
            if w:
                tap_xy(S, w["center"])
            time.sleep(3)
    dump_to_log(f"app start: no '{expect}'")
    return False


def create():
    if not start_app("Create a new wallet"):
        raise RuntimeError("no Welcome screen")
    for _ in range(5):  # the Welcome screen can still be settling: tap again until the PIN shows
        n = find(S, "Create a new wallet")
        if n:
            tap_xy(S, n["center"])
        if wait(S, "Choose a 6-digit PIN", 6):
            break
    if not pin_step("Choose a 6-digit PIN", ("Enter the PIN again",)):
        raise RuntimeError("PIN not taken")
    if not pin_step("Enter the PIN again", ("Skip tour", "Lock wallet", "of 8")):
        raise RuntimeError("repeat PIN not taken")
    if wait(S, "Skip tour", 120):
        tap(S, "Skip tour")
    if not wait(S, "Lock wallet", 60):
        raise RuntimeError("no home after create")
    log("created a new test wallet")


def read_phrase():
    """Home › Back up (or Settings › Security › Recovery phrase) › reveal with the PIN.
    Returns the words; never printed."""
    home()
    if find(S, "Back up", exact=True):
        tap(S, "Back up", exact=True)
    else:
        tap(S, "Settings", exact=True)
        wait(S, "Security", 10)
        tap(S, "Security")
        time.sleep(2)
        tap(S, "ecovery phrase")
    if wait(S, "I will keep", 15):
        tap(S, "I will keep")
        time.sleep(1)
    tap(S, "Show recovery phrase")
    pin_step("Enter your PIN", ("Word 1",))
    n = wait(S, "Word 1", 20)
    words = [w for _, w in re.findall(r"Word (\d+): ?([a-z]+)", n["label"])] if n else []
    secret_words(words)
    d = find(S, "Done", exact=True)
    if d:
        tap_xy(S, d["center"])
    home()
    return words


def restore(words, secs=1200):
    """Fresh app: Restore from phrase with `words` and the PIN; wait for home."""
    secret_words(words)
    if not start_app("Restore from phrase"):
        raise RuntimeError("no Welcome screen")
    tap(S, "Restore from phrase")
    wait(S, "All the words", 20)
    f = [n for n in nodes(S) if "EditText" in n["cls"]]
    tap_xy(S, f[0]["center"])
    time.sleep(1)
    type_text(S, " ".join(words))
    time.sleep(1)
    ph.hide_keyboard(S)  # so Continue is on screen
    time.sleep(1)
    tap(S, "Continue", exact=True)
    if not pin_step("Choose a 6-digit PIN", ("Enter the PIN again",)):
        raise RuntimeError("PIN not taken")
    pin_step("Enter the PIN again", ("Scan", "Lock wallet", "Skip tour", "of 8", "Checking"))
    end = time.time() + secs
    last = None
    while time.time() < end:
        ns = nodes(S)
        if any(n["label"] == "Not now" for n in ns):
            tap(S, "Not now", exact=True)
            time.sleep(3)
            continue
        if any(n["label"] == "Skip tour" for n in ns):
            tap(S, "Skip tour")
        if find(S, "Lock wallet", ns=ns) and not any(
                re.search(r"Scanning|Checking|Recheck.*%", n["label"]) for n in ns):
            log("restored: home shown")
            return True
        p = [n["label"] for n in ns if re.search(r"Scan|Check|%", n["label"])]
        if p and p[-1] != last:
            last = p[-1]
            log("restore:", mask(last)[:90])
        time.sleep(5)
    raise RuntimeError("restore did not finish in time")


# ---------------------------------------------------------------- reading the wallet

def address():
    home()
    tap(S, "Tab 3 of 3")
    n = wait(S, ", Epicbox address", 30)
    if not n:
        dump_to_log("no Epicbox address on Receive")
    addr = n["label"].split(",")[0].strip() if n else None
    w = find(S, "Tab 2 of 3")
    if w:
        tap_xy(S, w["center"])
    time.sleep(1)
    return addr


def short(addr):
    if not addr:
        return None
    k, _, d = addr.partition("@")
    return f"{k[:6]}…{k[-6:]}@{d}"


def wait_synced(secs=180):
    end = time.time() + secs
    while time.time() < end:
        home()
        n = find(S, "Node, ")
        if n and "Synced" in n["label"]:
            return True
        time.sleep(5)
    return False


def amount_of(label):
    m = re.search(r"([0-9][0-9,]*(?:\.[0-9]+)?)", label)
    try:
        return Decimal(m.group(1).replace(",", "")) if m else None
    except InvalidOperation:
        return None


def balance():
    home()
    ns = nodes(S)
    total = next((n["label"] for n in ns if n["label"].startswith("Total:")), None)
    spend = next((n["label"] for n in ns if n["label"].startswith("Spendable:")), None)
    norm = lambda v: format(v.normalize(), "f") if v is not None else None
    return {"total": norm(amount_of(total)) if total else None,
            "spendable": norm(amount_of(spend)) if spend else None}


def tx_rows(ns):
    return [n["label"] for n in ns if n["clickable"] and TX_RE.match(n["label"])]


def history():
    """Every row of Activity: (label) list, top to bottom."""
    home()
    ns = nodes(S)
    if find(S, "No payments yet", ns=ns) and not tx_rows(ns):
        return []
    va = find(S, "View all", ns=ns)
    if va:
        tap_xy(S, va["center"])
    else:
        a = find(S, "Activity", exact=True, ns=ns)
        tap_xy(S, a["center"])
    time.sleep(3)
    seen, rows = set(), []
    for _ in range(12):
        new = [r for r in tx_rows(nodes(S)) if r not in seen]
        if not new:
            break
        for r in new:
            seen.add(r)
            rows.append(r)
        ph.swipe_up(S)
        time.sleep(1.5)
    shot("activity")
    home()
    return rows


def tx_key(label):
    """What must survive an update: direction, amount and the other side (not the status or
    the time, which move as confirmations come in)."""
    m = TX_RE.match(label)
    kind = m.group(1)
    kind = {"Receiving": "Received", "Sending": "Sent"}.get(kind, kind)
    who = re.search(r"\b(?:from|to) ([A-Za-z0-9]{6}…[A-Za-z0-9]{6}|[^,]+)", label)
    amt = format(Decimal(m.group(2)).normalize(), "f")  # 0.0200 (26.10.24) = 0.02 (26.10.23)
    return f"{kind} {amt} {who.group(1) if who else ''}".strip()


def open_sheet(kind):
    home()
    n = find(S, f"{kind}, ", clickable=True)
    if not n:
        raise RuntimeError(f"no {kind} status on Home")
    tap_xy(S, n["center"])
    if not wait(S, kind, 10, exact=True):
        raise RuntimeError(f"{kind} sheet did not open")
    time.sleep(2)


def close_sheet():
    c = find(S, "Close", exact=True, clickable=True)
    if c:
        tap_xy(S, c["center"])
        time.sleep(1.5)


def sheet_rows(ns):
    return [n for n in ns if n["clickable"] and HOST_ROW.match(n["label"])]


def row_info(label):
    host = HOST_ROW.match(label).group(1)
    parts = [p.strip() for p in label.split(",")]
    return {"host": host, "current": "Current" in parts, "added": "Added by you" in parts}


def server_list(kind):
    """The sheet's list: hosts in order with Current / Added by you, and the removed count."""
    open_sheet(kind)
    seen, rows, removed = set(), [], None
    for _ in range(6):
        ns = nodes(S)
        for n in sheet_rows(ns):
            i = row_info(n["label"])
            if i["host"] not in seen:
                seen.add(i["host"])
                rows.append(i)
        r = next((n["label"] for n in ns if "removed" in n["label"] and "Restore" in n["label"]), None)
        if r:
            removed = r
        before = len(seen)
        adb(S, "shell", "input", "swipe", "540", "2000", "540", "1300", "400")
        time.sleep(1.2)
        if len(set(row_info(n["label"])["host"] for n in sheet_rows(nodes(S))) - seen) == 0 and before == len(seen):
            break
    shot(f"{kind.lower()}-list")
    close_sheet()
    home()
    return {"rows": rows, "removed": removed}


def bare_host(value):
    return re.sub(r"^[a-z]+://", "", value.strip().lower()).rstrip("/")


def same_host(row_host, target):
    a, b = bare_host(row_host), bare_host(target)
    return a == b or a == b + ":443" or a + ":443" == b


def _field():
    f = [n for n in nodes(S) if "EditText" in n["cls"]]
    return f[0] if f else None


def _filter(text):
    f = _field()
    clear = find(S, "Clear", exact=True, clickable=True)
    if clear:
        tap_xy(S, clear["center"])
        time.sleep(0.8)
    tap_xy(S, f["center"])
    time.sleep(0.8)
    if text:
        type_text(S, text)
        time.sleep(2.5)


def _confirm_switch():
    """The Epicbox sheet asks before a switch (the address changes); the node sheet does not."""
    time.sleep(1.5)
    d = find(S, "Switch to ")
    if d:
        b = find(S, "Switch", exact=True, clickable=True)
        tap_xy(S, b["center"])
        time.sleep(3)


def use_typed_server(kind, target):
    """Make `target` a typed-in ("Added by you") entry and the one in use. A built-in entry of
    the same host is first switched away from and removed, so the typed-in entry is the user's."""
    open_sheet(kind)
    for attempt in range(6):  # switch away, remove, add, switch to it: up to four rounds
        _filter(bare_host(target))
        ns = nodes(S)
        hit = next((n for n in sheet_rows(ns) if same_host(row_info(n["label"])["host"], target)), None)
        if hit and row_info(hit["label"])["added"]:
            if not row_info(hit["label"])["current"]:
                tap_xy(S, hit["center"])
                _confirm_switch()
            break
        if hit and row_info(hit["label"])["current"]:
            # in use: switch to another one first
            _filter("")
            ph.hide_keyboard(S)
            time.sleep(1)
            other = next((n for n in sheet_rows(nodes(S)) if not row_info(n["label"])["current"]
                          and "Health unknown" not in n["label"]), None)
            if not other:
                raise RuntimeError(f"{kind}: nothing to switch to before removing {target}")
            tap_xy(S, other["center"])
            _confirm_switch()
            continue
        if hit:
            rm = [n for n in ns if n["label"] == "Remove" and n["clickable"]
                  and hit["bounds"][1] <= n["center"][1] <= hit["bounds"][3]]
            if not rm:
                raise RuntimeError(f"{kind}: no Remove on {target}")
            tap_xy(S, rm[0]["center"])
            time.sleep(3)
            continue
        add = wait(S, "Add ", 10, clickable=True)
        if not add:
            dump_to_log(f"{kind}: no Add for {target}")
            raise RuntimeError(f"{kind}: the sheet offers no Add for {target}")
        tap_xy(S, add["center"])
        end = time.time() + 40
        while time.time() < end and not find(S, "Added by you"):
            time.sleep(2)
    _filter("")
    time.sleep(1)
    ns = nodes(S)
    cur = next((row_info(n["label"]) for n in sheet_rows(ns) if row_info(n["label"])["current"]), None)
    if not cur:  # the node sheet shows the one in use in a card above the list
        c = next((n["label"] for n in ns if n["label"].startswith("Current, ")), "")
        cur = {"host": c.split(",")[1].strip() if c else None, "added": True}
    close_sheet()
    home()
    ok = bool(cur and cur["host"] and same_host(cur["host"], target))
    log(f"{kind}: in use {cur and cur['host']} (typed-in {target}): {ok}")
    return ok


def advanced_page():
    home()
    tap(S, "Settings", exact=True)
    wait(S, "Advanced", 10)
    tap(S, "Advanced")
    wait(S, "Shows more", 10)
    time.sleep(1)


def _scroll_to(text, tries=6):
    for _ in range(tries):
        n = find(S, text)
        if n and 400 < n["center"][1] < 2050:
            return n
        ph.swipe_up(S)
        time.sleep(1.2)
    return find(S, text)


def _switch_in_row(label):
    ns = nodes(S)
    row = next((n for n in ns if n["label"] == label), None)
    if not row:
        return None
    sw = [n for n in ns if n["clickable"] and not n["label"] and n["bounds"][0] > 700
          and n["bounds"][1] <= row["center"][1] <= n["bounds"][3]]
    return sw[0] if sw else None


def confirmations_now():
    n = find(S, " confirmations, ")
    m = re.match(r"(\d+) confirmations", n["label"]) if n else None
    return int(m.group(1)) if m else None


def read_settings():
    """The stored settings the test watches: Theme, Show prices, Currency (Appearance);
    Technical details, Node failover, Confirmations (Advanced)."""
    out = {}
    home()
    tap(S, "Settings", exact=True)
    wait(S, "Appearance", 10)
    tap(S, "Appearance")
    wait(S, "Theme", 10)
    time.sleep(1)
    ns = nodes(S)
    for name in ("Theme", "Currency", "Language"):
        n = next((x for x in ns if x["label"].startswith(name + " | ")), None)
        out[name.lower()] = n["label"].split(" | ", 1)[1] if n else None
    sp = next((x for x in ns if x["label"] == "Show prices"), None)
    out["show_prices"] = bool(sp and sp["checked"]) if sp else None
    shot("appearance")
    advanced_page()
    for name, k in (("Technical details", "technical_details"), ("Node failover", "node_failover")):
        _scroll_to(name)
        sw = _switch_in_row(name)
        out[k] = sw["checked"] if sw else None
    _scroll_to(" confirmations, ")
    out["confirmations"] = confirmations_now()
    shot("advanced")
    home()
    return out


def change_settings():
    """Theme → THEME, Technical details on, Confirmations → CONFIRMATIONS."""
    home()
    tap(S, "Settings", exact=True)
    wait(S, "Appearance", 10)
    tap(S, "Appearance")
    wait(S, "Theme", 10)
    tap(S, "Theme | ")
    time.sleep(1.5)
    tap(S, THEME, exact=True, clickable=True)
    time.sleep(1.5)
    advanced_page()
    _scroll_to("Technical details")
    sw = _switch_in_row("Technical details")
    if sw and not sw["checked"]:
        tap_xy(S, sw["center"])
        time.sleep(1.5)
    _scroll_to(" confirmations, ")
    for _ in range(30):
        c = confirmations_now()
        if c is None or c == CONFIRMATIONS:
            break
        tap(S, "Fewer confirmations" if c > CONFIRMATIONS else "More confirmations", exact=True)
        time.sleep(0.8)
    time.sleep(1.5)  # the setting is written after a short debounce
    home()


def digest():
    vn, vc = ph.version(S)
    d = {"version": vn, "version_code": vc, "address": address()}
    wait_synced(120)
    d["balance"] = balance()
    d["history"] = history()
    d["nodes"] = server_list("Node")
    d["relays"] = server_list("Epicbox")
    d["settings"] = read_settings()
    shot("home")
    return d


def public_digest(d):
    """The digest as written to the proof: the address shortened, nothing secret."""
    p = dict(d)
    p["address"] = short(d.get("address"))
    return p


# ---------------------------------------------------------------- payments

def pending_rows():
    return [r for r in tx_rows(nodes(S)) if re.search(r"waiting for|Waiting for", r)]


def wait_tx(pred, secs, what):
    end = time.time() + secs
    last = None
    while time.time() < end:
        home()
        rows = tx_rows(nodes(S))
        hit = next((r for r in rows if pred(r)), None)
        if hit:
            return hit
        top = rows[0] if rows else None
        if top != last:
            log(f"{what}: top row: {top}")
            last = top
        time.sleep(6)
    return None


def clear_field_and_type(text):
    f = _field()
    tap_xy(S, f["center"])
    time.sleep(0.8)
    key(S, 123)  # end of the text
    for _ in range(4):
        adb(S, "shell", "input", "keyevent", *(["67"] * 30))
    type_text(S, text)
    time.sleep(1.5)


def send_epicbox(to_addr, amount):
    """Send tab › Epicbox › address › amount › review › send. Returns True once sent."""
    home()
    tap(S, "Tab 1 of 3")
    time.sleep(2)
    for _ in range(4):  # a send left half-way: back to its first step
        b = find(S, "Back", exact=True, clickable=True)
        if find(S, "| 1 of 3") or not b:
            break
        tap_xy(S, b["center"])
        time.sleep(1.5)
    m = find(S, "Epicbox", exact=True, clickable=True)
    if m:
        tap_xy(S, m["center"])
        time.sleep(1)
    clr = find(S, "Clear recipient", clickable=True)
    if clr:
        tap_xy(S, clr["center"])
        time.sleep(1)
    clear_field_and_type(to_addr)
    ph.hide_keyboard(S)
    tap(S, "Continue", exact=True, clickable=True)
    if not wait(S, "Amount", 15):
        raise RuntimeError("send: no amount step")
    clear_field_and_type(amount)
    ph.hide_keyboard(S)
    c = wait(S, "Continue", 10, exact=True, clickable=True)
    if not c:
        dump_to_log("send: Continue not enabled")
        raise RuntimeError("send: amount not accepted (Continue off)")
    tap_xy(S, c["center"])
    time.sleep(3)
    dump_to_log("send: review")
    shot("send-review")
    b = next((n for n in nodes(S) if n["clickable"] and n["center"][1] > 1000
              and re.fullmatch(r"Send [0-9.]+ EPIC|Send|Send now|Confirm", n["label"])), None)
    if not b:
        raise RuntimeError("send: no Send button on the review")
    tap_xy(S, b["center"])
    time.sleep(2)
    if find(S, "PIN"):
        pin_step("PIN", ("Sent", "Sending", "Waiting", "Done", "Lock wallet", "Payment"))
    time.sleep(3)
    dump_to_log("send: after send")
    shot("send-done")
    d = find(S, "Done", exact=True, clickable=True)
    if d:
        tap_xy(S, d["center"])
    home()
    return True


def funds(p, my_addr):
    """send_ok, receive_ok and their details. P's listener runs for the whole of it."""
    res = {"send_ok": False, "receive_ok": False}
    det = {}
    p_addr = p.address()
    if not p_addr:
        det["send_ok"] = det["receive_ok"] = "could not read P's address"
        return res, det
    pk = p_addr.split("@")[0]
    p_short = f"{pk[:6]}…{pk[-6:]}"
    # Send first: the funds already in the wallet are spendable; P's listener answers.
    need = Decimal(SEND_AMOUNT) + Decimal("0.01")
    end = time.time() + 1200
    while time.time() < end:
        sp = balance()["spendable"]
        if sp and Decimal(sp) >= need:
            break
        time.sleep(15)
    try:
        before = set(tx_rows(nodes(S)))
        send_epicbox(p_addr, SEND_AMOUNT)
        amt = str(Decimal(SEND_AMOUNT).normalize())
        row = wait_tx(lambda r: r.startswith(("Sent", "Sending")) and f" {amt} EPIC" in r
                      and p_short in r and r not in before
                      and not re.search(r"waiting for|Waiting for|cancel", r, re.I), 420, "send")
        res["send_ok"] = bool(row)
        det["send_ok"] = (f"{SEND_AMOUNT} EPIC to P ({short(p_addr)}) by Epicbox: {row}" if row
                          else f"{SEND_AMOUNT} EPIC to P not posted in 7 min")
    except Exception as e:  # noqa: BLE001
        det["send_ok"] = f"send failed: {e}"
        dump_to_log("send failed")
    log("send:", det["send_ok"])
    # Receive: P pays the wallet; the phone answers; P's listener finalizes and posts.
    try:
        row = receive_from_p(p, my_addr, RECEIVE_AMOUNT, p_short)
        res["receive_ok"] = bool(row)
        det["receive_ok"] = (f"{RECEIVE_AMOUNT} EPIC from P by Epicbox: {row}" if row
                             else f"{RECEIVE_AMOUNT} EPIC from P not posted in time")
    except Exception as e:  # noqa: BLE001
        det["receive_ok"] = f"receive failed: {e}"
        dump_to_log("receive failed")
    log("receive:", det["receive_ok"])
    shot("after-funds")
    return res, det


def receive_from_p(p, my_addr, amount, p_short=None, secs=900):
    """P pays `amount` to the wallet; returns the wallet's row once the payment is posted
    (Received …, confirming or received), else None. P's listener finalizes the payment but at
    times never posts it: 45 s after a finalize with nothing posted, P posts its copy again."""
    mark = p.listener_mark()
    ok, out = p.send(my_addr, amount)
    if not ok:
        raise RuntimeError("P's send failed: " + " ".join(re.findall(r"ERROR[^\n]*", out))[:200])
    amt = str(Decimal(amount).normalize())
    ours = lambda r: r.startswith(("Received", "Receiving")) and f" {amt} EPIC" in r \
        and (p_short is None or p_short in r)
    posted = lambda r: ours(r) and not re.search(r"waiting for", r, re.I)
    end, finalized_at, reposts, last = time.time() + secs, None, 0, None
    while time.time() < end:
        home()
        rows = [r for r in tx_rows(nodes(S)) if ours(r)]
        hit = next((r for r in rows if posted(r)), None)
        if hit:
            return hit
        if rows and rows[0] != last:
            last = rows[0]
            log("receive:", last)
        if finalized_at is None and p.finalized_since(mark):
            finalized_at = time.time()
            log("receive: P finalized")
        if finalized_at and time.time() - finalized_at > 45 and reposts < 3:
            log("receive: not posted 45 s after P's finalize: P posts it again")
            p.repost_to(my_addr)
            reposts += 1
            finalized_at = time.time()
            mark = p.listener_mark()
        time.sleep(6)
    return None


def has_sender(label):
    return bool(re.search(r"\b(?:from|to) [A-Za-z0-9]{6}…[A-Za-z0-9]{6}", label))


def fund_new_wallet(p, my_addr, amount):
    row = receive_from_p(p, my_addr, amount)
    if not row:
        raise RuntimeError("the funding payment from P was not posted")
    log("funded:", row)


# ---------------------------------------------------------------- compare and proof

def compare(a, b):
    res, det = {}, {}
    ka = (a.get("address") or "").split("@")[0]
    kb = (b.get("address") or "").split("@")[0]
    res["wallet_opens"] = bool(b.get("opened") and ka and ka == kb)
    det["wallet_opens"] = ("unlocked with the PIN; same wallet key " + short(a["address"]).split("@")[0]
                           if res["wallet_opens"] else
                           f"opened={b.get('opened')}, key before {short(a.get('address'))}, after {short(b.get('address'))}")
    res["balance_kept"] = bool(a["balance"]["total"] is not None and a["balance"] == b["balance"]) or (
        a["balance"]["total"] is not None and a["balance"]["total"] == b["balance"]["total"])
    det["balance_kept"] = f"before {a['balance']}, after {b['balance']}"
    ha = sorted(tx_key(r) for r in a["history"])
    hb = sorted(tx_key(r) for r in b["history"])
    senders = sum(has_sender(r) for r in a["history"])
    res["history_kept"] = bool(ha) and ha == hb and senders > 0
    det["history_kept"] = (f"{len(ha)} rows before ({senders} with a sender), {len(hb)} after"
                           + ("" if ha == hb else f"; missing {sorted(set(ha) - set(hb))[:5]}"
                              f"; new {sorted(set(hb) - set(ha))[:5]}"))
    for k, name, target in (("custom_nodes_kept", "nodes", NODE), ("custom_relays_kept", "relays", EPICBOX)):
        la, lb = a[name], b[name]
        added_a = [r["host"] for r in la["rows"] if r["added"]]
        added_b = [r["host"] for r in lb["rows"] if r["added"]]
        cur_a = next((r["host"] for r in la["rows"] if r["current"]), None)
        cur_b = next((r["host"] for r in lb["rows"] if r["current"]), None)
        hosts_a = [r["host"] for r in la["rows"]]
        hosts_b = [r["host"] for r in lb["rows"]]
        typed_there = any(same_host(h, target) for h in added_b)
        ok = bool(added_a) and added_a == added_b and cur_a == cur_b and typed_there \
            and set(hosts_a) <= set(hosts_b) | set() and set(hosts_b) - set(hosts_a) <= set() \
            and la["removed"] == lb["removed"]
        res[k] = ok
        det[k] = (f"typed-in {added_a} → {added_b}; in use {cur_a} → {cur_b}; "
                  f"removed '{la['removed']}' → '{lb['removed']}'"
                  + ("" if hosts_a == hosts_b else f"; list {hosts_a} → {hosts_b}"))
    sa, sb = a["settings"], b["settings"]
    diff = {k: (sa.get(k), sb.get(k)) for k in sa if sa.get(k) != sb.get(k)}
    changed_ok = sa.get("theme") == THEME and sa.get("technical_details") is True and sa.get("confirmations") == CONFIRMATIONS
    res["settings_kept"] = not diff and changed_ok
    det["settings_kept"] = (f"kept {sb}" if not diff and changed_ok else
                            f"changed by the update: {diff}" if diff else
                            f"the test could not set them on the previous version: {sa}")
    return res, det


def write_proof(checks, details, extra):
    proof = {
        "platform": "android",
        "variant": E("REL_VARIANT", "tor"),
        "previous": E("REL_PREVIOUS_VERSION", ""),
        "candidate": E("REL_CANDIDATE_VERSION", ""),
        "node": NODE,
        "epicbox": EPICBOX,
        "update_method": "adb install -r (same signature, as the in-app updater's PackageInstaller)",
        "checks": {k: bool(checks.get(k, False)) for k in CHECKS},
        "details": {k: details.get(k, "not performed") for k in CHECKS},
    }
    proof.update(extra)
    with open(os.path.join(OUT, "proof.json"), "w") as f:
        json.dump(proof, f, indent=2, ensure_ascii=False)
        f.write("\n")
    return proof


RESULT = ({}, {}, {})  # checks, details, extra: kept when the run stops on an error


def run():
    prev_apk, cand_apk = E("REL_PREVIOUS_APK"), E("REL_CANDIDATE_APK")
    required = [c for c in E("REL_CHECKS", ",".join(CHECKS)).split(",") if c]
    if not FUNDS:  # data checks only: the payment checks are not asked for
        required = [c for c in required if c not in ("send_ok", "receive_ok")]
    checks, details, extra = RESULT
    extra["required"] = required
    from pfund import PSession

    def finish(code_if_ok=0):
        if not FUNDS:
            for k in ("send_ok", "receive_ok"):
                details.setdefault(k, "not run (REL_FUNDS=0)")
        proof = write_proof(checks, details, extra)
        missing = [c for c in required if not proof["checks"].get(c)]
        log("checks:", json.dumps(proof["checks"]))
        if missing:
            log("NOT PROVEN:", ", ".join(missing))
            return 1
        return code_if_ok

    # 1. previous release, fresh
    log("previous APK", os.path.basename(prev_apk))
    adb(S, "uninstall", PKG)
    r = adb(S, "install", prev_apk, timeout=300)
    if "Success" not in r:
        details["wallet_opens"] = f"could not install the previous APK: {r.strip()[-200:]}"
        write_proof(checks, details, extra)
        return 2
    vn0, vc0 = ph.version(S)
    log(f"installed previous {vn0} ({vc0})")
    words = (read_secret("phrase") or "").split()
    p_log = os.path.join(OUT, "p.log")
    if words:
        secret_words(words)
        restore(words)
        unlock(30)
    else:
        create()
        words = read_phrase()
        if len(words) not in (12, 24):
            raise RuntimeError("could not read the new wallet's phrase")
        write_secret("phrase", " ".join(words))
        log(f"kept the new wallet's phrase ({len(words)} words) in {STATE} (mode 600)")
    # 2. the user's own servers and settings
    ok_n = use_typed_server("Node", NODE)
    ok_r = use_typed_server("Epicbox", EPICBOX)
    change_settings()
    my_addr = address()
    log("wallet", short(my_addr))
    # 3. history with a payment the chain cannot give back: a restore (or a rescan of a lost
    # wallet folder) only finds outputs ("Found on the chain"); a payment by Epicbox carries
    # its sender, which only the wallet's own data holds.
    if not any(has_sender(r) for r in history()):
        bal = Decimal(balance()["total"] or "0")
        amount = FUND_AMOUNT if bal < Decimal("0.03") else PREP_AMOUNT
        log(f"no payment with a sender in the history: P pays {amount} EPIC")
        with PSession(p_log) as p:
            fund_new_wallet(p, my_addr, amount)
    a = digest()
    a["opened"] = True
    extra["before"] = public_digest(a)
    log("digest before:", json.dumps(public_digest(a), ensure_ascii=False))
    if not (ok_n and ok_r):
        extra["setup_note"] = "the typed-in node or relay could not be put in use on the previous version"
    # 4. update the way the in-app updater does: same package, same signature, data kept
    log("candidate APK", os.path.basename(cand_apk))
    r = adb(S, "install", "-r", cand_apk, timeout=300)
    vn1, vc1 = ph.version(S)
    log(f"adb install -r: {r.strip()[-80:]} → {vn1} ({vc1})")
    extra["installed"] = {"previous": f"{vn0} ({vc0})", "candidate": f"{vn1} ({vc1})"}
    if "Success" not in r or vc1 == vc0:
        details["wallet_opens"] = f"the candidate did not install over the previous one: {r.strip()[-200:]}"
        return finish() or 1
    start_app("PIN", 120)
    opened = unlock(180)
    shot("after-update-unlock")
    if not opened:
        dump_to_log("after update: no home")
        details["wallet_opens"] = "the candidate did not open the wallet with the PIN"
        return finish()
    b = {"opened": True}
    b.update(digest())
    # a refresh can still be landing: read the balance and history again before judging
    for _ in range(6):
        if b["balance"]["total"] == a["balance"]["total"] and len(b["history"]) >= len(a["history"]):
            break
        time.sleep(20)
        b["balance"], b["history"] = balance(), history()
    extra["after"] = public_digest(b)
    log("digest after:", json.dumps(public_digest(b), ensure_ascii=False))
    c, d = compare(a, b)
    checks.update(c)
    details.update(d)
    for k, ok in (("custom_nodes_kept", ok_n), ("custom_relays_kept", ok_r)):
        if not ok:  # fail closed: the user's own server was never in use before the update
            checks[k] = False
            details[k] = "not set up on the previous version (typed-in server not in use); " + details[k]
    # 5. payments on the candidate
    if FUNDS:
        if not checks.get("wallet_opens"):
            details["send_ok"] = details["receive_ok"] = "not run: the wallet did not open"
        else:
            # The payments go through REL_NODE / REL_EPICBOX: if the update dropped them, put
            # them back first (the lost lists are already reported above).
            note = []
            for kind, target, name in (("Node", NODE, "nodes"), ("Epicbox", EPICBOX, "relays")):
                cur = next((r["host"] for r in b[name]["rows"] if r["current"]), None)
                if not (cur and same_host(cur, target)):
                    note.append(f"{kind} {target} put back in use for the payments")
                    use_typed_server(kind, target)
            my_addr = address() if note else b["address"]
            with PSession(p_log) as p:
                fr, fd = funds(p, my_addr)
            if note:
                fd = {k: v + " (" + "; ".join(note) + ")" for k, v in fd.items()}
            checks.update(fr)
            details.update(fd)
    return finish()


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    cmd = sys.argv[1] if len(sys.argv) > 1 else "run"
    words = (read_secret("phrase") or "").split()
    if words:
        secret_words(words)
    try:
        if cmd == "run":
            sys.exit(run())
        elif cmd == "fail":  # trust-android.sh could not start: a fail-closed proof
            write_proof({}, {k: f"not performed: {sys.argv[2]}" for k in CHECKS}, {"error": sys.argv[2]})
        elif cmd == "digest":
            print(json.dumps(public_digest(digest()), indent=1, ensure_ascii=False))
        elif cmd == "unlock":
            print(unlock())
        elif cmd == "servers":
            print(use_typed_server("Node", NODE), use_typed_server("Epicbox", EPICBOX))
        elif cmd == "settings":
            change_settings()
            print(read_settings())
        elif cmd == "history":
            print("\n".join(history()))
        elif cmd == "phrase-check":
            w = read_phrase()
            print(len(w), "words; same as kept:", w == words)
        elif cmd == "keep-phrase":  # the wallet on screen becomes the test wallet
            w = read_phrase()
            write_secret("phrase", " ".join(w))
            print(f"kept {len(w)} words")
        elif cmd == "send":
            print(send_epicbox(sys.argv[2], sys.argv[3]))
    except Exception as e:  # noqa: BLE001
        log("driver error:", e)
        try:
            ns = nodes(S)
            dump_to_log(f"driver error: {e}")
            if not any(mask(n["label"], n["cls"]).startswith(("***", "Word ***")) and "EditText" not in n["cls"]
                       for n in ns):  # never a screenshot of a phrase
                shot("error")
        except Exception:  # noqa: BLE001
            pass
        with open(os.path.join(OUT, "driver.log"), "a") as f:
            traceback.print_exc(file=f)
        if cmd == "run":
            checks, details, extra = RESULT
            for k in CHECKS:
                if k not in checks:
                    details.setdefault(k, f"not performed: driver error: {e}")
            extra["error"] = str(e)
            write_proof(checks, details, extra)
            # before the update nothing was judged: could not run; after it, not proven
            sys.exit(1 if checks else 2)
        sys.exit(2)
