# SPDX-License-Identifier: Apache-2.0
"""The AI loop behind recover.py: a few model turns with a safe action set, the playbook the model
reads, and a cache of the paths that worked, replayed without the model.

A turn sends the goal, the screen tree (Node.brief: no password values), the playbook entries for
the platform and the actions taken so far; the model answers one JSON object:
    {"do": "click|scroll|expand|type|done|give_up", "i": <node>, "dir": "up|down", "text": "...",
     "why": "...", "pb": "<playbook key it used, if any>"}
At most REL_AI_TURNS turns (default 4) per goal. An empty or invalid answer, a model error, or an
action the guards refuse is one wasted turn, logged.

Guards, in code (check()): never a node whose name reads as destructive or as sending or confirming
a payment (DESTRUCTIVE); never a secret or phrase screen (no model call at all); `type` only into a
plain text field, never a password, PIN or phrase field, and never text that looks like a phrase
or a PIN.

Paths: a success is stored under (platform, goal, screen signature) through core/record.py
(`aipath.put`; the DB table ai_paths(key, actions, state, hits, fails)), or in the lane's
ai-paths.json when the DB is not there. States: new → reviewed → promoted, or rejected (after 2
fails). Replayed for new, reviewed and promoted. promote_report() lists the promoted ones as goal
steps for a human to paste.
"""
import hashlib
import json
import os
import re
import sqlite3
import time

from . import record

HERE = os.path.dirname(os.path.abspath(__file__))
PLAYBOOK = os.path.join(os.path.dirname(HERE), "playbook.toml")

DESTRUCTIVE = re.compile(r"\b(delete|remove|erase|reset|wipe|forget|restore|uninstall|log ?out|sign ?out|send|pay|"
                         r"cancel (the )?(payment|send)|replace|clear|import|unlink|disconnect|"
                         r"confirm|approve|accept (the )?(invoice|payment|request)|sign|finali[sz]e|broadcast|"
                         r"withdraw|transfer|spend|"
                         r"(show|reveal|view|back ?up) (the |my )?(recovery )?(phrase|words|seed))\b", re.I)
ACTIONABLE = {"button", "link", "menu_item", "row", "tab", "checkbox", "toggle"}
PHRASE = re.compile(r"(\b[a-z]{3,8}\b[\s|,]+){11,}")  # 12+ short lower-case words in a row: maybe a recovery phrase
# A phrase shown one word per node: "Word 3: ghost" (phone), "3. ghost" / "3" + "ghost" (desktop grid)
WORD_CELL = re.compile(r"(word\s*)?\d{1,2}\s*[:.)]?\s*[a-z]{3,8}", re.I)
LONE_WORD = re.compile(r"[a-z]{3,8}")
# a field never typed into, by its name
SECRET_FIELD = re.compile(r"password|passphrase|\bpin\b|phrase|seed|mnemonic|secret|\bword\s*\d", re.I)
# typed text that could be phrase words or a PIN
SECRET_TEXT = re.compile(r"([a-z]{3,8}\s+){2,}[a-z]{3,8}|\d{4,8}", re.I)

ACTIONS = ("click", "scroll", "expand", "type", "done", "give_up")
REPLAY_STATES = ("new", "replayed", "reviewed", "promoted")
MAX_FAILS = 2

SYSTEM = (
    "You help an automated test drive a wallet app's UI. You never send, pay, confirm, delete, reset, "
    "restore or reveal anything, and never type into a password, PIN or recovery phrase field. "
    "Answer with exactly one JSON object and nothing else: "
    '{"do":"click|scroll|expand|type|done|give_up","i":<node number>,"dir":"up|down","text":"...",'
    '"why":"<short reason>","pb":"<playbook key you followed, if any>"}')


def secret_screen(tree):
    return any("password" in n.states for n in tree) or phrase_screen(tree)


def phrase_screen(tree):
    """What may be a recovery phrase on the screen (a password field alone is not one): in the labels, or
    typed into fields (a restore screen's word fields, or the whole phrase pasted into one)."""
    cells = lone = vals = 0
    for n in tree:
        value = (n.value or "").strip().lower()
        if PHRASE.search(" ".join([n.name or "", n.value or ""]).lower()) or PHRASE.search(value + " "):
            return True
        name = (n.name or "").strip()
        cells += bool(WORD_CELL.fullmatch(name))
        lone += bool(LONE_WORD.fullmatch(name))
        vals += bool(LONE_WORD.fullmatch(value))
    return cells >= 3 or lone >= 6 or vals >= 6


def max_turns():
    try:
        return max(1, min(int(os.environ.get("REL_AI_TURNS") or 4), 8))
    except ValueError:
        return 4


# ---- playbook

