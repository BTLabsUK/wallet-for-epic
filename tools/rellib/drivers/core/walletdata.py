# SPDX-License-Identifier: Apache-2.0
"""What the wallet's own data holds, read the same way on every platform: the digest the G4 update-trust
checks (core/checks.py) compare before and after an update. Nothing here reads a screen.

A platform gives `read` a `files` object (the small interface below); everything else is the same
code: wallets.json, the wallet database (a plain wallet.sqlite3, or the encrypted wallet.enc.sqlite3
through the LEPIC command-line wallet), settings.toml, the app's secure storage, the address book and
the file listing.

files interface (what a platform implements; DirFiles is a ready one for a folder on this machine):
    root                      the data root, as text (for messages; wallets.json's dataDir is made relative to it)
    text(rel) -> str | None   a small file of the data folder, None when it is not there
    blob(rel) -> bytes | None the same as bytes
    listing() -> [rel]        every file below the data root, "/" separated, without logs, tor and cache
    fetch(rel, local) -> bool copy one file to [local] (False when it is not there); a database is fetched
                              with its -wal and -shm by the caller of fetch, one call per file
    store() -> dict           the app's secure-storage keys (value text or parsed JSON); {} when none can be read
    store_note                (attribute, optional) why store() is empty when it is, for the details

The digest (JSON-safe; amounts are integers in nanoEPIC, 1 EPIC = 1e8):
    wallet        {id, label, dataDir} of the wallet in use (wallets.json lastUsedId), or None
    wallet_ids    every wallet id in wallets.json
    source        "db" (plain wallet.sqlite3) | "cli" (encrypted store through the LEPIC CLI) | "none"
    store_dir     the folder of the wallet's database, relative to the data root
    balance       {total, spendable, unconfirmed, locked} | None; balance_how says how it was derived
    outputs       [{commit, amount, status, height}] | None (the CLI reports none)
    txs           [{id, direction, state, transport, credited, debited, fee, height, counterparty, slate}] | None
    counterparties_read   False through the CLI (it does not report who paid or was paid)
    tip           the chain height spendable was derived from (plain store), else None
    servers       {node_in_use, nodes, nodes_added, relay_in_use, relays, relays_added}
    settings_toml {node: [...], epicbox: [...], plain_http: [...]} | None (a release without the file)
    settings      {theme, technical_details, label, confirmations}; a value that could not be read is None
    unread        {field: why} for every field of settings (and level) that could not be read
    level         the stored wallet level or None
    address_book  {source, contacts: [{id, name, epicbox}]} | None;  notes: [text] | None
    hashes        {relative path: sha256} of the plain app files in migration.WATCHED
    files         the file listing
    log           {lines, first_start: [(line no, text)], subscribed: [(line no, relay)],
                   hosts: [(line no, host)] (the servers its lines name; hermetic.log_hosts)} from logs/wfe.log
"""
import datetime
import decimal
import hashlib
import json
import os
import re
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import time
import tomllib
import urllib.request

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import facts  # noqa: E402
import migration  # noqa: E402
from . import breaks  # noqa: E402
from .faults import InfraFault  # noqa: E402
from .hermetic import entry as server_entry, log_hosts  # noqa: E402

D = decimal.Decimal
NANO = 100000000
DEFAULT_CONF = 6  # the wallet's minimum confirmations while it has none stored
CONF_KEY = "wallet.minimum_confirmations"
TIP_KEY = "refresh.last_confirmed_height"
FIRST_START = re.compile(r"levels: first start|network: first run")
LOG_FILE = "logs/wfe.log"

CLI_CACHE = os.path.expanduser("/tmp/epic-build/lepic-cli")
CLI_TARGET = os.path.expanduser("~/.cache/lepic-target")
COMMANDS = {"restore": ["wallet", "restore", "--no-scan"], "info": ["wallet", "info"], "txs": ["tx", "list"],
            "address": ["wallet", "address"]}
GLOBAL = ["--network", "mainnet", "--log-level", "error", "--output", "json"]

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))


class ReadError(Exception):
    """The wallet's data could not be read (a harness problem, not a verdict on the product)."""


class CliError(ReadError):
    pass


# ---- amounts ---------------------------------------------------------------------------------------

def nano(v):
    """nanoEPIC integer of an EPIC amount as the CLI prints it (a number or a decimal string)."""
    if v is None or v == "":
        return 0
    try:
        return int((D(str(v)) * NANO).to_integral_value())
    except (decimal.InvalidOperation, ValueError):
        return 0


