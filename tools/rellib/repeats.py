# SPDX-License-Identifier: Apache-2.0
"""No blind retry: what a failed lane attempt leaves behind, and what may start the lane again.

Each failed attempt adds one record to the step's status `failures`: the failing step's name, the
cause, the kind, the phase, the driver and the seconds. verdict() reads them and says whether the
lane may start; tools/rel retry, run, resume and debug --exec all ask it.

Kinds. infra: the machine (cause infra:*: an InfraFault, a signal, ssh, no proof, no slot). harness:
the driver could not do its step (cause harness, harness:crash). product: the app did the wrong
thing (cause product, or false checks). A lane without a proof step (create, tx) has the cause
`step`, and takes its kind from the fault in its proof.json. Anything else is `other`.

Rules, on the failures of the bytes under test (a build that ran again is a new test):
- harness at a named step: refused until `tools/rel probe` has passed that step alone on the same
  platform, on a driver commit newer than the failure that changes the drivers. --fresh does not
  stand in for it. A harness failure that names no step has nothing to probe: the next rule covers it.
- the same failure twice (same step, same cause): no further automatic attempt, the other lanes go
  on. By hand, an infra failure retries as ever; the others need `retry --fresh "<reason>"`.
- one product or infra failure: no rule here. An infra failure gets its automatic retry.

A failure from before these records carries none, so it is not gated.

A lane with REL_TRUST_PARK set (every gated lane but a dry run or a probe) does not end at a harness
fault: it parks where it stands (core/hold.py). `tools/rel continue` carries it on from that action;
nothing here counts a park as a failed attempt. A lane that is gone goes on through the rules above,
with the change in the drivers standing in for the probe.

Each attempt also adds to the status: attempt_seconds, repeats (attempts after a failure),
seconds_repeated and forced ([{attempt, reason, at}], `repeats_forced` in the rows). The same go to
the `end` event and metrics.jsonl for the Release panel."""
import contextlib
import json
import os
import subprocess
import uuid

from . import evidence
from .run import now_iso, read_json

# Only tools/rel sets these on a lane: from a caller's shell they would be a way round the rules.
PRIVATE = ("REL_TRUST_FRESH", "REL_TRUST_PROBE", "REL_PROBE_PHASE", "REL_PROBE_FROM", "REL_PRIOR_CAUSE",
           "REL_TRUST_RESUME", "REL_TRUST_PARK")
PARK_S = 7200  # how long a lane waits at a fault for tools/rel continue, before it ends as it would have
PARKED, ASK, ANSWER, CONTINUES = "parked.json", "continue.json", "continue-done.json", "continues.jsonl"  # core/hold.py
OUTSIDE = ("windows/agent.ps1", "linux/atspi_worker.py", "linux/standin.py")  # run beside the lane process, no reload reaches them
NEW_BYTES = "the build changed since the failed attempt"
REFUSED = "check: refused"


def gated(step):
    """A lane: what a run reaches over a driver, and what a repeat costs the most on."""
    return bool(step.driven or step.env.get("REL_TRUST_MODE") or step.env.get("REL_TX_PART"))


def platform_of(step):
    return step.platforms[0] if len(step.platforms) == 1 else None


def kind_of(cause, fault=None):
    cause = cause or ""
    if cause.startswith("infra:"):
        return "infra"
    if cause.startswith("harness"):
        return "harness"
    if cause == "product":
        return "product"
    kind = (fault or {}).get("kind")
    if cause == "step" and kind in ("harness", "product", "infra"):
        return kind
    return "other"


def proof_of(eng, step, started):
    """The proof.json this attempt wrote, or {}: a step that is no proof step leaves the last one lying."""
    path = os.path.join(eng.run.step_dir(step.id), "out", "proof.json")
    try:
        if os.path.getmtime(path) < started:
            return {}
    except OSError:
        return {}
    proof = read_json(path)
    return proof if isinstance(proof, dict) else {}


def failure(eng, step, attempt, result, seconds, started, driver):
    """The record of a failed attempt, or None for a start the lane refused: nothing ran."""
    cause = result.get("cause")
    proof = proof_of(eng, step, started)
    if cause == REFUSED or proof.get("refused"):
        return None
    fault = proof.get("fault") or {}
    phases = proof.get("phases") or {}
    kept = phases.get("kept") or []
    bad = result.get("failed_checks")
    return {"attempt": attempt, "cause": cause, "kind": kind_of(cause, fault),
            "step": fault.get("step") or ("check " + ",".join(bad) if bad else cause),
            "what": str(fault.get("what") or result.get("note") or cause)[:200],
            "phase": phases.get("failed") or (kept[0]["phase"] if kept else None), "driver": driver,
            "seconds": seconds, "at": now_iso(), "inputs": eng.inputs_digest(step)}


def signature(fail):
    return fail["step"], fail["cause"], fail.get("inputs")


