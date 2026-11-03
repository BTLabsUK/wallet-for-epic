# SPDX-License-Identifier: Apache-2.0
"""The app on an Android emulator as a core Surface (core/surface.py), read through uiautomator.

A read is one `uiautomator dump`: every node of the window on screen becomes a core Node. Flutter puts
a widget's Semantics label in content-desc (a field's text in text), its Semantics identifier in
resource-id, and its flags in checkable/checked/selected/password/enabled. Roles come from the node's
class and flags, never from where it sits. A press taps the node's own bounds centre; nothing here
knows a coordinate of its own.

When adb or the emulator is gone every call raises HarnessGone: the lane restarts the emulator
(android/platform.py, the app's data kept) and runs the phase again.
"""
import html
import os
import re
import subprocess
import time
import xml.etree.ElementTree as ET

import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from core.faults import HarnessGone  # noqa: E402
from core.surface import Node  # noqa: E402

ADB = os.environ.get("ADB", os.path.expanduser("~/Android/Sdk/platform-tools/adb"))
DUMP = "/sdcard/wfe-ui.xml"
# The status and navigation bars are not the app's; everything else showing is (the app, a system dialog over it).
NOT_APP = ("com.android.systemui",)
KEYS = {"back": 4, "escape": 111, "enter": 66, "tab": 61, "page_down": 93, "home": 3, "del": 67, "move_end": 123}
GONE = re.compile(r"device (?:'[^']*' )?not found|device offline|no devices/emulators found|device still connecting|"
                  r"cannot connect to daemon|unauthorized", re.I)


class Device:
    """adb on one emulator. Every call that finds the device gone raises HarnessGone."""

    def __init__(self, serial, adb=ADB):
        self.serial, self.adb = serial, adb

    def run(self, *args, timeout=60, text=True, check_gone=True):
        try:
            r = subprocess.run([self.adb, "-s", self.serial, *args], capture_output=True, timeout=timeout,
                               **({"text": True, "errors": "replace"} if text else {}))
        except subprocess.TimeoutExpired:
            if check_gone and not self.online():
                raise HarnessGone("adb", "emulator %s stopped answering" % self.serial)
            raise
        err = r.stderr if text else r.stderr.decode("utf-8", "replace")
        if check_gone and r.returncode != 0 and GONE.search(err or ""):
            raise HarnessGone("adb", "emulator %s gone: %s" % (self.serial, (err or "").strip()[:120]))
        return r

    def sh(self, cmd, timeout=60):
        return self.run("shell", cmd, timeout=timeout).stdout

    def online(self):
        try:
            r = subprocess.run([self.adb, "-s", self.serial, "get-state"], capture_output=True, text=True, timeout=15)
        except (subprocess.TimeoutExpired, OSError):
            return False
        return r.stdout.strip() == "device"


def _bounds(s):
    v = [int(x) for x in re.findall(r"-?\d+", s or "")]
    return tuple(v) if len(v) == 4 else None


def role_of(a):
    """The core role of a uiautomator node's attributes."""
    cls = a.get("class", "")
    name = a.get("content-desc") or a.get("text") or ""
    clickable = a.get("clickable") == "true" or a.get("long-clickable") == "true"
    if cls.endswith("EditText"):
        return "text_field"
    if re.search(r"\bTab \d+ of \d+\b", name):
        return "tab"
    if cls.endswith(("Switch", "ToggleButton")):
        return "toggle"
    if cls.endswith(("CheckBox", "RadioButton")) or a.get("checkable") == "true":
        return "checkbox"
    if cls.endswith("SeekBar"):
        return "other"
    if clickable or cls.endswith(("Button", "ImageButton")):
        return "button"
    if name:
        return "text"
    return "other"


def parse(xml_text, pkg=None):
    """Nodes of a uiautomator dump: each showing node with a name, an id, a value or an action. [pkg]
    given: the app's nodes and system dialogs over it (not the status or navigation bar)."""
    try:
        root = ET.fromstring(xml_text)
    except ET.ParseError:
        return []
    out = []
    for e in root.iter("node"):
        a = e.attrib
        if a.get("package") in NOT_APP:
            continue
        b = _bounds(a.get("bounds"))
        if not b or b[2] <= b[0] or b[3] <= b[1]:
            continue
        cls = a.get("class", "")
        field = cls.endswith("EditText")
        desc, text = html.unescape(a.get("content-desc") or ""), html.unescape(a.get("text") or "")
        rid = a.get("resource-id") or None
        role = role_of(a)
        # A field's accessible name is its label (content-desc or hint); its text is its value.
        name = (desc or html.unescape(a.get("hint") or "")) if field else (desc or text)
        value = text if field else None
        actions = tuple(x for x, on in (("press", a.get("clickable") == "true" or a.get("long-clickable") == "true" or field),
                                        ("set_text", field), ("scroll", a.get("scrollable") == "true")) if on)
        if not (name or rid or field or actions or a.get("checkable") == "true"):
            continue
        states = {"showing"}
        for k in ("enabled", "focused", "checked", "selected", "password"):
            if a.get(k) == "true":
                states.add(k)
        if field:
            states.add("editable")
        out.append(Node(i=len(out), role=role, name=name.replace("\r", ""), id=rid, value=value,
                        states=frozenset(states), actions=actions, ref={"bounds": b, "class": cls, "pkg": a.get("package")}))
    return _row_labels(out)