def num(n):
    """EPIC text of nanoEPIC: 3000000 -> 0.03, 0 -> 0."""
    if n is None:
        return "?"
    t = format((D(int(n)) / NANO).normalize(), "f")
    return t if t != "-0" else "0"


def fmt(b):
    return ", ".join("%s %s" % (k, num(v)) for k, v in (b or {}).items()) or "none"


def short(a):
    if not a:
        return str(a)
    k, _, dom = a.partition("@")
    return "%s…%s%s" % (k[:6], k[-6:], ("@" + dom) if dom else "")


def host(u):
    return re.sub(r"^\w+://", "", (u or "").strip()).rstrip("/")


# ---- files ------------------------------------------------------------------------------------------

class DirFiles:
    """A data folder on this machine as a files object. [store_fn] gives the secure-storage keys
    (Linux: the keyring; a test: a dict). The listing is migration.snapshot_dir's: no logs, tor, cache,
    lock files."""

    def __init__(self, root, store_fn=None, store_note=""):
        self.root = os.path.abspath(root)
        self._store = store_fn
        self.store_note = store_note

    @staticmethod
    def check_rel(rel):
        """A relative path that stays below the data root (no absolute path, no ..); for the remote readers."""
        parts = str(rel).replace("\\", "/").split("/")
        if str(rel).startswith(("/", "\\")) or ".." in parts:
            raise ReadError("%r is outside the data folder" % rel)
        return rel

    def _path(self, rel):
        self.check_rel(rel)
        p = os.path.normpath(os.path.join(self.root, rel))
        if p != self.root and not p.startswith(self.root + os.sep):
            raise ReadError("%r is outside the data folder" % rel)
        return p

    def text(self, rel):
        b = self.blob(rel)
        return None if b is None else b.decode("utf-8", "replace")

    def blob(self, rel):
        try:
            with open(self._path(rel), "rb") as f:
                return f.read()
        except OSError:
            return None

    def listing(self):
        out = []
        for dp, _dn, fn in os.walk(self.root):
            rel = os.path.relpath(dp, self.root)
            if rel.split(os.sep)[0] in ("logs", "tor", "cache"):
                continue
            for f in fn:
                if f.endswith((".lock", ".log")) or f.startswith("LOCK"):
                    continue
                out.append(os.path.normpath(os.path.join(rel, f)).replace(os.sep, "/"))
        return sorted(out)

    def fetch(self, rel, local):
        try:
            shutil.copyfile(self._path(rel), local)
            return True
        except OSError:
            return False

    def store(self):
        return dict(self._store() or {}) if callable(self._store) else dict(self._store or {})


def rig_files(rig, data):
    """A files object over the Windows rig (windows/rig.py Rig) and the app's data folder [data] on the box.
    The rig reads as the box's user (as_owner / text / files / fetch_db are the rig's own calls)."""
    class RigFiles:
        root = data
        store_note = ""

        def _w(self, rel):
            return data.rstrip("\\") + "\\" + rel.replace("/", "\\")

        def text(self, rel):
            t = rig.text(self._w(rel))
            return None if t is None else t.replace("\r\n", "\n") if rel.endswith((".toml", ".log")) else t

        def blob(self, rel):
            t = rig.text(self._w(rel))
            return None if t is None else t.encode("utf-8")

        def listing(self):
            return sorted(p.replace("\\", "/") for p in rig.files(data))

        def fetch(self, rel, local):
            # the rig keeps a database's files (with -wal and -shm) in a folder of their own: not at `local`,
            # which is where the finished file goes
            got = rig.fetch_db(self._w(rel), os.path.join(os.path.dirname(local), ".rig"), os.path.basename(local))
            if got and os.path.exists(got):
                shutil.copyfile(got, local)
                for x in ("-wal", "-shm"):
                    if os.path.exists(got + x):
                        shutil.copyfile(got + x, local + x)
                return True
            return False

        def store(self):
            return rig.call("store", file=data + "\\flutter_secure_storage.dat").get("keys") or {}
    return RigFiles()


def sha256(b):
    return hashlib.sha256(b).hexdigest()


def snapshot(files):
    """(listing, hashes) of the data folder, in the shape migration.py judges."""
    listing = files.listing()
    hashes = {}
    for p in migration.watched_names(listing):
        b = files.blob(p)
        if b is not None:
            hashes[p] = sha256(b)
    return migration.norm(listing), hashes


