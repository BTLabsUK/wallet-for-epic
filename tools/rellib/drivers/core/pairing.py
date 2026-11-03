# SPDX-License-Identifier: Apache-2.0
"""The pairing recipes of the TX lane (linux/tx_lane.py, PAIR-1) on the desktop family, over
core/desktop.py: Pairing turned on (Settings › Advanced, experimental), the name a wallet is seen as,
an invite copied on one wallet and pasted on the other, the four words read on both sides and
confirmed, the pairing saved as a contact, a pair request to a proven contact, an invoice issued
and paid between the two, and the pairing removed.

The pairing's state is not in the LEPIC CLI's reports: it is read from the contact page's Pairing
block (Verified, Paired, not verified, Pairing ended, Not paired) and the four words from the check
dialog. Targets the registry does not hold are made here with T(): ARB keys first, the 26.11.0
English text as the fallback.

The clipboard: Copy invite puts the invite on the inviter's display; the platform reads it there
(`clip(text=None)`: read when text is None, else set) and the driver types it into the answerer's
field."""
import contextlib
import re

from .driver import Expect, either, gone, shows
from .targets import T

NAV_CONTACTS = T("g4.nav.contacts", keys=("deskShellNavContacts",), names=("Contacts",), match="exact")
ADV_PAIRING = T("pair.adv.pairing", role="toggle", keys=("expPairing",), names=("Pairing",), match="exact")
ADV_INVOICES = T("pair.adv.invoices", role="toggle", keys=("expInvoices",), names=("Invoices",), match="exact")

# Contacts › Pair: Your invite | Have their invite?
CONTACTS_PAIR = T("pair.contacts.pair", keys=("pairTitle",), names=("Pair",), match="exact")
PAIR_YOUR = T("pair.screen.yours", role="text", keys=("pairYourCode",), names=("Your invite",), match="exact")
PAIR_COPY = T("pair.screen.copy", keys=("pairCopyLink",), names=("Copy invite",), match="exact")
PAIR_SEEN_AS = T("pair.screen.seenas", role="text", keys=("pairSeenAsLine",), names=("re:they (will )?see you as .*",),
                 match="starts")
PAIR_CHANGE = T("pair.screen.change", keys=("pairChange",), names=("Change",), match="exact")
PAIR_NAME_FIELD = T("pair.name.field", role="text_field", keys=("pairSeenAsField",), match="starts")
PAIR_NAME_SAVE = T("pair.name.save", keys=("commonSave",), names=("Save",), match="exact")
PAIR_ENTER = T("pair.screen.enter", role="text_field", keys=("pairPasteField",), names=("Paste the invite",), match="starts")
PAIR_GO = T("pair.screen.go", keys=("pairTitle",), names=("Pair",), match="exact")
# the answerer: "Pair with Lane A?" › Pair; then "Pairing with Lane A…"
INCOMING_TITLE = T("pair.incoming.title", role="text", keys=("pairIncomingTitle",), match="exact")
INCOMING_PAIR = T("pair.incoming.pair", keys=("pairTitle",), names=("Pair",), match="exact")
WAITING_TITLE = T("pair.waiting.title", role="text", keys=("pairPairingWith",), match="exact")
# the words: "Check the words with Lane B", The four words, They match
CHECK_TITLE = T("pair.check.title", role="text", keys=("sasDialogTitle",), match="exact")
CHECK_WORDS = T("pair.check.words", role="other", keys=("sasWordsLabel",), names=("The four words",), match="starts")
CHECK_MATCH = T("pair.check.match", keys=("sasMatch",), names=("They match",), match="exact")
CHECK_ALLOW = T("pair.check.allow", role="toggle", keys=("contactAllowInvoices",), names=("Allow invoices",), match="exact")
# "Lane B is verified" › Save as a new contact › Save contact
SAVED_TITLE = T("pair.saved.title", role="text", keys=("sasMatchedTitle",), match="exact")
SAVED_NEW = T("pair.saved.new", keys=("pairSaveNewContact",), names=("Save as a new contact",), match="exact")
SAVE_CONTACT = T("pair.saved.save", keys=("deskConSave",), names=("Save contact",), match="exact")
# the contact page's Pairing block
STATE_VERIFIED = T("pair.state.verified", role="text", keys=("trustVerified",), names=("Verified",), match="line")
STATE_PAIRED = T("pair.state.paired", role="text", keys=("trustPaired",), names=("Paired, not verified",), match="line")
STATE_ENDED = T("pair.state.ended", role="text", keys=("pairEndedShort",), names=("Pairing ended",), match="line")
STATE_NONE = T("pair.state.none", role="text", keys=("pairNotPaired",), names=("Not paired",), match="line")
CONFIRMED_TOO = T("pair.state.both", role="text", keys=("pairConfirmedToo",), names=("re:.* confirmed too\\.",),
                  match="contains")
