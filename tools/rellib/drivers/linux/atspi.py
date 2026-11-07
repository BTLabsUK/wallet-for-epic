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
import dataclasses
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
from core import freeze  # noqa: E402
from core.faults import HarnessFault, HarnessGone  # noqa: E402
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
ENABLE_WAIT_S = 45  # a control with no action is read again this long: a disabled button (a form still
                    # working out its fee) has neither action nor focus until it is enabled; Send's fee
                    # estimate over Tor held Review for more than 10 s (26.11.4 run-2)
SECRET_FOCUS_S = 8  # a secret field that does not take focus at once is asked again this long (never set_text)
DESTRUCTIVE = re.compile(r"(?i)delete|remove|forget|reset|erase|wipe|replace|restore|unlink|clear|send|pay")


# The app's id: on Linux it comes in the label (lib/src/trust_ids.dart, WFE_TRUST_IDS), as AT-SPI has no
# field for it. Merged nodes hold several, the first is the node's, as `identifier` is on other systems.
MARK = re.compile("\u27e6([^\u27e7]+)\u27e7\\n?")


def _marked(name):
    """A node's name -> (its id or None, the name without the marks)."""
    ids = MARK.findall(name or "")
    return (ids[0] if ids else None), MARK.sub("", name or "").strip()


class AtspiSurface:
    platform, family = "linux", "desktop"

    def __init__(self, sb, log=print):
        self.sb, self.log = os.path.abspath(sb), log
        self.proc = None
        self.lock = threading.Lock()
        # the app's own log, this run's lines only (marked here: the sandbox may hold an earlier run's)
        self.seen_pid = None   # the app process that last answered a ping: gone from the bus after that is a freeze
        self.cursor = freeze.LogCursor(self._read_log)
        self.cursor.mark()

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

    def _call(self, req, timeout=CALL_S, once=False):
        """One request; a worker that hangs or dies is started again and asked once more. The display
        or dbus gone is HarnessGone (the lane rebuilds the sandbox). `once`: no second try, None when
        the worker gave no answer (froze() asks the app a question and wants that no-answer)."""
        if req.get("op") != "ping_app":
            # asked first (a fifth of a second): a call to a frozen app blocks for CALL_S, longer than a short
            # freeze lasts, and the app may freeze between two calls a moment apart
            why = self.froze()
            if why:
                raise freeze.Frozen("ui", why, evidence=self.evidence())
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
                    if once:
                        return None
                    continue
                return json.loads(ans[0])
        if not self.display_alive():
            raise HarnessGone("ui", "the sandbox's Xvfb or dbus is gone")
        # the display is up: a rebuild would kill an app that may be busy (a first-start migration)
        raise HarnessFault("ui", "AT-SPI stopped answering (%s twice in %d s)" % (req.get("op"), timeout))

    # ---- frozen app (core/freeze.py)

    def froze(self):
        """None, or the evidence: the app's own thread answers no AT-SPI question in FREEZE_S while the
        display, the bus and the app's process are all up. Flutter 3.47 on Linux runs the Dart UI isolate
        on the platform (GTK) thread, so a stuck Dart isolate (a StackOverflowError recursion) stops
        these answers too; a stopped process does the same. The preflight in _call asks first, so a
        freeze shorter than a tree read is still seen."""
        if not self.display_alive() or not self.alive():
            return None   # gone, not frozen: the callers' HarnessGone / app-quit paths decide
        warm = self.proc is not None and self.proc.poll() is None
        end, err = time.monotonic() + freeze.FREEZE_S, None
        while True:
            r = self._call({"op": "ping_app"}, timeout=freeze.FREEZE_S + (0 if warm else 4), once=True)
            pid = sandbox._pid(self.sb, "app")
            if r is not None and r.get("ok") and r.get("app"):
                self.seen_pid = pid
                return None
            if r is not None and r.get("ok") and (self.seen_pid is None or self.seen_pid != pid):
                return None   # not on the bus yet: this process has not answered once
            # no answer, or an error answer (a stopped app's bus call fails fast): an app still starting
            # may fail one ping, so only an app failing for FREEZE_S is frozen
            err = (r or {}).get("error") or ("the app is gone from the accessibility bus" if r and r.get("ok") else None)
            if r is None or time.monotonic() >= end:
                break
            time.sleep(0.5)
        if not self.display_alive() or not self.alive():
            return None
        return "no AT-SPI answer from the app in %d s%s (its process %s, display and bus up)" % (
            freeze.FREEZE_S, " (%s)" % err[:120] if err else "", self._state() or "state unknown")

    def _state(self):
        pid = sandbox._pid(self.sb, "app")
        try:
            with open("/proc/%d/stat" % pid) as f:
                st = f.read().rsplit(")", 1)[1].split()[0]
        except (OSError, TypeError, IndexError):
            return None
        return {"T": "stopped", "t": "stopped (traced)", "R": "running", "S": "sleeping", "D": "in disk wait",
                "Z": "a zombie"}.get(st, st)

    def _log_path(self):
        return os.path.join(self.sb, "home", ".epic_cash_desktop", "logs", "wfe.log")

    def _read_log(self):
        try:
            with open(self._log_path(), encoding="utf-8", errors="replace") as f:
                return f.read()
        except OSError:
            return None

    def log_lines(self):
        return self.cursor.new()

    def evidence(self):
        """For the fault bundle: the process and its threads (no tree read: a frozen app does not answer),
        and the app log's tail."""
        out = {"app-log-tail.txt": freeze.tail(self._log_path())}
        pid = sandbox._pid(self.sb, "app")
        try:
            r = subprocess.run(["ps", "-L", "-o", "tid,stat,wchan:24,comm", "-p", str(int(pid))], capture_output=True,
                               text=True, timeout=10)
            out["threads.txt"] = r.stdout[:20000]
        except (OSError, subprocess.SubprocessError, TypeError, ValueError):
            pass
        return out

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
            tid, name = _marked(name)
            out.append(Node(i=len(out), role=role, name=name, id=raw.get("id") or tid, value=raw.get("value"),
                            states=frozenset(st), actions=tuple(raw["actions"]), ref=raw))
        return out

    def _req(self, node, op, **kw):
        ref = node.ref
        return dict({"op": op, "path": ref["path"], "role": ref["role"], "name": ref["name"]}, **kw)

    def press(self, node):
        r = self._call(self._req(node, "press"))
        if r.get("ok"):
            return
        if r.get("how") == "gone":  # it left the screen since the read: the step's check decides
            self.log("AT-SPI: %s is gone from the screen; not pressed" % node.brief())
            return
        if self._press_once_enabled(node):
            return
        self.log("AT-SPI: %s has no action (%s); reaching it with the keyboard" % (node.brief(), r.get("how")))
        self._keyboard_press(node, "space" if node.role in ("checkbox", "toggle") else "enter")

    def _press_once_enabled(self, node):
        """True when the control, read again, turned enabled within ENABLE_WAIT_S and took the press."""
        ref = node.ref
        end = time.monotonic() + ENABLE_WAIT_S
        while time.monotonic() < end:
            time.sleep(0.5)
            n = next((x for x in self.tree() if x.ref["role"] == ref["role"] and x.ref["name"] == ref["name"]), None)
            if n is None or "enabled" not in n.states:
                continue
            if self._call(self._req(n, "press")).get("ok"):
                if "enabled" not in node.states:
                    self.log("AT-SPI: %s pressed once it was enabled" % n.brief())
                return True
            return False
        return False

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
        # grab_focus may well land though the box never reports it: Space once, and read the box
        self._call(self._req(node, "focus"))
        self.key(key)
        time.sleep(0.6)
        tree = self.tree()
        if state(tree) is not None and state(tree) != start:
            self.log("AT-SPI: %s toggled after grab_focus (its focus is not reported)" % node.brief())
            return
        if live(tree) != rest:
            self._undo(tree, rest)
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

    def _focus(self, node, wait=0):
        """Focus through AT-SPI, asked again for up to `wait` s: a field on a screen still coming in
        takes it a moment later (26.11.0 run-3 linux-tor: Word 1 of the restore grid, 7 s after start)."""
        end = time.time() + wait
        while True:
            if self._call(self._req(node, "focus")).get("ok") or self._focused_is(node):
                return True
            if time.time() >= end:
                return False
            time.sleep(0.5)

    def set_text(self, node, text, secret=False):
        """Focus, select all, type (the text on xdotool's stdin, never its command line). Flutter's
        GTK embedder takes EditableText.set_text_contents into the semantics value only, not the
        field: the form never sees it (26.10.25's create form said "Passwords differ"); it is
        the fallback for a field that will not take focus, never for a secret. A secret is typed
        slower (xdotool drops keys at speed and a phrase word is checked letter for letter) and its
        field is named without its value in any line."""
        if self._focus(node, SECRET_FOCUS_S if secret else 0):
            if node.value != "":   # an empty field is left as it is: Backspace there moves a phrase grid back a field
                self._xdo("key", "ctrl+a")
                self._xdo("key", "BackSpace")
            self._xdo("type", "--delay", "90" if secret else "12", "--file", "-", inp=text)
            return
        if secret:
            raise RuntimeError("%s took no focus (a secret is only typed)" % dataclasses.replace(node, value=None).brief())
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
