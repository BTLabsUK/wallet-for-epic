# SPDX-License-Identifier: Apache-2.0
"""The linked-devices recipes of the TX lane (linux/tx_lane.py, LINK-1) on the desktop family, over
core/desktop.py: Settings › Linked devices, the name this device goes by (This device › Rename),
Link a device with its invite copied on one install and pasted on the other (the dialog's Paste
invite tab), the link's result (Linked to <name>. | the failure's own line), and Remove on one
install with what the other then reads.

Targets the registry does not hold are made here with T(): ARB keys first, the 26.11.0 English
text as the fallback.

The check of a payment both installs could answer (check_answers) is pure: it takes the slate and
each install's wallet data (walletdata's digest) and is unit-tested (tests/test_trust_tx.py)."""
import re

from .driver import Expect, either, gone, shows
from .payments import NAV_ACTIVITY, TX_RECEIVED, TX_ROW_RX
from .targets import T

LINK_OPEN = T("link.open")
RENAME = T("link.rename")
RENAME_FIELD = T("link.rename.field")
RENAME_SAVE = T("link.rename.save")
# the dialog: Show QR | Paste invite; the shower's Copy invite; the paster's Invite field and Link
TAB_PASTE = T("link.tab.paste")
COPY = T("link.copy")
FIELD = T("link.field")
GO = T("link.go")
CANCEL = T("link.cancel")
CLOSE = T("link.close")
LINKING = T("link.linking")
DONE = T("link.done")
# desktop's failure is one line, the reason (deskLinkFailureText); "Not linked" is the phone's title
FAILED = T("link.failed")
# the linked row's Remove, its dialog's Remove; the other install's notice
REMOVE = T("link.remove")
REMOVE_TITLE = T("link.remove.title")
REMOVED_BY = T("link.removedby")
REMOVING = T("link.removing")

DROPPED = re.compile(r"cancel", re.I)  # LEPIC's cancelled state, however it is spelt


class Linking:
    def __init__(self, ui, clip, log=print):
        """ui: the Desktop recipe on the app; clip(text=None): the app's clipboard, read or set."""
        self.ui, self.d, self.clip, self.log = ui, ui.d, clip, log

    def open(self):
        """Settings › Linked devices."""
        self.ui.ensure_unlocked()
        if not self.ui.section("linked"):
            self.d.harness("Settings lists no Linked devices section")

    def rename(self, name):
        """This device › Rename: the name the other install sees this one as."""
        d = self.d
        self.open()
        if any(n.name.split("\n")[0].strip() == name for n in d.tree()):
            self.log("SKIP link-rename: %s already" % name)
            return
        hits = d.find_in(RENAME, d.tree())
        if not hits:
            d.harness("Linked devices shows no Rename")
        d._act(d.s.press, hits[0])  # This device's (a linked row's comes after it)
        d.must(shows(RENAME_FIELD), 20, step="link-rename")
        d.fill(RENAME_FIELD, name, step="link-rename-field")
        d.press(RENAME_SAVE, step="link-rename-save", then=gone(RENAME_FIELD), timeout=20)

    def linked(self):
        """A device is linked here: the Linked device group offers Remove, not Link a device."""
        self.open()
        tree = self.d.tree()
        return bool(self.d.find_in(REMOVE, tree)) and not self.d.find_in(LINK_OPEN, tree)

    def show_invite(self):
        """Link a device (Show QR) › Copy invite; -> the invite the app copied. The dialog stays open,
        waiting for the other install."""
        d = self.d
        self.open()
        self.clip("")
        d.press(LINK_OPEN, step="link-open", then=either(shows(COPY), shows(FAILED)), timeout=60)
        if d.seen(FAILED):
            d.harness("Link a device failed before an invite was shown: %s" % d.seen(FAILED).name.replace("\n", " ")[:120])
        got = None
        for _ in range(3):
            d.press(COPY, step="link-copy", then=Expect("copied", lambda dd, tree: True), timeout=10)
            got = d.wait(Expect("the invite on the clipboard", lambda dd, tree: (self.clip() or "").strip() or None), 10)
            if got:
                break
        if not got:
            d.harness("Copy invite left nothing on the clipboard")
        self.log("%s: device invite copied (%d characters)" % (self.ui.which, len(got)))
        return got

    def paste_invite(self, text):
        """Link a device › Paste invite › the invite in Invite › Link."""
        d = self.d
        self.open()
        # the dialog opens on Show QR, making an invite: leaving the tab before it stands can land on it
        d.press(LINK_OPEN, step="link-open", then=either(shows(COPY), shows(FAILED)), timeout=60)
        d.press(TAB_PASTE, step="link-paste-tab", then=shows(FIELD), timeout=20)
        d.fill(FIELD, text, step="link-paste-field")
        hits = d.find_in(GO, d.tree())
        d._act(d.s.press, hits[-1])
        d.must(either(shows(LINKING), shows(DONE), shows(FAILED), gone(FIELD)), 60, step="link-go")

    def result(self, timeout=300):
        """The link dialog's result: (True, "Linked to …") | (False, its line); Linked closes by itself
        (waited for, Settings is under it), so a dialog gone with the device listed counts as linked."""
        d = self.d

        def got(dd, tree):
            for t in (DONE, FAILED):
                hits = dd.find_in(t, tree)
                if hits:
                    return t, hits
            return None
        r = d.wait(Expect("Linked or a failure line", got), timeout)
        d.shot("link-result")
        if r is None:
            if self.linked():
                return True, "the dialog closed; Linked devices lists the other install"
            return False, "no result in %d s" % timeout
        t, hits = r
        said = hits[0].name.replace("\n", " ")[:200]
        if t is DONE:
            d.wait(gone(DONE), 15)
            return True, said
        if d.seen(CLOSE):
            d.press(CLOSE, step="link-close", then=gone(FAILED), timeout=20)
        return False, "Not linked: %s" % said

    def cancel(self):
        """The link dialog closed (Cancel or Close), when one is open."""
        d = self.d
        for t in (CANCEL, CLOSE):
            if d.seen(t):
                d.press(t, step="link-dismiss", then=gone(t), timeout=20)
                return

    def remove(self):
        """The linked row's Remove › Remove (the dialog's); -> True once Link a device is offered again."""
        d = self.d
        self.open()
        d.press(REMOVE, step="link-remove", then=shows(REMOVE_TITLE), timeout=20)
        hits = d.find_in(REMOVE, d.tree())
        d._act(d.s.press, hits[-1])  # the dialog's
        r = d.wait(shows(LINK_OPEN), 60)
        d.shot("link-removed")
        return bool(r)

    def ended(self, timeout=300):
        """The other side's view after a Remove: <name> removed this device, or no device linked.
        -> (True, what it reads) | (False, what it reads)."""
        d = self.d
        self.open()
        r = d.wait(either(shows(REMOVED_BY), shows(LINK_OPEN)), timeout)
        d.shot("link-ended")
        tree = d.tree()
        by = d.find_in(REMOVED_BY, tree)
        if by:
            return True, by[0].name.replace("\n", " ")[:120]
        if r and d.find_in(LINK_OPEN, tree) and not d.find_in(REMOVING, tree):
            return True, "no device linked (Link a device offered)"
        return False, "still linked after %d s" % timeout


