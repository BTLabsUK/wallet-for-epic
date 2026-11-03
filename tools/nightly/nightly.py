#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Nightly full check of Epic Wallet's local main, with one Telegram DM to the owner when it is red.

What it is: a script started by a systemd user timer on the build machine through tools/nightly/launch.py,
which runs THIS file from a fresh worktree at main's sha (~/wfe-worktrees/nightly-code) with
--sha, so the nightly is always main's own code; the copy tools/nightly/install.sh puts in
~/.local/lib/wfe-nightly/ is only the launcher's fallback (result.json `runner` says which ran).
It is not an agent: it runs the full check on main, records the result and reports. It never
fixes, pushes, starts agents or blocks merges.

  nightly.py                     one attempt, as wfe-nightly.timer runs it (02:30, 03:30, 04:30 and
                                 05:30 local time). It refuses outside 01:00-06:00 local time
                                 (`skipped: daytime`), and skips while any build-slot slot is held
                                 or any tools/rel run is active (`skipped: busy`)
  python3 ~/.local/lib/wfe-nightly/launch.py --by-hand
                                 the same run started by a person: any time of day, waits for a
                                 build slot, still refuses while a tools/rel run is active
  nightly.py --sha <sha>         test that commit instead of reading main (launch.py passes it)
  nightly.py --simulate-red      no check: posts a red DM built from a fixture with test: true and
                                 "TEST" before the step, and writes it only under test-runs/
  nightly.py --parse <log>       print what the parser reads from a log (debugging)

A run:
  1. takes /tmp/epic-build/nightly/.lock (flock); a second run exits at once;
  2. reads refs/heads/main of %h/wallet-for-epic; skips (`skipped: unchanged`) when the last
     completed run (green or red) tested that sha; a sha whose last run was `error` is retried at
     most twice;
  3. moves the run worktree ~/wfe-worktrees/nightly (detached, used by nothing else) to the sha:
     checkout --force, git clean -ffdx except app/third_party/ (the LEPIC clones), lepic.sh sync;
     then checks the busy rules again;
  4. runs `tools/rellib/steps/source-check.sh <run>/source-check` when the commit has it, else
     `tools/check.sh --full` (or plain `tools/check.sh` before --full existed) inside
     dbus-run-session with an unlocked throwaway keyring; always under
     `nice -n 15 ionice -c3 build-slot`, with a 90 min limit from the slot (then `error`);
  5. parses the output: `== <step>` lines start steps, `check passed` ends a green run, the step
     check.sh was in when it failed is the failing one, flutter's progress lines give counts and
     `[E]` lines the failing tests;
  6. records /tmp/epic-build/nightly/runs/<UTC stamp>-<sha8>/{check.log,result.json} (last 7 kept),
     latest.json (newest completed run), summary.txt (one line), attempts.log (every attempt,
     skips too) and state.json (last green sha, error retries, keys of the DMs sent);
  7. green sends nothing. Red, or a run that broke, sends ONE DM: POST <url>/nightly/notify on
     the feedback bot, URL in ~/.config/wfe-nightly/notify_url, bearer token in
     ~/.config/wfe-nightly/notify_token (without both nothing is sent: "not configured"). The key
     nightly-<sha8>-<red|broken> is sent once: state.json remembers it and the bot dedupes on it.
     A failed send never fails the run; result.json `notified` records it;
  7a. LEPIC's golden vectors (`cargo xtask vectors verify`, a check.sh --full step, red on failure)
     and, after the check unless it broke, `cargo xtask upstream-drift` at the wallet's pin
     (tools/lepic.sh xtask, report only): latest.json `drift` {status: clean|drift|unknown, lines},
     a `group: drift` step, and the summary line names the modules with upstream changes. Drift or an
     unreachable upstream never turns the nightly red or sends a DM;
  7b. after a green source check, one fast G4 update-trust pass per platform (linux, android,
     windows) on the LAST TWO PUBLISHED releases (no builds): previous = the one before the last in
     /tmp/epic-build/rel/published.json plus published-by-hand.json (hand releases), candidate = the last, tor variant, REL_FUNDS=1, BT Labs node
     and Epicbox first, the commit's own drivers (tools/rellib/drivers/trust-<platform>.sh). The
     three run side by side, each under a time limit, output in <run>/trust-<platform>/ (proof.json
     there). Each is a step in latest.json (`group: trust`, `proof`, `failing_checks`) with
     status ok / fail / skipped (missing binaries, fewer than two published releases, a release run
     active, a driver that could not run: exit 2). The source status stays green (the G2 reuse and
     last_green_sha stay about the source); a failed trust step is `trust: {status: red, ...}` and
     sends ONE DM (key nightly-<sha8>-trust) naming the failing checks. NIGHTLY_TRUST=0 turns the
     pass off, NIGHTLY_TRUST_PLATFORMS=linux,android limits it, NIGHTLY_TRUST_CHECKS overrides
     REL_CHECKS (default: the driver's eight);
  7d. after a proved Linux trust pass, one BREAK lane on the same pair, only with drivers that restore
     the lane's permanent seed (P's payment before the update stays in that wallet when the break
     fails; without lane seeds it is skipped): REL_FUNDS=0 (no candidate legs),
     REL_TRUST_SAVE_STATE=0, REL_TRUST_BREAK = one break of the night (day number modulo the list:
     hide:<id> for each reachable desktop control of drivers/trust_ids.json, plus one dialog:<id>).
     Scored from <run>/breaks-linux/proof.json and result.txt into <run>/breaks.json, latest.json
     `breaks` and a step (group breaks): recovered right | recovered wrong | failed honestly |
     failed silently (a pass without a recovery means the break was not applied: a harness bug).
     A wrong pick or a silent result writes breaks-fix.md (a drafted selector fix; a file, no code
     change). It never changes the run's status or sends a DM. NIGHTLY_BREAKS=0 turns it off;
  7c. reads every Windows rig session's health (drivers/windows/rig.py health, read-only over SSH:
     task, last run and result, account, batch logon right, queue): latest.json `rigs` {status:
     ok|dead|unknown, dead: ["rig <k>: <cause>"]} and a `Windows rig health` step (group rigs);
     a dead rig is named in summary.txt too. It never changes the run's status;
  8. runs `tools/lepic.sh prune-shared` and `prebuild` (fills the prebuilt LEPIC cache) when the
     commit has them, ignoring their result.
