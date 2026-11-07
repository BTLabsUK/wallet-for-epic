# SPDX-License-Identifier: Apache-2.0
"""Targets: what a step looks for, said once in trust_ids.json, found on any build.

Every target lives in the registry `trust_ids.json`; the app's constants are generated from the same
file (tools/ui-targets), so the two sides cannot drift. A driver writes T("the.id") and nothing else:
no label, role or text. Kinds of entry:

  control   a control the app marks with this Semantics id. On the candidate it is found by id only.
  copy      read-only text a step checks: no id, found by the text of its ARB `keys` in the strings of
            the build being driven. A wording change needs no driver change.
  group     any of `ids` (a server row, Use or Add); with .of(data), the one whose text holds that data.
  template  an id with a `*` for data (a month, a word's number): .at(value) gives the concrete target.

The previous release has fewer ids, so on any build but the candidate a control falls back to role +
the text of its keys, then `names` (regex allowed with "re:"). Never tree order, never coordinates.

Name matching is on whitespace-normalised, case-folded text: the whole name, or its first line
(Flutter merges a row's title and value into one name: "Node server\\nnode.btlabs.uk"), or with
`match="starts"` the start of the name, `match="contains"` anywhere in it.
"""
import json
import os
import re
from dataclasses import dataclass, replace

from .surface import COMPATIBLE

HERE = os.path.dirname(os.path.abspath(__file__))
REGISTRY = os.path.join(os.path.dirname(HERE), "trust_ids.json")


@dataclass(frozen=True)
class Target:
    id: str                       # g4.<screen>.<control>; a stable name even where the platform shows no ids
    role: str = "button"
    keys: tuple = ()              # ARB keys, newest first
    names: tuple = ()             # literal names (regex allowed with "re:") for builds without the keys
    match: str = "line"           # line | starts | contains | exact
    screen: str = ""
    secret: bool = False          # the screen holds a phrase, password or PIN: never kept as a shot or a dump
    family: tuple = ("desktop", "android")
    kind: str = "control"         # control | copy | group | template
    ids: tuple = ()               # group: the ids it stands for
    data: str = ""                # .of(): the data the node's own text must hold

    def __str__(self):
        return self.id

    def of(self, data, names=()):
        """This target's row that holds `data` (a host, a contact's name): data, not copy, so read off
        the node's text. `names`: how a build without the id shows it, built from that data."""
        return replace(self, data=_norm(data), names=tuple(names) + self.names)

    def at(self, value, names=()):
        """A template's concrete target (`value` None: this target with `names` added)."""
        tid = self.id if value is None else self.id.replace("*", str(value))
        return replace(self, id=tid, names=tuple(names) + self.names, kind="control")


def _norm(s):
    return re.sub(r"\s+", " ", s or "").strip().casefold()


def _fits(name, pat, match):
    """pat: a regex over normalised text."""
    full = _norm(name)
    first = _norm((name or "").split("\n", 1)[0])
    if match == "exact":
        return re.fullmatch(pat, full) is not None
    if match == "starts":
        return re.match(pat, full) is not None
    if match == "contains":
        return re.search(pat, full) is not None
    return re.fullmatch(pat, first) is not None or re.fullmatch(pat, full) is not None


def patterns(target, labels):
    """The regexes (over normalised text) this target's label can be on this build, newest first."""
    ids_only = bool(getattr(labels, "ids_only", False))
    if ids_only and target.kind != "copy":
        return []
    out = []
    for k in target.keys:
        p = labels.pattern(k) if labels else None
        if p:
            out.append(_norm_pat(p))
    if not ids_only:
        for n in target.names:
            out.append(n[3:] if n.startswith("re:") else re.escape(_norm(n)))
    return out


def texts_of(targets, labels):
    """The normalised plain texts these targets can show: the build's keys, then older builds' names."""
    out = set()
    for t in targets:
        out |= {_norm(labels.text(k)) for k in t.keys if labels and labels.text(k)}
        out |= {_norm(n) for n in t.names if not n.startswith("re:")}
    return out


