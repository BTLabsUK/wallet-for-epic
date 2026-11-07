# SPDX-License-Identifier: Apache-2.0
"""The step engine every platform's lane drives the app with.

A step names its target (targets.Target) and the state it must reach (an Expect). The engine
finds the target by id or role + label on a fresh read of the tree, acts, and waits until the
expected state shows. When it does not:
  1. a known obstacle on screen (a tour, a toast, a notice the recipes list) is dismissed and the
     step tried again;
  2. the action is tried once more on a fresh read;
  3. the target itself not found: the known-trouble rules (TROUBLE) are tried in order, each
     logged: a known dialog, a scan overlay (waited out or closed), a folded section (expanded),
     the page scrolled, a stale picker (left and opened again by the recipe's `reopen`);
Every recovery is logged and listed in proof.json. If none works the step raises
HarnessFault with one line naming what was tried and a screenshot. If the app's process is gone
while its platform is alive, that is the product's fault (ProductFault): the app quit by itself;
when the surface itself went away (the display, the session), HarnessGone.

A Goal is a step that checks the state first: `done(tree)` holding already is a SKIP (logged and
sent as a step event), else `do()` runs and `done` must hold after it.

A frozen app is the product's fault too (alive_check): the platform's own sign that its UI stopped
answering (Android's "isn't responding" dialog or am_anr, a hung Windows window, an AT-SPI call to the
app unanswered for 5 s), or the app's own log for this run holding a StackOverflowError or an unhandled
error, ends the lane PRODUCT "the app froze: <evidence>" with a screenshot and the evidence in the
bundle (core/freeze.py). It runs after each step, inside the wait loops (every few seconds) and when a lane
phase asks for it.

Timing: every wait polls the tree for a state, never a fixed sleep; REL_TRUST_SLOW multiplies every
timeout (a slow emulator or a loaded host), so a slow app is waited for, not failed.
"""
import contextlib
import os
import re
import time

from . import freeze
from . import record
from . import targets as tg
from .faults import HarnessFault, HarnessGone, ProductFault, StepReached

SLOW = float(os.environ.get("REL_TRUST_SLOW") or "1")


# Moved by any press, so not a sign the press did anything.
UNCHANGED = frozenset(("focused", "showing"))


def look(tree):
    """What a press can change, in place included: a stepper's value, a switch's checked state."""
    return [(n.role, n.name, n.value, n.states - UNCHANGED) for n in tree]


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


class Goal:
    """A state to reach: `done(tree)` truthy when it holds, `do()` the steps that reach it."""

    def __init__(self, name, done, do):
        self.name, self.done, self.do = name, done, do

    def __str__(self):
        return self.name


# A scan or sync covering the page. Waited out, then closed.
# "Scanning from January 2025" and "Scanning starts ..." are lines on the restore page, no overlay.
OVERLAY_KEYS = ("deskSlotScanning", "scanProgress", "netStatusSyncing", "lvShellStateCatchingUp", "workRestoring",
                "deskOnbRestoreRestoring", "deskNodeLineKernelsBare")
OVERLAY_ROLES = ("dialog", "other", "text")
OVERLAY_CLOSE_KEYS = ("commonClose", "deskOvHide")
# A folded section's control, by its first line (or an expandable state the platform reports)
FOLD_KEYS = ("deskTxMore", "deskSetFrameAdvanced", "deskSetRowView", "msgCheckShowDetails")


class _Watched:
    """The surface, with the app freezing under any of its calls (freeze.Frozen) made this step's PRODUCT
    fault: its screenshot, its recoveries tried and the evidence for the bundle."""

    def __init__(self, driver, surface):
        self.__dict__.update(_d=driver, _s=surface)

    def unwrap(self):
        return self._s

    def __getattr__(self, k):
        attr = getattr(self._s, k)
        if not callable(attr):
            return attr

        def call(*a, **kw):
            try:
                return attr(*a, **kw)
            except freeze.Frozen as e:
                raise self._d._frozen(e.detail, e.evidence) from None
        return call