def named(fail):
    """The failure names a step a probe can stop at. Otherwise its `step` is a stand-in."""
    return fail["step"] != fail["cause"] and not fail["step"].startswith("check ")


def same_twice(failures):
    return len(failures) >= 2 and signature(failures[-1]) == signature(failures[-2])


def verdict(eng, step, st=None, manual=False, fresh=None):
    """None when the step may start again, else {"rule", "line"}. manual: tools/rel retry or run; the
    other callers are the automatic ones."""
    st = st or eng.run.status(step.id)
    fails = st.get("failures") or []
    if eng.dry or eng.run.info.get("dry") or not gated(step) or not fails:
        return None
    if st.get("status") != "failed" and not st.get("warned"):
        return None
    last = fails[-1]
    if st.get("go_on") == last["attempt"]:
        return None  # tools/rel continue let this one past: the driver changed, the lane was gone
    if last.get("inputs") != eng.inputs_digest(step):
        return None
    if last["kind"] == "harness" and named(last):
        why = probe_gap(eng, step, last)
        return {"rule": "needs-probe", "line": why} if why else None
    if not same_twice(fails) or (manual and (fresh or last["kind"] == "infra")):
        return None
    where = f"{step.id} failed the same way twice at {last['step']} ({last['cause']})"
    if manual:
        return {"rule": "same-failure", "line": f"refused: {where}. Only with a reason: "
                                                f"tools/rel retry {step.id} --fresh \"<reason>\""}
    back = (f"tools/rel retry {step.id}" if last["kind"] == "infra"
            else f"only with a reason: tools/rel retry {step.id} --fresh \"<reason>\"")
    return {"rule": "same-failure", "line": f"stopped: {where}: no further automatic attempts, the other "
                                            f"lanes carry on. To go again: {back}"}


def all_probes(run):
    return [p for s in run.steps for p in run.status(s.id).get("probes") or []]


def probe_gap(eng, step, fail):
    """None when a probe in this run proves fail's step on this platform, else the refusal."""
    name, platform = fail["step"], platform_of(step)
    old = fail.get("driver") or {}
    head = (f"refused: {step.id} failed on the driver at {name} (harness, attempt {fail['attempt']}, driver "
            f"{evidence.driver_label(old)}). A retry needs that step passed alone on {platform or 'its platform'} "
            f"on a newer driver commit: change the driver, commit it, then tools/rel probe {name} {step.id}.")
    why = None
    for p in reversed([p for p in all_probes(eng.run) if p["step"] == name and p["passed"]]):
        why = probe_flaw(eng, step, p, old, platform)
        if not why:
            return None
        if p.get("platform") == platform:
            break  # the newest pass on this platform says what is missing
    return f"{head} {why}" if why else head


def probe_flaw(eng, step, probe, old, platform):
    """What keeps a passed probe from counting, or None."""
    tag = f"probe {probe['n']} on {probe['target']}"
    driver = probe.get("driver") or {}
    if probe.get("platform") != platform:
        return f"The pass on {probe.get('platform')} ({tag}) does not count."
    if platform is None and probe["target"] != step.id:
        return f"The pass on {probe['target']} ({tag}) does not count."
    if driver.get("dirty"):
        return f"The pass with uncommitted driver changes ({tag}) does not count."
    commit, repo = driver.get("commit"), eng.runner
    if old.get("commit") and not newer(repo, old["commit"], commit):
        return f"The pass on {evidence.driver_label(driver)} ({tag}) is not newer than the failure."
    if old.get("commit") and tree(repo, old["commit"]) == tree(repo, commit):
        return f"The pass on {evidence.driver_label(driver)} ({tag}) changed nothing in the drivers."
    now = evidence.driver_record(repo)
    if now.get("dirty"):
        return f"This checkout has uncommitted driver changes, which {tag} did not run."
    if now.get("commit") != commit and not newer(repo, commit, now.get("commit")):
        return f"This checkout does not hold {evidence.driver_label(driver)}, which {tag} passed on."
    return None


def _git(repo, *args):
    return subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True)


def newer(repo, old, new):
    """new is a later commit than old, on its line."""
    return bool(old and new) and old != new and _git(repo, "merge-base", "--is-ancestor", old, new).returncode == 0


def changed(repo, old, new):
    """The driver files between two commits."""
    if not (old and new) or old == new:
        return []
    return _git(repo, "diff", "--name-only", old, new, "--", evidence.DRIVERS_DIR).stdout.split()


def tree(repo, commit):
    return _git(repo, "rev-parse", f"{commit}:{evidence.DRIVERS_DIR}").stdout.strip()


def last_cause(st):
    """The cause of the last attempt that ran: a lane that left no proof goes by it."""
    fails = st.get("failures") or []
    if fails:
        return fails[-1]["cause"]
    ran = [c for c in st.get("attempt_causes") or [] if c != REFUSED]
    return ran[-1] if ran else None


