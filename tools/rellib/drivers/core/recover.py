# SPDX-License-Identifier: Apache-2.0
"""The AI fallback: when a step's target is not on the screen by id or label, a model reads the
screen's accessibility tree as text and names the node that is it, or the control that gets past
a screen the driver does not know.

Rules (the owner, 2026-11-03):
  - a lane that used it may pass; every use is listed in proof.json `recovered` and the release
    summary, with a drafted selector fix (selector-fixes.md next to the proof);
  - checks never come from here: the model only says what to press;
  - a screen that holds a recovery phrase, a password or a PIN is never sent: a secret target, a
    password field, or a run of words that could be a phrase on the screen makes it refuse.

Order: a cached AI path for this (platform, goal, screen) is replayed without the model; else the
loop in core/ailoop.py runs a few model turns (REL_AI_TURNS, default 4) with the playbook
(drivers/playbook.toml). A pick is checked before it is used: it must name a node of this read, of a
role the target allows (any actionable role for `advance`), and never one whose name reads as
destructive (ailoop.check).

Backend: the command in REL_AI_CMD, which reads the prompt on stdin and prints the answer. REL_AI=0
turns it off.

Hooks the driver may call (both optional): bind(driver) lets the loop scroll, expand and type and
read the screen again between turns; reached(step) says the step's rule held after a recovery,
which stores the path (aipath.put), counts a replay's hit and proposes a playbook entry.
"""
import json
import os
import shlex
import subprocess
import time

from . import ailoop, record
from .ailoop import ACTIONABLE, DESTRUCTIVE, LONE_WORD, PHRASE, WORD_CELL, phrase_screen, secret_screen  # noqa: F401
from .surface import COMPATIBLE


def enabled():
    return os.environ.get("REL_AI", "1") != "0"


def _ask(prompt, timeout):
    """The model's raw answer to one prompt: one turn, no tools, so it cannot run out of turns."""
    cmd = os.environ.get("REL_AI_CMD")
    if cmd:
        argv, prompt = shlex.split(cmd), ailoop.SYSTEM + "\n\n" + prompt
    else:
        raise RuntimeError("no model command: REL_AI_CMD is not set")
    r = subprocess.run(argv, input=prompt, capture_output=True, text=True, timeout=timeout, env=dict(os.environ))
    if r.returncode != 0:
        raise RuntimeError("model exit %d: %s" % (r.returncode, (r.stderr or r.stdout).strip()[:200]))
    return r.stdout