class Driver:
    TROUBLE = ("dialog", "overlay", "folded", "scroll", "stale")

    def __init__(self, surface, labels, recover, *, out, log, poll=0.4):
        self.s = _Watched(self, surface)
        self.labels, self.rec, self.out, self.log, self.poll = labels, recover, out, log, poll
        self.obstacles = []   # [(Target to press when it shows, why)]: tours, toasts, notices a step may meet
        self.shots = 0
        self.step = "start"
        self.trail = []       # the last steps, for the failure line
        self.hushed = 0       # inside hush(): no shot, no dump (words being typed)
        self.by_label = set() # target ids this build matched by label only: it gives them no id
        self.tried = []       # the recoveries tried in the current step, for the failure line and the bundle
        self.not_folds = set()  # names a recipe knows are not folded sections (Settings' own sections)
        self.reopen = None    # the recipe's stale-picker rule: reopen(target) -> what it did, or None
        self.overlay_wait = 30
        self.last_tree = []   # the newest tree read (a frozen app's screen is judged by it, not read again)
        self.checked = 0      # when alive_check last ran in full (a step's end and a wait loop share it)
        self._unfolded = set()
        self.stop_at = (os.environ.get("REL_TRUST_PROBE") or "").strip() or None  # the step a probe ends at

    # ---- reading

    def tree(self):
        try:
            self.last_tree = self.s.tree()
            return self.last_tree
        except (HarnessFault, ProductFault):  # the sandbox gone, the lane stopped
            raise
        except Exception as e:  # noqa: BLE001 — a read that failed once (the app busy) is read again
            self.log("tree read failed (%s); reading again" % e)
            time.sleep(self.poll)
            self.last_tree = self.s.tree()
            return self.last_tree

    def find_in(self, target, tree):
        """By id or label."""
        return tg.find(target, tree, self.labels)

    def texts(self, target):
        return [p for p in tg.patterns(target, self.labels)]

    def seen(self, target, tree=None):
        hits = self.find_in(target, tree if tree is not None else self.tree())
        return hits[0] if hits else None

    # ---- evidence

    @contextlib.contextmanager
    def hush(self):
        """While a secret is typed or on screen in a shape the guards may miss (the first words of a
        phrase): no screenshot, no tree dump, a failure line only."""
        self.hushed += 1
        try:
            yield self
        finally:
            self.hushed -= 1

    def shot(self, name, tree=None):
        """A screenshot, never of a secret screen (the phrase or a password shown). [tree]: the screen as
        last read, for an app that cannot be read now (frozen)."""
        from .secret import secret_screen
        if self.hushed:
            return None
        try:
            if secret_screen(self.s.tree() if tree is None else tree):
                return None
        except Exception:  # noqa: BLE001 — a tree that cannot be read is not shot either
            return None
        self.shots += 1
        d = os.path.join(self.out, "shots")
        os.makedirs(d, exist_ok=True)
        p = os.path.join(d, "%03d-%s.png" % (self.shots, "".join(c if c.isalnum() or c in "-_." else "-" for c in name)[:60]))
        try:
            return os.path.relpath(p, self.out) if self.s.screenshot(p) else None
        except Exception:  # noqa: BLE001
            return None

    def dump(self, name, tree):
        """The tree as text next to the shots: a password screen's without the field's value
        (Node.brief), never a phrase screen's."""
        from .secret import phrase_screen
        if self.hushed or phrase_screen(tree):
            return
        with open(os.path.join(self.out, "tree-%03d-%s.txt" % (self.shots, name)), "w") as f:
            f.write("\n".join(n.brief() for n in tree))

    def harness(self, what, route=None):
        """The driver cannot do its step. [route]: how a probe gets back here, kept with the fault."""
        tree = []
        try:
            tree = self.s.tree()
        except Exception:  # noqa: BLE001
            pass
        shot = self.shot("fail-" + self.step)
        self.dump("fail-" + self.step, tree)
        fault = HarnessFault(self.step, what + " (after: %s)" % " → ".join(self.trail[-4:]), shot)
        fault.route = route
        raise self._tag(fault)

    def _tag(self, fault):
        """The recoveries this step tried go with its fault (the lane's bundle lists them)."""
        fault.tried = list(self.tried)
        return fault

    def app_quit(self):
        """The app's process is gone: the product's fault, unless the platform says the surface itself
        went away (the display, the emulator, the rig session)."""
        alive = getattr(self.s, "display_alive", None)
        if alive is not None and not alive():
            raise self._tag(HarnessGone(self.step, "the app's surface went away (the display or session is gone)"))
        shot = self.shot("app-quit-" + self.step)
        raise self._tag(ProductFault(self.step, "the app quit by itself", shot))

    # ---- a frozen app, a stack overflow, an unhandled error (core/freeze.py)

    def _frozen(self, what, evidence=None):
        """The fault for an app that froze: PRODUCT, the screen as last read shot, the evidence for the bundle."""
        shot = self.shot("froze-" + self.step, tree=self.last_tree)
        f = freeze.Frozen(self.step, what, shot, evidence)
        self.log("step %s: the app froze: %s" % (self.step, what))
        return self._tag(f)

    def alive_check(self, quit=True):
        """The app is running and its UI answers; returns within ~5 s (the platform's probe is limited to
        freeze.FREEZE_S). Raises ProductFault "the app froze: <evidence>" (bundle and screenshot) for a UI that
        does not answer, or for a StackOverflowError / unhandled error the app's own log wrote in this run; the
        app having quit stays app_quit() (ProductFault, or HarnessGone when the surface went too). [quit] False:
        the process being gone is left to the caller (a step that ends the app)."""
        self.checked = time.time()
        if quit and not self.s.alive():
            self.app_quit()
        froze = getattr(self.s, "froze", None)
        why = froze() if froze else None
        if why:
            raise self._frozen(why, self._evidence())
        lines = getattr(self.s, "log_lines", None)
        found = freeze.log_problem(lines()) if lines else None
        if found:
            raise self._frozen("the app's log has a %s: %s" % (found[0], freeze.clip(found[1])), self._evidence())

    def _evidence(self):
        ev = getattr(self.s, "evidence", None)
        try:
            return ev() if ev else {}
        except Exception as e:  # noqa: BLE001 — evidence only
            self.log("freeze evidence not collected: %s" % e)
            return {}

    def _tick(self):
        """alive_check at most every FREEZE_S: the end of a step and the wait loops share it."""
        if time.time() - self.checked >= freeze.FREEZE_S:
            self.alive_check(quit=False)

    def _begin(self, step):
        self.step = step
        self.trail.append(step)
        self.tried = []

    def _reached(self):
        self._tick()
        self.reached(self.step)

    def reached(self, step):
        """Step [step] passed: a probe sent to it ends here."""
        if step == self.stop_at:
            self.log("PROBE reached %s" % step)
            self.shot("probe-" + step)
            raise StepReached(step)

    def has_control(self, target):
        """False when this build's strings know none of [target]'s keys: a release from before that control."""
        return self.labels is None or not target.keys or any(self.labels.text(k) for k in target.keys)

    # ---- waiting

    def wait(self, expect, timeout=30, *, dismiss=True):
        """Polls until `expect` holds; returns its value or None at the timeout. Known obstacles are
        pressed away on the way."""
        end = time.time() + timeout * SLOW
        noted = False
        while True:
            tree = self.tree()
            r = expect.test(self, tree)
            if r:
                return r
            if time.time() >= end:
                return None
            if dismiss and self._dismiss(tree):
                continue
            if not noted and self.overlay(tree):
                noted = True
                self.log("step %s: %s covers the page; waiting" % (self.step, self.overlay(tree).brief()))
            if not self.s.alive():
                self.app_quit()
            self._tick()
            time.sleep(self.poll)

    def must(self, expect, timeout=30, *, step=None, goal=None):
        """wait(), then a HarnessFault."""
        if step:
            self._begin(step)
        r = self.wait(expect, timeout)
        if r:
            self._reached()
            return r
        self.harness("never reached: %s%s" % (expect, self._tried_text()))

    def _tried_text(self):
        return "; tried %s" % ", ".join(self.tried) if self.tried else "; nothing known to try"

    # ---- goals

    def achieve(self, goal, timeout=10):
        """`goal.done` first: holding already, a SKIP; else `goal.do()`, then `done` must hold.
        Returns "skipped" or "done"."""
        self._begin(goal.name)
        record.emit("step.start", step=goal.name, detail="goal")
        if goal.done(self.tree()):
            self.log("SKIP %s: already done" % goal.name)
            record.emit("step.end", step=goal.name, state="skipped")
            self.reached(goal.name)
            return "skipped"
        goal.do()
        self.step = goal.name
        if self.wait(Expect("%s done" % goal.name, lambda d, tree: goal.done(tree)), timeout):
            self._reached()
            record.emit("step.end", step=goal.name, state="ok")
            return "done"
        record.emit("step.end", step=goal.name, state="failed")
        self.harness("%s: not done after its steps" % goal.name)

    # ---- known trouble

    def overlay(self, tree):
        """A scan or sync overlay covering the page, or None."""
        rx = re.compile(r"^(%s)\b" % "|".join(tg.regex(self.labels, k).split(r"\ \(")[0].rstrip("…") for k in OVERLAY_KEYS), re.I)
        return next((n for n in tree if n.role in OVERLAY_ROLES and rx.match(n.name.strip())), None)

    def untangle(self, target, timeout=3):
        """The known-trouble rules, in TROUBLE's order, until `target` shows: the node, or None. Each rule
        that acted is logged and kept in `tried`."""
        for rule in self.TROUBLE:
            did = getattr(self, "_trouble_" + rule)(target)
            if not did:
                continue
            self.tried.append("%s (%s)" % (rule, did))
            self.log("step %s: %s missing; known trouble %s: %s" % (self.step, target, rule, did))
            n = self.wait(shows(target), timeout)
            if n:
                self.log("step %s: %s found after %s" % (self.step, target, rule))
                return n
        return None

    def _trouble_dialog(self, target):
        names = []
        for _ in range(3):
            tree = self.tree()
            hit = next(((t, why, h[0]) for t, why in self.obstacles for h in [self.find_in(t, tree)] if h), None)
            if not hit:
                break
            names.append("%s pressed" % hit[1])
            self._dismiss(tree)
        return ", ".join(names) or None

    def _trouble_overlay(self, target):
        o = self.overlay(self.tree())
        if not o:
            return None
        what = o.name.split("\n")[0][:60]
        if self.wait(Expect("%s gone" % what, lambda d, tree: not d.overlay(tree)), self.overlay_wait, dismiss=False):
            return "waited out %r" % what
        close = [n for n in self.tree() if n.role in ("button", "link")
                 and n.name.split("\n")[0].strip().lower() in {tg.copy(self.labels, k).lower() for k in OVERLAY_CLOSE_KEYS}]
        if close:
            self._act(self.s.press, close[0])
            time.sleep(self.poll)
            return "%r closed with %r" % (what, close[0].name)
        return "%r still there after %d s" % (what, self.overlay_wait)

    def _trouble_folded(self, target):
        pressed = []
        fold_names = {tg.copy(self.labels, k).lower() for k in FOLD_KEYS}
        for n in self.tree():
            first = n.name.split("\n")[0].strip().lower()
            folded = ("expandable" in n.states and "expanded" not in n.states) or \
                (n.role in ("button", "row", "other", "link") and first in fold_names)
            key = (self.step, n.role, first)
            if not folded or first in self.not_folds or key in self._unfolded or "expanded" in n.states:
                continue
            self._unfolded.add(key)
            self._act(self.s.press, n)
            time.sleep(self.poll)
            pressed.append(repr(n.name.split("\n")[0][:40]))
            if self.find_in(target, self.tree()):
                break
        return "expanded " + ", ".join(pressed) if pressed else None

    def _trouble_scroll(self, target):
        for i in range(3):
            self.s.scroll("down")
            time.sleep(self.poll)
            if self.find_in(target, self.tree()):
                return "scrolled down %d" % (i + 1)
        for _ in range(3):
            self.s.scroll("up")
        return "scrolled down 3 and back"

    def _trouble_stale(self, target):
        return self.reopen(target) if self.reopen else None

    def _clear(self, target=None):
        """Known obstacles off the screen before an action: an overlay (the first-run tour) lets a
        tap through but holds the keyboard focus a control without an action needs."""
        for _ in range(3):
            if not self._dismiss(self.tree()):
                break
        if self.overlay(self.tree()):   # a tap under a scan overlay goes nowhere: waited out first
            did = self._trouble_overlay(target)
            self.tried.append("overlay (%s)" % did)
            self.log("step %s: known trouble overlay: %s" % (self.step, did))

    def _act(self, fn, node, *args):
        """A surface action; its own error (no way to reach the control) becomes this step's harness line."""
        try:
            return fn(node, *args)
        except RuntimeError as e:
            self.harness(str(e))

    def _dismiss(self, tree):
        for t, why in self.obstacles:
            hits = self.find_in(t, tree)
            if hits:
                self.log("obstacle %s (%s): pressed %s" % (t, why, hits[0].brief()))
                try:
                    self.s.press(hits[0])
                except RuntimeError as e:  # the next read shows whether it went
                    self.log("obstacle %s: %s" % (t, e))
                time.sleep(self.poll)
                return True
        return False

    # ---- acting

    def locate(self, target, timeout=20):
        """The node for `target`: by id/label within `timeout`; HarnessFault when none."""
        n = self.wait(shows(target), timeout)
        if n:
            self._note_label(target, n)
            return n
        n = self.untangle(target)
        if n:
            return n
        by_id = self.labels is not None and self.labels.ids_only
        self.harness("%s not on screen (looked for %s%s)" % (target, "the id" if by_id else "%s %s" % (target.role, self.texts(target) or "no text"),
                                                             self._tried_text()))

    def _note_label(self, target, node):
        """A target found by its label: once per lane into by-label.txt, so a build whose ids do not
        reach the platform (a release from before the ids) shows which controls still hang on text."""
        if node.id or not target.id or target.id in self.by_label:
            return
        self.by_label.add(target.id)
        try:
            with open(os.path.join(self.out, "by-label.txt"), "a", encoding="utf-8") as f:
                f.write("%s %s %r\n" % (target.id, node.role, node.name.split("\n")[0][:80]))
        except OSError:
            pass

    def press(self, target, *, step, then=None, timeout=20, goal=None):
        """Press `target` and wait for `then` (an Expect; default: the screen changed or the target went)."""
        self._begin(step)
        for attempt in range(2):
            self._clear(target)
            node = self.locate(target, timeout)
            before = look(self.tree())
            self._act(self.s.press, node)
            want = then or Expect("the screen changed after %s" % target,
                                  lambda d, tree, b=before: look(tree) != b)
            r = self.wait(want, timeout)
            if r:
                self._reached()
                return r
            self.log("step %s: %s not reached after pressing %s (try %d)" % (step, want, node.brief(), attempt + 1))
        return self.must(then or gone(target), timeout, goal=goal or "%s, after pressing %s" % (then or "the next screen", target))

    def fill(self, target, text, *, step, timeout=20):
        """Type `text` into the field `target` and check it took (a password field's value is not
        readable on every platform: then its length or that it is non-empty). A secret target's
        text goes to the surface as secret (kept off logs and command lines) and is typed hushed."""
        self._begin(step)
        for attempt in range(2):
            self._clear(target)
            node = self.locate(target, timeout)
            if target.secret:
                with self.hush():
                    self._act(self.s.set_text, node, text, True)
            else:
                self._act(self.s.set_text, node, text)
            n = self.wait(shows(target), 5)
            v = (n.value if n else None)
            if v is None or v == text or ("password" in n.states and len(v) in (0, len(text)) and v != ""):
                self._reached()
                return n
            self.log("step %s: the field reads %d characters, not %d (try %d)" % (step, len(v), len(text), attempt + 1))
        self.harness("%s did not take the text" % target)

    def toggle(self, target, on, *, step, timeout=20):
        """Set a check box or switch to `on`; reads its checked state before and after."""
        self._begin(step)
        self._clear(target)
        node = self.locate(target, timeout)
        if ("checked" in node.states) == on:
            self.log("SKIP %s: already %s" % (step, "on" if on else "off"))
            self.reached(step)
            return node
        self._act(self.s.press, node)
        r = self.wait(Expect("%s %s" % (target, "on" if on else "off"),
                             lambda d, tree: next((n for n in d.find_in(target, tree) if ("checked" in n.states) == on), None)), timeout)
        if r:
            self._reached()
        return r or self.harness("%s did not turn %s" % (target, "on" if on else "off"))
