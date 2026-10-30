#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Nightly full check of Epic Wallet's local main, with a Telegram note to the owner when it is red.

What it is: a script started by systemd user units on the build machine (tools/nightly/install.sh puts it in
~/.local/lib/wfe-nightly/ and the units in ~/.config/systemd/user/). It is not an agent: it runs
the full check on main, records the result and reports. It never fixes, pushes, starts agents or
blocks merges.

  nightly.py                     one attempt, as the timer runs it (wfe-nightly.timer, 02:30,
                                 03:30, 04:30 and 05:30 local time): skipped when main's sha was
                                 already tested, or when any build-slot slot is held
  nightly.py --wait-slot         the same, by hand (wfe-nightly-now.service): no busy check, waits
                                 for a build slot
  nightly.py --simulate-red      no check: sends a red report built from a fixture, marked TEST,
                                 and writes it only under test-runs/ (proves the Telegram route)
  nightly.py --parse <log>       print what the parser reads from a log (debugging)

A run:
  1. takes /tmp/epic-build/nightly/.lock (flock); a second run exits at once;
  2. reads refs/heads/main of %h/wallet-for-epic; skips (`skipped: unchanged`) when the last
     completed run (green or red) tested that sha; a sha whose last run was `error` is retried at
     most twice;
  3. moves the run worktree ~/wfe-worktrees/nightly (detached, used by nothing else) to the sha:
     checkout --force, git clean -ffdx except app/third_party/ (the LEPIC clones), lepic.sh sync;
  4. runs `tools/rellib/steps/source-check.sh <run>/source-check` when the commit has it, else
     `tools/check.sh --full` (or plain `tools/check.sh` before --full existed) inside
     dbus-run-session with an unlocked throwaway keyring; always under
     `nice -n 15 ionice -c3 build-slot`, with a 90 min limit (then the run is `error`);
  5. parses the output: `== <step>` lines start steps, `check passed` ends a green run, the step
     check.sh was in when it failed is the failing one, flutter's progress lines give counts and
     `[E]` lines the failing tests;
  6. records /tmp/epic-build/nightly/runs/<UTC stamp>-<sha8>/{check.log,result.json} (last 7 kept),
     latest.json (newest completed run), summary.txt (one line), attempts.log (every attempt,
     skips too) and state.json (last green sha, error retries, weekly note);
  7. reports through relmsg to the owner's private chat: red or a broken run = a short release in the
     relay with one notifying alert; green = silent, except a silent "still green" note once a
     week. relmsg failures never fail the run; they are recorded in result.json `notified`;
  8. runs `tools/lepic.sh prune-shared` when the commit has it, ignoring its result.
