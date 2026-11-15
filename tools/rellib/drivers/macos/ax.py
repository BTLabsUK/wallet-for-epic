# SPDX-License-Identifier: Apache-2.0
"""The macOS desktop app as a core Surface, over the lane's AX helper (axhelper.swift) on the Mac.

The helper runs in a terminal pane in the user's GUI session and answers one JSON request per call; this
host reaches it with `wfe-axhelper call <socket>` over ssh (ios/mac.py), the request on stdin, so a typed
secret is never on a command line or in a log.

Reading: the app's windows through AXUIElement (Flutter builds its tree once an assistive client sets
AXEnhancedUserInterface). The helper sends raw attributes; parse() maps them onto the core's roles. A
Flutter Semantics node on macOS has its label as both AXTitle and AXDescription and its text as AXValue
(a plain text node: AXStaticText with the text in its value). The window's own chrome (close, zoom,
minimise, the title text) is not the app's UI and is left out. No AXIdentifier: core/targets.py goes by
role and label (Labels.for_build(which, ids=False)).
Pressing: AXPress on the node, found again by its path and checked to be the same node (role, title,
value, description); a node that moved is looked for again by role and name. Typing: the field is
pressed (Flutter focuses it), its text selected (Cmd+A) and deleted, the text posted to the app as
key events; when the field does not read the text back, its AXValue is set instead (never for a password).
Keys and scrolling: key events posted to the app's process. No screenshots: the helper has no Screen
Recording permission and the lane does not ask for one; the proof keeps the AX tree instead (Driver.shot
writes the tree when screenshot() is False).

The system dialog guard: every read (at most every DIALOG_S) lists the on-screen windows' owners. A
window of a watched owner (the keychain, Gatekeeper, a privacy prompt) that came up during the run
stops the app at once, is cancelled when its text names this lane's app or keychain (never Allow), and
fails the lane with SystemDialog. One already on screen when the lane starts is never touched: the lane
refuses to start.
"""
import json
import shlex
import os
import re
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

from core import freeze  # noqa: E402
from core.faults import HarnessFault, HarnessGone  # noqa: E402
from core.surface import Node  # noqa: E402

ROLE = {
    "AXButton": "button", "AXPopUpButton": "button", "AXMenuButton": "button", "AXCheckBox": "checkbox",
    "AXRadioButton": "checkbox", "AXTextField": "text_field", "AXTextArea": "text_field", "AXSearchField": "text_field",
    "AXSecureTextField": "text_field", "AXComboBox": "text_field", "AXStaticText": "text", "AXLink": "link",
    "AXMenuItem": "menu_item", "AXRow": "row", "AXCell": "row", "AXSheet": "dialog", "AXTabGroup": "other",
}
CHROME = {"AXCloseButton", "AXFullScreenButton", "AXMinimizeButton", "AXZoomButton"}
KEYS = {"escape", "back", "enter", "tab", "shift_tab", "page_down", "page_up", "space", "end", "home", "ctrl_enter",
        "shift", "select_all", "delete", "quit"}
EYE = re.compile(r"(?i)^(show|hide)\b")
WORDS = (12, 15, 18, 21, 24)   # the phrase lengths a restore grid can hold
SEP = "\x01"
q = shlex.quote

# The owners of the system's own dialogs: the keychain (SecurityAgent), Gatekeeper and "downloaded from the
# Internet" (CoreServicesUIAgent), a privacy prompt (UserNotificationCenter, universalAccessAuthWarn, tccd's).
WATCHED = ("SecurityAgent", "CoreServicesUIAgent", "UserNotificationCenter", "universalAccessAuthWarn", "coreautha")
# The buttons the guard may press on such a dialog: a refusal, never a grant. OK only on Gatekeeper's notice.
CANCEL = ("Cancel", "Deny", "Don’t Allow", "Don't Allow")
CANCEL_NOTICE = ("Cancel", "Done", "OK")
DIALOG_S = 5.0


class SystemDialog(HarnessFault):
    """A system dialog (keychain, Gatekeeper, privacy) came up on the user's screen during the run."""
    fatal = True


def watched(windows):
    """The on-screen windows ({owner, pid, layer, bounds}) that are system dialogs the lane guards against."""
    return [w for w in windows if any(str(w.get("owner") or "").startswith(o) for o in WATCHED)]


def node_key(d):
    """What the helper compares to know a path still holds the node the driver read."""
    return SEP.join(str(d.get(k) or "") for k in ("role", "title", "value", "desc"))