REMOVE_PAIRING = T("pair.contact.remove", keys=("contactRemovePairing",), names=("Remove pairing",), match="exact")
REMOVE_CONFIRM = T("pair.contact.removeok", keys=("contactRemove",), names=("Remove",), match="exact")
CONTACT_PAIR = T("pair.contact.pair", keys=("pairTitle", "pairAgain"), names=("Pair", "Pair again"), match="exact")
# a pair request to a proven contact: "Pair with Lane A" › Send request; the other side's Pair requests · 1 › Pair
REQUEST_SEND = T("pair.request.send", keys=("pairSendRequest",), names=("Send request",), match="exact")
REQUESTS_ROW = T("pair.requests.row", keys=("pairRequestsRow",), names=("re:pair requests · \\d+",), match="exact")
REQUESTS_PAIR = T("pair.requests.pair", keys=("pairRequestPair",), names=("Pair",), match="exact")

# invoices: the issuer's contact page › Issue an invoice › Amount › Send invoice; the payer's
# Invoices › Pay › Review › Approve and pay › Wallet password › Pay
INV_ISSUE = T("inv.contact.issue", keys=("deskInvIssueAction",), names=("Issue an invoice",), match="exact")
INV_AMOUNT = T("inv.issue.amount", role="text_field", keys=("deskInvIssuerAmount",), names=("Amount",), match="starts")
INV_SEND = T("inv.issue.send", keys=("reqNewSend",), names=("Send invoice",), match="exact")
INV_SENT = T("inv.issue.sent", role="other", keys=("reqSent", "deskInvIssuerWaitingText"),
             names=("re:invoice sent to .*", "re:delivered to .*epicbox server.*"), match="contains")
INV_FAILED = T("inv.issue.failed", role="other", keys=("deskInvFailed", "deskInvIssuerNotDelivered"), match="contains")
NAV_INVOICES = T("inv.nav", keys=("deskInvNav",), names=("Invoices",), match="exact")
INV_TAB_PAY = T("inv.tab.pay", role="other", keys=("deskInvTabPay",), names=("Pay",), match="starts")
INV_REVIEW = T("inv.pay.review", keys=("deskInvPayerReview",), names=("Review",), match="exact")
INV_APPROVE = T("inv.pay.approve", keys=("invoiceApprove",), names=("Approve and pay",), match="exact")
INV_PASSWORD = T("inv.pay.password", role="text_field", keys=("deskInvPayerPassword",), names=("Wallet password",),
                 match="starts", secret=True)
INV_PAY = T("inv.pay.pay", keys=("deskInvPayerPay",), names=("Pay",), match="exact")
INV_PAID = T("inv.pay.paid", role="other", keys=("invoicePaidNotice", "reqPaidWaiting"),
             names=("re:paid\\. .*", "re:paid\\. waiting for .*"), match="starts")

STATES = (("verified", STATE_VERIFIED), ("paired", STATE_PAIRED), ("ended", STATE_ENDED), ("none", STATE_NONE))
WORD_RX = re.compile(r"[a-z]+")
INVITE_RX = re.compile(r"\S*(?:epicpair|pair)[^\s]*", re.I)


