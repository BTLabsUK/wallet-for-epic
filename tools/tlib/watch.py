# SPDX-License-Identifier: Apache-2.0
"""What tools/t checks before and while a run (docs/TESTING.md, "tools/t").

stale_pins(): the git-ignored clones tools/lepic.sh makes must be at their pins. A clone left at
an old commit after a pin bump makes every test file fail to load, slowly ("The Dart compiler
exited unexpectedly"), so tools/t refuses to start instead.

Watch: reads flutter's json reporter events as they come. It counts the files that failed to
load (the compiler died, or the file does not compile) so that tools/t stops a run that fails
for one systematic reason after a few files, and it makes the progress line tools/t prints
every PROGRESS_S seconds, so a redirected log is never silent.
"""
import os
import re
import subprocess

# The pin files that map to a clone, and where tools/lepic.sh keeps it (its `binding` and
# `clone`). tools/lepic.sh build checks both clones the same way (check_clone), with or without
# LEPIC_SHARED: the shared clone is made from app/third_party/lepic, so that one is the one to check.
PINS = (
    ("tools/lepic-flutter.rev", "app/third_party/lepic-flutter"),
    ("tools/lepic.rev", "app/third_party/lepic"),
)
SYNC = "tools/lepic.sh sync"
PROGRESS_S = 30
FAILFAST_DEFAULT = 3
# What a file that never loaded reports, on its `loading <file>` test.
LOAD_FAILED = re.compile(r"The Dart compiler exited unexpectedly|Failed to load")


def stale_pins(root):
    """A message per clone that is not at its pin: the clone, its HEAD, the pin and the command.
    No app/third_party at all is not stale: tools/t's prepare() syncs a new worktree."""
    if not os.path.isdir(os.path.join(root, "app", "third_party")):
        return []
    out = []
    for rev_file, rel in PINS:
        try:
            with open(os.path.join(root, rev_file), encoding="utf-8") as f:
                pin = f.read().strip()
        except OSError:
            continue
        clone = os.path.join(root, rel)
        if not os.path.isdir(os.path.join(clone, ".git")) and not os.path.isfile(os.path.join(clone, ".git")):
            out.append(f"no clone at {rel} ({rev_file} pins {pin[:12]}): run {SYNC}")
            continue
        r = subprocess.run(["git", "-C", clone, "rev-parse", "HEAD"], capture_output=True, text=True,
                           check=False)
        head = r.stdout.strip() if r.returncode == 0 else "(no HEAD)"
        if head != pin:
            out.append(f"{rel} is at {head[:12]}, not at the pin {pin[:12]} in {rev_file}: run {SYNC}")
    return out


def failfast_threshold(environ=None):
    """WFE_T_FAILFAST: stop after this many files failed to load; 0 never stops. Default 3."""
    v = (environ if environ is not None else os.environ).get("WFE_T_FAILFAST", "").strip()
    if not v:
        return FAILFAST_DEFAULT
    if not v.isdigit():
        raise ValueError(f"WFE_T_FAILFAST={v}: a number of files (0 never stops)")
    return int(v)


def clock(seconds):
    """'4m10s', '45s', '1h02m'."""
    s = int(seconds)
    if s < 60:
        return f"{s}s"
    if s < 3600:
        return f"{s // 60}m{s % 60:02d}s"
    return f"{s // 3600}h{s % 3600 // 60:02d}m"


class Watch:
    """The run so far, from its events: files started, done and failed, and load failures.
    Its fields are plain ints and sets that tools/t's progress thread only reads."""

    def __init__(self, total, threshold=FAILFAST_DEFAULT):
        self.total = total
        self.threshold = threshold
        self.suites = {}  # suite id -> path
        self.suite_of = {}  # test id -> suite id
        self.loading = set()  # test ids of `loading <file>` tests
        self.running = {}  # suite id -> test ids started, not done
        self.failed = set()  # suite ids with a failed test
        self.load_failures = []  # [(path, message)], one per file, in order
        self.tripped = False

    def feed(self, e):
        """Takes one event; True once, on the event that brings the load failures to the threshold."""
        kind = e.get("type")
        if kind == "suite":
            s = e.get("suite") or {}
            if "id" in s:
                self.suites[s["id"]] = s.get("path") or ""
        elif kind == "testStart":
            t = e.get("test") or {}
            sid = t.get("suiteID")
            self.suite_of[t.get("id")] = sid
            self.running.setdefault(sid, set()).add(t.get("id"))
            if (t.get("name") or "").startswith("loading "):
                self.loading.add(t.get("id"))
        elif kind == "testDone":
            tid = e.get("testID")
            sid = self.suite_of.get(tid)
            self.running.get(sid, set()).discard(tid)
            if e.get("result") not in (None, "success"):
                self.failed.add(sid)
        elif kind == "error":
            tid = e.get("testID")
            sid = self.suite_of.get(tid)
            msg = e.get("error") or ""
            path = self.suites.get(sid, "")
            if tid in self.loading and LOAD_FAILED.search(msg) and \
                    all(p != path for p, _ in self.load_failures):
                self.load_failures.append((path, msg))
                if self.threshold and not self.tripped and len(self.load_failures) >= self.threshold:
                    self.tripped = True
                    return True
        return False

    def files_done(self):
        """Files that started a test and have none running (a file between two tests counts too)."""
        return sum(1 for tids in list(self.running.values()) if not tids)

    def line(self, seconds):
        """tools/t's progress line: `tools/t: 120/468 files done, 3 failed, 4m10s`."""
        return (f"tools/t: {self.files_done()}/{self.total} files done, {len(self.failed)} failed, "
                f"{clock(seconds)}")
