# SPDX-License-Identifier: Apache-2.0
"""The Windows desktop app as a core Surface, over the rig agent (agent.ps1) in epicrig's session 0.

Reading: UI Automation's tree of the app's FLUTTERVIEW (roles, names, values, states, rects, and
the AutomationId the engine sets from a Semantics identifier as Node.id; builds before the app's ids
have none, and core/targets.py falls back to role + label).
Pressing: MSAA's default action on the node (UIA's own Invoke and SetFocus fail in a session without
a desktop); a node with none is clicked at the centre of its UIA rect, with a posted mouse message.
Both paths are logged. Typing: posted WM_CHAR after a click in the field; a secret goes to the rig as
a file, never on a command line or in a log. Keys: plain posted keys (posted Ctrl and Shift do not
count). No screenshots: PrintWindow returns one colour in this session, so screenshot() is False.

Never coordinates a person wrote down and never the order of the tree: a click uses the rect the
node has in the read just made, and a press re-reads when the node is not where it was.
"""
import dataclasses
import os
import re
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

from core import freeze  # noqa: E402
from core import targets as tg  # noqa: E402
from core.faults import HarnessFault, HarnessGone  # noqa: E402
from core.surface import Node  # noqa: E402

ROLE = {
    "Button": "button", "SplitButton": "button", "ComboBox": "button", "CheckBox": "checkbox", "RadioButton": "checkbox",
    "Edit": "text_field", "Text": "text", "Hyperlink": "link", "MenuItem": "menu_item", "TabItem": "tab",
    "ListItem": "row", "DataItem": "row", "TreeItem": "row", "Window": "dialog",
}
VK = {"escape": 0x1B, "back": 0x1B, "enter": 0x0D, "tab": 0x09, "page_down": 0x22, "page_up": 0x21, "space": 0x20,
      "end": 0x23, "ctrl_enter": 0x0D, "shift_tab": 0x09}
EYE = re.compile(r"(?i)^(show|hide)\b[^(]*\(")
ERASE_SECRET = 64   # a password field's text is not readable: this many backspaces clear it


def _once(text):
    """The engine names a button with a tooltip "Label. Label": the label once."""
    m = re.match(r"^(.+)\. \1$", text)
    return m.group(1) if m else text


