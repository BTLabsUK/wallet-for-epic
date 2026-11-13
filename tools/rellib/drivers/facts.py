# SPDX-License-Identifier: Apache-2.0
"""What the update-trust drivers assume about the app and the test setup, in one place.

Read from their own sources where one exists, never copied per driver:
  - the servers a test picks (BT Labs first): release/pipeline.toml [defaults] nodes / epicboxes,
    the same lists G1's health pick uses;
  - the confirmations the test wallets move to: REL_TRUST_CONFIRMATIONS, default 1 (the owner
    2026-10-31: test wallets and P at one confirmation);
  - the label texts the drivers look for: the app's English strings (app/lib/l10n/app_en.arb of
    this checkout), the literal only when the file or key is missing.
Not here, on purpose: the auto-lock time (the drivers unlock when they find the wallet locked,
whatever the timeout) and which servers a release ships built in (the drivers read the
"Added by you" mark off each release's own screen, which is what a user sees).
"""
import json
import os
import re
import subprocess
import tomllib

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))


def _defaults():
    try:
        with open(os.path.join(ROOT, "release", "pipeline.toml"), "rb") as f:
            return tomllib.load(f).get("defaults", {})
    except (OSError, ValueError):
        return {}


_D = _defaults()
NODE_PICK = _D.get("nodes") or ["https://node.btlabs.uk"]
RELAY_PICK = _D.get("epicboxes") or ["epicbox.btlabs.uk"]

TEST_CONFIRMATIONS = int(os.environ.get("REL_TRUST_CONFIRMATIONS") or "1")


