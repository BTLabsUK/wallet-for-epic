# SPDX-License-Identifier: Apache-2.0
"""G4 update trust: what the data folder must look like after an update that encrypts the wallet
database, as pure functions over file listings and hashes (so a driver, a dry run and a test judge
the same facts). Names come from facts.py.

A snapshot is [listing] (every file below the data folder, relative, "/" or "\\\\" separated) and
[hashes] ({relative path: sha256 hex} of the small plain files in WATCHED). Nothing here reads a disk.

Which expectation applies is decided by the folder BEFORE the update, never by the one after it:
a plain database before means the migration must have happened; an encrypted one before means it
must still be encrypted. A migration that silently did not happen therefore cannot pass as "not
applicable".
"""
import hashlib
import json
import os
import sys
import tomllib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import facts  # noqa: E402

WATCHED = (facts.META_PLAIN, facts.CONTACTS_PLAIN, facts.LAN_NODES_FILE)


def norm(listing):
    return sorted({str(p).replace("\\", "/").lstrip("/") for p in listing})


def sha256_bytes(b):
    return hashlib.sha256(b).hexdigest()


def watched_names(listing):
    """The files of [listing] whose bytes the checks compare."""
    return [p for p in norm(listing) if os.path.basename(p) in WATCHED]


def store_dirs(listing):
    """The folders that hold a wallet's database (`.../lepic`), from either kind of file in them."""
    names = {facts.STORE_PLAIN, facts.STORE_ENC, facts.STORE_CHECK, facts.STORE_PRE}
    out = set()
    for p in norm(listing):
        d, f = os.path.split(p)
        if os.path.basename(d) == facts.STORE_DIR and (f in names or f.startswith(facts.STORE_PLAIN) or f.startswith(facts.STORE_ENC)):
            out.add(d)
    return sorted(out)


def _names(listing, d):
    return {os.path.basename(p) for p in norm(listing) if os.path.dirname(p) == d}


def store_files(before, after):
    """(ok, why): the wallet database's file set after the update, per wallet folder."""
    dirs = sorted(set(store_dirs(before)) | set(store_dirs(after)))
    if not dirs:
        return False, "no wallet database folder (%s/) in the data folder before or after" % facts.STORE_DIR
    problems, good = [], []
    for d in dirs:
        b, a = _names(before, d), _names(after, d)
        was_plain = facts.STORE_PLAIN in b and facts.STORE_ENC not in b
        was_enc = facts.STORE_ENC in b
        miss = []
        if facts.STORE_ENC not in a:
            miss.append("%s is missing" % facts.STORE_ENC)
        if facts.STORE_CHECK not in a:
            miss.append("%s is missing" % facts.STORE_CHECK)
        left = [n for n in (facts.STORE_PLAIN, facts.STORE_PLAIN + "-wal", facts.STORE_PLAIN + "-shm") if n in a]
        if left:
            miss.append("the plain database is still there (%s)" % ", ".join(left))
        if facts.STORE_TMP in a:
            miss.append("%s was left behind (a migration did not finish)" % facts.STORE_TMP)
        if was_plain and facts.STORE_PRE not in a:
            miss.append("%s is missing (the plain database was not set aside)" % facts.STORE_PRE)
        if not (was_plain or was_enc):
            miss.append("no database before the update (%s)" % (", ".join(sorted(b)) or "no files"))
        (problems if miss else good).append("%s: %s" % (d, "; ".join(miss)) if miss else d)
    if problems:
        return False, "; ".join(problems)
    return True, "%s: %s and %s present, no plain database%s" % (
        ", ".join(good), facts.STORE_ENC, facts.STORE_CHECK,
        ", %s kept" % facts.STORE_PRE if any(facts.STORE_PLAIN in _names(before, d) for d in good) else "")


def wallet_dirs(listing):
    """The wallet folders that hold app files (wfe_meta.*), or a database."""
    out = {os.path.dirname(p) for p in norm(listing) if os.path.basename(p) in (facts.META_PLAIN, facts.META_SEALED)}
    out |= {os.path.dirname(d) for d in store_dirs(listing)}
    return sorted(out)


