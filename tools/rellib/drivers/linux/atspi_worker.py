#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""The AT-SPI side of linux/atspi.py, run as its own process in the sandbox's environment (DISPLAY,
dbus, a11y bus) so a hung AT-SPI call or a rebuilt sandbox costs a restart of this worker, never the
lane. One JSON request per line on stdin, one JSON answer per line on stdout.

    {"op": "tree"}                                   -> {"ok": true, "app": bool, "nodes": [...]}
    {"op": "press", "path": [..], "role", "name"}    -> {"ok": bool, "how": "..."}
    {"op": "set_text", "path", "role", "name", "text"} -> {"ok": bool, "how": "..."}
    {"op": "focus", "path", "role", "name"}          -> {"ok": bool}
    {"op": "ping_app"}                               -> {"ok": true, "app": bool}  (asks the app itself)

A node is {"path": child indexes from the app root, "role": AT-SPI role name, "name", "id"
(accessible id where the toolkit sets one), "desc", "value" (never a password field's), "states",
"actions"}. An action re-reads the node at its path and checks role and name first; when the tree
moved under it, the node is looked up again by role and name. Component.get_extents is never called:
on Flutter it blocks the app for about 15 s. A text sent to set_text is never written anywhere.
"""
import json
import sys
import time
import warnings

warnings.filterwarnings("ignore")

import gi  # noqa: E402

gi.require_version("Atspi", "2.0")
from gi.repository import Atspi  # noqa: E402

APP_NAMES = ("uk.btlabs.epiccash.desktop", "btwallet", "com.blacktyger.epicwallet", "epic_wallet")
ST = Atspi.StateType
STATES = {}
for _n in ("showing", "visible", "enabled", "sensitive", "focused", "editable", "checked", "selected", "focusable"):
    try:
        STATES[_n] = getattr(ST, _n.upper())
    except AttributeError:
        pass


def app():
    desk = Atspi.get_desktop(0)
    for i in range(desk.get_child_count()):
        a = desk.get_child_at_index(i)
        if a is not None and (a.get_name() or "") in APP_NAMES:
            return a
    return None


def read(acc, path):
    role = acc.get_role_name() or ""
    ss = acc.get_state_set()
    states = [n for n, t in STATES.items() if ss.contains(t)]
    actions = []
    try:
        ai = acc.get_action_iface()
        if ai:
            actions = [ai.get_action_name(i) for i in range(ai.get_n_actions())]
    except Exception:  # noqa: BLE001
        pass
    value = None
    if "password" not in role:
        try:
            if acc.get_text_iface():
                value = Atspi.Text.get_text(acc, 0, Atspi.Text.get_character_count(acc))
        except Exception:  # noqa: BLE001
            pass
    ident = None
    try:
        ident = acc.get_accessible_id() or None
    except Exception:  # noqa: BLE001
        pass
    desc = ""
    try:
        desc = acc.get_description() or ""
    except Exception:  # noqa: BLE001
        pass
    return {"path": path, "role": role, "name": acc.get_name() or "", "id": ident, "desc": desc,
            "value": value, "states": states, "actions": actions}


def walk(acc, path, out, depth=0):
    try:
        n = read(acc, path)
    except Exception:  # noqa: BLE001
        return
    out.append(n)
    if depth >= 60:
        return
    try:
        cnt = acc.get_child_count()
    except Exception:  # noqa: BLE001
        return
    for i in range(cnt):
        c = None
        for _ in range(3):
            try:
                c = acc.get_child_at_index(i)
            except Exception:  # noqa: BLE001
                c = None
            if c is not None:
                break
            time.sleep(0.1)
        if c is not None:
            walk(c, path + [i], out, depth + 1)


def resolve(req):
    """The accessible at req's path when its role and name still match; else the first with that role and name."""
    root = app()
    if root is None:
        return None
    acc = root
    try:
        for i in req["path"]:
            acc = acc.get_child_at_index(i)
            if acc is None:
                break
        if acc is not None and acc.get_role_name() == req["role"] and (acc.get_name() or "") == req["name"]:
            return acc
    except Exception:  # noqa: BLE001
        pass
    found = []

    def look(a, depth=0):
        if found or depth > 60:
            return
        try:
            if a.get_role_name() == req["role"] and (a.get_name() or "") == req["name"]:
                found.append(a)
                return
            for i in range(a.get_child_count()):
                c = a.get_child_at_index(i)
                if c is not None:
                    look(c, depth + 1)
        except Exception:  # noqa: BLE001
            pass
    look(root)
    return found[0] if found else None


def do(acc, wants):
    ai = acc.get_action_iface()
    if not ai:
        return None
    names = [ai.get_action_name(i) for i in range(ai.get_n_actions())]
    for w in wants:
        if w in names and ai.do_action(names.index(w)):
            return w
    return None


def press(req):
    acc = resolve(req)
    if acc is None:
        return {"ok": False, "how": "gone"}
    a = acc
    for depth in range(4):  # the node's own action, else a near ancestor's (a label inside a button)
        try:
            w = do(a, ("Tap", "click", "Press", "press", "activate"))
            if w:
                return {"ok": True, "how": "%s%s" % (w, " on parent %d" % depth if depth else "")}
        except Exception:  # noqa: BLE001
            pass
        try:
            a = a.get_parent()
        except Exception:  # noqa: BLE001
            a = None
        if a is None:
            break
    return {"ok": False, "how": "no action"}


def focus(req):
    acc = resolve(req)
    if acc is None:
        return {"ok": False}
    for _ in range(3):
        try:
            do(acc, ("Focus", "Tap"))
        except Exception:  # noqa: BLE001
            pass
        try:
            acc.grab_focus()
        except Exception:  # noqa: BLE001
            pass
        time.sleep(0.25)
        try:
            if acc.get_state_set().contains(ST.FOCUSED):
                return {"ok": True}
        except Exception:  # noqa: BLE001
            pass
    return {"ok": False}


def set_text(req):
    acc = resolve(req)
    if acc is None:
        return {"ok": False, "how": "gone"}
    try:
        et = acc.get_editable_text_iface()
        if et and et.set_text_contents(req["text"]):
            return {"ok": True, "how": "editable text"}
    except Exception:  # noqa: BLE001
        pass
    return {"ok": False, "how": "no editable text"}


def ping_app():
    """A question only the app's own thread can answer (GetAttributes is not cached by libatspi): a frozen
    app leaves it unanswered. {"app": false} when the app is not on the bus: not up yet, or a stopped app
    (its name can no longer be read: the caller knows which from whether this process answered before)."""
    root = app()
    if root is None:
        return {"ok": True, "app": False}
    root.get_attributes()
    if root.get_child_count() > 0:
        win = root.get_child_at_index(0)
        if win is not None:
            win.get_attributes()
    return {"ok": True, "app": True}


def main():
    for line in sys.stdin:
        try:
            req = json.loads(line)
            op = req.get("op")
            if op == "tree":
                root = app()
                out = []
                if root is not None:
                    walk(root, [], out)
                ans = {"ok": True, "app": root is not None, "nodes": out}
            elif op == "press":
                ans = press(req)
            elif op == "set_text":
                ans = set_text(req)
            elif op == "focus":
                ans = focus(req)
            elif op == "ping":
                ans = {"ok": True}
            elif op == "ping_app":
                ans = ping_app()
            else:
                ans = {"ok": False, "error": "unknown op %r" % op}
        except Exception as e:  # noqa: BLE001
            ans = {"ok": False, "error": "%s: %s" % (type(e).__name__, e)}
        sys.stdout.write(json.dumps(ans) + "\n")
        sys.stdout.flush()


if __name__ == "__main__":
    main()
