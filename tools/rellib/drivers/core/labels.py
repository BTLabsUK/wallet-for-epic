# SPDX-License-Identifier: Apache-2.0
"""The English strings of one build, by ARB key.

A driver looks a control up by the text the build it is driving shows, so the candidate is read
with the candidate's strings (REL_CANDIDATE_SRC: the release worktree) and the previous release
with its own (git tag v<version>, or REL_PREVIOUS_REF). A renamed button in the candidate is then
found by its key, with no driver change. A key a build does not have gives no text; the target's
other keys and literal names still apply.
"""
import json
import os
import re
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
ARB = "app/lib/l10n/app_%s.arb"


def _load_dir(src, locale="en"):
    try:
        with open(os.path.join(src, ARB % locale), encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def _load_ref(ref, locale="en", repo=ROOT):
    try:
        r = subprocess.run(["git", "-C", repo, "show", "%s:%s" % (ref, ARB % locale)], capture_output=True, text=True, timeout=30)
        return json.loads(r.stdout) if r.returncode == 0 else None
    except (OSError, ValueError, subprocess.SubprocessError):
        return None


class Labels:
    """Strings of one build. `src` a source tree, `ref` a git ref of this checkout; the first that
    loads wins, else this checkout's own ARB (said in `origin`)."""

    def __init__(self, src=None, ref=None, arb=None, locale=None):
        """`locale`: the language the app shows (the device's or the rig user's: REL_TRUST_LOCALE), its
        ARB over the English one, so a key missing from it still matches the English text."""
        self.locale = locale or os.environ.get("REL_TRUST_LOCALE") or "en"
        self.arb, self.origin = arb, "given" if arb is not None else None
        if self.arb is None and src:
            self.arb, self.origin = _load_dir(src), src
        if self.arb is None and ref:
            self.arb, self.origin = _load_ref(ref), "git " + ref
        if self.arb is None:
            self.arb, self.origin = _load_dir(ROOT) or {}, "this checkout"
        self.en = self.arb   # the English strings, before a locale's own go over them
        if self.locale != "en" and arb is None:
            if self.origin == "this checkout":
                src, ref = ROOT, None
            loc = (_load_dir(src, self.locale) if src else None) or (_load_ref(ref, self.locale) if ref else None) or {}
            self.arb = dict(self.arb, **{k: v for k, v in loc.items() if isinstance(v, str) and v and not k.startswith("@")})
            self.origin += " (%s)" % self.locale

    @classmethod
    def for_build(cls, which):
        """`previous` or `candidate`, from the runner's env (tools/rel's contract, trust-*.sh)."""
        if which == "candidate":
            return cls(src=os.environ.get("REL_CANDIDATE_SRC"), ref=os.environ.get("REL_CANDIDATE_REF"))
        v = (os.environ.get("REL_PREVIOUS_VERSION") or "").strip()
        ref = (os.environ.get("REL_PREVIOUS_REF") or "").strip() or (("v" + v.lstrip("v")) if v else None)
        return cls(src=os.environ.get("REL_PREVIOUS_SRC"), ref=ref)

    def localized(self, english, prefix="deskSet"):
        """The texts this build shows (its locale) for the English names given: those of every `prefix` key whose
        English text is one of them. For a name list written in English (a recipe's section names) on a
        build shown in another language."""
        names = set(english)
        return {self.text(k) for k, v in self.en.items() if k.startswith(prefix) and v in names and self.text(k)}

    def text(self, key):
        v = self.arb.get(key)
        return v if isinstance(v, str) and v else None

    def pattern(self, key):
        """The key's text as a regex: placeholders ({amount}) match any text; None without the key.
        ICU plural/select messages match on their literal head only."""
        t = self.text(key)
        if t is None:
            return None
        if re.search(r"\{\w+,\s*(plural|select)", t):
            if t.lstrip().startswith("{"):
                return _icu_branches(t)
            t = t.split("{", 1)[0]
            return re.escape(t.strip()) + r".*" if t.strip() else None
        parts = re.split(r"\{\w+\}", t)
        return ".+?".join(re.escape(p) for p in parts)


def _icu_branches(t):
    """A message that is one plural/select ("{count, plural, one{I have {count} word} other{...}}"): any of
    its branches, the count and other placeholders matching any text. None when it does not parse."""
    t = t.strip()
    m = re.match(r"\{\w+,\s*(?:plural|select),\s*", t)
    if not m or not t.endswith("}"):
        return None
    body, branches, i = t[m.end():-1], [], 0
    while i < len(body):
        j = body.find("{", i)
        if j < 0:
            break
        depth, k = 1, j + 1
        while k < len(body) and depth:
            depth += {"{": 1, "}": -1}.get(body[k], 0)
            k += 1
        if depth:
            return None
        branches.append(body[j + 1:k - 1])
        i = k
    alts = []
    for b in branches:
        parts = re.split(r"\{\w+\}|#", b)
        alts.append(".+?".join(re.escape(p) for p in parts))
    return "(?:%s)" % "|".join(alts) if alts else None
