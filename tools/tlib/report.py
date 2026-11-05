# SPDX-License-Identifier: Apache-2.0
"""flutter test's json reporter events, reduced to what an agent reads: counts, the files that
passed, and each failure's name, file:line and the first lines of its message.

The summary printed on stdout stays short. Each failure's head line uses flutter's own progress
format (`MM:SS +passed ~skipped -failed: <file>: <name> [E]`) and so does the last line
(`All tests passed!` / `Some tests failed.`), which tools/nightly/nightly.py reads from
tools/check.sh's log.
"""
import os
import re

MESSAGE_LINES = 20
SUMMARY_FAILURES = 6
_FRAME = re.compile(r"(?:^|[\s/])(test/[\w./-]+\.dart)[ :](\d+)(?::\d+)?")
_GOLDEN = re.compile(r"Golden \"|golden file")
# A fix command a test names in its message (l10n_test, the golden comparator, …).
_FIX = re.compile(r"tools/(?:t goldens --update|l10n sync|l10n check)[^\s,;)`]*(?: \S+\.(?:png|dart))?")


class Run:
    """Collects the events of one `flutter test --reporter json` run."""

    def __init__(self, app_root):
        self.app_root = app_root
        self.suites = {}  # suite id -> app-relative path
        self.tests = {}  # test id -> event "test"
        self.errors = {}  # test id -> [(error, stack)]
        self.done = {}  # test id -> testDone event
        self.prints = {}  # test id -> printed messages (a widget test's exception report)
        self.offset = 0  # added to the ids of a later flutter process's events (a retry)
        self.suite_time = {}  # suite id -> ms since the run started
        self.done_time = {}  # test id -> ms
        self.success = None
        self.other = []  # lines that were not events (compile output, crashes)
        self.aborted = None  # {file, message, count} when tools/t stopped the run (tlib/watch.py)

    def rel(self, path):
        if not path:
            return ""
        if path.startswith("file://"):
            path = path[len("file://"):]
        if os.path.isabs(path):
            path = os.path.relpath(path, self.app_root)
        return path.replace(os.sep, "/")

    def drop_files(self, files):
        """Forget the given files' suites and tests (their first attempt, before a retry)."""
        files = set(files)
        sids = {sid for sid, p in self.suites.items() if p in files}
        tids = {tid for tid, t in self.tests.items() if t.get("suiteID") in sids}
        for sid in sids:
            self.suites.pop(sid, None)
            self.suite_time.pop(sid, None)
        for tid in tids:
            for d in (self.tests, self.errors, self.done, self.prints, self.done_time):
                d.pop(tid, None)

    def feed(self, e):
        if self.offset:
            e = shift_ids(e, self.offset)
        kind = e.get("type")
        if kind == "suite":
            s = e.get("suite") or {}
            if "id" in s and s.get("path"):
                self.suites[s["id"]] = self.rel(s["path"])
                if "time" in e:
                    self.suite_time[s["id"]] = e["time"]
        elif kind == "testStart":
            t = e.get("test") or {}
            if "id" in t:
                self.tests[t["id"]] = t
        elif kind == "error":
            self.errors.setdefault(e.get("testID"), []).append((e.get("error") or "", e.get("stackTrace") or ""))
        elif kind == "print":
            self.prints.setdefault(e.get("testID"), []).append(e.get("message") or "")
        elif kind == "testDone":
            self.done[e.get("testID")] = e
            if "time" in e:
                self.done_time[e.get("testID")] = e["time"]
        elif kind == "done":
            self.success = bool(e.get("success"))

    def feed_line(self, line):
        import json
        line = line.strip()
        if not line:
            return
        if line.startswith("{"):
            try:
                e = json.loads(line)
            except ValueError:
                e = None
            if isinstance(e, dict):
                self.feed(e)
                return
        self.other.append(line)
        del self.other[:-40]

    def counts(self):
        passed = skipped = failed = 0
        for tid, d in self.done.items():
            failed_now = d.get("result") != "success"
            if failed_now:
                failed += 1
            elif d.get("hidden"):
                continue
            elif d.get("skipped"):
                skipped += 1
            else:
                passed += 1
        return {"passed": passed, "skipped": skipped, "failed": failed}

    def file_of(self, tid):
        t = self.tests.get(tid) or {}
        return self.suites.get(t.get("suiteID"), "")

    def failures(self):
        out = []
        for tid, d in self.done.items():
            if d.get("result") == "success":
                continue
            t = self.tests.get(tid) or {}
            f = self.file_of(tid)
            name = t.get("name") or ""
            if name.startswith("loading "):
                name = "loading the file (it does not compile or throws in main)"
            errs = self.errors.get(tid) or [("(no message: the test process ended without a result)", "")]
            text = "\n".join(e for e, _ in errs).strip()
            stack = "\n".join(s for _, s in errs)
            caught = exception_report("\n".join(self.prints.get(tid, [])))
            if caught and (text.startswith("Test failed. See exception logs above") or not text):
                # flutter_test printed the exception; the error event only points at it
                text, stack = caught[0], caught[1] + "\n" + stack
            line = _line_in(stack, f) or t.get("root_line") or t.get("line")
            msg_lines = text.splitlines()[:MESSAGE_LINES]
            fix = None
            m = _FIX.search(text)
            if m:
                fix = m.group(0)
            elif _GOLDEN.search(text):
                fix = f"tools/t goldens --update app/{f}"
            out.append({"file": f, "line": line, "name": name, "message": "\n".join(msg_lines),
                        "fix": fix})
        out.sort(key=lambda x: (x["file"], x["line"] or 0, x["name"]))
        return out

    def file_outcomes(self, files, rc=0):
        """{app-relative file: {result, reason, failing, duration_s}} for the given files of one run.

        `pass`: the file ran and every test passed. `fail`: a test reported an error that is the
        test's own (an expect, an exception, code that does not compile). `infra`: the file failed
        with no such error, only the process dying, not starting or losing its connection, or the
        file never finished in a run that ended abnormally (`rc` not 0). A file with both is
        `fail`.
        """
        by_file = {}
        for tid, d in self.done.items():
            by_file.setdefault(self.file_of(tid), []).append((tid, d))
        started = {}
        for tid in self.tests:
            started.setdefault(self.file_of(tid), set()).add(tid)
        out = {}
        seen = set(self.suites.values())
        for f in files:
            tests = by_file.get(f, [])
            bad = [(tid, d) for tid, d in tests if d.get("result") != "success"]
            unfinished = [tid for tid in started.get(f, ()) if tid not in self.done]
            failing, kinds, reasons = [], set(), []
            for tid, d in bad:
                t = self.tests.get(tid) or {}
                errs = self.errors.get(tid) or []
                text = "\n".join(e for e, _ in errs) + "\n" + "\n".join(self.prints.get(tid, []))
                kind = classify_error(text) if errs else "infra"
                kinds.add(kind)
                name = t.get("name") or ""
                failing.append("loading the file" if name.startswith("loading ") else name)
                if kind == "infra":
                    reasons.append(_first_line(text) or "the test process ended without a result")
            if unfinished and rc != 0:
                kinds.add("infra")
                reasons.append("the test process ended before the file finished")
            if f not in seen and not tests and rc != 0:
                kinds.add("infra")
                reasons.append(f"flutter test exited {rc} before the file ran")
            if "fail" in kinds:
                out[f] = {"result": "fail", "failing": failing, "reason": ""}
            elif "infra" in kinds:
                out[f] = {"result": "infra", "failing": failing, "reason": reasons[0][:200]}
            elif f in seen and tests:
                out[f] = {"result": "pass", "failing": [], "reason": ""}
            else:
                continue
            out[f]["duration_s"] = self.file_seconds(f)
        return out

    def file_seconds(self, f):
        """Seconds from the file's suite start to its last test's end, from the event times."""
        sids = [sid for sid, p in self.suites.items() if p == f]
        start = min((self.suite_time[s] for s in sids if s in self.suite_time), default=None)
        end = max((self.done_time[tid] for tid in self.done if self.file_of(tid) == f
                   and tid in self.done_time), default=None)
        return round((end - start) / 1000, 1) if start is not None and end is not None else 0.0

    def files_green(self, files):
        """The given app-relative test files whose every test passed."""
        bad = {self.file_of(tid) for tid, d in self.done.items() if d.get("result") != "success"}
        seen = set(self.suites.values())
        return [f for f in files if f in seen and f not in bad and self.success is not None]


