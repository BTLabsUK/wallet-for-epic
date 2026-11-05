# SPDX-License-Identifier: Apache-2.0
"""The app on the iOS Simulator as a core Surface (core/surface.py), read and driven through WebDriverAgent
(appium/WebDriverAgent, an XCUITest runner on the Simulator that answers HTTP) with no Appium server.

A read is one `GET /source?format=json`: XCUITest's snapshot of the app's accessibility tree. Flutter puts a
widget's Semantics identifier in accessibilityIdentifier (WDA's rawIdentifier), its label in label, a
field's text in value and its flags in the accessibility traits (Selected, Button, ...); a Switch is
XCUIElementTypeSwitch with value 1 or 0. Roles come from the element type and traits, never from where it
sits. A press taps the node's own frame centre (points); nothing here knows a coordinate of its own. Text
goes in through WDA's /wda/keys into the focused field: the text is in an HTTP body over the ssh tunnel,
never on a command line.

When WebDriverAgent stops answering every call raises HarnessGone: the lane starts it again
(ios_platform.recover, the app's data kept) and runs the phase again.
"""
import base64
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from core.faults import HarnessGone  # noqa: E402
from core.surface import Node  # noqa: E402

FIELDS = ("TextField", "SecureTextField", "SearchField", "TextView")
# The attributes the lane does not read: WDA works out visibility and accessibility per element, slow on a
# large tree; frames are given as rect already.
EXCLUDED = "visible,accessible,frame,nativeFrame,nativeAccessibilityElement,minValue,maxValue"
BACK_NAMES = ("Back", "Close", "Dismiss")   # Flutter's back button, a sheet's Close; its modal barrier on iOS (no Back key)


class WdaError(RuntimeError):
    pass


class Wda:
    """WebDriverAgent's HTTP API at [base] (the tunnel's end on this host), one session on the active app."""

    def __init__(self, base, timeout=90):
        self.base, self.timeout = base.rstrip("/"), timeout
        self.sid = None

    def call(self, method, path, body=None, timeout=None):
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(self.base + path, data=data, method=method,
                                     headers={"Content-Type": "application/json"} if data else {})
        try:
            with urllib.request.urlopen(req, timeout=timeout or self.timeout) as r:
                out = json.loads(r.read().decode("utf-8", "replace") or "{}")
        except urllib.error.HTTPError as e:
            try:
                out = json.loads(e.read().decode("utf-8", "replace") or "{}")
            except ValueError:
                raise WdaError("WDA %s %s: HTTP %d" % (method, path.split("?")[0], e.code))
        except (urllib.error.URLError, ConnectionError, TimeoutError, OSError) as e:
            raise HarnessGone("wda", "WebDriverAgent does not answer (%s %s: %s)" % (method, path.split("?")[0], e))
        v = out.get("value") if isinstance(out, dict) else None
        if isinstance(v, dict) and v.get("error"):
            if v["error"] == "invalid session id":
                self.sid = None
            raise WdaError("WDA %s %s: %s: %s" % (method, path.split("?")[0], v["error"], str(v.get("message", ""))[:200]))
        return v

    def up(self):
        try:
            v = self.call("GET", "/status", timeout=10)
        except (HarnessGone, WdaError):
            return False
        return bool(isinstance(v, dict) and v.get("ready", True))

    def session(self):
        """A session on whatever app is in front (no bundleId: the lane launches the app with simctl)."""
        if self.sid is None:
            caps = {"shouldWaitForQuiescence": False, "waitForIdleTimeout": 0, "maxTypingFrequency": 30,
                    "shouldUseTestManagerForVisibilityDetection": False}
            req = {"capabilities": {"alwaysMatch": caps}}
            data = json.dumps(req).encode()
            r = urllib.request.Request(self.base + "/session", data=data, method="POST",
                                       headers={"Content-Type": "application/json"})
            try:
                with urllib.request.urlopen(r, timeout=self.timeout) as f:
                    out = json.loads(f.read().decode("utf-8", "replace"))
            except (urllib.error.URLError, ConnectionError, TimeoutError, OSError) as e:
                raise HarnessGone("wda", "WebDriverAgent does not answer (POST /session: %s)" % e)
            self.sid = out.get("sessionId") or (out.get("value") or {}).get("sessionId")
            if not self.sid:
                raise WdaError("WDA gave no session: %s" % str(out)[:200])
            self.call("POST", "/session/%s/appium/settings" % self.sid,
                      {"settings": {"snapshotMaxDepth": 100, "animationCoolOffTimeout": 0}})
        return self.sid

    def s(self, method, path, body=None, timeout=None):
        """A call in the session; a session WDA lost (it restarted) is made again once."""
        for attempt in range(2):
            sid = self.session()
            try:
                return self.call(method, "/session/%s%s" % (sid, path), body, timeout)
            except WdaError:
                if self.sid is None and attempt == 0:
                    continue
                raise

    def source(self):
        return self.s("GET", "/source?format=json&excluded_attributes=" + EXCLUDED, timeout=120)

    def tap(self, x, y):
        self.s("POST", "/wda/tap", {"x": x, "y": y})

    def keys(self, text):
        self.s("POST", "/wda/keys", {"value": list(text)}, timeout=60 + len(text))

    def swipe(self, x0, y0, x1, y1, ms=300):
        """A finger down, moved over [ms], up: W3C actions (a press-and-drag would be a long press first)."""
        acts = [{"type": "pointer", "id": "finger", "parameters": {"pointerType": "touch"}, "actions": [
            {"type": "pointerMove", "duration": 0, "x": int(x0), "y": int(y0)},
            {"type": "pointerDown", "button": 0},
            {"type": "pointerMove", "duration": ms, "x": int(x1), "y": int(y1)},
            {"type": "pointerUp", "button": 0}]}]
        self.s("POST", "/actions", {"actions": acts})

    def size(self):
        v = self.s("GET", "/window/size")
        return int(v["width"]), int(v["height"])

    def active_bundle(self):
        v = self.call("GET", "/wda/activeAppInfo")
        return (v or {}).get("bundleId")

    def activate(self, bundle):
        self.s("POST", "/wda/apps/activate", {"bundleId": bundle})

    def home(self):
        self.call("POST", "/wda/homescreen")

    def screenshot(self):
        v = self.call("GET", "/screenshot", timeout=60)
        return base64.b64decode(v) if isinstance(v, str) else None

    def dismiss_keyboard(self, names):
        self.s("POST", "/wda/keyboard/dismiss", {"keyNames": list(names)})