def _name(d, role):
    if d.get("role") == "AXStaticText":
        return d.get("value") or d.get("title") or d.get("desc") or ""
    return d.get("title") or d.get("desc") or d.get("placeholder") or ""


def _node(i, d, view):
    """One raw helper node as a core Node, or None when it is not part of the app's own UI."""
    path, role_ax, sub = d.get("path") or [], d.get("role") or "", d.get("sub") or ""
    if len(path) <= 1 or sub in CHROME:
        return None   # the window itself, its close / zoom / minimise buttons
    if len(path) == 2 and role_ax == "AXStaticText":
        return None   # the window's title
    acts = d.get("actions") or []
    role = ROLE.get(role_ax)
    if role == "checkbox" and sub == "AXSwitch":
        role = "toggle"
    elif role_ax == "AXRadioButton" and sub == "AXTabButton":
        role = "tab"
    elif role_ax == "AXGroup" and sub == "AXLandmarkBanner":
        role = "text"   # a heading
    elif role is None:
        role = "button" if "AXPress" in acts else "other"
    name = _name(d, role)
    value = d.get("value")
    if role in ("button", "toggle", "checkbox", "tab", "other", "row", "menu_item", "link") and value == "":
        value = None
    if role == "text":
        value = None
    if not name and value is None and role in ("other", "text"):
        return None   # Flutter's nameless layout groups
    st = {"enabled"} if d.get("enabled", True) else set()
    fr, inside = d.get("frame") or [], True
    if view and len(fr) == 4:
        cx, cy = fr[0] + fr[2] / 2, fr[1] + min(fr[3], 2) / 2
        inside = view[0] <= cx < view[0] + view[2] and view[1] <= cy < view[1] + view[3]
    if inside:
        st.add("showing")
    if d.get("focused"):
        st.add("focused")
    if role in ("checkbox", "toggle") and d.get("value") == "1":
        st.add("checked")
    if d.get("selected") or (role == "tab" and d.get("value") == "1"):
        st.add("selected")
    if role == "text_field":
        st.add("editable")
        if role_ax == "AXSecureTextField" or sub == "AXSecureTextField":
            st.add("password")
    a = tuple(x for x, have in (("press", "AXPress" in acts or role == "text_field"),
                                ("set_text", role == "text_field"), ("scroll", "AXScrollToVisible" in acts)) if have)
    return Node(i=i, role=role, name=name, value=value, states=frozenset(st), actions=a,
                ref={"path": path, "key": node_key(d), "frame": fr})


def parse(nodes):
    """The helper's raw nodes (a `tree` answer) as core Nodes: chrome and layout groups out, a password
    field marked (the AX role, or the show/hide eye button right after an unmarked field)."""
    view = next((d.get("frame") for d in nodes if len(d.get("path") or []) == 1 and len(d.get("frame") or []) == 4), None)
    out = [n for n in (_node(i, d, view) for i, d in enumerate(nodes)) if n]
    for k, n in enumerate(out[:-1]):
        nxt = out[k + 1]
        if n.role == "text_field" and nxt.role == "button" and EYE.match(nxt.name):
            n.states = n.states | {"password"}
    _name_words(out)
    return out


def _name_words(out):
    """The phrase grid's fields carry no name in macOS AX (26.11.3: no title, description, placeholder,
    help or identifier, nor a labelled group around them), where AT-SPI reads "Word N". A run of 12 to 24
    unnamed plain text fields side by side in the tree is that grid: each is named "Word N" by its place
    on screen, row by row (the app's own label, deskOnbWordN)."""
    run = []
    for n in out + [None]:
        if n is not None and n.role == "text_field" and not n.name and "password" not in n.states:
            run.append(n)
            continue
        if len(run) in WORDS:
            spot = lambda f: (round((f.ref.get("frame") or [0, 0])[1]), (f.ref.get("frame") or [0, 0])[0])
            for k, f in enumerate(sorted(run, key=spot), 1):
                f.name = "Word %d" % k
        run = []