# ---- plain parts ------------------------------------------------------------------------------------

def _json(text):
    try:
        v = json.loads(text) if isinstance(text, str) else text
    except ValueError:
        return None
    return v


def wallets_of(files):
    """(wallets.json as a dict | None, the entry in use | None)."""
    w = _json(files.text("wallets.json") or "null")
    if not isinstance(w, dict) or not isinstance(w.get("wallets"), list) or not w["wallets"]:
        return None, None
    entries = [x for x in w["wallets"] if isinstance(x, dict)]
    if not entries:
        return None, None
    entry = next((x for x in entries if x.get("id") == w.get("lastUsedId")), entries[0])
    return w, entry


def store_dir_of(entry, listing, root):
    """The wallet's database folder (".../lepic") relative to the data root: from the entry's dataDir when it
    lies under the root, else the folder in the listing that ends the same way (a restored sandbox keeps
    the old absolute path in wallets.json), else the only one."""
    dirs = migration.store_dirs(listing)
    data = str((entry or {}).get("dataDir") or "").replace("\\", "/").rstrip("/")
    r = str(root or "").replace("\\", "/").rstrip("/")
    if data and r and data.startswith(r + "/"):
        cand = data[len(r) + 1:] + "/" + facts.STORE_DIR
        if cand in dirs:
            return cand
    if data:
        tail = data.split("/")[-1]
        hit = [d for d in dirs if d.split("/")[-2:-1] == [tail]]
        if len(hit) == 1:
            return hit[0]
    return dirs[0] if len(dirs) == 1 else None


def servers_23(s):
    """Node and Epicbox lists and choices as the desktop's store keeps them (26.10.23 and earlier)."""
    def j(k):
        v = s.get(k)
        if isinstance(v, str):
            try:
                return json.loads(v)
            except ValueError:
                return v
        return v or {}
    n, r = j("desk.serverList.node.mainnet"), j("desk.serverList.relay.mainnet")
    n = n if isinstance(n, dict) else {}
    r = r if isinstance(r, dict) else {}
    return {"node_in_use": s.get("app.node.mainnet") or "", "nodes": n.get("entries", []), "nodes_added": n.get("added", []),
            "relay_in_use": s.get("app.relay.mainnet") or "", "relays": r.get("entries", []), "relays_added": r.get("added", [])}


def toml_servers(text):
    """{node: [...], epicbox: [...], plain_http: [...]} from settings.toml (the first entry is in use);
    None without the file or when it is not TOML."""
    if text is None:
        return None
    try:
        t = tomllib.loads(text)
    except tomllib.TOMLDecodeError:
        return None

    def lst(sect, key="servers"):
        v = (t.get(sect) or {}).get(key) or []
        return [x for x in v if isinstance(x, str)]
    return {"node": lst("node"), "epicbox": lst("epicbox"), "plain_http": lst("node", "plain_http")}


def servers_of(s, toml):
    """The lists and choices in servers_23's shape: settings.toml when the release has one (26.10.24 and
    later keep their servers there, the first in use; the file has no "added" record), else the store."""
    if toml is None:
        return servers_23(s)
    n, r = toml.get("node") or [], toml.get("epicbox") or []
    return {"node_in_use": n[0] if n else "", "nodes": n, "nodes_added": [],
            "relay_in_use": r[0] if r else "", "relays": r, "relays_added": []}


def settings_of(store, entry, conf, unread, conf_why):
    """The four simple settings, each None when it could not be read (and then named in [unread])."""
    ds = store.get("desk.settings")
    if isinstance(ds, str):
        ds = _json(ds)
    theme = tech = None
    if isinstance(ds, dict):
        theme = ds.get("theme")
        feats = (ds.get("advanced") or {}).get("features")
        tech = (facts_tech() in feats) if isinstance(feats, list) else False
    elif store:
        # a fresh install keeps only what differs from the defaults: the key may be absent
        theme, tech = None, None
        unread["theme"] = unread["technical_details"] = "no desk.settings in the secure storage"
    if theme is None and "theme" not in unread:
        unread["theme"] = unread["technical_details"] = (
            getattr(store, "note", "") or "the app's secure storage cannot be read here")
    label = (entry or {}).get("label")
    if label is None:
        unread["label"] = "no label in wallets.json"
    if conf is None:
        unread["confirmations"] = conf_why
    return {"theme": theme, "technical_details": tech, "label": label, "confirmations": conf}


