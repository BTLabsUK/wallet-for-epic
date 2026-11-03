# SPDX-License-Identifier: Apache-2.0
"""The phone app's G4 steps (app/lib/src: the Android and iOS screens), written once on targets.

Every step names its control by Target (an id from trust_ids.json, the build's own ARB text, literal
names for releases before a key) and the state it must reach; the Driver finds, presses, waits and
recovers. Nothing here reads tree order or coordinates. A setting is found on whichever Settings page
holds it: the pages a release is known to use first, then every page the Settings list shows.

Secrets: the PIN and the password are made here (the password only guards the LEPIC CLI's vault the
checks read the store with; the store's key comes from the phrase), the phrase is read off Settings ›
Security › Back up recovery phrase. All three go back to the lane (saved state, never a log). PIN and
phrase screens are secret targets: never sent to a model, never dumped.
"""
import re
import secrets as _secrets
import time

from . import breaks
from . import targets as tg
from .driver import Expect, either, gone, shows, where
from .faults import HarnessFault, ProductFault

T = tg.T

# ---- targets (ids: trust_ids.json; keys newest first; names for builds before a key)

WELCOME_CREATE = T("g4.welcome.create", keys=("firstRunCreate",), names=("Create a new wallet",))
TOR_ONLY = T("g4.welcome.toronly", role="toggle", keys=("advModeTorOnly", "levelUndercoverTitle"), names=("Tor only",))
LEVEL_PICK = T("g4.level.title", role="text", keys=("lvPickTitle",), names=("Pick your view",))
DEEP_END = T("g4.level.stop.3", role="other", keys=("lvPickStopThree",), names=("Deep end",), match="exact")
TOUR_SKIP = T("g4.tour.skip", keys=("tourPhoneSkip",), names=("Skip tour",))
BIOMETRICS_NOT_NOW = T("g4.pin.biometrics.notnow", keys=("pinBiometricsNotNow",), names=("Not now",), match="exact")
ANR_WAIT = T("g4.system.anr.wait", names=("Wait",), match="exact")  # Android's "isn't responding" dialog

PIN_CHOOSE = T("g4.pin.choose", role="text", keys=("pinChooseTitle",), names=(r"re:choose a \d+-digit pin",), secret=True)
PIN_AGAIN = T("g4.pin.again", role="text", keys=("pinConfirmTitle",), names=("Enter the PIN again",), secret=True)
PIN_FIELD = T("g4.pin.field", role="text_field", keys=("pinLabel", "pinRepeatLabel"), names=("PIN", "Repeat PIN"),
              match="exact", secret=True)
PIN_WRONG = T("g4.pin.wrong", role="text", keys=("pinWrong",), names=(r"re:wrong pin\b.*",), match="starts")
UNLOCK_TITLE = T("g4.unlock.title", role="text", keys=("unlockTitle",), names=("Unlock wallet",))

LOCK = T("g4.home.lock", keys=("homeLockTooltip",), names=("Lock wallet",), match="exact")
SETTINGS = T("g4.home.settings", keys=("homeSettingsTooltip",), names=("Settings",), match="exact")
TAB_SEND = T("g4.tab.send", role="tab", keys=("homeSendButton",), names=("Send",))
TAB_WALLET = T("g4.tab.wallet", role="tab", keys=("shellWalletTab",), names=("Wallet",))
TAB_RECEIVE = T("g4.tab.receive", role="tab", keys=("homeReceiveButton",), names=("Receive",))
CLOSE = T("g4.common.close", keys=("commonClose",), names=("Close",), match="exact")
DONE = T("g4.common.done", keys=("commonDone",), names=("Done",), match="exact")
SAVE = T("g4.common.save", keys=("commonSave",), names=("Save",), match="exact")
CONTINUE = T("g4.common.continue", keys=("commonContinue",), names=("Continue",), match="exact")

SECTION = {
    "security": T("g4.settings.section.security", keys=("settingsSectionSecurity",), names=("Security",), match="line"),
    "appearance": T("g4.settings.section.display", keys=("settingsSectionDisplay",), names=("Appearance",), match="line"),
    "wallet": T("g4.settings.section.wallet", keys=("settingsSectionWallet",), names=("This wallet",), match="line"),
    "advanced": T("g4.settings.section.advanced", keys=("advTitle",), names=("Advanced",), match="line"),
}
# every Settings entry a phone release has had (for "a setting moved": the pages are walked when the known ones miss it)
ALL_SECTIONS = ("Security", "Appearance", "This wallet", "Linked devices", "Help", "Donate", "Advanced", "About",
                "Network & privacy", "Transactions", "Wallets")

