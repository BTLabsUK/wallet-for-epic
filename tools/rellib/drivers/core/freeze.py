# SPDX-License-Identifier: Apache-2.0
"""What a frozen or erroring app looks like, for every platform's driver (Driver.alive_check).

A freeze is the product's fault: the app froze (ProductFault, cause class PRODUCT) with a bundle,
never a control the driver could not find. Three kinds of evidence, each classified here and read by
the platform's surface:
  1. the platform says the UI is not answering: Android's "isn't responding" dialog or `am_anr`,
     Windows' hung window (SendMessageTimeout WM_NULL), Linux' AT-SPI call to the app unanswered;
  2. the app's own log for this run holds a StackOverflowError or an unhandled exception;
  3. (desktop) a probe that needs the Dart side: the window is resized by one pixel and the app's
     view must follow within the limit, which a stopped Dart isolate cannot do.
The surface-gone cases (the display, the emulator, the rig) stay HarnessGone: they are raised by the
surfaces before they ask for evidence.

Surface hooks (all optional; a surface without them is never frozen):
    froze()      -> None, or the evidence text; answers within FREEZE_S + a little
    log_lines()  -> the app's own log lines written since the last call (this run only)
    evidence()   -> {file name: text} for the bundle (logcat around it, the ANR trace, the app log tail)
"""
import os
import re

from .faults import ProductFault

FREEZE_S = float(os.environ.get("REL_TRUST_FREEZE_S") or "5")

# Android's system dialog and its text (the app's name, then "isn't responding"; either apostrophe)
ANR_DIALOG = re.compile(r"\b(?:isn['\u2019]?t|is not) responding\b", re.I)
# Dart prints "Stack Overflow" for its StackOverflowError; Java's is java.lang.StackOverflowError
STACK_OVERFLOW = re.compile(r"StackOverflowError|\bstack ?overflow\b", re.I)
# The app's own unhandled errors: desktop wfe.log lines (`<ts> ERROR dart.flutter: ...`, `dart.platform:`
# from main_desktop.dart's handlers) and the Dart VM's line in logcat
UNHANDLED = re.compile(r"\sERROR\s+dart\.(?:flutter|platform):|\b[Uu]nhandled [Ee]xception\b")
# Android: `am_anr` (events buffer) or the activity manager's line (main buffer) for the app's package
AM_ANR = re.compile(r"\bam_anr\b.*")
ANR_IN = re.compile(r"\bANR in (\S+)")


class Frozen(ProductFault):
    """The app froze. `evidence` is {file name: text} the lane's bundle keeps."""
    fatal = True  # no app to drive

    def __init__(self, step, what, shot=None, evidence=None):
        super().__init__(step, "the app froze: " + what, shot)
        self.detail, self.evidence = what, evidence or {}


def log_problem(lines):
    """(kind, line) of the first line that is a stack overflow or an unhandled error, else None."""
    for ln in lines:
        if STACK_OVERFLOW.search(ln):
            return "stack overflow", ln
    for ln in lines:
        if UNHANDLED.search(ln):
            return "unhandled error", ln
    return None


def clip(line, n=160):
    return re.sub(r"\s+", " ", line).strip()[:n]


def logcat_problem(text, pkg, pids):
    """(kind, line) for the app in a `logcat -v threadtime` dump (main, events, crash buffers): an ANR
    record naming the package, or a stack overflow / unhandled error on one of the app's pids. Lines of
    other processes (the system's own) are not the app's."""
    anr = None
    for ln in text.splitlines():
        if pkg in ln and (AM_ANR.search(ln) or (ANR_IN.search(ln) and ANR_IN.search(ln).group(1) == pkg)):
            anr = anr or ("ANR", ln)
    if anr:
        return anr
    mine = [ln for ln in text.splitlines() if _pid_of(ln) in pids]
    return log_problem(mine)


def _pid_of(line):
    # threadtime: `MM-DD HH:MM:SS.mmm  PID  TID L tag: msg`
    m = re.match(r"^\d\d-\d\d \d\d:\d\d:\d\d\.\d+\s+(\d+)\s+\d+\s", line)
    return m.group(1) if m else None


def anr_dialog(tree_names):
    """The ANR dialog's text if any of the node names holds it, else None."""
    return next((n for n in tree_names if ANR_DIALOG.search(n)), None)


def tail(path, n=200):
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            return "".join(f.readlines()[-n:])
    except OSError:
        return ""


class LogCursor:
    """The lines of a growing text file written since the last read (this run's; the file may rotate:
    a smaller file is read from its start). `mark()` skips what is there now: lines of an earlier run."""

    def __init__(self, read):
        self.read, self.seen, self.size = read, 0, None   # read() -> the whole file's text, or None

    def mark(self):
        t = self.read()
        self.seen = len(t.splitlines()) if t else 0
        self.size = len(t) if t else 0

    def new(self):
        t = self.read()
        if t is None:
            return []
        lines = t.splitlines()
        if self.size is not None and len(t) < self.size:   # rotated: the new file is this run's too
            self.seen = 0
        self.size = len(t)
        got, self.seen = lines[self.seen:], len(lines)
        return got
