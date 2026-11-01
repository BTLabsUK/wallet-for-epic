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
        self.success = None
        self.other = []  # lines that were not events (compile output, crashes)

    def rel(self, path):
        if not path:
            return ""
        if path.startswith("file://"):
            path = path[len("file://"):]
        if os.path.isabs(path):
            path = os.path.relpath(path, self.app_root)
        return path.replace(os.sep, "/")

    def feed(self, e):
        kind = e.get("type")
        if kind == "suite":
            s = e.get("suite") or {}
            if "id" in s and s.get("path"):
                self.suites[s["id"]] = self.rel(s["path"])
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
            errs = self.errors.get(tid) or [("(no message)", "")]
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

    def files_green(self, files):
        """The given app-relative test files whose every test passed."""
        bad = {self.file_of(tid) for tid, d in self.done.items() if d.get("result") != "success"}
        seen = set(self.suites.values())
        return [f for f in files if f in seen and f not in bad and self.success is not None]


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