Python 3 standard library only.
"""

import argparse
import datetime as dt
import fcntl
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import threading
import time
from pathlib import Path

HOME = Path.home()
REPO = Path(os.environ.get("WFE_NIGHTLY_REPO", HOME / "wallet-for-epic"))
WORKTREE = Path(os.environ.get("WFE_NIGHTLY_WORKTREE", HOME / "wfe-worktrees" / "nightly"))
BASE = Path(os.environ.get("WFE_NIGHTLY_DIR", HOME / "epic-build" / "nightly"))
RELMSG = os.environ.get("WFE_NIGHTLY_RELMSG", str(HOME / ".local" / "bin" / "relmsg"))

CHECK_TIMEOUT_S = 90 * 60
KEEP_RUNS = 7
MAX_ERROR_RUNS = 3  # the first run of a sha and at most two retries after `error`
CULPRITS_KEPT = 30
DETAIL_ITEMS = 15
GREEN_NOTE_EVERY = dt.timedelta(days=7)
TIMER_SLOT_WAIT_S = 120
NOW_SLOT_WAIT_S = 12 * 3600

STEP_RE = re.compile(r"^== (.+?)\s*$")
PROGRESS_RE = re.compile(r"^\d+:\d\d \+(\d+)(?: ~(\d+))?(?: -(\d+))?: (.*)$")
STAMP_RE = re.compile(r"^(\d\d):(\d\d):(\d\d) ")
TEST_FILE_RE = re.compile(r"^(?:loading )?(\S+?\.dart)(?:: (.*))?$")
STEP_ID_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.:+-]{0,63}$")


# ---------------------------------------------------------------- time and files

def utcnow():
    return dt.datetime.now(dt.timezone.utc).replace(microsecond=0)


def iso(t):
    return t.strftime("%Y-%m-%dT%H:%M:%SZ")


def parse_iso(s):
    return dt.datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=dt.timezone.utc)


def fmt_duration(s):
    s = int(s or 0)
    h, rest = divmod(s, 3600)
    m, sec = divmod(rest, 60)
    return f"{h}h{m:02d}m{sec:02d}s" if h else f"{m}m{sec:02d}s"


def write_atomic(path, text):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(f".{path.name}.tmp{os.getpid()}")
    with open(tmp, "w", encoding="utf-8") as f:
        f.write(text)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, path)


def write_json(path, data):
    write_atomic(path, json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def read_json(path, default):
    try:
        return json.loads(Path(path).read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return default


# ---------------------------------------------------------------- parsing check.sh output

def _strip_stamp(line):
    """(seconds of day or None, line without the time prefix nightly.py writes)."""
    m = STAMP_RE.match(line)
    if not m:
        return None, line
    h, mi, s = (int(x) for x in m.groups())
    return h * 3600 + mi * 60 + s, line[m.end():]


def _test_ref(text, app_root=None):
    """{file, name} for the text of a failing test line (without the progress prefix and [E])."""
    m = TEST_FILE_RE.match(text)
    if not m:
        return {"file": "", "name": text}
    path, name = m.group(1), (m.group(2) or "").strip()
    if text.startswith("loading "):
        name = name or "loading the file"
    i = path.rfind("/app/")
    if i >= 0:
        path = path[i + 1:]
    elif app_root and path.startswith(app_root):
        path = path[len(app_root):].lstrip("/")
    return {"file": path, "name": name}


def parse_check_log(lines, expected_steps=()):
    """What a check.sh run printed, read from its (optionally time-prefixed) lines.

    Returns {passed, steps: [{name, status, duration_s}], tests: {step: {passed, skipped, failed}},
    failing_tests: [{file, name}], failing_step}. `passed` is True only when `check passed` was
    printed. Without it the last step started is the failing one; steps in expected_steps that
    never started are not_run.
    """
    steps = []
    tests = {}
    failing = []
    seen_failing = set()
    passed = False
    last_t = None
    day = 0
    # per step: counts of finished flutter runs, and the newest progress line of the open run
    run_done = {}
    run_open = {}

    def close_run(name):
        cur = run_open.pop(name, None)
        if cur is None:
            return
        acc = run_done.setdefault(name, [0, 0, 0])
        for i in range(3):
            acc[i] += cur[i]

    for raw in lines:
        raw = raw.rstrip("\n")
        t, line = _strip_stamp(raw)
        if t is not None:
            if last_t is not None and t + day < last_t - 3600:
                day += 86400  # past midnight
            t += day
            last_t = t
        m = STEP_RE.match(line)
        if m:
            if steps:
                close_run(steps[-1]["name"])
                if steps[-1]["_t0"] is not None and t is not None:
                    steps[-1]["duration_s"] = t - steps[-1]["_t0"]
            steps.append({"name": m.group(1), "status": "running", "duration_s": None, "_t0": t})
            continue
        if line.startswith("check passed"):
            passed = True
            continue
        if not steps:
            continue
        cur = steps[-1]["name"]
        p = PROGRESS_RE.match(line)
        if not p:
            continue
        counts = [int(p.group(1)), int(p.group(2) or 0), int(p.group(3) or 0)]
        msg = p.group(4)
        run_open[cur] = counts
        if msg.endswith(" [E]"):
            ref = _test_ref(msg[:-4])
            key = (ref["file"], ref["name"])
            if key not in seen_failing:
                seen_failing.add(key)
                failing.append(ref)
        elif msg.startswith("All tests passed") or msg.startswith("Some tests failed"):
            close_run(cur)

    if steps:
        close_run(steps[-1]["name"])
        if steps[-1]["_t0"] is not None and last_t is not None and steps[-1]["duration_s"] is None:
            steps[-1]["duration_s"] = last_t - steps[-1]["_t0"]
    failing_step = None
    for i, s in enumerate(steps):
        if passed or i < len(steps) - 1:
            s["status"] = "ok"
        else:
            s["status"] = "failed"
            failing_step = s["name"]
        del s["_t0"]
    names = {s["name"] for s in steps}
    for name in expected_steps:
        if name not in names:
            steps.append({"name": name, "status": "not_run", "duration_s": None})
    for name, (np, ns, nf) in run_done.items():
        tests[name] = {"passed": np, "skipped": ns, "failed": nf}
    return {"passed": passed, "steps": steps, "tests": tests, "failing_tests": failing,
            "failing_step": failing_step}


def expected_steps_of(check_sh, full=True):
    """The literal step names in a check.sh, in order (a name with a shell expansion is the
    fast mode's and is left out in full mode)."""
    try:
        text = Path(check_sh).read_text(encoding="utf-8")
    except OSError:
        return []
    names = re.findall(r'^\s*step "([^"]*)"', text, re.M)
    return [n for n in names if not (full and "$" in n)]


def count_line(tests):
    """'+6309 ~45 -22' summed over the flutter steps."""
    p = sum(t["passed"] for t in tests.values())
    s = sum(t["skipped"] for t in tests.values())
    f = sum(t["failed"] for t in tests.values())
    return f"+{p} ~{s} -{f}" if tests else "no test counts"


# ---------------------------------------------------------------- decisions

def decide(state, sha):
    """('run', None) or ('skip', reason) for main at `sha`, from state.json."""
    last = state.get("last_completed") or {}
    if last.get("sha") == sha:
        if last.get("status") in ("green", "red"):
            return "skip", "unchanged"
        if last.get("status") == "error":
            n = int((state.get("errors") or {}).get(sha, 0))
            if n >= MAX_ERROR_RUNS:
                return "skip", f"error retries used up ({n} runs ended in error)"
    return "run", None


def busy_slots(status_text):
    """The `build-slot --status` lines of slots that are held."""
    held = []
    for line in status_text.splitlines():
        m = re.match(r"^slot \d+: (.*)$", line.strip())
        if m and m.group(1).strip() != "free":
            held.append(line.strip())
    return held


def green_note_due(state, now):
    last = state.get("last_green_note")
    if not last:
        return True
    try:
        return now - parse_iso(last) >= GREEN_NOTE_EVERY
    except ValueError:
        return True


def step_id(name, taken):
    base = re.sub(r"[^A-Za-z0-9_.+-]+", "-", name).strip("-.+_")[:60] or "step"
    sid, n = base, 2
    while sid in taken:
        sid, n = f"{base[:58]}-{n}", n + 1
    taken.add(sid)
    return sid


# ---------------------------------------------------------------- git

def git(*args, cwd=None, check=True):
    r = subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True, timeout=600)
    if check and r.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)}: {(r.stderr or r.stdout).strip()[-400:]}")
    return r.stdout.strip()