def app_files(before, before_hashes, after, after_hashes, wallet_ids=()):
    """(ok, why): the app files after the update. The sealed copies are there, the plain ones are still
    in place and byte-identical, and the address book's key is wrapped for each wallet."""
    b, a = set(norm(before)), set(norm(after))
    miss = []
    seen = []
    for d in wallet_dirs(before):
        plain = (d + "/" if d else "") + facts.META_PLAIN
        sealed = (d + "/" if d else "") + facts.META_SEALED
        if plain not in b:
            continue
        seen.append(plain)
        if plain not in a:
            miss.append("%s is gone" % plain)
        elif before_hashes.get(plain) != after_hashes.get(plain):
            miss.append("%s changed" % plain)
        if sealed not in a:
            miss.append("%s is missing" % sealed)
    if facts.CONTACTS_PLAIN in b:
        seen.append(facts.CONTACTS_PLAIN)
        if facts.CONTACTS_PLAIN not in a:
            miss.append("%s is gone" % facts.CONTACTS_PLAIN)
        elif before_hashes.get(facts.CONTACTS_PLAIN) != after_hashes.get(facts.CONTACTS_PLAIN):
            miss.append("%s changed" % facts.CONTACTS_PLAIN)
        if facts.CONTACTS_SEALED not in a:
            miss.append("%s is missing" % facts.CONTACTS_SEALED)
        keys = sorted(p for p in a if p.startswith(facts.CONTACTS_KEYS_DIR + "/") and p.endswith(facts.CONTACTS_WRAP_SUFFIX))
        want = ["%s/%s%s" % (facts.CONTACTS_KEYS_DIR, w, facts.CONTACTS_WRAP_SUFFIX) for w in wallet_ids]
        if not keys:
            miss.append("no %s/<walletId>%s" % (facts.CONTACTS_KEYS_DIR, facts.CONTACTS_WRAP_SUFFIX))
        else:
            miss += ["%s is missing" % w for w in want if w not in a]
    if not seen:
        return False, "no %s or %s in the previous release's data folder, so nothing to compare" % (
            facts.META_PLAIN, facts.CONTACTS_PLAIN)
    if miss:
        return False, "; ".join(miss)
    return True, "%s: plain files unchanged beside their sealed copies%s" % (
        ", ".join(seen), "; address-book key wrapped for %s" % ", ".join(wallet_ids) if wallet_ids else "")


def _toml(text):
    try:
        return tomllib.loads(text or "")
    except (tomllib.TOMLDecodeError, TypeError):
        return None


def host_key(url):
    """host:port of an address, lower case, 80 when it names no port (as the app matches nodes)."""
    u = str(url or "").strip()
    if "://" in u:
        u = u.split("://", 1)[1]
    u = u.split("/", 1)[0]
    if ":" not in u:
        u += ":80"
    return u.lower()


def lan_nodes(old_text, old_sha_before, old_sha_after, settings_text):
    """(ok, why): `[node] plain_http` of settings.toml holds the agreements lan_nodes.json held for the
    nodes in the Node list, and lan_nodes.json is untouched. [old_text]: the file as the previous
    release left it ({"plainHttp": [...]})."""
    if old_text is None:
        return False, "the previous release left no %s to compare (nothing was seeded)" % facts.LAN_NODES_FILE
    try:
        old = {host_key(u) for u in (json.loads(old_text).get("plainHttp") or []) if isinstance(u, str)}
    except (ValueError, AttributeError):
        return False, "%s from before the update is not {\"plainHttp\": [...]}" % facts.LAN_NODES_FILE
    if not old:
        return False, "%s from before the update agrees for no node" % facts.LAN_NODES_FILE
    if old_sha_after is None:
        return False, "%s is gone after the update" % facts.LAN_NODES_FILE
    if old_sha_before != old_sha_after:
        return False, "%s changed during the update" % facts.LAN_NODES_FILE
    t = _toml(settings_text)
    if t is None:
        return False, "%s is missing or not TOML after the update" % facts.SETTINGS_TOML
    node = t.get("node") or {}
    listed = {host_key(u) for u in node.get("servers") or [] if isinstance(u, str)}
    agreed = {host_key(u) for u in node.get("plain_http") or [] if isinstance(u, str)}
    want = old & listed
    if not want:
        return False, "none of the nodes %s agreed for is in the Node list after the update (%s)" % (
            facts.LAN_NODES_FILE, ", ".join(sorted(listed)) or "empty")
    gone = sorted(want - agreed)
    if gone:
        return False, "[node] plain_http lacks %s (lan_nodes.json agreed for them; plain_http holds %s)" % (
            ", ".join(gone), ", ".join(sorted(agreed)) or "nothing")
    return True, "[node] plain_http holds %s, as %s did; %s unchanged" % (
        ", ".join(sorted(want)), facts.LAN_NODES_FILE, facts.LAN_NODES_FILE)


