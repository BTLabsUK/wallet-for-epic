# SPDX-License-Identifier: Apache-2.0
"""Server-side log lines for a failed G4 lane, so a harness fault can be told apart from a server or
product fault. Four sources, each read for the step's window (started..ended, padded):

    remote node    the public node's file log, read over ssh (current file and rotated .gz)
    remote relay   the public Epicbox relay's journal (journalctl -u <unit>), read over ssh
    local node        the hermetic node's file log (tools/rellib/hermetic, DEBUG)
    local relay       the hermetic epic-relay's JSON log (loguru serialize, DEBUG)

Read only: nothing on the servers is changed, and a source that cannot be read is a note, never a
failure. From the relays: the lines that name the lane's address (proof.json details.address,
first 8…last 6) and every line of those connections (connects, subscribes, slate posts, closes), plus
server-wide errors; error lines of other connections are only counted. From the nodes: warnings,
errors and transaction/pool lines (never TRACE, peer gossip
or the steady noise of other wallets).

What is stored carries no IP addresses (loopback and [serverlogs] known_ips names stay), no full
wallet addresses (the lane's is shortened like proof.json, others are <other address>), no slate
bodies (long or JSON-looking lines are cut) and nothing that looks like a seed phrase.

Written to steps/<id>/out/server-logs.txt (the lines) and server-logs.json (counts and the few
quoted lines the failure alert and the gate message show). Settings: [serverlogs] in pipeline.toml."""
import gzip
import json
import os
import re
import shlex
import subprocess
import time
from datetime import datetime

from .run import read_json, write_json

DEFAULTS = {
    "enabled": True,
    "ssh": "demo-vps",
    "remote_node_log": "~/.epic/main/epic-server.log",
    "remote_relay_unit": "epic-floonet-epicbox",
    "local_node_log": "/tmp/epic-build/rel/hermetic/var/log/epic-server.log",
    "local_relay_log": "/tmp/epic-build/rel/hermetic/var/log/relay.log",
    "known_ips": {"203.0.113.10": "server"},
    "pad_s": 60,           # seconds read before the step started and after it ended
    "per_source": 40,      # lines kept per source in server-logs.txt
    "quote": 3,            # lines quoted per source in the alert and the gate
    "ssh_timeout_s": 40,
}
SOURCES = ("remote relay", "remote node", "local relay", "local node")

NODE_LINE = re.compile(r"^(\d{8} \d{2}:\d{2}:\d{2}\.\d{3}) (TRACE|DEBUG|INFO|WARN|ERROR)\s+(\S+) - (.*)$")
JOURNAL_LINE = re.compile(r"^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?[+-]\d{2}:?\d{2}) \S+ [^:]+: (.*)$")
# The reference relay's connection id: "[time] [uid] New connection from ip", "- [uid][ip] -> [type]".
CONN_TAG = re.compile(r"\] \[([A-Za-z0-9]{4,8})\] New connection|- \[([A-Za-z0-9]{4,8})\]\[")
NODE_KEEP = re.compile(r"transaction|tx_pool|txpool|pool|stem|fluff|dandelion|push_tx|kernel", re.I)
# Every node's steady noise: wallets asking for outputs the chain does not have, gossip of other
# people's transactions.
NODE_NOISE = re.compile(r"Output for commitment \w+, Message: Not found|rejected: DuplicateTx|truncate_reorg_cache")
ERRORISH = re.compile(r"error|fail|timed out|reject|refus|invalid|denied", re.I)
IPV4 = re.compile(r"(?<![\d.])(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})(?![\d.])")
# An IPv6 address: hex groups with "::" or at least six groups, and a digit (so neither a time of day
# nor a Rust path like epic_pool::pool matches).
IPV6 = re.compile(r"(?<![\w:.])(?=[\w:]*\d)(?:[0-9A-Fa-f]{0,4}(?::[0-9A-Fa-f]{0,4})*::[0-9A-Fa-f]{0,4}(?::[0-9A-Fa-f]{1,4})*"
                  r"|(?:[0-9A-Fa-f]{1,4}:){5,7}[0-9A-Fa-f]{1,4})(?![\w:])")
ADDRESS = re.compile(r"\b[1-9A-HJ-NP-Za-km-z]{40,}\b")          # a full base58 wallet address
SHORT_ADDRESS = re.compile(r"\b([1-9A-HJ-NP-Za-km-z]{8,})…")      # epic-relay prints address[:12]…
SEEDISH = re.compile(r"(?:\b[a-z]{3,8}\b[ ,]+){11,}\b[a-z]{3,8}\b")
MAX_LINE = 300


