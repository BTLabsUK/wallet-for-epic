# SPDX-License-Identifier: Apache-2.0
"""Continue: a lane that hits a harness fault stays where it is, and goes on from that action after the fix.

The lane parks instead of ending: the app stays up on its screen, the process waits, `tools/rel
continue <step>` asks it to go on. It reloads the driver code (reload_drivers) and runs the phase
again, this time on what the first run recorded: the same code path, fixed, reaches the failed
action without touching the app, and from there everything is live. So the fix may be anywhere in
the drivers, in the middle of the phase's own call stack.

What it records, while tools/rel asks for it (REL_TRUST_PARK=<seconds a park may last>, never on a
probe), per phase, in memory only: each outermost call on the surface, on the platform, on the funder
and on the two Wallet helpers, with what it returned or raised and when. Nothing here reaches a disk:
it holds what a password field was given.

Replay. An action (a press, a send, an install) that matches the record returns what it returned, and
is not done again. A read gives the recorded reads in order, the last one for good, a live one when
there is none. The clock is the recorded one and sleeps take no time, so waits end where they ended.
Logs and DB events are off. When the last action that succeeded has been consumed the replay is over:
the failed action, and the reads before it, run live, with a clock that does not count the park. The
search that failed is part of that action: the scrolls and known-trouble presses at the end of the
record are not replayed, and the fixed code looks at the screen they left.

State. A phase's kit objects (the lane, the wallets, the recipes, the drivers, the ledger) go back
to what they held when it began, and the phase's own code rebuilds them. The platforms, surfaces and
seeds and the file and log cursors are left out: the app's live state is the one at the park.

When the fix changes the path: an action that does not match the record ends the replay and goes
live there, on the screen the app is on. In a funds phase that is refused: core.faults.Diverged ends
the lane rather than risk paying twice. Once raised it stays raised: each further call in the phase
raises it again, and a phase that returned with it swallowed raises it at its end, so no catch-all on
the way (the Tor fallback, a kick) can carry on to the next send. A funds phase that ends with recorded
actions unused ends the same way. A fault during the replay parks again.

What cannot go on from the action, and where it goes instead:
- one platform call (an install, an update, a restore) is one action: it runs again whole.
- HarnessGone, a dead app, product and infra faults do not park.
- a send or cancel on the funder that raised does not park: P's service may finish it after the client
  gave up, and nothing here can tell.
- the frames already running keep their code: Lane._main and _candidate (the phase order) and lambdas
  written inside them. What they call is new.
- windows/agent.ps1, linux/atspi_worker.py and linux/standin.py run outside the lane process.
- a lane process that is gone has nothing to hold: tools/rel continue goes back to its resume point.

This module stays out of the reload: it holds the journal in flight."""
import collections
import contextlib
import copy
import functools
import gc
import json
import os
import re
import sys
import threading
import time
import types

PARKED, CONTINUE, ANSWER, CONTINUES = "parked.json", "continue.json", "continue-done.json", "continues.jsonl"
READS = {"s": {"tree", "alive", "screenshot", "in_front", "foreground", "display_alive", "froze", "log_lines", "evidence",
               "keyboard_shown", "size", "online"},
         "p": {"alive", "digest", "logs", "appimage", "resume_dir", "resume_handle", "ready"},
         "f": {"ready", "finalized", "relay", "info", "total"},
         "w": {"listening"}}
UNKEYED = {"screenshot"}  # its path counts shots, which a fix may change
PASS = {"log", "unwrap"}
FUNDS = re.compile(r"fund|pay|sweep|send|receive|back|invoice|link-end")
SPENDS = ("send", "cancel")  # on the funder
NEVER = {"ProductFault", "Frozen", "HarnessGone", "LaneStopped", "RefusedStart", "InfraFault", "Diverged", "_Stop",
         "StepReached"}
OUT = {"Platform", "P", "LaneSeed", "_Watched", "Held", "BaseException",  # the surfaces are duck typed: named one by one
       "AtspiSurface", "WinSurface", "WdaSurface", "Wda", "Uia", "Device", "Rig", "Mac", "Sim",
       "LogCursor", "DirFiles", "AppFiles", "LepicCli"}
