# SPDX-License-Identifier: Apache-2.0
"""The Linux desktop app as a core Surface: AT-SPI through atspi_worker.py (a process of its own in
the sandbox's environment, every call under a time limit), keys and scrolling through xdotool, shots
with ImageMagick's import, all on the sandbox's own display.

What AT-SPI gives on Flutter's GTK embedder: names, roles, values and checked/selected states; most
buttons have a Tap action. Controls without one (some footer buttons, a check box) are reached the
way a keyboard user does: focus moved with Tab until that control has it, then Enter or Space.
Never coordinates, never the order of the tree. Text fields often have no name: their description
or the label the recipe gives them is matched instead (see core/targets.py).
"""
import json
import os
import re
import subprocess
import sys
import threading
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

import sandbox  # noqa: E402
from core.faults import HarnessGone  # noqa: E402
from core.surface import Node  # noqa: E402

ROLE = {
    "push button": "button", "button": "button", "combo box": "button", "split button": "button",
    "toggle button": "toggle", "switch": "toggle",
    "check box": "checkbox", "radio button": "checkbox", "check menu item": "checkbox",
    "text": "text_field", "entry": "text_field", "password text": "text_field", "spin button": "text_field",
    "page tab": "tab", "list item": "row", "table row": "row", "tree item": "row", "table cell": "row",
    "link": "link", "menu item": "menu_item", "dialog": "dialog", "alert": "dialog",
    "label": "text", "static": "text", "heading": "text", "paragraph": "text", "header": "text",
}
# Flutter reports a disabled button as sensitive without enabled: only enabled counts
STATE = {"showing": "showing", "visible": "showing", "enabled": "enabled",
         "focused": "focused", "checked": "checked", "selected": "selected", "editable": "editable"}
KEYS = {"escape": "Escape", "back": "Escape", "enter": "Return", "tab": "Tab", "shift_tab": "shift+Tab",
        "page_down": "Next", "page_up": "Prior", "space": "space", "ctrl_enter": "ctrl+Return", "end": "End"}
CALL_S = 45       # one AT-SPI call; Flutter's tree read takes a few seconds on a busy host
TAB_LIMIT = 60    # focus steps tried to reach a control with no action
DESTRUCTIVE = re.compile(r"(?i)delete|remove|forget|reset|erase|send")