def facts_tech():
    return "technicalDetails"


def address_book(files):
    """({source, contacts}, notes) from the app's plain files; (None, None) where they are not there."""
    book = notes = None
    t = files.text(facts.CONTACTS_PLAIN)
    d = _json(t) if t else None
    if isinstance(d, dict) and isinstance(d.get("contacts"), list):
        book = {"source": facts.CONTACTS_PLAIN,
                "contacts": [{"id": c.get("id"), "name": c.get("name"), "epicbox": c.get("epicbox")}
                             for c in d["contacts"] if isinstance(c, dict)]}
    return book, notes


def notes_of(files, store_dir):
    """The notes of the wallet's wfe_meta.json (text values), None without the file."""
    wdir = os.path.dirname(store_dir) if store_dir else ""
    t = files.text((wdir + "/" if wdir else "") + facts.META_PLAIN)
    d = _json(t) if t else None
    if isinstance(d, dict) and isinstance(d.get("notes"), dict):
        return [str(v) for v in d["notes"].values()]
    return None


def log_flags(files):
    t = files.text(LOG_FILE)
    if t is None:
        return None
    lines = [l for l in t.replace("\r", "").split("\n") if l.strip()]
    return {"lines": len(lines),
            "first_start": [(i, l) for i, l in enumerate(lines) if FIRST_START.search(l)],
            "subscribed": [(i, m.group(1)) for i, l in enumerate(lines)
                           if "epicbox subscribed" in l for m in [re.search(r"relay=(\S+)", l)] if m],
            "hosts": [(i, h) for i, l in enumerate(lines) for h in log_hosts(l)]}


# ---- the plain database -----------------------------------------------------------------------------

def node_tip(urls, timeout=10):
    """The chain height a node reports (/v1/status), from the first of [urls] that answers; None otherwise."""
    for u in urls:
        if not u:
            continue
        u = u if "://" in u else "https://" + u
        try:
            with urllib.request.urlopen(u.rstrip("/") + "/v1/status", timeout=timeout) as r:
                return int(json.load(r)["tip"]["height"])
        except Exception:  # noqa: BLE001 — a node that does not answer is the next one's turn
            continue
    return None


def _scratch():
    d = os.environ.get("TMPDIR") or tempfile.gettempdir()
    return d if os.path.isdir(d) else tempfile.gettempdir()


def read_db(files, store_dir, work):
    """Outputs, transactions and settings of the plain wallet.sqlite3, from a copy (with its -wal and -shm)
    in [work]; None when the file is not there."""
    base = facts.STORE_PLAIN
    local = os.path.join(work, base)
    if not files.fetch(store_dir + "/" + base, local):
        return None
    for sfx in ("-wal", "-shm"):
        files.fetch(store_dir + "/" + base + sfx, local + sfx)  # missing is fine: a closed wallet has none
    c = sqlite3.connect(local)
    try:
        outs = [dict(commit=r[0], amount=r[1], status=r[2], height=r[3]) for r in
                c.execute("select hex(commitment), amount, status, height from outputs")]
        txs = [dict(id=r[0], direction=r[1], state=r[2], transport=r[3], credited=r[4] or 0, debited=r[5] or 0, fee=r[6],
                    height=r[7], counterparty=r[8], slate=r[9] or None) for r in
               c.execute("select id, direction, state, transport, amount_credited, amount_debited, fee, confirmed_height, "
                         "counterparty, hex(slate_id) from transactions order by id")]
        st = dict(c.execute("select key, value from settings"))
    finally:
        c.close()
    return {"outputs": outs, "txs": txs, "settings": st}


def balance_of(outputs, conf, tip):
    """total / spendable / unconfirmed / locked from the outputs. Spendable is the unspent outputs with
    [conf] confirmations at [tip] (None without a tip: nothing counts as spendable)."""
    def tot(status):
        return sum(o["amount"] for o in outputs if o["status"] == status)
    spend = sum(o["amount"] for o in outputs if o["status"] == "unspent" and tip and o["height"]
                and tip - o["height"] + 1 >= conf)
    return {"total": tot("unspent") + tot("unconfirmed") + tot("locked"), "spendable": spend,
            "unconfirmed": tot("unconfirmed"), "locked": tot("locked")}


# ---- the LEPIC command-line wallet ------------------------------------------------------------------