def attempt_env(eng, step, st):
    """What this attempt's lane must know of the last one."""
    env = {}
    fails = st.get("failures") or []
    prior = last_cause(st)
    if gated(step) and not eng.dry:
        env["REL_TRUST_PARK"] = str(PARK_S)
    if prior and gated(step):
        env["REL_PRIOR_CAUSE"] = prior
    if st.get("fresh"):
        env["REL_TRUST_FRESH"] = st["fresh"]
    elif fails and gated(step) and fails[-1].get("inputs") != eng.inputs_digest(step):
        env["REL_TRUST_FRESH"] = NEW_BYTES  # other bytes: a new test, nothing of the old one to resume
    return env


def clear_park(stage):
    """A new attempt: what the last one left of a park means nothing to it."""
    for name in (PARKED, ASK, ANSWER, CONTINUES):
        with contextlib.suppress(OSError):
            os.remove(os.path.join(stage, name))


def parked(stage):
    """The park the lane in stage holds, or None. A lane that went took its park with it."""
    park = read_json(os.path.join(stage, PARKED))
    if not isinstance(park, dict) or not park.get("pid"):
        return None
    try:
        os.kill(park["pid"], 0)
    except ProcessLookupError:
        return None
    except PermissionError:
        pass
    return park


def continues(stage):
    """What the lane in stage continued from, in order."""
    try:
        with open(os.path.join(stage, CONTINUES), encoding="utf-8") as f:
            return [json.loads(line) for line in f if line.strip()]
    except (OSError, ValueError):
        return []


def ask_park(stage, driver, stop=False):
    """Tells the parked lane to go on. -> the token its answer carries."""
    token = uuid.uuid4().hex
    path = os.path.join(stage, ASK)
    with open(path + ".tmp", "w", encoding="utf-8") as f:
        json.dump({"token": token, "driver": driver, "stop": stop}, f)
    os.replace(path + ".tmp", path)
    return token


def park_answer(stage, token):
    answer = read_json(os.path.join(stage, ANSWER))
    return answer if isinstance(answer, dict) and answer.get("token") == token else None


def forced(st, attempt):
    """The status field of an attempt started with --fresh."""
    if not st.get("fresh"):
        return {}
    return {"forced": (st.get("forced") or []) + [{"attempt": attempt, "reason": st["fresh"], "at": now_iso()}]}


def tally(st, result, seconds):
    """The attempt's status fields, once it has ended, and whether it counted as a repeat."""
    again = bool(st.get("attempt_causes")) and result.get("cause") != REFUSED
    out = {"attempt_seconds": (st.get("attempt_seconds") or []) + [seconds]}
    if again:
        out.update(repeats=(st.get("repeats") or 0) + 1,
                   seconds_repeated=round((st.get("seconds_repeated") or 0) + seconds, 1))
    return out, again


def failing_step(run, target, name):
    """The failure a probe of `name` goes after: the target's own, then another lane's, then, for a failure
    from before the records, the fault in the target's proof.json. None when no failure has that name."""
    for s in [target] + [x for x in run.steps if x.id != target.id]:
        for f in reversed(run.status(s.id).get("failures") or []):
            if f["step"] == name and named(f):
                return f
    proof = read_json(os.path.join(run.step_dir(target.id), "out", "proof.json"))
    fault = (proof.get("fault") or {}) if isinstance(proof, dict) else {}
    if fault.get("step") == name:
        return {"step": name, "phase": (proof.get("phases") or {}).get("failed")}
    return None


def failing_names(run, target):
    names = [f["step"] for f in run.status(target.id).get("failures") or [] if named(f)]
    return sorted(set(names))


def probe_env(run, target, fail, stage):
    """The target's lane, told to stop at fail's step, writing into the probe's own folder."""
    return {"REL_TRUST_PROBE": fail["step"], "REL_PROBE_PHASE": fail.get("phase") or "", "REL_OUT": stage,
            "REL_STAGE": stage, "REL_PROBE_FROM": os.path.join(run.step_dir(target.id), "out")}


def probe_record(eng, step, fail, n, rc, seconds, driver, proof, log):
    said = (proof.get("probe") or {})
    fault = proof.get("fault") or {}
    return {"n": n, "step": fail["step"], "phase": fail.get("phase"), "platform": platform_of(step),
            "target": step.id, "passed": rc == 0 and bool(said.get("passed")), "reached": said.get("reached"),
            "driver": driver, "at": now_iso(), "seconds": seconds, "rc": rc, "log": log,
            "fault": fault.get("line")}


def counts(rec):
    """The probe's verdict for the person who ran it: what to do next."""
    if rec["passed"]:
        return f"tools/rel retry {rec['target']}"
    return f"not a pass: {rec.get('fault') or 'rc %s' % rec['rc']}; log: {rec['log']}"
