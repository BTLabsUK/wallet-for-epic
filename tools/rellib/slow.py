# SPDX-License-Identifier: Apache-2.0
"""Steps that got slower, from <state_root>/metrics.jsonl: shown by `tools/rel stats` and in the
gate message. Nothing here stops a release."""
import json
import os
import pathlib
from statistics import median

SLOW_FACTOR = 1.3  # a step this far over its median is reported
SLOW_MIN_RUNS = 3


def slow_steps(path):
    """The steps whose latest passing runs sit 30% over the median before them: [{step, last_s,
    median_s, over_pct, commit}], commit being the first run that moved it (empty on older lines)."""
    by = {}
    try:
        lines = pathlib.Path(path).read_text(encoding="utf-8").splitlines()
    except OSError:
        return []
    for line in lines:
        try:
            r = json.loads(line)
        except ValueError:
            continue
        if isinstance(r, dict) and r.get("base") and r.get("status") == "done" and not r.get("dry") and not r.get("reused"):
            by.setdefault(r["base"], []).append(r)
    out = []
    for base, rows in sorted(by.items()):
        d = [r.get("duration_s") or 0 for r in rows]
        for i in range(SLOW_MIN_RUNS, len(d)):
            med = median(d[:i])
            if med > 0 and all(x > SLOW_FACTOR * med for x in d[i:]):
                out.append({"step": base, "last_s": d[-1], "median_s": med, "over_pct": round((d[-1] / med - 1) * 100),
                            "commit": rows[i].get("commit") or ""})
                break
    return out


def slow_line(h):
    return f"Slower: {h['step']} {h['last_s']:.0f}s, median {h['median_s']:.0f}s (+{h['over_pct']}%), moved at {h['commit'][:12] or 'an older commit'}"


def metrics_path(run):
    """metrics.jsonl beside the run folders (<state_root>/<version>/<run>/ is two levels down)."""
    return os.path.join(os.path.dirname(os.path.dirname(run.path)), "metrics.jsonl")
