#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""The permanent wallet of each G4 update-trust lane: its recovery phrase and what the lanes recorded
about it. Every run restores the lane's wallet from the phrase through the previous release's own
screens (core/lane.py, start mode `seed`), so its coins stay in it between runs.

Store (outside the repo, like P's secrets), REL_TRUST_SEEDS_ROOT overrides the root:
    ~/.config/btlabs/rel-lane-seeds/                       0700
        bip39-english.txt                                  the BIP39 English list, checked by its sha256
        <platform>-<variant>/                              0700
            phrase                                         0600: 24 words, one line
            meta.json                                      0600: created_at, birth_height, birth_month,
                                                           last {spendable, total, run, at} (EPIC text),
                                                           fundings [{amount, at, run, slate8}]
            .lock                                          the lane holds flock on it for its whole run
No address and no word in meta.json. Nothing here ever prints, logs or returns a word but phrase().

CLI (python3 -I tools/rellib/drivers/core/lane_seed.py ...):
    init <lane>|all     a new phrase from secrets.token_bytes(32), birth = the node's tip and this month;
                        refuses to overwrite a phrase that exists
    check [lane ...]    the doctor's checks (tools/rel doctor also weighs P's balance)
    scan <dir|file>...  the full phrase or any 3 consecutive words of any lane seed, in text, binary and
                        .gz files; prints the paths of the files that hold one; exit 1 on a hit
"""
import datetime
import fcntl
import glob
import gzip
import hashlib
import json
import os
import re
import secrets
import sys
import time
import urllib.request

try:
    from .faults import HarnessFault
except ImportError:  # run as a script
    sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    from core.faults import HarnessFault

PLATFORMS = ("android", "linux", "windows")
VARIANTS = ("tor", "notor")
LANES = tuple("%s-%s" % (p, v) for p in PLATFORMS for v in VARIANTS)
# sha256 of the BIP39 English list as one word per line with a final newline (bitcoin/bips bip-0039/english.txt)
BIP39_SHA256 = "2f5eed53a4727b4bf8880d8f3f199efc90e58503646d9ff8eff3a2ed3b24dbda"
WORDLIST_NAME = "bip39-english.txt"
# Where this host has the list: the bip39 crate LEPIC builds with
WORDLIST_SOURCES = ("~/.cargo/registry/src/*/bip39-*/src/language/english.rs",)
NODES = ("https://node.btlabs.uk", "https://node.epicnet.us:3413", "https://node.epiccash.com")
NANO = 100000000


def root():
    return os.environ.get("REL_TRUST_SEEDS_ROOT") or os.path.expanduser("~/.config/btlabs/rel-lane-seeds")


def lane_name(platform, variant):
    return "%s-%s" % (platform, variant)


# ---- the word list -----------------------------------------------------------------------------------

_WORDS = None


def _list_of(text):
    """The words of a .txt list (one per line) or of the bip39 crate's english.rs (quoted)."""
    quoted = re.findall(r'"([a-z]+)"', text)
    return quoted if len(quoted) == 2048 else [w.strip() for w in text.splitlines() if w.strip()]


def _good(words):
    return len(words) == 2048 and hashlib.sha256(("\n".join(words) + "\n").encode()).hexdigest() == BIP39_SHA256


def words():
    """The BIP39 English list, from the store's copy, REL_BIP39_WORDS or the bip39 crate in the cargo
    registry; any copy must match BIP39_SHA256. The store keeps a checked copy."""
    global _WORDS
    if _WORDS:
        return _WORDS
    own = os.path.join(root(), WORDLIST_NAME)
    cands = [own] + ([os.environ["REL_BIP39_WORDS"]] if os.environ.get("REL_BIP39_WORDS") else [])
    for pat in WORDLIST_SOURCES:
        cands += sorted(glob.glob(os.path.expanduser(pat)), reverse=True)
    for c in cands:
        try:
            with open(c, encoding="utf-8") as f:
                w = _list_of(f.read())
        except OSError:
            continue
        if _good(w):
            _WORDS = w
            if c != own and os.path.isdir(root()):
                _write(own, "\n".join(w) + "\n")
            return w
    raise HarnessFault("seed", "no BIP39 English list with sha256 %s… found (looked in %s)" % (BIP39_SHA256[:12], ", ".join(cands)))


# ---- phrases -----------------------------------------------------------------------------------------

