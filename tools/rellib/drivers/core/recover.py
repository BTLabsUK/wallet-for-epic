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

Backend: the command in REL_AI_CMD, which reads the prompt on stdin and prints the answer. REL_AI=0 turns it off.
A pick is checked before it is used: it must name a node of this read, of a role the target allows
(any actionable role for `advance`), and never one whose name reads as destructive.
"""
import json
import os
import re
import shlex
import subprocess
import time

from .surface import COMPATIBLE

DESTRUCTIVE = re.compile(r"\b(delete|remove|erase|reset|wipe|forget|restore|uninstall|log ?out|sign ?out|send|pay|"
                         r"cancel (the )?(payment|send)|replace)\b", re.I)
ACTIONABLE = {"button", "link", "menu_item", "row", "tab", "checkbox", "toggle"}
PHRASE = re.compile(r"(\b[a-z]{3,8}\b[\s|,]+){11,}")  # 12+ short lower-case words in a row: maybe a recovery phrase
# A phrase shown one word per node: "Word 3: ghost" (phone), "3. ghost" / "3" + "ghost" (desktop grid)
WORD_CELL = re.compile(r"(word\s*)?\d{1,2}\s*[:.)]?\s*[a-z]{3,8}", re.I)
LONE_WORD = re.compile(r"[a-z]{3,8}")


def enabled():
    return os.environ.get("REL_AI", "1") != "0"


def secret_screen(tree):
    cells = lone = 0
    for n in tree:
        if "password" in n.states or PHRASE.search(" ".join([n.name or "", n.value or ""]).lower()):
            return True
        name = (n.name or "").strip()
        cells += bool(WORD_CELL.fullmatch(name))
        lone += bool(LONE_WORD.fullmatch(name))
    return cells >= 3 or lone >= 6


def _ask(prompt, timeout):
    cmd = os.environ.get("REL_AI_CMD")
    if cmd:
        argv = shlex.split(cmd)
    else:
        raise RuntimeError("no model command: REL_AI_CMD is not set")
    env = dict(os.environ)
    r = subprocess.run(argv, input=prompt, capture_output=True, text=True, timeout=timeout, env=env)
    if r.returncode != 0:
        raise RuntimeError("model exit %d: %s" % (r.returncode, (r.stderr or r.stdout).strip()[:200]))
    m = re.search(r"\{[^{}]*\"i\"[^{}]*\}", r.stdout, re.S)
    if not m:
        raise RuntimeError("no JSON answer: %s" % r.stdout.strip()[:200])
    return json.loads(m.group(0))


class Recover:
    """One per lane. `out` the lane's output folder; `log` a function for the lane log."""

    def __init__(self, out, platform, build="", log=print, timeout=120):
        self.out, self.platform, self.build, self.log, self.timeout = out, platform, build, log, timeout
        self.used = []          # what proof.json lists as `recovered`
        self.learned = {}       # target id -> the name the model found, reused within the lane without asking again

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
                            "`Semantics(identifier: '%s')`, or add its key to tools/rellib/drivers/trust_ids.json.\n" % (
                                e["target"], step, self.platform, self.build, getattr(target, "role", "?"), texts,
                                node.role, node.name.split("\n")[0], e["target"]))
                else:
                    f.write("- step %s (%s %s): a screen the driver does not know stood in the way; pressed %s %r to go on. "
                            "Fix: teach the recipe this screen (its id or label) or drop it from the app.\n" % (
                                step, self.platform, self.build, node.role, node.name.split("\n")[0]))
        except OSError:
            pass
        self.log("RECOVERED (%s) step %s: %s → %s (%s)" % (kind, step, e["target"], node.brief(), why))

    def _tree_text(self, tree):
        return "\n".join(n.brief() for n in tree)

    def _pick(self, prompt, tree, allowed, guard=True):
        if not enabled():
            return None, "AI fallback off (REL_AI=0)"
        if secret_screen(tree):
            return None, "a secret screen (phrase, password or PIN): never sent to a model"
        try:
            ans = _ask(prompt, self.timeout)
        except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as e:
            return None, "model failed: %s" % e
        i = ans.get("i")
        node = next((n for n in tree if n.i == i), None) if isinstance(i, int) else None
        if node is None:
            return None, "model found nothing: %s" % ans.get("why", "")
        if node.role not in allowed:
            return None, "model picked a %s, not allowed here" % node.role
        if guard and DESTRUCTIVE.search(node.name or ""):
            return None, "model picked %r, which reads as destructive" % node.name[:60]
        return node, str(ans.get("why", ""))[:200]

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
        prompt = (
            "You help an automated test drive a wallet app's UI. The step '%s' needs the control '%s' "
            "(role %s; on older builds its text was %s). It was not found under that text: the app may have "
            "renamed or moved it. Below is the screen's accessibility tree, one node per line "
            "(#number role 'name' [states]). Answer with JSON only: {\"i\": <number of the node that is that "
            "control>, \"why\": \"<short reason>\"}, or {\"i\": null, \"why\": \"...\"} when no node does the same job. "
            "Never pick a control that deletes, sends, pays or resets anything unless that is the control asked for.\n\n%s\n"
            % (step, target.id, target.role, texts or "unknown", self._tree_text(tree)))
        # a target that is itself a send or delete control may be picked as one
        guard = not DESTRUCTIVE.search("%s %s" % (target.id.replace(".", " "), texts))
        node, why = self._pick(prompt, tree, allowed, guard)
        if node is not None:
            self.learned[target.id] = node.name
            self._record("pick", step, target, node, why, texts)
        else:
            self.log("recover: %s for %s at step %s: %s" % ("no pick", target.id, step, why))
        return node

    def advance(self, goal, tree, *, step):
        """The control that gets past an unknown screen (a new dialog, an extra step) toward `goal`,
        without changing the wallet's data; None when there is none or the screen is secret."""
        prompt = (
            "You help an automated test drive a wallet app's UI. The test wants to reach: %s (step '%s'). "
            "A screen it does not know is showing (maybe a new dialog, notice or onboarding step). Below is "
            "the accessibility tree, one node per line (#number role 'name' [states]). Name the one control that "
            "dismisses or continues past this screen without deleting, sending, paying, resetting or changing "
            "settings (e.g. OK, Got it, Continue, Not now, Skip, Close). Answer with JSON only: "
            "{\"i\": <number>, \"why\": \"<short reason>\"} or {\"i\": null, \"why\": \"...\"}.\n\n%s\n"
            % (goal, step, self._tree_text(tree)))
        node, why = self._pick(prompt, tree, ACTIONABLE)
        if node is not None:
            self._record("advance", step, None, node, why, goal)
        else:
            self.log("recover: no way past the screen at step %s: %s" % (step, why))
        return node
