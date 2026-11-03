# SPDX-License-Identifier: Apache-2.0
"""The step engine every platform's lane drives the app with.

A step names its target (targets.Target) and the state it must reach (an Expect). The engine
finds the target by id or role + label on a fresh read of the tree, acts, and waits until the
expected state shows. When it does not:
  1. a known obstacle on screen (a tour, a toast, a notice the recipes list) is dismissed and the
     step tried again;
  2. the action is tried once more on a fresh read;
  3. an unknown screen in the way: recover.advance() asks the model for the control that gets past
     it (never on a secret screen);
  4. the target itself not found: recover.pick() asks the model which node it is.
Every recovery is logged; the model's are listed in proof.json. If none works the step raises
HarnessFault with one line and a screenshot. If the app's process is gone while its platform is
alive, that is the product's fault (ProductFault): the app quit by itself.

Timing: every wait polls the tree for a state, never a fixed sleep; REL_TRUST_SLOW multiplies every
timeout (a slow emulator or a loaded host), so a slow app is waited for, not failed.
"""
import os
import time

from . import targets as tg
from .faults import HarnessFault, HarnessGone, ProductFault

SLOW = float(os.environ.get("REL_TRUST_SLOW") or "1")


class Expect:
    """A state of the screen. `test(driver, tree)` truthy when reached; `what` for messages."""

    def __init__(self, what, test):
        self.what, self.test = what, test

    def __str__(self):
        return self.what


def shows(*ts):
    """Any of the targets is on screen."""
    return Expect("shows " + " or ".join(map(str, ts)), lambda d, tree: next((n for t in ts for n in d.find_in(t, tree)), None))


def gone(*ts):
    return Expect("no " + " or ".join(map(str, ts)), lambda d, tree: all(not d.find_in(t, tree) for t in ts))


def either(*es):
    return Expect(" or ".join(e.what for e in es), lambda d, tree: next((r for e in es for r in [e.test(d, tree)] if r), None))


def where(screens):
    """Which of {name: Expect} the screen is in; the first that holds."""
    return Expect("one of " + ", ".join(screens), lambda d, tree: next((k for k, e in screens.items() if e.test(d, tree)), None))