# ---- one payment, two installs ------------------------------------------------------------------------

def slate_key(slate):
    return re.sub(r"[^0-9a-f]", "", (slate or "").lower())


def answers(slate, d):
    """The incoming transactions of [slate] in one install's data (walletdata digest)."""
    s = slate_key(slate)
    return [t for t in ((d or {}).get("txs") or []) if t["direction"] == "incoming" and s and slate_key(t.get("slate")) == s]


def live(t):
    return not DROPPED.search(t.get("state") or "")


def check_answers(slate, data, amount_nano, settled=False):
    """(ok, why, facts) for a payment to the wallet's one address that both installs could answer.
    data: {install: digest}. ok True: exactly one install holds the incoming of [slate], confirmed and
    of [amount_nano], and every other install has none or dropped its own (cancelled). None: not
    there yet. False: two answers took, or the amount is wrong. [settled]: the time to drop the
    losing answer is up, so one still open is False."""
    got = {k: answers(slate, d) for k, d in data.items()}
    facts = {k: [t["state"] for t in v] for k, v in got.items()}
    took = {k: [t for t in v if t["state"] in ("posted", "confirmed")] for k, v in got.items()}
    winners = [k for k, v in took.items() if v]
    if len(winners) > 1:
        return False, "the slate's incoming took on %s (wallet data: %s)" % (" and ".join(winners), _states(facts)), facts
    if not winners:
        return None, "no install's incoming is posted or confirmed yet (%s)" % _states(facts), facts
    w = winners[0]
    t = took[w][-1]
    facts["answered"] = w
    if (t.get("credited") or 0) != amount_nano:
        return False, "%s received %s nanoEPIC, not %s (wallet data)" % (w, t.get("credited"), amount_nano), facts
    if t["state"] != "confirmed":
        return None, "%s's incoming is %s" % (w, t["state"]), facts
    facts["confirmed"] = True
    open_ = [k for k, v in got.items() if k != w and any(live(x) for x in v)]
    if open_:
        if settled:
            return False, "%s answered and confirmed; %s still holds its own answer open (%s)" % (
                w, " and ".join(open_), _states(facts)), facts
        return None, "%s answered; %s's own answer not dropped yet (%s)" % (w, " and ".join(open_), _states(facts)), facts
    return True, "one answer took: %s's, confirmed; %s" % (w, _states(facts)), facts


def _states(facts):
    return "; ".join("%s: %s" % (k, ", ".join(v) or "none") for k, v in facts.items() if k not in ("answered", "confirmed"))


def activity_row(ui, amount_text, timeout=120):
    """The Activity row of a receipt of [amount_text] EPIC on this install; -> its name, or None."""
    d = ui.d
    ui.ensure_unlocked()
    ui.nav(NAV_ACTIVITY)
    amt = re.escape(amount_text) + "0*"

    def row(dd, tree):
        return next((n for n in tree if n.name and TX_ROW_RX.match(n.name) and n.name.lower().startswith(TX_RECEIVED)
                     and re.search(r"\b%s\b" % amt, n.name)), None)
    r = d.wait(Expect("an Activity row: received %s" % amount_text, row), timeout)
    d.shot("link-activity")
    return r.name.replace("\n", " ")[:120] if r else None
