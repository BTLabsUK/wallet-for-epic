#!/usr/bin/env python3
"""The nightly's stop alarm (A-01): a separate timer runs this once a morning.

When no night result landed in the last ALARM_WINDOW_H hours it sends one message through the
nightly's own notify path (nightly.post_dm), once per day. A run that was skipped because main is
unchanged (or already green) counts as a result. It also writes the latest result's verdict into
by-commit.json (green or red, by commit), so the record stays right even when the nightly itself
did not get that far.

It sees the nightly being off: with the timer disabled or the service failing, no result and no
attempt appear, and this alarm is the only thing that still fires. It starts nothing and changes no
nightly files except by-commit.json and alarm.json.

  alarm.py            check, and send when due
  alarm.py --dry-run  print what would be sent
"""
import argparse
import fcntl
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import nightly as n  # noqa: E402

ALARM_WINDOW_H = 26  # one night plus slack for the 07:15 check
ALIVE_SKIPS = ("skipped: unchanged", "skipped: already green")


def last_attempt(path=None):
    """(time, line) of the newest attempts.log line, or (None, '')."""
    try:
        lines = [l for l in Path(path or n.BASE / "attempts.log").read_text(encoding="utf-8").splitlines() if l.strip()]
    except OSError:
        return None, ""
    for line in reversed(lines):
        try:
            return n.parse_iso(line.split(" ", 1)[0]), line
        except (ValueError, TypeError):
            continue
    return None, ""


def running(base):
    """True while a nightly run holds BASE/.lock (non-blocking probe)."""
    try:
        with open(Path(base) / ".lock", "a") as f:
            try:
                fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                return True
            fcntl.flock(f, fcntl.LOCK_UN)
    except OSError:
        pass
    return False


def alive(now=None, base=None):
    """(True, why) when a night result landed in the window; else (False, what was seen)."""
    base = Path(base or n.BASE)
    now = now or n.utcnow()
    limit = ALARM_WINDOW_H * 3600
    latest = n.read_json(base / "latest.json", {})
    try:
        if (now - n.parse_iso(latest["ended"])).total_seconds() < limit:
            return True, f"result {latest.get('status')} {str(latest.get('sha'))[:8]}"
    except (KeyError, ValueError, TypeError):
        pass
    for rec in n.read_json(base / "by-commit.json", {}).values():  # written as the source check ends
        try:
            if (now - n.parse_iso(rec["ended"])).total_seconds() < limit:
                return True, f"source check {rec.get('status')} recorded"
        except (KeyError, ValueError, TypeError):
            pass
    if running(base):
        return True, "a run holds the lock"
    when, line = last_attempt(base / "attempts.log")
    if when and (now - when).total_seconds() < limit and any(k in line for k in ALIVE_SKIPS):
        return True, "main unchanged"
    seen = f"last attempt: {line[:160]}" if line else "no attempt recorded"
    return False, seen


def alarm_body(now, seen, latest, test=False):
    sha = str(latest.get("sha") or "0" * 40)
    day = now.strftime("%Y%m%d")
    last = (latest.get("ended") or "never")[:16].replace("T", " ")
    return {"kind": "broken", "sha": sha, "key": f"nightly-{'test-' if test else ''}alarm-{day}",
            "step": "no night result",
            "reason": n._clip(f"No nightly result in {ALARM_WINDOW_H} h (last: {last}Z). {seen}", 300)}


def run(dry=False, now=None, base=None, conf_dir=None, opener=None, sleep=None):
    base = Path(base or n.BASE)
    now = now or n.utcnow()
    latest = n.read_json(base / "latest.json", {})
    if latest.get("sha") and latest.get("status") in ("green", "red"):
        n.record_by_commit(latest["sha"], latest["status"], latest.get("ended"), path=base / "by-commit.json")
    ok, why = alive(now, base)
    if ok:
        print(f"nightly alive: {why}")
        return 0
    body = alarm_body(now, why, latest)
    if dry:
        print("would send:", json.dumps(body))
        return 1
    state = n.read_json(base / "alarm.json", {})
    sent = state.setdefault("sent_keys", [])
    if body["key"] in sent:
        print("alarm already sent today")
        return 1
    conf = n.notify_config(conf_dir)
    if conf is None:
        print("alarm: notify not configured", file=sys.stderr)
        return 1
    out = n.post_dm(body, *conf, opener=opener, **({"sleep": sleep} if sleep else {}))
    if out.get("sent"):
        sent.append(body["key"])
        del sent[:-30]
        n.write_json(base / "alarm.json", state)
    print("alarm:", json.dumps(out))
    return 1  # the unit shows failed while the nightly is down


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--dry-run", action="store_true")
    return run(dry=ap.parse_args(argv).dry_run)


if __name__ == "__main__":
    sys.exit(main())