def pin(src=None):
    """The LEPIC commit the release is built with: tools/lepic.rev of the candidate's source (REL_CANDIDATE_SRC),
    else of this checkout."""
    for base in (src or os.environ.get("REL_CANDIDATE_SRC"), ROOT):
        if not base:
            continue
        try:
            with open(os.path.join(base, "tools", "lepic.rev")) as f:
                v = f.read().strip()
        except OSError:
            continue
        if len(v) >= 12 and all(c in "0123456789abcdef" for c in v):
            return v
    raise CliError("no tools/lepic.rev with a commit in the candidate's source or this checkout")


def lepic_repo(pin_):
    """A local LEPIC clone that holds the pin: LEPIC_REPO, the candidate's app/third_party/lepic, ~/lepic."""
    src = os.environ.get("REL_CANDIDATE_SRC") or ROOT
    for c in (os.environ.get("LEPIC_REPO"), os.path.join(src, "app", "third_party", "lepic"), os.path.expanduser("~/lepic")):
        if c and os.path.isdir(c) and subprocess.run(["git", "-C", c, "cat-file", "-e", pin_ + "^{commit}"],
                                                    capture_output=True).returncode == 0:
            return c
    raise CliError("no local LEPIC clone holds %s (set LEPIC_REPO)" % pin_)


def cli_exe_path(pin_):
    return os.path.join(CLI_CACHE, pin_[:12], "lepic")


def _runs(exe):
    try:
        r = subprocess.run([exe, "--version"], capture_output=True, text=True, timeout=60)
    except (OSError, subprocess.SubprocessError):
        return False
    return r.returncode == 0


def ensure_cli(pin_=None, log=print, build=True):
    """The LEPIC CLI at the candidate's pin: LEPIC_CLI_EXE if set, else the cached binary
    /tmp/epic-build/lepic-cli/<pin12>/lepic, built once through build-slot (shared CARGO_TARGET_DIR) from a
    `git archive` of the pin when it is not there. The shared target's lepic is never taken as it is:
    any agent's build overwrites it; the binary is taken from the executable cargo reports for this
    build and copied away at once."""
    env = os.environ.get("LEPIC_CLI_EXE")
    if env:
        if not _runs(env):
            raise CliError("LEPIC_CLI_EXE %s does not run" % env)
        return env
    p = pin_ or pin()
    exe = cli_exe_path(p)
    if os.path.isfile(exe) and _runs(exe):
        return exe
    if not build:
        raise CliError("no LEPIC CLI at %s" % exe)
    folder = os.path.dirname(exe)
    os.makedirs(folder, exist_ok=True)
    src = os.path.join(folder, "src")
    if os.path.exists(src):
        shutil.rmtree(src)  # a half-built source of this very cache folder
    os.makedirs(src)
    repo = lepic_repo(p)
    tar = subprocess.run(["git", "-C", repo, "archive", "--format=tar", p], capture_output=True, timeout=300)
    if tar.returncode != 0:
        raise CliError("git archive %s: %s" % (p[:12], tar.stderr[-200:].decode("utf-8", "replace")))
    subprocess.run(["tar", "-x", "-C", src], input=tar.stdout, check=True, timeout=300)
    log("building the LEPIC CLI at %s (cargo through build-slot, target %s)" % (p[:12], CLI_TARGET))
    env2 = dict(os.environ, CARGO_TARGET_DIR=CLI_TARGET, CARGO_INCREMENTAL="0", CARGO_PROFILE_DEV_DEBUG="line-tables-only")
    heavy = shutil.which("build-slot")
    cmd = ([heavy] if heavy else []) + ["cargo", "build", "--locked", "-p", "lepic-cli", "--message-format=json-render-diagnostics"]
    r = subprocess.run(cmd, cwd=src, env=env2, capture_output=True, text=True, timeout=3600)
    built = None
    for line in r.stdout.splitlines():
        try:
            m = json.loads(line)
        except ValueError:
            continue
        if m.get("reason") == "compiler-artifact" and m.get("executable") and (m.get("target") or {}).get("name") == "lepic":
            built = m["executable"]
    if r.returncode != 0 or not built or not os.path.isfile(built):
        raise CliError("the LEPIC CLI build failed: %s" % (r.stderr or r.stdout)[-400:])
    tmp = exe + ".tmp"
    shutil.copyfile(built, tmp)
    os.chmod(tmp, 0o755)
    os.replace(tmp, exe)
    with open(os.path.join(folder, "pin"), "w") as f:
        f.write(p + "\n")
    shutil.rmtree(src)
    if not _runs(exe):
        raise CliError("the built LEPIC CLI does not run: %s" % exe)
    return exe