class Driver:
    def __init__(self, surface, labels, recover, *, out, log, poll=0.4):
        self.s, self.labels, self.rec, self.out, self.log, self.poll = surface, labels, recover, out, log, poll
        self.obstacles = []   # [(Target to press when it shows, why)]: tours, toasts, notices a step may meet
        self.shots = 0
        self.step = "start"
        self.trail = []       # the last steps, for the failure line

    # ---- reading

    def tree(self):
        try:
            return self.s.tree()
        except HarnessGone:
            raise
        except Exception as e:  # noqa: BLE001 — a read that failed once (the app busy) is read again
            self.log("tree read failed (%s); reading again" % e)
            time.sleep(self.poll)
            return self.s.tree()

    def find_in(self, target, tree):
        return tg.find(target, tree, self.labels)

    def texts(self, target):
        return [p for p in tg.patterns(target, self.labels)]

    def seen(self, target, tree=None):
        hits = self.find_in(target, tree if tree is not None else self.tree())
        return hits[0] if hits else None

    # ---- evidence

    def shot(self, name):
        self.shots += 1
        d = os.path.join(self.out, "shots")
        os.makedirs(d, exist_ok=True)
        p = os.path.join(d, "%03d-%s.png" % (self.shots, "".join(c if c.isalnum() or c in "-_." else "-" for c in name)[:60]))
        try:
            return os.path.relpath(p, self.out) if self.s.screenshot(p) else None
        except Exception:  # noqa: BLE001
            return None

    def dump(self, name, tree):
        """The tree as text next to the shots (never a secret screen's)."""
        from .recover import secret_screen
        if secret_screen(tree):
            return
        with open(os.path.join(self.out, "tree-%03d-%s.txt" % (self.shots, name)), "w") as f:
            f.write("\n".join(n.brief() for n in tree))

    def harness(self, what):
        tree = []
        try:
            tree = self.s.tree()
        except Exception:  # noqa: BLE001
            pass
        shot = self.shot("fail-" + self.step)
        self.dump("fail-" + self.step, tree)
        raise HarnessFault(self.step, what + " (after: %s)" % " → ".join(self.trail[-4:]), shot)

    def app_quit(self):
        shot = self.shot("app-quit-" + self.step)
        raise ProductFault(self.step, "the app quit by itself", shot)

    # ---- waiting

    def wait(self, expect, timeout=30, *, dismiss=True):
        """Polls until `expect` holds; returns its value or None at the timeout. Known obstacles are
        pressed away on the way."""
        end = time.time() + timeout * SLOW
        while True:
            tree = self.tree()
            r = expect.test(self, tree)
            if r:
                return r
            if dismiss and self._dismiss(tree):
                continue
            if not self.s.alive():
                self.app_quit()
            if time.time() >= end:
                return None
            time.sleep(self.poll)

    def must(self, expect, timeout=30, *, step=None, goal=None):
        """wait(), then an AI advance past an unknown screen, then a HarnessFault."""
        if step:
            self.step = step
        r = self.wait(expect, timeout)
        if r:
            return r
        for _ in range(3):
            tree = self.tree()
            n = self.rec.advance(goal or str(expect), tree, step=self.step)
            if n is None:
                break
            self.s.press(n)
            r = self.wait(expect, timeout)
            if r:
                return r
        self.harness("never reached: %s" % expect)

    def _dismiss(self, tree):
        for t, why in self.obstacles:
            hits = self.find_in(t, tree)
            if hits:
                self.log("obstacle %s (%s): pressed %s" % (t, why, hits[0].brief()))
                self.s.press(hits[0])
                time.sleep(self.poll)
                return True
        return False

    # ---- acting

    def locate(self, target, timeout=20):
        """The node for `target`: by id/label within `timeout`, else the model's pick; HarnessFault when none."""
        n = self.wait(shows(target), timeout)
        if n:
            return n
        tree = self.tree()
        n = self.rec.pick(target, tree, step=self.step, texts=self.texts(target))
        if n:
            return n
        self.harness("%s not on screen (looked for %s %s)" % (target, target.role, self.texts(target) or "no text"))

    def press(self, target, *, step, then=None, timeout=20, goal=None):
        """Press `target` and wait for `then` (an Expect; default: the screen changed or the target went)."""
        self.step = step
        self.trail.append(step)
        for attempt in range(2):
            node = self.locate(target, timeout)
            before = [(n.role, n.name) for n in self.tree()]
            self.s.press(node)
            want = then or Expect("the screen changed after %s" % target,
                                  lambda d, tree, b=before: [(n.role, n.name) for n in tree] != b)
            r = self.wait(want, timeout)
            if r:
                return r
            self.log("step %s: %s not reached after pressing %s (try %d)" % (step, want, node.brief(), attempt + 1))
        return self.must(then or gone(target), timeout, goal=goal or "%s, after pressing %s" % (then or "the next screen", target))

    def fill(self, target, text, *, step, timeout=20):
        """Type `text` into the field `target` and check it took (a password field's value is not
        readable on every platform: then its length or that it is non-empty)."""
        self.step = step
        self.trail.append(step)
        for attempt in range(2):
            node = self.locate(target, timeout)
            self.s.set_text(node, text)
            n = self.wait(shows(target), 5)
            v = (n.value if n else None)
            if v is None or v == text or ("password" in n.states and len(v) in (0, len(text)) and v != ""):
                return n
            self.log("step %s: the field reads %d characters, not %d (try %d)" % (step, len(v), len(text), attempt + 1))
        self.harness("%s did not take the text" % target)

    def toggle(self, target, on, *, step, timeout=20):
        """Set a check box or switch to `on`; reads its checked state before and after."""
        self.step = step
        self.trail.append(step)
        node = self.locate(target, timeout)
        if ("checked" in node.states) == on:
            return node
        self.s.press(node)
        r = self.wait(Expect("%s %s" % (target, "on" if on else "off"),
                             lambda d, tree: next((n for n in d.find_in(target, tree) if ("checked" in n.states) == on), None)), timeout)
        return r or self.harness("%s did not turn %s" % (target, "on" if on else "off"))
