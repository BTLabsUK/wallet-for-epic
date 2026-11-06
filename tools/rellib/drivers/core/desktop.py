# SPDX-License-Identifier: Apache-2.0
"""The desktop app's G4 steps (app/lib/src/desktop), written once on targets for Linux and Windows.

Every step names its control by Target (an id from trust_ids.json, the build's own ARB text, literal
names for releases before a key) and the state it must reach; the Driver finds, presses, waits and
recovers. Nothing here reads tree order or coordinates. A setting is found on whichever Settings page
holds it: the pages a release is known to use first, then every page the section list shows, so a
setting moved to another page is still found.

Secrets: the password is made here, the recovery phrase read off the reveal screen; both go back to
the lane (saved state, never a log). Screens that show them are never sent to a model (recover.py).
A phrase restored is typed word by word as a secret (Surface.set_text) with the driver hushed: no
screenshot, tree dump or model while words are on screen, and no word in any line.
"""
import calendar
import re
import secrets as _secrets
import time

from . import targets as tg
from . import breaks
from .driver import Expect, Goal, either, gone, shows, where
from .faults import HarnessFault, InfraFault, ProductFault

T = tg.T

# ---- targets (ids: app/lib/src/desktop/trust_ids.dart; keys newest first; names for older builds)

WELCOME_CREATE = T("g4.welcome.create", keys=("deskOnbWelcomeCreate", "firstRunCreate"), names=("Create a new wallet",))
WELCOME_RESTORE = T("g4.welcome.restore", names=("Restore from phrase",))
DEEP_END = T("g4.level.stop.3", keys=("lvPickStopThree",), names=("Deep end",))
CREATE_TITLE = T("g4.create.title", role="text", keys=("deskOnbCreateTitle",), names=("Create wallet",), secret=True)
PASSWORD = T("g4.account.password", role="text_field", names=("re:.*",), secret=True)
REVEAL = T("g4.create.reveal", keys=("deskOnbCreateReveal",), names=("Reveal phrase",), secret=True)
WRITTEN = T("g4.create.written", role="checkbox", keys=("deskOnbCreateWritten",), names=("re:i have written down.*",),
            match="starts", secret=True)
CONTINUE = T("g4.create.continue", keys=("commonContinue",), names=("Continue",))
SETUP_SKIP = T("g4.setup.skip", keys=("deskSetupSkip",), names=("Skip setup",))

# restore from phrase (26.10.25 and 26.10.26: restore_screen.dart, phrase_grid.dart). The word fields are
# "Word N" (deskOnbWordN, Desktop._word); the words step's button is RESTORE_NEXT. Ids g4.restore.* from
# the release with restore from a height (trust_ids.dart); older builds are found by label.
RESTORE_NEXT = T("g4.restore.next", keys=("commonContinue",), names=("Continue",))
RESTORE_SUBMIT = T("g4.restore.continue", keys=("deskOnbRestoreSide",), names=("Restore wallet",), match="exact", secret=True)
# The start choice (restore_screen.dart, start_date.dart): a mainnet restore scans from January 2025 unless the
# start is changed. Built to the planned final design of the scan-start block (feat/restore-start-ui, same on
# phone and desktop): a button "Change the start" opens the Month | Block height panel; "Scan from the start"
# sits behind the info button "Scan start". The names after the keys are main's interim texts (a link, no info
# button). A rename is a change to these three targets only.
# role "other": on 26.10.26 the link is an unnamed node with its label a text of its own on Linux;
# restoreStartFromMonthLink is its key, so the link is found in the build's language (Polish on the rigs)
RESTORE_FROM_OPEN = T("g4.restore.start", role="other", keys=("scanStartChange", "restoreStartFromMonthLink"),
                      names=("Change the start", "Start from a month or height"), match="exact", secret=True)
RESTORE_INFO = T("g4.restore.info", role="button", keys=("scanStartInfoTitle",), names=("Scan start",),
                 match="exact", secret=True)
RESTORE_FROM_START = T("g4.restore.fromStart", role="button", keys=("restoreScanFromStart",),
                       names=("Scan from the start",), match="exact", secret=True)
RESTORE_BY_HEIGHT = T("g4.restore.by.height", keys=("restoreStartByHeight",), names=("Block height",), match="exact",
                      secret=True)
RESTORE_HEIGHT = T("g4.restore.height", role="text_field", keys=("deskOnbRestoreFromLabel",), names=("Start from block",),
                   match="starts", secret=True)
RESTORE_RESTORING = T("g4.restore.restoring", role="text", keys=("deskOnbRestoreRestoring",), names=("Restoring the wallet",),
                      secret=True)
RESTORE_FAILED = T("g4.restore.failed", role="text", keys=("deskOnbRestoreNotRestored",), names=("Wallet not restored",),
                   secret=True)
# mainnet block 1's time and the margin app/lib/src/start_month.dart keeps: a birth month as a height
MAINNET_BLOCK_ONE_UNIX, RESTORE_MARGIN_BLOCKS = 1567476608, 2 * 24 * 60
UNLOCK_TITLE = T("g4.unlock.title", role="text", keys=("deskOnbUnlockTitle",), names=("Unlock wallet",))
UNLOCK = T("g4.unlock.submit", keys=("deskOnbUnlockButton",), names=("Unlock",))
UNLOCK_WRONG = T("g4.unlock.wrong", role="text", keys=("deskOnbUnlockWrong",), match="starts")
TOUR_SKIP = T("g4.tour.skip", keys=("deskTourSkip",), names=("Skip tour",))
LAST_SESSION = T("g4.lastsession.notnow", keys=("deskLastSessionNotNow",), names=("Not now",))
LEVEL_PICK = T("g4.level.title", role="text", keys=("lvPickTitle",), names=("Pick your view",))
MAIN_NAV = T("g4.nav", role="other", keys=("deskShellMainNav",), names=("Main navigation",), match="exact")


def NAV(section, key):
    return T("g4.nav.%s" % section, keys=(key,), names=(section.capitalize(),), match="exact")


NAV_OVERVIEW = NAV("overview", "deskShellNavOverview")
NAV_SEND = NAV("send", "deskShellNavSend")
NAV_RECEIVE = NAV("receive", "deskShellNavReceive")
NAV_ACTIVITY = NAV("activity", "deskShellNavActivity")
NAV_SETTINGS = NAV("settings", "deskShellNavSettings")
SETTINGS_BACK = T("g4.settings.back", keys=("deskSetFrameBack",), names=("← Wallet", "Wallet"))