MOVES = {"scroll", "hide_keyboard"}  # looks around, whoever does it: see Journal.trimmed
SPIN = 5000  # reads past the end of what was recorded before a loop counts as lost

current = None  # the journal of the phase in flight
_held = None
_MAIN = threading.main_thread().ident
_real = {}


class _Again(BaseException):
    """A parked fault was caught below the phase, and the person said go on: back up to the phase."""


class _Clock:
    replay = False
    t = m = 0.0        # the time during a replay
    skew_t = skew_m = 0.0  # what the rest of a phase after a park does not count


def _time():
    if threading.get_ident() == _MAIN:
        return _Clock.t if _Clock.replay else _real["time"]() - _Clock.skew_t
    return _real["time"]()


def _monotonic():
    if threading.get_ident() == _MAIN:
        return _Clock.m if _Clock.replay else _real["monotonic"]() - _Clock.skew_m
    return _real["monotonic"]()


def _sleep(s):
    if _Clock.replay and threading.get_ident() == _MAIN:
        _Clock.t += s
        _Clock.m += s
        return
    _real["sleep"](s)


def _clock_at(e):
    _Clock.t, _Clock.m = max(_Clock.t, e.t), max(_Clock.m, e.m)


def _clock_end():
    """The replay is over: real time again, less the time parked."""
    _Clock.replay = False
    _Clock.skew_t, _Clock.skew_m = _real["time"]() - _Clock.t, _real["monotonic"]() - _Clock.m


def _clock_reset():
    _Clock.replay = False
    _Clock.skew_t = _Clock.skew_m = 0.0


def _norm(v):
    """What identifies an argument between two runs of the same code."""
    if isinstance(v, (str, bytes, int, float, bool, type(None))):
        return repr(v)
    name = type(v).__name__
    if name == "Node":
        return "Node(%s,%s)" % (v.role, v.name)
    if name == "Target":
        return "Target(%s)" % v.id
    if name == "Decimal":
        return str(v)
    if isinstance(v, dict):
        return "{%s}" % ",".join(sorted("%s:%s" % (_norm(k), _norm(x)) for k, x in v.items()))
    if isinstance(v, (list, tuple)):
        return "[%s]" % ",".join(_norm(x) for x in v)
    if isinstance(v, (set, frozenset)):
        return "{%s}" % ",".join(sorted(_norm(x) for x in v))
    return name


def _copy(v, memo, found=None):
    """v with its plain containers new. Kit objects stay themselves, and go into found."""
    if isinstance(v, (str, bytes, int, float, bool, type(None))):
        return v
    i = id(v)
    if i in memo:
        return memo[i]
    if isinstance(v, dict):
        c = copy.copy(v)
        memo[i] = c
        for k in list(c):
            c[k] = _copy(c[k], memo, found)
        return c
    if type(v) is list:
        c = []
        memo[i] = c
        c.extend(_copy(x, memo, found) for x in v)
        return c
    if type(v) is tuple:
        return tuple(_copy(x, memo, found) for x in v)
    if type(v) is set:
        return set(v)
    if found is not None and _kit(v):
        found.append(v)
    return v


def _clone(v):
    return _copy(v, {})


def _kit(o):
    """An object of the kit's own, whose attributes a phase may change. Not the live side: see the module doc."""
    if isinstance(o, (type, types.ModuleType, types.FunctionType, types.MethodType)) or not hasattr(o, "__dict__"):
        return False
    path = getattr(sys.modules.get(type(o).__module__), "__file__", "") or ""
    if not os.path.realpath(path).startswith(_drivers() + os.sep):
        return False
    return not {c.__name__ for c in type(o).__mro__} & OUT


def _drivers():
    return _held.root if _held is not None else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _snapshot(root):
    saved, seen, memo, stack = [], set(), {}, [root]
    while stack:
        o = stack.pop()
        if id(o) in seen:
            continue
        seen.add(id(o))
        found = []
        saved.append((o, _copy(vars(o), memo, found)))
        stack.extend(found)
    return saved


