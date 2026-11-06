# SPDX-License-Identifier: Apache-2.0
"""The tests `tools/t affected` (and `tools/check.sh`'s fast mode) run for a change.

The change is every file that differs from the merge base with the base ref (main): committed,
staged, unstaged and untracked (not ignored). The rule holds for any change of any size:

  1. a changed test file runs;
  2. a changed Dart file, helper or data file selects the tests that directly import it (or a file
     that exports it) or name it in a literal. No import closure;
  3. strings (app/lib/l10n/**, app/l10n.yaml): the tests that read the string files, and the tests
     whose own code names a changed key or still contains a changed English text. The generated
     app_localizations*.dart count only as data;
  4. a changed file with more than FILE_LIMIT such tests (l10n.dart, wallet_service.dart, a shared
     mock) keeps its namesake test and the tests naming a symbol the diff touched, at most
     FILE_LIMIT; without any, the few that import least;
  5. tools/lepic*.rev: the tests that import package:lepic, under the same limit; app/pubspec.yaml
     and app/pubspec.lock add nothing, flutter analyze and the sentinels check them;
  6. always the SENTINELS below;
  7. the whole selection stops at MAX_TESTS, taking in turn from each changed file.

What steps 4 and 7 drop is in Selection.left and printed by --list: the nightly and the candidate's
full run cover it. `--closure` is the old rule (every test the import graph reaches, every test on
pubspec), without limits. Nothing routine uses it; the guard treats it as a full run.
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

FILE_LIMIT = 12  # tests one changed file may select
MAX_TESTS = 40  # tests one selection may hold, sentinels included (the guard's limit as well)
FEW = 3  # tests kept for a wide file whose diff names nothing a test names
COMMON_MEMBERS = {"build", "main", "dispose", "initState", "createState", "toString", "copyWith",
                  "hashCode", "if", "for", "while", "switch", "return", "catch", "super", "assert"}
_OWNER = re.compile(r"^(?:abstract\s+|sealed\s+|final\s+|base\s+|interface\s+)*"
                    r"(?:class|mixin|enum|extension(?:\s+type)?|typedef)\s+(\w+)")
_MEMBER = re.compile(r"^ {0,2}(?!\s)(?:[\w<>?,.\[\] ]+\s)?(\w+)\s*(?:<[^>()]*>)?\s*(?:\(|=[^=>]|=>|;|\{)")
_HUNK = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@")

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


def _symbols_of(line, members, owners):
    m = _OWNER.match(line)
    if m:
        owners.add(m.group(1))
        return True
    m = _MEMBER.match(line)
    if m and m.group(1) not in COMMON_MEMBERS and not m.group(1).startswith("_"):
        members.add(m.group(1))
        return True
    return False


def changed_symbols(root, base, path):
    """(members, owners): the public names declared on the diff's lines or around them, and the
    classes that hold them. The class comes apart: a test naming it is a weaker match."""
    members, owners = set(), set()
    if not base:
        return members, owners
    try:
        with open(os.path.join(root, path), encoding="utf-8", errors="replace") as f:
            lines = f.read().split("\n")
    except OSError:
        lines = []
    r = subprocess.run(["git", "-C", root, "diff", "-U0", base, "--", path], capture_output=True, text=True)
    for line in r.stdout.split("\n"):
        m = _HUNK.match(line)
        if m:
            start, n = int(m.group(1)), int(m.group(2) or 1)
            for at in range(start, start + max(n, 1)):
                found_member = False
                for i in range(min(at, len(lines)) - 1, -1, -1):
                    text = lines[i]
                    indent = len(text) - len(text.lstrip(" "))
                    if text.strip() and indent == 0 and _OWNER.match(text):
                        _symbols_of(text, members, owners)
                        break
                    if not found_member and text.strip() and indent <= 2:
                        found_member = _symbols_of(text, members, owners)
        elif line[:1] in "+-" and line[:3] not in ("+++", "---"):
            _symbols_of(line[1:], members, owners)
    return members, owners


def _word_re(words):
    return re.compile(r"\b(" + "|".join(sorted(map(re.escape, words))) + r")\b") if words else None


def bound(graph, root, base, path, hits):
    """The tests a wide file keeps (step 4), best first."""
    if len(hits) <= FILE_LIMIT:
        return sorted(hits)
    stem = os.path.basename(path).split(".")[0]
    members, owners = changed_symbols(root, base, path) if path.endswith(".dart") else (set(), set())
    member_re, owner_re = _word_re(members), _word_re(owners)

    def rank(t):
        name, text = os.path.basename(t), graph.sources.get(t, "")
        if name == f"{stem}_test.dart" or name.startswith(f"{stem}_"):
            return 0
        if member_re and member_re.search(text):
            return 1
        if owner_re and not members and owner_re.search(text):
            return 2
        return 3
    ranked = sorted((rank(t), len(graph.edges.get(t, ())), t) for t in hits)
    kept = [t for r, _, t in ranked if r < 3] or [t for _, _, t in ranked[:FEW]]
    return kept[:FILE_LIMIT]


def _take_turns(sel, wanted, room):
    """Step 7: one test from each cause in turn while there is room."""
    queues = [(cause, list(ts)) for cause, ts in wanted.items()]
    while queues:
        for item in list(queues):
            cause, ts = item
            while ts and ts[0] in sel.tests:
                ts.pop(0)
            if not ts:
                queues.remove(item)
            elif room > 0:
                sel.add(ts.pop(0), cause)
                room -= 1
            else:
                queues.remove(item)


class Selection:
    def __init__(self):
        self.tests = {}  # test -> reason
        self.left = []  # tests the change touches that this run leaves to the nightly
        self.notes = []
        self.full = False

    def add(self, test, reason):
        self.tests.setdefault(test, reason)


def select(root, changed, base=None, graph=None, sentinels=True, closure=False):
    """The tests to run for `changed` (repository paths). `base` (a commit) is needed only to read
    diffs: string files, and the symbols of a wide file."""
    graph = graph or g.Graph(root, repo_files(root))
    if closure:
        return _select_closure(root, changed, base, graph, sentinels)
    sel = Selection()
    tests = graph.tests()
    test_set = set(tests)
    changed = set(changed)
    direct = {t: graph.direct(t) for t in tests}
    pending = set(SENTINELS) & set(graph.sources) if sentinels else set()
    wanted, dropped, silent = {}, set(), []

    def want(cause, hits):
        if not hits:
            return
        kept = bound(graph, root, base, cause, hits)
        wanted[cause] = kept
        dropped.update(set(hits) - set(kept))

    for c in sorted(changed):
        if c in test_set:
            wanted[c] = [c]
        elif c in LEPIC_PINS:
            want(c, [t for t in tests if g.PKG_LEPIC in direct[t]])
        elif c in FULL_TRIGGERS:
            sel.notes.append(f"{c} changed: flutter analyze and the sentinels check it")
        elif c in ANALYSIS_ONLY:
            sel.notes.append("analysis_options.yaml changed: flutter analyze checks it, no test does")
        else:
            data_only = GENERATED_L10N.match(c)
            hits = [t for t in tests if (c in direct[t] and not data_only) or graph.reads(t, c)]
            want(c, hits)
            if not hits and c.endswith(".dart") and c.startswith(("app/lib/", "app/test/")):
                silent.append(c)

    strings = {c for c in changed if c.startswith(L10N_DIR) or c == L10N_CONFIG}
    if strings:
        keys, old_texts = changed_strings(root, base, strings) if base else (set(), set())
        key_re = _word_re(keys)
        hits = {}
        for t in tests:
            text = graph.sources.get(t, "")
            m = key_re.search(text) if key_re else None
            if m:
                hits.setdefault(f"string {m.group(1)}", []).append(t)
            elif any(s in text for s in old_texts):
                hits.setdefault("an English text it checks", []).append(t)
        wanted.update(hits)
        sel.notes.append(f"strings changed: l10n tests, and tests naming {len(keys)} changed keys")

    for s in sorted(pending):
        sel.add(s, "sentinel")
    _take_turns(sel, wanted, MAX_TESTS - len(sel.tests))
    touched = dropped | {t for ts in wanted.values() for t in ts}
    sel.left = sorted(touched - set(sel.tests))
    if silent:
        sel.notes.append(f"no test imports {len(silent)} changed file(s) directly ({', '.join(silent[:3])}"
                         f"{', …' if len(silent) > 3 else ''}): name the tests yourself if they matter")
    if sel.left:
        sel.notes.append(f"{len(sel.left)} more tests touch this change: left to the nightly and the "
                         "candidate's full run")
    return sel


def _select_closure(root, changed, base, graph, sentinels):
    """--closure: every test the import graph reaches, with no limit."""
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