def _arb():
    try:
        with open(os.path.join(ROOT, "app", "lib", "l10n", "app_en.arb"), encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


_ARB = _arb()


def label(key, fallback):
    v = _ARB.get(key)
    return v if isinstance(v, str) and v and "{" not in v else fallback


def _previous_arb():
    """The previous release's English strings (git ref REL_PREVIOUS_REF of this checkout, else the tag
    v<REL_PREVIOUS_VERSION>), {} when neither is set or the ref is not here. The ref matters for a
    rebuild: 26.10.24-r2 carries version 26.10.24 but its own tag."""
    ref = (os.environ.get("REL_PREVIOUS_REF") or "").strip()
    v = (os.environ.get("REL_PREVIOUS_VERSION") or "").strip()
    if not ref and not v:
        return {}
    tag = ref or (v if v.startswith("v") else "v" + v)
    try:
        r = subprocess.run(["git", "-C", ROOT, "show", f"{tag}:app/lib/l10n/app_en.arb"],
                           capture_output=True, text=True, timeout=30)
        return json.loads(r.stdout) if r.returncode == 0 else {}
    except (OSError, ValueError, subprocess.SubprocessError):
        return {}


_PREV = []


def labels(key, *fallbacks):
    """Every text the label [key] has in the candidate and in the previous release, then
    [fallbacks] (older releases' words): for a step that runs before and after the update."""
    if not _PREV:
        _PREV.append(_previous_arb())
    out = []
    for v in (_ARB.get(key), _PREV[0].get(key), *fallbacks):
        if isinstance(v, str) and v and "{" not in v and v not in out:
            out.append(v)
    return tuple(out)


ADDED_BY_YOU = label("slAddedByYou", "Added by you")  # a server the user typed in
CURRENT = label("serverCurrent", "Current")            # the server in use
# The server in use, in every release's words: "Current" to 26.10.24, "In use" after.
CURRENTS = labels("serverCurrent", "Current", "In use")
# A server's row before its health is read: "Health unknown" to 26.10.24, "Status unknown" after.
HEALTH_UNKNOWN = labels("serverHealthNone", "Health unknown", "Status unknown")

# The phone app's words the Android trust driver taps, waits for or reads: from the ARB, so a
# copy change lands here instead of as a silent miss on an emulator. The same in the candidate
# and 26.10.24-r2 unless a labels() tuple says otherwise.
RECENT_ACTIVITY = label("homeRecentActivity", "Recent activity")
NO_PAYMENTS = label("homeNoPayments", "No payments yet")
LOCK_WALLET = label("homeLockTooltip", "Lock wallet")
SETTINGS = label("homeSettingsTooltip", "Settings")
ACTIVITY = label("historyTitle", "Activity")
SKIP_TOUR = label("tourPhoneSkip", "Skip tour")
NOT_NOW = label("restoreImportNotNow", "Not now")
CREATE_WALLET = label("firstRunCreate", "Create a new wallet")
RESTORE_WALLET = label("firstRunRestore", "Restore from phrase")
PIN_CHOOSE = "Choose a 6-digit PIN"  # pinChooseTitle is a plural ({digits}): its 6-digit reading
PIN_AGAIN = label("pinConfirmTitle", "Enter the PIN again")
PIN_PROMPT = label("pinPromptTitle", "Enter your PIN")
PHRASE_HELPER = "All the words"      # the start of restorePhraseHelper
BACK_UP = label("homeBackupCardButton", "Back up")
SECURITY = label("settingsSectionSecurity", "Security")
PHRASE_AGREE = label("backupCopyAgree", "I will keep the phrase private")
SHOW_PHRASE = label("backupShowPhrase", "Show recovery phrase")
DONE = label("commonDone", "Done")
CLOSE = label("commonClose", "Close")
CONTINUE = label("commonContinue", "Continue")
SAVE = label("commonSave", "Save")
RECEIVE_ADDRESS = label("receiveAddressLabel", "Epicbox address")
NODE = label("netStatusNode", "Node")
SYNCED = label("netStatusSynced", "Synced")
TOTAL = label("homeTileTotal", "Total")
SPENDABLE = label("homeBalanceSpendable", "Spendable")
REMOVE = label("slRemove", "Remove")
SWITCH = label("slSwitch", "Switch")
CLEAR = label("slClear", "Clear")
APPEARANCE = label("settingsSectionDisplay", "Appearance")
THEME = label("settingsTheme", "Theme")
CURRENCY = label("settingsCurrency", "Currency")
LANGUAGE = label("languageSetting", "Language")
SHOW_PRICES = label("settingsShowPrices", "Show prices")
ADVANCED = label("advTitle", "Advanced")
SHOWS_MORE = label("advShowsHeader", "Shows more")
TECHNICAL_DETAILS = label("advTechnical", "Technical details")
NODE_FAILOVER = label("advNodeFailover", "Node failover")
CONF_FEWER = label("advConfirmationsFewer", "Fewer confirmations")
CONF_MORE = label("advConfirmationsMore", "More confirmations")
EPICBOX_METHOD = label("methodEpicbox", "Epicbox")
CLEAR_RECIPIENT = label("sendClearRecipient", "Clear recipient")
AMOUNT_STEP = label("sendStepAmount", "Amount")

# Wallet levels (main after 26.10.24): a fresh install answers "Pick your view" (26.10.25 wording) before Welcome;
# an existing install updated to a build with levels is settled to level 3 and never asked.
# Since first-run-basic (Nov 2026) a fresh install shows no picker: it starts at level 1, with Create, Restore and a
# Tor only switch on its first screen; the picker is in Settings › Advanced. The picker words below are the previous
# releases' (the keys left the candidate's ARB). A previous release without the picker creates its wallet at level 1:
# the driver must then pick Deep end in Settings › Advanced before its settings steps.
LEVEL_PICK_TITLE = label("lvPickTitle", "Pick your view")
LEVEL_DEEP_END = label("lvPickStopThree", "Deep end")                # the dial's level-3 stop
LEVEL_UNDERCOVER = "Undercover from the start"                       # the previous releases' first-start switch
LEVEL_ROW = label("levelRowTitle", "Wallet view")                   # Settings › Advanced, first row
LEVEL_THREE = label("levelThreeTitle", "Let me explore everything")  # that row's value at level 3
LEVELS_BUILT = "levelRowTitle" in _ARB                               # the candidate has levels
DESK_DEPTH = label("lvPickDepth", "View")  # desktop: the dial's group, Settings › Advanced and About
LEVEL_KEY = "app.level"  # the stored level (app/lib/src/levels/wallet_level.dart levelKey): 1, 2, 3 or ask


def level_after_update(value, before=None):
    """An install from before wallet levels, updated to a build with them, is level 3 and never asked;
    one from a release with levels keeps the level it had ([before], stored the same way). [value] is
    the stored level or the level the screen names; (True | False | None, why), None when the build
    has no levels (nothing stored or shown)."""
    v = str(value).strip() if value is not None else ""
    if not v:
        return None, "no wallet level stored or shown (a build without levels)"
    b = str(before).strip() if before is not None else ""
    if b and b != "ask":
        if v == b:
            return True, "level %s, as the previous release stored it" % v
        return False, "level %s after the update; the previous release stored level %s" % (v, b)
    if v in ("3", LEVEL_DEEP_END, LEVEL_THREE):
        return True, "level 3 (%s), as an existing install must be" % LEVEL_DEEP_END
    if v == "ask":
        return False, "the update took the install for a new one: its level is still to be asked, and nothing connects until it is"
    return False, "level %s after the update; an existing install must be level 3 (%s)" % (v, LEVEL_DEEP_END)
# The confirmations setting's row: "1 confirmation, …" / "6 confirmations, …" (singular at one).
CONF_ROW = re.compile(r"(\d+) confirmations?, ")


def address_key(address):
    """The key part of an Epicbox address (before @host), "" when none was read."""
    return (address or "").split("@")[0].strip()


def same_wallet(before, after):
    """(True, key) when both addresses were read and are the same wallet; else (False, why). An
    address that could not be read never counts as the same (an empty read equals an empty read)."""
    a0, a1 = address_key(before), address_key(after)
    if not a1:
        return False, "no Epicbox address could be read after the update"
    if not a0:
        return False, "the previous release's address could not be read, so the wallet cannot be compared"
    if a0 != a1:
        return False, "a different wallet opened: address %s…%s, was %s…%s" % (a1[:6], a1[-6:], a0[:6], a0[-6:])
    return True, a1


# ---- the data a release leaves in the data folder: names in one place -------------------------------
# The first release that keeps the wallet database encrypted (wallet.enc.sqlite3). Checks of the file
# set below apply to a candidate at or after it.
FIRST_ENCRYPTED_RELEASE = "26.10.25"
STORE_DIR = "lepic"                        # under each wallet's folder: wallets/<name>/lepic/
STORE_PLAIN = "wallet.sqlite3"             # + -wal, -shm
STORE_ENC = "wallet.enc.sqlite3"           # + -wal, -shm
STORE_CHECK = "wallet.enc.sqlite3.check"   # the key check beside it
STORE_TMP = "wallet.enc.sqlite3.tmp"       # a migration in progress: never left behind
STORE_PRE = "wallet.sqlite3.pre-encryption"  # the plain database, set aside after a verified migration
# The first release that deletes STORE_PRE once the wallet is unlocked on the encrypted database (LEPIC
# retirePlainStore, e244794f0): right after the migration's own unlock, so the update leaves no STORE_PRE.
FIRST_RETIRING_RELEASE = "26.11.2"
# Plain app files stay in place beside their sealed copies until a later release retires them.
META_PLAIN, META_SEALED = "wfe_meta.json", "wfe_meta.sealed"          # in each wallet's folder
CONTACTS_PLAIN, CONTACTS_SEALED = "contacts.json", "contacts.sealed"  # in the data folder
CONTACTS_KEYS_DIR = "contacts.keys"        # contacts.keys/<walletId>.key: the address book's key, wrapped per wallet
CONTACTS_WRAP_SUFFIX = ".key"              # contacts.keys/<walletId>.key (the store-encryption detail plan says .wfeh; ".wfeh" is the history backup)
LAN_NODES_FILE = "lan_nodes.json"          # {"plainHttp": [...]}: never written again by 26.10.25
SETTINGS_TOML = "settings.toml"            # [node] plain_http


def version_tuple(v):
    """(26, 10, 25) of "26.10.25", "26.10.24-r2" or "v26.10.25"; () when none."""
    return tuple(int(x) for x in re.findall(r"\d+", str(v or "").split("-")[0]))


def encrypts_store(version):
    """Whether a release at [version] keeps its wallet database encrypted."""
    return bool(version_tuple(version)) and version_tuple(version) >= version_tuple(FIRST_ENCRYPTED_RELEASE)


def retires_plain_copy(version):
    """Whether a release at [version] deletes the plain database's set-aside copy (STORE_PRE) on unlock."""
    return bool(version_tuple(version)) and version_tuple(version) >= version_tuple(FIRST_RETIRING_RELEASE)
