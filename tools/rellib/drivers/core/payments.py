# SPDX-License-Identifier: Apache-2.0
"""The payment recipes of the TX lane (linux/tx_lane.py) on the desktop family, over core/desktop.py:
a receive method turned on and its address read, a send by a chosen method, the File round trip's
screens, and the method a transaction's detail names.

Methods are named as the wallet's data names a transaction's transport: epicbox, http, tor, file.
The Send page picks the method from the address it is given (an Epicbox address, http(s)://, an
onion); a file send starts from its own form (Pay with a file).

Targets the registry (trust_ids.json, the app's TrustIds) does not hold are made here with
T(id, keys=, names=): ARB keys first, the 26.11.0 English text as the fallback.

File dialogs: the app asks the system's file chooser; the platform answers it (Linux: the sandbox's
stand-in portal, linux/portal_stub.py). Payments takes that as `choose(path)`, called before the
button that opens the dialog.

Nothing here decides whether a payment went: the checks (core/txchecks.py) read that from the
wallet's data."""
import os
import re
import time

from .desktop import (NAV_ACTIVITY, NAV_RECEIVE, NAV_SEND, SEND_AMOUNT, SEND_ANOTHER, SEND_CONFIRM, SEND_FAILED,
                      SEND_REVIEW, SEND_REVIEW_TITLE)
from .driver import Expect, either, shows
from .targets import T

METHODS = ("epicbox", "http", "tor", "file")

# Settings › Payments › Methods: the switches (a button of the same name opens each one's details)
PAY_SWITCH = {
    "http": T("tx.pay.http", role="toggle", keys=("methodDirectHttp",), names=("Link · HTTP",), match="exact"),
    "tor": T("tx.pay.tor", role="toggle", keys=("methodDirectTor",), names=("Link · Tor",), match="exact"),
    "file": T("tx.pay.file", role="toggle", keys=("methodDirectFile", "advTransactionFiles"),
              names=("Direct · File Transfer",), match="exact"),
}
# the method a transaction's detail (Activity, Deep end) names, by transport
METHOD_LABEL = {"epicbox": "Epicbox", "http": "Link · HTTP", "tor": "Link · Tor", "file": "Direct · File Transfer"}

HTTP_ADDRESS_RX = re.compile(r"^https?://[\w.:\[\]-]+/?$")
ONION_RX = re.compile(r"^(?:https?://)?([a-z2-7]{56})(?:\.onion)?/?$")

SEND_PAY_FILE = T("tx.send.payfile", keys=("sendPayByFile",), names=("Pay with a file",), match="exact")
FILE_READY = T("tx.send.fileready", role="text", keys=("deskSendFileReadyTitle",), names=("Transaction file ready",),
               match="starts")
RECV_OPEN = T("tx.recv.open", keys=("deskRecvOpen",), names=("Open",), match="exact")
FILES_OPENED = T("tx.recv.files", role="text", keys=("deskTfResults",), names=("Files opened",), match="starts")
TX_METHOD = T("tx.detail.method", role="text", keys=("deskTxFactMethod",), names=("Method",), match="starts")
TX_ROW_RX = re.compile(r"^(sent|received) ", re.I)

ONION_WAIT_S = 240  # the onion service's first start (Tor bootstrap and descriptor upload)


