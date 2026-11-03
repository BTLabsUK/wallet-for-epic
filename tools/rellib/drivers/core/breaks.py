# SPDX-License-Identifier: Apache-2.0
"""Break tests: faults put into a lane on purpose, to show the drivers survive what they should and
fail on what they must. Test runs only; a release run never sets REL_TRUST_BREAK.

REL_TRUST_BREAK is a comma list of:
    hide:<target id>        the driver cannot find that control by id or label (a rename it does not
                            know): the step must recover through the AI fallback and say so
    dialog:<target id>      a dialog the recipe does not know (the page's More information) opens just
                            before that step, once: the step must get past it (AI advance) and say so
    move:<target id>        a setting is not on the pages the recipe expects (it moved): found by
                            searching every Settings section
    kill@<phase>            the sandbox / emulator / rig session is killed as the phase starts
                            (HarnessGone: the lane rebuilds it and runs the phase again)
    slow@<phase>:<seconds>  the app is frozen for that long as the phase starts
    lose-balance            the previous release's wallet loses its outputs while it is closed (before
                            the update): balance_kept must come out false, a product fault. Needs a
                            plain store: 26.10.25 and later encrypt theirs, so use lose-node there
    lose-node               the custom node is removed from the closed previous release's settings
                            (before the update): custom_nodes_kept must come out false, a product fault
    fold:<target id>        the control sits in a folded section: hidden behind a "Show more" button
                            until that is pressed. The driver's known-trouble rule "folded" expands it
    overlay@<phase>[:N]     a "Scanning the chain…" overlay covers the page for N tree reads (default 20)
                            as the phase starts: waited out ("overlay" rule), never pressed through
    stale:<picker id>       after the server is typed into that picker, its rows read stale (gone) until
                            the picker is closed: the "stale" rule leaves it, opens it again and retypes
    selected:<picker id>    the server is chosen in that picker before the step: the step's goal must
                            SKIP ("SKIP ...: already done")
    quit@<phase>[:s]        the app's process is killed as the phase starts (after s seconds): the lane
                            ends PRODUCT (the app quit), or HarnessGone when the surface went with it
    node-down               the first node the LEPIC CLI reads through is unreachable, once: it moves to
                            the next node of the test order and logs it (INFRA node when all fail)
    ssh-timeout@<phase>     a hook only: ssh_timeout(phase) is True once for that phase, and a rig
                            platform (windows_platform) takes it as an ssh timeout of its own
Each kind ends in a named cause or a logged recovery, never a bare "not found".
"""
import os
import threading
import time

from .surface import Node

KINDS = ("hide:", "dialog:", "move:", "kill@", "slow@", "lose-balance", "lose-node", "fold:", "overlay@",
         "stale:", "selected:", "quit@", "node-down", "ssh-timeout@")


class BreakRefused(RuntimeError):
    pass


def refuse_in_release():
    """The rel engine sets REL_RUN_KIND=release for a run that is not --test: no break list then. A
    kind this module does not know is refused too (a typo would test nothing)."""
    if os.environ.get("REL_RUN_KIND") == "release" and _items():
        raise BreakRefused("REL_TRUST_BREAK is set in a release run: break tests run in --test runs only")
    bad = [it for it in _items() if not any(it == k or (k[-1] in ":@" and it.startswith(k)) for k in KINDS)]
    if bad:
        raise BreakRefused("REL_TRUST_BREAK: unknown kind %s (known: %s)" % (", ".join(bad), " ".join(KINDS)))


def _items():
    return [x.strip() for x in (os.environ.get("REL_TRUST_BREAK") or "").split(",") if x.strip()]


_unfolded = set()
_peek = []


def hidden(target_id):
    if _peek:
        return False
    return ("hide:%s" % target_id) in _items() or folded(target_id)


def folded(target_id):
    return ("fold:%s" % target_id) in _items() and target_id not in _unfolded


def _arg(prefix):
    """The ids given to `prefix` (fold:, stale:, selected:)."""
    return [it[len(prefix):] for it in _items() if it.startswith(prefix)]


_once = set()


def _first(key):
    if key in _once:
        return False
    _once.add(key)
    return True


def stale_once(picker_id):
    """True once per picker named by stale:<id>."""
    return ("stale:%s" % picker_id) in _items() and _first("stale:" + picker_id)


def selected(picker_id):
    """True once per picker named by selected:<id>: the recipe chooses the server before its step."""
    return ("selected:%s" % picker_id) in _items() and _first("selected:" + picker_id)


def node_down():
    """True once: the LEPIC CLI's first node is an unreachable one."""
    return "node-down" in _items() and _first("node-down")


def ssh_timeout(phase):
    """True once for ssh-timeout@<phase>. A hook for a rig platform: windows_platform calls it before its
    ssh calls in that phase and takes a True as an ssh timeout (its own retry, then InfraFault ssh)."""
    return ("ssh-timeout@%s" % phase) in _items() and _first("ssh-timeout@" + phase)


def reset():
    """Forget the once-only breaks (tests)."""
    _dialogs.clear()
    _once.clear()
    _unfolded.clear()
    _overlay[0] = 0