BACKUP_ROW = T("g4.backup.row", keys=("settingsBackupPhrase",), names=("Back up recovery phrase",))
BACKUP_AGREE = T("g4.backup.agree", role="checkbox", keys=("backupCopyAgree",), names=("I will keep the phrase private",), secret=True)
BACKUP_SHOW = T("g4.backup.show", keys=("backupShowPhrase",), names=("Show recovery phrase",), secret=True)
BACKUP_DONE = T("g4.backup.done", keys=("commonDone",), names=("Done",), match="exact", secret=True)

THEME_ROW = T("g4.appearance.theme", keys=("settingsTheme",), names=("Theme",))
THEME = {t: T("g4.appearance.theme.%s" % t.lower(), role="checkbox", keys=("settingsTheme%s" % t,), names=(t,), match="exact")
         for t in ("System", "Dark", "Light")}
LEVEL_ROW = T("g4.advanced.level", keys=("levelRowTitle",), names=("Wallet view",))
TECHNICAL = T("g4.advanced.technical", role="toggle", keys=("advTechnical",), names=("Technical details",))
CONF_FEWER = T("g4.confirmations.fewer", keys=("advConfirmationsFewer",), names=("Fewer confirmations",), match="exact")
CONF_RX = re.compile(r"^(\d+)\s+confirmations?\b", re.I)

SERVER = {
    "node": {"status": T("g4.status.node", names=(r"re:node, .*",), match="starts"),
             "field": T("g4.server.node.field", role="text_field", keys=("slNodeField",), names=("Node address",), match="exact")},
    "relay": {"status": T("g4.status.epicbox", names=(r"re:epicbox, .*",), match="starts"),
              "field": T("g4.server.relay.field", role="text_field", keys=("slRelayField",), names=("Epicbox server",), match="exact")},
}
STATUS_ANY = T("g4.status.network", names=(r"re:network\b.*",), match="starts")  # level 1 shows one Network icon
SWITCH = T("g4.server.switch", keys=("slSwitch", "lvShellSwitch"), names=("Switch",), match="exact")
CLEAR = T("g4.server.clear", keys=("slClear",), names=("Clear",), match="exact")
SERVER_REFUSED = T("g4.server.refused", role="text", names=(r"re:.*(no answer from this server|nothing added|not a node|"
                                                            r"could not reach|did not answer).*",), match="contains")

RECEIVE_EPICBOX = T("g4.receive.method.epicbox", keys=("methodEpicbox",), names=("Epicbox",), match="exact")
SEND_EPICBOX = T("g4.send.method.epicbox", keys=("methodEpicbox",), names=("Epicbox",), match="exact")
SEND_TO = T("g4.send.to", role="text_field", keys=("sendToHint", "sendToLabel"), names=("Address or contact", "To"), match="exact")
SEND_CLEAR = T("g4.send.clear", keys=("sendClearRecipient",), names=("Clear recipient",), match="exact")
SEND_AMOUNT = T("g4.send.amount", role="text_field", keys=("sendAmountLabel",), names=(r"re:amount\b.*",), match="starts")
SEND_MAX = T("g4.send.max", keys=("sendMax",), names=("Max",), match="exact")
SEND_CONFIRM = T("g4.send.confirm", names=(r"re:send [\d.,]+ ?epic",), match="exact")  # sendReviewSendButton "Send {amount}"
SEND_BACK = T("g4.send.back", names=("Back",), match="exact")
SEND_FAILED = T("g4.send.failed", role="text", names=(r"re:.*(send failed|not sent|nothing was sent|could not send).*",),
                match="contains")

ADDRESS_RX = re.compile(r"\b([1-9A-HJ-NP-Za-km-z]{48,56})(@[\w.:-]+)?")


def phrase_words(names, spoken=None):
    """The revealed phrase off the accessibility names: one node per word, "Word 3: abandon"
    (backupWordSpoken), in number order. Never logged."""
    rx = re.compile(spoken or r"word (\d{1,2}): ([a-z]{3,8})", re.I)
    got = {}
    for name in names:
        m = rx.fullmatch((name or "").strip())
        if m:
            got[int(m.group(1))] = m.group(2).lower()
    n = len(got)
    if n in (12, 24) and sorted(got) == list(range(1, n + 1)):
        return [got[i] for i in range(1, n + 1)]
    return []