def _inside(inner, outer):
    return outer[0] <= inner[0] and outer[1] <= inner[1] and inner[2] <= outer[2] and inner[3] <= outer[3] and inner != outer


def _row_labels(nodes):
    """A switch or check box with no name of its own takes the first line of the labelled row it sits
    in (the smallest named node around it): Flutter labels the row, not the switch, so "Technical
    details" is the row and its switch, both. The row stays as it is."""
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


class Uia:
    """The running app on emulator [dev] (a Device) as a Surface."""
    platform = "android"
    family = "phone"

    def __init__(self, dev, pkg, log=print, chunk=10):
        self.dev, self.pkg, self.log, self.chunk = dev, pkg, log, chunk
        self._size = None

    # ---- reading

    def tree(self):
        x = ""
        for _ in range(4):
            r = self.dev.run("shell", "uiautomator dump %s >/dev/null 2>&1; cat %s; rm -f %s" % (DUMP, DUMP, DUMP), timeout=60)
            x = r.stdout
            if "<hierarchy" in x:
                break
            if not self.dev.online():
                raise HarnessGone("tree", "emulator %s gone" % self.dev.serial)
            time.sleep(0.5)  # uiautomator was busy (an animation, another dump): read again
        return parse(x[x.find("<?xml"):] if "<?xml" in x else x, self.pkg)

    # ---- acting

    def _tap(self, x, y):
        self.dev.run("shell", "input tap %d %d" % (x, y))

    def keyboard_shown(self):
        return "mInputShown=true" in self.dev.sh("dumpsys input_method | grep -m1 mInputShown")

    def hide_keyboard(self):
        """The soft keyboard covers what is under it and is not in the dump; Back with it up only closes it."""
        for _ in range(2):
            if not self.keyboard_shown():
                return
            self.dev.run("shell", "input keyevent 4")
            time.sleep(0.6)

    def _fresh(self, node):
        """The same control on a new read (after the keyboard went, the layout moved)."""
        for n in self.tree():
            if n.role == node.role and n.name == node.name and n.id == node.id:
                return n
        return node

    def press(self, node):
        if node.role != "text_field" and self.keyboard_shown():
            self.hide_keyboard()
            node = self._fresh(node)
        b = node.ref["bounds"]
        self._tap((b[0] + b[2]) // 2, (b[1] + b[3]) // 2)

    def _type(self, text, chunk):
        for i in range(0, len(text), chunk):
            part = text[i:i + chunk].replace("%", r"\%").replace(" ", "%s")
            self.dev.run("shell", "input text '%s'" % part.replace("'", "'\\''"))

    def _clear(self, node):
        self.dev.run("shell", "input keycombination 113 29")  # ctrl+a selects the field's text
        self.dev.run("shell", "input keyevent 67")
        v = node.value or ""
        if v:  # a field that ignores ctrl+a: delete from the end
            self.dev.run("shell", "input keyevent 123 " + " ".join(["67"] * (len(v) + 2)))

    def set_text(self, node, text):
        """Focus the field, clear it, type [text]. `input text` drops characters on a busy emulator:
        typed in chunks, read back (not a password field, whose text reads as dots) and typed again
        one character at a time if it did not take. The text is never logged."""
        b = node.ref["bounds"]
        self._tap((b[0] + b[2]) // 2, (b[1] + b[3]) // 2)
        time.sleep(0.3)
        self._clear(node)
        self._type(text, self.chunk)
        if "password" in node.states:
            return
        for chunk in (1,):
            got = self._fresh(node).value
            if got is None or got == text:
                return
            self._clear(self._fresh(node))
            self._type(text, chunk)

    def type_digits(self, digits):
        """A PIN pad's digits as key events (no field to set): KEYCODE_0..9."""
        self.dev.run("shell", "input keyevent " + " ".join(str(7 + int(c)) for c in digits))

    def key(self, name):
        self.dev.run("shell", "input keyevent %d" % KEYS[name])

    def size(self):
        if not self._size:
            m = re.search(r"(\d+)x(\d+)", self.dev.sh("wm size"))
            self._size = (int(m.group(1)), int(m.group(2))) if m else (1080, 2400)
        return self._size

    def scroll(self, direction="down"):
        w, h = self.size()
        y0, y1 = (int(h * 0.7), int(h * 0.3)) if direction == "down" else (int(h * 0.3), int(h * 0.7))
        self.dev.run("shell", "input swipe %d %d %d %d 350" % (w // 2, y0, w // 2, y1))

    def screenshot(self, path):
        r = self.dev.run("exec-out", "screencap", "-p", text=False, timeout=60)
        if r.returncode != 0 or not r.stdout.startswith(b"\x89PNG"):
            return False
        with open(path, "wb") as f:
            f.write(r.stdout)
        return True

    def foreground(self):
        """The app in front again (Back on its first screen leaves it, as for a user)."""
        self.dev.run("shell", "monkey -p %s -c android.intent.category.LAUNCHER 1" % self.pkg, timeout=60)

    def in_front(self):
        out = self.dev.sh("dumpsys window | grep -m1 -E 'mCurrentFocus|mFocusedApp'")
        return self.pkg in out

    def alive(self):
        if not self.dev.online():
            raise HarnessGone("alive", "emulator %s gone" % self.dev.serial)
        return bool(self.dev.sh("pidof %s" % self.pkg).strip())
