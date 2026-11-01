#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Starts the nightly with main's own code (wfe-nightly.service runs this; tools/nightly/install.sh
puts it in ~/.local/lib/wfe-nightly/ beside a fallback copy of nightly.py).

The installed nightly.py used to be the runner, and it drifted from main: on 2026-11-01 the 03:30
run recorded no trust steps although main had had them since the day before. Now this small,
rarely changing launcher:
  1. reads refs/heads/main of the repo (WFE_NIGHTLY_REPO, default %h/wallet-for-epic);
  2. moves the code worktree (WFE_NIGHTLY_CODE_WORKTREE, default ~/wfe-worktrees/nightly-code;
     detached, used by nothing else, created when missing) to that sha: checkout --force, then
     git clean -ffdxq, so it holds exactly the commit's files;
  3. runs that worktree's tools/nightly/nightly.py with --sha <sha> (the run tests that sha, even
     when main moves meanwhile) and WFE_NIGHTLY_RUNNER=worktree:<sha>, which result.json records.
If any of that fails, or the commit's nightly.py does not compile, it runs the installed copy
(WFE_NIGHTLY_FALLBACK, default ~/.local/lib/wfe-nightly/nightly.py) with
WFE_NIGHTLY_RUNNER=installed:<why>, and attempts.log says so: a red or broken nightly is still
reported. Arguments (--by-hand, --simulate-red, --parse) pass through.
Python 3 standard library only.
"""
import fcntl
import os
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
REPO = Path(os.environ.get("WFE_NIGHTLY_REPO", HOME / "wallet-for-epic"))
CODE = Path(os.environ.get("WFE_NIGHTLY_CODE_WORKTREE", HOME / "wfe-worktrees" / "nightly-code"))
FALLBACK = Path(os.environ.get("WFE_NIGHTLY_FALLBACK", HOME / ".local" / "lib" / "wfe-nightly" / "nightly.py"))
BASE = Path(os.environ.get("WFE_NIGHTLY_DIR", HOME / "epic-build" / "nightly"))


def git(*args, cwd=None):
    r = subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True, timeout=600)
    if r.returncode != 0:
        raise RuntimeError(f"git {' '.join(args[:3])}: {(r.stderr or r.stdout).strip()[-200:]}")
    return r.stdout.strip()


def prepare(sha, repo=REPO, code=CODE):
    """The code worktree at sha with exactly the commit's files; -> its nightly.py."""
    if not (code / ".git").exists():
        code.parent.mkdir(parents=True, exist_ok=True)
        git("-C", str(repo), "worktree", "add", "--detach", str(code), sha)
    git("checkout", "--quiet", "--force", "--detach", sha, cwd=str(code))
    git("clean", "-ffdxq", cwd=str(code))
    head = git("rev-parse", "HEAD", cwd=str(code))
    if head != sha:
        raise RuntimeError(f"code worktree at {head[:8]}, not {sha[:8]}")
    script = code / "tools" / "nightly" / "nightly.py"
    if not script.is_file():
        raise RuntimeError(f"{sha[:8]} has no tools/nightly/nightly.py")
    compile(script.read_text(encoding="utf-8"), str(script), "exec")  # SyntaxError: the fallback runs
    return script


def takes_sha(script):
    """True when that nightly.py knows --sha (older commits do not)."""
    try:
        return "--sha" in Path(script).read_text(encoding="utf-8")
    except OSError:
        return False


def choose(argv, repo=REPO, code=CODE, fallback=FALLBACK, base=BASE):
    """-> (argv to exec, runner label, note or None)."""
    passthrough = [a for a in argv if a != "--sha"]
    base.mkdir(parents=True, exist_ok=True)
    try:
        with open(base / ".launch.lock", "w") as lk:
            fcntl.flock(lk, fcntl.LOCK_EX)  # two launchers never move the code worktree at once
            sha = git("-C", str(repo), "rev-parse", "refs/heads/main")
            script = prepare(sha, repo, code)
    except (OSError, RuntimeError, subprocess.SubprocessError, SyntaxError, ValueError) as e:
        why = str(e).replace("\n", " ")[:200]
        return [sys.executable, str(fallback), *passthrough], f"installed:{why}", f"launcher: fallback to the installed copy ({why})"
    extra = ["--sha", sha] if takes_sha(script) else []
    return [sys.executable, str(script), *passthrough, *extra], f"worktree:{sha}", None


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    cmd, runner, note = choose(argv)
    if note:
        try:
            BASE.mkdir(parents=True, exist_ok=True)
            with open(BASE / "attempts.log", "a", encoding="utf-8") as f:
                import datetime as dt
                f.write(f"{dt.datetime.now(dt.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')} "
                        f"launch -        {note}\n")
        except OSError:
            pass
        print(note, file=sys.stderr)
    env = dict(os.environ, WFE_NIGHTLY_RUNNER=runner)
    os.execve(cmd[0], cmd, env)


if __name__ == "__main__":
    main()