# What flutter prints when the process that runs a test file died, never started or lost its
# connection: the machine, not the test (tools/tlib/infra.py).
INFRA_ERROR = re.compile(
    r"The Dart compiler exited unexpectedly|"
    r"Shell subprocess (?:ended|crashed|cleanup)|flutter_tester|Exited \(|exited with code|"
    r"Connection (?:closed|reset)|SocketException|WebSocket|Broken pipe|"
    r"Out of memory|Cannot allocate memory|OutOfMemory|"
    r"Unable to (?:start|spawn)|Failed to (?:start|spawn)|Process .* (?:died|was killed|crashed)|"
    r"\.dill\b.*(?:No such file|Could not|corrupt|truncated)|"
    r"(?:No such file|Could not|corrupt|truncated).*\.dill\b|"
    r"kernel (?:file|snapshot).*(?:missing|corrupt|invalid)|frontend_server.*(?:crashed|died|exited)|"
    r"Bad state: (?:StreamSink|Stream has already been|Cannot add|The test process)|"
    r"Unexpected end of file|SIGKILL|SIGSEGV|signal 9\b|signal 11\b", re.I)
# Dart code that does not compile, or a test that threw: the code's own failure, never infra.
CODE_ERROR = re.compile(r"\.dart:\d+:\d+: Error:|\bError: |Expected: |Actual: |Test failed\. See exception|"
                        r"The following .* was thrown|TestFailure|_?AssertionError|Golden \"")