class WinSurface:
    platform, family = "windows", "desktop"
    shows_selection = False   # UI Automation gives a Flutter segmented button no chosen state

    def __init__(self, rig, log=print, secret_dir=None, app_log=None):
        self.rig, self.log = rig, log
        self.app_log = app_log   # the app's wfe.log on the rig (windows_platform sets it: the run's data folder)
        self.offset = -1         # how much of it was read: the first read marks the end, so only this run's lines count
        self.pending = []
        self.secret_dir = secret_dir or os.environ.get("TMPDIR") or tempfile.gettempdir()
        self.last = []        # the nodes of the last read, UIA order, unfiltered
        self.last_press = None
        self.tree_nodes = []
        self.pressed = {}     # how presses went: {"msaa": n, "click": n}

    # ---- the agent

    def _call(self, op, timeout=120, **kw):
        r = self.rig.call(op, timeout=timeout, **kw)
        err = r.get("error") or ""
        if not r.get("ok") and ("agent did not take" in err or "did not answer in time" in err or err == "no answer"
                                or err.startswith("bad answer")):
            raise HarnessGone("ui", "the rig agent does not answer (%s)" % err[:120])
        return r

    # ---- a frozen app (core/freeze.py)

    def _health(self, **kw):
        """One agent call: does the app window answer a WM_NULL (within FREEZE_S), and the app log's problem
        lines since the last call. The log lines wait in self.pending for log_lines()."""
        extra = {"log": self.app_log, "offset": self.offset} if self.app_log else {}
        r = self._call("health", timeout=int(freeze.FREEZE_S) + 60, ms=int(freeze.FREEZE_S * 1000), **extra, **kw)
        if r.get("ok") and self.app_log and r.get("offset") is not None:
            self.offset = r["offset"]
            self.pending += r.get("lines") or []
        return r

    @staticmethod
    def _hung_text(r):
        return ("Windows counts the app window as hung (IsHungAppWindow)" if r.get("hung") == 1 else
                "the app window gave no answer to a WM_NULL in %d s (SendMessageTimeout)" % freeze.FREEZE_S)

    def froze(self):
        r = self._health()
        return self._hung_text(r) if r.get("ok") and r.get("app") and r.get("hung") else None

    def log_lines(self):
        if not self.pending:
            self._health()
        out, self.pending = self.pending, []
        return out

    def evidence(self):
        r = self._health(procs=True, tail=200)
        ev = {"processes.txt": "\n".join(r.get("procs") or []) + "\n"}
        if r.get("tail"):
            ev["app-log-tail.txt"] = r["tail"] + "\n"
        return ev

    # ---- reading

    def tree(self):
        r = self._call("uia_tree", timeout=120, wait_s=0, min=1, max=2500)
        if r.get("hung"):   # the agent asked the window first: a frozen app is not read for 30 s
            raise freeze.Frozen("ui", self._hung_text(r), evidence=self.evidence())
        if not r.get("ok"):
            if "no app window" in (r.get("error") or ""):
                return []
            raise HarnessFault("ui", "UI Automation read failed: %s" % (r.get("error") or "")[:200])
        self.last = r.get("nodes") or []
        nodes = [self._node(i, d) for i, d in enumerate(self.last)]
        # The engine marks no field as a password. A password field is the one with the show/hide eye button right after it.
        for i, n in enumerate(nodes[:-1]):
            nxt = nodes[i + 1]
            if n and nxt and n.role == "text_field" and EYE.match(nxt.name):
                n.states = n.states | {"password"}
        self._list_items(nodes)
        nodes = [n for n in nodes if n]
        self.tree_nodes = nodes
        self._trace(nodes)
        return nodes

    def _trace(self, nodes):
        """REL_TRUST_TREES=<file>: every read of a Settings page (the screens with the settings search field,
        never a secret screen) as one block of lines, to see how the engine exposes a page over time."""
        path = os.environ.get("REL_TRUST_TREES")
        if not path or not any(n.role == "text_field" and n.name.split("\n")[0] == tg.copy(None, "deskSetSearchHint") for n in nodes):
            return
        with open(path, "a") as f:
            f.write("---- %s\n%s\n" % (time.strftime("%H:%M:%S"), "\n".join(n.brief() for n in nodes)))

    @staticmethod
    def _list_items(nodes):
        """The engine can merge a list into one node: a button whose value is the chosen item, followed by the
        items as plain texts. The list is not a control, the items are rows (pressed by a click at their own rect, the merged node has
        no per-item action)."""
        live = [n for n in nodes if n]
        for k, n in enumerate(live):
            if n.role != "button" or not n.value or "editable" not in n.states:
                continue
            run = []
            for m in live[k + 1:]:
                if m.role != "text":
                    break
                run.append(m)
            if len(run) >= 2 and any(m.name == n.value for m in run):
                n.role = "other"   # the merged list is not a control of its own
                for m in run:
                    m.role = "row"
                    m.ref["click"] = True

    @staticmethod
    def _node(i, d):
        if d.get("off"):
            return None
        role = ROLE.get(d.get("ct"), "other")
        pat = d.get("pat") or []
        if "toggle" in pat and role in ("button", "other"):
            role = "toggle"
        elif "invoke" in pat and role in ("other", "text"):
            role = "button"
        name, val = "\n".join(_once(x) for x in (d.get("name") or "").split("\n")), d.get("val")
        if not name and val is None and not pat:
            return None   # the engine's unnamed layout nodes
        st = {"showing"}
        if d.get("en", True):
            st.add("enabled")
        if d.get("focus"):
            st.add("focused")
        if d.get("tog") == "On" or d.get("sel"):
            st.add("checked" if role in ("checkbox", "toggle") else "selected")
        if d.get("pw"):
            st.add("password")
        if "value" in pat:
            st.add("editable")
        acts = tuple(a for a, p in (("press", "invoke"), ("set_text", "value"), ("scroll", "scroll")) if p in pat)
        return Node(i=i, role=role, name=name, id=d.get("aid") or None, value=val, states=frozenset(st), actions=acts,
                    ref={"idx": i, "rid": d.get("rid"), "rect": d.get("rect") or [], "name": d.get("name") or ""})

    def _fresh(self, node):
        """The node as the app has it now: the same role and name, when the screen changed since the read."""
        for n in self.tree():
            if n.role == node.role and n.name == node.name:
                return n
        return None

    # ---- acting

    def _click(self, node):
        rect = node.ref["rect"]
        if len(rect) != 4 or rect[2] <= 0 or rect[3] <= 0:
            raise HarnessFault("ui", "%s has no area to click" % node.brief())
        self._call("click_rect", rect=rect)
        self.pressed["click"] = self.pressed.get("click", 0) + 1
        self.log("press by click at the node's centre: %s" % node.brief())

    def _in_view(self, node):
        """True when the node's centre is inside the app's view: the engine keeps nodes of a scrolled page
        that lie below the window in the tree (not off screen to UIA), and a click there reaches nothing."""
        view = next((d.get("rect") for d in self.last if len(d.get("rect") or []) == 4), None)
        rect = node.ref.get("rect") or []
        if not view or len(rect) != 4:
            return True
        x, y = rect[0] + rect[2] / 2, rect[1] + rect[3] / 2
        return view[0] <= x < view[0] + view[2] and view[1] <= y < view[1] + view[3]

    def press(self, node):
        # MSAA's default action is a no-op on a check box or switch, and a press the driver sees did nothing
        # and repeats is clicked instead; never a node outside the view, which only its default action reaches
        if node.ref.get("click"):
            return self._click(node)
        key = (node.role, node.name)
        again = self.last_press == (key, int(time.time() // 30))
        self.last_press = (key, int(time.time() // 30))
        seen = self._in_view(node)
        if seen and (node.role in ("checkbox", "toggle") or again):
            return self._click(node)
        for attempt in range(2):
            r = self._call("ui_at", idx=node.ref["idx"], name=node.ref["name"], what="press")
            if r.get("ok"):
                self.pressed["msaa"] = self.pressed.get("msaa", 0) + 1
                if not seen:
                    self.log("pressed %s by its default action: it lies outside the view" % node.brief())
                elif node.role in ("button", "row") and self._unchanged(node):
                    self.log("the default action changed nothing on %s; clicking" % node.brief())
                    self._click(node)
                return
            err = r.get("error") or ""
            if "different node" in err or "wanted #" in err:
                fresh = self._fresh(node) if attempt == 0 else None
                if fresh:
                    node = fresh
                    continue
                raise HarnessFault("ui", "%s is not on screen any more" % node.brief())
            self.log("MSAA press failed (%s); clicking" % err[:100])
            return self._click(node)
        raise HarnessFault("ui", "could not press %s" % node.brief())

    @staticmethod
    def _signature(nodes):
        return [(n.role, n.name, n.value, tuple(sorted(n.states))) for n in nodes]

    def _unchanged(self, node):
        """True when the screen reads the same just after a default action: some controls take none."""
        before, end = self._signature(self.tree_nodes), time.time() + 0.8
        while True:
            same = self._signature(self.tree()) == before
            if not same or time.time() >= end:
                return same
            time.sleep(0.1)

    def set_text(self, node, text, secret=False):
        """Click into the field (a field outside the view: its default action, which focuses it), clear
        what it holds, type. A password field's value is not readable, so it is cleared by a fixed run
        of backspaces. A secret (a password, a phrase word) or a long text goes to the rig as a file the
        agent deletes as soon as it has read it: never on the ssh command line, in a command file or in
        a log, and the field is named without its value."""
        secret = secret or "password" in node.states
        shown = dataclasses.replace(node, value=None) if secret else node
        if self._in_view(node):
            self._click(shown)
        else:
            r = self._call("ui_at", idx=node.ref["idx"], name=node.ref["name"], what="press")
            if not r.get("ok"):
                raise HarnessFault("ui", "could not reach %s outside the view: %s" % (shown.brief(), (r.get("error") or "")[:120]))
            self.log("focused %s by its default action: it lies outside the view" % shown.brief())
        time.sleep(0.3)
        n = ERASE_SECRET if "password" in node.states else len(node.value or "")
        if n:
            self._call("erase", timeout=60 + n, n=n)
        if secret or len(text) > 200:
            r = self._type_file(text)
        else:
            r = self._call("type", timeout=60 + len(text), text=text)
        if not r.get("ok"):
            raise HarnessFault("ui", "typing into %s failed: %s" % (shown.brief(), (r.get("error") or "")[:120]))

    def _type_file(self, text):
        """The text typed from a file in the run's secret folder, removed on the rig right after: by the
        agent once read (drop), else here by its exact path."""
        fd, path = tempfile.mkstemp(dir=self.secret_dir, prefix="typed-")
        try:
            os.fchmod(fd, 0o600)
            with os.fdopen(fd, "w") as f:
                f.write(text)
            remote = self.rig.put_secret(path, "typed")
        finally:
            os.unlink(path)
        r = {}
        try:
            r = self._call("type", timeout=60 + len(text), file=remote, drop=True)
        finally:
            if not r.get("dropped"):
                self.rig.pwsh("Remove-Item -LiteralPath '%s' -Force -ErrorAction SilentlyContinue" % remote, check=False)
        return r

    def key(self, name):
        vk = VK.get(name)
        if vk is None:
            raise HarnessFault("ui", "no key %r on Windows" % name)
        self._call("keys", vks=[vk], gap_ms=200)

    def scroll(self, direction="down"):
        self.key("page_down" if direction == "down" else "page_up")

    def screenshot(self, path):
        return False

    def alive(self):
        r = self._call("procs")
        if not r.get("ok"):
            raise HarnessFault("ui", "the rig agent could not list the app's processes: %s" % (r.get("error") or "")[:120])
        return any(p.split(" ")[0] in ("btwallet", "epic_wallet") for p in (r.get("procs") or []))

    def close(self):
        pass
