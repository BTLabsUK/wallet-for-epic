#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Read and drive the Epic Cash Desktop app in a sandbox (sandbox.py) over AT-SPI, xdotool as a
fallback. A module for trust.py and a small CLI for looking at a screen by hand:

    TRUST_SB=<sandbox> python3 -I ui.py tree | text | fields
    TRUST_SB=<sandbox> python3 -I ui.py click "<name>" [--role R] [--nth N]   ("re:<regex>" for a regex)
    TRUST_SB=<sandbox> python3 -I ui.py key <xdotool key> ...

Facts of the Flutter build (26.10.7 to 26.10.24): names, values, [checked]/[selected] states and
read-only field values are readable; most buttons have a Tap action; footer buttons and the
"written down" check box have none (xdotool on coordinates then); Component.get_extents blocks the
app for about 15 s and returns nothing, so it is never called; text fields have no names, so
fields are found by their order on the screen. Refuses to run unless DISPLAY and HOME are the
sandbox's.
"""
import os
import re
import subprocess
import sys
import time
import warnings

warnings.filterwarnings("ignore")  # PyGObject deprecation noise from Atspi.Text & co

SB = os.path.abspath(os.environ.get("TRUST_SB", "") or ".")
APP_NAMES = ("uk.btlabs.epiccash.desktop", "com.blacktyger.epicwallet", "epic_wallet")

try:
    for _l in open(os.path.join(SB, "env")):
        _k, _v = _l.rstrip("\n").split("=", 1)
        os.environ[_k] = _v
except FileNotFoundError:
    sys.exit("no sandbox session in %s (TRUST_SB, sandbox.py start)" % SB)
_m = re.fullmatch(r":(\d+)", os.environ.get("DISPLAY", ""))
if not _m or int(_m.group(1)) < 100 or not os.environ.get("HOME", "").startswith(SB + os.sep):
    sys.exit("refusing: DISPLAY=%r HOME=%r are not the sandbox's" % (os.environ.get("DISPLAY"), os.environ.get("HOME")))

import gi  # noqa: E402

gi.require_version("Atspi", "2.0")
from gi.repository import Atspi  # noqa: E402

ST = Atspi.StateType
STATES = {}
for _n in ("showing", "visible", "enabled", "sensitive", "focused", "editable", "checked", "selected",
           "read-only", "busy", "modal"):
    try:
        STATES[_n] = getattr(ST, _n.upper().replace("-", "_"))
    except AttributeError:
        pass
KEEP = {"focused", "editable", "checked", "selected", "read-only", "busy", "modal"}


def find_app():
    desk = Atspi.get_desktop(0)
    for i in range(desk.get_child_count()):
        a = desk.get_child_at_index(i)
        if a is not None and (a.get_name() or "") in APP_NAMES:
            return a
    return None


class Node:
    __slots__ = ("acc", "role", "name", "states", "actions", "value")

    def __init__(self, acc):
        self.acc = acc
        self.role = acc.get_role_name()
        self.name = acc.get_name() or ""
        ss = acc.get_state_set()
        self.states = {n for n, t in STATES.items() if ss.contains(t)}
        self.actions = []
        try:
            ai = acc.get_action_iface()
            if ai:
                self.actions = [ai.get_action_name(i) for i in range(ai.get_n_actions())]
        except Exception:
            pass
        self.value = None
        if "password" not in self.role:
            try:
                if acc.get_text_iface():
                    self.value = Atspi.Text.get_text(acc, 0, Atspi.Text.get_character_count(acc))
            except Exception:
                pass
        if self.value == self.name:
            self.value = None

    @property
    def showing(self):
        return "showing" in self.states or "visible" in self.states

    def __str__(self):
        s = "%s %r" % (self.role, self.name)
        st = sorted(self.states & KEEP)
        if st:
            s += " [%s]" % ",".join(st)
        if self.actions:
            s += " {%s}" % ",".join(self.actions)
        if self.value:
            s += " =%r" % self.value
        return s


def walk(acc=None, depth=0):
    if acc is None:
        acc = find_app()
        if acc is None:
            return
    try:
        n = Node(acc)
    except Exception:
        return
    yield n
    if depth >= 60:
        return
    try:
        cnt = acc.get_child_count()
    except Exception:
        return
    for i in range(cnt):
        c = None
        for _ in range(3):
            try:
                c = acc.get_child_at_index(i)
            except Exception:
                c = None
            if c is not None:
                break
            time.sleep(0.2)
        if c is not None:
            yield from walk(c, depth + 1)


def nodes():
    """The showing nodes of the app, in tree order."""
    return [n for n in walk() if n.showing]


def matcher(pattern):
    if hasattr(pattern, "search"):
        return lambda name: bool(pattern.search(name))
    if isinstance(pattern, str) and pattern.startswith("re:"):
        rx = re.compile(pattern[3:], re.S)
        return lambda name: bool(rx.search(name))
    return lambda name: name == pattern or pattern in name.split("\n") or name.strip() == pattern


def find(pattern, role=None, all_nodes=None):
    m = matcher(pattern)
    out = []
    for n in all_nodes if all_nodes is not None else nodes():
        if not n.name:
            continue
        if role and n.role != role:
            continue
        if m(n.name):
            out.append(n)
    # elements that do something first, then their label panels
    out.sort(key=lambda n: 0 if (n.actions or "editable" in n.states) else 1)
    return out


def has(pattern, role=None):
    return bool(find(pattern, role))


def texts():
    """Every showing name and field value, one string each."""
    out = []
    for n in nodes():
        if n.name and n.role not in ("frame", "application"):
            out.append(n.name)
        if n.value and "editable" in n.states:
            out.append(n.value)
    return out


def xdo(*args, inp=None):
    return subprocess.run(["xdotool", *args], input=inp, text=True, capture_output=True, timeout=20)


def xclick(x, y):
    xdo("mousemove", str(x), str(y))
    time.sleep(0.1)
    xdo("click", "1")


def key(*names):
    for k in names:
        xdo("key", k)
        time.sleep(0.15)


def tap(n):
    """The node's (or a near ancestor's) Tap action; else Focus and Return. False if neither."""
    acc = n.acc
    for _ in range(4):
        try:
            ai = acc.get_action_iface()
            if ai and ai.get_n_actions():
                names = [ai.get_action_name(i) for i in range(ai.get_n_actions())]
                for want in ("Tap", "click", "Press"):
                    if want in names and ai.do_action(names.index(want)):
                        return True
                if "Focus" in names:
                    ai.do_action(names.index("Focus"))
                    time.sleep(0.25)
                    xdo("key", "Return")
                    return True
        except Exception:
            pass
        acc = acc.get_parent()
        if acc is None:
            break
    return False


def click(pattern, role=None, nth=0, timeout=20.0):
    """Wait for a showing node whose name matches and activate it. Raises when there is none."""
    end = time.time() + timeout
    while True:
        found = [n for n in find(pattern, role) if n.actions]
        if found:
            if tap(found[min(nth, len(found) - 1)]):
                return found[min(nth, len(found) - 1)].name
        if time.time() > end:
            raise LookupError("nothing to press for %r" % (pattern,))
        time.sleep(0.5)


def wait(pattern, timeout=30.0, gone=False, role=None):
    end = time.time() + timeout
    while True:
        found = find(pattern, role)
        if bool(found) != gone:
            return found
        if time.time() > end:
            raise TimeoutError("%s %r" % ("still showing" if gone else "never showed", pattern))
        time.sleep(0.5)


def wait_any(patterns, timeout=30.0):
    """The first of [patterns] to show (its index)."""
    end = time.time() + timeout
    while True:
        all_n = nodes()
        for i, p in enumerate(patterns):
            if find(p, all_nodes=all_n):
                return i
        if time.time() > end:
            raise TimeoutError("none of %r showed" % (patterns,))
        time.sleep(0.5)


def fields():
    """Showing editable fields in tree order (they have no names: the label is a sibling)."""
    return [n for n in nodes() if "editable" in n.states]


def focus(n):
    for _ in range(3):
        try:
            ai = n.acc.get_action_iface()
            names = [ai.get_action_name(i) for i in range(ai.get_n_actions())]
            ai.do_action(names.index("Tap") if "Tap" in names else names.index("Focus"))
        except Exception:
            pass
        time.sleep(0.3)
        try:
            if "focused" in Node(n.acc).states:
                return True
        except Exception:
            pass
    return False


def fill(idx, text):
    """Put [text] into the idx-th showing field (replacing what is there). The text is never logged."""
    fl = fields()
    if idx >= len(fl):
        raise LookupError("no field #%d (%d showing)" % (idx, len(fl)))
    n = fl[idx]
    focus(n)
    try:
        et = n.acc.get_editable_text_iface()
        if et:
            et.set_text_contents(text)
            if "password" in n.role:
                time.sleep(0.2)
                return
            for _ in range(10):
                time.sleep(0.15)
                if (Node(n.acc).value or "") == text:
                    return
    except Exception:
        pass
    xdo("key", "ctrl+a")
    xdo("key", "BackSpace")
    xdo("type", "--delay", "12", "--file", "-", inp=text)
    time.sleep(0.3)


def window():
    """(x, y, w, h) of the app's window on the sandbox display."""
    r = xdo("search", "--onlyvisible", "--name", "Epic Cash")
    for wid in r.stdout.split():
        g = xdo("getwindowgeometry", "--shell", wid).stdout
        d = dict(l.split("=", 1) for l in g.split() if "=" in l)
        if int(d.get("WIDTH", 0)) > 400:
            return int(d["X"]), int(d["Y"]), int(d["WIDTH"]), int(d["HEIGHT"])
    raise LookupError("no app window")