def _restore(saved):
    memo = {}
    for o, d in saved:
        fresh = _copy(d, memo)
        o.__dict__.clear()
        o.__dict__.update(fresh)


def _atoms(target):
    """The plain attributes of a platform or the funder after an action: P's slate, a platform's running."""
    if target is None:
        return None
    return {k: v for k, v in vars(target).items() if isinstance(v, (str, int, float, bool, type(None)))}


class Entry:
    __slots__ = ("kind", "tag", "name", "key", "value", "exc", "t", "m", "n", "attrs", "search")

    def __init__(self, kind, tag, name, key, value, exc, t, m, attrs, search=False):
        self.kind, self.tag, self.name, self.key, self.value, self.exc = kind, tag, name, key, value, exc
        self.t, self.m, self.n, self.attrs, self.search = t, m, 1, attrs, search


class Replay:
    def __init__(self, journal, entries):
        self.j = journal
        self.parts, self.values, self.last, self.attrs, self.spun = [], {}, {}, {}, 0
        reads = {}
        for e in entries:
            if e.kind == "read":
                reads.setdefault(e.key, collections.deque()).append([e, e.n])
            elif e.kind == "value":
                self.values.setdefault(e.key, collections.deque()).append(e)
            else:
                self.parts.append((reads, e))
                reads = {}
        self.i = 0
        self.total = len(self.parts)

    def read(self, key):
        q = self.parts[self.i][0].get(key)
        if q:
            e = q[0][0]
            q[0][1] -= 1
            if q[0][1] <= 0 and len(q) > 1:
                q.popleft()
            self.last[key] = e
            self.spun = 0
            _clock_at(e)
            return e
        e = self.last.get(key)
        if e is None:
            return None
        self.spun += 1
        if self.spun > SPIN:
            self.j.stop()
            self.j.log("replay: a loop reads on past what was recorded: live from action %d of %d" % (self.i + 1, self.total))
            return None
        return e

    def act(self, key, tag, name):
        reads, e = self.parts[self.i]
        if e.key != key:
            return self.left(e, tag, name)
        self.i += 1
        self.spun = 0
        _clock_at(e)
        self.attrs[tag] = e.attrs
        if self.i == self.total:
            self.j.stop()
        return e

    def left(self, e, tag, name):
        """The fixed code does something else than the record here."""
        rest = [x for _, x in self.parts[self.i:]]
        at = "action %d of %d: %s %s, the record has %s %s" % (self.i + 1, self.total, tag, name, e.tag, e.name)
        self.j.stop()
        if self.pays(rest):
            raise self.j.diverge("the replay left the recorded path at %s. In a funds phase it stops there: going on "
                                 "live could pay twice." % at)
        self.j.log("replay left the recorded path at %s: live from here" % at)
        return None

    def pays(self, rest):
        return FUNDS.search(self.j.phase) or any(x.tag[0] == "f" and x.name in SPENDS for x in rest)

    def unused(self):
        """The phase returned before the record ran out: the fixed code never did what the app has done."""
        rest = [x for _, x in self.parts[self.i:]]
        at = "%d of %d recorded actions not reached, the first %s %s" % (len(rest), self.total, rest[0].tag, rest[0].name)
        self.j.stop()
        if self.pays(rest):
            raise self.j.diverge("the phase ended on the replay with %s. In a funds phase what was paid must be "
                                 "accounted for: the lane stops." % at)
        self.j.log("the phase ended on the replay with %s" % at)

    def attr(self, tag, k, live):
        known = self.attrs.get(tag)
        return known[k] if known and k in known else live