class MacSurface:
    platform, family = "macos", "desktop"
    shows_selection = True

    def __init__(self, mac, helper, sock, pid, *, log=print, app_log=None):
        self.mac, self.helper, self.sock, self.pid = mac, helper, sock, int(pid)
        self.log, self.app_log = log, app_log
        self.offset = -1            # how much of the app log was read; the first read marks its end
        self.raw = []
        self.tree_nodes = []
        self.hung = False
        self.base = None            # the watched owners on screen when the lane started (never touched)
        self.dialog_at = 0.0
        self.pressed = {}

    # ---- the helper

    def call(self, op, timeout=120, **kw):
        req = dict(kw, op=op)
        if op not in ("ping", "windows"):
            req.setdefault("pid", self.pid)
        r = self.mac.run("%s call %s" % (self.helper, self.sock), timeout=timeout, inp=json.dumps(req) + "\n")
        try:
            ans = json.loads(r.stdout or "")
        except ValueError:
            raise HarnessGone("ui", "the AX helper gave no answer (exit %d): %s" % (r.returncode, (r.stderr or "")[-160:]))
        if ans.get("down"):
            raise HarnessGone("ui", "the AX helper is not running on the Mac")
        if ans.get("trusted") is False:
            raise HarnessFault("ui", "the AX helper has no Accessibility permission")
        return ans

    # ---- the system dialog guard

    def windows(self):
        r = self.call("windows", timeout=60)
        if not r.get("ok"):
            raise HarnessFault("ui", "the window list could not be read: %s" % (r.get("error") or "")[:120])
        return r.get("windows") or []

    def guard_start(self):
        """At the app's start: the watched dialogs already on screen. One there refuses the start (it is
        not this lane's, and the lane does not touch it)."""
        have = watched(self.windows())
        if have:
            raise SystemDialog("start", "a system dialog is on the screen before the app starts (%s): not touched; "
                               "the run does not start" % ", ".join(sorted({str(w.get('owner')) for w in have})))
        self.base = set()
        self.dialog_at = time.time()

    def guard(self, force=False):
        """A system dialog that came up during the run: the app stopped, the dialog cancelled when it is the
        lane's own, SystemDialog raised either way."""
        if self.base is None or (not force and time.time() - self.dialog_at < DIALOG_S):
            return
        self.dialog_at = time.time()
        new = watched(self.windows())
        if not new:
            return
        owners = sorted({str(w.get("owner")) for w in new})
        self.log("SYSTEM DIALOG on screen (%s): stopping the app" % ", ".join(owners))
        if self.pid > 0:
            self.mac.run("kill -TERM %d 2>/dev/null; true" % self.pid, timeout=30)
        notes = []
        for w in new:
            notes.append(self._cancel(w))
        time.sleep(1.0)
        left = watched(self.windows())
        what = "a system dialog came up on the user's screen (%s); the app was stopped. %s. %s" % (
            ", ".join(owners), "; ".join(notes), "It is gone." if not left else
            "STILL ON SCREEN: %s." % ", ".join(sorted({str(w.get('owner')) for w in left})))
        self.log(what)
        raise SystemDialog("system-dialog", what)

    def _cancel(self, w):
        """Press the refusal on dialog window [w] when its text names this lane's app or keychain."""
        owner, pid = str(w.get("owner")), int(w.get("pid") or 0)
        try:
            r = self.call("tree", timeout=60, pid=pid)
        except HarnessFault as e:
            return "%s not read (%s)" % (owner, e)
        nodes = r.get("nodes") or []
        text = " ".join(str(d.get(k) or "") for d in nodes for k in ("title", "desc", "value"))
        self.log("dialog %s reads: %s" % (owner, re.sub(r"\s+", " ", text)[:400]))
        if not re.search(r"lane\.keychain|BT Wallet|btwallet", text, re.I):
            return "%s does not name this lane's app or keychain: left alone" % owner
        allowed = CANCEL_NOTICE if owner.startswith("CoreServicesUIAgent") else CANCEL
        for d in nodes:
            if d.get("role") == "AXButton" and (d.get("title") or "") in allowed:
                p = self.call("press", timeout=60, pid=pid, path=d.get("path"), key=node_key(d))
                return "%s: pressed %s (%s)" % (owner, d.get("title"), "done" if p.get("ok") else p.get("error"))
        return "%s has no %s button: left alone" % (owner, "/".join(allowed))

    # ---- reading

    def tree(self):
        self.guard()
        r = self.call("tree", timeout=120)
        if not r.get("ok"):
            raise HarnessFault("ui", "the AX read failed: %s" % (r.get("error") or "")[:200])
        self.hung = bool(r.get("hung"))
        if self.hung:
            raise freeze.Frozen("ui", "the app's accessibility calls time out (kAXErrorCannotComplete)",
                                evidence=self.evidence())
        self.raw = r.get("nodes") or []
        self.tree_nodes = parse(self.raw)
        return self.tree_nodes

    def froze(self):
        return "the app's accessibility calls time out (kAXErrorCannotComplete)" if self.hung else None

    def _log_read(self, tail=0):
        """The app log's new bytes since the last read (and its size); the first read only marks the end."""
        if not self.app_log:
            return []
        f = self.app_log
        cmd = ("f=%s; [ -f \"$f\" ] || { echo 0; exit 0; }; s=$(stat -f %%z \"$f\"); echo $s; o=%d; "
               "[ $o -ge 0 ] && [ $o -le $s ] && tail -c +$((o+1)) \"$f\" | head -c 4000000; true") % (
                   q(f), self.offset if self.offset >= 0 else -1)
        if tail:
            cmd = "f=%s; [ -f \"$f\" ] && tail -n %d \"$f\"; true" % (q(f), tail)
            return self.mac.sh(cmd, timeout=60).splitlines()
        out = self.mac.sh(cmd, timeout=60)
        head, _, body = out.partition("\n")
        try:
            size = int(head.strip() or "0")
        except ValueError:
            return []
        first, self.offset = self.offset < 0, size
        return [] if first else body.splitlines()

    def log_lines(self):
        self.guard()
        return self._log_read()

    def evidence(self):
        ev = {}
        try:
            ev["processes.txt"] = self.mac.sh("ps -o pid,stat,%%cpu,rss,command -p %d; true" % self.pid, timeout=30)
            lines = self._log_read(tail=200)
            if lines:
                ev["app-log-tail.txt"] = "\n".join(lines) + "\n"
        except Exception as e:  # noqa: BLE001 — evidence only
            ev["evidence-error.txt"] = str(e)
        return ev

    # ---- acting

    def _fresh(self, node):
        for n in self.tree():
            if n.role == node.role and n.name == node.name:
                return n
        return None

    def _at(self, op, node, **kw):
        """[op] on the node at its path; a node that is not there any more is found again once by role and name."""
        for attempt in range(2):
            r = self.call(op, timeout=60, path=node.ref["path"], key=node.ref["key"], **kw)
            if r.get("ok"):
                return node
            err = r.get("error") or ""
            if "different node" in err and attempt == 0:
                fresh = self._fresh(node)
                if fresh:
                    node = fresh
                    continue
                raise HarnessFault("ui", "%s is not on screen any more" % node.brief())
            raise HarnessFault("ui", "%s on %s failed: %s" % (op, node.brief(), err[:120]))
        raise HarnessFault("ui", "could not reach %s" % node.brief())

    def press(self, node):
        self.guard()
        self._at("press", node)
        self.pressed["ax"] = self.pressed.get("ax", 0) + 1

    def set_text(self, node, text, secret=False):
        """Focus the field (a press), select all and delete, post the text as key events; when the field
        does not read it back, set its AXValue (never a password field's). The text travels on ssh's stdin
        only and is never logged."""
        self.guard()
        secret = secret or "password" in node.states
        try:
            node = self._at("press", node)
        except HarnessFault:
            node = self._at("focus", node)
        time.sleep(0.3)
        self.call("keys", keys=["select_all", "delete"], gap_ms=120)
        r = self.call("type", timeout=60 + len(text), text=text)
        if not r.get("ok"):
            raise HarnessFault("ui", "typing into a field failed: %s" % (r.get("error") or "")[:120])
        if "password" in node.states:
            return
        time.sleep(0.3)
        for n in self.tree():
            if n.ref["path"] == node.ref["path"] and n.role == "text_field":
                if (n.value or "") == text:
                    return
                self.log("the field reads %d characters after typing, not %d: setting its value"
                         % (len(n.value or ""), len(text)))
                self._at("setvalue", n, text=text)
                return
        if not secret:
            self.log("the field moved after typing; the driver reads it again")

    def key(self, name):
        if name not in KEYS:
            raise HarnessFault("ui", "no key %r on macOS" % name)
        r = self.call("keys", keys=[name], gap_ms=200)
        if not r.get("ok"):
            raise HarnessFault("ui", "key %s failed: %s" % (name, (r.get("error") or "")[:120]))

    def scroll(self, direction="down"):
        self.key("page_down" if direction == "down" else "page_up")

    def screenshot(self, path):
        return False

    def alive(self):
        self.guard()
        r = self.call("alive", timeout=30)
        return bool(r.get("alive"))

    def display_alive(self):
        try:
            return bool(self.call("ping", timeout=30).get("ok"))
        except HarnessFault:
            return False

    def close(self):
        pass
