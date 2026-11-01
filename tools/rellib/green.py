#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Green records: `tools/check.sh --full` that passed on a clean tree leaves one, so tools/rel's
G2 can take that result for any candidate with the same content key (tools/rellib/reuse.py,
docs/RELEASING.md "Reused results").

  python3 tools/rellib/green.py record --root <checkout> --started <epoch seconds>

writes ${WFE_GREEN_DIR:-/tmp/epic-build/green}/<sha>.json:
  {"sha", "tree", "status": "green", "clean": true, "command": "tools/check.sh --full",
   "started", "ended", "duration_s", "host", "by", "checkout"}
and keeps the newest KEEP records. A tree with changes (tracked or untracked, ignored files aside)
gets no record: its result is not that commit's. Never fails the check that called it (exit 0).
Python 3 standard library only.
"""
import argparse
import datetime as dt
import glob
import json
import os
import socket
import subprocess
import sys

KEEP = 200


def iso(t):
    return dt.datetime.fromtimestamp(t, dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def git(root, *args):
    p = subprocess.run(["git", "-C", root, *args], capture_output=True, text=True)
    if p.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)}: {p.stderr.strip()[-200:]}")
    return p.stdout


def green_dir():
    return os.path.expanduser(os.environ.get("WFE_GREEN_DIR") or "/tmp/epic-build/green")


def record(root, started, now=None, command="tools/check.sh --full"):
    """-> (path or None, message)."""
    dirty = git(root, "status", "--porcelain", "--untracked-files=normal").strip()
    sha = git(root, "rev-parse", "HEAD").strip()
    if dirty:
        return None, (f"green record: not written: {root} has changes ({len(dirty.splitlines())} path(s)); "
                      "G2 takes only a clean commit's result")
    end = now if now is not None else dt.datetime.now(dt.timezone.utc).timestamp()
    scratch = os.environ.get("TMPDIR", "").rstrip("/")
    rec = {
        "sha": sha, "tree": git(root, "rev-parse", "HEAD^{tree}").strip(), "status": "green", "clean": True,
        "command": command, "started": iso(started) if started else None, "ended": iso(end),
        "duration_s": int(end - started) if started else None, "host": socket.gethostname(),
        "by": os.path.basename(scratch) if scratch else os.environ.get("USER", "?"), "checkout": root,
    }
    d = green_dir()
    os.makedirs(d, exist_ok=True)
    path = os.path.join(d, f"{sha}.json")
    tmp = f"{path}.{os.getpid()}.tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(rec, f, indent=1)
        f.write("\n")
    os.replace(tmp, path)
    old = sorted(glob.glob(os.path.join(d, "*.json")), key=os.path.getmtime)
    for p in old[:-KEEP] if len(old) > KEEP else []:
        try:
            os.remove(p)
        except OSError:
            pass
    return path, f"green record: {path} (tools/rel G2 reuses it for this content)"


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("record")
    r.add_argument("--root", required=True)
    r.add_argument("--started", type=float, default=0)
    a = ap.parse_args(argv)
    try:
        _, msg = record(a.root, a.started)
    except (OSError, RuntimeError) as e:
        msg = f"green record: not written ({e})"
    print(msg)
    return 0


if __name__ == "__main__":
    sys.exit(main())
