# SPDX-License-Identifier: Apache-2.0
"""Order of the test files for a whole `flutter test` run (tools/flutter-test-all.sh).

`flutter test` runs its files a few at a time in the order given. A few files take minutes, and
started last they run alone at the end, so the slowest go first: by how long each file took in
earlier runs on this machine, files with no time yet first of all (they may be slow), then the
name. The order changes nothing but the order: the same files run, each in its own test process.

  flutter_test_order.py order <times.json>            files on stdin, ordered on stdout
  flutter_test_order.py record <times.json> <run.json> add a run's times (flutter's json reporter)

<times.json> is {"<file>": seconds}; a file missing, unreadable or bad counts as empty.
"""
import json
import math
import os
import sys
import tempfile


def read_times(path):
    """The times file; an entry that is not a finite number of seconds is left out."""
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, ValueError):
        return {}
    times = {}
    for k, v in data.items() if isinstance(data, dict) else ():
        try:
            t = float(v)
        except (TypeError, ValueError):
            continue
        if math.isfinite(t):
            times[k] = t
    return times


def order(files, times):
    """Files without a time first, then the slowest first; the name breaks ties."""
    return sorted(files, key=lambda f: (f in times, -times.get(f, 0.0), f))


def run_times(lines, app_root):
    """{file relative to app_root: seconds} from flutter's json reporter lines: from the suite's
    start to its last test's end (loading included)."""
    path_of, start, end, suite_of = {}, {}, {}, {}
    for line in lines:
        try:
            e = json.loads(line)
        except ValueError:
            continue
        kind = e.get("type") if isinstance(e, dict) else None
        if kind == "suite":
            s = e.get("suite") or {}
            if s.get("path") and "id" in s and "time" in e:
                path_of[s["id"]] = os.path.relpath(s["path"], app_root)
                start[s["id"]] = e["time"]
        elif kind == "testStart":
            t = e.get("test") or {}
            if "id" in t:
                suite_of[t["id"]] = t.get("suiteID")
        elif kind == "testDone":
            sid = suite_of.get(e.get("testID"))
            if sid in start and "time" in e:
                end[sid] = max(end.get(sid, 0), e["time"])
    return {path_of[s]: (end[s] - start[s]) / 1000 for s in end if s in path_of}


def record(times_path, run_path, app_root):
    times = read_times(times_path)
    with open(run_path, encoding="utf-8") as f:
        times.update({k: round(v, 1) for k, v in run_times(f, app_root).items()})
    d = os.path.dirname(os.path.abspath(times_path))
    os.makedirs(d, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=d, prefix=".times.")
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(times, f, indent=0, sort_keys=True)
    os.replace(tmp, times_path)


def main(argv):
    if len(argv) == 3 and argv[1] == "order":
        files = [l.strip() for l in sys.stdin if l.strip()]
        print("\n".join(order(files, read_times(argv[2]))))
        return 0
    if len(argv) == 4 and argv[1] == "record":
        record(argv[2], argv[3], os.getcwd())
        return 0
    print(__doc__, file=sys.stderr)
    return 64


if __name__ == "__main__":
    sys.exit(main(sys.argv))
