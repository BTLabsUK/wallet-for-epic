# SPDX-License-Identifier: Apache-2.0
"""What every platform's UI looks like to the driver core: a flat list of Nodes read from the
platform's accessibility tree, and a few actions on them.

A platform adapter (linux/atspi.py, android/uia.py, windows/uia.py) implements Surface. The core
never sees AT-SPI, uiautomator or UIA objects, only Nodes; `ref` is the adapter's own handle and
the core passes it back untouched. Roles are the core's small set below, mapped by each adapter.

Nothing here reads tree order, coordinates or a position on screen to decide what a control is:
`i` numbers a node within one read only so a model's answer can name it.
"""
from dataclasses import dataclass, field
from typing import Any, Optional, Protocol

# The roles a target can ask for. Adapters map their own (AT-SPI "push button", Android
# android.widget.Button + clickable, UIA ControlType.Button) onto these; anything else is "other".
ROLES = ("button", "text_field", "checkbox", "toggle", "tab", "row", "text", "link", "menu_item", "dialog", "other")

# Roles that satisfy a target's role: a row or a link can act as a button; a toggle reads as a
# checkbox on some platforms (Android's Switch is checkable, AT-SPI says "toggle button").
COMPATIBLE = {
    "button": {"button", "link", "menu_item", "row", "tab"},
    "checkbox": {"checkbox", "toggle"},
    "toggle": {"toggle", "checkbox", "button"},
    "row": {"row", "button", "menu_item", "text"},
    "tab": {"tab", "button", "menu_item"},
    "text": {"text", "other", "row", "button"},
    "text_field": {"text_field"},
    "link": {"link", "button"},
    "menu_item": {"menu_item", "button", "row"},
    "dialog": {"dialog"},
    "other": set(ROLES),
}


@dataclass
class Node:
    i: int                       # number within this read (for logs and the model's answer)
    role: str                    # one of ROLES
    name: str                    # the accessible name (Flutter: the Semantics label, often several lines)
    id: Optional[str] = None     # Semantics identifier when the platform exposes it (Android resource-id)
    value: Optional[str] = None  # a text field's text, a slider's value
    states: frozenset = frozenset()  # subset of: enabled, focused, checked, selected, editable, showing, password
    actions: tuple = ()          # what the adapter can do on it: press, set_text, scroll
    ref: Any = field(default=None, repr=False, compare=False)

    @property
    def enabled(self):
        return "enabled" in self.states or not self.states  # adapters that read no states: assume enabled

    def brief(self):
        """One line for logs and the model: no value of a password field."""
        v = "" if "password" in self.states or self.value is None else " value=%r" % self.value[:60]
        st = ",".join(sorted(self.states - {"showing", "enabled"}))
        return "#%d %s %r%s%s%s" % (self.i, self.role, self.name[:90].replace("\n", " | "),
                                    " id=" + self.id if self.id else "", v, " [" + st + "]" if st else "")


class Surface(Protocol):
    """One running app's UI. Every method may raise HarnessGone (core.faults) when the display,
    emulator or rig behind it is gone; the lane then rebuilds the platform and resumes."""
    platform: str   # linux | windows | android
    family: str     # desktop | phone (which app UI: app/lib/src/desktop or app/lib/src/ui)

    def tree(self) -> list:
        """The app window's nodes that are showing, in any order."""

    def press(self, node: Node) -> None:
        """Activate it the way a user would (the node's own action, else a click at its centre)."""

    def set_text(self, node: Node, text: str, secret: bool = False) -> None:
        """Replace the field's text. The text never goes to a log; [secret] (a phrase, a PIN, a
        password) also keeps it off this host's command lines and out of every file."""

    def key(self, name: str) -> None:
        """back | escape | enter | tab | page_down: a key press or the system Back."""

    def scroll(self, direction: str = "down") -> None:
        """Scroll the page or list that has focus or is under the pointer."""

    def screenshot(self, path: str) -> bool:
        """PNG of the app window; False when none could be taken."""

    def alive(self) -> bool:
        """The app's process is running."""