def load_playbook(path=PLAYBOOK):
    """(version, entries); (0, []) when the file is missing or broken (the loop runs without it)."""
    try:
        import tomllib
        with open(path, "rb") as f:
            d = tomllib.load(f)
    except (OSError, ValueError, ImportError):
        return 0, []
    return int(d.get("version") or 0), [e for e in d.get("entry", []) if e.get("key") and e.get("fix")]


FAMILY = {"linux": "desktop", "windows": "desktop", "macos": "desktop", "android": "phone", "ios": "phone"}


def for_platform(entries, platform):
    want = {"all", platform, FAMILY.get(platform, "")}
    return [e for e in entries if want & set(e.get("platforms") or ["all"])]


# ---- the screen and the key

def norm(s):
    """A name as the cache keeps it: first line, case-folded, spaces collapsed, digits as #
    (latencies, ports and block heights change between runs)."""
    first = (s or "").split("\n", 1)[0]
    return re.sub(r"\d+", "#", re.sub(r"\s+", " ", first).strip().casefold())


def screen_sig(tree):
    """A stable hash of the screen's actionable nodes (role, id, name): no values, no order, no positions."""
    items = sorted({"%s|%s|%s" % (n.role, n.id or "", norm(n.name)) for n in tree
                    if n.role in ACTIONABLE or n.role == "text_field"})
    return hashlib.sha256("\n".join(items).encode()).hexdigest()[:16]


def path_key(platform, goal, sig):
    return "%s|%s|%s" % (platform, norm(goal), sig)


def ref(node):
    return {"role": node.role, "id": node.id, "name": norm(node.name)}


def resolve(r, tree):
    """The node a stored action names, on this read: by id, else by role and name."""
    if r.get("id"):
        hit = next((n for n in tree if n.id == r["id"]), None)
        if hit:
            return hit
    return next((n for n in tree if n.role == r.get("role") and norm(n.name) == r.get("name")), None)


# ---- the guards

def check(ans, tree, *, allowed=ACTIONABLE, guard=True):
    """(node or None, refusal or None) for a parsed answer on this tree. `allowed` the roles a click
    may name; guard False only for a pick whose target is itself a send or delete control (the
    recipe presses it, the model only names it)."""
    do = ans.get("do")
    if do not in ACTIONS:
        return None, "unknown action %r" % do
    if do in ("give_up", "scroll"):
        if do == "scroll" and (ans.get("dir") or "down") not in ("up", "down"):
            return None, "scroll direction %r" % ans.get("dir")
        return None, None
    i = ans.get("i")
    if do == "done" and i is None:
        return None, None
    node = next((n for n in tree if n.i == i), None) if isinstance(i, int) and not isinstance(i, bool) else None
    if node is None:
        return None, "no node #%s on this screen" % i
    name = node.name or ""
    if do == "type":
        if node.role != "text_field" or "password" in node.states or SECRET_FIELD.search("%s %s" % (name, node.id or "")):
            return None, "type into %s %r refused: not a plain text field" % (node.role, name[:40])
        text = ans.get("text")
        if not isinstance(text, str) or not text or len(text) > 120 or SECRET_TEXT.fullmatch(text.strip()) \
                or PHRASE.search(text.lower() + " "):
            return None, "type refused: the text is empty, long or could be a phrase or a PIN"
        return node, None
    if do in ("click", "done") and node.role not in allowed:
        return None, "%s on a %s, not allowed here" % (do, node.role)
    if do == "expand" and node.role not in ACTIONABLE:
        return None, "expand on a %s" % node.role
    if (guard or do == "expand") and DESTRUCTIVE.search(name):
        return None, "%s %r refused: reads as destructive or as a payment" % (do, name[:60])
    return node, None


def parse(raw):
    """The first JSON object in the model's answer; None when there is none. An answer without "do"
    (the one-turn format) is a click when it names a node, else give_up."""
    raw = (raw or "").strip()
    dec = json.JSONDecoder()
    for m in re.finditer(r"\{", raw):
        try:
            ans, _ = dec.raw_decode(raw[m.start():])
        except ValueError:
            continue
        if isinstance(ans, dict):
            if "do" not in ans and "i" in ans:
                ans["do"] = "click" if ans.get("i") is not None else "give_up"
            return ans if "do" in ans else None
    return None


def describe(a):
    """One line for an action: the history the model reads, the log, a proposed playbook fix."""
    n = a.get("node") or {}
    what = {"scroll": "scroll %s" % a.get("dir", "down"),
            "type": "type %d characters into %s %r" % (len(a.get("text") or ""), n.get("role"), n.get("name"))}.get(a["do"])
    return what or ("%s %s %r" % (a["do"], n.get("role"), n.get("name")) if n else a["do"])


# ---- the loop

