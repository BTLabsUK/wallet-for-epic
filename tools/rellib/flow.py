# SPDX-License-Identifier: Apache-2.0
"""The release flow as data: the stages in order with class, needs and outputs (`tools/rel flow`, the
header block of pipeline.toml), the lane table (`tools/rel lanes`, `tools/rel lane`) and the record a
night leaves per commit (<night root>/../lanes/<sha>.json), which `tools/rel cut` and the gate note read."""
import glob
import json
import os
import re
import subprocess
import tomllib

from .config import ConfigError, Pipeline, is_night
from .run import now_iso, read_json

BEGIN = "# flow:begin"
END = "# flow:end"
ORDER = ("common", "night", "release", "publish")
# A stage with several instances (one per variant) shows its worst.
WORST = ("failed", "running", "waiting", "held", "closed", "pending", "refused", "done", "skipped")


def class_of(spec):
    return "informs" if spec.get("warn_only") else "blocks"


def _stage_of(name, spec, night_names):
    if spec.get("publish") or spec.get("kind") == "publish":
        return "publish"
    if is_night(spec):
        return "night"
    return "common" if name in night_names else "release"


def flow_stages(pipeline):
    """The steps by name, in the order they run: what night and release share, night, release, publish."""
    night_names = pipeline.stage_steps("night")
    release_names = pipeline.stage_steps("release")
    seen, order = set(), []

    def visit(name):
        if name in seen:
            return
        seen.add(name)
        for n in pipeline.steps[name].get("needs", []):
            visit(n.split("@")[0])
        order.append(name)

    for name in pipeline.steps:
        visit(name)
    rows = []
    for name in order:
        spec = pipeline.steps[name]
        stage = _stage_of(name, spec, night_names)
        rows.append({"name": name, "title": spec.get("title", name), "stage": stage,
                     "runs_in": [s for s, names in (("night", night_names), ("release", release_names)) if name in names],
                     "class": class_of(spec), "kind": spec.get("kind", "command"),
                     "needs": list(spec.get("needs", [])), "outputs": list(spec.get("outputs", []))})
    rows.sort(key=lambda r: ORDER.index(r["stage"]))  # stable: the order inside a stage stays
    return rows


def flow_lines(pipeline):
    """One line per stage: what `tools/rel flow` prints and the header block of pipeline.toml holds."""
    lines = []
    for r in flow_stages(pipeline):
        lines.append(f"{r['stage']:8} {r['class']:8} {r['name']:24} needs {', '.join(r['needs']) or '-'}"
                     + (f"; outputs {', '.join(r['outputs'])}" if r["outputs"] else ""))
    return lines


def header_block(pipeline):
    return "\n".join([BEGIN + " (tools/rel flow --write; a test fails when it differs from the steps below)",
                      *("# " + x for x in flow_lines(pipeline)), END])


def header_lines(text):
    """The stage lines in pipeline.toml's header block, without the comment mark."""
    if BEGIN not in text or END not in text:
        return None
    body = text[text.index(BEGIN):text.index(END)].splitlines()[1:]
    return [x[2:] for x in body]


def rewrite_header(text, pipeline):
    if BEGIN not in text or END not in text:
        raise ConfigError(f"no {BEGIN} block in the pipeline file")
    a, b = text.index(BEGIN), text.index(END) + len(END)
    return text[:a] + header_block(pipeline) + text[b:]


# ---- the lane table ----

def lane_bases(pipeline):
    """A lane: a night step, or a proof step of the release (G4)."""
    return [(n, "night" if is_night(s) else "release") for n, s in pipeline.steps.items()
            if is_night(s) or s.get("proof")]


def lanes_dir(pipeline):
    return os.path.join(os.path.dirname(pipeline.night_root()), "lanes")


def night_records(lanes_path):
    """The night records, oldest first."""
    out = []
    for p in glob.glob(os.path.join(lanes_path, "*.json")):
        rec = read_json(p, None)
        if isinstance(rec, dict) and rec.get("sha") and isinstance(rec.get("lanes"), dict):
            out.append(rec)
    return sorted(out, key=lambda r: r.get("ended") or "")


def _metric_runs(path):
    """The proof lanes' runs from metrics.jsonl: {base: [one summary per run, oldest first]}."""
    by = {}
    try:
        lines = open(path, encoding="utf-8").read().splitlines()
    except OSError:
        return {}
    for line in lines:
        try:
            r = json.loads(line)
        except ValueError:
            continue
        if not isinstance(r, dict) or not r.get("base") or r.get("dry") or r.get("reused"):
            continue
        runs = by.setdefault(r["base"], {})
        cur = runs.setdefault(r.get("run"), {"status": r.get("status"), "warned": False, "sha": "", "ended": ""})
        cur["status"] = worst(cur["status"], r.get("status"))
        cur["warned"] = cur["warned"] or bool(r.get("warned"))
        cur["sha"] = r.get("commit") or cur["sha"]  # older lines have none
        cur["ended"] = r.get("ended") or cur["ended"]
    return {b: list(runs.values()) for b, runs in by.items()}