def _holds(node, data):
    """`data` as a whole token of the node's text (a host stops at a comma, a space or the end)."""
    return not data or re.search(r"(?:^|[\s:])%s(?:[,\s]|$)" % re.escape(data), _norm(node.name)) is not None


def _norm_pat(p):
    # labels.pattern() escapes literal text; normalise the escaped spaces and case like the names
    return re.sub(r"(\\ )+|\s+", " ", p).casefold()


def _role_fit(want, got):
    """0 the role asked for, 1 a check box where a switch is asked for and back, 2 any other compatible
    role (a Windows row of a switch is a label button next to its check box: the check box is the control)."""
    if got == want:
        return 0
    return 1 if {want, got} == {"toggle", "checkbox"} else 2


def _box(n):
    ref = n.ref if isinstance(n.ref, dict) else {}
    return ref.get("bounds")


def _control_in(row, tree):
    """A switch's id on the row around it (26.11.0 on: the id joins the list tile's node, the switch
    is a node of its own): the one switch or check box inside the row is the control, the node whose
    checked state is the setting. The row itself where none is inside, or no bounds are read."""
    if row.role in ("toggle", "checkbox") or not _box(row):
        return row
    r = _box(row)
    inside = [n for n in tree if n.role in ("toggle", "checkbox") and _box(n)
              and r[0] <= _box(n)[0] and r[1] <= _box(n)[1] and _box(n)[2] <= r[2] and _box(n)[3] <= r[3]]
    return inside[0] if len(inside) == 1 else row


def find(target, tree, labels=None):
    """The nodes that are this target: by id; a copy target, or any target on a build before its id, by
    role and text. Best first."""
    wanted = target.ids or (target.id,)
    by_id = [n for n in tree if n.id and n.id in wanted and _holds(n, target.data)]
    if by_id:
        return [_control_in(n, tree) if target.role in ("toggle", "checkbox") else n for n in by_id]
    ok_roles = COMPATIBLE.get(target.role, {target.role})
    hits = []
    for rank, pat in enumerate(patterns(target, labels)):
        for n in tree:
            if n.role in ok_roles and _fits(n.name, pat, target.match) and _holds(n, target.data) and n not in hits:
                hits.append((rank, _role_fit(target.role, n.role), 0 if n.enabled else 1, n))
    hits.sort(key=lambda h: h[:3])
    return [h[3] for h in hits]


def load_registry(path=REGISTRY, family="desktop"):
    """{id: Target} from trust_ids.json, an entry's `android` fields applied for the phone family."""
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    out = {}
    for c in data["controls"]:
        c = dict(c, **c.get(family, {}))
        out[c["id"]] = Target(id=c["id"], role=c.get("role", "button"), keys=tuple(c.get("keys", ())),
                              names=tuple(c.get("names", ())), match=c.get("match", "line"),
                              screen=c.get("screen", ""), secret=bool(c.get("secret")),
                              family=tuple(c.get("family", ("desktop", "android"))),
                              kind=c.get("kind", "control"), ids=tuple(c.get("ids", ())))
    return out


_REG = {}


def _registry(family):
    if family not in _REG:
        _REG[family] = load_registry(family=family)
    return _REG[family]


def T(tid):
    """The registry's target `tid`, as the desktop app has it."""
    reg = _registry("desktop")
    if tid not in reg:
        raise KeyError("%s is not in trust_ids.json: add it with tools/ui-targets add" % tid)
    return reg[tid]


def T_phone(tid):
    """The registry's target `tid`, as the phone app has it."""
    reg = _registry("android")
    if tid not in reg:
        raise KeyError("%s is not in trust_ids.json: add it with tools/ui-targets add" % tid)
    return reg[tid]


def under(prefix, family):
    """Every target of `family` whose id starts with `prefix`, in registry order."""
    return [t for t in _registry(family).values() if t.id.startswith(prefix) and family in t.family]