def commits_between(old, new, limit=CULPRITS_KEPT):
    """['sha8 subject', ...] newest first: commits on new not on old (all of them when old is
    unknown, capped)."""
    rng = [f"{old}..{new}"] if old else [new]
    try:
        out = git("-C", str(REPO), "log", "--first-parent",
                  f"--max-count={limit}", "--format=%H %s", *rng)
    except (RuntimeError, subprocess.SubprocessError):
        return []
    return [f"{l[:8]} {l[41:]}" for l in out.splitlines() if l]


# ---------------------------------------------------------------- relmsg

class Notifier:
    """Calls relmsg; every answer or failure goes to self.log, nothing raises."""

    def __init__(self, test=False):
        self.test = test
        self.release = None
        self.log = []

    def call(self, *args):
        cmd = [RELMSG, "--json"]
        if self.release is not None:
            cmd += ["--release", str(self.release)]
        cmd += list(args)
        entry = {"cmd": " ".join(args[:2])}
        try:
            r = subprocess.run(cmd, capture_output=True, text=True, timeout=90)
            entry["exit"] = r.returncode
            out = r.stdout.strip()
            try:
                entry["answer"] = json.loads(out) if out else None
            except ValueError:
                entry["answer"] = out[-500:]
            if r.returncode != 0:
                entry["error"] = (r.stderr or "").strip()[-500:]
        except (OSError, subprocess.SubprocessError) as e:
            entry["exit"] = None
            entry["error"] = str(e)[-500:]
        self.log.append(entry)
        return entry

    def ok(self, entry):
        return entry.get("exit") == 0

    def start(self, version, sha, steps, run_id):
        args = ["start", version, "--title", "Epic Wallet nightly", "--commit", sha,
                "--steps", ",".join(steps), "--run-id", run_id]
        if self.test:
            args.append("--test")
        e = self.call(*args)
        if self.ok(e) and isinstance(e.get("answer"), dict):
            self.release = e["answer"].get("release_id")
        return self.release is not None