def worst(a, b):
    rank = lambda s: WORST.index(s) if s in WORST else 0
    return a if rank(a) <= rank(b) else b


def _green(entry):
    return entry["status"] == "done" and not entry["warned"]


def lanes_table(pipeline, state_root):
    records = night_records(lanes_dir(pipeline))
    metrics = _metric_runs(os.path.join(state_root, "metrics.jsonl"))
    table = []
    for base, stage in lane_bases(pipeline):
        spec = pipeline.steps[base]
        if stage == "night":
            history = [{"status": r["lanes"][base].get("status"), "warned": bool(r["lanes"][base].get("warned")),
                        "sha": r["sha"], "ended": r.get("ended") or ""} for r in records if base in r["lanes"]]
        else:
            history = metrics.get(base, [])
        streak = 0
        for e in reversed(history):
            if not _green(e):
                break
            streak += 1
        table.append({"base": base, "title": spec.get("title", base), "class": class_of(spec), "stage": stage,
                      "last": history[-1] if history else None, "green_streak": streak})
    return table


def set_class(text, base, cls, path="release/pipeline.toml"):
    """The file with this one step's class changed and the header block matching. Raises ConfigError
    when the pipeline refuses it (warn_only never goes on a gate, proof or build)."""
    m = re.search(rf"^\[step\.{re.escape(base)}\]\n(.*?)(?=^\[|\Z)", text, re.M | re.S)
    if not m:
        raise ConfigError(f"no step {base} in {path}")
    body = re.sub(r"^warn_only = true\n", "", m.group(1), flags=re.M)
    if cls == "informs":
        title = re.search(r"^title = .*\n", body, re.M)
        at = title.end() if title else 0
        body = body[:at] + "warn_only = true\n" + body[at:]
    text = text[:m.start(1)] + body + text[m.end(1):]
    return rewrite_header(text, Pipeline(tomllib.loads(text), path))


def change_class(main, base, cls, pipeline):
    """Rewrite one line of the main checkout's pipeline.toml and commit only that file. -> commit or
    a refusal as ConfigError."""
    rel = "release/pipeline.toml"
    if base not in {b for b, _ in lane_bases(pipeline)}:
        raise ConfigError(f"{base} is not a lane (tools/rel lanes)")

    def git(*args):
        return subprocess.run(["git", "-C", main, *args], capture_output=True, text=True, check=False)

    branch = git("rev-parse", "--abbrev-ref", "HEAD").stdout.strip()
    if branch != "main":
        raise ConfigError(f"{main} is on {branch or '?'}, not main")
    if git("status", "--porcelain", "--", rel).stdout.strip():
        raise ConfigError(f"{main}/{rel} has uncommitted changes: nothing rewritten")
    path = os.path.join(main, rel)
    with open(path, encoding="utf-8") as f:
        text = f.read()
    new = set_class(text, base, cls, path)
    if new == text:
        return None
    with open(path, "w", encoding="utf-8") as f:
        f.write(new)
    done = git("commit", "-q", "-m", f"Lanes: {base} {cls}", "--", rel)
    if done.returncode:
        git("checkout", "--", rel)
        raise ConfigError(f"git commit: {done.stderr.strip()}")
    return git("rev-parse", "HEAD").stdout.strip()


# ---- what a night leaves ----

def write_night_record(run):
    """<night root>/../lanes/<sha>.json: every night step of the run. Rewritten at each end, so a
    retry of one lane shows. `class` is the run's own (plan.json froze warn_only)."""
    lanes = {}
    for s in run.steps:
        st = run.status(s.id)
        status = st.get("status")
        cur = lanes.setdefault(s.base, {"class": "informs" if s.warn_only else "blocks", "status": status, "warned": False, "note": "",
                                        "duration_s": 0.0})
        if worst(status, cur["status"]) == status and status != cur["status"]:
            cur["note"] = ""
        cur["status"] = worst(cur["status"], status)
        cur["warned"] = cur["warned"] or bool(st.get("warned"))
        cur["note"] = cur["note"] or st.get("note") or st.get("reason") or ""
        cur["duration_s"] += st.get("duration_s") or 0.0
    night = set(run.info.get("night_steps") or [])
    source = lanes.get("source-check", {}).get("status", "missing")
    rec = {"sha": run.info["commit"], "ended": now_iso(), "run_id": run.info["run_id"], "version": run.info["version"],
           "source": {"status": source}, "lanes": {b: v for b, v in lanes.items() if b in night}}
    d = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(run.path))), "lanes")
    os.makedirs(d, exist_ok=True)
    tmp = os.path.join(d, f".{rec['sha']}.tmp")
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(rec, f, indent=1)
    os.replace(tmp, os.path.join(d, f"{rec['sha']}.json"))
    return rec
