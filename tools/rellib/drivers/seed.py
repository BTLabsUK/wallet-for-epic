# SPDX-License-Identifier: Apache-2.0
"""G4 update trust: the user's simple settings, seeded into the previous release's own files.

Theme, Technical details, the wallet's label and its minimum confirmations are written straight into
the files the previous release keeps them in, while it is closed, instead of being clicked through its
screens (the custom node and relay still go through the screens: that is where #143 broke). Every
change starts from the file as that release wrote it and touches only the seeded values, so the
format stays the release's own; a file that does not look the way it is expected to fails the seed
instead of guessing. The after-update checks are unchanged: each seeded value must survive.

Where a desktop release keeps them (26.10.23; platform-neutral, the store is the keyring on Linux and
a DPAPI file on Windows):
  desk store "desk.settings"       JSON: "theme", "advanced": {"features": [...]}
  desk store "desk.wallet.<chain>" JSON: "name" (the label the sidebar shows)
  wallets.json                     the wallet's "label" (2-space indent)
  <dataDir>/lepic/wallet.sqlite3   settings row wallet.minimum_confirmations (text)

A fresh install keeps only what differs from its defaults (26.10.23: {"tourSeen":true}); the whole
desk.settings object is written the first time a setting is saved. So fixtures/desk-settings-
<version>.json holds that whole object as the release wrote it once (a fresh wallet, only the theme
changed), and a fresh file is laid over it: the fixture gives the release's own keys, order and
defaults, the file its current values. A version without a fixture of its own uses the newest older
one (the run says which); the file a run starts from is kept in its seed/ folder.
"""
import glob
import json
import os
import re
import sqlite3

FIXTURES = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fixtures")

SEED = {"theme": "light", "technical_details": True, "confirmations": 4}
TECH = "technicalDetails"
CONF_KEY = "wallet.minimum_confirmations"


class SeedError(Exception):
    """A file is not in the format the seed knows: nothing was written."""


def _obj(text, what):
    try:
        d = json.loads(text)
    except (TypeError, ValueError) as e:
        raise SeedError("%s is not JSON: %s" % (what, e))
    if not isinstance(d, dict):
        raise SeedError("%s is not a JSON object" % what)
    return d


def _ver(v):
    return tuple(int(x) for x in re.findall(r"\d+", v.split("-")[0]))


def fixture_for(version):
    """(path, version) of the desk.settings fixture for a release: its own, else the newest older one;
    None when there is none."""
    have = []
    for path in glob.glob(os.path.join(FIXTURES, "desk-settings-*.json")):
        v = os.path.basename(path)[len("desk-settings-"):-len(".json")]
        if _ver(v) <= _ver(version):
            have.append((_ver(v), path, v))
    return max(have)[1:] if have else None


def desk_settings(text, theme, technical_details, template=None):
    """desk.settings with the theme and the Technical details switch set; compact, as Dart writes it.
    [template]: the release's whole object (a fixture), under a fresh file that lacks the keys."""
    d = _obj(text, "desk.settings")
    if template is not None and ("theme" not in d or "advanced" not in d):
        base = _obj(template, "the desk.settings fixture")
        adv = dict(base.get("advanced") or {}, **(d.get("advanced") or {}))
        base.update(d)
        base["advanced"] = adv
        d = base
    adv = d.get("advanced")
    if "theme" not in d or not isinstance(adv, dict) or not isinstance(adv.get("features"), list):
        raise SeedError("desk.settings has no theme or advanced.features: %s" % sorted(d))
    d["theme"] = theme
    feats = [f for f in adv["features"] if f != TECH]
    adv["features"] = feats + [TECH] if technical_details else feats
    return json.dumps(d, separators=(",", ":"), ensure_ascii=False)


def desk_wallet(text, label):
    """desk.wallet.<chain> with the wallet's name set."""
    d = _obj(text, "desk.wallet")
    if "name" not in d:
        raise SeedError("desk.wallet has no name: %s" % sorted(d))
    d["name"] = label
    return json.dumps(d, separators=(",", ":"), ensure_ascii=False)


def wallets_json(text, wallet_id, label):
    """wallets.json with that wallet's label set."""
    d = _obj(text, "wallets.json")
    hit = [w for w in d.get("wallets") or [] if isinstance(w, dict) and w.get("id") == wallet_id]
    if len(hit) != 1 or "label" not in hit[0]:
        raise SeedError("wallets.json has no wallet %r with a label" % wallet_id)
    hit[0]["label"] = label
    return json.dumps(d, indent=2, ensure_ascii=False)


def wallet_db(path, confirmations):
    """The wallet database's minimum confirmations, in a closed wallet's own SQLite file (its -wal
    folded in, so the main file alone carries everything)."""
    if not 1 <= int(confirmations) <= 30:
        raise SeedError("confirmations %s outside 1-30" % confirmations)
    c = sqlite3.connect(path)
    try:
        cols = [r[1] for r in c.execute("pragma table_info(settings)")]
        if cols[:2] != ["key", "value"]:
            raise SeedError("wallet database has no settings(key, value) table: %s" % cols)
        with c:
            c.execute("insert into settings(key, value) values (?, ?) "
                      "on conflict(key) do update set value = excluded.value", (CONF_KEY, str(int(confirmations))))
        c.execute("pragma wal_checkpoint(truncate)")
        got = c.execute("select value from settings where key = ?", (CONF_KEY,)).fetchone()
    finally:
        c.close()
    if not got or got[0] != str(int(confirmations)):
        raise SeedError("wallet database did not keep %s = %s" % (CONF_KEY, confirmations))