def notify(result, *, test=False, green_note=False):
    """Sends the relay messages for a result; returns what was sent (for result.json)."""
    n = Notifier(test=test)
    sha8 = result["sha"][:8]
    day = result["started"][:10].replace("-", "")
    stamp = result.get("run_stamp") or result["started"].replace("-", "").replace(":", "")[:13]
    steps = result["steps"] or [{"name": "nightly run", "status": "failed", "duration_s": None}]
    taken = set()
    ids = [step_id(s["name"], taken) for s in steps]
    run_id = f"nightly-{'test-' if test else ''}{stamp}-{sha8}"
    if not n.start(f"nightly-{day}", result["sha"], ids, run_id):
        return {"sent": False, "kind": "none", "calls": n.log}
    for sid, s in zip(ids, steps):
        status = {"ok": "ok", "failed": "failed"}.get(s["status"], "skipped")
        args = ["step", sid, status, "--label", s["name"][:80], "--no-alert"]
        if s.get("duration_s") is not None:
            args += ["--note", fmt_duration(s["duration_s"])]
        n.call(*args)
    if green_note:
        n.call("done", "ok", "--note", f"still green: {count_line(result['tests'])}")
        return {"sent": True, "kind": "still green note", "release_id": n.release, "calls": n.log}
    if result["status"] == "red":
        title = f"main is red: {result.get('failing_step') or 'unknown step'}"
    else:
        title = f"nightly run broke: {result.get('error') or 'unknown reason'}"
    if test:
        title = "TEST " + title
    failing_sid = next((sid for sid, s in zip(ids, steps) if s["status"] == "failed"), None)
    args = ["alert", title[:200], "--detail", alert_detail(result),
            "--expects", "fix the named failing tests only", "--key",
            f"nightly-{'test-' if test else ''}{sha8}"]
    if failing_sid:
        args += ["--step", failing_sid]
    a = n.call(*args)
    n.call("done", "failed")
    return {"sent": n.ok(a), "kind": "alert", "title": title, "release_id": n.release,
            "calls": n.log}


