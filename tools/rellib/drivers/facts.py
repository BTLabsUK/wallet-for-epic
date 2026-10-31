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
NODE_PICK = _D.get("nodes") or ["https://node.btlabs.uk", "https://node.epicnet.us:3413", "https://node.epiccash.com"]
RELAY_PICK = _D.get("epicboxes") or ["epicbox.stackwallet.com", "epicbox.epicnet.us", "epicbox.epiccash.com"]

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


ADDED_BY_YOU = label("slAddedByYou", "Added by you")  # a server the user typed in
CURRENT = label("serverCurrent", "Current")            # the server in use
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