class Loop:
    """One goal's turns. `ask(prompt) -> str` the model; `act(action, node)` does a scroll, expand or
    type on the app (None: no driver bound, so only click/done/give_up can be used); `reread()` the
    tree after an action; `found(tree)` the goal's node when the caller's rule already holds."""

    def __init__(self, *, mode, goal, ask, playbook, platform, log, act=None, reread=None, found=None,
                 allowed=ACTIONABLE, guard=True, turns=None):
        self.mode, self.goal, self.ask, self.platform, self.log = mode, goal, ask, platform, log
        self.playbook = for_platform(playbook, platform)
        self.act, self.reread, self.found, self.allowed, self.guard = act, reread, found, allowed, guard
        self.turns = turns if turns is not None else max_turns()
        self.used = 0
        self.history = []   # lines the model reads
        self.actions = []   # what the cache stores
        self.why = ""
        self.pb = None

    def prompt(self, tree):
        if self.mode == "pick":
            task = ("Find the control: %s. click i (or done with i) means node i IS that control. Use scroll "
                    "or expand to bring it into view; give_up when no node does that job." % self.goal)
        else:
            task = ("The test wants to reach: %s. A screen it does not know is in the way. click i names the "
                    "one control that dismisses or continues past it (OK, Got it, Continue, Not now, Skip, "
                    "Close); scroll, expand or type (a plain non-secret field only) to get there; done when "
                    "the goal is already on screen; give_up when there is nothing to get past." % self.goal)
        pb = "\n".join("- [%s] %s → %s" % (e["key"], e.get("situation", ""), e["fix"]) for e in self.playbook)
        return ("%s\n\nPlaybook (known screens):\n%s\n\nActions so far:\n%s\n\nTurn %d of %d. Screen, one node per "
                "line (#number role 'name' [states]):\n%s\n" % (
                    task, pb or "- none", "\n".join(self.history) or "- none", self.used, self.turns,
                    "\n".join(n.brief() for n in tree)))

    def waste(self, why):
        self.history.append("- turn %d: wasted: %s" % (self.used, why))
        self.log("ai turn %d (%s): wasted: %s" % (self.used, self.goal, why))

    def run(self, tree):
        """The node to hand back (click, or done with a node), or None (give_up, done, out of turns,
        a secret screen)."""
        while self.used < self.turns:
            if secret_screen(tree):
                self.why = "a secret screen (phrase, password or PIN): never sent to a model"
                return None
            self.used += 1
            try:
                raw = self.ask(self.prompt(tree))
            except Exception as e:  # noqa: BLE001 - a model failure is a wasted turn
                self.waste("model failed: %s" % str(e)[:160])
                continue
            ans = parse(raw)
            if ans is None:
                self.waste("no valid JSON answer: %r" % (raw or "")[:80])
                continue
            node, refused = check(ans, tree, allowed=self.allowed, guard=self.guard)
            if refused:
                self.waste("refused: %s" % refused)
                continue
            do, self.why = ans["do"], str(ans.get("why", ""))[:200]
            if isinstance(ans.get("pb"), str) and ans["pb"]:
                self.pb = ans["pb"][:60]
            if do == "give_up":
                self.history.append("- turn %d: give_up" % self.used)
                return None
            if do == "done" and self.mode != "pick":
                self.history.append("- turn %d: done" % self.used)
                return None   # the caller's rule re-reads the screen
            if do in ("click", "done"):
                if node is not None:
                    self.actions.append({"do": "click", "node": ref(node)})
                    return node
                if do == "done" and self.found:
                    return self.found(tree)
                return None
            if self.act is None:
                self.waste("%s needs the driver (not bound)" % do)
                continue
            a = {"do": do, "node": ref(node) if node else None, "dir": ans.get("dir") or "down", "text": ans.get("text")}
            if do != "type":
                a.pop("text")
            try:
                self.act(a, node)
            except Exception as e:  # noqa: BLE001 - the next read shows what happened
                self.waste("%s failed: %s" % (do, str(e)[:120]))
                continue
            self.actions.append(a)
            self.history.append("- turn %d: %s" % (self.used, describe(a)))
            self.log("ai turn %d (%s): %s" % (self.used, self.goal, describe(a)))
            tree = self.reread() if self.reread else tree
            hit = self.found(tree) if self.found else None
            if hit is not None:
                self.actions.append({"do": "done"})
                return hit
        self.why = self.why or "out of turns (%d)" % self.turns
        return None


# ---- the cache

