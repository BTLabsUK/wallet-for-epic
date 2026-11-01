# SPDX-License-Identifier: Apache-2.0
"""Which Flutter tests a change affects: the import graph of app/ (tools/t, tools/check.sh).

Every Dart file under app/ is read once. A file depends on:
  - the files its `import`, `export` and `part` directives name (package:epic_wallet/ is app/lib/,
    a relative URI is relative to the file, both branches of a conditional import count; a URI
    whose file is gone still counts, so deleting a file selects the tests that imported it);
  - `package:lepic`, as the pseudo path PKG_LEPIC, which the pins in tools/lepic*.rev stand for;
  - data: every string literal that names an existing repository path, relative to app/ (where
    tests run) or to the file (goldens), like 'lib/l10n/app_en.arb', 'test/fixtures/x',
    'goldens/a.png' or '../tools/install-contract.json'. Interpolated literals count up to their
    first `$`, as their folder. A folder counts with everything under it.
A test (app/test/**/*_test.dart) depends on its transitive closure plus every
flutter_test_config.dart above it. It is affected when a changed path is in its closure, is one of
its data files or lies under one of its data folders.

Paths are repository-relative, with forward slashes.
"""
import os
import re

APP = "app"
TEST_DIR = "app/test"
PKG_PREFIX = "package:epic_wallet/"
PKG_LEPIC = "package:lepic"
DART_ROOTS = ("app/lib", "app/test", "app/tool", "app/bin", "app/integration_test")

_DIRECTIVE_START = re.compile(r"^\s*(import|export|part|library)\b")
_PART_OF = re.compile(r"^\s*part\s+of\b")
_QUOTED = re.compile(r"""'([^'\\\n]*)'|"([^"\\\n]*)\"""")
_SKIPPABLE = re.compile(r"^\s*(//.*|/\*.*|\*.*|@\w.*)?$")
# A literal that may be a path: no spaces, at least one slash, no scheme.
_PATHISH = re.compile(r"^[\w.\-]+(/[\w.\-${}]*)+$")
_DIR_CALL = re.compile(r"""Directory\(\s*'([\w.\-]+)'\s*\)""")


def norm(path):
    return os.path.normpath(path).replace(os.sep, "/")


def directives(source):
    """(directive text, rest of the source): the import/export/part block at the top of a file.
    Scanning stops at the first line that is not a directive, a comment, an annotation or blank,
    so an `import '…'` inside a string further down is not read as one."""
    lines = source.split("\n")
    out = []
    i = 0
    in_block_comment = False
    while i < len(lines):
        line = lines[i]
        if in_block_comment:
            if "*/" in line:
                in_block_comment = False
            i += 1
            continue
        if line.lstrip().startswith("/*") and "*/" not in line:
            in_block_comment = True
            i += 1
            continue
        if _DIRECTIVE_START.match(line):
            stmt = [line]
            while ";" not in stmt[-1] and i + 1 < len(lines):
                i += 1
                stmt.append(lines[i])
            out.append("\n".join(stmt))
            i += 1
            continue
        if _SKIPPABLE.match(line):
            i += 1
            continue
        break
    return out, "\n".join(lines[i:])


def uris(directive_text):
    """The URIs a directive names (two for a conditional import); none for `library` / `part of`."""
    if _PART_OF.match(directive_text) or directive_text.lstrip().startswith("library"):
        return []
    return [a or b for a, b in _QUOTED.findall(directive_text)]


def resolve(uri, importer):
    """The repository path a URI names from the file `importer`, PKG_LEPIC, or None (dart:, other
    packages)."""
    if uri.startswith(PKG_PREFIX):
        return norm(f"{APP}/lib/{uri[len(PKG_PREFIX):]}")
    if uri.startswith("package:lepic/"):
        return PKG_LEPIC
    if ":" in uri:
        return None
    return norm(os.path.join(os.path.dirname(importer), uri))


def literals(body):
    """String literals of a Dart source (single-line ones; enough for paths)."""
    return [a or b for a, b in _QUOTED.findall(body)]