def parse_cli(res):
    """{"info": {...}, "txs": [...], "address": str | None} from the three commands' JSON text."""
    try:
        info = json.loads(res["info"])
        txs = json.loads(res["txs"])
    except (KeyError, ValueError):
        raise CliError("the CLI did not answer with JSON: %s" % " | ".join(
            "%s: %s" % (k, str(v)[:200]) for k, v in res.items()))
    addr = None
    try:
        a = json.loads(res.get("address") or "null")
        addr = a.get("address") if isinstance(a, dict) else (a if isinstance(a, str) else None)
    except ValueError:
        pass
    return {"info": info, "txs": txs.get("transactions") or [], "address": addr}


# The CLI could not reach its node: exit 9 (the node error kind), or the error says so
NODE_DOWN = re.compile(r'could not connect to the node|"kind"\s*:\s*"node"', re.I)
UNREACHABLE_NODE = "http://127.0.0.1:9"   # the discard port: nothing answers (the node-down break)


def with_node(text, host):
    """settings.toml's text with `host` first in [node] servers (in use for the CLI); the other entries
    and every other table kept. CliError when the result is not TOML."""
    text = text or ""
    m = re.search(r"(?m)^\[node\]\s*$", text)
    if not m:
        new = text.rstrip("\n") + ("\n\n" if text.strip() else "") + "[node]\nservers = [%s]\n" % json.dumps(host)
    else:
        end = re.search(r"(?m)^\[", text[m.end():])
        sect = text[m.end():m.end() + end.start()] if end else text[m.end():]
        old = (toml_servers(text) or {}).get("node") or []
        line = "servers = [%s]" % ", ".join(json.dumps(x) for x in [host] + [x for x in old if x != host])
        sect2, n = re.subn(r"(?ms)^\s*servers\s*=\s*\[.*?\]", "\n" + line, sect, count=1)
        if not n:
            sect2 = "\n" + line + sect
        new = text[:m.end()] + sect2 + (text[m.end() + end.start():] if end else "")
    t = toml_servers(new)
    if not t or (t.get("node") or [None])[0] != host:
        raise CliError("could not put the node %s into the CLI's settings" % host)
    return new