def settings(conf):
    """[serverlogs] from pipeline.toml with the defaults filled in."""
    return {k: (conf or {}).get(k, v) for k, v in DEFAULTS.items()}


def is_lane_step(step):
    parts = step.id.split("-")
    return bool(getattr(step, "proof", False)) and parts[0] == "trust" and len(parts) >= 3 and parts[1] != "manifest"


def window(st, pad):
    """(t0, t1) epoch seconds from the step status's started/ended ISO times, padded."""
    def ts(v):
        try:
            return datetime.fromisoformat(str(v)).timestamp()
        except ValueError:
            return None
    t0, t1 = ts(st.get("started")), ts(st.get("ended")) or time.time()
    return ((t0 or t1 - 3600) - pad, t1 + pad)


def lane_marks(stage):
    """The lane's address marks (first 8, last 6) from out/proof.json, as many as the proof holds."""
    proof = read_json(os.path.join(stage, "proof.json")) or {}
    details = proof.get("details") or {}
    marks = []
    for key in ("address", "address_after"):
        v = details.get(key)
        if isinstance(v, str) and "…" in v:
            head, tail = v.split("…", 1)
            if len(head) >= 6:
                marks.append((head, tail))
    return marks


# ---- redaction ------------------------------------------------------------------------------------

def redact(text, marks, known_ips):
    def ip(m):
        s = m.group(0)
        if s.startswith("127."):
            return s
        return f"<{known_ips[s]}>" if s in known_ips else "<ip>"

    def full(m):
        a = m.group(0)
        for head, tail in marks:
            if a.startswith(head) and (not tail or a.endswith(tail)):
                return f"{a[:8]}…{a[-6:]}"
        return "<other address>"

    def short(m):
        a = m.group(1)
        for head, _ in marks:
            if a.startswith(head) or head.startswith(a):
                return f"{head}…"
        return "<other address>…"

    if SEEDISH.search(text):
        return "<line left out: looks like words of a seed phrase>"
    text = IPV6.sub("<ip>", IPV4.sub(ip, text))
    text = SHORT_ADDRESS.sub(short, ADDRESS.sub(full, text))
    if len(text) > MAX_LINE or text.lstrip().startswith(("{", "[{")) or "Message {" in text:
        text = text[:120] + " …<cut>"
    return text


def names_lane(text, marks):
    for tok in ADDRESS.findall(text):
        if any(tok.startswith(h) and (not t or tok.endswith(t)) for h, t in marks):
            return True
    for tok in SHORT_ADDRESS.findall(text):
        if any(tok.startswith(h) or h.startswith(tok) for h, _ in marks):
            return True
    return False


# ---- parsing --------------------------------------------------------------------------------------

def parse_node(lines, utc_offset=None):
    """epic-server.log lines -> [(ts, level, text)]. The node writes its host's local time;
    utc_offset (seconds east of UTC) is given for a remote host, None means this host's zone."""
    out = []
    for raw in lines:
        m = NODE_LINE.match(raw.rstrip("\n"))
        if not m:
            continue
        t = datetime.strptime(m.group(1), "%Y%m%d %H:%M:%S.%f")
        ts = (t.timestamp() if utc_offset is None
              else (t - datetime(1970, 1, 1)).total_seconds() - utc_offset)
        out.append((ts, m.group(2), f"{m.group(2)} {m.group(3)} - {m.group(4)}"))
    return out


def parse_journal(lines):
    """journalctl -o short-iso lines of the reference relay -> [(ts, conn, text)]. A line without a
    [uid] tag ("subscribed …", "postslate from …") belongs to the tagged line just before it."""
    out, conn = [], None
    for raw in lines:
        m = JOURNAL_LINE.match(raw.rstrip("\n"))
        if not m:
            continue
        stamp = m.group(1)
        if re.search(r"[+-]\d{4}$", stamp):
            stamp = stamp[:-2] + ":" + stamp[-2:]
        ts = datetime.fromisoformat(stamp).timestamp()
        text = m.group(2)
        tag = CONN_TAG.search(text)
        if tag:
            conn = tag.group(1) or tag.group(2)
        out.append((ts, conn, text))
    return out