class AtspiSurface:
    platform, family = "linux", "desktop"

    def __init__(self, sb, log=print):
        self.sb, self.log = os.path.abspath(sb), log
        self.proc = None
        self.lock = threading.Lock()

    # ---- the worker

    def _env(self):
        env = sandbox.read_env(self.sb)
        if not env.get("DISPLAY"):
            raise HarnessGone("ui", "the sandbox session has no display (env gone)")
        return env

    def _start(self):
        env = self._env()
        self.proc = subprocess.Popen([sys.executable, "-I", os.path.join(HERE, "atspi_worker.py")], env=env,
                                     stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                                     text=True, bufsize=1, start_new_session=True)

    def _stop(self):
        if self.proc and self.proc.poll() is None:
            self.proc.kill()
            try:
                self.proc.wait(5)
            except subprocess.TimeoutExpired:
                pass
        self.proc = None

    def display_alive(self):
        return sandbox._alive(sandbox._pid(self.sb, "xvfb")) and sandbox._alive(sandbox._pid(self.sb, "dbus"))

    def _call(self, req, timeout=CALL_S):
        """One request; a worker that hangs or dies is started again and asked once more. The display
        or dbus gone is HarnessGone (the lane rebuilds the sandbox)."""
        for attempt in range(2):
            if not self.display_alive():
                self._stop()
                raise HarnessGone("ui", "the sandbox's Xvfb or dbus is gone")
            with self.lock:
                if self.proc is None or self.proc.poll() is not None:
                    self._start()
                ans = [None]

                def rd():
                    try:
                        ans[0] = self.proc.stdout.readline()
                    except Exception:  # noqa: BLE001
                        ans[0] = None
                try:
                    self.proc.stdin.write(json.dumps(req) + "\n")
                    self.proc.stdin.flush()
                except (BrokenPipeError, OSError):
                    self._stop()
                    continue
                t = threading.Thread(target=rd, daemon=True)
                t.start()
                t.join(timeout)
                if t.is_alive() or not ans[0]:
                    self.log("AT-SPI %s: no answer in %d s; worker restarted (try %d)" % (req.get("op"), timeout, attempt + 1))
                    self._stop()
                    continue
                return json.loads(ans[0])
        if not self.display_alive():
            raise HarnessGone("ui", "the sandbox's Xvfb or dbus is gone")
        raise HarnessGone("ui", "AT-SPI stopped answering (%s twice in %d s)" % (req.get("op"), timeout))

    # ---- Surface

    def tree(self):
        r = self._call({"op": "tree"})
        if not r.get("ok"):
            raise RuntimeError(r.get("error") or "tree read failed")
        out = []
        for raw in r.get("nodes", []):
            st = {STATE[s] for s in raw["states"] if s in STATE}
            if "showing" not in st:
                continue
            role = ROLE.get(raw["role"])
            if role is None:
                role = "text" if raw["name"] and raw["role"] in ("panel", "section", "filler", "group", "image") else "other"
            if raw["role"] == "password text":
                st.add("password")
            if role == "text_field":
                st.add("editable")
            name = raw["name"] or (raw["desc"] if role == "text_field" else "")
            out.append(Node(i=len(out), role=role, name=name, id=raw.get("id"), value=raw.get("value"),
                            states=frozenset(st), actions=tuple(raw["actions"]), ref=raw))
        return out

    def _req(self, node, op, **kw):
        ref = node.ref
        return dict({"op": op, "path": ref["path"], "role": ref["role"], "name": ref["name"]}, **kw)

    def press(self, node):
        r = self._call(self._req(node, "press"))
        if r.get("ok"):
            return
        self.log("AT-SPI: %s has no action (%s); reaching it with the keyboard" % (node.brief(), r.get("how")))
        self._keyboard_press(node, "space" if node.role in ("checkbox", "toggle") else "enter")

    def _focused_is(self, node):
        ref = node.ref
        for n in self.tree():
            if "focused" in n.states and n.ref["role"] == ref["role"] and n.ref["name"] == ref["name"]:
                return True
        return False

    def _keyboard_press(self, node, key):
        if self._call(self._req(node, "focus")).get("ok") or self._focused_is(node):
            self.key(key)
            return
        if node.role in ("checkbox", "toggle") and not any("focused" in n.states and n.role != "other" for n in self.tree()):
            return self._toggle_walk(node, key)
        for step in range(TAB_LIMIT):
            self.key("tab")
            time.sleep(0.12)
            if self._focused_is(node):
                self.key(key)
                return
        raise RuntimeError("%s could not be reached with Tab in %d steps" % (node.brief(), TAB_LIMIT))

    def _toggle_walk(self, node, key):
        """A check box whose focus the build does not report (26.10.25's ECheckbox: a checked state,
        no action, no focus flag): Tab, Space, and read whether this box changed. A control the walk
        pressed instead is undone through AT-SPI (a dialog's Close, or the one button that replaced
        another, as Reveal replaces Hide); when the same detour comes back, focus was reset by it,
        so the next try Tabs one step further."""
        ref = node.ref
        mine = lambda t: next((n for n in t if n.ref["role"] == ref["role"] and n.ref["name"] == ref["name"]), None)
        state = lambda t: ("checked" in mine(t).states) if mine(t) else None
        live = lambda t: {(n.role, n.name) for n in t if n.role in ("button", "checkbox", "toggle", "text_field", "dialog")
                          and not (n.ref["role"] == ref["role"] and n.ref["name"] == ref["name"])}
        tree = self.tree()
        start, rest = state(tree), live(tree)
        seen, tabs = set(), 1
        for step in range(TAB_LIMIT // 2):
            for _ in range(tabs):
                self.key("tab")
                time.sleep(0.15)
            self.key(key)
            time.sleep(0.6)
            tree = self.tree()
            if state(tree) is not None and state(tree) != start:
                self.log("AT-SPI: %s reached with Tab (its focus is not reported; %d tries)" % (node.brief(), step + 1))
                return
            now = live(tree)
            if now == rest:
                tabs = 1
                continue
            sig = (frozenset(now - rest), frozenset(rest - now))
            tabs = tabs + 1 if sig in seen else 1
            seen.add(sig)
            self._undo(tree, rest)
        raise RuntimeError("%s did not change with Tab and %s" % (node.brief(), key))

    def _undo(self, tree, rest):
        new = [n for n in tree if n.role == "button" and (n.role, n.name) not in rest]
        close = [n for n in new if re.match(r"(?i)close|cancel|back|not now", n.name)]
        pick = close[:1] or (new if len(new) == 1 and not DESTRUCTIVE.search(new[0].name) else [])
        if pick and self._call(self._req(pick[0], "press")).get("ok"):
            self.log("AT-SPI: walk pressed something else; undone with %s" % pick[0].brief())
        else:
            self.key("escape")
        time.sleep(0.8)

    def set_text(self, node, text):
        """Focus, select all, type (the text on xdotool's stdin, never its command line). Flutter's
        GTK embedder takes EditableText.set_text_contents into the semantics value only, not the
        field: the form never sees it (26.10.25's create form said "Passwords differ"); it is
        the fallback for a field that will not take focus."""
        if self._call(self._req(node, "focus")).get("ok"):
            self._xdo("key", "ctrl+a")
            self._xdo("key", "BackSpace")
            self._xdo("type", "--delay", "12", "--file", "-", inp=text)
            return
        if not self._call(self._req(node, "set_text", text=text)).get("ok"):
            raise RuntimeError("%s took neither focus nor text" % node.brief())

    def key(self, name):
        self._xdo("key", KEYS.get(name, name))

    def scroll(self, direction="down"):
        r = self._xdo("search", "--onlyvisible", "--name", "Epic Cash|BT Wallet")
        wid = (r.stdout.split() or [None])[0]
        if wid:
            self._xdo("mousemove", "--window", wid, "700", "450")
        for _ in range(5):
            self._xdo("click", "5" if direction == "down" else "4")
            time.sleep(0.05)

    def screenshot(self, path):
        try:
            sandbox.shot(self.sb, path)
            return os.path.exists(path)
        except (Exception, SystemExit):  # noqa: BLE001
            return False

    def alive(self):
        return sandbox._alive(sandbox._pid(self.sb, "app"))

    def close(self):
        self._stop()

    def _xdo(self, *args, inp=None):
        if not self.display_alive():
            raise HarnessGone("ui", "the sandbox's Xvfb or dbus is gone")
        return subprocess.run(["xdotool", *args], input=inp, text=True, capture_output=True, timeout=20, env=self._env())