class LepicCli:
    """The encrypted store, read through the LEPIC CLI on copies. A CLI wallet restored from the run wallet's
    phrase (`wallet restore --no-scan` into a scratch folder) opens the app's store, since the store key comes
    from the seed; the app's wallet.enc.sqlite3 (+ -wal, -shm, .check) are COPIED over the scratch store
    (never the live folder: the running app holds it) and `wallet info`, `tx list` run there. The phrase and
    the wallet password go in on standard input, never as an argument or in the environment. The restore runs
    once per object; every read copies the store files again.

    The node: the app's own (settings.toml's first) first, then the test order (facts.NODE_PICK). A CLI
    that cannot reach a node (exit 9, "could not connect to the node") moves to the next one and logs
    it; when none answers, InfraFault (sub node): the network under the test, not the app."""

    step = "wallet-read"

    def __init__(self, exe=None, log=print):
        self.exe = exe
        self.log = log
        self.work = None
        self._key = None
        self.nodes, self.at = [], 0

    def _order(self, settings_text):
        own = ((toml_servers(settings_text) or {}).get("node") or [])[:1]
        # URLs as they are: the CLI's node.servers needs the scheme; the same server listed twice is tried once
        seen, order = set(), []
        for x in own + list(facts.NODE_PICK):
            if x and server_entry(x) not in seen:
                seen.add(server_entry(x))
                order.append(x if re.match(r"^https?://", x) else "http://" + x)
        if breaks.node_down():
            self.log("BREAK: the CLI's first node is %s (nothing answers there)" % UNREACHABLE_NODE)
            order.insert(0, UNREACHABLE_NODE)
        return order

    def _use_node(self, host):
        with open(self.settings) as f:
            text = f.read()
        with open(self.settings, "w") as f:
            f.write(with_node(text, host))

    def _run_node(self, args, stdin, secrets=()):
        """_run, moved on to the next node while the CLI cannot reach the one it has."""
        while True:
            r = self._run(args, stdin)
            if not (r.returncode == 9 or NODE_DOWN.search((r.stderr or "") + (r.stdout or ""))):
                return r
            down = self.nodes[self.at] if self.at < len(self.nodes) else "its node"
            self.at += 1
            if self.at >= len(self.nodes):
                raise InfraFault(self.step, "the LEPIC CLI reached no node (tried %s): %s"
                                 % (", ".join(self.nodes) or "none", _clean(r.stderr or r.stdout, *secrets)[-160:]), sub="node")
            self.log("LEPIC CLI: node %s not reachable (exit %d); trying %s" % (down, r.returncode, self.nodes[self.at]))
            self._use_node(self.nodes[self.at])

    def _exe(self):
        if not self.exe:
            self.exe = ensure_cli(log=self.log)
        return self.exe

    def _run(self, args, stdin, timeout=600):
        cfg = ["--data-dir", self.dst, "--settings", self.settings] + GLOBAL
        r = subprocess.run([self._exe()] + cfg + args, input=stdin, capture_output=True, text=True, timeout=timeout)
        return r

    def _restore(self, phrase, password, settings_text):
        key = sha256((phrase + "\n" + password).encode())
        if self._key == key and self.work and os.path.isdir(self.dst):
            return
        self.close()
        self.work = tempfile.mkdtemp(prefix="lepic-cli-", dir=_scratch())
        os.chmod(self.work, 0o700)
        self.dst = os.path.join(self.work, "data")
        self.settings = os.path.join(self.work, "cli-settings.toml")
        os.makedirs(self.dst, mode=0o700)
        with open(self.settings, "w") as f:
            f.write(settings_text or "")
        os.chmod(self.settings, 0o600)
        self.nodes, self.at = self._order(settings_text), 0
        if self.nodes and ((toml_servers(settings_text) or {}).get("node") or [None])[0] != self.nodes[0]:
            self._use_node(self.nodes[0])
        r = self._run_node(COMMANDS["restore"], phrase + "\n" + password + "\n", (phrase, password))
        if r.returncode != 0:
            self.close()
            raise CliError("the CLI restore failed (exit %d): %s" % (r.returncode, _clean(r.stderr or r.stdout, phrase, password)))
        self._key = key

    def read(self, files, store_dir, secrets, settings_text=None):
        """{"info", "txs", "address"} of the app's encrypted store in [store_dir] (relative to the data root)."""
        phrase, password = (secrets or {}).get("phrase"), (secrets or {}).get("password")
        if not phrase:
            raise CliError("no recovery phrase was kept for the CLI restore (the encrypted store opens with the seed's key)")
        if not password:
            raise CliError("no wallet password was kept for the CLI restore")
        self._restore(phrase, password, settings_text)
        got = 0
        listing = files.listing()
        for name in sorted({os.path.basename(p) for p in migration.norm(listing) if os.path.dirname(p) == store_dir}):
            if name.startswith(facts.STORE_ENC) and not name.endswith(".tmp"):
                if files.fetch(store_dir + "/" + name, os.path.join(self.dst, name)):
                    got += 1
        if not got:
            raise CliError("no %s in %s to read" % (facts.STORE_ENC, store_dir))
        res = {}
        for name in ("info", "txs", "address"):
            r = self._run_node(COMMANDS[name], password + "\n", (phrase, password))
            if r.returncode != 0 and name != "address":
                raise CliError("`%s` failed (exit %d): %s" % (" ".join(COMMANDS[name]), r.returncode,
                                                            _clean(r.stderr or r.stdout, phrase, password)))
            res[name] = r.stdout.strip()
        return parse_cli(res)

    def close(self):
        if self.work and os.path.isdir(self.work):
            shutil.rmtree(self.work, ignore_errors=True)  # the folder this object made
        self.work = self._key = None


def _clean(text, *secrets):
    t = (text or "")[-300:]
    for s in secrets:
        if s:
            t = t.replace(s, "<secret>")
    return t.strip()


_SHARED = []


def shared_cli(log=print):
    """One LepicCli for the process (the restore is done once)."""
    if not _SHARED:
        _SHARED.append(LepicCli(log=log))
    return _SHARED[0]