def alert_detail(result, limit=3000):
    parts = []
    ft = result.get("failing_tests") or []
    if ft:
        parts.append(f"Failing tests ({len(ft)}):")
        parts += [f"- {t['file']}: {t['name']}" if t["file"] else f"- {t['name']}"
                  for t in ft[:DETAIL_ITEMS]]
        if len(ft) > DETAIL_ITEMS:
            parts.append(f"  … and {len(ft) - DETAIL_ITEMS} more")
    elif result.get("log_tail"):
        parts.append("Log tail:")
        parts += result["log_tail"][-15:]
    cs = result.get("commits_since_green") or []
    green = (result.get("last_green_sha") or "")[:8] or "none recorded"
    parts.append("")
    parts.append(f"Commits since the last green run ({green}): {len(cs)}")
    parts += [f"- {c}" for c in cs[:DETAIL_ITEMS]]
    if len(cs) > DETAIL_ITEMS:
        parts.append(f"  … and {len(cs) - DETAIL_ITEMS} more")
    parts.append("")
    parts.append(f"Tests: {count_line(result.get('tests') or {})}")
    parts.append(f"Duration: {fmt_duration(result.get('duration_s'))}")
    parts.append(f"Log: {result.get('log')}")
    text = "\n".join(parts)
    if len(text) > limit:
        text = text[: limit - 2] + " …"
    return text


# ---------------------------------------------------------------- running the check

def run_logged(cmd, log, env, cwd, timeout=None, start_new_session=True):
    """Runs cmd, appending its output to the open log file with a UTC time prefix per line.
    Returns (exit status or None on timeout, tail lines)."""
    tail = []
    proc = subprocess.Popen(cmd, cwd=cwd, env=env, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL,
                            start_new_session=start_new_session)

    def pump():
        for b in iter(proc.stdout.readline, b""):
            line = b.decode("utf-8", "replace").rstrip("\n")
            log.write(f"{utcnow().strftime('%H:%M:%S')} {line}\n")
            log.flush()
            tail.append(line)
            if len(tail) > 60:
                del tail[:-40]

    th = threading.Thread(target=pump, daemon=True)
    th.start()
    try:
        rc = proc.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        rc = None
        for sig, wait in ((signal.SIGTERM, 30), (signal.SIGKILL, 10)):
            try:
                os.killpg(proc.pid, sig)
            except ProcessLookupError:
                break
            try:
                proc.wait(timeout=wait)
                break
            except subprocess.TimeoutExpired:
                pass
        # build-slot runs the check in its own scope; what is left of it goes too
        subprocess.run(["systemctl", "--user", "stop", "build-slot-nightly-*.scope"],
                       capture_output=True, timeout=60)
    th.join(timeout=30)
    return rc, tail


def check_env(run_dir, wait_slot):
    env = dict(os.environ)
    for k in ("WAYLAND_DISPLAY", "DISPLAY", "CARGO_TARGET_DIR", "BUILD_SLOT"):
        env.pop(k, None)
    scratch = run_dir / "scratch" / "nightly-000000"
    tmp = scratch / "tmp"
    tmp.mkdir(parents=True, exist_ok=True)
    env["PATH"] = ":".join([str(HOME / ".local" / "bin"), str(HOME / ".cargo" / "bin"),
                            "/usr/local/bin", "/usr/bin", "/bin"])
    env["TMPDIR"] = str(scratch)
    env["TMPDIR"] = env["TMP"] = env["TEMP"] = str(tmp)
    env["BUILD_SLOT_WAIT"] = str(NOW_SLOT_WAIT_S if wait_slot else TIMER_SLOT_WAIT_S)
    env["XDG_DATA_HOME"] = str(run_dir / "xdg-data")
    return env


def check_command(run_dir):
    """(argv, text for result.json) for the commit in the run worktree."""
    wrap = ["nice", "-n", "15", "ionice", "-c3", "build-slot"]
    source_check = WORKTREE / "tools" / "rellib" / "steps" / "source-check.sh"
    if source_check.is_file():
        argv = wrap + [str(source_check), str(run_dir / "source-check")]
        return argv, f"tools/rellib/steps/source-check.sh {run_dir / 'source-check'} (check.sh --full)"
    check_sh = WORKTREE / "tools" / "check.sh"
    try:
        full = "--full" in check_sh.read_text(encoding="utf-8")
    except OSError:
        full = False
    check = "tools/check.sh --full" if full else "tools/check.sh"
    script = ('export XDG_DATA_HOME="$NIGHTLY_XDG"; '
              "printf 'throwaway\\n' | gnome-keyring-daemon --unlock --components=secrets "
              f">/dev/null; exec {check}")
    argv = wrap + ["dbus-run-session", "--", "bash", "-c", script]
    return argv, check