def encode(entropy):
    """BIP39: entropy (16 or 32 bytes) -> its words, with the checksum."""
    if len(entropy) not in (16, 32):
        raise ValueError("entropy must be 16 or 32 bytes")
    w = words()
    bits = len(entropy) * 8
    n = (int.from_bytes(entropy, "big") << (bits // 32)) | (hashlib.sha256(entropy).digest()[0] >> (8 - bits // 32))
    count = (bits + bits // 32) // 11
    return " ".join(w[(n >> (11 * (count - 1 - i))) & 2047] for i in range(count))


def new_phrase():
    return encode(secrets.token_bytes(32))


def validate(phrase):
    """(True, "24 words, checksum good") or (False, why); why never holds a word."""
    w = words()
    index = {x: i for i, x in enumerate(w)}
    ws = (phrase or "").split()
    if len(ws) not in (12, 24):
        return False, "%d words, not 12 or 24" % len(ws)
    bad = [i + 1 for i, x in enumerate(ws) if x not in index]
    if bad:
        return False, "word %s not in the BIP39 English list" % ", ".join(map(str, bad))
    n = 0
    for x in ws:
        n = (n << 11) | index[x]
    cs = len(ws) // 3
    ent = (n >> cs).to_bytes(cs * 4, "big")
    if hashlib.sha256(ent).digest()[0] >> (8 - cs) != n & ((1 << cs) - 1):
        return False, "%d words with a wrong checksum" % len(ws)
    return True, "%d words, checksum good" % len(ws)


def fingerprint(phrase):
    """sha256 of the phrase's words, to compare seeds in memory; never stored or printed."""
    return hashlib.sha256(" ".join(phrase.split()).encode()).hexdigest()


# ---- files -------------------------------------------------------------------------------------------

def _write(path, text):
    """A 0600 file written whole: a temporary file renamed into place."""
    tmp = "%s.tmp-%d" % (path, os.getpid())
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        f.write(text)
        f.flush()
        os.fsync(f.fileno())
    os.chmod(tmp, 0o600)
    os.replace(tmp, path)


def _mkdir(path):
    os.makedirs(path, mode=0o700, exist_ok=True)
    os.chmod(path, 0o700)


def epic(nano):
    """EPIC text of nanoEPIC, exact: 7120000 -> '0.0712'."""
    from decimal import Decimal
    return format((Decimal(int(nano)) / NANO).normalize(), "f") if nano is not None else None


def nano(text):
    from decimal import Decimal
    return int((Decimal(str(text)) * NANO).to_integral_value()) if text is not None else None


class LaneSeed:
    """One lane's seed folder. phrase() is the only call that returns words."""

    def __init__(self, lane, base=None):
        if lane not in LANES:
            raise ValueError("unknown lane %r (one of %s)" % (lane, ", ".join(LANES)))
        self.lane = lane
        self.dir = os.path.join(base or root(), lane)
        self.phrase_path = os.path.join(self.dir, "phrase")
        self.meta_path = os.path.join(self.dir, "meta.json")
        self.lock_path = os.path.join(self.dir, ".lock")
        self._lock = None

    def exists(self):
        return os.path.isfile(self.phrase_path)

    def phrase(self):
        """The words, checked; a HarnessFault (naming no word) when the file is missing or not a phrase."""
        try:
            with open(self.phrase_path, encoding="utf-8") as f:
                p = " ".join(f.read().split())
        except OSError as e:
            raise HarnessFault("seed", "lane seed %s has no phrase (%s): lane_seed.py init %s" % (self.lane, e.strerror, self.lane))
        ok, why = validate(p)
        if not ok:
            raise HarnessFault("seed", "lane seed %s is not a valid phrase: %s" % (self.lane, why))
        return p

    def meta(self):
        try:
            with open(self.meta_path, encoding="utf-8") as f:
                return json.load(f)
        except (OSError, ValueError):
            return {}

    def _save_meta(self, m):
        _write(self.meta_path, json.dumps(m, indent=1) + "\n")

    def birth(self):
        m = self.meta()
        return {"height": m.get("birth_height"), "month": m.get("birth_month")}

    def last_spendable(self):
        """meta.last.spendable in nanoEPIC, or None when no lane recorded one."""
        return nano(((self.meta().get("last") or {}).get("spendable")))

    def create(self, phrase, birth_height, birth_month):
        """Writes a new seed; refuses (FileExistsError) when the lane has a phrase."""
        _mkdir(os.path.dirname(self.dir))
        _mkdir(self.dir)
        tmp = "%s.tmp-%d" % (self.phrase_path, os.getpid())
        fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(fd, "w") as f:
            f.write(phrase + "\n")
            f.flush()
            os.fsync(f.fileno())
        try:
            os.link(tmp, self.phrase_path)  # never replaces an existing phrase
        finally:
            os.unlink(tmp)
        self._save_meta({"created_at": time.strftime("%Y-%m-%dT%H:%M:%S"), "birth_height": birth_height,
                         "birth_month": birth_month, "last": None, "fundings": []})

    # ---- the lock

    def lock(self):
        """flock on .lock for the lane's whole run (released by unlock() or the process ending)."""
        _mkdir(self.dir)
        fd = os.open(self.lock_path, os.O_RDWR | os.O_CREAT, 0o600)
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            holder = os.read(fd, 32).decode(errors="replace").strip() or "?"
            os.close(fd)
            raise HarnessFault("seed", "lane seed %s in use by pid %s" % (self.lane, holder))
        os.ftruncate(fd, 0)
        os.write(fd, str(os.getpid()).encode())
        self._lock = fd

    def unlock(self):
        if self._lock is not None:
            try:
                fcntl.flock(self._lock, fcntl.LOCK_UN)
            finally:
                os.close(self._lock)
                self._lock = None

    def lock_holder(self):
        """None when the lock is free, else the pid written in it."""
        if not os.path.exists(self.lock_path):
            return None
        fd = os.open(self.lock_path, os.O_RDONLY)
        try:
            fcntl.flock(fd, fcntl.LOCK_SH | fcntl.LOCK_NB)
        except OSError:
            return os.read(fd, 32).decode(errors="replace").strip() or "?"
        finally:
            os.close(fd)
        return None

    # ---- what the lanes record

    def record_last(self, balance, run):
        """balance: the wallet data's {spendable, total} in nanoEPIC."""
        m = self.meta()
        m["last"] = {"spendable": epic(balance.get("spendable")), "total": epic(balance.get("total")), "run": run,
                     "at": time.strftime("%Y-%m-%dT%H:%M:%S")}
        self._save_meta(m)

    def record_funding(self, amount, run, slate):
        m = self.meta()
        m.setdefault("fundings", []).append({"amount": str(amount), "at": time.strftime("%Y-%m-%dT%H:%M:%S"), "run": run,
                                             "slate8": (slate or "")[:8] or None})
        self._save_meta(m)


def run_id():
    e = os.environ
    return e.get("REL_RUN_ID") or (os.path.basename(e["REL_RUN"].rstrip("/")) if e.get("REL_RUN") else "manual")


# ---- birth -------------------------------------------------------------------------------------------

def tip(nodes=None, timeout=15):
    """(height, node) from the first node that answers get_tip, BT Labs first."""
    tried = []
    for url in ([os.environ["REL_NODE"]] if os.environ.get("REL_NODE") else []) + list(nodes or NODES):
        if url in tried:
            continue
        tried.append(url)
        u = url if "://" in url else "https://" + url
        body = json.dumps({"jsonrpc": "2.0", "method": "get_tip", "params": [], "id": 1}).encode()
        req = urllib.request.Request(u.rstrip("/") + "/v2/foreign", data=body, headers={"content-type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=timeout) as r:
                h = json.loads(r.read(65536))["result"]["Ok"]["height"]
            return int(h), url
        except Exception:  # noqa: BLE001 — the next node
            continue
    raise HarnessFault("seed", "no node answered get_tip (tried %s)" % ", ".join(tried))


# ---- the leak scan -----------------------------------------------------------------------------------

LETTERS = re.compile(rb"[A-Za-z]+")
CHUNK = 4 << 20


class Needles:
    """What a scan looks for: every 3 consecutive words of the given phrases, kept only as salted
    hashes, so a scanner holds no word."""

    def __init__(self, phrases):
        self.salt = secrets.token_bytes(16)
        self.words = frozenset(words())
        self.hashes = set()
        for p in phrases:
            ws = p.lower().split()
            for i in range(len(ws) - 2):
                self.hashes.add(self._h(ws[i:i + 3]))

    def _h(self, three):
        return hashlib.sha256(self.salt + " ".join(three).encode()).digest()

    def __bool__(self):
        return bool(self.hashes)

    def in_stream(self, chunks):
        """True when 3 consecutive words of a phrase appear in the byte stream, any case, separated by
        anything that is not a letter."""
        win, carry = [], b""
        for chunk in chunks:
            data = carry + chunk
            carry = b""
            ms = list(LETTERS.finditer(data))
            if ms and ms[-1].end() == len(data) and chunk:
                carry = ms.pop().group(0)  # a word cut by the chunk's end: read with the next chunk
            for m in ms:
                w = m.group(0).lower().decode("ascii")
                if w in self.words:
                    win.append(w)
                    if len(win) >= 3 and self._h(win[-3:]) in self.hashes:
                        return True
                    if len(win) > 3:
                        del win[0]
                else:
                    win = []
        if carry:
            w = carry.lower().decode("ascii")
            if w in self.words:
                win.append(w)
                if len(win) >= 3 and self._h(win[-3:]) in self.hashes:
                    return True
        return False

    def in_file(self, path):
        opener = gzip.open if path.endswith(".gz") else open
        try:
            with opener(path, "rb") as f:
                head = f.read(CHUNK)
            wide = head.count(b"\0") * 4 > len(head) > 0  # UTF-16 text: its letters apart by NULs
            with opener(path, "rb") as f:
                if self.in_stream(iter(lambda: f.read(CHUNK), b"")):
                    return True
            if wide:
                with opener(path, "rb") as f:
                    return self.in_stream(c.replace(b"\0", b"") for c in iter(lambda: f.read(CHUNK), b""))
        except (OSError, EOFError, gzip.BadGzipFile):
            if opener is gzip.open:  # a .gz that is not one: its bytes as they are
                with open(path, "rb") as f:
                    return self.in_stream(iter(lambda: f.read(CHUNK), b""))
            raise
        return False


def scan(paths, phrases=(), skip=(), needles=None):
    """-> (files with a hit, files read). Symlinks are not followed; paths under `skip` are not read.
    [needles] (a Needles) in place of [phrases] for a phrase no longer held."""
    needles = needles if needles is not None else Needles(phrases)
    skip = [os.path.realpath(s) for s in skip]
    hits, n = [], 0

    def one(p):
        nonlocal n
        rp = os.path.realpath(p)
        if os.path.islink(p) or any(rp == s or rp.startswith(s + os.sep) for s in skip):
            return
        n += 1
        if needles and needles.in_file(p):
            hits.append(p)

    for top in paths:
        if os.path.isfile(top):
            one(top)
            continue
        for d, dirs, files in os.walk(top):
            dirs.sort()
            for f in sorted(files):
                one(os.path.join(d, f))
    return hits, n


# ---- the doctor's checks -----------------------------------------------------------------------------

def _mode(path):
    return os.stat(path).st_mode & 0o777


def doctor(lanes, p_spendable=None, funds_lanes=(), base=None):
    """[(level, line)] with level ok | FAIL | warn, for the lanes in a run's scope: seed present, modes
    0700/0600, 12/24 valid words, all seeds distinct, lock free, a balance on record; then whether P's
    spendable (EPIC text, None: not read) covers what the lanes take from P."""
    try:
        from . import checks  # the funds rule
    except ImportError:  # run as a script
        from core import checks
    out = []
    prints = {}
    for lane in LANES:
        s = LaneSeed(lane, base)
        if s.exists():
            try:
                prints.setdefault(fingerprint(s.phrase()), []).append(lane)
            except HarnessFault:
                pass
    need = 0
    for lane in lanes:
        s = LaneSeed(lane, base)
        if not s.exists():
            out.append(("FAIL", "lane seed %s: none in %s (lane_seed.py init %s)" % (lane, s.dir, lane)))
            continue
        modes = {"folder": (_mode(s.dir), 0o700), "phrase": (_mode(s.phrase_path), 0o600)}
        if os.path.exists(s.meta_path):
            modes["meta.json"] = (_mode(s.meta_path), 0o600)
        wrong = ["%s %o (want %o)" % (k, got, want) for k, (got, want) in modes.items() if got != want]
        try:
            p = s.phrase()
            ok, why = True, validate(p)[1]
        except HarnessFault as e:
            p, ok, why = None, False, e.what
        shared = [x for x in (prints.get(fingerprint(p), []) if p else []) if x != lane]
        holder = s.lock_holder()
        bad = wrong + ([] if ok else [why]) + (["the same phrase as %s" % ", ".join(shared)] if shared else []) + (
            ["in use by pid %s" % holder] if holder else [])
        last = s.last_spendable()
        if bad:
            out.append(("FAIL", "lane seed %s: %s" % (lane, "; ".join(bad))))
        else:
            out.append(("ok", "lane seed %s: %s, modes 0700/0600, distinct, lock free; last spendable %s" % (
                lane, why, "%s EPIC" % epic(last) if last is not None else "not on record yet")))
        if last is None:
            out.append(("warn", "lane seed %s: no balance on record (first run): counted as needing the top-up" % lane))
        amount, _ = checks.p_pays(last, True)
        need += nano(amount) + (nano(checks.FUND_AFTER) if lane in funds_lanes else 0)
        need += nano(checks.FEE_MAX) * (2 if lane in funds_lanes else 1)
    if lanes:
        if p_spendable is None:
            out.append(("warn", "P's spendable not read: the lanes take up to %s EPIC from P (fees included)" % epic(need)))
        elif nano(p_spendable) >= need:
            out.append(("ok", "P's spendable %s EPIC covers the lanes' %s EPIC (fees included)" % (epic(nano(p_spendable)), epic(need))))
        else:
            out.append(("FAIL", "P's spendable %s EPIC does not cover the lanes' %s EPIC (fees included)" % (
                epic(nano(p_spendable)), epic(need))))
    return out


# ---- CLI ---------------------------------------------------------------------------------------------

def _lanes(args):
    if not args or args == ["all"]:
        return list(LANES)
    bad = [a for a in args if a not in LANES]
    if bad:
        raise SystemExit("unknown lane %s (one of %s, or all)" % (", ".join(bad), ", ".join(LANES)))
    return args


def cmd_init(args):
    if len(args) != 1:
        raise SystemExit("usage: lane_seed.py init <lane>|all")
    lanes = _lanes(args)
    _mkdir(root())
    words()  # the list checked (and copied into the store) before anything is made
    height, node = tip()
    print("birth height %d from %s; month %s" % (height, node, datetime.date.today().strftime("%Y-%m")))
    known = {fingerprint(LaneSeed(x).phrase()) for x in LANES if LaneSeed(x).exists()}
    refused = 0
    for lane in lanes:
        s = LaneSeed(lane)
        if s.exists():
            print("%s: refused, a phrase exists (%s)" % (lane, s.phrase_path))
            refused += 1
            continue
        p = new_phrase()
        while fingerprint(p) in known:
            p = new_phrase()
        assert validate(p)[0]
        known.add(fingerprint(p))
        try:
            s.create(p, height, datetime.date.today().strftime("%Y-%m"))
        except FileExistsError:
            print("%s: refused, a phrase exists (%s)" % (lane, s.phrase_path))
            refused += 1
            continue
        finally:
            del p
        print("%s: made (24 words, not shown) in %s" % (lane, s.dir))
    return 1 if refused else 0


def cmd_check(args):
    out = doctor(_lanes(args))
    for level, line in out:
        print("%-4s %s" % (level, line))
    return 1 if any(level == "FAIL" for level, _ in out) else 0


def cmd_scan(args):
    if not args:
        raise SystemExit("usage: lane_seed.py scan <dir|file>...")
    phrases = [LaneSeed(x).phrase() for x in LANES if LaneSeed(x).exists()]
    if not phrases:
        print("no lane seed in %s: nothing to look for" % root(), file=sys.stderr)
        return 2
    hits, n = scan(args, phrases, skip=[root()])
    del phrases
    for h in hits:
        print(h)
    print("%d of %d files hold lane seed words" % (len(hits), n) if hits else "no lane seed words in %d files" % n, file=sys.stderr)
    return 1 if hits else 0


def main(argv):
    cmds = {"init": cmd_init, "check": cmd_check, "scan": cmd_scan}
    if not argv or argv[0] not in cmds:
        print(__doc__.split("CLI")[1].strip(), file=sys.stderr)
        return 64
    try:
        return cmds[argv[0]](argv[1:])
    except HarnessFault as e:
        print(e.line(), file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