def contact_note(want_contact, want_note, before_hashes, after_hashes, shown_contact, shown_note, how):
    """(ok, why): the contact and the note made on the previous release are still there. The plain
    files are byte-identical (the address book and notes live in them), and [shown_contact] /
    [shown_note] say whether the app shows them (True / False; None where nothing reads the screen:
    only the files count, and [how] says so)."""
    miss = []
    for name in (facts.CONTACTS_PLAIN, facts.META_PLAIN):
        ps = [p for p in before_hashes if os.path.basename(p) == name]
        if not ps:
            miss.append("no %s from before the update to compare" % name)
        for p in ps:
            if before_hashes[p] != after_hashes.get(p):
                miss.append("%s changed" % p)
    if shown_contact is False:
        miss.append("contact %r is not in the address book after the update" % want_contact)
    if shown_note is False:
        miss.append("note %r is not shown after the update" % want_note)
    if miss:
        return False, "; ".join(miss)
    return True, "contact %r and note %r kept (%s)" % (want_contact, want_note, how)


# ---- offline: judge two data folders on disk (a dry run of the file checks, no app, no rig) ---------

def snapshot_dir(root):
    """(listing, hashes) of a data folder on disk, without logs, tor, cache and lock files."""
    listing, hashes = [], {}
    for dp, _dn, fn in os.walk(root):
        rel = os.path.relpath(dp, root)
        if rel.split(os.sep)[0] in ("logs", "tor", "cache"):
            continue
        for f in fn:
            if f.endswith((".lock", ".log")) or f.startswith("LOCK"):
                continue
            p = os.path.normpath(os.path.join(rel, f)).replace(os.sep, "/")
            listing.append(p)
            if f in WATCHED:
                with open(os.path.join(dp, f), "rb") as fh:
                    hashes[p] = sha256_bytes(fh.read())
    return sorted(listing), hashes


def _text(root, rel):
    try:
        with open(os.path.join(root, rel), encoding="utf-8") as f:
            return f.read()
    except OSError:
        return None


def judge(before_root, after_root):
    """[(check, ok, why)] for the file-set checks of two data folders (before and after an update)."""
    bl, bh = snapshot_dir(before_root)
    al, ah = snapshot_dir(after_root)
    try:
        ids = [w["id"] for w in json.loads(_text(after_root, "wallets.json") or "{}").get("wallets") or [] if w.get("id")]
    except (ValueError, AttributeError):
        ids = []
    return [("store_encrypted", *store_files(bl, al)), ("app_files_kept", *app_files(bl, bh, al, ah, ids)),
            ("lan_nodes_kept", *lan_nodes(_text(before_root, facts.LAN_NODES_FILE), bh.get(facts.LAN_NODES_FILE),
                                          ah.get(facts.LAN_NODES_FILE), _text(after_root, facts.SETTINGS_TOML)))]


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("usage: migration.py <data folder before the update> <data folder after it>")
    bad = 0
    for check, ok, why in judge(sys.argv[1], sys.argv[2]):
        print("%s %s: %s" % ("ok  " if ok else "FAIL", check, why))
        bad += not ok
    sys.exit(1 if bad else 0)