def prepare_worktree(sha, log, env):
    """Moves the run worktree to sha with a clean tree; raises RuntimeError on failure."""
    if not (WORKTREE / ".git").exists():
        rc, tail = run_logged(["git", "-C", str(REPO), "worktree", "add", "--detach",
                               str(WORKTREE), sha], log, env, str(REPO), timeout=600)
        if rc != 0:
            raise RuntimeError("git worktree add failed")
    for cmd in (["git", "checkout", "--quiet", "--force", "--detach", sha],
                ["git", "clean", "-ffdxq", "-e", "/app/third_party/"],
                ["tools/lepic.sh", "sync"]):
        rc, tail = run_logged(cmd, log, env, str(WORKTREE), timeout=1800)
        if rc != 0:
            raise RuntimeError(f"{' '.join(cmd[:2])} failed ({rc})")
    head = git("-C", str(WORKTREE), "rev-parse", "HEAD")
    if head != sha:
        raise RuntimeError(f"worktree at {head[:8]}, not {sha[:8]}")


def prune_dirs(parent, keep=KEEP_RUNS):
    if not parent.is_dir():
        return
    runs = sorted(p for p in parent.iterdir() if p.is_dir() and re.match(r"^\d{8}T\d{4}-", p.name))
    for p in runs[:-keep] if len(runs) > keep else []:
        shutil.rmtree(p, ignore_errors=True)


def attempt(kind, sha, what):
    line = f"{iso(utcnow())} {kind:<5} {(sha or '-')[:8]:<8} {what}\n"
    BASE.mkdir(parents=True, exist_ok=True)
    with open(BASE / "attempts.log", "a", encoding="utf-8") as f:
        f.write(line)
    print(line, end="")


