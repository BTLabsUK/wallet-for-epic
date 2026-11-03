# SPDX-License-Identifier: Apache-2.0
"""The run history of tools/t: one JSON line per test file per run, kept so a flake rate can be
measured (`tools/t flaky`, docs/TESTING.md).

Where: ~/.cache/wfe-test-history.jsonl, or WFE_TEST_HISTORY. A line:
  ts, worktree, sha, mode (full | affected | file | goldens), key (the file's cache key),
  file (relative to app/), result (pass | fail | infra), duration_s, failing (test names),
  attempt (1, or 2 for the retry of an infrastructure failure), reason (infra only).
The file is bounded: past KEEP_LINES + SLACK_LINES lines it is cut to its last KEEP_LINES.

A flake is a file (or a test in it) that both failed and passed with the same cache key: the same
inputs gave different results. An `infra` result is not a test result and is left out of that.
"""
import fcntl
import json
import os
import time

KEEP_LINES = 50000
SLACK_LINES = 5000
# Lines are longer than this on average; below this size the file cannot hold too many.
MIN_LINE_BYTES = 120
PATH = os.environ.get("WFE_TEST_HISTORY", os.path.expanduser("~/.cache/wfe-test-history.jsonl"))


def path():
    return os.environ.get("WFE_TEST_HISTORY", PATH)


def append(records, hist=None):
    """Adds the records (dicts) to the history; never raises (a full disk must not fail a run)."""
    hist = hist or path()
    if not records:
        return
    try:
        os.makedirs(os.path.dirname(os.path.abspath(hist)), exist_ok=True)
        data = "".join(json.dumps(r, separators=(",", ":"), sort_keys=True) + "\n" for r in records)
        with open(hist, "a+", encoding="utf-8") as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            f.write(data)
            f.flush()
            if os.path.getsize(hist) > (KEEP_LINES + SLACK_LINES) * MIN_LINE_BYTES:
                _rotate(f, hist)
    except (OSError, ValueError):
        pass


def _rotate(f, hist):
    """Under the lock: cut to the last KEEP_LINES lines when there are more than KEEP + SLACK."""
    f.seek(0)
    lines = f.readlines()
    if len(lines) <= KEEP_LINES + SLACK_LINES:
        return
    tmp = hist + ".tmp"
    with open(tmp, "w", encoding="utf-8") as out:
        out.writelines(lines[-KEEP_LINES:])
    os.replace(tmp, hist)
    # `f` still holds the old inode; the next append reopens the path.


def read(hist=None, since=None):
    """The history's records, oldest first; `since` is an epoch second. Bad lines are skipped."""
    hist = hist or path()
    out = []
    try:
        with open(hist, encoding="utf-8") as f:
            for line in f:
                try:
                    r = json.loads(line)
                except ValueError:
                    continue
                if not isinstance(r, dict):
                    continue
                if since is not None and r.get("epoch", 0) < since:
                    continue
                out.append(r)
    except OSError:
        pass
    return out


def record(run_at, worktree, sha, mode, key, file, result, duration_s, failing=(), attempt=1,
           reason=None):
    r = {"ts": time.strftime("%Y-%m-%dT%H:%M:%S%z", time.localtime(run_at)), "epoch": int(run_at),
         "worktree": worktree, "sha": sha, "mode": mode, "key": key, "file": file,
         "result": result, "duration_s": round(duration_s, 1), "failing": list(failing),
         "attempt": attempt}
    if reason:
        r["reason"] = reason
    return r


def flaky(records):
    """Files and tests that both failed and passed with the same cache key.

    Returns [{file, test, key_count, fails, passes, last_fail}] sorted by fails, most first.
    `test` is None for a file-level flake (the file passed once and failed another time, whatever
    the failing test) and a test name when failing tests of one key are named. Records of another
    result than pass or fail (infra) are ignored; a pass is a file-level pass.
    """
    by_key = {}
    for r in records:
        if r.get("result") in ("pass", "fail"):
            by_key.setdefault((r.get("file"), r.get("key")), []).append(r)
    files = {}
    tests = {}
    for (file, key), rs in by_key.items():
        passes = [r for r in rs if r["result"] == "pass"]
        fails = [r for r in rs if r["result"] == "fail"]
        if not passes or not fails:
            continue
        e = files.setdefault(file, {"file": file, "test": None, "keys": 0, "fails": 0, "passes": 0,
                                    "last_fail": ""})
        e["keys"] += 1
        e["fails"] += len(fails)
        e["passes"] += len(passes)
        e["last_fail"] = max(e["last_fail"], max(r.get("ts", "") for r in fails))
        for r in fails:
            for name in r.get("failing") or ["(file)"]:
                t = tests.setdefault((file, name), {"file": file, "test": name, "keys": {},
                                                    "fails": 0, "last_fail": ""})
                t["keys"][key] = len(passes)
                t["fails"] += 1
                t["last_fail"] = max(t["last_fail"], r.get("ts", ""))
    out = list(files.values())
    for t in tests.values():
        t["passes"] = sum(t["keys"].values())
        t["keys"] = len(t["keys"])
        out.append(t)
    out.sort(key=lambda x: (-x["fails"], x["file"], x["test"] or ""))
    return out


def flaky_index(records):
    """{(file, test or None): entry} for the nightly: is this failing test known to flake?"""
    return {(e["file"], e["test"]): e for e in flaky(records)}
