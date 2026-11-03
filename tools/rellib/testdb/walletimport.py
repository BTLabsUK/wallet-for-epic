# SPDX-License-Identifier: Apache-2.0
"""`testdb wallets import`: reads the harness's own test wallets from their files (read-only) and emits
wallet.put / wallet.address / wallet.snapshot. Test wallets only. Event ids come from the file's mtime,
so importing twice changes nothing. Nothing secret is printed."""
import json
import os
import re

from . import client, writer

HOME = os.path.expanduser("~")
ADDR = re.compile(r"\bes[A-Za-z0-9]{40,}@[\w.\-]+")
PHRASE_INTRO = "Your recovery phrase is:"


def _read(path):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read().strip()
    except OSError:
        return None


def _ts(path):
    return writer.norm_ts(os.path.getmtime(path)) if os.path.exists(path) else client.now_ts()


def _put(db, report, name, role, files, **f):
    ts = max([_ts(p) for p in files if os.path.exists(p)] or [client.now_ts()])
    client.emit("wallet.put", source="import", db=db, eid="wimport-%s-put-%s" % (name, ts), ts=ts, name=name, role=role, **f)
    report.append("wallet %-22s %-8s from %s" % (name, role, ", ".join(os.path.basename(os.path.dirname(p)) + "/" + os.path.basename(p)
                                                                  for p in files if os.path.exists(p))))


def _address(db, name, role, kind, address, ts):
    client.emit("wallet.address", source="import", db=db, eid="wimport-%s-addr-%s" % (name, address), ts=ts,
                name=name, role=role, kind=kind, address=address)


def run(db):
    report, missing = [], []
    cfg = os.path.join(HOME, ".config", "btlabs")

    # Q and the Android trust wallet: phrase, pin, wallet-pass; Q's NOTES.md names its Epicbox address
    for folder, name, role in (("rel-wallet-q", "wallet-q", "qa"), ("rel-trust-android", "trust-android", "qa")):
        d = os.path.join(cfg, folder)
        phrase, pin, pw = (_read(os.path.join(d, x)) for x in ("phrase", "pin", "wallet-pass"))
        if not phrase:
            missing.append("%s: no phrase file" % folder)
            continue
        notes = _read(os.path.join(d, "NOTES.md")) or ""
        _put(db, report, name, role, [os.path.join(d, x) for x in ("phrase", "pin", "wallet-pass", "NOTES.md")],
             platform="android" if name == "trust-android" else None, phrase=phrase, password=pw,
             origin=folder, note=("app PIN %s; " % pin if pin else "") + ("mainnet; restored into the app by the trust-android lane"))
        m = ADDR.search(notes)
        if m:
            _address(db, name, role, "epicbox", m.group(0), _ts(os.path.join(d, "NOTES.md")))
        else:
            missing.append("%s: no address on file" % name)

    # lane seeds: <platform>-<variant>/phrase and meta.json (last balance, fundings, birth)
    seeds = os.path.join(cfg, "rel-lane-seeds")
    for lane in sorted(os.listdir(seeds)) if os.path.isdir(seeds) else []:
        d = os.path.join(seeds, lane)
        phrase = _read(os.path.join(d, "phrase")) if os.path.isdir(d) else None
        if not phrase:
            continue
        try:
            meta = json.loads(_read(os.path.join(d, "meta.json")) or "{}")
        except ValueError:
            meta = {}
        name = "lane-" + lane
        birth = meta.get("birth") or {}
        note = "birth height %s (%s); %d fundings" % (birth.get("height"), birth.get("method"), len(meta.get("fundings") or []))
        _put(db, report, name, "lane", [os.path.join(d, "phrase"), os.path.join(d, "meta.json")],
             platform=lane.split("-")[0], lane="trust-" + lane, phrase=phrase, created=meta.get("created_at"),
             origin="rel-lane-seeds", note=note)
        last = meta.get("last") or {}
        if last.get("at"):
            at = last["at"] + (".000000Z" if not last["at"].endswith("Z") else "")
            client.emit("wallet.snapshot", source="import", db=db, eid="wimport-%s-snap-%s" % (name, at), ts=at,
                        name=name, role="lane", run=last.get("run"), lane="trust-" + lane,
                        spendable=last.get("spendable"), total=last.get("total"))
    missing.append("lane wallets: no addresses on file (meta.json holds balances and fundings only)")

    # funder P: password in ~/.epic/qa-funder/.password, phrase in RECOVERY-PHRASE.txt (the init output),
    # address REL_P_ADDR in drivers/core/checks.py. ~/.config/btlabs/p-pass exists but is empty.
    qa = os.path.join(HOME, ".epic", "qa-funder")
    pw = _read(os.path.join(qa, ".password"))
    text = _read(os.path.join(qa, "RECOVERY-PHRASE.txt")) or ""
    phrase = None
    if PHRASE_INTRO in text:
        after = text.split(PHRASE_INTRO, 1)[1].strip().splitlines()
        phrase = next((l.strip() for l in after if l.strip()), None)
    if phrase or pw:
        files = [os.path.join(qa, ".password"), os.path.join(qa, "RECOVERY-PHRASE.txt")]
        _put(db, report, "funder-p", "funder", files, platform="linux", phrase=phrase, password=pw,
             origin="~/.epic/qa-funder", note="QA funder P (mainnet, epic-wallet CLI on the build machine)")
        checks = _read(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "drivers", "core", "checks.py")) or ""
        m = ADDR.search(checks)
        if m:
            _address(db, "funder-p", "funder", "epicbox", m.group(0), _ts(os.path.join(qa, ".password")))
        else:
            missing.append("funder-p: REL_P_ADDR not found in drivers/core/checks.py")
        if not _read(os.path.join(cfg, "p-pass")):
            missing.append("~/.config/btlabs/p-pass is empty (the password came from ~/.epic/qa-funder/.password)")
    else:
        missing.append("funder-p: neither .password nor RECOVERY-PHRASE.txt readable")
    writer.drain(db, wait=True)
    print("\n".join(report))
    for m in missing:
        print("not mapped: " + m)