def scroll(direction="down", n=5, at=None):
    x, y, w, h = window()
    cx, cy = at or (x + w * 2 // 3, y + h // 2)
    xdo("mousemove", str(cx), str(cy))
    for _ in range(n):
        xdo("click", "5" if direction == "down" else "4")
        time.sleep(0.05)


def screenshot(path):
    subprocess.run(["import", "-window", "root", path], check=True, timeout=30, capture_output=True)
    return path


def checkbox_squares(png, box):
    """Empty check-box outlines (rounded squares 14-30 px, light border, dark inside) in [box] of
    [png]: their centres, top to bottom. For the check box that has no AT-SPI action."""
    from PIL import Image
    im = Image.open(png).convert("L")
    x0, y0, x1, y1 = box
    px = im.load()
    out = []
    for y in range(y0, y1 - 30):
        x = x0
        while x < x1:
            if px[x, y] < 60:
                x += 1
                continue
            a = x
            while x < x1 and px[x, y] >= 60:
                x += 1
            b = x - 1
            if not 10 <= b - a + 1 <= 26:
                continue
            for s in range(b - a + 1, b - a + 9):
                mid, cx = y + s // 2, (a + b) // 2
                if y + s >= y1 or px[cx, y + s] < 60 or px[cx, y + 1 + s // 4] >= 50 or px[cx, mid] >= 50:
                    continue
                left = any(px[xl, mid] >= 60 for xl in range(max(a - 5, 0), a))
                right = any(px[xr, mid] >= 60 for xr in range(b + 1, b + 6))
                if left and right:
                    c = (cx, mid)
                    if not any(abs(c[0] - o[0]) < 8 and abs(c[1] - o[1]) < 8 for o in out):
                        out.append(c)
                    break
    return sorted(out, key=lambda c: c[1])


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    c, a = argv[1], argv[2:]
    role = a[a.index("--role") + 1] if "--role" in a else None
    nth = int(a[a.index("--nth") + 1]) if "--nth" in a else 0
    if c == "tree":
        for n in nodes():
            if n.name or n.actions or n.value or "editable" in n.states:
                print(n)
    elif c == "text":
        for t in texts():
            print(t.replace("\n", " | "))
    elif c == "fields":
        for i, n in enumerate(fields()):
            print(i, n.role, ",".join(sorted(n.states & KEEP)), "" if "password" in n.role else (n.value or ""))
    elif c == "click":
        print("pressed %r" % click(a[0], role, nth))
    elif c == "key":
        key(*a)
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