# Settings section entries, by the page's key; the first that the build has wins
SECTION = {
    "node": T("g4.settings.section.node", keys=("deskSetFrameNode",), names=("Node",), match="exact"),
    "payments": T("g4.settings.section.payments", keys=("deskSetSecPayments", "deskSetFrameTransactions"),
                  names=("Payments", "Transactions", "Receiving"), match="exact"),
    "wallet": T("g4.settings.section.wallet", keys=("deskSetSecWallet", "deskSetFrameThisWallet"),
                names=("Wallet", "This wallet"), match="exact"),
    "appearance": T("g4.settings.section.appearance", keys=("deskSetFrameAppearance",), names=("Appearance",), match="exact"),
    "advanced": T("g4.settings.section.advanced", keys=("deskSetFrameAdvanced",), names=("Advanced",), match="exact"),
    "about": T("g4.settings.section.about", keys=("deskSetFrameAbout",), names=("About",), match="exact"),
    "privacy": T("g4.settings.section.privacy", keys=("settingsSectionNetworkPrivacy", "deskSetFramePrivacy"),
                 names=("Network & privacy", "Privacy"), match="exact"),
}
# Settings › Contacts leaves Settings for the Contacts page: not a section, so not in SECTION
SETTINGS_CONTACTS = T("g4.settings.section.contacts", keys=("deskShellNavContacts",), names=("Contacts",), match="exact")
CONTACTS_ADD = T("g4.contacts.add", keys=("deskConAdd",), names=("Add contact",), match="exact")
# every section a release has had (for "a setting moved": the pages are walked when the known ones miss it)
ALL_SECTIONS = ("Node", "Transactions", "Receiving", "Privacy", "Appearance", "This wallet", "All wallets",
                "Advanced", "About", "Wallet", "Security", "Payments", "Network & privacy", "Wallets", "Files & logs")

THEME = {t: T("g4.appearance.theme.%s" % t.lower(), keys=("deskSetAppear%s" % t,), names=(t,), match="exact")
         for t in ("System", "Dark", "Light")}
LABEL_FIELD = T("g4.wallet.label", role="text_field", keys=("deskSetAcctLabel",), names=("Name",), match="exact")
LABEL_SAVE = T("g4.wallet.label.save", keys=("deskSetAcctSaveLabel",), names=("Save label",))
CONF_FEWER = T("g4.confirmations.fewer", keys=("deskSetAdvConfirmationsFewer",), names=("Fewer confirmations",))
CONF_MORE = T("g4.confirmations.more", keys=("deskSetAdvConfirmationsMore",), names=("More confirmations",))
# the number field; up to 26.10.26 its name went on with the − button's tooltip ("Confirmations. Fewer confirmations")
CONF_FIELD = T("g4.confirmations.value", role="text_field", keys=("deskSetAdvConfirmations",), names=("Confirmations",), match="starts")
CONF_NOT_SAVED = T("g4.confirmations.not_saved", role="text", keys=("deskSetAdvConfirmationsNotSaved",), names=("Confirmations not changed",))
CONF_COUNT = T("g4.confirmations.count", role="text", keys=("deskSetAdvConfirmationsCount",), match="starts")
TECHNICAL = T("g4.advanced.technical", role="toggle", keys=("deskSetAdvTechnical",), names=("Technical details",))

NODE_PICKER = T("g4.server.node", keys=("deskSetNodeServer",), names=("Node server",), match="starts")
RELAY_PICKER = T("g4.server.epicbox", keys=("deskSetRecvEpicboxServer",), names=("Epicbox server",), match="starts")
PICKER_PAGES = {"g4.server.node": ("node",), "g4.server.epicbox": ("payments",)}
PICKER_SEARCH = T("g4.server.search", role="text_field", names=("re:.*",))
SWITCH = T("g4.server.switch", keys=("deskSendEpicboxSwitch",), names=("Switch",), match="exact")
SERVER_REFUSED = T("g4.server.refused", role="text", names=("re:.*(no answer from this server|nothing added|not a node).*",),
                   match="contains")

RECEIVE_ADDRESS = T("g4.receive.address", role="text", keys=("deskRecvEpicboxAddress",), names=("Epicbox address",),
                    match="starts")

SEND_METHOD_EPICBOX = T("g4.send.method.epicbox", names=("Epicbox",), match="exact")
SEND_METHOD_LINK = T("g4.send.method.link", names=("Link",), match="exact")
SEND_ANOTHER = T("g4.send.another", keys=("deskSendNewSend",), names=("Send another",))
SEND_TO = T("g4.send.to", role="text_field", keys=("deskSendToSem", "deskSendTo"), names=("Recipient", "To"), match="starts")
SEND_VIA_PAIRING = T("g4.send.viapairing", role="toggle", keys=("sendViaMailbox",),
                     names=("Send through the pairing",))  # starts on for a paired contact
VIA_PAIRING_WAIT_S = 4    # for the pairing switch after To is filled
SEND_AMOUNT = T("g4.send.amount", role="text_field", keys=("deskSendAmountSem", "deskSendAmount"), names=("Amount",),
                match="starts")
SEND_MAX = T("g4.send.max", keys=("deskSendAllButton",), names=("Max",), match="exact")
SEND_REVIEW = T("g4.send.review", keys=("deskSendReview",), names=("Review send", "Review"), match="exact")
SEND_REVIEW_TITLE = T("g4.send.review.title", role="text", keys=("deskSendReviewTitle",), names=("Check and send",),
                      match="contains")
SEND_PASSWORD = T("g4.send.password", role="text_field", keys=("deskSendPassword",), names=("Password",), secret=True)
SEND_CONFIRM = T("g4.send.confirm", keys=("deskSendConfirm",), names=(r"re:send [\d.,]+ epic",), match="exact")
SEND_FAILED = T("g4.send.failed", role="text", keys=("deskSendFailedTitle", "deskSendNoAnswer"),
                names=("re:.*(send failed|not sent).*",), match="contains")
SEND_DONE = T("g4.send.done", role="text", keys=("deskSendDoneViaEpicbox", "deskSendDoneViaDirect", "deskSendHintSent"),
              match="starts")

# Tor (26.11.0): Settings › Network & privacy › Connection mode, radio rows adv-mode-<name> (the Tor switch
# is gone; Tor only is the one whole-wallet Tor control). The rail's and the title bar's Tor and Epicbox
# status are not in AT-SPI on Linux (26.11.0), so the UI read is Settings: Tor only checked there, and
# Epicbox's state line on the Transactions page under its server picker, "Connected · <host>, over Tor"
# (methodStateLine: Epicbox through Tor, subscribed) once Tor is up.
MODE_TOR_ONLY = T("g4.privacy.mode.toronly", role="checkbox", keys=("advModeTorOnly",), names=("Tor only",), match="starts")
MODE_NORMAL = T("g4.privacy.mode.standard", role="checkbox", keys=("advModeStandard",), names=("Normal",), match="starts")
# one line of a node's name: on Linux the line is a line of its group's text ("Epicbox\nReceiving\n
# Connected · epicbox.stackwallet.com, over Tor\nStart with the wallet")
EPICBOX_LINE = re.compile(
    r"(connected|connecting|waiting for tor|not connected|not answering|slow|off|blocked) · [\w.:-]+(, over tor)?")
EPICBOX_UP = "connected"   # ShownState.connected (netStatusConnected): Epicbox subscribed
OVER_TOR = ", over tor"    # deskKitMethodOverTor: "{host}, over Tor"
TOR_START_S = 240       # a Tor start, each of the two tries (before REL_TRUST_SLOW)

ADDRESS_RX = re.compile(r"\b([1-9A-HJ-NP-Za-km-z]{48,56})(@[\w.:-]+)?")