class Journal:
    def __init__(self, hold, phase, entries=()):
        self.hold, self.phase = hold, phase
        self.entries, self.depth, self.replay, self.was, self.tail, self.searching = [], 0, None, None, {}, 0
        self.dead = None
        if any(e.kind == "act" for e in entries):
            self.replay = Replay(self, entries)
            _Clock.t, _Clock.m = entries[0].t, entries[0].m
            _Clock.replay = True
            self.all = list(entries)

    def log(self, s):
        self.hold.log(s)

    def stop(self):
        if self.replay is not None:
            self.replay = None
            _clock_end()

    def diverge(self, why):
        self.dead = self.hold.diverged(self.phase, why)
        return self.dead

    def ended(self):
        """The phase returned."""
        if self.dead is not None:
            raise self.dead
        if self.replay is not None:
            self.replay.unused()

    def unsure(self):
        """A send or cancel on the funder that raised: it may have gone all the same."""
        return next((e for e in self.entries if e.exc is not None and e.tag[0] == "f" and e.name in SPENDS), None)

    def failed(self):
        """A fault: when it came in the replay, the record stands whole for the next fix."""
        if self.replay is not None:
            self.was = self.all
        self.stop()

    def add(self, kind, tag, name, key, value, exc, t, m, attrs=None):
        if kind == "read":
            last = self.tail.get(key)
            if last is not None and exc is None and last.exc is None and last.value == value:
                last.n += 1  # a poll of a screen that did not change. Replay reads by key, so this loses no order
                return
        else:
            self.tail = {}
        e = Entry(kind, tag, name, key, value, exc, t, m, attrs, bool(self.searching) or name in MOVES)
        self.entries.append(e)
        if kind == "read":
            self.tail[key] = e

    def call(self, tag, name, fn, a, kw, target=None):
        if self.depth or threading.get_ident() != _MAIN:
            return fn(*a, **kw)
        if self.dead is not None:
            raise self.dead
        kind = "read" if name in READS.get(tag[0], ()) else "act"
        key = (tag, name) if name in UNKEYED else (tag, name, _norm(a), _norm(kw))
        if self.replay is not None:
            e = self.replay.read(key) if kind == "read" else self.replay.act(key, tag, name)
            if e is not None:
                self.add(kind, tag, name, key, e.value, e.exc, e.t, e.m, e.attrs)
                if e.exc is not None:
                    raise e.exc
                return _clone(e.value)
        self.depth += 1
        try:
            value = fn(*a, **kw)
        except Exception as ex:  # noqa: BLE001 — it was raised once, it is raised again in the replay
            self.add(kind, tag, name, key, None, ex, time.time(), time.monotonic())
            raise
        finally:
            self.depth -= 1
        self.add(kind, tag, name, key, value, None, time.time(), time.monotonic(), _atoms(target) if kind == "act" else None)
        return _clone(value)

    def value(self, name, fn):
        q = self.replay.values.get(name) if self.replay is not None else None
        if q:
            v = q.popleft().value
        else:
            v = fn()
        self.add("value", "v", name, name, v, None, time.time(), time.monotonic())
        return v

    def trimmed(self):
        """What a replay stands on: everything up to the last action that succeeded. A search for a
        missing control at the end of the record is the failed action itself: its scrolls and known
        troubles stay out, and the fixed code looks at the screen they left."""
        if self.was is not None:
            return self.was
        for i in range(len(self.entries) - 1, -1, -1):
            e = self.entries[i]
            if e.kind == "act" and e.exc is None and not e.search:
                return self.entries[:i + 1]
        return []


class Held:
    """A platform or the funder, its calls through the journal. What it holds passes through."""

    def __init__(self, target, tag):
        object.__setattr__(self, "_t", target)
        object.__setattr__(self, "_tag", tag)

    def __getattr__(self, k):
        target, tag = self._t, self._tag
        attr = getattr(target, k)
        if k.startswith("__") or k in PASS or isinstance(attr, type):
            return attr
        if not callable(attr):
            j = current
            return j.replay.attr(tag, k, attr) if j is not None and j.replay is not None else attr
        if k == "exchange":
            return functools.partial(self._exchange, attr)

        def call(*a, **kw):
            j = current
            return attr(*a, **kw) if j is None else j.call(tag, k, attr, a, kw, target)
        return call

    def __setattr__(self, k, v):
        setattr(self._t, k, v)

    @contextlib.contextmanager
    def _exchange(self, real, *a, **kw):
        """The funder's service is up in a replay: its exchange was the first run's."""
        j = current
        if j is not None and j.replay is not None:
            yield self
            return
        with real(*a, **kw):
            yield self