# ---- the tree

def _type(e):
    t = e.get("type") or ""
    return t[len("XCUIElementType"):] if t.startswith("XCUIElementType") else t


def _traits(e):
    return {t.strip() for t in str(e.get("traits") or "").split(",") if t.strip()}


def _rect(e):
    r = e.get("rect") or {}
    try:
        x, y, w, h = (int(round(float(r[k]))) for k in ("x", "y", "width", "height"))
    except (KeyError, TypeError, ValueError):
        return None
    return (x, y, x + w, y + h)


def _yes(v):
    return str(v).strip().lower() in ("1", "true", "yes")


def role_of(e):
    """The core role of a WDA element."""
    t, tr = _type(e), _traits(e)
    name = e.get("label") or ""
    if t in FIELDS:
        return "text_field"
    if re.search(r"\bTab \d+ of \d+\b", name):
        return "tab"
    if t == "Switch":
        return "toggle"
    if t in ("CheckBox", "RadioButton") or "ToggleButton" in tr:
        return "checkbox"
    if t in ("Slider", "Keyboard", "Key"):
        return "other"
    if t == "Link" or "Link" in tr:
        return "link"
    if t in ("Button", "Cell", "MenuItem") or "Button" in tr:
        return "button"
    if t in ("StaticText", "Image", "Header") or "StaticText" in tr or "Header" in tr:
        return "text" if name else "other"
    if name:   # Flutter's tappable rows (InkWell, ListTile): an Other with a label and no text trait
        return "button"
    return "other"


def walk(root):
    """Every element of a WDA JSON source with no Keyboard below it, and the keyboard's frame (or None)."""
    out, kb = [], None
    stack = [root] if isinstance(root, dict) else []
    while stack:
        e = stack.pop(0)
        t = _type(e)
        if t == "Keyboard":
            kb = _rect(e)
            continue
        out.append(e)
        stack[0:0] = [c for c in (e.get("children") or []) if isinstance(c, dict)]
    return out, kb


def _untooltip(label):
    """Flutter on iOS reads a node's label and its tooltip as one, joined by a newline: a segment
    whose tooltip repeats its text reads "Epicbox\nEpicbox". The repeat is dropped, as AT-SPI keeps
    the tooltip apart."""
    lines = label.split("\n")
    return "\n".join(x for i, x in enumerate(lines) if i == 0 or x != lines[i - 1])