class Payments:
    def __init__(self, ui, choose, log=print):
        """ui: the Desktop recipe on the app; choose(path): the next file dialog's answer (None closes it)."""
        self.ui, self.d, self.choose, self.log = ui, ui.d, choose, log

    # ---- receiving

    def enable_receive(self, method):
        """Turns [method] on for receiving (Settings › Payments) and returns its address as a sender
        types it: the Epicbox address, http://127.0.0.1:<port>, the onion; None for file."""
        if method not in METHODS:
            raise ValueError("unknown method %s" % method)
        if method == "epicbox":
            return self.ui.address()
        self.ui.section("payments")
        self.d.toggle(PAY_SWITCH[method], True, step="receive-%s-on" % method, timeout=30)
        if method == "file":
            return None
        return self.receive_address(method)

    def receive_address(self, method, timeout=None):
        """The Link address Receive shows for [method] (http, tor), read in full from its field."""
        rx = HTTP_ADDRESS_RX if method == "http" else ONION_RX
        self.ui.nav(NAV_RECEIVE)

        def got(dd, tree):
            for n in tree:
                v = (n.value or "").strip()
                if n.role == "text_field" and rx.match(v):
                    return v
            return None
        a = self.d.must(Expect("the %s address on Receive" % method, got), timeout or (ONION_WAIT_S if method == "tor" else 60),
                        step="receive-%s-address" % method)
        if method == "tor":
            a = ONION_RX.match(a).group(1) + ".onion"
        self.log("%s: %s address %s" % (self.ui.which, method, a if method == "http" else a[:8] + "…"))
        return a

    # ---- sending

    def send(self, method, to, amount):
        """[amount] (EPIC text) by [method]: to an address for epicbox, http, tor (the Send page picks the
        method from it), a file for file (send_file). -> (ok, why) as Desktop.send."""
        if method == "file":
            return self.send_file(amount)
        return self.ui.send(to, amount)

    def send_hold(self):
        """The Send page's lines on Tor (its notice, the hint and the tip under Review: "Waiting for Tor",
        "Tor not connected", "Turn on Tor …"), the method's name aside; "" when there are none."""
        rx = re.compile(r"\btor\b", re.I)
        seen = []
        for n in self.d.tree():
            t = (n.name or "").replace("\n", " ").strip()
            if t and rx.search(t) and t != METHOD_LABEL["tor"] and t not in seen:
                seen.append(t)
        return "; ".join(seen)[:300]

    def send_file(self, amount):
        """Send › Pay with a file: [amount], its review and confirm; the app saves the file itself (its
        Downloads folder). -> (ok, why); the file is found by its slate id (file_for)."""
        d = self.d
        self.ui.nav(NAV_SEND)
        if d.seen(SEND_ANOTHER):
            d.press(SEND_ANOTHER, step="send-another", timeout=20)
        if d.wait(shows(SEND_PAY_FILE), 10):  # else already on the file form (a phase run again)
            d.press(SEND_PAY_FILE, step="send-file-form", then=shows(SEND_AMOUNT), timeout=20)
        d.fill(SEND_AMOUNT, amount, step="send-file-amount")
        d.shot("send-file-filled")
        d.press(SEND_REVIEW, step="send-file-review", then=shows(SEND_REVIEW_TITLE), timeout=60)
        pw = [n for n in d.tree() if n.role == "text_field" and "password" in n.states]
        if pw:
            d._act(d.s.set_text, pw[0], self.ui.password, True)
        d.press(SEND_CONFIRM, step="send-file-confirm", then=either(shows(FILE_READY), shows(SEND_FAILED)), timeout=120)
        d.shot("send-file-after")
        failed = d.find_in(SEND_FAILED, d.tree())
        if failed:
            return False, "the app says: %s" % failed[0].name.replace("\n", " ")[:200]
        return True, "file made (%s EPIC)" % amount

    # ---- transaction files (Receive › Transaction files › Open)

    def open_file(self, path, timeout=120):
        """Opens the transaction file [path] through Receive's Open (the app signs, finalizes or posts
        it, by what it is). -> the app's line for that file (e.g. "Signed. Response saved to …",
        "Payment posted", "Not a transaction file …")."""
        d = self.d
        name = os.path.basename(path)
        self.ui.nav(NAV_RECEIVE)
        self.choose(path)
        line_rx = re.compile(r"(?:^|\n)%s\s+(.+)$" % re.escape(name), re.M)

        def result(dd, tree):
            for n in dd.find_in(FILES_OPENED, tree):
                m = line_rx.search(n.name or "")
                if m:
                    return m.group(1).strip()
            return None
        d.press(RECV_OPEN, step="open-file", then=Expect("the result for %s" % name, result), timeout=timeout)
        got = result(d, d.tree())
        self.log("%s: opened %s: %s" % (self.ui.which, name, got))
        return got

    # ---- history

    def history_method(self, amount_text, incoming, timeout=60):
        """The method the newest Activity row of [amount_text] EPIC (sent, or received when [incoming])
        names in its detail, read from the Deep end's Method fact; None when no such row shows."""
        d = self.d
        self.ui.nav(NAV_ACTIVITY)
        word = "received" if incoming else "sent"
        amt = re.escape(amount_text) + "0*"  # the row may show 4 decimals (0.0100)

        def row(dd, tree):
            return next((n for n in tree if n.name and TX_ROW_RX.match(n.name) and n.name.lower().startswith(word)
                         and re.search(r"\b%s\b" % amt, n.name)), None)
        r = d.wait(Expect("an Activity row: %s %s" % (word, amount_text), row), timeout)
        if not r:
            return None
        d._act(d.s.press, r)
        if not d.wait(shows(TX_METHOD), 20):
            return None
        tree = d.tree()
        for i, n in enumerate(tree):
            if d.find_in(TX_METHOD, [n]):
                rest = re.split(r"\s*[\n|]\s*", n.name or "", 1)
                if len(rest) > 1 and rest[1].strip():
                    return rest[1].strip()
                nxt = next((m for m in tree[i + 1:] if (m.name or "").strip()), None)
                return (nxt.name or "").strip() if nxt else None
        return None


def method_of(label):
    """The transport a detail's Method label names, or None."""
    lab = re.sub(r"\s+", " ", label or "").strip().casefold()
    return next((m for m, l in METHOD_LABEL.items() if l.casefold() == lab), None)


def file_for(folders, slate, suffix=".tx", wait_s=30):
    """The newest file <first 8 of [slate]><suffix> (or <8>-<n><suffix>) in [folders], waited for a little
    (the app writes it as the screen changes). slate: the wallet data's hex slate id or the dashed one."""
    s8 = re.sub(r"[^0-9a-f]", "", (slate or "").lower())[:8]
    if len(s8) != 8:
        return None
    rx = re.compile(r"^%s(-\d+)?%s$" % (s8, re.escape(suffix)))
    end = time.time() + wait_s
    while True:
        found = []
        for f in folders:
            try:
                found += [os.path.join(f, n) for n in os.listdir(f) if rx.match(n.lower())]
            except OSError:
                pass
        if found or time.time() >= end:
            return max(found, key=os.path.getmtime) if found else None
        time.sleep(1)