class Pairing:
    def __init__(self, ui, clip, log=print):
        """ui: the Desktop recipe on the app; clip(text=None): the app's clipboard, read or set."""
        self.ui, self.d, self.clip, self.log = ui, ui.d, clip, log

    # ---- set up

    @contextlib.contextmanager
    def _own_not_now(self):
        """The pairing dialogs' Not now declines the pairing: while they are up the driver must not
        take it for the last-session notice's Not now (a desktop obstacle it presses on sight)."""
        d = self.d
        keep = d.obstacles
        d.obstacles = [(t, why) for t, why in keep if "Not now" not in t.names]
        try:
            yield
        finally:
            d.obstacles = keep

    def enable(self, invoices=False):
        """Settings › Advanced › Experiments: Invoices on when [invoices] (off on a new install). Pairing
        is on for everyone since 26.11.0; an older build's Pairing switch is turned on when it shows."""
        self.ui.section("advanced")
        if self.d.seen(ADV_PAIRING):
            self.d.toggle(ADV_PAIRING, True, step="pairing-on", timeout=30)
        if invoices:
            self.d.toggle(ADV_INVOICES, True, step="invoices-on", timeout=30)
        self.ui.leave_settings()

    def open_pair(self):
        """Contacts › Pair: the invite (Your invite) and the field for theirs."""
        d = self.d
        self.ui.nav(NAV_CONTACTS)
        d.press(CONTACTS_PAIR, step="pair-open", then=shows(PAIR_YOUR), timeout=30)

    def seen_as(self, name):
        """The name the other wallet sees this one as (the Pair page's They will see you as … Change)."""
        d = self.d
        line = d.wait(shows(PAIR_SEEN_AS), 20)
        if line and line.name.strip().endswith(name):
            self.log("SKIP pair-name: seen as %s already" % name)
            return
        d.press(PAIR_CHANGE, step="pair-name", then=shows(PAIR_NAME_FIELD), timeout=20)
        d.fill(PAIR_NAME_FIELD, name, step="pair-name-field")
        d.press(PAIR_NAME_SAVE, step="pair-name-save", then=Expect("seen as %s" % name, lambda dd, tree: any(
            n.name.strip().endswith(name) for n in dd.find_in(PAIR_SEEN_AS, tree))), timeout=30)

    # ---- the invite

    def copy_invite(self):
        """Copy invite on the Pair page; -> the message the app copied (it carries the invite link)."""
        d = self.d
        self.clip("")
        d.must(Expect("Copy invite enabled", lambda dd, tree: next((n for n in dd.find_in(PAIR_COPY, tree)
                                                                       if "enabled" in n.states or "sensitive" in n.states), None)),
               60, step="pair-invite-ready")
        got = None
        for _ in range(3):
            d.press(PAIR_COPY, step="pair-copy", then=Expect("copied", lambda dd, tree: True), timeout=10)
            got = d.wait(Expect("the invite on the clipboard", lambda dd, tree: (self.clip() or "").strip() or None), 10)
            if got:
                break
        if not got:
            d.harness("Copy invite left nothing on the clipboard")
        self.log("%s: invite copied (%d characters)" % (self.ui.which, len(got)))
        return got

    def enter_invite(self, text, inviter):
        """The answerer: the invite into Have their invite?, Pair, then Pair with <inviter>? › Pair."""
        d = self.d
        d.fill(PAIR_ENTER, text, step="pair-enter")
        with self._own_not_now():
            d.press(PAIR_GO, step="pair-go", then=shows(INCOMING_TITLE), timeout=60)
            title = d.find_in(INCOMING_TITLE, d.tree())
            if inviter not in title[0].name:
                d.harness("the invite says %r, not %s" % (title[0].name, inviter))
            hits = d.find_in(INCOMING_PAIR, d.tree())
            d._act(d.s.press, hits[-1])  # the dialog's Pair (the page's own is under it)
            d.must(either(shows(WAITING_TITLE), shows(CHECK_TITLE)), 60, step="pair-answered")

    # ---- the words

    def words(self, timeout=300):
        """The four words the open check dialog shows (waits for it); -> list of 4, lower case."""
        d = self.d

        def got(dd, tree):
            if not dd.find_in(CHECK_MATCH, tree):
                return None
            for n in dd.find_in(CHECK_WORDS, tree):
                w = words_in(n.name)
                if len(w) == 4:
                    return w
            return None
        w = d.must(Expect("the four words", got), timeout, step="pair-words")
        d.shot("pair-words")
        return w

    def confirm_words(self, allow_invoices=False):
        """They match (Allow invoices on first when asked and offered); then the result saved as a new contact."""
        d = self.d
        if allow_invoices and d.seen(CHECK_ALLOW):
            d.toggle(CHECK_ALLOW, True, step="pair-allow-invoices")
        with self._own_not_now():  # "<name> is verified": Not now | Add to a contact | Save as a new contact
            d.press(CHECK_MATCH, step="pair-match", then=either(shows(SAVED_NEW), gone(CHECK_MATCH)), timeout=60)
            if d.wait(shows(SAVED_NEW), 10):
                d.press(SAVED_NEW, step="pair-save-new", then=shows(SAVE_CONTACT), timeout=20)
                d.press(SAVE_CONTACT, step="pair-save-contact", then=gone(SAVE_CONTACT), timeout=30)

    # ---- the contact page

    def open_contact(self, name):
        """Contacts › <name>: the contact page with its Pairing block."""
        d = self.d
        self.ui.nav(NAV_CONTACTS)
        row = T("pair.contact.row.%s" % name.lower().replace(" ", "_"), role="other", names=(name,), match="line")
        d.press(row, step="contact-open", then=either(*(shows(t) for _, t in STATES)), timeout=30)

    def state(self, name, refresh=True):
        """The pairing state with <name> on its contact page: verified | paired | ended | none, plus
        whether it says <name> confirmed too; (None, False) when the page shows none of them."""
        if refresh:
            self.open_contact(name)
        tree = self.d.tree()
        st = next((k for k, t in STATES if self.d.find_in(t, tree)), None)
        return st, bool(self.d.find_in(CONFIRMED_TOO, tree))

    def wait_state(self, name, want, timeout=180):
        """Until <name>'s contact page reads [want] (the page reopened now and then)."""
        d = self.d
        self.open_contact(name)
        r = d.wait(Expect("%s %s" % (name, want), lambda dd, tree: d.find_in(dict(STATES)[want], tree) or None), timeout)
        d.shot("pair-state-%s" % want)
        return bool(r)

    def remove(self, name):
        """<name>'s contact page › Remove pairing › Remove."""
        d = self.d
        self.open_contact(name)
        d.press(REMOVE_PAIRING, step="pair-remove", then=shows(REMOVE_CONFIRM), timeout=20)
        hits = d.find_in(REMOVE_CONFIRM, d.tree())
        d._act(d.s.press, hits[-1])
        d.must(either(shows(STATE_ENDED), shows(STATE_NONE)), 60, step="pair-removed")

    # ---- a request to a proven contact

    def request(self, name):
        """<name>'s contact page › Pair › Send request (offered when <name>'s address is proven); False when
        the app opened the invite page instead (not proven)."""
        d = self.d
        self.open_contact(name)
        d.press(CONTACT_PAIR, step="pair-request-open", then=either(shows(REQUEST_SEND), shows(PAIR_YOUR)), timeout=60)
        if not d.seen(REQUEST_SEND):
            self.log("%s: no request offered for %s (the invite page opened)" % (self.ui.which, name))
            return False
        d.press(REQUEST_SEND, step="pair-request-send", then=gone(REQUEST_SEND), timeout=60)
        return True

    def accept_request(self, timeout=300):
        """Contacts › Pair requests · n › Pair (the newest)."""
        d = self.d
        self.ui.nav(NAV_CONTACTS)
        d.must(shows(REQUESTS_ROW), timeout, step="pair-request-seen")
        with self._own_not_now():
            d.press(REQUESTS_ROW, step="pair-requests-open", then=shows(REQUESTS_PAIR), timeout=20)
            hits = d.find_in(REQUESTS_PAIR, d.tree())
            d._act(d.s.press, hits[-1])

    # ---- an invoice between paired contacts

    def issue_invoice(self, name, amount):
        """<name>'s contact page › Issue an invoice (to <name>) › Amount › Send invoice. -> (ok, why)."""
        d = self.d
        self.open_contact(name)
        d.press(INV_ISSUE, step="inv-issue", then=shows(INV_AMOUNT), timeout=30)
        d.fill(INV_AMOUNT, amount, step="inv-amount")
        d.shot("inv-filled")
        d.press(INV_SEND, step="inv-send", then=either(shows(INV_SENT), shows(INV_FAILED)), timeout=120)
        d.shot("inv-sent")
        failed = d.find_in(INV_FAILED, d.tree())
        if failed:
            return False, "the app says: %s" % failed[0].name.replace("\n", " ")[:200]
        return True, "invoice for %s EPIC sent to %s" % (amount, name)

    def pay_invoice(self, password, timeout=300):
        """Invoices › Pay › Review (the newest) › Approve and pay › the wallet password › Pay."""
        d = self.d
        self.ui.nav(NAV_INVOICES)
        if d.wait(shows(INV_TAB_PAY), 10):
            d.press(INV_TAB_PAY, step="inv-pay-tab", timeout=20)
        d.must(shows(INV_REVIEW), timeout, step="inv-received")
        d.press(INV_REVIEW, step="inv-review", then=shows(INV_APPROVE), timeout=30)
        d.shot("inv-review")
        d.press(INV_APPROVE, step="inv-approve", then=shows(INV_PASSWORD), timeout=60)
        d.fill(INV_PASSWORD, password, step="inv-password")
        hits = d.find_in(INV_PAY, d.tree())
        d._act(d.s.press, hits[-1])  # the dialog's Pay
        d.must(either(shows(INV_PAID), gone(INV_PASSWORD)), 120, step="inv-paid")
        d.shot("inv-paid")


def words_in(text):
    """The words a word-tile group's name reads: its label line dropped, numbers dropped."""
    lines = [x for x in re.split(r"[\n,]+", text or "") if x.strip()]
    if lines and re.match(r"(?i)the four words", lines[0].strip()):
        lines = lines[1:]
    words = []
    for x in lines:
        words += [w for w in WORD_RX.findall(x.lower())]
    return words


def invite_link(message):
    """The link in the app's Pair with me … message (the whole message is pasted; the app finds it)."""
    m = re.search(r"https?://\S+|\b\w+:\S+", message or "")
    return m.group(0) if m else None