def cmd_run(wait_slot):
    kind = "now" if wait_slot else "timer"
    BASE.mkdir(parents=True, exist_ok=True)
    lock = open(BASE / ".lock", "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        attempt(kind, None, "skipped: another run holds the lock")
        return 0

    state = read_json(BASE / "state.json", {})
    try:
        sha = git("-C", str(REPO), "rev-parse", "refs/heads/main")
    except (RuntimeError, subprocess.SubprocessError) as e:
        return broken_run(kind, state, None, f"cannot read main: {e}")

    verdict, reason = decide(state, sha)
    if verdict == "skip":
        attempt(kind, sha, f"skipped: {reason}")
        return 0
    if not wait_slot:
        try:
            st = subprocess.run(["build-slot", "--status"], capture_output=True, text=True,
                                timeout=60, env=check_env_path()).stdout
        except (OSError, subprocess.SubprocessError) as e:
            st = ""
            print(f"build-slot --status failed: {e}", file=sys.stderr)
        held = busy_slots(st)
        if held:
            attempt(kind, sha, "skipped: busy (" + "; ".join(held)[:300] + ")")
            return 0

    started = utcnow()
    stamp = started.strftime("%Y%m%dT%H%M")
    run_dir = BASE / "runs" / f"{stamp}-{sha[:8]}"
    if run_dir.exists():
        shutil.rmtree(run_dir)  # a busy-skipped attempt in the same minute
    run_dir.mkdir(parents=True)
    log_path = run_dir / "check.log"
    env = check_env(run_dir, wait_slot)
    env["NIGHTLY_XDG"] = env["XDG_DATA_HOME"]
    error = None
    rc = None
    tail = []
    command = None
    with open(log_path, "w", encoding="utf-8") as log:
        log.write(f"{started.strftime('%H:%M:%S')} nightly {kind} run of main {sha}\n")
        try:
            prepare_worktree(sha, log, env)
            argv, command = check_command(run_dir)
            log.write(f"{utcnow().strftime('%H:%M:%S')} $ {' '.join(argv)}\n")
            log.flush()
            rc, tail = run_logged(argv, log, env, str(WORKTREE), timeout=CHECK_TIMEOUT_S)
        except Exception as e:  # a broken run is reported, never raised
            error = str(e)[:300]
    ended = utcnow()

    if rc == 75 and any("no build slot free" in l for l in tail):
        if not wait_slot:
            shutil.rmtree(run_dir, ignore_errors=True)
            attempt(kind, sha, "skipped: busy (no build slot within "
                    f"{TIMER_SLOT_WAIT_S}s)")
            prune_shared()
            return 0
        error = "no build slot came while waiting"

    with open(log_path, encoding="utf-8") as f:
        parsed = parse_check_log(f, expected_steps_of(WORKTREE / "tools" / "check.sh",
                                                       full=True))
    if error is None:
        if rc is None:
            error = f"the check ran past {CHECK_TIMEOUT_S // 60} min and was stopped"
        elif rc == 0 and parsed["passed"]:
            pass
        elif rc != 0 and parsed["failing_step"] is None:
            error = f"the check exited {rc} before its first step"
        elif rc == 0:
            error = "the check exited 0 without `check passed`"
    status = "error" if error else ("green" if rc == 0 else "red")

    last_green = state.get("last_green_sha")
    result = {
        "status": status,
        "sha": sha,
        "started": iso(started),
        "ended": iso(ended),
        "duration_s": int((ended - started).total_seconds()),
        "kind": kind,
        "command": command,
        "exit": rc,
        "steps": parsed["steps"],
        "failing_step": parsed["failing_step"],
        "tests": parsed["tests"],
        "failing_tests": parsed["failing_tests"],
        "last_green_sha": sha if status == "green" else last_green,
        "commits_since_green": [] if status == "green" else commits_between(last_green, sha),
        "log": str(log_path),
        "run_stamp": stamp,
    }
    if error:
        result["error"] = error
        result["log_tail"] = [l[-200:] for l in tail[-15:]]

    now = utcnow()
    if status == "green":
        if green_note_due(state, now):
            result["notified"] = notify(result, green_note=True)
            if result["notified"].get("sent"):
                state["last_green_note"] = iso(now)
        else:
            result["notified"] = {"sent": False, "kind": "none (green, silent)"}
    else:
        result["notified"] = notify(result)

    write_json(run_dir / "result.json", result)
    write_json(BASE / "latest.json", result)
    write_atomic(BASE / "summary.txt", summary_line(result) + "\n")
    state["last_completed"] = {"sha": sha, "status": status, "run": run_dir.name,
                               "ended": result["ended"]}
    errors = {k: v for k, v in (state.get("errors") or {}).items() if k == sha}
    if status == "error":
        errors[sha] = int(errors.get(sha, 0)) + 1
    else:
        errors.pop(sha, None)
    state["errors"] = errors
    if status == "green":
        state["last_green_sha"] = sha
    write_json(BASE / "state.json", state)
    attempt(kind, sha, summary_line(result))
    prune_dirs(BASE / "runs")
    prune_shared()
    return 0


def check_env_path():
    env = dict(os.environ)
    env["PATH"] = f"{HOME / '.local' / 'bin'}:/usr/local/bin:/usr/bin:/bin"
    return env


def broken_run(kind, state, sha, reason):
    """A run that broke before the check started (no sha, git failure): reported, recorded."""
    now = utcnow()
    result = {"status": "error", "sha": sha or "0" * 40, "started": iso(now), "ended": iso(now),
              "duration_s": 0, "kind": kind, "command": None, "steps": [], "tests": {},
              "failing_step": None, "failing_tests": [],
              "last_green_sha": state.get("last_green_sha"), "commits_since_green": [],
              "log": None, "error": reason[:300], "run_stamp": now.strftime("%Y%m%dT%H%M")}
    result["notified"] = notify(result)
    write_json(BASE / "latest.json", result)
    write_atomic(BASE / "summary.txt", summary_line(result) + "\n")
    attempt(kind, sha, summary_line(result))
    return 1


def summary_line(r):
    when = r["ended"][:16].replace("T", " ") + "Z"
    line = f"{when} {r['status']} {r['sha'][:8]} {count_line(r.get('tests') or {})} " \
           f"{fmt_duration(r.get('duration_s'))}"
    if r["status"] == "red":
        line += f" failing: {r.get('failing_step')}"
    elif r["status"] == "error":
        line += f" error: {r.get('error')}"
    return line


def prune_shared():
    lepic = WORKTREE / "tools" / "lepic.sh"
    try:
        if "prune-shared" in lepic.read_text(encoding="utf-8"):
            subprocess.run([str(lepic), "prune-shared"], cwd=str(WORKTREE), env=check_env_path(),
                           capture_output=True, timeout=1800)
    except (OSError, subprocess.SubprocessError):
        pass


# ---------------------------------------------------------------- simulate red

def cmd_simulate_red():
    sha = git("-C", str(REPO), "rev-parse", "refs/heads/main")
    started = utcnow()
    stamp = started.strftime("%Y%m%dT%H%M")
    run_dir = BASE / "test-runs" / f"{stamp}-{sha[:8]}"
    ok = lambda n, d: {"name": n, "status": "ok", "duration_s": d}
    not_run = lambda n: {"name": n, "status": "not_run", "duration_s": None}
    result = {
        "status": "red", "sha": sha, "started": iso(started), "ended": iso(started),
        "duration_s": 1500, "kind": "test", "command": "(simulated: no check ran)",
        "steps": [ok("version (https://docs.btlabs.uk/developers/releases/)", 1), ok("install contract (docs/install-contract.md)", 1),
                  ok("LEPIC at the pin (tools/lepic.rev)", 40), ok("no hosts in code (docs/settings-file.md)", 1),
                  ok("wallet core under plain Dart (no Flutter on its path)", 20),
                  ok("flutter analyze", 90),
                  {"name": "flutter test (all)", "status": "failed", "duration_s": 1100},
                  not_run("integration tests on LEPIC (Linux, offline)"), not_run("bot"),
                  not_run("web build (the demo's flags, tool/build_web.sh)")],
        "failing_step": "flutter test (all)",
        "tests": {"flutter test (all)": {"passed": 6307, "skipped": 45, "failed": 2}},
        "failing_tests": [
            {"file": "app/test/nightly_simulated_test.dart", "name": "TEST a simulated failure one"},
            {"file": "app/test/nightly_simulated_test.dart", "name": "TEST a simulated failure two"}],
        "last_green_sha": None,
        "commits_since_green": commits_between(None, sha, limit=3),
        "log": str(run_dir / "check.log") + " (simulated, no log)",
        "run_stamp": stamp,
    }
    result["notified"] = notify(result, test=True)
    write_json(run_dir / "result.json", result)
    prune_dirs(BASE / "test-runs")
    print(json.dumps(result["notified"], indent=2, ensure_ascii=False))
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(description="Epic Wallet nightly full check (see the header).")
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--wait-slot", action="store_true",
                   help="started by hand: no busy check, wait for a build slot")
    g.add_argument("--simulate-red", action="store_true",
                   help="send a TEST red report from a fixture; no check runs")
    g.add_argument("--parse", metavar="LOG", help="print what the parser reads from a check log")
    a = ap.parse_args(argv)
    if a.simulate_red:
        return cmd_simulate_red()
    if a.parse:
        with open(a.parse, encoding="utf-8", errors="replace") as f:
            print(json.dumps(parse_check_log(f), indent=2, ensure_ascii=False))
        return 0
    return cmd_run(a.wait_slot)


if __name__ == "__main__":
    sys.exit(main())
