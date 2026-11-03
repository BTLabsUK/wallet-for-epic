# SPDX-License-Identifier: Apache-2.0
"""The desktop app's G4 steps (app/lib/src/desktop), written once on targets for Linux and Windows.

Every step names its control by Target (an id from trust_ids.json, the build's own ARB text, literal
names for releases before a key) and the state it must reach; the Driver finds, presses, waits and
recovers. Nothing here reads tree order or coordinates. A setting is found on whichever Settings page
holds it: the pages a release is known to use first, then every page the section list shows, so a
setting moved to another page is still found.

Secrets: the password is made here, the recovery phrase read off the reveal screen; both go back to
the lane (saved state, never a log). Screens that show them are never sent to a model (recover.py).
"""
import re
import secrets as _secrets
import time

from . import targets as tg
from . import breaks
from .driver import Expect, either, gone, shows, where
from .faults import HarnessFault, ProductFault

T = tg.T

# ---- targets (ids: app/lib/src/desktop/trust_ids.dart; keys newest first; names for older builds)

WELCOME_CREATE = T("g4.welcome.create", keys=("deskOnbWelcomeCreate", "firstRunCreate"), names=("Create a new wallet",))
DEEP_END = T("g4.level.stop.3", keys=("lvPickStopThree",), names=("Deep end",))
CREATE_TITLE = T("g4.create.title", role="text", keys=("deskOnbCreateTitle",), names=("Create wallet",), secret=True)
PASSWORD = T("g4.account.password", role="text_field", names=("re:.*",), secret=True)
REVEAL = T("g4.create.reveal", keys=("deskOnbCreateReveal",), names=("Reveal phrase",), secret=True)
WRITTEN = T("g4.create.written", role="checkbox", keys=("deskOnbCreateWritten",), names=("re:i have written down.*",),
            match="starts", secret=True)
CONTINUE = T("g4.create.continue", keys=("commonContinue",), names=("Continue",))
SETUP_SKIP = T("g4.setup.skip", keys=("deskSetupSkip",), names=("Skip setup",))
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
}
# every section a release has had (for "a setting moved": the pages are walked when the known ones miss it)
ALL_SECTIONS = ("Node", "Transactions", "Receiving", "Privacy", "Appearance", "This wallet", "All wallets",
                "Advanced", "About", "Wallet", "Security", "Payments", "Network & privacy", "Wallets", "Files & logs")

THEME = {t: T("g4.appearance.theme.%s" % t.lower(), keys=("deskSetAppear%s" % t,), names=(t,), match="exact")
         for t in ("System", "Dark", "Light")}
LABEL_FIELD = T("g4.wallet.label", role="text_field", keys=("deskSetAcctLabel",), names=("Name",), match="exact")
LABEL_SAVE = T("g4.wallet.label.save", keys=("deskSetAcctSaveLabel",), names=("Save label",))
CONF_FEWER = T("g4.confirmations.fewer", keys=("deskSetAdvConfirmationsFewer",), names=("Fewer confirmations",))
CONF_FIELD = T("g4.confirmations.value", role="text_field", keys=("deskSetAdvConfirmations",), names=("Confirmations",), match="exact")
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