Python 3 standard library only.
"""

import argparse
import datetime as dt
import fcntl
import glob
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import threading
import time
import urllib.error
import urllib.request
from pathlib import Path

# The run history of tools/t (tlib/history.py). The installed fallback copy of this file sits
# outside the repository and has no tlib: it then reports no flake records.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
try:
    from tlib import history as test_history
except ImportError:  # pragma: no cover
    test_history = None

HOME = Path.home()
REPO = Path(os.environ.get("WFE_NIGHTLY_REPO", HOME / "wallet-for-epic"))
WORKTREE = Path(os.environ.get("WFE_NIGHTLY_WORKTREE", HOME / "wfe-worktrees" / "nightly"))
BASE = Path(os.environ.get("WFE_NIGHTLY_DIR", HOME / "epic-build" / "nightly"))
REL_LOCKS = str(HOME / "epic-build" / "rel" / "*" / "run-*" / ".lock")
NOTIFY_CONF = HOME / ".config" / "wfe-nightly"
# Green `tools/check.sh --full` records (tools/rellib/green.py): a commit with one is not run again.
GREEN_DIR = Path(os.environ.get("WFE_GREEN_DIR") or HOME / "epic-build" / "green")

CHECK_TIMEOUT_S = 90 * 60
KEEP_RUNS = 7
MAX_ERROR_RUNS = 3  # the first run of a sha and at most two retries after `error`
CULPRITS_KEPT = 30
TIMER_SLOT_WAIT_S = 120
BY_HAND_SLOT_WAIT_S = 12 * 3600
NIGHT_HOURS = (1, 6)  # timer runs only from 01:00 to 06:00 local time
DM_ITEMS, DM_TEST_CHARS, DM_COMMIT_CHARS = 15, 160, 120
DM_FIELDS = {"kind", "sha", "key", "step", "counts", "duration", "reason", "tests", "commits",
             "log", "test"}
DM_RETRIES = 3
REL_ROOT = Path(os.environ.get("WFE_NIGHTLY_REL_ROOT", HOME / "epic-build" / "rel"))
TRUST_PLATFORMS = ("linux", "android", "windows")
TRUST_TIMEOUT_S = {"linux": 50 * 60, "android": 60 * 60, "windows": 60 * 60}
TRUST_NODE = "https://node.btlabs.uk"
TRUST_EPICBOX = "epicbox.stackwallet.com"
SENT_KEYS_KEPT = 500
BREAK_TIMEOUT_S = TRUST_TIMEOUT_S["linux"]
BREAK_DIALOG = "dialog:g4.unlock.submit"
# Registry screens whose controls a Linux lane without funds reaches (send, first-run and secret screens are not).
BREAK_SCREENS = ("shell", "settings", "advanced", "payments", "overview")
BREAK_ROLES = ("button", "tab", "menu_item", "toggle")

STEP_RE = re.compile(r"^== (.+?)\s*$")
# The line check.sh prints when a step ends: `== bot: ok 4s`, or `== bot: FAILED (exit 1) after 4s`.
STEP_END_RE = re.compile(r"^== .+?: (?:ok (\d+)s|FAILED \(exit \d+\) after (\d+)s)\s*$")
PROGRESS_RE = re.compile(r"^\d+:\d\d \+(\d+)(?: ~(\d+))?(?: -(\d+))?: (.*)$")
STAMP_RE = re.compile(r"^(\d\d):(\d\d):(\d\d) ")
TEST_FILE_RE = re.compile(r"^(?:loading )?(\S+?\.dart)(?:: (.*))?$")


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
        e = STEP_END_RE.match(line)
        if e and steps:
            # check.sh's own timing of the open step; it is not a step of its own
            steps[-1]["duration_s"] = int(e.group(1) or e.group(2))
            continue
        m = STEP_RE.match(line)
        if m:
            if steps:
                close_run(steps[-1]["name"])
                if steps[-1]["duration_s"] is None and steps[-1]["_t0"] is not None and t is not None:
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


def mark_flaky(failing, records=None, days=30):
    """The failing tests of a run, each with `flaky` = {fails, passes, last_fail, scope} when the run
    history (`tools/t flaky`) has the test, or else its file, failing and passing with the same
    inputs; without a record the test has no `flaky` key. Nothing is hidden: the marks only add."""
    if records is None:
        if test_history is None:
            return failing
        records = test_history.read(since=time.time() - days * 86400)
    index = test_history.flaky_index(records) if test_history else {}
    out = []
    for t in failing:
        t = dict(t)
        f = t.get("file", "")
        f = f[len("app/"):] if f.startswith("app/") else f
        e = index.get((f, t.get("name"))) or index.get((f, "(file)"))
        scope = "test"
        if not e:
            e, scope = index.get((f, None)), "file"
        if e:
            t["flaky"] = {"fails": e["fails"], "passes": e["passes"], "last_fail": e["last_fail"][:10],
                          "scope": scope}
        out.append(t)
    return out


def flaky_tag(t):
    """' [flaky: 3 fails, 12 passes, last 2026-11-02]' for a failing test with a record, else ''."""
    k = t.get("flaky")
    if not k:
        return ""
    where = "" if k.get("scope") == "test" else " in its file"
    return f" [flaky{where}: {k['fails']} fails, {k['passes']} passes, last {k['last_fail']}]"


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

def decide(state, sha, green_dir=None):
    """('run', None) or ('skip', reason) for main at `sha`, from state.json and the green records:
    the full suite never runs twice on one tree (a release's G2 on this commit counts)."""
    last = state.get("last_completed") or {}
    if last.get("sha") == sha:
        if last.get("status") in ("green", "red"):
            return "skip", "unchanged"
        if last.get("status") == "error":
            n = int((state.get("errors") or {}).get(sha, 0))
            if n >= MAX_ERROR_RUNS:
                return "skip", f"error retries used up ({n} runs ended in error)"
    rec = read_json(Path(green_dir or GREEN_DIR) / f"{sha}.json", {})
    if isinstance(rec, dict) and rec.get("status") == "green" and rec.get("clean") is True:
        return "skip", f"already green: tools/check.sh --full passed on this commit (by {rec.get('by', '?')}, {rec.get('ended', '?')})"
    return "run", None


def busy_slots(status_text):
    """The `build-slot --status` lines of slots that are held."""
    held = []
    for line in status_text.splitlines():
        m = re.match(r"^slot \d+: (.*)$", line.strip())
        if m and m.group(1).strip() != "free":
            held.append(line.strip())
    return held


def rel_busy(pattern=None):
    """Lock files of tools/rel runs that are active (held). Only tries a shared lock and lets go:
    nothing changes and nothing waits."""
    held = []
    for path in sorted(glob.glob(pattern or REL_LOCKS)):
        try:
            fd = os.open(path, os.O_RDONLY)
        except OSError:
            continue
        try:
            fcntl.flock(fd, fcntl.LOCK_SH | fcntl.LOCK_NB)
            fcntl.flock(fd, fcntl.LOCK_UN)
        except OSError:
            held.append(path)
        finally:
            os.close(fd)
    return held


def slot_status():
    try:
        return subprocess.run(["build-slot", "--status"], capture_output=True, text=True,
                              timeout=60, env=check_env_path()).stdout
    except (OSError, subprocess.SubprocessError) as e:
        print(f"build-slot --status failed: {e}", file=sys.stderr)
        return ""


def refusal(by_hand, now_local=None, status_text=None, rel_pattern=None):
    """Why this attempt must not run now ('daytime', 'busy (...)'), or None."""
    if not by_hand:
        hour = (now_local or dt.datetime.now()).hour
        if not NIGHT_HOURS[0] <= hour < NIGHT_HOURS[1]:
            return "daytime"
    rel = rel_busy(rel_pattern)
    if rel:
        return "busy (tools/rel run active: " + ", ".join(rel)[:200] + ")"
    if not by_hand:
        held = busy_slots(slot_status() if status_text is None else status_text)
        if held:
            return "busy (" + "; ".join(held)[:300] + ")"
    return None


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


# ---------------------------------------------------------------- the DM (bot route /nightly/notify)

def _clip(s, n):
    return s if len(s) <= n else s[: n - 1] + "…"


def trust_red(result):
    return result["status"] == "green" and (result.get("trust") or {}).get("status") == "red"


def dm_kind(result):
    return "red" if result["status"] == "red" or trust_red(result) else "broken"


def dm_key(sha, kind, test=False, trust=False):
    return f"nightly-{'test-' if test else ''}{sha[:8]}-{'trust' if trust else kind}"


def dm_body(result, test=False):
    """The JSON body for POST /nightly/notify: only the route's fields, within its caps."""
    kind = dm_kind(result)
    trust = trust_red(result)
    body = {"kind": kind, "sha": result["sha"], "key": dm_key(result["sha"], kind, test, trust)}
    step = result["trust"]["step"] if trust else result.get("failing_step")
    if step:
        body["step"] = ("TEST " if test else "") + step
    elif test:
        body["step"] = "TEST"
    if result.get("tests"):
        body["counts"] = count_line(result["tests"])
    if result.get("duration_s"):
        body["duration"] = fmt_duration(result["duration_s"])
    if kind == "broken":
        body["reason"] = _clip(result.get("error") or "unknown", 300)
    if trust:  # source green: the failing checks, no commit list (driver drift or a real regression)
        tests = [_clip(f, DM_TEST_CHARS) for f in result["trust"]["failed"][:DM_ITEMS]]
    else:
        tests = []
        for t in (result.get("failing_tests") or [])[:DM_ITEMS]:
            tag = flaky_tag(t)
            text = f"{t['file']}: {t['name']}" if t.get("file") else t["name"]
            tests.append(_clip(text, DM_TEST_CHARS - len(tag)) + tag)
    if tests:
        body["tests"] = tests
    commits = [_clip(c, DM_COMMIT_CHARS)
               for c in (result.get("commits_since_green") or [])[:DM_ITEMS]] if not trust else []
    if commits:
        body["commits"] = commits
    if result.get("log"):
        body["log"] = result["log"]
    if test:
        body["test"] = True
    return body


def notify_config(conf_dir=None):
    """(url, token) from the two files, or None when either is missing or empty."""
    d = Path(conf_dir or NOTIFY_CONF)
    try:
        url = (d / "notify_url").read_text(encoding="utf-8").strip()
        token = (d / "notify_token").read_text(encoding="utf-8").strip()
    except OSError:
        return None
    return (url, token) if url and token else None


def post_dm(body, url, token, opener=None, sleep=time.sleep):
    """POSTs the body; retries network errors, 5xx and 429 DM_RETRIES times with back-off.
    Returns what result.json records (never the token or the URL)."""
    opener = opener or urllib.request.urlopen
    data = json.dumps(body).encode("utf-8")
    tries = []
    for n in range(DM_RETRIES + 1):
        req = urllib.request.Request(
            url.rstrip("/") + "/nightly/notify", data=data, method="POST",
            headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"})
        wait = 5 * 3 ** n
        try:
            with opener(req, timeout=20) as resp:
                status, text = resp.status, resp.read(2000).decode("utf-8", "replace")
        except urllib.error.HTTPError as e:
            status, text = e.code, e.read(2000).decode("utf-8", "replace")
            if status == 429:
                try:
                    wait = min(120, max(wait, int(e.headers.get("Retry-After", "0"))))
                except (TypeError, ValueError, AttributeError):
                    pass
        except (urllib.error.URLError, OSError) as e:
            status, text = None, f"network: {getattr(e, 'reason', e)}"[:200]
        tries.append(status)
        if status == 200:
            try:
                answer = json.loads(text) if text.strip() else {}
            except ValueError:
                answer = {}
            dup = isinstance(answer, dict) and answer.get("duplicate") is True
            return {"sent": True, "duplicate": dup, "status": 200, "tries": tries}
        retry = status is None or status == 429 or status >= 500
        if not retry or n == DM_RETRIES:
            return {"sent": False, "status": status, "why": text[:300], "tries": tries}
        sleep(wait)
    return {"sent": False, "tries": tries}


def report(result, state, test=False, conf_dir=None, opener=None, sleep=time.sleep):
    """Sends the one DM a result calls for; green sends nothing. Adds the key to
    state['sent_keys'] once the bot took it."""
    if result["status"] == "green" and not trust_red(result):
        return {"sent": False, "why": "green sends nothing"}
    body = dm_body(result, test=test)
    sent_keys = state.setdefault("sent_keys", [])
    if body["key"] in sent_keys:
        return {"sent": False, "why": "already sent", "key": body["key"]}
    conf = notify_config(conf_dir)
    if conf is None:
        return {"sent": False, "why": "not configured", "key": body["key"]}
    out = post_dm(body, *conf, opener=opener, sleep=sleep)
    out["key"] = body["key"]
    out["body"] = body
    if out.get("sent"):
        sent_keys.append(body["key"])
        del sent_keys[:-SENT_KEYS_KEPT]
    return out


# ---------------------------------------------------------------- G4 trust pass

def published_pair(rel_root=None):
    """(previous, candidate) as {version, files, extra} dicts: the newest two of the runner's
    published.json and the hand-made published-by-hand.json ({version, dir} entries; dir is a flat
    release folder with emulator/ inside), the runner's entry winning for a version; or
    (None, reason) when fewer than two."""
    root = Path(rel_root or REL_ROOT)
    by_version = {}
    hand = read_json(root / "published-by-hand.json", [])
    for p in hand if isinstance(hand, list) else []:
        if isinstance(p, dict) and p.get("version") and p.get("dir"):
            by_version[p["version"]] = {"version": p["version"], "files": p["dir"], "extra": p["dir"]}
    pubs = read_json(root / "published.json", [])
    for p in pubs if isinstance(pubs, list) else []:
        if isinstance(p, dict) and p.get("version") and p.get("run") \
                and p.get("kind", "release") == "release":
            by_version[p["version"]] = {"version": p["version"], "files": str(Path(p["run"]) / "files"),
                                        "extra": str(Path(p["run"]) / "extra")}  # a rebuild replaces
    versions = sorted(by_version, key=version_key)
    if len(versions) < 2:
        return None, f"fewer than two published releases in {root / 'published.json'} and published-by-hand.json"
    return by_version[versions[-2]], by_version[versions[-1]]


def version_key(v):
    return tuple(int(x) if x.isdigit() else 0 for x in re.split(r"[.\-]", v))


def release_names(platform, v):
    """The file the G4 driver installs, new name first: (bt-wallet-…, the name before it)."""
    return {"linux": (f"bt-wallet-{v}-linux-x86_64.AppImage", f"EpicCashDesktop-{v}-x86_64.AppImage"),
            "windows": (f"bt-wallet-{v}-windows-x64-setup.exe", f"epic-cash-desktop-{v}-windows-x64-setup.exe"),
            "android": (f"bt-wallet-{v}-android-x86_64.apk", f"epic-cash-mobile-{v}-x86_64.apk")}[platform]


def trust_inputs(platform, prev, cand):
    """(env for the driver, None) or (None, why it is skipped): the pair's binaries must be on
    disk: `files` holds the desktop and Windows files, `extra`/emulator the x86_64 APKs."""
    pv, cv = prev["version"], cand["version"]
    pf, cf = Path(prev["files"]), Path(cand["files"])
    pe, ce = Path(prev["extra"]), Path(cand["extra"])
    # Each binary by its bt-wallet name, or the name before it (releases made before the rename).
    if platform == "linux":
        names = [(pf, release_names("linux", pv)), (cf, release_names("linux", cv))]
        env = {"REL_PREVIOUS_DIR": str(pf), "REL_CANDIDATE_DIR": str(cf)}
    elif platform == "windows":
        names = [(pf, release_names("windows", pv)), (cf, release_names("windows", cv))]
        env = {"REL_PREVIOUS_DIR": str(pf), "REL_CANDIDATE_DIR": str(cf)}
    else:
        names = [(pe / "emulator", release_names("android", pv)), (ce / "emulator", release_names("android", cv))]
        env = {"REL_PREVIOUS_DIR": str(pe), "REL_CANDIDATE_DIR": str(cf), "REL_CANDIDATE_EXTRA": str(ce)}
    for d, ns in names:
        if not any((d / n).is_file() for n in ns):
            return None, f"binary missing: {d / ns[0]}"
    env.update(REL_PREVIOUS_VERSION=pv, REL_CANDIDATE_VERSION=cv)
    return env, None


def failing_checks(proof):
    checks = (proof or {}).get("checks") or {}
    return sorted(k for k, v in checks.items() if v is not True)


def run_trust_one(platform, prev, cand, run_dir, driver, env_base, runner=None, now=time.monotonic):
    """One platform's step dict. `runner(argv, env, log_path, timeout)` -> rc or None (timeout);
    injectable for tests."""
    title = f"G4 trust {platform} ({prev['version']} \u2192 {cand['version']})"
    step = {"name": title, "group": "trust", "platform": platform, "status": "skipped",
            "duration_s": 0}
    out = Path(run_dir) / f"trust-{platform}"
    env_extra, why = trust_inputs(platform, prev, cand)
    if env_extra is None:
        step["reason"] = why
        return step
    if not Path(driver).is_file():
        step["reason"] = f"no driver {driver}"
        return step
    out.mkdir(parents=True, exist_ok=True)
    env = dict(env_base)
    env.update(env_extra)
    env.update(REL_VARIANT="tor", REL_FUNDS="1", REL_NODE=TRUST_NODE, REL_EPICBOX=TRUST_EPICBOX,
               REL_OUT=str(out))
    if os.environ.get("NIGHTLY_TRUST_CHECKS"):
        env["REL_CHECKS"] = os.environ["NIGHTLY_TRUST_CHECKS"]
    log = out / "driver.log"
    t0 = now()
    rc = (runner or run_driver)([str(driver)], env, log, TRUST_TIMEOUT_S[platform])
    step["duration_s"] = int(now() - t0)
    proof_path = out / "proof.json"
    proof = read_json(proof_path, None)
    if proof_path.is_file():
        step["proof"] = str(proof_path)
    step["log"] = str(log)
    if rc is None:
        step["status"] = "fail"
        step["reason"] = f"timed out after {TRUST_TIMEOUT_S[platform] // 60} min"
    elif rc == 0 and not failing_checks(proof) and proof is not None:
        step["status"] = "ok"
    elif rc == 2:
        step["status"] = "skipped"  # the driver could not run (rig / emulator / tool missing)
        step["reason"] = "driver could not run: " + _clip(
            str((proof or {}).get("reason") or (proof or {}).get("error") or _last_line(log)), 200)
    else:
        step["status"] = "fail"
        step["failing_checks"] = failing_checks(proof)
        step["reason"] = f"driver exit {rc}" + ("" if proof is not None else ", no proof.json")
    return step


def _last_line(path):
    try:
        lines = [l for l in Path(path).read_text(encoding="utf-8", errors="replace").splitlines() if l.strip()]
    except OSError:
        return "no log"
    return lines[-1] if lines else "no output"


def run_driver(argv, env, log_path, timeout):
    """Runs a driver with its output in log_path; rc, or None after killing it on the timeout."""
    with open(log_path, "w", encoding="utf-8") as log:
        proc = subprocess.Popen(argv, env=env, stdout=log, stderr=subprocess.STDOUT,
                                stdin=subprocess.DEVNULL, start_new_session=True)
        try:
            return proc.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
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
            return None


def trust_enabled(environ=None):
    e = os.environ if environ is None else environ
    return str(e.get("NIGHTLY_TRUST", "1")).strip().lower() not in ("0", "false", "no", "off")


def trust_platforms(environ=None):
    e = os.environ if environ is None else environ
    want = [p.strip() for p in str(e.get("NIGHTLY_TRUST_PLATFORMS", "")).split(",") if p.strip()]
    return [p for p in TRUST_PLATFORMS if not want or p in want]


def run_trust(run_dir, env_base, worktree=None, rel_root=None, runner=None, busy=None):
    """The whole pass: a list of step dicts, one per platform (parallel); [] when switched off."""
    if not trust_enabled():
        return []
    platforms = trust_platforms()
    prev, cand = published_pair(rel_root)
    if prev is None:
        return [{"name": f"G4 trust {p}", "group": "trust", "platform": p, "status": "skipped",
                 "duration_s": 0, "reason": cand} for p in platforms]
    held = (busy or rel_busy)()
    if held:
        return [{"name": f"G4 trust {p} ({prev['version']} \u2192 {cand['version']})", "group": "trust",
                 "platform": p, "status": "skipped", "duration_s": 0,
                 "reason": "a release run is active"} for p in platforms]
    drivers = Path(worktree or WORKTREE) / "tools" / "rellib" / "drivers"
    results = {}

    def one(p):
        try:
            results[p] = run_trust_one(p, prev, cand, run_dir, drivers / f"trust-{p}.sh", env_base,
                                       runner=runner)
        except Exception as e:  # one platform's trouble never stops the others
            results[p] = {"name": f"G4 trust {p} ({prev['version']} \u2192 {cand['version']})",
                          "group": "trust", "platform": p, "status": "fail", "duration_s": 0,
                          "reason": f"nightly error: {str(e)[:150]}"}

    threads = [threading.Thread(target=one, args=(p,)) for p in platforms]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    return [results[p] for p in platforms]


# ---------------------------------------------------------------- G4 break lane

def breaks_enabled(environ=None):
    e = os.environ if environ is None else environ
    return str(e.get("NIGHTLY_BREAKS", "1")).strip().lower() not in ("0", "false", "no", "off")


def drivers_dir(worktree=None):
    return Path(worktree or WORKTREE) / "tools" / "rellib" / "drivers"


def registry_controls(worktree=None):
    """{id: control dict} of trust_ids.json (the drivers' own list of targets); {} when unreadable."""
    data = read_json(drivers_dir(worktree) / "trust_ids.json", {})
    return {c["id"]: c for c in (data.get("controls") or []) if isinstance(c, dict) and c.get("id")}


def break_list(worktree=None):
    """The breaks to rotate through: hide:<id> for every desktop, non-secret control of the registry
    on a screen a Linux lane without funds reaches, then one dialog. breaks.py names the kinds, not
    the targets; the targets are the registry's."""
    ids = sorted(i for i, c in registry_controls(worktree).items()
                 if "desktop" in (c.get("family") or []) and not c.get("secret")
                 and c.get("screen") in BREAK_SCREENS and c.get("role") in BREAK_ROLES
                 and not i.endswith((".send", ".switch")))  # funds=0 never sends or switches Epicbox
    return [f"hide:{i}" for i in ids] + [BREAK_DIALOG]


def break_for(day, breaks):
    """The night's break: `day` (a date ordinal) modulo the list; None for an empty list."""
    return breaks[day % len(breaks)] if breaks else None


def _text(path):
    try:
        return Path(path).read_text(encoding="utf-8", errors="replace").strip()
    except OSError:
        return ""


def score_break(brk, rc, out, controls, worktree=None):
    """{score, why, ...} from the lane's proof.json, result.txt and exit code.
    kind hide:<id>: right = proved, with a `pick` recovery for that target, of a role the target
    allows and not another registry control's id; wrong = proved with another role or id picked;
    honest = failed with a fault that names the target; silent = failed without a fault (or one
    that does not name the target), or proved with no recovery for the target (not applied).
    kind dialog:<id>: right = proved with an `advance` recovery at a step of that id's screen."""
    kind, _, target = brk.partition(":")
    out = Path(out)
    proof = read_json(out / "proof.json", None)
    line = _text(out / "result.txt")
    res = {"break": brk, "target": target, "result": line[:300], "rc": rc}
    if not isinstance(proof, dict):
        return dict(res, score="failed silently", why="no proof.json: nothing says what the lane did")
    fault = proof.get("fault") or {}
    recovered = [r for r in (proof.get("recovered") or []) if isinstance(r, dict)]
    proved = rc == 0 and line.startswith("PASS") and all(v is True for v in (proof.get("checks") or {}).values())
    if not proved:
        text = " ".join(str(fault.get(k) or "") for k in ("line", "what", "step"))
        if fault and target and (target in text or target.rsplit(".", 1)[-1] in text):
            return dict(res, score="failed honestly", why=fault.get("line") or text[:200])
        if fault:
            return dict(res, score="failed silently", why="a fault that does not name the target: " + (fault.get("line") or "")[:200])
        return dict(res, score="failed silently", why="failed with no fault in proof.json")
    if kind == "dialog":
        got = [r for r in recovered if r.get("kind") == "advance"]
        if not got:
            return dict(res, score="failed silently", why="proved with no advance recovery: the dialog break was not applied")
        return dict(res, score="recovered right", picked=got[0].get("picked"), step=got[0].get("step"))
    mine = [r for r in recovered if r.get("kind") == "pick" and r.get("target") == target]
    if not mine:
        return dict(res, score="failed silently", why="proved with no recovery for the hidden target: the break was not applied")
    pick = mine[0].get("picked") or {}
    want = (controls.get(target) or {}).get("role", "")
    other = pick.get("id") and pick.get("id") != target and pick["id"] in controls
    if want and pick.get("role") not in _compatible(want, worktree) or other:
        why = ("picked a %s, the target is a %s" % (pick.get("role"), want)) if not other else \
            "picked the control %s, which is another target" % pick.get("id")
        return dict(res, score="recovered wrong", why=why, picked=pick, step=mine[0].get("step"),
                    looked_for=mine[0].get("looked_for"))
    return dict(res, score="recovered right", picked=pick, step=mine[0].get("step"))


def _compatible(role, worktree=None):
    """Roles a target of this role may be pressed through: core/surface.py's COMPATIBLE, read from the
    source (a literal), so it cannot drift; the role itself when unreadable."""
    import ast
    try:
        tree = ast.parse((drivers_dir(worktree) / "core" / "surface.py").read_text(encoding="utf-8"))
        for node in tree.body:
            if isinstance(node, ast.Assign) and any(getattr(t, "id", "") == "COMPATIBLE" for t in node.targets):
                table = ast.literal_eval(node.value)
                return set(table.get(role, {role}))
    except (OSError, SyntaxError, ValueError):
        pass
    return {role}


def driver_line(target, worktree=None):
    """'core/desktop.py:75' where the drivers name the target id; '' when none does."""
    root = drivers_dir(worktree)
    hits = []
    for f in sorted(root.rglob("*.py"), key=lambda f: (f.parent.name != "core", str(f))):
        try:
            for n, text in enumerate(f.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
                if f'"{target}"' in text or f"'{target}'" in text:
                    hits.append(f"{f.relative_to(root.parent.parent.parent)}:{n}")
                    break
        except OSError:
            continue
    return hits[0] if hits else ""


def draft_fix(scored, controls, worktree=None):
    """A markdown note for a wrong pick or a silent result; None for the other scores."""
    if scored["score"] not in ("recovered wrong", "failed silently"):
        return None
    t = scored["target"]
    c = controls.get(t) or {}
    where = driver_line(t, worktree) or "no driver names it (check core/breaks.py)"
    lines = [f"# Drafted selector fix: {scored['break']}", "",
             f"- score: {scored['score']}", f"- target: `{t}` ({c.get('role', '?')}, screen {c.get('screen', '?')})",
             f"- expected: id `{t}`, label keys {c.get('keys') or []}, names {c.get('names') or []}",
             f"- control picked: {scored.get('picked') or 'none recorded'}",
             f"- why: {scored.get('why', '')}", f"- driver: {where}", ""]
    if scored["score"] == "recovered wrong":
        lines.append("Fix: the AI fallback pressed the wrong control. Give the real control `trustId('%s', ...)` "
                     "(app/lib/src/trust_ids.dart) or tighten its keys/names in trust_ids.json, then rerun the break." % t)
    else:
        lines.append("Fix: the break was not applied or the failure is not tied to the target. Check that the step "
                     "reaches `%s` on a Linux lane without funds, and that `breaks.hidden/dialog` is consulted there." % t)
    return "\n".join(lines) + "\n"


def run_breaks(run_dir, env_base, trust_steps, worktree=None, rel_root=None, runner=None, busy=None,
               today=None, now=time.monotonic):
    """The break lane's step dict (with `breaks`: the score), or None when it does not run: switched
    off, or the plain Linux lane did not prove (a break result would mean nothing)."""
    if not breaks_enabled() or not trust_enabled():
        return None
    plain = [s for s in trust_steps if s.get("platform") == "linux"]
    if not plain or plain[0]["status"] != "ok":
        return None
    prev, cand = published_pair(rel_root)
    if prev is None:
        return None
    title = f"G4 break linux ({prev['version']} → {cand['version']})"
    step = {"name": title, "group": "breaks", "platform": "linux", "status": "skipped", "duration_s": 0}
    if (busy or rel_busy)():
        step["reason"] = "a release run is active"
        return step
    driver = drivers_dir(worktree) / "trust-linux.sh"
    env_extra, why = trust_inputs("linux", prev, cand)
    if env_extra is None or not driver.is_file():
        step["reason"] = why or f"no driver {driver}"
        return step
    if not (drivers_dir(worktree) / "core" / "lane_seed.py").is_file():
        # P pays every lane before the update, REL_FUNDS=0 or not, and a break is meant to fail: only a
        # lane on its permanent seed keeps those coins when it does; a throwaway wallet loses them.
        step["reason"] = "the drivers have no lane seeds: a failed break would strand P's payment"
        return step
    breaks = break_list(worktree)
    brk = break_for((today or dt.date.today()).toordinal(), breaks)
    if brk is None:
        step["reason"] = "no breaks: trust_ids.json unreadable"
        return step
    out = Path(run_dir) / "breaks-linux"
    out.mkdir(parents=True, exist_ok=True)
    env = dict(env_base)
    env.update(env_extra)
    env.update(REL_VARIANT="tor", REL_FUNDS="0", REL_TRUST_BREAK=brk, REL_TRUST_SAVE_STATE="0",
               REL_NODE=TRUST_NODE, REL_EPICBOX=TRUST_EPICBOX, REL_OUT=str(out))
    env.pop("REL_RUN_KIND", None)
    log = out / "driver.log"
    t0 = now()
    rc = (runner or run_driver)([str(driver)], env, log, BREAK_TIMEOUT_S)
    step["duration_s"] = int(now() - t0)
    step["log"] = str(log)
    controls = registry_controls(worktree)
    if rc is None:
        scored = {"break": brk, "target": brk.partition(":")[2], "rc": None, "score": "failed silently",
                  "why": f"timed out after {BREAK_TIMEOUT_S // 60} min"}
    else:
        scored = score_break(brk, rc, out, controls, worktree)
    fix = draft_fix(scored, controls, worktree)
    if fix:
        write_atomic(Path(run_dir) / "breaks-fix.md", fix)
        scored["fix"] = str(Path(run_dir) / "breaks-fix.md")
    write_json(Path(run_dir) / "breaks.json", scored)
    step["breaks"] = scored
    step["status"] = "ok" if scored["score"] in ("recovered right", "failed honestly") else "fail"
    step["reason"] = f"{brk}: {scored['score']}" + (f" ({scored['why']})" if scored.get("why") else "")
    return step


def rig_health(worktree=None, hosts_file=None, probe=None):
    """Every Windows rig session on the box, read-only (the commit's drivers/windows/rig.py health, as
    BT over SSH): {status: ok|dead|unknown, dead: [str], checked: [int]} for latest.json `rigs`.
    `probe(host)` -> {session: (facts, problems)}; injectable for tests."""
    hosts_file = Path(hosts_file or os.environ.get("REL_HOSTS") or HOME / ".config" / "btlabs" / "release-hosts.toml")
    try:
        import tomllib
        host = tomllib.loads(hosts_file.read_text(encoding="utf-8")).get("host", {}).get("windows", {}).get("ssh")
    except (OSError, ValueError):
        host = None
    host = host or "windows-pc"
    try:
        if probe is None:
            import importlib.util
            spec = importlib.util.spec_from_file_location(
                "win_rig", Path(worktree or WORKTREE) / "tools" / "rellib" / "drivers" / "windows" / "rig.py")
            mod = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mod)
            probe = mod.health
        report = probe(host)
    except Exception as e:  # the box asleep or unreachable: unknown, not dead
        return {"status": "unknown", "host": host, "dead": [], "checked": [], "reason": _clip(str(e), 200)}
    dead = [f"rig {k}: " + "; ".join(probs) for k, (_, probs) in sorted(report.items()) if probs]
    return {"status": "dead" if dead else "ok", "host": host, "dead": dead, "checked": sorted(report)}


def rig_step(rigs):
    status = {"ok": "ok", "dead": "fail"}.get(rigs["status"], "skipped")
    step = {"name": "Windows rig health", "group": "rigs", "status": status, "duration_s": 0}
    if rigs["status"] != "ok":
        step["reason"] = "; ".join(rigs["dead"]) or rigs.get("reason", "")
    return step


DRIFT_TIMEOUT_S = 15 * 60
DRIFT_LINES_KEPT = 40


def run_drift(run_dir, env, worktree=None, runner=None):
    """LEPIC's `cargo xtask upstream-drift` at the wallet's pin (tools/lepic.sh xtask), report only:
    exit 2 is drift, exit 0 none, anything else (offline, a build failure) is unknown. Never turns
    the nightly red. Returns {status: clean|drift|unknown, lines: [str], reason}."""
    worktree = Path(worktree or WORKTREE)
    lepic = worktree / "tools" / "lepic.sh"
    try:
        if "  xtask)" not in lepic.read_text(encoding="utf-8"):
            return {"status": "unknown", "lines": [], "reason": "this commit's tools/lepic.sh has no xtask command"}
    except OSError as e:
        return {"status": "unknown", "lines": [], "reason": _clip(str(e), 200)}
    argv = ["nice", "-n", "15", "ionice", "-c3", "build-slot", str(lepic), "xtask", "upstream-drift"]
    log_path = Path(run_dir) / "drift.log"
    try:
        with open(log_path, "w", encoding="utf-8") as log:
            rc, tail = (runner or run_logged)(argv, log, env, str(worktree), timeout=DRIFT_TIMEOUT_S, slot_wait=True)
        lines = [l.split(" ", 1)[-1] if re.match(r"\d\d:\d\d:\d\d ", l) else l
                 for l in log_path.read_text(encoding="utf-8").splitlines()]
    except Exception as e:  # report only: never raised
        return {"status": "unknown", "lines": [], "reason": _clip(f"nightly error: {e}", 200)}
    lines = [l for l in lines if l.strip() and not l.startswith("build-slot:")][-DRIFT_LINES_KEPT:]
    if rc == 0:
        return {"status": "clean", "lines": lines[-3:], "reason": ""}
    if rc == 2:
        return {"status": "drift", "lines": lines, "reason": ""}
    why = "timed out" if rc is None else f"exit {rc}"
    return {"status": "unknown", "lines": lines[-5:], "reason": f"{why}: " + _clip(" / ".join(lines[-2:]), 160)}


def drift_step(drift):
    step = {"name": "LEPIC upstream drift (report only)", "group": "drift",
            "status": "skipped" if drift["status"] == "unknown" else "ok", "duration_s": 0}
    if drift["status"] != "clean":
        step["reason"] = drift["reason"] or "upstream changed since the recorded pins"
    return step


def trust_summary(steps):
    """{status: red|green|skipped, failed: [str]} for the result; None without trust steps."""
    if not steps:
        return None
    failed = [s for s in steps if s["status"] == "fail"]
    if failed:
        return {"status": "red", "failed": [f"{s['platform']}: " + (", ".join(s.get("failing_checks") or [])
                                                                     or s.get("reason", "failed")) for s in failed],
                "step": failed[0]["name"]}
    return {"status": "green" if any(s["status"] == "ok" for s in steps) else "skipped", "failed": []}


# ---------------------------------------------------------------- running the check

def run_logged(cmd, log, env, cwd, timeout=None, slot_wait=False):
    """Runs cmd, appending its output to the open log file with a UTC time prefix per line.
    With slot_wait, the timeout starts once build-slot has a slot (its first other line).
    Returns (exit status or None on timeout, tail lines)."""
    tail = []
    started_at = [] if slot_wait else [time.monotonic()]
    proc = subprocess.Popen(cmd, cwd=cwd, env=env, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL,
                            start_new_session=True)

    def pump():
        for b in iter(proc.stdout.readline, b""):
            line = b.decode("utf-8", "replace").rstrip("\n")
            log.write(f"{utcnow().strftime('%H:%M:%S')} {line}\n")
            log.flush()
            if not started_at and not line.startswith(("build-slot:", "  ")):
                started_at.append(time.monotonic())
            tail.append(line)
            if len(tail) > 60:
                del tail[:-40]

    th = threading.Thread(target=pump, daemon=True)
    th.start()
    rc = None
    while True:
        # the limit counts from the first line that is not build-slot's slot wait, so a run
        # queued for a build slot is not stopped for waiting
        began = started_at[0] if started_at else time.monotonic()
        left = None if timeout is None else began + timeout - time.monotonic()
        if left is not None and left <= 0 and started_at:
            break
        try:
            rc = proc.wait(timeout=30 if left is None else max(1, min(30, left)))
            break
        except subprocess.TimeoutExpired:
            continue
    if rc is None:
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


def check_env(run_dir, by_hand):
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
    env["BUILD_SLOT_WAIT"] = str(BY_HAND_SLOT_WAIT_S if by_hand else TIMER_SLOT_WAIT_S)
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


class Refused(Exception):
    """The busy rules said no right before the check."""


def runner_info(environ=None):
    """Which code ran this nightly: launch.py's WFE_NIGHTLY_RUNNER (worktree:<sha> or
    installed:<why>), else this file started directly."""
    e = os.environ if environ is None else environ
    r = e.get("WFE_NIGHTLY_RUNNER") or f"direct:{Path(__file__).resolve()}"
    kind, _, detail = r.partition(":")
    return {"kind": kind, "detail": detail[:200]}


def cmd_run(by_hand, pinned_sha=None):
    kind = "hand" if by_hand else "timer"
    BASE.mkdir(parents=True, exist_ok=True)
    lock = open(BASE / ".lock", "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        attempt(kind, None, "skipped: another run holds the lock")
        return 0

    state = read_json(BASE / "state.json", {})
    try:
        # launch.py pins the sha whose code this is (--sha): the run tests exactly that commit.
        sha = pinned_sha or git("-C", str(REPO), "rev-parse", "refs/heads/main")
    except (RuntimeError, subprocess.SubprocessError) as e:
        return broken_run(kind, state, None, f"cannot read main: {e}")

    why = refusal(by_hand)
    if why:
        attempt(kind, sha, f"skipped: {why}")
        return 0
    verdict, reason = decide(state, sha)
    if verdict == "skip":
        attempt(kind, sha, f"skipped: {reason}")
        return 0

    started = utcnow()
    stamp = started.strftime("%Y%m%dT%H%M")
    run_dir = BASE / "runs" / f"{stamp}-{sha[:8]}"
    if run_dir.exists():
        shutil.rmtree(run_dir)  # a skipped attempt in the same minute
    run_dir.mkdir(parents=True)
    log_path = run_dir / "check.log"
    env = check_env(run_dir, by_hand)
    env["NIGHTLY_XDG"] = env["XDG_DATA_HOME"]
    error = None
    refused = None
    rc = None
    tail = []
    command = None
    with open(log_path, "w", encoding="utf-8") as log:
        log.write(f"{started.strftime('%H:%M:%S')} nightly {kind} run of main {sha}\n")
        try:
            prepare_worktree(sha, log, env)
            why = refusal(by_hand)
            if why:
                raise Refused(why)
            argv, command = check_command(run_dir)
            log.write(f"{utcnow().strftime('%H:%M:%S')} $ {' '.join(argv)}\n")
            log.flush()
            rc, tail = run_logged(argv, log, env, str(WORKTREE), timeout=CHECK_TIMEOUT_S,
                                  slot_wait=True)
        except Refused as e:
            refused = str(e)
        except Exception as e:  # a broken run is reported, never raised
            error = str(e)[:300]
    ended = utcnow()

    if refused is None and rc == 75 and any("no build slot free" in l for l in tail):
        if by_hand:
            error = "no build slot came while waiting"
        else:
            refused = f"busy (no build slot within {TIMER_SLOT_WAIT_S}s)"
    if refused:
        shutil.rmtree(run_dir, ignore_errors=True)
        attempt(kind, sha, f"skipped: {refused}")
        return 0

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
    trust_steps = []
    if status == "green":
        trust_steps = run_trust(run_dir, {k: v for k, v in env.items()
                                          if k not in ("XDG_DATA_HOME", "NIGHTLY_XDG")})

    break_step = None
    if status == "green":
        try:
            break_step = run_breaks(run_dir, {k: v for k, v in env.items()
                                              if k not in ("XDG_DATA_HOME", "NIGHTLY_XDG")}, trust_steps)
        except Exception as e:  # the break lane never breaks the run
            break_step = {"name": "G4 break linux", "group": "breaks", "platform": "linux", "status": "skipped",
                          "duration_s": 0, "reason": f"nightly error: {str(e)[:150]}"}
    drift = None
    if status != "error":
        drift = run_drift(run_dir, {k: v for k, v in env.items() if k not in ("XDG_DATA_HOME", "NIGHTLY_XDG")})
    rigs = rig_health()
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
        "steps": parsed["steps"] + trust_steps + ([break_step] if break_step else []) + ([drift_step(drift)] if drift else []) + [rig_step(rigs)],
        "drift": drift,
        "trust": trust_summary(trust_steps),
        "breaks": (break_step or {}).get("breaks") or ({"score": "skipped", "why": break_step["reason"]} if break_step else None),
        "rigs": rigs,
        "failing_step": parsed["failing_step"],
        "tests": parsed["tests"],
        "failing_tests": mark_flaky(parsed["failing_tests"]) if status == "red" else parsed["failing_tests"],
        "last_green_sha": sha if status == "green" else last_green,
        "commits_since_green": [] if status == "green" else commits_between(last_green, sha),
        "log": str(log_path),
        "runner": runner_info(),
    }
    if error:
        result["error"] = error
        result["log_tail"] = [l[-200:] for l in tail[-15:]]
    result["notified"] = report(result, state)

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
              "log": None, "error": reason[:300]}
    result["notified"] = report(result, state)
    write_json(BASE / "latest.json", result)
    write_atomic(BASE / "summary.txt", summary_line(result) + "\n")
    write_json(BASE / "state.json", state)
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
    t = r.get("trust")
    if t:
        line += f" | G4 trust {t['status']}" + (": " + "; ".join(t["failed"]) if t["failed"] else "")
        skipped = [s["platform"] for s in r["steps"] if s.get("group") == "trust" and s["status"] == "skipped"]
        if skipped:
            line += f" (skipped: {', '.join(skipped)})"
    b = r.get("breaks")
    if b:
        line += f" | G4 break {b.get('break', '-')}: {b['score']}" + (f" ({b['why']})" if b.get("why") and b["score"] not in ("recovered right",) else "")
    d = r.get("drift") or {}
    if d.get("status") == "drift":
        found = next((m.group(1) for l in reversed(d.get("lines") or [])
                      for m in [re.search(r"(\d+ of \d+ module\(s\))", l)] if m), "upstream changes")
        line += f" | LEPIC upstream drift: {found} (drift.log in the run folder)"
    elif d.get("status") == "unknown":
        line += f" | LEPIC drift unknown: {d.get('reason')}"
    rigs = r.get("rigs") or {}
    if rigs.get("status") == "dead":
        line += " | Windows rig dead: " + "; ".join(rigs["dead"])
    return line


def prune_shared():
    lepic = WORKTREE / "tools" / "lepic.sh"
    try:
        if "prune-shared" in lepic.read_text(encoding="utf-8"):
            subprocess.run([str(lepic), "prune-shared"], cwd=str(WORKTREE), env=check_env_path(),
                           capture_output=True, timeout=1800)
        if "prebuild" in lepic.read_text(encoding="utf-8"):
            # Keeps the shared prebuilt LEPIC cache warm for the pin on main; the result is ignored.
            heavy = shutil.which("build-slot")
            subprocess.run(([heavy] if heavy else []) + [str(lepic), "prebuild"], cwd=str(WORKTREE),
                           env=check_env_path(), capture_output=True, timeout=3600)
    except (OSError, subprocess.SubprocessError):
        pass


# ---------------------------------------------------------------- simulate red

def simulated_red(sha):
    ok = lambda n, d: {"name": n, "status": "ok", "duration_s": d}
    not_run = lambda n: {"name": n, "status": "not_run", "duration_s": None}
    return {
        "status": "red", "sha": sha, "duration_s": 1500, "kind": "test",
        "command": "(simulated: no check ran)",
        "steps": [ok("version (https://docs.btlabs.uk/developers/releases/)", 1),
                  ok("install contract (docs/install-contract.md)", 1),
                  ok("LEPIC at the pin (tools/lepic.rev)", 40),
                  ok("no hosts in code (docs/settings-file.md)", 1),
                  ok("wallet core under plain Dart (no Flutter on its path)", 20),
                  ok("flutter analyze", 90),
                  {"name": "flutter test (all)", "status": "failed", "duration_s": 1100},
                  not_run("integration tests on LEPIC (Linux, offline)"), not_run("bot"),
                  not_run("web build (the preview, tool/build_web.sh)")],
        "failing_step": "flutter test (all)",
        "tests": {"flutter test (all)": {"passed": 6307, "skipped": 45, "failed": 2}},
        "failing_tests": [
            {"file": "app/test/nightly_simulated_test.dart", "name": "TEST a simulated failure one"},
            {"file": "app/test/nightly_simulated_test.dart", "name": "TEST a simulated failure two"}],
        "last_green_sha": None,
        "commits_since_green": commits_between(None, sha, limit=3),
    }


def cmd_simulate_red():
    """Posts the fixture red DM (test: true, TEST before the step); records only in test-runs/."""
    sha = git("-C", str(REPO), "rev-parse", "refs/heads/main")
    started = utcnow()
    run_dir = BASE / "test-runs" / f"{started.strftime('%Y%m%dT%H%M')}-{sha[:8]}"
    result = simulated_red(sha)
    result.update(started=iso(started), ended=iso(started),
                  log=str(run_dir / "check.log") + " (simulated, no log)")
    result["notified"] = report(result, {}, test=True)
    write_json(run_dir / "result.json", result)
    prune_dirs(BASE / "test-runs")
    print(json.dumps(result["notified"], indent=2, ensure_ascii=False))
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(description="Epic Wallet nightly full check (see the header).")
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--by-hand", action="store_true",
                   help="started by a person: any time of day, waits for a build slot")
    g.add_argument("--simulate-red", action="store_true",
                   help="post a TEST red DM from a fixture; no check runs")
    g.add_argument("--parse", metavar="LOG", help="print what the parser reads from a check log")
    ap.add_argument("--sha", help="test this commit of main (launch.py passes the sha its code is from)")
    a = ap.parse_args(argv)
    if a.simulate_red:
        return cmd_simulate_red()
    if a.parse:
        with open(a.parse, encoding="utf-8", errors="replace") as f:
            print(json.dumps(parse_check_log(f), indent=2, ensure_ascii=False))
        return 0
    if a.sha and not re.fullmatch(r"[0-9a-f]{40}", a.sha):
        ap.error("--sha: a full 40-character commit id")
    return cmd_run(a.by_hand, a.sha)


if __name__ == "__main__":
    sys.exit(main())