def parse_relay_json(lines):
    """epic-relay JSON lines -> [(ts, level, conn, text)]."""
    out = []
    for raw in lines:
        try:
            rec = json.loads(raw)["record"]
            out.append((float(rec["time"]["timestamp"]), rec["level"]["name"],
                        str((rec.get("extra") or {}).get("conn") or "-"), str(rec["message"])))
        except (ValueError, KeyError, TypeError):
            continue
    return out


# ---- selection ------------------------------------------------------------------------------------

def pick_relay(entries, marks):
    """entries: [(ts, level or None, conn, text)] in the window -> (kept, other_errors). Kept: the
    lane's connections in full, plus errors that belong to no connection (the server's own)."""
    lane_conns = {c for _, _, c, text in entries if c and c not in ("-",) and names_lane(text, marks)}
    kept, other = [], 0
    for ts, level, conn, text in entries:
        err = level in ("WARNING", "ERROR", "CRITICAL") or bool(ERRORISH.search(text))
        if conn in lane_conns or names_lane(text, marks):
            kept.append((ts, err, text))
        elif err and conn in (None, "-", "db", "sweep", "boot"):
            kept.append((ts, True, text))
        elif err:
            other += 1
    return kept, other


def pick_node(entries):
    kept = []
    for ts, level, text in entries:
        if level == "TRACE" or NODE_NOISE.search(text):
            continue
        err = level in ("WARN", "ERROR")
        if err or (" epic_p2p::" not in text and NODE_KEEP.search(text)):
            kept.append((ts, err, text))
    return kept


def cap(kept, n):
    """At most n lines: errors first, then the latest others, back in time order."""
    if len(kept) <= n:
        return kept, 0
    errs = [k for k in kept if k[1]][-n:]
    rest = [k for k in kept if not k[1]][-(n - len(errs)):] if n > len(errs) else []
    return sorted(errs + rest), len(kept) - len(errs) - len(rest)


# ---- reading --------------------------------------------------------------------------------------

def _within(entries, t0, t1):
    return [e for e in entries if t0 <= e[0] <= t1]


def read_tail(path, t0):
    """The lines of a local log and its rotated files (.1, .2… or .N.gz) not older than t0."""
    path = os.path.expanduser(path)
    files = []
    folder, base = os.path.split(path)
    try:
        for name in os.listdir(folder or "."):
            full = os.path.join(folder, name)
            if (name == base or name.startswith(base + ".")) and os.path.getmtime(full) >= t0:
                files.append(full)
    except OSError:
        return None
    if not files:
        return None if not os.path.exists(path) else []
    lines = []
    for f in sorted(files, key=os.path.getmtime):
        opener = gzip.open if f.endswith(".gz") else open
        try:
            with opener(f, "rt", encoding="utf-8", errors="replace") as fh:
                lines.extend(fh)
        except OSError:
            continue
    return lines


# Runs on the remote host (python3 -I -): prints the node log lines in [t0, t1] that are not TRACE,
# from the current file and the rotated .gz files written since t0, then its UTC offset.
REMOTE_NODE = r"""
import gzip, os, sys, time, re
path, t0, t1 = sys.argv[1], float(sys.argv[2]), float(sys.argv[3])
folder, base = os.path.split(path)
files = sorted((os.path.join(folder, n) for n in os.listdir(folder)
                if n == base or (n.startswith(base + ".") and n.endswith(".gz"))), key=os.path.getmtime)
files = [f for f in files if os.path.getmtime(f) >= t0][:12]
lo, hi = time.strftime("%Y%m%d %H:%M:%S", time.localtime(t0)), time.strftime("%Y%m%d %H:%M:%S", time.localtime(t1))
for f in files:
    with (gzip.open if f.endswith(".gz") else open)(f, "rt", errors="replace") as fh:
        for line in fh:
            if lo <= line[:17] <= hi and " TRACE " not in line[:30]:
                sys.stdout.write(line)
print("#offset", -time.altzone if time.localtime().tm_isdst > 0 else -time.timezone)
"""


def _ssh(conf, args, stdin=None):
    cmd = ["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=10", conf["ssh"], args]
    try:
        r = subprocess.run(cmd, input=stdin, capture_output=True, text=True, timeout=conf["ssh_timeout_s"])
    except (OSError, subprocess.TimeoutExpired) as e:
        return None, f"ssh {conf['ssh']}: {type(e).__name__}"
    if r.returncode != 0:
        return None, f"ssh {conf['ssh']}: exit {r.returncode} {r.stderr.strip()[-120:]}"
    return r.stdout.splitlines(True), None