_dialogs = set()


def dialog(target_id):
    """True once per target named by dialog:<id>."""
    if ("dialog:%s" % target_id) in _items() and target_id not in _dialogs:
        _dialogs.add(target_id)
        return True
    return False


def moved(target_id):
    return ("move:%s" % target_id) in _items()


def lose_balance():
    return "lose-balance" in _items()


# ---- the surface with screen faults put in (Driver wraps every surface; a pass-through without a break)

FOLD_BUTTON = "Show more"
OVERLAY_NAME = "Scanning the chain…"
_overlay = [0]   # tree reads the overlay still covers (any wrapped surface: the app may be opened after the phase starts)


class Broken:
    """A Surface with fold, overlay and stale put in. Anything else goes to the surface underneath."""

    def __init__(self, surface):
        self._s = surface
        self.hide_rows = None   # stale: a predicate on nodes kept off the tree until the next Escape

    def __getattr__(self, k):
        return getattr(self._s, k)

    def tree(self):
        t = self._s.tree()
        folds = [i for i in _arg("fold:") if folded(i) and self._holds(i, t)]
        if folds:
            t = [n for n in t if n.id not in folds]
            t.append(Node(i=len(t) + 900, role="button", name=FOLD_BUTTON, states=frozenset({"enabled", "showing"}),
                          actions=("press",), ref="break-fold"))
        if self.hide_rows is not None:
            t = [n for n in t if not self.hide_rows(n)]
        if _overlay[0] > 0:
            _overlay[0] -= 1
            t = [Node(i=999, role="dialog", name=OVERLAY_NAME, states=frozenset({"showing"}), ref="break-overlay")] + t
        return t

    @staticmethod
    def _holds(target_id, tree):
        """The folded control is on this page: by its id, else by the recipe target's label."""
        if any(n.id == target_id for n in tree):
            return True
        from . import targets as tg
        t = _target(target_id)
        if t is None:
            return False
        _peek.append(1)
        try:
            return bool(tg.find(t, tree))
        finally:
            _peek.pop()

    def press(self, node):
        if node.ref == "break-fold":
            _unfolded.update(_arg("fold:"))
            return None
        if node.ref == "break-overlay":
            return None
        return self._s.press(node)

    def key(self, name):
        if name == "escape":
            self.hide_rows = None
        return self._s.key(name)


def _target(target_id):
    """The recipe's Target with that id (desktop or phone), for a fold on a build without the id."""
    import importlib
    for mod in ("desktop", "phone"):
        try:
            m = importlib.import_module("." + mod, __package__)
        except Exception:  # noqa: BLE001
            continue
        for v in vars(m).values():
            if getattr(v, "id", None) == target_id and hasattr(v, "keys"):
                return v
    return None


def wrap(surface):
    """The surface, wrapped when the break list has a screen fault; else itself."""
    if isinstance(surface, Broken) or not any(it.startswith(("fold:", "overlay@", "stale:")) for it in _items()):
        return surface
    return Broken(surface)


def stale_rows(surface, pred):
    """stale: rows matching `pred` read gone until the next Escape."""
    if isinstance(surface, Broken):
        surface.hide_rows = pred


def at_phase(lane, phase):
    """Called by lane.run_phase as [phase] starts (the first time only)."""
    for it in _items():
        if it.startswith("overlay@%s" % phase) and _first(it):
            reads = int(it.split(":", 1)[1]) if ":" in it else 20
            lane.log("BREAK: a scan overlay covers the page for %d reads as %s starts" % (reads, phase))
            _overlay[0] = reads
        elif (it == "quit@%s" % phase or it.startswith("quit@%s:" % phase)) and _first(it):
            after = float(it.split(":", 1)[1]) if ":" in it else 0
            quit_ = getattr(lane.p, "break_quit", None)
            if quit_ is None:
                from .faults import HarnessFault
                raise HarnessFault(phase, "break quit@: the %s platform cannot kill the app" % lane.p.name)
            lane.log("BREAK: the app is killed %s as %s starts" % ("after %d s" % after if after else "", phase))
            if after:
                threading.Timer(after, quit_).start()
            else:
                quit_()
                time.sleep(1)
        if it == "kill@%s" % phase and phase not in lane.retried:
            lane.log("BREAK: killing the platform's session as %s starts" % phase)
            lane.p.break_kill()
        elif it.startswith("slow@%s:" % phase) and phase not in lane.retried:
            s = float(it.split(":", 1)[1])
            lane.log("BREAK: the app frozen for %d s as %s starts" % (s, phase))
            lane.p.break_freeze(True)
            threading.Timer(s, lambda: lane.p.break_freeze(False)).start()
        elif it == "lose-balance" and phase == "snapshot":
            lane.log("BREAK: the previous release's wallet loses its outputs before the update")
            lane.p.break_lose_balance()
        elif it == "lose-node" and phase == "snapshot":
            lane.log("BREAK: the previous release's custom node is lost before the update")
            lane.p.break_lose_node()