def parse(src):
    """Nodes of a WDA JSON source (the `value` of GET /source?format=json): each element on screen with a
    name, an id, a value or an action. The keyboard is left out (its frame: keyboard_frame(src))."""
    elems, _kb = walk(src)
    screen = _rect(src) if isinstance(src, dict) else None
    out = []
    for e in elems:
        t = _type(e)
        if t in ("Application", "Window"):
            continue
        b = _rect(e)
        if not b or b[2] <= b[0] or b[3] <= b[1]:
            continue
        if screen and (b[3] <= screen[1] or b[1] >= screen[3] or b[2] <= screen[0] or b[0] >= screen[2]):
            continue   # scrolled off the screen (Flutter keeps the cache extent's nodes in the tree)
        field = t in FIELDS
        role = role_of(e)
        label = _untooltip((e.get("label") or "").replace("\r", ""))
        rid = e.get("rawIdentifier") or None
        raw = e.get("value")
        value = None
        if field:
            value = "" if raw is None or raw == e.get("placeholderValue") else str(raw)
            name = label or (e.get("placeholderValue") or "")
        else:
            name = label
            # a Semantics value (the confirmations count): its own field, as AT-SPI reads it; a switch's 1/0 is its state
            if raw not in (None, "") and role not in ("toggle", "checkbox") and str(raw) != label:
                value = str(raw)
        tr = _traits(e)
        actions = tuple(x for x, on in (("press", role in ("button", "link", "tab", "toggle", "checkbox") or field),
                                        ("set_text", field), ("scroll", t in ("ScrollView", "Table", "CollectionView")))
                        if on)
        if not (name or rid or field or actions):
            continue
        states = {"showing"}
        if _yes(e.get("isEnabled", "1")) and "NotEnabled" not in tr:
            states.add("enabled")
        if _yes(e.get("isFocused")):
            states.add("focused")
        if "Selected" in tr or _yes(e.get("isSelected")):
            states.add("selected")
        if role == "toggle" and _yes(raw):
            states.add("checked")
        if role == "checkbox" and (_yes(raw) or "Selected" in tr):
            states.add("checked")
        if t == "SecureTextField":
            states.add("password")
        if field:
            states.add("editable")
        out.append(Node(i=len(out), role=role, name=name, id=rid, value=value, states=frozenset(states),
                        actions=actions, ref={"bounds": b, "type": t, "multiline": t == "TextView"}))
    return row_labels(out)


def keyboard_frame(src):
    return walk(src)[1]


def _inside(inner, outer):
    return outer[0] <= inner[0] and outer[1] <= inner[1] and inner[2] <= outer[2] and inner[3] <= outer[3] and inner != outer


def row_labels(nodes):
    """A switch or check box with no name of its own takes the first line of the labelled row it sits in
    (the smallest named node around it), as android/uia.py's _row_labels: Flutter labels the row."""
    out = []
    for n in nodes:
        if n.role in ("toggle", "checkbox") and not n.name:
            rows = [r for r in nodes if r.name and r.role in ("button", "text", "row") and _inside(n.ref["bounds"], r.ref["bounds"])]
            if rows:
                r = min(rows, key=lambda r: (r.ref["bounds"][2] - r.ref["bounds"][0]) * (r.ref["bounds"][3] - r.ref["bounds"][1]))
                n = Node(i=n.i, role=n.role, name=r.name.split("\n", 1)[0], id=n.id, value=n.value, states=n.states,
                         actions=n.actions, ref=dict(n.ref, label_from=r.i))
        out.append(n)
    return out


