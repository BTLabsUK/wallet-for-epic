# SPDX-License-Identifier: Apache-2.0
"""The result cache of tools/t: a test file that passed is not run again while nothing it
depends on has changed, on any worktree of this machine.

A file's key is the sha256 of:
  - KEY_VERSION;
  - the run's context (context_key): app/pubspec.yaml, app/pubspec.lock, app/l10n.yaml, the
    Flutter and Dart versions, the LEPIC pins (tools/lepic.rev, tools/lepic-flutter.rev) and, when
    WFE_DEMO_LEPIC_LIB names a library, that library's bytes; the dart-defines and the test-name
    filter of the run; the WFE_* and DESK_* environment variables the tests read;
  - the path and content hash of every file the test depends on (graph.Graph.deps): its Dart
    import closure and the data files and folders it names.
A green file is stored as <STORE>/<key>.json. Only green is stored: red always runs again.
"""
import bisect
import hashlib
import json
import os
import tempfile
import time

KEY_VERSION = "wfe-t-1"
STORE = os.environ.get("WFE_TEST_RESULTS", os.path.expanduser("~/.cache/wfe-test-results"))
KEEP_DAYS = 30
CONTEXT_FILES = ("app/pubspec.yaml", "app/pubspec.lock", "app/l10n.yaml", "tools/lepic.rev",
                 "tools/lepic-flutter.rev")
ENV_PREFIXES = ("WFE_", "DESK_")
# Variables of the runner itself, not read by tests.
ENV_IGNORED = ("WFE_TEST_RESULTS", "WFE_TEST_TIMES")


def sha256_file(path):
    h = hashlib.sha256()
    try:
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(1 << 20), b""):
                h.update(chunk)
    except OSError:
        return "missing"
    return h.hexdigest()


def flutter_version(flutter_root):
    """The framework and engine revisions and the Dart SDK version, read from the SDK's files
    (`flutter --version` takes a second)."""
    parts = []
    for rel in ("bin/cache/flutter.version.json", "version", "bin/cache/dart-sdk/version",
                "bin/cache/engine.stamp"):
        p = os.path.join(flutter_root, rel)
        if os.path.exists(p):
            parts.append(f"{rel}={sha256_file(p)}")
    return ";".join(parts) or "unknown"


def context_key(root, env, flutter_root, defines=(), name_filter=None):
    h = hashlib.sha256()
    h.update(KEY_VERSION.encode())
    for rel in CONTEXT_FILES:
        h.update(f"\n{rel}={sha256_file(os.path.join(root, rel))}".encode())
    h.update(f"\nflutter={flutter_version(flutter_root)}".encode())
    lib = env.get("WFE_DEMO_LEPIC_LIB")
    h.update(f"\nlepic_lib={sha256_file(lib) if lib else 'none'}".encode())
    for d in sorted(defines):
        h.update(f"\ndefine={d}".encode())
    h.update(f"\nname={name_filter or ''}".encode())
    for k in sorted(env):
        if k.startswith(ENV_PREFIXES) and k not in ENV_IGNORED:
            h.update(f"\nenv {k}={env[k]}".encode())
    return h.hexdigest()


class Hasher:
    """Content hashes of repository files, each read once per run."""

    def __init__(self, root, repo_files):
        self.root = root
        self.files = sorted(repo_files)
        self._memo = {}
        self._under = {}

    def file(self, rel):
        if rel not in self._memo:
            self._memo[rel] = sha256_file(os.path.join(self.root, rel))
        return self._memo[rel]

    def under(self, folder):
        if folder not in self._under:
            prefix = folder + "/"
            i = bisect.bisect_left(self.files, prefix)
            out = []
            while i < len(self.files) and self.files[i].startswith(prefix):
                out.append(self.files[i])
                i += 1
            self._under[folder] = out
        return self._under[folder]


def file_key(context, hasher, closure, data_files, data_dirs):
    paths = set(p for p in closure if not p.startswith("package:"))
    paths |= set(data_files)
    for d in data_dirs:
        paths.update(hasher.under(d))
    h = hashlib.sha256(context.encode())
    for p in sorted(paths):
        h.update(f"\n{p}={hasher.file(p)}".encode())
    return h.hexdigest()


def combined(keys):
    """One key for a set of files (what `cached green (<key>)` prints)."""
    return hashlib.sha256("\n".join(sorted(keys)).encode()).hexdigest()


def lookup(key, store=None):
    path = os.path.join(store or STORE, f"{key}.json")
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def store_green(key, record, store=None):
    store = store or STORE
    os.makedirs(store, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=store, prefix=".tmp.")
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(record, f)
    os.replace(tmp, os.path.join(store, f"{key}.json"))


def prune(store=None, days=KEEP_DAYS):
    """Drop entries older than `days`; cheap enough to run after every run."""
    store = store or STORE
    cutoff = time.time() - days * 86400
    try:
        names = os.listdir(store)
    except OSError:
        return
    for n in names:
        p = os.path.join(store, n)
        try:
            if os.path.getmtime(p) < cutoff:
                os.remove(p)
        except OSError:
            pass
