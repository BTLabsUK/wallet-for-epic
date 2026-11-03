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
"""
import os
import threading


class BreakRefused(RuntimeError):
    pass


def refuse_in_release():
    """The rel engine sets REL_RUN_KIND=release for a run that is not --test: no break list then."""
    if os.environ.get("REL_RUN_KIND") == "release" and _items():
        raise BreakRefused("REL_TRUST_BREAK is set in a release run: break tests run in --test runs only")


def _items():
    return [x.strip() for x in (os.environ.get("REL_TRUST_BREAK") or "").split(",") if x.strip()]


def hidden(target_id):
    return ("hide:%s" % target_id) in _items()


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


def at_phase(lane, phase):
    """Called by lane.run_phase as [phase] starts (the first time only)."""
    for it in _items():
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