def phrase_words(names):
    """The revealed phrase off the accessibility names: each grid cell's number then its word ("1",
    "abandon", "2", …, or "1 abandon"), in number order; else the words after a "24"/"12" word-count
    label (builds before 26.10.25). Never logged."""
    words, want = [], 1
    for i, name in enumerate(names):
        m = re.fullmatch(r"(\d{1,2})\.? ?([a-z]{3,12})?", name or "")
        if not m or int(m.group(1)) != want:
            continue
        w = m.group(2) or (names[i + 1] if i + 1 < len(names) else "")
        if re.fullmatch(r"[a-z]{3,12}", w or ""):
            words.append(w)
            want += 1
    if len(words) in (12, 24):
        return words
    for n in (24, 12):
        if str(n) in names:
            i = names.index(str(n))
            return [w for w in names[i + 1:] if re.fullmatch(r"[a-z]{3,12}", w)][:n]
    return []


def birth_height(birth):
    """The height a restore starts scanning at: the birth height, else the first of the birth month as
    the app maps it (start_month.dart: from block 1 at 60 s a block, less two days); None: the whole chain."""
    birth = birth or {}
    if birth.get("height"):
        return int(birth["height"])
    m = re.fullmatch(r"(\d{4})-(\d{2})", birth.get("month") or "")
    if not m:
        return None
    seconds = calendar.timegm((int(m.group(1)), int(m.group(2)), 1, 0, 0, 0)) - MAINNET_BLOCK_ONE_UNIX
    return max(1, 1 + seconds // 60 - RESTORE_MARGIN_BLOCKS)


class Desktop:
    """The recipe on one running app. `which` is previous | candidate."""

    def __init__(self, driver, which, log=print):
        self.d, self.which, self.log = driver, which, log
        self.password = self.phrase = None
        d = self.d
        d.obstacles += [(TOUR_SKIP, "the first-run tour"), (SETUP_SKIP, "the setup assistant"),
                        (LAST_SESSION, "the last-session notice (left unsent)")]
        d.not_folds |= self.section_names()   # Settings › Advanced is a page, not a folded section
        d.reopen = self._reopen
        self._picking = None   # (picker, typed) while a server is chosen: the stale-picker rule's context

    # ---- helpers

    def _passwords(self, tree):
        return [n for n in tree if n.role == "text_field" and "password" in n.states]

    def _unflagged_password(self):
        """A text field named by the build's password label that is not a password to assistive tech is
        the app's fault. On Windows the engine sets no IsPassword: the surface knows a password field by
        its show/hide button right after it, and 26.10.26 b1e4540's Semantics ids put that button around
        the field instead. The field is empty here (nothing typed yet), so its tree is saved."""
        d = self.d
        tree = d.tree()
        words = {tg._norm(w) for w in (d.labels.text("deskOnbStepPassword"), "Password") if w}
        named = [n for n in tree if n.role == "text_field" and "password" not in n.states
                 and any(w in tg._norm(n.name.split("\n")[0]) for w in words)]
        if named:
            shot = d.shot("fail-" + d.step)
            d.dump("fail-" + d.step, tree)
            raise ProductFault(d.step, "password field not exposed as a password to assistive tech: %s"
                               % ", ".join(n.brief() for n in named), shot)

    def _fill_passwords(self, step, want_at_least=1, submit=None):
        """Types the password into every password field on screen (create: password and confirm,
        unlock: one); order does not matter, each gets the same text. With `submit`, the form's button
        must turn enabled; a field that lost keys while the screen settled is typed again (twice at most)."""
        d = self.d
        d.step = step
        for attempt in range(3):
            fields = d.wait(Expect("%d password field(s)" % want_at_least,
                                   lambda dd, tree: (lambda f: f if len(f) >= want_at_least else None)(self._passwords(tree))), 60)
            if not fields:
                self._unflagged_password()
                d.harness("no password field (wanted %d)" % want_at_least)
            for n in fields:
                d._act(d.s.set_text, n, self.password, True)
            if submit is None or d.wait(Expect("%s enabled" % submit, lambda dd, tree: any(
                    n.enabled and n.role == "button" for n in dd.find_in(submit, tree))), 4):
                return len(fields)
            self.log("%s: the form's button stays disabled after typing; typing again (%d)" % (step, attempt + 1))
        d.harness("the password form does not take the password: %s stays disabled" % submit)

    def _home(self):
        return either(shows(MAIN_NAV), shows(NAV_OVERVIEW))

    def in_settings(self, tree=None):
        tree = tree if tree is not None else self.d.tree()
        names = {tg._norm(n.name.split("\n")[0]) for n in tree if n.role in ("button", "tab", "row", "link")}
        if len(names & self.section_names()) >= 2:
            return True
        # a narrow window shows one section at a time, with no list: the search field is on every Settings page
        return any(self._settings_search(n) for n in tree)

    def _settings_search(self, n):
        hint = tg._norm(self.d.labels.text("deskSetSearchHint") or "Search settings")
        return n.role == "text_field" and tg._norm(n.name.split("\n")[0]) == hint

    def section_names(self):
        """Every section name a release has had, and this build's own (English) section names."""
        if getattr(self, "_section_names", None) is None:
            self._section_names = {tg._norm(s) for s in (*ALL_SECTIONS, *self.d.labels.localized(ALL_SECTIONS))}
        return self._section_names

    # ---- first run and unlock

    def create_wallet(self):
        """A new wallet on the welcome screen; returns {password, phrase}. The phrase is read off the
        reveal screen and only handed back."""
        d = self.d
        self.password = _secrets.token_urlsafe(16)
        d.must(shows(WELCOME_CREATE), 120, step="welcome", goal="the welcome screen with Create a new wallet")
        self._depth_dial()
        d.press(WELCOME_CREATE, step="create", then=shows(CREATE_TITLE), timeout=30)
        self._fill_passwords("create-password", 2, submit=CREATE_TITLE)
        self._create_submit()
        d.press(REVEAL, step="reveal", then=Expect("the phrase shown", lambda dd, tree: len(phrase_words([n.name for n in tree])) in (12, 24)),
                timeout=20)
        words = phrase_words([n.name for n in d.tree()])
        phrase = self.phrase = " ".join(words)
        del words
        self.log("wallet created; the phrase is kept with the lane's secrets, not printed")
        d.toggle(WRITTEN, True, step="written-down")
        d.press(CONTINUE, step="continue", then=either(shows(UNLOCK_TITLE), self._home(), shows(SETUP_SKIP)), timeout=120)
        self.open_wallet({"password": self.password}, after_update=False)
        return {"password": self.password, "phrase": phrase}

    def restore_wallet(self, phrase, birth=None):
        """The wallet of `phrase` restored on the welcome screen (Restore from phrase): the words typed one
        field at a time, a new password, the scan from the birth height (`birth`: {"height", "month"}),
        then to the wallet's Overview. Returns {password}. The words are never logged, shot or dumped."""
        d = self.d
        words = phrase.split()
        if len(words) not in (12, 15, 18, 21, 24):
            raise HarnessFault("restore", "the lane's phrase has %d words" % len(words))
        self.password = _secrets.token_urlsafe(16)
        d.must(shows(WELCOME_RESTORE), 120, step="welcome", goal="the welcome screen with Restore from phrase")
        self._depth_dial()
        d.press(WELCOME_RESTORE, step="restore", then=shows(self._word(1)), timeout=30)
        with d.hush():
            self._type_words(words)
            del words
            d.press(RESTORE_NEXT, step="restore-words", timeout=60,
                    then=Expect("the password step", lambda dd, tree: len(self._passwords(tree)) >= 2))
        self.log("restore: the phrase took (%d words); the password step" % len(phrase.split()))
        self._fill_passwords("restore-password", 2, submit=RESTORE_SUBMIT)
        height = birth_height(birth)
        if height:
            self._start_from(height)
        else:
            self._scan_from_start()
        d.press(RESTORE_SUBMIT, step="restore-submit", timeout=60,
                then=either(shows(RESTORE_RESTORING), shows(RESTORE_FAILED), shows(SETUP_SKIP), shows(UNLOCK_TITLE), self._home()))
        d.step = "restoring"
        end = time.time() + 1800
        while d.wait(shows(RESTORE_RESTORING), 2, dismiss=False) and not d.find_in(RESTORE_FAILED, d.tree()):
            if time.time() > end:
                d.harness("the restore still runs after 30 min")
            time.sleep(5)
        failed = d.find_in(RESTORE_FAILED, d.tree())
        if failed:
            raise ProductFault("restore_ok", "the app did not restore the wallet: %s" % " | ".join(
                n.name.replace("\n", " ")[:160] for n in d.tree() if n.role == "text")[:400], d.shot("restore-failed"))
        self.log("restore: the wallet was restored; opening it")
        self.open_wallet({"password": self.password}, after_update=False)
        return {"password": self.password}

    def _word(self, i):
        """Field `i` (from 1) of the phrase grid: "Word {number}" in the build's language, or in English."""
        texts = {self.d.labels.text("deskOnbWordN"), "Word {number}"} - {None}
        pats = tuple(sorted("re:(?:.* )?%s(?: .*)?" % re.escape(tg._norm(t)).replace(re.escape("{number}"), str(i))
                            for t in texts))
        return T("g4.restore.phrase" if i == 1 else "g4.restore.word.%d" % i, role="text_field", names=pats, match="exact", secret=True)

    def _type_words(self, words):
        """Each word into its own field, checked against what the field then holds (a key lost on the way
        is typed again); the grid's button turns enabled when the phrase checks out. Called hushed."""
        d = self.d
        for i, w in enumerate(words, 1):
            t = self._word(i)
            d.step = "restore-word-%d" % i
            for attempt in range(3):
                node = d.locate(t, 20)
                d._act(d.s.set_text, node, w, True)
                took = d.wait(Expect("word %d held" % i, lambda dd, tree, t=t, w=w: next(
                    (n for n in dd.find_in(t, tree) if n.value is None or n.value.strip().lower() == w), None)), 5)
                if took:
                    break
                self.log("restore: field %d does not hold the word typed (try %d)" % (i, attempt + 1))
            else:
                d.harness("field %d of the phrase grid does not take the word typed" % i)
            if i < len(words):
                # Space commits the word and moves to the next field, as a person typing does: AT-SPI's
                # focus reaches the first field only (26.10.25 on Linux kept the keyboard in field 1)
                d.s.key("space")
        ready = Expect("Continue enabled", lambda dd, tree: any(n.enabled and n.role == "button" for n in dd.find_in(RESTORE_NEXT, tree)))
        if not d.wait(ready, 5):
            d.s.key("tab")   # commits the last field (its word checked), as a person moving on does
            d.must(ready, 30, step="restore-words", goal="the phrase checked: Continue enabled")

    def _start_from(self, height):
        """Start from a month or height › Block height (mainnet offers a month first) › the birth height."""
        d = self.d
        opened = either(shows(RESTORE_BY_HEIGHT), shows(RESTORE_HEIGHT))
        if not d.wait(opened, 2, dismiss=False):
            d.press(RESTORE_FROM_OPEN, step="restore-from", then=opened, timeout=20)
        by = d.wait(shows(RESTORE_BY_HEIGHT), 5)
        if by:
            d._act(d.s.press, by)
        d.must(shows(RESTORE_HEIGHT), 20, step="restore-from-height", goal="the Start from block field")
        d.fill(RESTORE_HEIGHT, str(height), step="restore-height")
        self.log("restore: scanning from block %d" % height)

    def _scan_from_start(self):
        """No birth: Scan from the start (block 0); doing nothing would scan from January 2025."""
        d = self.d
        if not d.wait(shows(RESTORE_FROM_START), 3, dismiss=False) and d.seen(RESTORE_INFO):
            d.press(RESTORE_INFO, step="restore-start-info", then=shows(RESTORE_FROM_START), timeout=20)
        if not d.wait(shows(RESTORE_FROM_START), 3, dismiss=False):  # a test network scans from block 0: none offered
            self.log("restore: no birth height; no Scan from the start offered")
            return
        d.press(RESTORE_FROM_START, step="restore-from-start", then=gone(RESTORE_FROM_START), timeout=20)
        self.log("restore: no birth height: Scan from the start (the whole chain)")

    def _create_submit(self):
        """The create form's button shares the title's text; Enter in the confirm field submits it."""
        d = self.d
        d.step = "create-submit"
        d.trail.append("create-submit")
        d.s.key("enter")
        if d.wait(shows(REVEAL), 180):
            return
        btn = [n for n in d.find_in(CREATE_TITLE, d.tree()) if n.role == "button"]
        if btn:
            d._act(d.s.press, btn[0])
        d.must(shows(REVEAL), 180, goal="the recovery phrase screen after creating the wallet")

    def _depth_dial(self):
        """A build with wallet levels asks the depth on a fresh install: Deep end (level 3), what a
        release before levels shows. Nothing on a build without the dial."""
        d = self.d
        n = d.seen(DEEP_END)
        if n is None:
            return
        if "checked" in n.states or "selected" in n.states:
            self.log("SKIP view-deep-end: already done")
            return
        if True:
            d._act(d.s.press, n)
            time.sleep(1)
        self.log("depth dial: Deep end (level 3)")

    def open_wallet(self, secrets, after_update=False):
        """From wherever the app opened to the wallet's Overview: unlock with the password; after an
        update the candidate must find the wallet (no welcome, no depth question)."""
        d = self.d
        self.password = secrets.get("password") or self.password
        screens = {"unlock": shows(UNLOCK_TITLE), "home": self._home(), "welcome": shows(WELCOME_CREATE),
                   "levels": shows(LEVEL_PICK)}
        at = d.must(where(screens), 180, step="open-%s" % self.which, goal="the Unlock screen or the wallet")
        d.shot("%s-first" % self.which)
        if after_update and at in ("welcome", "levels"):
            raise ProductFault("wallet_opens", "after the update the candidate shows %s: it found no wallet" % (
                "'Create a new wallet'" if at == "welcome" else "the depth question of a fresh install"), d.shot("cand-no-wallet"))
        if at == "welcome":
            d.harness("the previous release shows the welcome screen where a wallet was expected")
        if at in ("unlock", "levels"):
            self.unlock()
        d.must(self._home(), 180, step="home-%s" % self.which, goal="the wallet's main screen (Overview)")
        self.log("%s: wallet open" % self.which)

    def ensure_unlocked(self):
        """The wallet unlocked (auto-lock can close it while the lane waits for a payment); True when
        it had locked itself and was unlocked here (the page it was on is gone)."""
        if self.d.seen(UNLOCK_TITLE):
            self.log("the wallet locked itself (auto-lock): unlocking again")
            self.unlock()
            return True
        return False

    def poke(self):
        """Shift through the keyboard: the app's idle time starts again. Presses through AT-SPI are
        neither a key nor the mouse to auto-lock, so a wallet the lane works only through them
        locks itself after its idle time (26.11.3 and 26.11.4 run-2: the Pair page's Change)."""
        self.d.s.key("shift")

    def unlock(self):
        d = self.d
        d.must(shows(UNLOCK_TITLE), 120, step="unlock")
        self._fill_passwords("unlock-password", 1)
        r = d.press(UNLOCK, step="unlock", then=either(self._home(), shows(UNLOCK_WRONG)), timeout=180)
        if d.find_in(UNLOCK_WRONG, d.tree()):
            raise ProductFault("unlock", "the app says the password is wrong (it is the one the wallet was made with)",
                               d.shot("unlock-wrong"))
        return r

    # ---- navigation

    def nav(self, target):
        """A page of the main navigation; from Settings (a whole-window page from 26.10.25) Esc first."""
        d = self.d
        if d.seen(UNLOCK_TITLE):
            self.log("the wallet locked itself (auto-lock): unlocking again")
            self.unlock()
        for _ in range(3):
            if d.seen(target) or not self.in_settings():
                break
            d.s.key("escape")
            d.wait(gone(SETTINGS_BACK), 3)
        d.press(target, step="nav-%s" % target.id.rsplit(".", 1)[-1], then=Expect("page %s" % target, lambda dd, tree: True),
                timeout=30)
        time.sleep(0.8)

    def settings(self):
        d = self.d
        if self.in_settings():
            return
        self.nav(NAV_SETTINGS)
        d.must(Expect("Settings sections", lambda dd, tree: self.in_settings(tree)), 30, step="settings")

    def section(self, key_or_name, _again=False):
        """Settings › a section, by its target (SECTION key) or a literal name. False when the build
        lists no such section."""
        d = self.d
        self.settings()
        t = SECTION.get(key_or_name) or T("g4.settings.section.%s" % tg._norm(key_or_name).replace(" ", "_"),
                                          names=(key_or_name,), match="exact")
        if not d.wait(shows(t), 4):
            if not self._open_section_list():
                return False
            if not d.wait(shows(t), 4):
                if _again:
                    return False
                # the open list shows only its rows inside the window (UIA drops the rest) and a scrolled
                # page moves it: once more from a fresh Settings page
                self.log("Settings › %s: not in the open section list; opening Settings again" % key_or_name)
                d.s.key("escape")
                time.sleep(0.8)
                self.nav(NAV_OVERVIEW)
                return self.section(key_or_name, _again=True)
        # 26.10.25 names the back button "Wallet" too: a press that leaves Settings was the wrong one
        # the one that stayed is tried first next time
        first = getattr(self, "_section_hit", {}).get(t.id, 0)
        for k in [first] + [i for i in range(3) if i != first]:
            hits = d.find_in(t, d.tree())
            if k >= len(hits):
                continue
            d._act(d.s.press, hits[k])
            time.sleep(1)
            if d.wait(Expect("still in Settings", lambda dd, tree: self.in_settings(tree)), 4, dismiss=False):
                self._section_hit = dict(getattr(self, "_section_hit", {}), **{t.id: k})
                return True
            self.log("Settings › %s: %s left Settings; trying the next one" % (key_or_name, hits[k].brief()))
            self.settings()
        d.harness("Settings › %s: no control of that name opens the section" % key_or_name)

    def contacts(self):
        """Settings › Contacts, until the Contacts page shows (its Add contact), then back to Overview. A build
        before the entry has Contacts only in the sidebar: logged, back to Overview."""
        d = self.d
        self.settings()
        if not d.wait(shows(SETTINGS_CONTACTS), 4) and not (self._open_section_list() and d.wait(shows(SETTINGS_CONTACTS), 4)):
            self.log("no Contacts in Settings: a build before the entry")
            self.nav(NAV_OVERVIEW)
            return False
        d.press(SETTINGS_CONTACTS, step="settings-contacts", then=shows(CONTACTS_ADD), timeout=20)
        self.log("Settings › Contacts: the Contacts page")
        self.nav(NAV_OVERVIEW)
        return True

    def _open_section_list(self):
        """A narrow window folds the section list into one selector: a button named like the open section,
        holding it as its value. Pressing it lists the sections again."""
        tree = self.d.tree()
        sel = [n for n in tree if n.role == "button" and n.value and tg._norm(n.name.split("\n")[0]) == tg._norm(n.value)
               and tg._norm(n.value) in self.section_names()]
        if not sel:
            return False
        self.log("Settings: the section list is folded into %s; opening it" % sel[0].brief())
        self.d._act(self.d.s.press, sel[0])
        time.sleep(0.8)
        return True

    def find_setting(self, target, pages, what):
        """Opens the Settings page that holds `target`: the known `pages` first, then every section
        the list shows (a setting moved to another page is found there, and the log says so)."""
        d = self.d
        self.settings()
        kept = pages
        if breaks.moved(target.id):
            self.log("BREAK: %s taken as moved; the recipe's pages %s are not tried first" % (what, ", ".join(pages)))
            pages = ()
        elif d.seen(target):
            return True
        tried = []
        for p in pages:
            if self.section(p):
                tried.append(p)
                if d.wait(shows(target), 3):
                    return True
                d.step = "find-%s" % target.id
                if d.untangle(target):   # folded, scrolled off, a dialog in the way: the known-trouble rules first
                    return True
                # renamed on the page the recipe expects: the model's pick, before every section is searched
                if d.rec.pick(target, d.tree(), step="find-%s" % target.id, texts=d.texts(target)):
                    return True
        d.step = "find-%s" % target.id
        if d.untangle(target):   # folded, scrolled off, a dialog in the way: the known-trouble rules first
            return True
        tree = d.tree()
        if self._open_section_list():   # a narrow window: the sections are listed once the selector is open
            tree = d.tree()
        listed = list(dict.fromkeys(n.name.split("\n")[0].strip() for n in tree
                                    if n.role in ("button", "tab", "row") and tg._norm(n.name.split("\n")[0]) in self.section_names()))
        for name in listed:
            if name in tried:
                continue
            if self.section(name) and d.wait(shows(target), 3):
                self.log("%s found under Settings › %s (not where this release kept it: %s)" % (what, name, ", ".join(kept)))
                d.rec.moved("find-%s" % target.id, target, name, kept)
                return True
        n = d.rec.pick(target, d.tree(), step="find-%s" % target.id, texts=d.texts(target))
        if n:
            return True
        d.harness("%s not found under Settings (sections %s%s)" % (what, ", ".join(tried + listed) or "none", d._tried_text()))

    def leave_settings(self):
        d = self.d
        for _ in range(3):
            if not self.in_settings():
                return
            d.s.key("escape")
            time.sleep(0.8)

    # ---- set up on the previous release

    def set_servers(self, node, custom_node, relay, custom_relay):
        """Adds a server of the user's own and picks the one in use, for the node and for Epicbox."""
        node_entry = re.sub(r"^https?://", "", node).rstrip("/")
        self._view_deep_end()
        self.find_setting(NODE_PICKER, ("node",), "the node picker")
        self.use_server(NODE_PICKER, "http://%s" % custom_node, custom_node, use=False)
        self.use_server(NODE_PICKER, node, node_entry, use=True)
        self.log("node: %s added, %s in use" % (custom_node, node_entry))
        self.d.shot("%s-node" % self.which)
        self.find_setting(RELAY_PICKER, ("payments",), "the Epicbox picker")
        self.use_server(RELAY_PICKER, custom_relay, custom_relay, use=False)
        self.use_server(RELAY_PICKER, relay, relay, use=True)
        self.log("Epicbox: %s added, %s in use" % (custom_relay, relay))
        self.d.shot("%s-relay" % self.which)

    def use_servers(self, node, relay):
        """The live-servers phase (core/lane.py): a public node and relay in use, through the same pickers
        as set_servers; the wallet's own servers stay listed."""
        self._view_deep_end()
        self.find_setting(NODE_PICKER, ("node",), "the node picker")
        self.use_server(NODE_PICKER, node, re.sub(r"^https?://", "", node).rstrip("/"), use=True)
        self.find_setting(RELAY_PICKER, ("payments",), "the Epicbox picker")
        self.use_server(RELAY_PICKER, relay, relay, use=True)
        self.log("live servers in use: node %s, Epicbox %s" % (node, relay))
        self.d.shot("%s-live-servers" % self.which)

    def _view_deep_end(self):
        """A release with levels opens a new install in the basic view, where Settings hides Node and
        more: Settings › Advanced › View › Deep end (level 3). Nothing on a build without levels."""
        d = self.d
        if not self.section("advanced"):
            return
        n = d.wait(shows(DEEP_END), 3)
        if not n:
            return
        if "checked" in n.states or "selected" in n.states:
            self.log("SKIP view-deep-end: already done")
            return
        d._act(d.s.press, n)
        d.wait(Expect("Deep end chosen", lambda dd, tree: any(("checked" in x.states or "selected" in x.states)
                                                              for x in dd.find_in(DEEP_END, tree))), 10)
        self.log("Settings › Advanced › View: Deep end")

    # ---- Tor (the Tor lanes' after-update payments)

    def _chosen(self, target, tree):
        return any("checked" in n.states or "selected" in n.states for n in self.d.find_in(target, tree))

    def tor_state(self, tree=None):
        """{tor, epicbox, over_tor}: what the Settings page on screen shows. tor: "tor only" or "normal"
        where the Connection mode shows (None elsewhere); epicbox: the Epicbox state line's word (lower
        case, None where it does not show) and over_tor whether it says over Tor."""
        tree = tree if tree is not None else self.d.tree()
        tor = "tor only" if self._chosen(MODE_TOR_ONLY, tree) else "normal" if self._chosen(MODE_NORMAL, tree) else None
        line = next((ln for x in tree for ln in map(tg._norm, (x.name or "").split("\n")) if EPICBOX_LINE.fullmatch(ln)), None)
        return {"tor": tor, "epicbox": line.split(" · ")[0] if line else None, "over_tor": bool(line) and line.endswith(OVER_TOR)}

    def _tor_up(self, tree):
        s = self.tor_state(tree)
        return s["epicbox"] == EPICBOX_UP and s["over_tor"]

    def _epicbox_page(self):
        """Settings › Transactions, where Epicbox's state line is (under its server picker)."""
        self.find_setting(RELAY_PICKER, PICKER_PAGES[RELAY_PICKER.id], "the Epicbox state line")

    def _mode(self, target, what):
        """Settings › Network & privacy › Connection mode: `target` chosen."""
        d = self.d
        self.find_setting(target, ("privacy",), what)
        if not self._chosen(target, d.tree()):
            d.press(target, step="mode-%s" % target.id.rsplit(".", 1)[-1], timeout=20,
                    then=Expect("%s chosen" % target, lambda dd, tree: self._chosen(target, tree)))

    def tor_on(self, budget=TOR_START_S):
        """Tor only, then Epicbox's state line Connected over Tor (Settings). A goal: Tor only chosen with
        Epicbox over Tor is a SKIP. A slow start gets `budget` and one more try (Normal, then Tor only
        again); still not up is InfraFault tor. -> "skipped" | "done"."""
        d = self.d
        self.find_setting(MODE_TOR_ONLY, ("privacy",), "the Tor only connection mode")
        chosen = [self._chosen(MODE_TOR_ONLY, d.tree())]
        self._epicbox_page()

        def up():
            for attempt in (1, 2):
                self._mode(MODE_TOR_ONLY, "the Tor only connection mode")
                chosen[0] = True
                self._epicbox_page()
                if d.wait(Expect("Epicbox connected over Tor", lambda dd, tree: self._tor_up(tree)), budget):
                    self.log("Tor only: Epicbox connected over Tor (%s)" % self.tor_state())
                    return
                tree = d.tree()
                self.log("tor-on: not connected after %d s (%s)%s; Epicbox lines on screen: %s" % (
                    budget, self.tor_state(tree), "; Normal, then Tor only again" if attempt == 1 else "",
                    [n.brief()[:120] for n in tree if "epicbox" in tg._norm(n.name)][:10] or "none"))
                if attempt == 1:
                    self._mode(MODE_NORMAL, "the Normal connection mode")
            raise InfraFault("tor-on", "Tor only chosen, Epicbox not connected over Tor in %d s, twice (%s)" % (
                budget, self.tor_state()), sub="tor", shot=d.shot("tor-on"))

        r = d.achieve(Goal("tor-on", lambda tree: chosen[0] and self._tor_up(tree), up), 30)
        d.shot("%s-tor-on" % self.which)
        self.leave_settings()
        return r

    def tor_off(self):
        """Back to Normal (Tor off): the fallback legs run in the clear."""
        self._mode(MODE_NORMAL, "the Normal connection mode")
        self._epicbox_page()
        self.log("Connection mode Normal: Tor off (%s)" % self.tor_state())
        self.leave_settings()

    def tor_status(self):
        """Read on Settings: the Connection mode (Network & privacy), Epicbox's state line (Transactions),
        and up (Tor only with Epicbox Connected over Tor): what the lane records."""
        self.find_setting(MODE_TOR_ONLY, ("privacy",), "the Network & privacy page")
        tor = self.tor_state()["tor"]
        self._epicbox_page()
        s = self.tor_state()
        s["tor"] = tor
        s["up"] = tor == "tor only" and s["epicbox"] == EPICBOX_UP and s["over_tor"]
        self.leave_settings()
        return s

    def _in_use(self, picker, entry, tree=None):
        tree = tree if tree is not None else self.d.tree()
        n = self.d.seen(picker, tree)
        if not n:
            # 26.10.26 on Windows: a choice closes the picker and takes it out of the UIA tree; the
            # page's status line ("Synced: node.btlabs.uk") still names the server in use
            rx = re.compile(r":\s*%s\s*(\||,|$)" % re.escape(entry))
            return not any(self._picker_row(x.name) for x in tree) and any(
                x.role == "text" and rx.search(x.name.replace("\n", " | ")) for x in tree)
        # the server in use after the picker's label ("Node server: node.btlabs.uk"), or as its value
        rests = [re.split(r"[:\n]", n.name, maxsplit=1)[1].strip() if re.search(r"[:\n]", n.name) else "", (n.value or "").strip()]
        return any(r == entry or r.startswith(entry + ",") or r.startswith(entry + " ") for r in rests)

    def _words(self, verb):
        """The word a picker row starts with: "use" or "add" (the lanes run the apps in English)."""
        return {verb}

    def _use_row(self, entry):
        verbs = "|".join(re.escape(w) for w in sorted(self._words("use") | self._words("add")))
        return T("g4.server.use", names=(r"re:(%s) %s(,.*)?" % (verbs, re.escape(tg._norm(entry))),), match="exact")

    def _picker_row(self, name):
        n = tg._norm(name)
        return any(n.startswith(w + " ") for w in self._words("use"))

    def _listed(self, entry, tree):
        verbs = "|".join(re.escape(w) for w in sorted(self._words("use")))
        rx = re.compile(r"^(%s) %s(,|$)" % (verbs, re.escape(tg._norm(entry))))
        return any(rx.match(tg._norm(n.name)) for n in tree if n.role == "button")

    def _open_picker(self, picker):
        d = self.d
        if not d.wait(shows(picker), 3):  # a stray Escape or a dialog took the page away: back to it
            self.find_setting(picker, PICKER_PAGES[picker.id], str(picker))
        d.press(picker, step="open-%s" % picker.id, timeout=20,
                then=Expect("the picker open", lambda dd, tree: any(n.role == "text_field" and "focused" in n.states
                                                                    and not self._settings_search(n) for n in tree)
                            or any(self._picker_row(n.name) for n in tree)))

    def use_server(self, picker, typed, entry, use):
        """`entry` in use (a goal: SKIP when the picker or the status line already names it) or listed
        (use=False: typed into the picker and added, SKIP when the open picker lists it already)."""
        d = self.d
        if not use:
            return self._choose(picker, typed, entry, False)
        if breaks.selected(picker.id):
            self.log("BREAK: %s chosen in %s before its step; the step must find it done" % (entry, picker))
            self._choose(picker, typed, entry, True)
            d.wait(shows(picker), 3)
        return d.achieve(Goal("use-%s" % entry, lambda tree: self._in_use(picker, entry, tree),
                              lambda: self._choose(picker, typed, entry, True)), timeout=5)

    def _type_server(self, picker, typed):
        d = self.d
        # the picker's own field: Settings' search field is on the page too (and may hold the focus)
        search = [n for n in d.tree() if n.role == "text_field" and "password" not in n.states and not self._settings_search(n)]
        focused = [n for n in search if "focused" in n.states] or search
        if not focused:
            d.harness("the %s picker has no search field" % picker)
        d._act(d.s.set_text, focused[0], typed)

    def _reopen(self, target):
        """The stale-picker rule (Driver.untangle): a server row the open picker should show is missing,
        so the picker is closed, opened again and the server typed again."""
        if not self._picking or target.id != "g4.server.use":
            return None
        picker, typed = self._picking
        self.d.s.key("escape")
        time.sleep(0.8)
        self._open_picker(picker)
        self._type_server(picker, typed)
        return "closed %s, opened it again and typed %s" % (picker, typed)

    def _choose(self, picker, typed, entry, use, _again=False):
        """Types `typed` into the picker and presses Use/Add `entry`. Done when listed (use=False) or
        in use (use=True; a Switch offer is taken)."""
        d = self.d
        self._open_picker(picker)
        if not use and self._listed(entry, d.tree()):
            self.log("SKIP add-%s: already listed in %s" % (entry, picker))
            d.s.key("escape")
            time.sleep(0.8)
            return "skipped"
        self._type_server(picker, typed)
        if breaks.stale_once(picker.id):
            self.log("BREAK: %s rows read stale after typing %s" % (picker, typed))
            breaks.stale_rows(d.s, lambda n: n.role == "button" and re.match(r"^(use|add) ", tg._norm(n.name)))
        self._picking = (picker, typed)
        try:
            self._press_server(picker, entry, use)
        finally:
            self._picking = None
        self._settle(picker, typed, entry, use, _again)

    def _press_server(self, picker, entry, use):
        d = self.d
        for attempt in range(3):
            # an Add is answered only once the app has checked the server: listed, or "No answer ... Nothing added"
            d.press(self._use_row(entry), step="use-%s" % entry, timeout=30,
                    then=Expect("%s %s" % (entry, "in use" if use else "listed or refused"),
                                lambda dd, tree: ((self._in_use(picker, entry, tree) or dd.find_in(SWITCH, tree)
                                                   # the press closed the picker: the loop below reads the choice
                                                   or not any(self._picker_row(n.name) for n in tree)) if use else
                                                  (self._listed(entry, tree) or self._in_use(picker, entry, tree)
                                                   or dd.find_in(SERVER_REFUSED, tree)
                                                   or not any(self._picker_row(n.name) for n in tree)))))
            if use or not d.find_in(SERVER_REFUSED, d.tree()) or attempt == 2:
                break
            self.log("%s %s: no answer from the server; adding again (%d)" % (picker, entry, attempt + 1))
            time.sleep(3)

    def _settle(self, picker, typed, entry, use, _again):
        d = self.d
        end, gone, rereads = time.time() + 120, None, 0
        while time.time() < end:
            tree = d.tree()
            if use and rereads < 2 and not d.seen(picker, tree) and not any(self._picker_row(n.name) for n in tree):
                # 26.10.26 on Windows: a choice closes the picker and UIA marks it off screen until the
                # page is built again; leaving Settings and coming back shows it with the choice
                gone = gone or time.time()
                if time.time() - gone > 5 and not self._in_use(picker, entry, tree):
                    rereads += 1
                    self.log("%s closed but not in the tree; leaving Settings to read it again (%d)" % (picker, rereads))
                    self.nav(NAV_OVERVIEW)
                    self.find_setting(picker, PICKER_PAGES[picker.id], str(picker))
                    gone = None
                    continue
            else:
                gone = None
            if d.find_in(SERVER_REFUSED, tree):
                raise InfraFault("server", "%s %s refused by the app (the stand-in or server not answering)" % (picker, entry),
                                 sub="node" if picker is NODE_PICKER else "relay", shot=d.shot("server-refused"))
            sw = d.find_in(SWITCH, tree)
            if use and sw:
                d._act(d.s.press, sw[0])
                time.sleep(1)
                continue
            if use and self._in_use(picker, entry, tree):
                break
            if not use:
                if self._in_use(picker, entry, tree) or self._listed(entry, tree):
                    break
                if not any(self._picker_row(n.name) for n in tree):
                    self._open_picker(picker)
                    if self._listed(entry, d.tree()):
                        break
            time.sleep(1.5)
        else:
            d.harness("%s %s never %s" % (picker, entry, "in use" if use else "listed"))
        open_ = lambda tree: any(self._picker_row(n.name) for n in tree)
        if open_(d.tree()) and not d.wait(Expect("the picker closed", lambda dd, tree: not open_(tree)), 3, dismiss=False):
            d.s.key("escape")  # closes the picker (if it closed first, _open_picker finds the page again)
            time.sleep(0.8)
        if use and not d.wait(shows(picker), 2) and not self._in_use(picker, entry):  # an Escape too many left the page: back to it to read the choice
            self.find_setting(picker, PICKER_PAGES[picker.id], str(picker))
        if use and not (d.wait(Expect("%s in use with the picker closed" % entry,
                                      lambda dd, tree: self._in_use(picker, entry, tree)), 5, dismiss=False)):
            # the picker showed it chosen but closing it dropped the choice (26.10.25 once): choose again
            if _again:
                d.harness("%s %s shown in use in the picker but not once it closed" % (picker, entry))
            self.log("%s %s not in use once the picker closed; choosing it again" % (picker, entry))
            return self._choose(picker, typed, entry, use, _again=True)

    def change_settings(self, want):
        """Theme, wallet label, confirmations, Technical details: the choices a user makes that the
        update must keep."""
        d = self.d
        theme = THEME[want.get("theme", "Light")]
        self.find_setting(theme, ("appearance",), "the theme choice")
        group = [t for t in THEME.values()]

        def chosen(dd, tree):
            if any("selected" in n.states or "checked" in n.states for n in dd.find_in(theme, tree)):
                return True
            # a platform that shows no chosen state on any of the three: the press landed, and the wallet's
            # settings file (settings_kept) says which was chosen
            blind = not getattr(dd.s, "shows_selection", True) and not any(
                "selected" in n.states or "checked" in n.states for t in group for n in dd.find_in(t, tree))
            return bool(blind and dd.find_in(theme, tree))
        pressed = []

        def press_theme():
            d.press(theme, step="theme", timeout=20, then=Expect("%s chosen" % theme, chosen))
            pressed.append(1)
        # done: shown chosen; a platform that shows no chosen state: once pressed (settings_kept checks it)
        d.achieve(Goal("theme", lambda tree: any("selected" in n.states or "checked" in n.states for n in d.find_in(theme, tree))
                       or (pressed and chosen(d, tree)), press_theme), timeout=5)
        self.find_setting(LABEL_FIELD, ("wallet",), "the wallet label")  # Save label shows once it is edited
        d.fill(LABEL_FIELD, want["label"], step="label")
        d.press(LABEL_SAVE, step="label-save", timeout=20)
        self.find_setting(CONF_FEWER, ("payments", "advanced"), "the confirmations stepper")
        self.set_confirmations(int(want.get("confirmations", 1)))
        if want.get("technical_details"):
            self.find_setting(TECHNICAL, ("advanced",), "Technical details")
            d.toggle(TECHNICAL, True, step="technical-details")
        d.shot("%s-settings" % self.which)
        self.leave_settings()

    def set_confirmations(self, want):
        """− or + on the stepper (its page open) until it shows `want`; the count it shows at the end
        (None when this build's count cannot be read: then nothing is pressed)."""
        d = self.d
        v = self._confirmations()
        for _ in range(30):
            if v is None or v == want:
                break
            t = CONF_FEWER if v > want else CONF_MORE
            d.press(t, step="confirmations", timeout=10,
                    then=Expect("%s from %d" % (t, v), lambda dd, tree, v0=v: self._confirmations(tree) not in (None, v0)))
            v = self._confirmations()
        return v

    def read_confirmations(self):
        """The count on Settings › Payments (the wallet's own minimum confirmations, read back by the app)."""
        self.find_setting(CONF_FEWER, ("payments", "advanced"), "the confirmations stepper")
        return self.d.wait(Expect("the confirmations count", lambda dd, tree: self._confirmations(tree)), 10)

    def confirmations_land(self, want):
        """Sets the count on the stepper, leaves Settings and opens the page again: (the count it shows
        then, whether the app said the change was not saved)."""
        self.find_setting(CONF_FEWER, ("payments", "advanced"), "the confirmations stepper")
        self.set_confirmations(want)
        refused = bool(self.d.wait(shows(CONF_NOT_SAVED), 2, dismiss=False))
        self.leave_settings()
        return self.read_confirmations(), refused

    def _confirmations(self, tree=None):
        tree = tree if tree is not None else self.d.tree()
        for n in self.d.find_in(CONF_FIELD, tree):
            if (n.value or "").strip().isdigit():
                return int(n.value.strip())
        for n in self.d.find_in(CONF_COUNT, tree):
            m = re.match(r"(\d+)", n.name)
            if m:
                return int(m.group(1))
        for n in tree:
            if n.role == "text_field" and (n.value or "").strip().isdigit():
                return int(n.value.strip())
        return None

    # ---- reading and paying

    def address(self):
        """The Epicbox address on Receive (the full one, user@relay)."""
        d = self.d
        self.nav(NAV_RECEIVE)

        def got(dd, tree):
            for n in tree:
                for s in (n.value or "", n.name or ""):
                    m = ADDRESS_RX.search(s)
                    if m:
                        return m.group(0)
            return None
        a = d.must(Expect("an Epicbox address on Receive", got), 60, step="address")
        self.log("%s: Epicbox address %s…%s" % (self.which, a[:8], a[-6:]))
        return a

    def send(self, to, amount=None):
        """Sends `amount` (None: Max) to `to` by Epicbox through the Send page and its review; True
        when the app says it was handed over. The payment's progress is read from the wallet's files
        by the checks, never from this page."""
        d = self.d
        self.nav(NAV_SEND)
        if d.seen(SEND_ANOTHER):
            d.press(SEND_ANOTHER, step="send-another", timeout=20)
        eb, link = d.seen(SEND_METHOD_EPICBOX), d.seen(SEND_METHOD_LINK)
        if eb and link and "selected" not in eb.states:
            d._act(d.s.press, eb)
            time.sleep(0.8)
        d.fill(SEND_TO, to, step="send-to")
        # A paired contact: the pairing switch shows once To resolves and starts on; this send means
        # the public Epicbox address. Bounded wait, as an unpaired recipient never shows it.
        if d.wait(shows(SEND_VIA_PAIRING), VIA_PAIRING_WAIT_S):
            d.toggle(SEND_VIA_PAIRING, False, step="send-via-pairing-off")
        if amount is None:
            d.press(SEND_MAX, step="send-max", timeout=20,
                    then=Expect("an amount filled", lambda dd, tree: next((n for n in dd.find_in(SEND_AMOUNT, tree)
                                                                          if re.match(r"\d", (n.value or "").strip())), None)))
            amount = (d.seen(SEND_AMOUNT).value or "").strip()
        else:
            d.fill(SEND_AMOUNT, amount, step="send-amount")
        d.shot("send-filled")
        if not d.wait(shows(SEND_REVIEW), 10):
            d.s.key("ctrl_enter")
        else:
            d.press(SEND_REVIEW, step="send-review", then=shows(SEND_REVIEW_TITLE), timeout=60)
        d.must(shows(SEND_REVIEW_TITLE), 60, step="send-review")
        pw = [n for n in d.tree() if n.role == "text_field" and "password" in n.states]
        if pw:
            d._act(d.s.set_text, pw[0], self.password, True)
        d.press(SEND_CONFIRM, step="send-confirm", then=either(gone(SEND_REVIEW_TITLE), shows(SEND_FAILED)), timeout=300)
        d.shot("send-after")
        failed = d.find_in(SEND_FAILED, d.tree())
        if failed:
            return False, "the app says: %s" % failed[0].name.replace("\n", " ")[:200]
        return True, "handed over (%s EPIC)" % amount
