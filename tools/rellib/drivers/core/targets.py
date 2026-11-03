# SPDX-License-Identifier: Apache-2.0
"""Targets: what a step looks for, said once, found on any build.

A Target names a control by its Semantics id (registry `trust_ids.json`, shared with the app's
contract test app/test/trust_ids_test.dart), its role, and its label by ARB key. Lookup order on a
tree: the id (where the platform exposes ids) → role + the build's text for one of the keys →
role + a literal name (`names`, for releases older than a key) → nothing (the driver then asks
recover.py). Never tree order, never coordinates.

Name matching is on whitespace-normalised, case-folded text: the whole name, or its first line
(Flutter merges a row's title and value into one name: "Node server\\nnode.btlabs.uk"), or with
`match="starts"` the start of the name, `match="contains"` anywhere in it.
"""
import json
import os
import re
from dataclasses import dataclass, field

from . import breaks
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
    secret: bool = False          # the screen holds a phrase, password or PIN: never sent to a model
    family: tuple = ("desktop", "phone")

    def __str__(self):
        return self.id


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
    out = []
    for k in target.keys:
        p = labels.pattern(k) if labels else None
        if p:
            out.append(_norm_pat(p))
    for n in target.names:
        out.append(n[3:] if n.startswith("re:") else re.escape(_norm(n)))
    return out


def _norm_pat(p):
    # labels.pattern() escapes literal text; normalise the escaped spaces and case like the names
    return re.sub(r"(\\ )+|\s+", " ", p).casefold()


def _role_fit(want, got):
    """0 the role asked for, 1 a check box where a switch is asked for and back, 2 any other compatible
    role (a Windows row of a switch is a label button next to its check box: the check box is the control)."""
    if got == want:
        return 0
    return 1 if {want, got} == {"toggle", "checkbox"} else 2


def find(target, tree, labels=None):
    """The nodes that are this target: by id first, else by role and label. Best first."""
    if breaks.hidden(target.id):
        return []
    by_id = [n for n in tree if n.id and n.id == target.id]
    if by_id:
        return by_id
    ok_roles = COMPATIBLE.get(target.role, {target.role})
    hits = []
    for rank, pat in enumerate(patterns(target, labels)):
        for n in tree:
            if n.role in ok_roles and _fits(n.name, pat, target.match) and n not in hits:
                hits.append((rank, _role_fit(target.role, n.role), 0 if n.enabled else 1, n))
    hits.sort(key=lambda h: h[:3])
    return [h[3] for h in hits]


def load_registry(path=REGISTRY):
    """{id: Target} from trust_ids.json; {} when the file is missing (a checkout before ids)."""
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, ValueError):
        return {}
    out = {}
    for c in data.get("controls", []):
        out[c["id"]] = Target(id=c["id"], role=c.get("role", "button"), keys=tuple(c.get("keys", ())),
                              names=tuple(c.get("names", ())), match=c.get("match", "line"),
                              screen=c.get("screen", ""), secret=bool(c.get("secret")),
                              family=tuple(c.get("family", ("desktop", "phone"))))
    return out


_REG = {}


def T(tid, **kw):
    """The registry's target `tid`, with fields overridden by kw (a driver adding literal names for an
    old release); a target the registry lacks is built from kw alone."""
    if not _REG:
        _REG.update(load_registry() or {"": None})
    base = _REG.get(tid)
    if base is None:
        return Target(id=tid, **kw)
    if not kw:
        return base
    d = dict(base.__dict__)
    for k, v in kw.items():
        d[k] = tuple(d[k]) + tuple(v) if k in ("names", "keys") else v  # more ways to find it, the registry's first
    return Target(**d)