def classify_error(text):
    """'infra' for a failure message that is about the test process, else 'fail'."""
    if CODE_ERROR.search(text) and not INFRA_ERROR.search(text):
        return "fail"
    if CODE_ERROR.search(text) and re.search(r"\.dart:\d+:\d+: Error:|Expected: |TestFailure|Test failed\.", text):
        return "fail"
    return "infra" if INFRA_ERROR.search(text) else "fail"


def exception_report(printed):
    """(message, stack) of the exception report flutter_test prints for a widget test
    (`══╡ EXCEPTION CAUGHT BY …`), or None."""
    start = printed.find("══╡ EXCEPTION CAUGHT")
    if start < 0:
        return None
    body = printed[start:].split("\n")[1:]
    msg, stack, in_stack = [], [], False
    for line in body:
        if line.startswith("When the exception was thrown"):
            in_stack = True
            continue
        if line.startswith("The test description was") or line.startswith("═"):
            break
        (stack if in_stack else msg).append(line)
    msg = [x for x in msg if not x.startswith("The following ") or len(msg) == 1]
    return "\n".join(msg).strip(), "\n".join(stack)


def _line_in(stack, file):
    """The line of `file` in a stack trace (where the expect failed), else of any test file."""
    best = None
    for m in _FRAME.finditer(stack or ""):
        if m.group(1) == file:
            return int(m.group(2))
        if best is None:
            best = int(m.group(2))
    return best


def shift_ids(e, n):
    """A copy of an event with its suite and test ids moved by n (two processes' ids collide)."""
    e = dict(e)
    for k in ("testID",):
        if isinstance(e.get(k), int):
            e[k] += n
    if isinstance(e.get("suite"), dict) and isinstance(e["suite"].get("id"), int):
        e["suite"] = {**e["suite"], "id": e["suite"]["id"] + n}
    if isinstance(e.get("test"), dict):
        t = dict(e["test"])
        for k in ("id", "suiteID"):
            if isinstance(t.get(k), int):
                t[k] += n
        e["test"] = t
    return e


def _first_line(text):
    for line in text.splitlines():
        if line.strip():
            return line.strip()
    return ""


def clock(seconds):
    s = int(round(seconds))
    return f"{s // 60:02d}:{s % 60:02d}"


def summary(title, status, counts, failures, seconds, extra=(), list_all=False):
    """The lines printed on stdout: at most about 20 unless `list_all` (tools/t full, read by the
    nightly), which names every failing test, still with messages only for the first ones."""
    lines = [title]
    lines.extend(extra)
    prog = f"{clock(seconds)} +{counts['passed']}" + (f" ~{counts['skipped']}" if counts["skipped"] else "")
    prog += f" -{counts['failed']}" if counts["failed"] else ""
    shown = failures if list_all else failures[:SUMMARY_FAILURES]
    for i, f in enumerate(shown):
        lines.append(f"{prog}: {f['file']}: {f['name']} [E]")
        if i < SUMMARY_FAILURES:
            first = [x for x in f["message"].splitlines() if x.strip()][:2]
            where = f"{f['file']}:{f['line']}" if f["line"] else f["file"]
            lines.append(f"    at {where}" + (f"  {first[0].strip()[:150]}" if first else ""))
            if len(first) > 1:
                lines.append(f"    {first[1].strip()[:150]}")
            if f.get("fix"):
                lines.append(f"    fix: {f['fix']}")
    if len(failures) > len(shown):
        lines.append(f"    … {len(failures) - len(shown)} more failures in .test-results/latest.json")
    lines.append(f"{prog}: " + ("All tests passed!" if status == "green" else "Some tests failed."))
    return lines
