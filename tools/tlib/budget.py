# SPDX-License-Identifier: Apache-2.0
"""What one test file and one tools/t run may cost (docs/TESTING.md, "Budgets").

Every run is measured from /proc: wall time and peak memory of each flutter_tester, one per test
file. A new or changed test file over WALL_S or PEAK_MB fails the run, with or without the result
cache, until it is cheaper or tools/test-budget.allow lists it. The run itself holds at most
MAX_JOBS files at once and RUN_RSS_MB of test memory; over that it stops. No flag or environment
variable lifts these.
"""
import json
import os
import re
import threading
import time

WALL_S = 30
PEAK_MB = 1500
MAX_JOBS = 6
RUN_RSS_MB = 14000
POLL_S = 1.0
ALLOW = "tools/test-budget.allow"
OVER = "budget-over.json"
_IMPORT = re.compile(r"import 'file://([^']+_test\.dart)' as test;")


def read_allow(root):
    """{app-relative test: (wall ceiling, 'slow' or 'keep', reason)}. A line without a reason is an
    error: an exception says why."""
    out = {}
    try:
        with open(os.path.join(root, ALLOW), encoding="utf-8") as f:
            lines = f.read().splitlines()
    except OSError:
        return out
    for n, line in enumerate(lines, 1):
        if not line.strip() or line.startswith("#"):
            continue
        parts = line.split(None, 3)
        if len(parts) < 4 or not parts[1].isdigit() or parts[2] not in ("slow", "keep"):
            raise ValueError(f"{ALLOW}:{n}: want <test> <wall s> <slow|keep> <reason>")
        out[parts[0]] = (int(parts[1]), parts[2], parts[3])
    return out


def drop_slow(tests, changed, allow):
    """(tests to run, slow tests left to `tools/t full`). A slow test changed itself stays."""
    keep, left = [], []
    for t in tests:
        rel = t[len("app/"):] if t.startswith("app/") else t
        (left if rel in allow and allow[rel][1] == "slow" and t not in changed else keep).append(t)
    return keep, left


def over(sample, allow):
    """Why this measured file breaks its budget, or None. `sample` has file, wall_s, peak_mb."""
    ceiling = allow.get(sample["file"], (WALL_S,))[0]
    if sample["wall_s"] > ceiling:
        return f"wall {sample['wall_s']:.0f} s, limit {ceiling} s"
    if sample["peak_mb"] > PEAK_MB:
        return f"peak memory {sample['peak_mb']:.0f} MB, limit {PEAK_MB} MB"
    return None


def gate(results_dir, seen, changed, allow):
    """Keeps the verdict of each measured file across runs (a cached green run measures nothing)
    and returns the messages of the changed test files over budget."""
    path = os.path.join(results_dir, OVER)
    try:
        with open(path, encoding="utf-8") as f:
            kept = json.load(f)
    except (OSError, ValueError):
        kept = {}
    kept.update({s["file"]: s for s in seen})
    with open(path, "w", encoding="utf-8") as f:
        json.dump(kept, f, indent=1)
    out = []
    for t, s in sorted(kept.items()):
        why = over(s, allow)
        if why and f"app/{t}" in changed:
            out.append(f"app/{t}: {why}")
    return out


class Sampler:
    """Reads /proc while a run lasts. `on_limit(message)` is called once when the run's testers
    hold more than `rss_limit_mb` together."""

    def __init__(self, app, on_limit, rss_limit_mb=RUN_RSS_MB, proc="/proc", poll=POLL_S):
        self.mark = f"--packages={app}/.dart_tool/"
        self.app = app
        self.on_limit = on_limit
        self.rss_limit_mb = rss_limit_mb
        self.proc = proc
        self.poll = poll
        self.live = {}
        self.seen = []
        self.peak_run_mb = 0
        self.fired = False
        self._stop = threading.Event()
        self._thread = threading.Thread(target=self._loop, daemon=True)

    def start(self):
        self._thread.start()
        return self

    def stop(self):
        self._stop.set()
        self._thread.join(5)
        self.tick(ended_all=True)
        return self.seen

    def _loop(self):
        while not self._stop.wait(self.poll):
            self.tick()

    def tick(self, ended_all=False):
        now = time.time()
        found = {} if ended_all else self._read()
        for pid, (file, hwm_mb, rss_mb) in found.items():
            r = self.live.setdefault(pid, {"file": file, "start": now, "peak_mb": 0, "rss_mb": 0})
            r.update(file=r["file"] or file, peak_mb=max(r["peak_mb"], hwm_mb), rss_mb=rss_mb, last=now)
        for pid in [p for p in self.live if p not in found]:
            r = self.live.pop(pid)
            if r["file"]:
                self.seen.append({"file": r["file"], "wall_s": r["last"] - r["start"], "peak_mb": r["peak_mb"]})
        total = sum(r["rss_mb"] for r in self.live.values())
        self.peak_run_mb = max(self.peak_run_mb, total)
        if total > self.rss_limit_mb and not self.fired:
            self.fired = True
            big = max(self.live.values(), key=lambda r: r["rss_mb"])
            self.on_limit(f"run memory {total:.0f} MB over the limit of {self.rss_limit_mb} MB; "
                          f"largest file: {big['file']} at {big['rss_mb']:.0f} MB")

    def _read(self):
        found = {}
        try:
            names = os.listdir(self.proc)
        except OSError:
            return found
        for name in names:
            if not name.isdigit():
                continue
            try:
                with open(f"{self.proc}/{name}/cmdline", "rb") as f:
                    cmd = f.read().decode(errors="replace").split("\0")
                if not cmd[0].endswith("flutter_tester") or not any(a.startswith(self.mark) for a in cmd):
                    continue
                hwm = rss = 0
                with open(f"{self.proc}/{name}/status") as f:
                    for line in f:
                        if line.startswith("VmHWM:"):
                            hwm = int(line.split()[1]) / 1024
                        elif line.startswith("VmRSS:"):
                            rss = int(line.split()[1]) / 1024
                found[int(name)] = (self._file(cmd), hwm, rss)
            except (OSError, IndexError, ValueError):
                continue
        return found

    def _file(self, cmd):
        """The test a tester runs, from the listener flutter writes next to its dill."""
        for a in reversed(cmd):
            if a.endswith(".dill"):
                try:
                    with open(a[:-5], encoding="utf-8") as f:
                        m = _IMPORT.search(f.read())
                except OSError:
                    return None
                if m and m.group(1).startswith(self.app + "/"):
                    return m.group(1)[len(self.app) + 1:]
        return None