class Hold:
    def __init__(self, lane, limit, diverged, root):
        self.lane, self.limit, self.diverged, self.root = lane, limit, diverged, root
        self.log = lane.log
        self.off = False
        self.done = []

    def run(self, lane, name, fn):
        global current
        saved = _snapshot(lane)
        j = Journal(self, name)
        try:
            while True:
                current = j
                try:
                    out = fn()
                    j.ended()
                    return out
                except _Again:
                    pass
                except Exception as e:  # noqa: BLE001 — a bug in the harness is what a fix is for
                    j.failed()
                    if j.dead is not None:
                        raise j.dead
                    if not self.parkable(lane, e) or not self.park(lane, name, e, j):
                        raise
                j = self.again(lane, saved, j)
        finally:
            current = None
            _clock_reset()

    def again(self, lane, saved, j):
        bundles = getattr(lane, "bundles", 0)
        keep = j.trimmed()
        _restore(saved)
        if hasattr(lane, "bundles"):
            lane.bundles = bundles
        lane.details["continues"] = list(self.done)
        return Journal(self, j.phase, keep)

    def parkable(self, lane, e):
        if self.off or {c.__name__ for c in type(e).__mro__} & NEVER:
            return False
        if getattr(e, "fatal", False) or getattr(e, "kind", "harness") != "harness":
            return False
        sent = current.unsure() if current is not None else None
        if sent is not None:
            self.log("no park: the funder's %s raised (%s), and it may have gone: a replay could pay twice" % (sent.name, sent.exc))
            return False
        alive = getattr(lane.p, "alive", None)
        try:
            return not callable(alive) or bool(alive())
        except Exception as ex:  # noqa: BLE001 — what cannot say it is alive is not
            self.log("alive: %s" % ex)
            return False

    def path(self, name):
        return os.path.join(self.lane.out, name)

    def write(self, name, data):
        tmp = self.path(name + ".tmp")
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(data, f)
        os.replace(tmp, self.path(name))

    def asked(self):
        try:
            with open(self.path(CONTINUE), encoding="utf-8") as f:
                ask = json.load(f)
        except (OSError, ValueError):
            return None
        os.remove(self.path(CONTINUE))
        return ask

    def park(self, lane, name, e, j):
        """Waits for tools/rel continue. -> True to go on, False when the fault takes its normal way."""
        step = getattr(e, "step", None) or name
        what = str(getattr(e, "what", None) or "%s: %s" % (type(e).__name__, e))[:300]
        if hasattr(e, "line") and hasattr(lane, "_bundle"):
            try:
                lane._bundle(e)
            except Exception as ex:  # noqa: BLE001 — evidence, never the result
                self.log("fault bundle not written: %s" % ex)
        at = _real["time"]()
        n = len(self.done) + 1
        acts = sum(1 for x in j.trimmed() if x.kind == "act")
        self.write(PARKED, {"pid": os.getpid(), "step": step, "what": what, "phase": name, "at": at, "n": n,
                            "limit": self.limit, "acts": acts, "line": e.line() if hasattr(e, "line") else what})
        self.log("PARKED at %s (phase %s): %s" % (step, name, what))
        try:
            while True:
                ask = self.asked()
                if ask is not None:
                    go = self.answer(ask, step, what, name, at, n, acts)
                    if go is not None:
                        return go
                if not os.path.exists(self.path(PARKED)):
                    self.off = True
                    self.log("PARK over: a new attempt took this stage")
                    return False
                if _real["time"]() - at > self.limit:
                    self.off = True
                    self.log("PARK over: nobody continued %s within %d s" % (step, self.limit))
                    return False
                _real["sleep"](1)
        finally:
            with contextlib.suppress(OSError):
                os.remove(self.path(PARKED))

    def answer(self, ask, step, what, name, at, n, acts):
        """-> True go on, False stop, None stay parked."""
        token = ask.get("token")
        if ask.get("stop"):
            self.off = True
            self.write(ANSWER, {"token": token, "ok": True, "note": "the park ended"})
            self.log("PARK over: stopped by tools/rel continue --stop")
            return False
        try:
            modules = reload_drivers(self.root)
        except Exception as ex:  # noqa: BLE001 — a fix that does not load: the app is still there for the next one
            note = "%s: %s" % (type(ex).__name__, ex)
            self.write(ANSWER, {"token": token, "ok": False, "note": note})
            self.log("continue: the drivers do not load: %s" % note)
            return None
        rec = {"n": n, "step": step, "what": what, "phase": name, "driver": ask.get("driver"), "acts": acts,
               "parked_s": round(_real["time"]() - at, 1)}
        self.done.append(rec)
        with open(self.path(CONTINUES), "a", encoding="utf-8") as f:
            f.write(json.dumps(rec) + "\n")
        self.write(ANSWER, {"token": token, "ok": True, "modules": modules, "acts": acts, "step": step, "phase": name})
        self.log("CONTINUE at %s: %d modules reloaded, replaying %d actions of phase %s" % (step, modules, acts, name))
        return True