def cli_shape(read):
    """balance, txs and the account from a CLI read (amounts in nanoEPIC). Outputs by commitment and a
    transaction's counterparty are not in the CLI's reports (None)."""
    acc = (read["info"].get("accounts") or [{}])[0]
    bal = {"total": nano(acc.get("total")), "spendable": nano(acc.get("spendable")),
           "unconfirmed": nano(acc.get("awaiting_confirmation")), "locked": nano(acc.get("locked"))}
    txs = [dict(id=t["tx_id"], direction=t["direction"], state=t["state"], transport=t.get("transport"),
                credited=nano(t.get("amount_credited")), debited=nano(t.get("amount_debited")), fee=nano(t.get("fee")) if t.get("fee") is not None else None,
                height=t.get("confirmed_height"), counterparty=None, slate=(t.get("slate_id") or "").replace("-", "").upper() or None)
           for t in read["txs"]]
    return bal, txs


# ---- read -------------------------------------------------------------------------------------------

def read(files, secrets, *, migrate=False, cli=None, tip=None, nodes=(), log=print):
    """The digest of the wallet's data (see the module doc). [migrate]: the candidate keeps the store encrypted
    (noted in the digest; the files decide which store is read: an encrypted store is read through [cli],
    a LepicCli or anything with read(files, store_dir, secrets, settings_text); None takes the shared one).
    [tip] / [nodes]: the chain height for spendable (the larger of the given, the nodes' and the one
    the wallet last saw)."""
    d = {"migrate": bool(migrate), "read_at": datetime.datetime.now().isoformat(timespec="seconds"),
         "source": "none", "wallet": None, "wallet_ids": [], "store_dir": None, "balance": None, "balance_how": "",
         "outputs": None, "txs": None, "counterparties_read": True, "tip": None, "unread": {}}
    listing = files.listing()
    d["files"] = migration.norm(listing)
    d["hashes"] = snapshot(files)[1] if listing else {}
    w, entry = wallets_of(files)
    d["wallet_ids"] = [x["id"] for x in (w or {}).get("wallets", []) if isinstance(x, dict) and x.get("id")]
    if entry:
        d["wallet"] = {"id": entry.get("id"), "label": entry.get("label"), "dataDir": entry.get("dataDir")}
    sdir = store_dir_of(entry, listing, files.root)
    d["store_dir"] = sdir
    store = files.store()
    toml_text = files.text(facts.SETTINGS_TOML)
    toml = toml_servers(toml_text)
    d["settings_toml"] = toml
    d["servers"] = servers_of(store, toml)
    d["level"] = store.get(facts.LEVEL_KEY)
    if d["level"] is not None:
        d["level"] = str(d["level"]).strip().strip('"')
    unread = d["unread"]
    note = getattr(files, "store_note", "") or "the app's secure storage cannot be read here"
    if not store:
        unread["level"] = note
    conf, conf_why = None, "no wallet database was read"
    names = {os.path.basename(p) for p in d["files"] if os.path.dirname(p) == sdir} if sdir else set()
    with tempfile.TemporaryDirectory(prefix="walletdata-", dir=_scratch()) as work:
        if sdir and facts.STORE_ENC in names:
            rd = (cli or shared_cli(log)).read(files, sdir, secrets, toml_text)
            d["source"] = "cli"
            d["balance"], d["txs"] = cli_shape(rd)
            d["counterparties_read"] = False
            d["address"] = rd.get("address")
            d["balance_how"] = ("the encrypted store read through the LEPIC CLI (wallet info, tx list); outputs by commitment, "
                                "counterparties and the wallet's settings are not in its reports")
            conf_why = "the encrypted store's settings are not in the LEPIC CLI's reports"
        elif sdir and facts.STORE_PLAIN in names:
            rd = read_db(files, sdir, work)
            if rd:
                d["source"] = "db"
                d["outputs"], d["txs"] = rd["outputs"], rd["txs"]
                v = rd["settings"].get(CONF_KEY)
                conf = int(v) if v else DEFAULT_CONF
                db_tip = int(rd["settings"].get(TIP_KEY) or 0) or None
                tips = [t for t in (tip, node_tip(list(nodes)) if nodes else None, db_tip) if t]
                d["tip"] = max(tips) if tips else None
                d["balance"] = balance_of(rd["outputs"], conf, d["tip"])
                d["balance_how"] = "the plain wallet database's outputs (%d) at chain height %s, %d confirmation(s)" % (
                    len(rd["outputs"]), d["tip"], conf)
                d["fingerprint"] = rd["settings"].get("wallet.fingerprint")
    d["settings"] = settings_of(store, entry, conf, unread, conf_why)
    if not store:
        for k in ("theme", "technical_details"):
            unread[k] = note
    book, _ = address_book(files)
    d["address_book"] = book
    d["notes"] = notes_of(files, sdir)
    d["log"] = log_flags(files)
    return d
