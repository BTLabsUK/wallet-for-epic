#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Nightly full check of Epic Wallet's local main, with one Telegram DM to the owner when it is red.

What it is: a script started by a systemd user timer on the build machine (tools/nightly/install.sh puts it
in ~/.local/lib/wfe-nightly/ and the units in ~/.config/systemd/user/). It is not an agent: it runs
the full check on main, records the result and reports. It never fixes, pushes, starts agents or
blocks merges.

  nightly.py                     one attempt, as wfe-nightly.timer runs it (02:30, 03:30, 04:30 and
                                 05:30 local time). It refuses outside 01:00-06:00 local time
                                 (`skipped: daytime`), and skips while any build-slot slot is held
                                 or any tools/rel run is active (`skipped: busy`)
  python3 ~/.local/lib/wfe-nightly/nightly.py --by-hand
                                 the same run started by a person: any time of day, waits for a
                                 build slot, still refuses while a tools/rel run is active
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
  8. runs `tools/lepic.sh prune-shared` when the commit has it, ignoring its result.
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

HOME = Path.home()
REPO = Path(os.environ.get("WFE_NIGHTLY_REPO", HOME / "wallet-for-epic"))
WORKTREE = Path(os.environ.get("WFE_NIGHTLY_WORKTREE", HOME / "wfe-worktrees" / "nightly"))
BASE = Path(os.environ.get("WFE_NIGHTLY_DIR", HOME / "epic-build" / "nightly"))
REL_LOCKS = str(HOME / "epic-build" / "rel" / "*" / "run-*" / ".lock")
NOTIFY_CONF = HOME / ".config" / "wfe-nightly"

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

STEP_RE = re.compile(r"^== (.+?)\s*$")
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
        tests = [_clip(f"{t['file']}: {t['name']}" if t.get("file") else t["name"], DM_TEST_CHARS)
                 for t in (result.get("failing_tests") or [])[:DM_ITEMS]]
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


def trust_inputs(platform, prev, cand):
    """(env for the driver, None) or (None, why it is skipped): the pair's binaries must be on
    disk: `files` holds the desktop and Windows files, `extra`/emulator the x86_64 APKs."""
    pv, cv = prev["version"], cand["version"]
    pf, cf = Path(prev["files"]), Path(cand["files"])
    pe, ce = Path(prev["extra"]), Path(cand["extra"])
    if platform == "linux":
        names = [(pf, f"EpicCashDesktop-{pv}-x86_64.AppImage"), (cf, f"EpicCashDesktop-{cv}-x86_64.AppImage")]
        env = {"REL_PREVIOUS_DIR": str(pf), "REL_CANDIDATE_DIR": str(cf)}
    elif platform == "windows":
        names = [(pf, f"epic-cash-desktop-{pv}-windows-x64-setup.exe"),
                 (cf, f"epic-cash-desktop-{cv}-windows-x64-setup.exe")]
        env = {"REL_PREVIOUS_DIR": str(pf), "REL_CANDIDATE_DIR": str(cf)}
    else:
        names = [(pe / "emulator", f"epic-cash-mobile-{pv}-x86_64.apk"),
                 (ce / "emulator", f"epic-cash-mobile-{cv}-x86_64.apk")]
        env = {"REL_PREVIOUS_DIR": str(pe), "REL_CANDIDATE_DIR": str(cf), "REL_CANDIDATE_EXTRA": str(ce)}
    for d, n in names:
        if not (d / n).is_file():
            return None, f"binary missing: {d / n}"
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


def cmd_run(by_hand):
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
        sha = git("-C", str(REPO), "rev-parse", "refs/heads/main")
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
        "steps": parsed["steps"] + trust_steps,
        "trust": trust_summary(trust_steps),
        "failing_step": parsed["failing_step"],
        "tests": parsed["tests"],
        "failing_tests": parsed["failing_tests"],
        "last_green_sha": sha if status == "green" else last_green,
        "commits_since_green": [] if status == "green" else commits_between(last_green, sha),
        "log": str(log_path),
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
                  not_run("web build (the demo's flags, tool/build_web.sh)")],
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
    a = ap.parse_args(argv)
    if a.simulate_red:
        return cmd_simulate_red()
    if a.parse:
        with open(a.parse, encoding="utf-8", errors="replace") as f:
            print(json.dumps(parse_check_log(f), indent=2, ensure_ascii=False))
        return 0
    return cmd_run(a.by_hand)


if __name__ == "__main__":
    sys.exit(main())