def data_deps(body, path, exists):
    """(files, folders) a Dart file names by literal. `exists(p)` returns 'f', 'd' or None."""
    files, dirs = set(), set()
    cands = []
    for lit in literals(body):
        if "/" not in lit or "://" in lit or " " in lit or not _PATHISH.match(lit):
            continue
        cut = lit.find("$")
        if cut >= 0:
            lit = os.path.dirname(lit[:cut])
            if not lit:
                continue
        cands.append(lit)
    cands.extend(_DIR_CALL.findall(body))
    here = os.path.dirname(path)
    for lit in cands:
        for base in (APP, here):
            p = norm(os.path.join(base, lit))
            if p.startswith(".."):
                continue
            kind = exists(p)
            if kind == "f":
                files.add(p)
            elif kind == "d":
                dirs.add(p)
    return files, dirs


class Graph:
    """The dependency graph of every Dart file under DART_ROOTS."""

    def __init__(self, root, repo_files):
        """`root`: the repository; `repo_files`: its tracked and untracked (not ignored) files."""
        self.root = root
        self.files = set(repo_files)
        self.dirs = set()
        for f in self.files:
            d = os.path.dirname(f)
            while d and d not in self.dirs:
                self.dirs.add(d)
                d = os.path.dirname(d)
        self.edges = {}  # dart file -> set of dart files (or PKG_LEPIC)
        self.data_files = {}  # dart file -> set of files
        self.data_dirs = {}  # dart file -> set of folders
        self.sources = {}  # dart file -> text
        for f in sorted(self.files):
            if f.endswith(".dart") and f.startswith(DART_ROOTS):
                self._read(f)
        self._closures = {}

    def _exists(self, p):
        if p in self.files:
            return "f"
        if p in self.dirs:
            return "d"
        return None

    def _read(self, f):
        try:
            with open(os.path.join(self.root, f), encoding="utf-8", errors="replace") as fh:
                src = fh.read()
        except OSError:
            return
        self.sources[f] = src
        heads, body = directives(src)
        deps = set()
        for d in heads:
            for u in uris(d):
                r = resolve(u, f)
                if r:
                    deps.add(r)
        self.edges[f] = deps
        self.data_files[f], self.data_dirs[f] = data_deps(body, f, self._exists)

    def tests(self):
        return sorted(f for f in self.sources if f.startswith(TEST_DIR + "/") and f.endswith("_test.dart"))

    def configs(self, test):
        """The flutter_test_config.dart files flutter loads for `test`."""
        out = []
        d = os.path.dirname(test)
        while d.startswith(TEST_DIR):
            c = f"{d}/flutter_test_config.dart"
            if c in self.files:
                out.append(c)
            d = os.path.dirname(d)
        return out

    def closure(self, test):
        """Every Dart file (and PKG_LEPIC) `test` reaches, itself and its configs included."""
        if test in self._closures:
            return self._closures[test]
        seen = set()
        stack = [test, *self.configs(test)]
        while stack:
            f = stack.pop()
            if f in seen:
                continue
            seen.add(f)
            stack.extend(self.edges.get(f, ()))
        self._closures[test] = seen
        return seen

    def deps(self, test):
        """(dart closure, data files, data folders) of a test."""
        clo = self.closure(test)
        files, dirs = set(), set()
        for f in clo:
            files |= self.data_files.get(f, set())
            dirs |= self.data_dirs.get(f, set())
        return clo, files, dirs

    def hit(self, test, changed, data_only=()):
        """The first changed path (sorted) that affects `test`, or None. Paths in `data_only`
        count only as data, not through imports."""
        clo, files, dirs = self.deps(test)
        for c in sorted(changed):
            if (c in clo and c not in data_only) or c in files or any(c.startswith(d + "/") for d in dirs):
                return c
        return None

    def test_side_text(self, test):
        """The text of the test's closure files under app/test (where test code names keys)."""
        return "\n".join(self.sources.get(f, "") for f in sorted(self.closure(test))
                         if f.startswith(TEST_DIR + "/"))