def install(lane, diverged):
    """Parks on for this lane, when tools/rel asked. Before the lane's first phase."""
    global _held
    try:
        limit = int(os.environ.get("REL_TRUST_PARK") or 0)
    except ValueError:
        limit = 0
    if limit <= 0 or getattr(lane, "probe", None) or _held is not None:
        return False
    lane.p = Held(lane.p, "p")
    if getattr(lane, "funder", None) is not None:
        lane.funder = Held(lane.funder, "f")
    for k, w in (getattr(lane, "w", None) or {}).items():
        w.p = Held(w.p, "p:" + k)
    _real.update(time=time.time, monotonic=time.monotonic, sleep=time.sleep)
    time.time, time.monotonic, time.sleep = _time, _monotonic, _sleep
    _held = Hold(lane, limit, diverged, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    return True


def join(w, key):
    """A wallet that came after install: its platform's calls go through the journal like the others'."""
    if _held is not None:
        w.p = Held(w.p, "p:" + key)


def uninstall():
    global _held, current
    _held = current = None
    _clock_reset()
    if _real:
        time.time, time.monotonic, time.sleep = _real["time"], _real["monotonic"], _real["sleep"]
        _real.clear()


def guard(lane, name, fn):
    """fn, under the journal when none is open yet."""
    h = _held
    if h is None or h.off or current is not None or threading.get_ident() != _MAIN:
        return fn
    return lambda: h.run(lane, name, fn)


def kept(lane, fault):
    """A fault the lane would keep and go past, inside an open phase: it parks all the same."""
    h, j = _held, current
    if h is None or j is None:
        return
    j.failed()
    if j.dead is not None:
        raise j.dead
    if h.parkable(lane, fault) and h.park(lane, j.phase, fault, j):
        raise _Again()


def call(tag, name, fn, a, kw):
    """One call on a surface."""
    j = current
    return fn(*a, **kw) if j is None else j.call(tag, name, fn, a, kw)


def value(name, fn):
    """A generated value (a password, a PIN) stays the same through a replay."""
    j = current
    return fn() if j is None or threading.get_ident() != _MAIN else j.value(name, fn)


@contextlib.contextmanager
def searching():
    """What the driver does to find a control that does not show: see Journal.trimmed."""
    j = current
    if j is None:
        yield
        return
    j.searching += 1
    try:
        yield
    finally:
        j.searching -= 1


def journaled(fn):
    """A Wallet method that touches the app beside the surface and the platform."""
    @functools.wraps(fn)
    def held(self, *a, **kw):
        j = current
        if j is None:
            return fn(self, *a, **kw)
        return j.call("w:%s" % getattr(self, "key", "?"), fn.__name__, lambda *x, **y: fn(self, *x, **y), a, kw)
    return held


def quiet():
    j = current
    return j is not None and j.replay is not None


def quieted(log):
    def say(s):
        if not quiet():
            log(s)
    return say


def reload_drivers(root=None):
    """The driver code new from disk, in this process: each module run again and merged into what is
    already there, so a class keeps its identity (`except HarnessFault`, live instances) and a function
    keeps its object (bound methods, `from x import f`). -> modules reloaded. Raises what stops a
    module loading, with nothing of that module changed."""
    root = os.path.realpath(root or os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    mods = []
    for name, m in list(sys.modules.items()):
        path = getattr(m, "__file__", None)
        if not path or not path.endswith(".py") or m is sys.modules.get(__name__):
            continue
        if os.path.realpath(path).startswith(root + os.sep):
            with open(path, encoding="utf-8") as f:
                mods.append((m, compile(f.read(), path, "exec")))
    moved = {}
    for m, code in reversed(mods):
        _reload(m, code, moved)
    for new, was in moved.items():
        bases = tuple(moved.get(b, b) for b in new.__bases__)
        if bases != was.__bases__:
            with contextlib.suppress(TypeError):
                was.__bases__ = bases
    for o in gc.get_objects():
        new = moved.get(type(o))
        if new is not None:
            with contextlib.suppress(TypeError):
                object.__setattr__(o, "__class__", new)
    return len(mods)


def _reload(m, code, moved):
    ns = m.__dict__
    old = dict(ns)
    main = m.__name__ == "__main__"
    if main:
        ns["__name__"] = "__hold__"  # its `if __name__ == "__main__"` stays shut
    try:
        exec(code, ns)
    except BaseException:
        ns.clear()
        ns.update(old)
        raise
    if main:
        ns["__name__"] = "__main__"
    for k, new in list(ns.items()):
        if isinstance(new, type) and new.__module__ == "__hold__":
            new.__module__ = "__main__"
        was = old.get(k)
        if new is was or was is None:
            continue
        if isinstance(new, type) and isinstance(was, type) and new.__module__ == was.__module__:
            ns[k] = moved.get(new) or _merge(was, new, moved)
        elif isinstance(new, types.FunctionType) and isinstance(was, types.FunctionType) and _swap(was, new):
            ns[k] = was


def _swap(old, new):
    """new's code into old, the object callers hold. -> False when old's closure cannot take it."""
    if hasattr(old, "__wrapped__") and hasattr(new, "__wrapped__"):
        _swap(old.__wrapped__, new.__wrapped__)
    fresh = new.__code__.co_freevars
    if len(fresh) != len(old.__code__.co_freevars) or any(n != "__class__" for n in fresh):
        return False
    old.__code__ = new.__code__
    old.__defaults__, old.__kwdefaults__, old.__doc__ = new.__defaults__, new.__kwdefaults__, new.__doc__
    d = dict(new.__dict__)
    if "__wrapped__" in d and "__wrapped__" in old.__dict__:
        d["__wrapped__"] = old.__wrapped__
    old.__dict__.clear()
    old.__dict__.update(d)
    return True


def _own(v, new, was):
    """Methods of the new class say super() of the old one, which stays."""
    for f in (getattr(v, a, None) for a in ("__func__", "fget", "fset", "fdel", "__wrapped__")):
        if f is not None:
            _own(f, new, was)
    if isinstance(v, types.FunctionType) and v.__closure__:
        for name, cell in zip(v.__code__.co_freevars, v.__closure__):
            if name == "__class__" and cell.cell_contents is new:
                cell.cell_contents = was


def _merge(was, new, moved):
    moved[new] = was
    have, names = vars(was), vars(new)
    for k, v in names.items():
        if k in ("__dict__", "__weakref__", "__slots__"):
            continue
        cur = have.get(k)
        _own(v, new, was)
        if isinstance(v, types.FunctionType) and isinstance(cur, types.FunctionType) and _swap(cur, v):
            continue
        if isinstance(v, type) and isinstance(cur, type) and v.__qualname__.startswith(new.__qualname__ + "."):
            _merge(cur, v, moved)
            continue
        with contextlib.suppress(AttributeError, TypeError):
            setattr(was, k, v)
    for k in list(have):
        if k not in names and isinstance(have[k], (types.FunctionType, staticmethod, classmethod, property)):
            delattr(was, k)
    return was
