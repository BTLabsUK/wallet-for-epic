# SPDX-License-Identifier: Apache-2.0
"""Per-lane health of the G4 trust lanes, from <state_root>/metrics.jsonl (docs/RELEASING.md,
"Lane health"). A lane is one trust step id (trust-android-tor); a run's first line for it is its first
try. For the last [health] runs: how often the first try passed, how many tries a run took, how many
AI recoveries the proofs needed, how long a pass takes and what failed. A lane below
[health] min_first_try over at least min_runs runs is weak. Nothing here stops a release: weak lanes
are shown in summary.md, report.html, the gate message and `tools/rel stats --lanes`."""
import json
import os
import pathlib
from collections import Counter
from statistics import median

from .config import PLATFORMS

DEFAULTS = {"runs": 10, "min_first_try": 0.8, "min_runs": 3}


def settings(conf):
    """[health] from pipeline.toml with the defaults filled in."""
    return {k: (conf or {}).get(k, v) for k, v in DEFAULTS.items()}


def is_lane(line):
    """A trust step line of a real run: not a dry run, not an overlap line, trust-<platform>-<variant>."""
    parts = str(line.get("step") or "").split("-")
    return (not line.get("dry") and line.get("kind") != "overlap" and len(parts) >= 3
            and parts[0] == "trust" and parts[1] in PLATFORMS and bool(line.get("status")))


def read_lines(path):
    out = []
    try:
        with open(path, encoding="utf-8") as f:
            for text in f:
                try:
                    line = json.loads(text)
                except json.JSONDecodeError:
                    continue
                if isinstance(line, dict) and is_lane(line):
                    out.append(line)
    except OSError:
        pass
    return out


def lane_health(lines, runs=10, min_first_try=0.8, min_runs=3):
    """[{lane, runs, first_try, rate, tries, recovered, mean_pass_s, last_causes, causes, weak}], by lane.
    lines: the trust lines of metrics.jsonl in file order (read_lines). causes: failed tries in the
    window by cause; last_causes: those of the last run."""
    by = {}
    for ln in lines:
        by.setdefault(ln["step"], {}).setdefault(ln.get("run"), []).append(ln)
    out = []
    for lane in sorted(by):
        window = list(by[lane].items())[-max(1, int(runs)):]
        first = sum(1 for _, ls in window if ls[0]["status"] == "done")
        every = [ln for _, ls in window for ln in ls]
        passes = [ln["duration_s"] for ln in every if ln["status"] == "done" and ln.get("duration_s") is not None]
        causes = Counter(ln.get("cause") or "unknown" for ln in every if ln["status"] == "failed")
        last = Counter(ln.get("cause") or "unknown" for ln in window[-1][1] if ln["status"] == "failed")
        n = len(window)
        out.append({"lane": lane, "runs": n, "first_try": first, "rate": round(first / n, 2),
                    "tries": round(len(every) / n, 1), "recovered": sum(int(ln.get("recovered") or 0) for ln in every),
                    "mean_pass_s": round(sum(passes) / len(passes)) if passes else None,
                    "last_causes": dict(last), "causes": dict(causes),
                    "weak": n >= min_runs and first / n < min_first_try})
    return out


def lanes_of(metrics_path, conf=None):
    """lane_health of the metrics file under the [health] settings in conf."""
    s = settings(conf)
    return lane_health(read_lines(metrics_path), **s)


def causes_text(causes):
    """`harness×4, product×1` (most frequent first), or `-`."""
    return ", ".join(f"{c}×{n}" for c, n in sorted(causes.items(), key=lambda x: (-x[1], x[0]))) or "-"


def weak_line(h):
    """The gate's line for a weak lane."""
    return (f"- {h['lane']}: first try {h['first_try']}/{h['runs']}, {h['tries']:g} tries a run, causes {causes_text(h['causes'])}"
            + (f", recovered {h['recovered']}" if h["recovered"] else ""))


def rows(lanes):
    """The table as [header, [cells]...] for summary.md, report.html and the terminal."""
    head = ["lane", "runs", "first try", "tries/run", "recovered", "pass time", "last run's causes"]
    body = [[h["lane"] + (" (weak)" if h["weak"] else ""), str(h["runs"]), f"{h['first_try']}/{h['runs']} ({h['rate']:.0%})",
             f"{h['tries']:g}", str(h["recovered"]), f"{h['mean_pass_s']}s" if h["mean_pass_s"] is not None else "-",
             causes_text(h["last_causes"])] for h in lanes]
    return [head] + body


def title(conf):
    return f"Lane health (last {settings(conf)['runs']} runs)"


def markdown(lanes, conf=None):
    """The summary.md section; empty when no lane has run."""
    if not lanes:
        return []
    t = rows(lanes)
    return ["", f"## {title(conf)}", "", "| " + " | ".join(t[0]) + " |", "|" + "---|" * len(t[0])] \
        + ["| " + " | ".join(c.replace("|", "/") for c in r) + " |" for r in t[1:]]


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