def read_sources(conf, t0, t1, ssh=_ssh):
    """-> {source: (entries, note)}; entries are already in the window. A source that cannot be read
    gets entries None and a note."""
    out = {}
    lines, err = ssh(conf, f"journalctl -q -u {shlex.quote(conf['remote_relay_unit'])} --since @{int(t0)} "
                           f"--until @{int(t1) + 1} -o short-iso --no-pager")
    out["remote relay"] = ((None, err) if lines is None else
                              (_within([(ts, None, c, x) for ts, c, x in parse_journal(lines)], t0, t1), None))
    lines, err = ssh(conf, f"python3 -I - {shlex.quote(conf['remote_node_log'])} {t0:.0f} {t1:.0f}", REMOTE_NODE)
    if lines is None:
        out["remote node"] = (None, err)
    else:
        offset = next((int(x.split()[1]) for x in lines if x.startswith("#offset")), 0)
        out["remote node"] = (_within(parse_node(lines, offset), t0, t1), None)
    lines = read_tail(conf["local_relay_log"], t0)
    out["local relay"] = ((None, "no local relay log") if lines is None
                          else (_within(parse_relay_json(lines), t0, t1), None))
    lines = read_tail(conf["local_node_log"], t0)
    out["local node"] = ((None, "no local node log") if lines is None
                         else (_within(parse_node(lines), t0, t1), None))
    return out


# ---- the report -----------------------------------------------------------------------------------

def collect(step, st, stage, conf, ssh=_ssh):
    """Reads the four sources for a failed lane step and writes server-logs.txt and .json into
    stage (the step's out folder). -> the summary dict (also server-logs.json)."""
    conf = settings(conf)
    t0, t1 = window(st, conf["pad_s"])
    marks = lane_marks(stage)
    known = conf["known_ips"]
    hhmm = lambda t: time.strftime("%H:%M:%S", time.gmtime(t))
    summary = {"window": [hhmm(t0), hhmm(t1)], "lane_address": [f"{h}…{t}" for h, t in marks], "sources": {}}
    text = [f"Server-side logs for {step.id}, {hhmm(t0)}–{hhmm(t1)} UTC"
            + (f", lane address {', '.join(summary['lane_address'])}" if marks else ", lane address unknown "
               "(no proof.json address): relay lines show errors only")]
    for name, (entries, note) in read_sources(conf, t0, t1, ssh).items():
        if entries is None:
            summary["sources"][name] = {"read": False, "note": note}
            text += ["", f"== {name}: not read ({note})"]
            continue
        if name.endswith("relay"):
            entries = [e if len(e) == 4 else (e[0], None) + e[1:] for e in entries]
            kept, other = pick_relay(entries, marks)
        else:
            kept, other = pick_node(entries), 0
        shown, more = cap(kept, conf["per_source"])
        lines = [f"{hhmm(ts)} {redact(x, marks, known)}" for ts, _, x in shown]
        errors = [f"{hhmm(ts)} {redact(x, marks, known)}" for ts, e, x in shown if e]
        summary["sources"][name] = {"read": True, "lines": len(kept), "errors": sum(1 for k in kept if k[1]),
                                    "other_errors": other, "quote": (errors or lines)[-conf["quote"]:]}
        head = f"== {name}: {_n(len(kept), 'line')}" + (f", {_n(summary['sources'][name]['errors'], 'error')}" if kept else "")
        if other:
            head += f"; {other} error lines of other connections in the window (not shown)"
        if more:
            head += f"; {more} older lines not shown"
        text += ["", head] + lines
    os.makedirs(stage, exist_ok=True)
    with open(os.path.join(stage, "server-logs.txt"), "w", encoding="utf-8") as f:
        f.write("\n".join(text) + "\n")
    write_json(os.path.join(stage, "server-logs.json"), summary)
    return summary


def _n(n, word):
    return f"{n} {word}" + ("" if n == 1 else "s")


def quote_lines(summary, width=220):
    """The short form for the failure alert and the gate: one count line per source, then its quoted
    lines."""
    if not summary:
        return []
    out = []
    for name in SOURCES:
        s = (summary.get("sources") or {}).get(name)
        if not s:
            continue
        if not s.get("read"):
            out.append(f"{name}: not read ({s.get('note')})"[:width])
            continue
        out.append(f"{name}: {_n(s['lines'], 'line')}, {_n(s['errors'], 'error')}"
                   + (f" (+{_n(s['other_errors'], 'error')} of other connections)" if s.get("other_errors") else ""))
        out.extend(f"  {q}"[:width] for q in s.get("quote") or [])
    return out