class Recover:
    """One per lane. `out` the lane's output folder; `log` a function for the lane log; `ask` a
    model (prompt -> answer text) in place of _ask, for tests."""

    def __init__(self, out, platform, build="", log=print, timeout=120, ask=None):
        self.out, self.platform, self.build, self.log, self.timeout = out, platform, build, log, timeout
        self.ask = ask
        self.used = []          # what proof.json lists as `recovered`
        self.learned = {}       # target id -> the name the model found, reused within the lane without asking again
        self.driver = None
        self.playbook_version, self.playbook = ailoop.load_playbook()
        self.paths = ailoop.Paths(os.path.join(out, "ai-paths.json"), log)
        self._sess = None       # this step's goals: their turns and actions carry over calls
        self._pending = {}      # step -> {key: path}, stored when reached(step) says the rule held

    # ---- hooks

    def bind(self, driver):
        """The driver this lane drives with: its surface acts for scroll, expand and type, and its
        reads and find_in re-check between turns. Unbound, the loop can only name a node."""
        self.driver = driver

    def reached(self, step):
        """The step's rule held after a recovery: store the model's paths, count the replays' hits,
        and propose a playbook entry for a fault the rules did not know."""
        for key, p in self._pending.pop(step, {}).items():
            if p["replayed"]:
                self.paths.hit(key, self.platform)
                continue
            self.paths.put(key, self.platform, p["goal"], p["sig"], p["actions"])
            if not p["pb"]:
                record.emit("playbook.propose", key=ailoop.norm(p["goal"])[:60], platform=self.platform, step=step,
                            situation="%s: %s; the rules found no way past it" % (p["mode"], p["goal"]),
                            fix=" → ".join(ailoop.describe(a) for a in p["actions"] if a["do"] != "done"),
                            playbook_version=self.playbook_version)

    def moved(self, step, target, section, expected):
        """A setting found by walking every Settings section, not on the pages the recipe names: listed as a
        recovery (no model asked), with a drafted fix to the recipe."""
        from .surface import Node
        self._record("moved", step, target, Node(i=-1, role="section", name=section),
                     "found under Settings › %s by walking the sections" % section, list(expected))

    def _record(self, kind, step, target, node, why, texts):
        e = {"kind": kind, "step": step, "target": getattr(target, "id", str(target)), "platform": self.platform,
             "build": self.build, "picked": {"role": node.role, "name": node.name, "id": node.id}, "why": why,
             "looked_for": texts, "at": time.strftime("%Y-%m-%dT%H:%M:%S")}
        self.used.append(e)
        try:
            with open(os.path.join(self.out, "recovered.json"), "w") as f:
                json.dump(self.used, f, indent=1)
            with open(os.path.join(self.out, "selector-fixes.md"), "a") as f:
                if kind == "pick":
                    f.write("- `%s` (step %s, %s %s): not found as %s %s; the screen has %s %r. Fix: give the control "
                            "`trustId('%s', …)` (app/lib/src/trust_ids.dart), or add its key to tools/rellib/drivers/trust_ids.json.\n" % (
                                e["target"], step, self.platform, self.build, getattr(target, "role", "?"), texts,
                                node.role, node.name.split("\n")[0], e["target"]))
                elif kind == "moved":
                    f.write("- `%s` (step %s, %s %s): not on Settings › %s; found under Settings › %s. Fix: name that page "
                            "for it in the recipe (core/desktop.py), or move the control back.\n" % (
                                e["target"], step, self.platform, self.build, " / ".join(texts) or "?", node.name))
                else:
                    f.write("- step %s (%s %s): a screen the driver does not know stood in the way; pressed %s %r to go on. "
                            "Fix: teach the recipe this screen (its id or label) or drop it from the app.\n" % (
                                step, self.platform, self.build, node.role, node.name.split("\n")[0]))
        except OSError:
            pass
        self.log("RECOVERED (%s) step %s: %s → %s (%s)" % (kind, step, e["target"], node.brief(), why))


    # ---- the model, the cache and the loop

    def _model(self, prompt):
        return self.ask(prompt) if self.ask else _ask(prompt, self.timeout)

    def _bound(self):
        return self.driver if self.driver is not None and getattr(self.driver, "s", None) is not None else None

    def _act(self, a, node):
        s = self.driver.s
        if a["do"] == "scroll":
            s.scroll(a.get("dir") or "down")
        elif a["do"] == "expand":
            (getattr(s, "expand", None) or s.press)(node)
        elif a["do"] == "type":
            s.set_text(node, a["text"])
        else:
            s.press(node)
        time.sleep(getattr(self.driver, "poll", 0.4))

    def _session(self, mode, step, goal, tree):
        """The goal's turns and actions, kept over the calls within one step."""
        k = (mode, step, ailoop.norm(goal))
        if self._sess is None or self._sess["step"] != step:
            self._sess = {"step": step}
        if k not in self._sess:
            # an earlier recovery in this step that is still pending did not get the step through
            for key, p in list(self._pending.get(step, {}).items()):
                if p["replayed"]:
                    self.paths.fail(key, self.platform, "the step needed another recovery after it")
                del self._pending[step][key]
            sig = ailoop.screen_sig(tree)
            self._sess[k] = {"mode": mode, "goal": goal, "sig": sig, "key": ailoop.path_key(self.platform, goal, sig),
                             "loop": None, "tried": False, "replay": False}
        return self._sess[k]

    def _replay(self, row, tree, *, allowed, guard, found):
        """(node, None) when the cached path got there; (None, why) when it did not. Every action is
        checked by the same guards as the model's, on the screen as it is now."""
        d = self._bound()
        acts = row["actions"]
        if d is None and not (len(acts) == 1 and acts[0]["do"] == "click"):
            return None, "unbound"
        for idx, a in enumerate(acts):
            if a["do"] == "done":
                hit = found(tree) if found else None
                return (hit, None) if hit is not None else (None, "the target is not there")
            node = ailoop.resolve(a["node"], tree) if a.get("node") else None
            if a.get("node") and node is None:
                return None, "%s is not on the screen" % ailoop.describe(a)
            last = idx == len(acts) - 1
            ans = {"do": a["do"], "i": node.i if node else None, "dir": a.get("dir"), "text": a.get("text")}
            n, refused = ailoop.check(ans, tree, allowed=allowed if last else ACTIONABLE, guard=guard or not last)
            if refused:
                return None, refused
            if a["do"] == "click" and last:
                return n, None
            try:
                self._act(a, n)
            except Exception as e:  # noqa: BLE001
                return None, "%s failed: %s" % (a["do"], e)
            tree = d.tree()
            hit = found(tree) if found else None
            if hit is not None:
                return hit, None
        return None, "the path ended without the goal"

    def _run(self, mode, step, goal, tree, *, allowed, guard, found=None):
        """The node from a cached path or the loop, and why; None and why not."""
        if not enabled():
            return None, "AI fallback off (REL_AI=0)"
        d = self._bound()
        if secret_screen(tree) or (d is not None and getattr(d, "hushed", 0)):
            return None, "a secret screen (phrase, password or PIN): never sent to a model"
        s = self._session(mode, step, goal, tree)
        if s["replay"]:   # handed back a replay, and the caller's rule did not hold
            s["replay"] = False
            self._pending.get(step, {}).pop(s["key"], None)
            self.paths.fail(s["key"], self.platform, "the step's rule did not hold after the replay")
        if not s["tried"]:
            s["tried"] = True
            row = self.paths.get(s["key"])
            if row:
                node, why = self._replay(row, tree, allowed=allowed, guard=guard, found=found)
                if node is not None:
                    s["replay"] = True
                    self._pending.setdefault(step, {})[s["key"]] = {"replayed": True}
                    self.log("ai path %s: replayed (%s)" % (s["key"], row.get("state")))
                    return node, "replay of a cached AI path (%s)" % row.get("state")
                if why != "unbound":
                    self.paths.fail(s["key"], self.platform, why)
                    if d is not None:
                        tree = d.tree()
        if s["loop"] is None:
            s["loop"] = ailoop.Loop(mode=mode, goal=goal, ask=self._model, playbook=self.playbook, platform=self.platform,
                                    log=self.log, act=self._act if d is not None else None,
                                    reread=d.tree if d is not None else None, found=found, allowed=allowed, guard=guard)
        loop = s["loop"]
        node = loop.run(tree)
        if node is not None:
            self._pending.setdefault(step, {})[s["key"]] = {
                "replayed": False, "mode": mode, "goal": goal, "sig": s["sig"], "actions": list(loop.actions), "pb": loop.pb}
            return node, loop.why
        return None, "model found nothing: %s" % (loop.why or "no answer")

    def pick(self, target, tree, *, step, texts):
        """The node in `tree` that is `target`, which was not found by id or by `texts`; None when none."""
        if target.secret:
            return None
        known = self.learned.get(target.id)
        if known:
            node = next((n for n in tree if n.name == known and n.role in COMPATIBLE.get(target.role, {target.role})), None)
            if node:
                return node
        allowed = COMPATIBLE.get(target.role, {target.role})
        goal = ("the control '%s' (role %s) for the step '%s'; on older builds its text was %s. It was not found "
                "under that text: the app may have renamed or moved it" % (target.id, target.role, step, texts or "unknown"))
        # a target that is itself a send or delete control may be named as one (the recipe presses it)
        guard = not DESTRUCTIVE.search("%s %s" % (target.id.replace(".", " "), texts))
        d = self._bound()
        found = (lambda t: next(iter(d.find_in(target, t)), None)) if d is not None and hasattr(d, "find_in") else None
        node, why = self._run("pick", step, goal, tree, allowed=allowed, guard=guard, found=found)
        if node is not None:
            self.learned[target.id] = node.name
            self._record("pick", step, target, node, why, texts)
        else:
            self.log("recover: %s for %s at step %s: %s" % ("no pick", target.id, step, why))
        return node

    def advance(self, goal, tree, *, step):
        """The control that gets past an unknown screen (a new dialog, an extra step) toward `goal`,
        without changing the wallet's data; None when there is none or the screen is secret."""
        node, why = self._run("advance", step, goal, tree, allowed=ACTIONABLE, guard=True)
        if node is not None:
            self._record("advance", step, None, node, why, goal)
        else:
            self.log("recover: no way past the screen at step %s: %s" % (step, why))
        return node