def bare_host(v):
    return re.sub(r"^[a-z]+://", "", (v or "").strip().lower()).rstrip("/")


def same_host(a, b):
    a, b = bare_host(a), bare_host(b)
    return a == b or a == b + ":443" or a + ":443" == b


class Phone:
    """The recipe on one running app. `which` is previous | candidate."""

    def __init__(self, driver, which, log=print):
        self.d, self.which, self.log = driver, which, log
        self.pin = self.password = self.phrase = None
        self.d.obstacles += [(TOUR_SKIP, "the app tour"), (BIOMETRICS_NOT_NOW, "the biometrics offer"),
                             (ANR_WAIT, "Android's not-responding dialog")]

    # ---- helpers

    def _text(self, key, fallback):
        return self.d.labels.text(key) if self.d.labels and self.d.labels.text(key) else fallback

    def _home(self):
        return Expect("the wallet's home (Lock wallet and the tabs)",
                      lambda d, tree: d.find_in(LOCK, tree) and d.find_in(TAB_WALLET, tree) and True)

    def _pressable(self, target, tree):
        hits = self.d.find_in(target, tree)
        return next((n for n in hits if "press" in n.actions), hits[0] if hits else None)

    def _type_pin(self, step, then, timeout=60):
        """The PIN into the PIN field on screen, until `then` holds (a PIN screen moves on by itself)."""
        d = self.d
        d.step = step
        d.trail.append(step)
        for _ in range(2):
            f = d.locate(PIN_FIELD, 30)
            d._act(d.s.set_text, f, self.pin)
            r = d.wait(then, timeout)
            if r:
                return r
            self.log("step %s: %s not reached after the PIN; typing it again" % (step, then))
        return d.must(then, timeout, goal="%s, after the PIN" % then)

    def _wait_home(self, step, timeout=180):
        self.d.must(self._home(), timeout, step=step, goal="the wallet's home screen (Lock wallet, Send/Wallet/Receive tabs)")

    # ---- first run and unlock

    def create_wallet(self):
        """A new wallet on the welcome screen; returns {pin, password, phrase}. The phrase is read off
        Settings › Security and only handed back."""
        d = self.d
        self.pin = "".join(_secrets.choice("0123456789") for _ in range(6))
        self.password = _secrets.token_urlsafe(16)
        at = d.must(where({"welcome": shows(WELCOME_CREATE), "levels": shows(LEVEL_PICK)}), 180, step="welcome",
                    goal="the welcome screen with Create a new wallet")
        if at == "levels":
            self._pick_deep_end()
        if d.seen(TOR_ONLY):
            d.toggle(TOR_ONLY, False, step="tor-only-off")
        d.press(WELCOME_CREATE, step="create", then=shows(PIN_CHOOSE, PIN_FIELD), timeout=30)
        self._type_pin("pin-choose", shows(PIN_AGAIN), 30)
        self._type_pin("pin-again", either(self._home(), shows(TOUR_SKIP)), 240)
        self._wait_home("home-after-create")
        self.phrase = self._read_phrase()
        self.log("wallet created; the PIN and phrase are kept with the lane's secrets, not printed")
        self.home()
        return {"pin": self.pin, "password": self.password, "phrase": self.phrase}

    def _pick_deep_end(self):
        """A build with wallet levels asks the depth on a fresh install: Deep end (level 3), what a
        release before levels shows."""
        d = self.d
        n = self._pressable(DEEP_END, d.tree())
        if n and "checked" not in n.states and "selected" not in n.states:
            d._act(d.s.press, n)
            d.wait(Expect("Deep end chosen", lambda dd, tree: any("checked" in x.states or "selected" in x.states
                                                                  for x in dd.find_in(DEEP_END, tree))), 10)
        self.log("level picker: Deep end (level 3)")

    def _words(self, tree):
        spoken = self._text("backupWordSpoken", "Word {number}: {word}")
        rx = re.escape(spoken).replace(re.escape("{number}"), r"(\d{1,2})").replace(re.escape("{word}"), r"([a-z]{3,8})")
        return phrase_words([n.name for n in tree], rx)

    def _read_phrase(self):
        """Settings › Security › Back up recovery phrase › (I will keep it private) › Show › PIN: the
        words, one node each. Done closes it."""
        d = self.d
        self.section("security")
        d.press(BACKUP_ROW, step="backup", then=shows(BACKUP_SHOW, BACKUP_AGREE, CONTINUE), timeout=30)
        words_shown = Expect("the phrase shown", lambda dd, tree: self._words(tree) or None)
        for _ in range(6):
            at = d.must(where({"words": words_shown, "pin": shows(PIN_FIELD),
                               "agree": Expect("the privacy box unticked", lambda dd, tree: any(
                                   "checked" not in n.states for n in dd.find_in(BACKUP_AGREE, tree)) or None),
                               "show": shows(BACKUP_SHOW), "continue": shows(CONTINUE)}), 30, step="backup-reveal")
            if at == "words":
                break
            if at == "pin":
                self._type_pin("backup-pin", either(words_shown, gone(PIN_FIELD)), 30)
            elif at == "agree":
                d.toggle(BACKUP_AGREE, True, step="backup-agree")
            elif at == "show":
                d.press(BACKUP_SHOW, step="backup-show", then=either(words_shown, shows(PIN_FIELD)), timeout=30)
            else:
                d.press(CONTINUE, step="backup-continue", timeout=20)
        words = self._words(d.tree())
        if not words:
            d.harness("the recovery phrase did not show (12 or 24 words)")
        phrase = " ".join(words)
        del words
        if d.seen(BACKUP_DONE):
            d.press(BACKUP_DONE, step="backup-done", then=gone(BACKUP_DONE), timeout=20)
        return phrase

    def open_wallet(self, secrets, after_update=False):
        """From wherever the app opened to the wallet's home: unlock with the PIN. After an update the
        candidate must find the wallet: a welcome screen, a level picker or a new-PIN screen is the
        product's fault."""
        d = self.d
        self.pin = secrets.get("pin") or self.pin
        self.password = secrets.get("password") or self.password
        self.phrase = secrets.get("phrase") or self.phrase
        screens = {"welcome": shows(WELCOME_CREATE), "levels": shows(LEVEL_PICK), "new-pin": shows(PIN_CHOOSE),
                   "unlock": shows(UNLOCK_TITLE, PIN_FIELD), "home": self._home()}
        at = d.must(where(screens), 240, step="open-%s" % self.which, goal="the Unlock screen or the wallet")
        d.shot("%s-first" % self.which)
        if after_update and at in ("welcome", "levels", "new-pin"):
            raise ProductFault("wallet_opens", "after the update the candidate shows %s: it found no wallet" % {
                "welcome": "'Create a new wallet'", "levels": "the depth question of a fresh install",
                "new-pin": "'Choose a PIN' of a fresh install"}[at], d.shot("cand-no-wallet"))
        if at in ("welcome", "levels", "new-pin"):
            d.harness("the previous release shows %s where a wallet was expected" % at)
        if at == "unlock":
            self.unlock()
        self._wait_home("home-%s" % self.which)
        self.log("%s: wallet open" % self.which)

    def ensure_unlocked(self):
        """The wallet unlocked (auto-lock can close it while the lane waits for a payment)."""
        if not self.d.s.in_front():
            self.d.s.foreground()
            self.d.wait(either(self._home(), shows(UNLOCK_TITLE, PIN_FIELD)), 60)
        tree = self.d.tree()
        if self.d.find_in(UNLOCK_TITLE, tree) or (self.d.find_in(PIN_FIELD, tree) and not self._home().test(self.d, tree)):
            self.log("the wallet locked itself (auto-lock): unlocking again")
            self.unlock()

    def unlock(self):
        d = self.d
        d.must(shows(UNLOCK_TITLE, PIN_FIELD), 120, step="unlock")
        self._type_pin("unlock-pin", either(self._home(), shows(PIN_WRONG), shows(TOUR_SKIP)), 120)
        if d.find_in(PIN_WRONG, d.tree()):
            raise ProductFault("unlock", "the app says the PIN is wrong (it is the one the wallet was made with)",
                               d.shot("unlock-wrong"))
        self._wait_home("unlock-home")

    # ---- navigation

    def home(self):
        """The wallet's home, Wallet tab: Back out of a page or sheet, the app brought to the front, the
        wallet unlocked when it locked itself."""
        d = self.d
        for _ in range(8):
            if hasattr(d.s, "hide_keyboard"):
                d.s.hide_keyboard()
            tree = d.tree()
            if self._home().test(d, tree):
                tab = d.find_in(TAB_WALLET, tree)[0]
                if "selected" not in tab.states:
                    d._act(d.s.press, tab)
                    d.wait(Expect("Wallet tab", lambda dd, t: any("selected" in n.states for n in dd.find_in(TAB_WALLET, t))), 10)
                return
            if d.find_in(UNLOCK_TITLE, tree):
                self.unlock()
                continue
            if not d.s.in_front():
                self.log("the app is not in front: bringing it back")
                d.s.foreground()
                d.wait(either(self._home(), shows(UNLOCK_TITLE)), 30)
                continue
            d.s.key("back")
            time.sleep(1)
        self._wait_home("home", 30)

    def tab(self, target):
        d = self.d
        self.home()
        d.press(target, step="tab-%s" % target.id.rsplit(".", 1)[-1], timeout=20,
                then=Expect("%s selected" % target, lambda dd, tree: any("selected" in n.states for n in dd.find_in(target, tree))))

    def in_settings(self, tree=None):
        tree = tree if tree is not None else self.d.tree()
        names = {tg._norm(n.name.split("\n")[0]) for n in tree if n.role in ("button", "row", "menu_item", "link")}
        return len(names & self.section_names()) >= 3

    def section_names(self):
        """Every section name a release has had, in English and as this build shows them (its locale)."""
        if getattr(self, "_section_names", None) is None:
            loc = self.d.labels.localized(ALL_SECTIONS, prefix="settings") if self.d.labels else set()
            self._section_names = {tg._norm(s) for s in (*ALL_SECTIONS, *loc)}
        return self._section_names

    def settings(self):
        """The Settings list: Back from a Settings page, else from home by the Settings button."""
        d = self.d
        for _ in range(3):
            if self.in_settings():
                return
            if d.seen(SETTINGS) and d.seen(LOCK):
                break
            d.s.key("back")
            time.sleep(1)
        if self.in_settings():
            return
        self.home()
        d.press(SETTINGS, step="settings", timeout=30,
                then=Expect("the Settings list", lambda dd, tree: self.in_settings(tree)))

    def section(self, key_or_name):
        """Settings › a section, by SECTION key or a literal name. False when the list has no such entry."""
        d = self.d
        self.settings()
        t = SECTION.get(key_or_name) or T("g4.settings.section.%s" % tg._norm(key_or_name).replace(" ", "_"),
                                          names=(key_or_name,))
        n = d.wait(shows(t), 4)
        if not n:
            return False
        d.press(t, step="section-%s" % t.id.rsplit(".", 1)[-1], timeout=20,
                then=Expect("the %s page" % t, lambda dd, tree: not self.in_settings(tree)))
        return True

    def _look(self, target, scrolls=4):
        """`target` on the page, scrolling down to it."""
        d = self.d
        for i in range(scrolls + 1):
            n = d.wait(shows(target), 2 if i else 3)
            if n:
                return n
            d.s.scroll("down")
            time.sleep(0.6)
        return None

    def find_setting(self, target, pages, what):
        """Opens the Settings page that holds `target`: the known `pages` first, then every entry the
        Settings list shows (a setting moved to another page is found there, and the log says so)."""
        d = self.d
        if breaks.moved(target.id):
            self.log("BREAK: %s taken as moved; the recipe's pages %s are not tried first" % (what, ", ".join(pages)))
            pages = ()
            self.settings()
        elif d.seen(target):
            return True
        tried = []
        for p in pages:
            if self.section(p):
                tried.append(p)
                if self._look(target):
                    return True
        self.settings()
        listed = [n.name.split("\n")[0].strip() for n in d.tree() if n.role in ("button", "row", "menu_item")
                  and tg._norm(n.name.split("\n")[0]) in self.section_names()]
        for name in listed:
            if name in [SECTION[p].names[0] for p in tried if p in SECTION]:
                continue
            if self.section(name) and self._look(target):
                self.log("%s found under Settings › %s (not where this release kept it: %s)" % (what, name, ", ".join(pages)))
                return True
        n = d.rec.pick(target, d.tree(), step="find-%s" % target.id, texts=d.texts(target))
        if n:
            return True
        d.harness("%s not found under Settings (tried %s)" % (what, ", ".join(tried + listed)))

    # ---- set up on the previous release

    def set_servers(self, node, custom_node, relay, custom_relay):
        """Adds a server of the user's own and picks the one in use, for the node and for Epicbox, in the
        sheets Home's status icons open."""
        self._view_deep_end()
        node_entry = bare_host(node)
        self.use_server("node", "http://%s" % custom_node, custom_node, use=False)
        self.use_server("node", node_entry, node_entry, use=True)
        self.log("node: %s added, %s in use" % (custom_node, node_entry))
        self.d.shot("%s-node" % self.which)
        self.use_server("relay", custom_relay, custom_relay, use=False)
        self.use_server("relay", relay, relay, use=True)
        self.log("Epicbox: %s added, %s in use" % (custom_relay, relay))
        self.d.shot("%s-relay" % self.which)
        self.home()

    def _level_three(self, tree):
        three = tg._norm(self._text("levelThreeTitle", "Let me explore everything"))
        return any(three in tg._norm(n.name) for n in self.d.find_in(LEVEL_ROW, tree))

    def _view_deep_end(self):
        """A release with levels opens a new install at level 1, where Home hides the node and Epicbox
        icons and Settings hides more: Settings › Advanced › Wallet view › Deep end › Save."""
        d = self.d
        if not self.section("advanced") or not self._look(LEVEL_ROW, 1):
            self.log("no Wallet view row: a build without levels")
            return
        if self._level_three(d.tree()):
            return
        d.press(LEVEL_ROW, step="wallet-view", then=shows(DEEP_END), timeout=20)
        n = self._pressable(DEEP_END, d.tree())
        if "checked" not in n.states and "selected" not in n.states:
            d._act(d.s.press, n)
            d.wait(Expect("Deep end chosen", lambda dd, tree: any(("checked" in x.states or "selected" in x.states)
                                                                  for x in dd.find_in(DEEP_END, tree))), 10)
        if d.seen(SAVE):
            d.press(SAVE, step="wallet-view-save", then=Expect("Wallet view: level 3", lambda dd, tree: self._level_three(tree)),
                    timeout=30)
        d.must(Expect("Wallet view: level 3", lambda dd, tree: self._level_three(tree)), 20, step="wallet-view")
        self.log("Settings › Advanced › Wallet view: Deep end")

    def _host_rows(self, tree, entry):
        out = []
        for n in tree:
            if n.role in ("button", "row", "text", "checkbox") and n.name and "press" in n.actions:
                first = n.name.split("\n")[0].split(",")[0].strip()
                if same_host(first, entry):
                    out.append(n)
        return out

    def _in_use(self, tree, entry):
        cur = tg._norm(self._text("serverCurrent", "In use"))
        return any("selected" in n.states or cur in [tg._norm(p) for p in n.name.replace("\n", ",").split(",")]
                   for n in self._host_rows(tree, entry))

    def _add_row(self, entry):
        add = self._text("slAddRow", "Add {host}")
        rx = re.escape(tg._norm(add)).replace(re.escape("{host}"), re.escape(tg._norm(bare_host(entry))))
        return T("g4.server.add", names=("re:" + rx + "(,.*)?",), match="exact")

    def _open_sheet(self, kind):
        """The Node or Epicbox sheet: Home's status icon, and on releases where it opens the Connections
        sheet first, that sheet's row for the service. Until the sheet's address field shows."""
        d = self.d
        field, status = SERVER[kind]["field"], SERVER[kind]["status"]
        if d.seen(field):
            return
        self.home()
        pressed = []
        for _ in range(4):
            tree = d.tree()
            if d.find_in(field, tree):
                return
            hits = [n for n in d.find_in(status, tree) if n.name not in pressed] or \
                   [n for n in d.find_in(STATUS_ANY, tree) if n.name not in pressed]
            if not hits:
                break
            pressed.append(hits[0].name)
            d._act(d.s.press, hits[0])
            d.wait(shows(field), 6)
        d.must(shows(field), 20, step="open-%s-sheet" % kind, goal="the %s sheet with its address field" % kind)

    def _close_sheet(self, kind):
        d = self.d
        for _ in range(3):
            if not d.seen(SERVER[kind]["field"]):
                return
            c = d.seen(CLOSE)
            if c:
                d._act(d.s.press, c)
            else:
                d.s.key("back")
            d.wait(gone(SERVER[kind]["field"]), 5)

    def _filter(self, kind, text):
        d = self.d
        f = d.locate(SERVER[kind]["field"], 20)
        if (f.value or "") == text:
            return
        if not text:
            c = d.seen(CLEAR)
            if c:
                d._act(d.s.press, c)
                d.wait(Expect("the field cleared", lambda dd, tree: not any((n.value or "") for n in dd.find_in(SERVER[kind]["field"], tree))), 5)
                return
        d._act(d.s.set_text, f, text)
        time.sleep(1.5)  # the list filters as it is typed: one settle before it is read

    def use_server(self, kind, typed, entry, use):
        """Types `typed` into the sheet's field and adds `entry` (Add <host>) or picks its row. Done when
        listed (use=False) or in use (use=True; the Switch question is answered)."""
        d = self.d
        d.step = "server-%s-%s" % (kind, entry)
        d.trail.append(d.step)
        self._open_sheet(kind)
        added = False
        end = time.time() + 180
        while time.time() < end:
            # The Switch question covers the sheet's field: answered before the field is typed in.
            sw = d.find_in(SWITCH, d.tree())
            if sw:
                d._act(d.s.press, sw[0])
                d.wait(gone(SWITCH), 10)
                continue
            self._filter(kind, bare_host(typed) if use else typed)
            tree = d.tree()
            if d.find_in(SERVER_REFUSED, tree):
                raise HarnessFault("server", "%s %s refused by the app (the stand-in or server not answering)" % (kind, entry),
                                   d.shot("server-refused"))
            sw = d.find_in(SWITCH, tree)
            if sw:
                continue
            rows = self._host_rows(tree, entry)
            if use and self._in_use(tree, entry):
                break
            if not use and rows:
                break
            if use and rows:
                d._act(d.s.press, rows[0])
                d.wait(either(shows(SWITCH), Expect("%s in use" % entry, lambda dd, t: self._in_use(t, entry))), 15)
                continue
            add = d.seen(self._add_row(entry), tree)
            if add and not added:
                d._act(d.s.press, add)
                added = True
                d.wait(Expect("%s listed" % entry, lambda dd, t: self._host_rows(t, entry) or dd.find_in(SWITCH, t)
                              or dd.find_in(SERVER_REFUSED, t)), 60)
                continue
            if not add and not rows:
                d.harness("the %s sheet shows no row and no Add for %s" % (kind, entry))
            time.sleep(1.5)
        else:
            d.harness("%s %s never %s" % (kind, entry, "in use" if use else "listed"))
        self._filter(kind, "")
        if use:  # read again over the whole list once the switch settles
            d.must(Expect("%s in use" % entry, lambda dd, tree: self._in_use(tree, entry) or self._in_use_filtered(kind, entry)),
                   40, step="server-%s-in-use" % kind)
        self._close_sheet(kind)

    def _in_use_filtered(self, kind, entry):
        self._filter(kind, bare_host(entry))
        r = self._in_use(self.d.tree(), entry)
        self._filter(kind, "")
        return r

    def change_settings(self, want):
        """Theme, confirmations, Technical details: the choices a user makes that the update must keep.
        The phone app has no wallet label (no wallets.json): the label is not set."""
        d = self.d
        theme = THEME[want.get("theme", "Light")]
        self.find_setting(THEME_ROW, ("appearance",), "the theme row")
        if not self._theme_is(theme):
            d.press(THEME_ROW, step="theme-open", then=shows(theme), timeout=20)
            d.press(theme, step="theme", timeout=20, then=Expect("theme %s" % theme, lambda dd, tree: self._theme_is(theme, tree)))
        self.log("theme %s" % want.get("theme", "Light"))
        self.find_setting(CONF_FEWER, ("advanced",), "the confirmations stepper")
        goal = int(want.get("confirmations", 1))
        for _ in range(30):
            v = self._confirmations()
            if v is None or v <= goal:
                break
            d.press(CONF_FEWER, step="confirmations", timeout=10,
                    then=Expect("fewer", lambda dd, tree, v0=v: self._confirmations(tree) != v0))
        v = self._confirmations()
        if v != goal:
            d.harness("confirmations read %s, wanted %d" % (v, goal))
        self.log("confirmations %d" % v)
        if want.get("technical_details"):
            self.find_setting(TECHNICAL, ("advanced",), "Technical details")
            d.toggle(TECHNICAL, True, step="technical-details")
            self.log("Technical details on")
        d.shot("%s-settings" % self.which)
        self.home()

    def _theme_is(self, theme, tree=None):
        tree = tree if tree is not None else self.d.tree()
        pats = self.d.texts(theme)
        for n in self.d.find_in(THEME_ROW, tree):
            lines = n.name.split("\n")
            if len(lines) > 1 and any(re.fullmatch(p, tg._norm(lines[1])) for p in pats):
                return True
        return False

    def _confirmations(self, tree=None):
        tree = tree if tree is not None else self.d.tree()
        for n in tree:
            m = CONF_RX.match((n.name or "").strip())
            if m:
                return int(m.group(1))
        return None

    # ---- reading and paying

    def address(self):
        """The Epicbox address on the Receive tab (the full one, key@relay)."""
        d = self.d
        self.tab(TAB_RECEIVE)
        m = d.seen(RECEIVE_EPICBOX)
        if m and "selected" not in m.states:
            d._act(d.s.press, m)

        def got(dd, tree):
            for n in tree:
                for s in (n.value or "", n.name or ""):
                    hit = ADDRESS_RX.search(s)
                    if hit and hit.group(2):
                        return hit.group(0)
            return None
        a = d.must(Expect("an Epicbox address on Receive", got), 90, step="address")
        self.log("%s: Epicbox address %s…%s" % (self.which, a[:8], a[-6:]))
        self.home()
        return a

    def send(self, to, amount=None):
        """Sends `amount` (None: Max) to `to` by Epicbox: Send tab › Epicbox › To › Continue › amount ›
        Continue › Send <amount> › PIN. True when the app took it; its progress is read from the
        wallet's files by the checks, never from these screens."""
        d = self.d
        self.tab(TAB_SEND)
        for _ in range(4):  # a send left half-way: back to its first step
            if d.wait(shows(SEND_TO), 3) or not d.seen(SEND_BACK):
                break
            d.press(SEND_BACK, step="send-back", timeout=10)
        m = d.seen(SEND_EPICBOX)
        if m and "selected" not in m.states:
            d._act(d.s.press, m)
            time.sleep(0.8)
        if d.seen(SEND_CLEAR):
            d.press(SEND_CLEAR, step="send-clear", timeout=10, then=Expect("the recipient cleared", lambda dd, tree: True))
        d.fill(SEND_TO, to, step="send-to")
        if hasattr(d.s, "hide_keyboard"):
            d.s.hide_keyboard()
        d.press(CONTINUE, step="send-to-continue", then=shows(SEND_AMOUNT, SEND_MAX), timeout=30)
        if amount is None:
            d.press(SEND_MAX, step="send-max", timeout=20,
                    then=Expect("an amount filled", lambda dd, tree: next((n for n in dd.find_in(SEND_AMOUNT, tree)
                                                                          if re.match(r"\d", (n.value or "").strip())), None)))
            amount = (d.seen(SEND_AMOUNT).value or "").strip()
        else:
            d.fill(SEND_AMOUNT, amount, step="send-amount")
        if hasattr(d.s, "hide_keyboard"):
            d.s.hide_keyboard()
        d.shot("send-filled")
        d.press(CONTINUE, step="send-amount-continue", then=shows(SEND_CONFIRM), timeout=60)
        d.shot("send-review")
        d.press(SEND_CONFIRM, step="send-confirm", then=either(shows(PIN_FIELD), gone(SEND_CONFIRM), shows(SEND_FAILED)),
                timeout=60)
        if d.seen(PIN_FIELD):
            self._type_pin("send-pin", either(gone(PIN_FIELD), shows(SEND_FAILED)), 300)
        d.wait(either(shows(DONE), shows(SEND_FAILED), self._home()), 60)
        d.shot("send-after")
        failed = d.find_in(SEND_FAILED, d.tree())
        if failed:
            return False, "the app says: %s" % failed[0].name.replace("\n", " ")[:200]
        if d.seen(DONE):
            d.press(DONE, step="send-done", timeout=20)
        self.home()
        return True, "handed over (%s EPIC)" % amount