class Desktop:
    """The recipe on one running app. `which` is previous | candidate."""

    def __init__(self, driver, which, log=print):
        self.d, self.which, self.log = driver, which, log
        self.password = self.phrase = None
        d = self.d
        d.obstacles += [(TOUR_SKIP, "the first-run tour"), (SETUP_SKIP, "the setup assistant"),
                        (LAST_SESSION, "the last-session notice (left unsent)")]

    # ---- helpers

    def _passwords(self, tree):
        return [n for n in tree if n.role == "text_field" and "password" in n.states]

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
                d.harness("no password field (wanted %d)" % want_at_least)
            for n in fields:
                d._act(d.s.set_text, n, self.password)
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
        return len(names & self.section_names()) >= 2

    def section_names(self):
        """Every section name a release has had, in English and as this build shows them (its locale)."""
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
        if "checked" not in n.states and "selected" not in n.states:
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
        """The wallet unlocked (auto-lock can close it while the lane waits for a payment)."""
        if self.d.seen(UNLOCK_TITLE):
            self.log("the wallet locked itself (auto-lock): unlocking again")
            self.unlock()

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

    def section(self, key_or_name):
        """Settings › a section, by its target (SECTION key) or a literal name. False when the build
        lists no such section."""
        d = self.d
        self.settings()
        t = SECTION.get(key_or_name) or T("g4.settings.section.%s" % tg._norm(key_or_name).replace(" ", "_"),
                                          names=(key_or_name,), match="exact")
        if not d.wait(shows(t), 4):
            return False
        # 26.10.25 names the back button "Wallet" too: a press that leaves Settings was the wrong one
        for k in range(3):
            hits = d.find_in(t, d.tree())
            if k >= len(hits):
                break
            d._act(d.s.press, hits[k])
            time.sleep(1)
            if d.wait(Expect("still in Settings", lambda dd, tree: self.in_settings(tree)), 4, dismiss=False):
                return True
            self.log("Settings › %s: %s left Settings; trying the next one" % (key_or_name, hits[k].brief()))
            self.settings()
        d.harness("Settings › %s: no control of that name opens the section" % key_or_name)

    def find_setting(self, target, pages, what):
        """Opens the Settings page that holds `target`: the known `pages` first, then every section
        the list shows (a setting moved to another page is found there, and the log says so)."""
        d = self.d
        self.settings()
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
                # renamed on the page the recipe expects: the model's pick, before every section is searched
                if d.rec.pick(target, d.tree(), step="find-%s" % target.id, texts=d.texts(target)):
                    return True
        listed = [n.name.split("\n")[0].strip() for n in d.tree()
                  if n.role in ("button", "tab", "row") and tg._norm(n.name.split("\n")[0]) in self.section_names()]
        for name in listed:
            if name in tried:
                continue
            if self.section(name) and d.wait(shows(target), 3):
                self.log("%s found under Settings › %s (not where this release kept it: %s)" % (what, name, ", ".join(pages)))
                return True
        n = d.rec.pick(target, d.tree(), step="find-%s" % target.id, texts=d.texts(target))
        if n:
            return True
        d.harness("%s not found under Settings (tried %s)" % (what, ", ".join(tried + listed)))

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

    def _view_deep_end(self):
        """A release with levels opens a new install in the basic view, where Settings hides Node and
        more: Settings › Advanced › View › Deep end (level 3). Nothing on a build without levels."""
        d = self.d
        if not self.section("advanced"):
            return
        n = d.wait(shows(DEEP_END), 3)
        if not n:
            return
        if "checked" not in n.states and "selected" not in n.states:
            d._act(d.s.press, n)
            d.wait(Expect("Deep end chosen", lambda dd, tree: any(("checked" in x.states or "selected" in x.states)
                                                                  for x in dd.find_in(DEEP_END, tree))), 10)
        self.log("Settings › Advanced › View: Deep end")

    def _in_use(self, picker, entry, tree=None):
        n = self.d.seen(picker, tree)
        if not n:
            return False
        rest = re.split(r"[:\n]", n.name, 1)[1].strip() if re.search(r"[:\n]", n.name) else ""
        return rest == entry or rest.startswith(entry + ",") or rest.startswith(entry + " ")

    def _use_row(self, entry):
        return T("g4.server.use", names=(r"re:(use|add) %s(,.*)?" % re.escape(tg._norm(entry)),), match="exact")

    def _listed(self, entry, tree):
        rx = re.compile(r"^use %s(,|$)" % re.escape(tg._norm(entry)))
        return any(rx.match(tg._norm(n.name)) for n in tree if n.role == "button")

    def _open_picker(self, picker):
        d = self.d
        if not d.wait(shows(picker), 3):  # a stray Escape or a dialog took the page away: back to it
            self.find_setting(picker, PICKER_PAGES[picker.id], str(picker))
        d.press(picker, step="open-%s" % picker.id, timeout=20,
                then=Expect("the picker open", lambda dd, tree: any(n.role == "text_field" and "focused" in n.states for n in tree)
                            or any(tg._norm(n.name).startswith("use ") for n in tree)))

    def use_server(self, picker, typed, entry, use, _again=False):
        """Types `typed` into the picker and presses Use/Add `entry`. Done when listed (use=False) or
        in use (use=True; a Switch offer is taken)."""
        d = self.d
        if use and self._in_use(picker, entry):
            return
        self._open_picker(picker)
        search = [n for n in d.tree() if n.role == "text_field" and "password" not in n.states]
        focused = [n for n in search if "focused" in n.states] or search
        if not focused:
            d.harness("the %s picker has no search field" % picker)
        d._act(d.s.set_text, focused[0], typed)
        d.press(self._use_row(entry), step="use-%s" % entry, timeout=30,
                then=Expect("%s %s" % (entry, "in use" if use else "listed"),
                            lambda dd, tree: ((self._in_use(picker, entry, tree) or dd.find_in(SWITCH, tree)) if use else
                                              (self._listed(entry, tree) or self._in_use(picker, entry, tree)
                                               or not any(tg._norm(n.name).startswith("use ") for n in tree)))))
        end = time.time() + 120
        while time.time() < end:
            tree = d.tree()
            if d.find_in(SERVER_REFUSED, tree):
                raise HarnessFault("server", "%s %s refused by the app (the stand-in or server not answering)" % (picker, entry),
                                   d.shot("server-refused"))
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
                if not any(tg._norm(n.name).startswith("use ") for n in tree):
                    self._open_picker(picker)
                    if self._listed(entry, d.tree()):
                        break
            time.sleep(1.5)
        else:
            d.harness("%s %s never %s" % (picker, entry, "in use" if use else "listed"))
        open_ = lambda tree: any(tg._norm(n.name).startswith("use ") for n in tree)
        if open_(d.tree()) and not d.wait(Expect("the picker closed", lambda dd, tree: not open_(tree)), 3, dismiss=False):
            d.s.key("escape")  # closes the picker (if it closed first, _open_picker finds the page again)
            time.sleep(0.8)
        if use and not d.wait(shows(picker), 2):  # an Escape too many left the page: back to it to read the choice
            self.find_setting(picker, PICKER_PAGES[picker.id], str(picker))
        if use and not (d.wait(Expect("%s in use with the picker closed" % entry,
                                      lambda dd, tree: self._in_use(picker, entry, tree)), 5, dismiss=False)):
            # the picker showed it chosen but closing it dropped the choice (26.10.25 once): choose again
            if _again:
                d.harness("%s %s shown in use in the picker but not once it closed" % (picker, entry))
            self.log("%s %s not in use once the picker closed; choosing it again" % (picker, entry))
            return self.use_server(picker, typed, entry, use, _again=True)

    def change_settings(self, want):
        """Theme, wallet label, confirmations, Technical details: the choices a user makes that the
        update must keep."""
        d = self.d
        theme = THEME[want.get("theme", "Light")]
        self.find_setting(theme, ("appearance",), "the theme choice")
        d.press(theme, step="theme", timeout=20,
                then=Expect("%s chosen" % theme, lambda dd, tree: any("selected" in n.states or "checked" in n.states
                                                                      for n in dd.find_in(theme, tree))))
        self.find_setting(LABEL_FIELD, ("wallet",), "the wallet label")  # Save label shows once it is edited
        d.fill(LABEL_FIELD, want["label"], step="label")
        d.press(LABEL_SAVE, step="label-save", timeout=20)
        self.find_setting(CONF_FEWER, ("payments", "advanced"), "the confirmations stepper")
        for _ in range(30):
            v = self._confirmations()
            if v is None or v <= int(want.get("confirmations", 1)):
                break
            d.press(CONF_FEWER, step="confirmations", timeout=10,
                    then=Expect("fewer", lambda dd, tree, v0=v: self._confirmations(tree) != v0))
        if want.get("technical_details"):
            self.find_setting(TECHNICAL, ("advanced",), "Technical details")
            d.toggle(TECHNICAL, True, step="technical-details")
        d.shot("%s-settings" % self.which)
        self.leave_settings()

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
            d._act(d.s.set_text, pw[0], self.password)
        d.press(SEND_CONFIRM, step="send-confirm", then=either(gone(SEND_REVIEW_TITLE), shows(SEND_FAILED)), timeout=300)
        d.shot("send-after")
        failed = d.find_in(SEND_FAILED, d.tree())
        if failed:
            return False, "the app says: %s" % failed[0].name.replace("\n", " ")[:200]
        return True, "handed over (%s EPIC)" % amount