class WdaSurface:
    """The running app [bundle] on the Simulator, through [wda] (a Wda) and [sim] (ios_platform.Sim: the
    process and the app's console log on the Mac)."""
    platform = "ios"
    family = "phone"

    def __init__(self, wda, sim, bundle, log=print):
        self.wda, self.sim, self.bundle, self.log = wda, sim, bundle, log
        self._size = None
        self.kb = None   # the keyboard's frame on the last read

    # ---- a frozen app (core/freeze.py)

    def froze(self):
        """iOS has no ANR record to read; a UI that does not answer shows as reads that time out."""
        return None

    def log_lines(self):
        """The app's console lines since the last call (simctl launch --stdout/--stderr): a Dart
        "Unhandled Exception", a "Stack Overflow"."""
        return [ln for ln in self.sim.console_new() if re.search(r"tack ?[Oo]verflow|nhandled [Ee]xception", ln)]

    def evidence(self):
        try:
            return {"console.txt": self.sim.console_tail()}
        except Exception as e:  # noqa: BLE001 — evidence only
            return {"evidence-error.txt": str(e)}

    # ---- reading

    def tree(self):
        last = None
        for _ in range(3):
            try:
                src = self.wda.source()
                break
            except WdaError as e:   # a snapshot taken mid-change: read again
                last = e
                time.sleep(0.5)
        else:
            raise last
        self.kb = keyboard_frame(src)
        if not self.sim.running():
            return []
        return parse(src) if isinstance(src, dict) else []

    # ---- acting

    def keyboard_shown(self):
        return self.kb is not None

    def hide_keyboard(self):
        """The soft keyboard covers what is under it. A Done key where the keyboard has one; else Return
        in a one-line field (Flutter's default action there ends the editing); a multi-line field keeps it."""
        if self.kb is None:
            self.tree()
        if self.kb is None:
            return
        try:
            self.wda.dismiss_keyboard(["Done", "done", "Hide keyboard"])
        except WdaError:
            pass
        nodes = self.tree()
        if self.kb is None:
            return
        f = next((n for n in nodes if n.role == "text_field" and "focused" in n.states), None)
        if f is not None and not f.ref.get("multiline"):
            self.wda.keys("\n")
            time.sleep(0.6)
            self.tree()

    def _fresh(self, node):
        for n in self.tree():
            if n.role == node.role and n.name == node.name and n.id == node.id:
                return n
        return node

    def _covered(self, node):
        b = node.ref["bounds"]
        return self.kb is not None and (b[1] + b[3]) // 2 >= self.kb[1]

    def press(self, node):
        if node.role != "text_field" and self._covered(node):
            self.hide_keyboard()
            node = self._fresh(node)
        b = node.ref["bounds"]
        self.wda.tap((b[0] + b[2]) // 2, (b[1] + b[3]) // 2)

    def _clear(self, node, n):
        """Delete [n] characters back from the end of the field (the cursor goes to its end first)."""
        if n <= 0:
            return
        b = node.ref["bounds"]
        self.wda.tap(max(b[0] + 1, b[2] - 6), (b[1] + b[3]) // 2)
        time.sleep(0.2)
        self.wda.keys("\b" * (n + 2))

    def set_text(self, node, text, secret=False):
        """Focus the field, clear it, type [text], read it back (not a password field, whose text reads as
        dots) and type it again once if it did not take. The text is never logged; it goes to WDA in an
        HTTP body only."""
        b = node.ref["bounds"]
        self.wda.tap((b[0] + b[2]) // 2, (b[1] + b[3]) // 2)
        time.sleep(0.4)
        self._clear(node, len(node.value or ""))
        self.wda.keys(text)
        if "password" in node.states:
            return
        got = self._fresh(node).value
        if got is None or got == text:
            return
        n = self._fresh(node)
        self._clear(n, len(n.value or "") + len(text))
        self.wda.keys(text)

    def type_digits(self, digits):
        self.wda.keys(digits)

    def key(self, name):
        if name == "back":
            return self._back()
        if name == "home":
            return self.wda.home()
        if name == "enter":
            return self.wda.keys("\n")
        if name == "del":
            return self.wda.keys("\b")
        if name == "page_down":
            return self.scroll("down")
        if name == "tab":
            return self.wda.keys("\t")
        # escape, move_end: no key on a phone; nothing to do

    def _back(self):
        """A phone with no Back key: the page's own Back button, a sheet's or dialog's barrier, else the
        system's back swipe from the left edge."""
        nodes = self.tree()
        for want in BACK_NAMES:
            n = next((n for n in nodes if n.name.split("\n")[0] == want and n.role in ("button", "text", "other")), None)
            if n is not None:
                b = n.ref["bounds"]
                # the barrier spans the screen under the sheet: its top, above a tall sheet, not its middle
                y = b[1] + min(80, (b[3] - b[1]) // 6) if want == "Dismiss" else (b[1] + b[3]) // 2
                self.wda.tap((b[0] + b[2]) // 2, y)
                return
        w, h = self.size()
        self.wda.swipe(1, h // 2, int(w * 0.7), h // 2, 250)

    def size(self):
        if not self._size:
            self._size = self.wda.size()
        return self._size

    def scroll(self, direction="down"):
        w, h = self.size()
        y0, y1 = (int(h * 0.7), int(h * 0.3)) if direction == "down" else (int(h * 0.3), int(h * 0.7))
        self.wda.swipe(w // 2, y0, w // 2, y1, 350)

    def screenshot(self, path):
        try:
            png = self.wda.screenshot()
        except (WdaError, HarnessGone):
            png = self.sim.screenshot()
        if not png or not png.startswith(b"\x89PNG"):
            return False
        with open(path, "wb") as f:
            f.write(png)
        return True

    def foreground(self):
        self.wda.activate(self.bundle)

    def in_front(self):
        return self.wda.active_bundle() == self.bundle

    def alive(self):
        return self.sim.running()

