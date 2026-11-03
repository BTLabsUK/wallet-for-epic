# SPDX-License-Identifier: Apache-2.0
"""The tests `tools/t affected` (and `tools/check.sh`'s fast mode) run for a change.

The change is every file that differs from the merge base with the base ref (main): committed,
staged, unstaged and untracked (not ignored). The selection is:

  1. every test the import graph (graph.py) says the change reaches;
  2. app/pubspec.yaml or app/pubspec.lock changed: every test (packages and assets move);
  3. tools/lepic.rev or tools/lepic-flutter.rev changed: every test that reaches package:lepic;
  4. strings (app/lib/l10n/**, app/l10n.yaml): the generated app_localizations*.dart files are left
     out of step 1 (nearly every screen imports them; a new key changes nothing they show). In
     their place: the tests that read the l10n files (step 1's data rule finds them: l10n_test,
     l10n_quality_test, the help and layout checks), and the tests whose code names a changed key
     or still contains a changed English text;
  5. app/analysis_options.yaml: nothing more (flutter analyze is its check);
  6. always the SENTINELS below.
"""
import json
import os
import re
import subprocess

from . import graph as g

# A fixed set of fast tests (about 5 s each, under a minute together) on what must never break,
# run with every selection: opening a wallet (the PIN vault, and with WFE_LEPIC_LIB the LEPIC
# end to end part), a seed restore (the core's restore flag and scan; a restored wallet's first
# Setup), an install made by an older release opened by this one (the install contract's test and
# its migrations), the LEPIC binding without the native library (error mapping, rows, where a
# build finds the library) and the strings (every language has exactly the template's keys).
SENTINELS = (
    "app/test/vault_test.dart",
    "app/test/restore_scan_test.dart",
    "app/test/desktop/restore_setup_locked_test.dart",
    "app/test/install_upgrade_test.dart",
    "app/test/lepic_mapping_test.dart",
    "app/test/lepic_library_test.dart",
    "app/test/l10n_test.dart",
)

FULL_TRIGGERS = ("app/pubspec.yaml", "app/pubspec.lock")
LEPIC_PINS = ("tools/lepic.rev", "tools/lepic-flutter.rev")
L10N_DIR = "app/lib/l10n/"
L10N_CONFIG = "app/l10n.yaml"
GENERATED_L10N = re.compile(r"^app/lib/l10n/app_localizations(_\w+)?\.dart$")
ANALYSIS_ONLY = ("app/analysis_options.yaml",)


def git(root, *args, check=True):
    r = subprocess.run(["git", "-C", root, *args], capture_output=True, text=True)
    if check and r.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)}: {r.stderr.strip()}")
    return r.stdout


def repo_files(root):
    """Tracked and untracked (not ignored) files, as git sees the working tree."""
    out = git(root, "ls-files", "-z", "--cached", "--others", "--exclude-standard")
    return [p for p in out.split("\0") if p]


def merge_base(root, base_ref):
    r = subprocess.run(["git", "-C", root, "merge-base", "HEAD", base_ref], capture_output=True, text=True)
    if r.returncode == 0:
        return r.stdout.strip()
    return git(root, "rev-parse", "HEAD").strip()


def changed_files(root, base):
    """Files that differ from `base` in the working tree, untracked ones included (check.sh's rule)."""
    diff = git(root, "diff", "--name-only", "-z", base)
    untracked = git(root, "ls-files", "-z", "--others", "--exclude-standard")
    return sorted({p for p in (diff + untracked).split("\0") if p})


def _load_json(text):
    try:
        data = json.loads(text)
    except ValueError:
        return {}
    return data if isinstance(data, dict) else {}


def is_english(path):
    """An English string file: the template ARB or a fragment without a language suffix."""
    name = os.path.basename(path)
    if name.endswith(".arb"):
        return name == "app_en.arb"
    return name.endswith(".json") and name.count(".") == 1


def changed_strings(root, base, changed):
    """(keys, old English texts) of the changed string files: a key counts when it was added,
    removed or its text changed, in any language."""
    keys, old_texts = set(), set()
    for p in changed:
        if not p.startswith(L10N_DIR) or not p.endswith((".arb", ".json")) or p.endswith("/untranslated.json"):
            continue
        try:
            with open(os.path.join(root, p), encoding="utf-8") as f:
                now = _load_json(f.read())
        except OSError:
            now = {}
        r = subprocess.run(["git", "-C", root, "show", f"{base}:{p}"], capture_output=True, text=True)
        before = _load_json(r.stdout) if r.returncode == 0 else {}
        for k in set(now) | set(before):
            if k.startswith("@") or k.startswith("@@"):
                continue
            if now.get(k) != before.get(k):
                keys.add(k)
                old = before.get(k)
                if is_english(p) and isinstance(old, str):
                    old_texts.update(_text_pieces(old))
    return keys, old_texts


def _text_pieces(message):
    """The longest literal run of an English message between placeholders, if long enough to find
    in a test without false hits."""
    pieces = [s.strip() for s in re.split(r"\{[^{}]*\}|[{}]", message)]
    pieces = [s for s in pieces if len(s) >= 8]
    return [max(pieces, key=len)] if pieces else []


class Selection:
    def __init__(self):
        self.tests = {}  # test -> reason
        self.notes = []
        self.full = False

    def add(self, test, reason):
        self.tests.setdefault(test, reason)


def select(root, changed, base=None, graph=None, sentinels=True):
    """The tests to run for `changed` (repository paths). `base` (a commit) is needed only to diff
    string files."""
    graph = graph or g.Graph(root, repo_files(root))
    sel = Selection()
    tests = graph.tests()
    changed = set(changed)

    full = sorted(changed & set(FULL_TRIGGERS))
    if full:
        sel.full = True
        sel.notes.append(f"{full[0]} changed: every test")
        for t in tests:
            sel.add(t, full[0])
        return sel

    strings = {c for c in changed if c.startswith(L10N_DIR) or c == L10N_CONFIG}
    generated = {c for c in changed if GENERATED_L10N.match(c)}
    graph_changed = set(changed)
    pins = sorted(changed & set(LEPIC_PINS))
    if pins:
        graph_changed.add(g.PKG_LEPIC)
    for t in tests:
        c = graph.hit(t, graph_changed, data_only=generated)
        if c:
            sel.add(t, pins[0] if c == g.PKG_LEPIC else c)

    if strings:
        keys, old_texts = changed_strings(root, base, strings) if base else (set(), set())
        if keys or old_texts:
            key_re = re.compile(r"\b(" + "|".join(sorted(map(re.escape, keys))) + r")\b") if keys else None
            for t in tests:
                if t in sel.tests:
                    continue
                text = graph.test_side_text(t)
                m = key_re.search(text) if key_re else None
                if m:
                    sel.add(t, f"string {m.group(1)}")
                    continue
                for s in old_texts:
                    if s in text:
                        sel.add(t, "an English text it checks")
                        break
        sel.notes.append(f"strings changed: l10n tests, and tests naming {len(keys)} changed keys")
    if changed & set(ANALYSIS_ONLY):
        sel.notes.append("analysis_options.yaml changed: flutter analyze checks it, no test does")
    if sentinels:
        for s in SENTINELS:
            if s in graph.sources:
                sel.add(s, "sentinel")
    return sel