class Paths:
    """AI paths: the DB's ai_paths (read-only, via record.read()), else `fallback` (a JSON file);
    writes go out as record events and into the JSON file, which also holds this lane's own
    fails before the DB writer has them."""

    def __init__(self, fallback, log=print):
        self.file, self.log = fallback, log

    def _local(self):
        try:
            with open(self.file) as f:
                return json.load(f)
        except (OSError, ValueError):
            return {}

    def _save(self, d):
        try:
            tmp = self.file + ".tmp"
            with open(tmp, "w") as f:
                json.dump(d, f, indent=1)
            os.replace(tmp, self.file)
        except OSError:
            pass

    def get(self, key):
        """{actions, state, hits, fails} when a path may be replayed; else None."""
        row = None
        conn = record.read()
        if conn is not None:
            try:
                r = conn.execute("SELECT actions, state, hits, fails FROM ai_paths WHERE key = ?", (key,)).fetchone()
                if r:
                    row = {"actions": json.loads(r[0]) if isinstance(r[0], str) else r[0],
                           "state": r[1], "hits": r[2] or 0, "fails": r[3] or 0}
            except (sqlite3.Error, ValueError, TypeError):
                row = None
            finally:
                try:
                    conn.close()
                except Exception:  # noqa: BLE001
                    pass
        local = self._local().get(key)
        if local:
            if row is None:
                row = local
            else:   # this lane's fails count before the DB writer has them
                row["fails"] = max(row["fails"], local.get("fails", 0))
                if local.get("state") == "rejected":
                    row["state"] = "rejected"
        if not row or row.get("state") not in REPLAY_STATES or row.get("fails", 0) >= MAX_FAILS or not row.get("actions"):
            return None
        return row

    def put(self, key, platform, goal, sig, actions):
        record.emit("aipath.put", key=key, platform=platform, goal=goal, screen_sig=sig, actions=actions)
        d = self._local()
        old = d.get(key, {})
        d[key] = {"platform": platform, "goal": goal, "screen_sig": sig, "actions": actions,
                  "state": old.get("state", "new"), "hits": old.get("hits", 0), "fails": old.get("fails", 0),
                  "at": time.strftime("%Y-%m-%dT%H:%M:%S")}
        self._save(d)

    def hit(self, key, platform):
        record.emit("aipath.hit", key=key, platform=platform)
        d = self._local()
        if key in d:
            d[key]["hits"] = d[key].get("hits", 0) + 1
            self._save(d)

    def fail(self, key, platform, why):
        record.emit("aipath.fail", key=key, platform=platform, why=why)
        d = self._local()
        e = d.setdefault(key, {"platform": platform, "actions": [], "state": "new", "hits": 0, "fails": 0})
        e["fails"] = e.get("fails", 0) + 1
        if e["fails"] >= MAX_FAILS:
            e["state"] = "rejected"
        self._save(d)
        self.log("ai path %s: replay failed (%s); %d fail(s)%s" % (key, why, e["fails"],
                                                                   ", rejected" if e["state"] == "rejected" else ""))


def promote_report(fallback=None):
    """The promoted AI paths as goal-step snippets for a human to paste into the recipe (core/desktop.py
    or core/phone.py): the DB's, else those in `fallback` (an ai-paths.json)."""
    rows = []
    conn = record.read()
    if conn is not None:
        try:
            rows = [(k, json.loads(a) if isinstance(a, str) else a, h or 0) for k, a, h in conn.execute(
                "SELECT key, actions, hits FROM ai_paths WHERE state = 'promoted' ORDER BY key")]
        except (sqlite3.Error, ValueError, TypeError):
            rows = []
        finally:
            try:
                conn.close()
            except Exception:  # noqa: BLE001
                pass
    if not rows and fallback:
        try:
            with open(fallback) as f:
                d = json.load(f)
            rows = [(k, v.get("actions") or [], v.get("hits", 0)) for k, v in sorted(d.items()) if v.get("state") == "promoted"]
        except (OSError, ValueError):
            rows = []
    if not rows:
        return "No promoted AI paths.\n"
    out = []
    for key, actions, hits in rows:
        platform, rest = key.split("|", 1)
        goal, sig = rest.rsplit("|", 1)
        out.append("# AI path %s: %s, %d replay(s), screen %s" % (platform, goal, hits, sig))
        lines = []
        for a in actions:
            n = a.get("node") or {}
            t = 'T(%r, role=%r, names=(%r,))' % (n.get("id") or "g4.TODO", n.get("role"), n.get("name"))
            if a["do"] == "click":
                lines.append("    d.press(%s, step=%r)," % (t, goal))
            elif a["do"] == "expand":
                lines.append("    d.press(%s, step=%r),  # expand: its toggle" % (t, goal))
            elif a["do"] == "scroll":
                lines.append("    d.s.scroll(%r)," % a.get("dir", "down"))
            elif a["do"] == "type":
                lines.append("    d.fill(%s, %r, step=%r)," % (t, a.get("text") or "", goal))
        out.append("Goal(%r, done=<the step's check>, do=lambda d: (\n%s\n))\n" % (goal, "\n".join(lines) or "    None,"))
    return "\n".join(out)
