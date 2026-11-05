# SPDX-License-Identifier: Apache-2.0
"""Runs a run's steps: picks the ready ones, runs each through its executor (local command,
the signer over ssh, a hand-off to the Apple builder, a builtin check or gate), keeps logs,
status and metrics, and says how it ended with a stable exit code."""
import hashlib
import json
import os
import shlex
import shutil
import signal
import subprocess
import threading
import time
import queue

from . import evidence
from . import failures as known
from . import guards
from . import serverlogs
from . import window as win
from .load import LoadSampler
from .run import SETTLED, now_iso, read_json, write_json

# Exit codes (stable; agents read them).
EXIT_OK, EXIT_WAITING, EXIT_FAILED, EXIT_PREFLIGHT, EXIT_DENIED, EXIT_USAGE, EXIT_BUSY = 0, 10, 20, 30, 40, 64, 75

def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def place(src, dst):
    """Copies src to dst (a hard link when possible): run folders hold real files, never links
    (a size read through a link once made a manifest wrong)."""
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    if os.path.exists(dst):
        os.remove(dst)
    try:
        os.link(os.path.realpath(src), dst)
    except OSError:
        shutil.copy2(os.path.realpath(src), dst)


# The checkout tools/rel runs from: its step scripts and G4 drivers ({rel} in pipeline.toml).
RUNNER = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def relmsg_state(st):
    """A step's state as relmsg shows it: a warn_only step that failed shows as failed (with its
    WARNING note and no alert) although the run carries on."""
    if st.get("warned"):
        return "failed"
    return {"held": "waiting", "closed": "waiting"}.get(st["status"], st["status"])



def recovered_note(proof):
    """`; RECOVERED by AI: <steps>` when the driver needed the model to find a control or get past a
    screen (the owner 2026-11-03: such a lane may pass, marked, with a selector fix drafted next to its proof)."""
    rec = proof.get("recovered") or []
    if not rec:
        return ""
    steps = sorted({str(r.get("step")) for r in rec})
    return f"; RECOVERED by AI ({len(rec)}): {', '.join(steps)[:120]} (selector-fixes.md)"

class Engine:
    def __init__(self, run, pipeline, hosts, repo, *, relmsg=None, dry=False, echo=None, failures=None, runner=None):
        self.run = run
        self.runner = runner or RUNNER
        self.pipeline = pipeline
        self.hosts = hosts
        self.repo = repo
        self.relmsg = relmsg
        self.dry = dry or bool(run.info.get("dry"))
        self.echo = echo or (lambda *a: None)
        self.failures = failures or []
        self._q = queue.Queue()
        self.load = LoadSampler()
        # Machine sharing: the heavy cap, steps kept apart, infra retries (tools/rellib/window.py).
        # run.json "concurrency" holds a run's own overrides (tools/rel --max-heavy, --exclusive-machine).
        self.policy = win.Policy(getattr(pipeline, "concurrency", {}), run.info.get("concurrency"))
        self.heavy_status = win.heavy_status
        self._deferred = {}
        self._running = {}
        self._window = None
        self._status_cache = (0.0, "")

    # ---- context ----

    @property
    def info(self):
        return self.run.info

    def base_env(self, step):
        i = self.info
        prev = i.get("previous", {})
        if step.platforms and (step.proof or step.env.get("REL_TRUST_MODE")):
            # A platform's G4 steps (trust-*, create-*) update from that platform's own previous release.
            prev = (i.get("previous_by_platform") or {}).get(step.platforms[0]) or prev
        net = i.get("net", {})
        env = {
            "REL_RUN": self.run.path, "REL_RUN_ID": i["run_id"], "REL_VERSION": i["version"],
            "REL_COMMIT": i["commit"], "REL_FILES": self.run.files, "REL_EXTRA": self.run.extra,
            "REL_MANIFESTS": os.path.join(self.run.path, "manifests"),
            "REL_STAGE": os.path.join(self.run.step_dir(step.id), "out"), "REL_SRC": i.get("src", ""),
            "REL_TEST": "1" if i.get("test") else "0",
            "REL_TEST_KEY": "1" if guards.test_key(i) else "0", "REL_RUN_KIND": guards.run_kind(i), "REL_TARGET": i.get("target", "live"),
            "REL_VARIANT": step.variant or "", "REL_NOTES_FILE": os.path.join(self.run.path, "notes.txt"),
            "REL_PREVIOUS_DIR": prev.get("dir", ""), "REL_PREVIOUS_VERSION": prev.get("version", ""),
            "REL_PREVIOUS_REF": prev.get("ref", ""), "REL_PREVIOUS_EXTRA": prev.get("extra", ""),
            "REL_NODE": net.get("node", ""), "REL_EPICBOX": net.get("epicbox", ""),
            "REL_DRY_RUN": "1" if self.dry else "0",
            "REL_MANIFEST_DAYS": str(self.pipeline.manifest_days()),
        }
        signer = self.hosts["host"].get("signer", {})
        for k in ("signing_key", "btlabs_public", "android_key_properties"):
            if signer.get(k):
                env[f"REL_SIGNER_{k.upper()}"] = signer[k]
        if step.proof:
            proof = self.pipeline.proof
            checks = list(proof.get("checks", []))
            funds = step.variant == proof.get("funds_variant", "tor")
            if funds:
                checks += proof.get("funds_checks", [])
            env.update({"REL_OUT": env["REL_STAGE"], "REL_CHECKS": ",".join(checks), "REL_FUNDS": "1" if funds else "0",
                        "REL_CANDIDATE_DIR": self.run.files, "REL_CANDIDATE_EXTRA": self.run.extra,
                        "REL_CANDIDATE_SRC": i.get("src", ""), "REL_CANDIDATE_VERSION": i["version"]})
        return env

    def input_hash(self, step):
        h = hashlib.sha256()
        h.update(json.dumps({"run": step.run, "env": step.env, "commit": self.info["commit"], "kind": step.kind,
                             "outputs": step.outputs, "scope": self.info.get("scope")}, sort_keys=True).encode())
        return h.hexdigest()[:16]

    # ---- evidence tied to the artefacts (docs/RELEASING.md, "Evidence and rc-manifest.json") ----

    @staticmethod
    def is_build(step):
        return bool(step.outputs or step.extras) and not step.publish and not step.proof

    def build_closure(self, step):
        """The build steps step (transitively) needs."""
        by_id = {s.id: s for s in self.run.steps}
        seen, frontier, out = set(), list(step.needs), []
        while frontier:
            sid = frontier.pop()
            if sid in seen or sid not in by_id:
                continue
            seen.add(sid)
            s = by_id[sid]
            if self.is_build(s):
                out.append(s)
            frontier.extend(s.needs)
        return sorted(out, key=lambda s: s.id)

    def inputs_digest(self, step):
        """A digest of the bytes every build step needs recorded (name and SHA-256 of each output),
        or None for a step that needs no build. A build that ran again changes it, so evidence
        made against the old bytes (a proof, G3, the gate) stops applying."""
        if self.is_build(step) or step.publish:
            return None
        builds = self.build_closure(step)
        if not builds:
            return None
        parts = {}
        for b in builds:
            outs = self.run.status(b.id).get("outputs") or {}
            parts[b.id] = {n: o.get("sha256") for n, o in sorted(outs.items())}
        return hashlib.sha256(json.dumps(parts, sort_keys=True).encode()).hexdigest()[:24]

    def platform_files(self, step):
        """{name: path} of the release files a proof step tests: what its platform's builds made, of
        the builds it waits for (trust-windows-notor never waits for, nor tests, the tor Setup)."""
        out = {}
        for s in self.build_closure(step):
            if set(s.platforms) & set(step.platforms):
                for o in s.outputs:
                    out[os.path.basename(o)] = os.path.join(self.run.files, os.path.basename(o))
                for e in s.extras:
                    out[e] = os.path.join(self.run.extra, e)
        return out

    def snapshot(self, step):
        """{name: sha256} of the files a proof step is about to test (None for a missing file)."""
        return {n: (sha256_file(p) if os.path.isfile(p) else None) for n, p in sorted(self.platform_files(step).items())}

    # ---- one step ----

    def refusal(self, step):
        """Why this step must not start (guards.py), or None. Every start, resume, retry and run passes here."""
        why = guards.trust_break_refusal(self.info)
        if why:
            return why
        if step.base == "source" or step.kind in ("gate",) or step.publish or step.base.startswith("publish"):
            return guards.never_ship_refusal(self.info, self.repo)
        return None

    def pin_driver(self, step, st, attempt):
        """-> (status fields, the earlier driver record this attempt differs from or None) for a proof
        step: which driver code this attempt runs (evidence.driver_record of the checkout tools/rel
        runs from), kept per attempt in status `drivers`. Others -> (None, None)."""
        if not step.proof:
            return None, None
        rec = evidence.driver_record(self.runner)
        earlier = list(st.get("drivers") or [])
        differs = [e for e in earlier if (e.get("commit"), e.get("dirty")) != (rec["commit"], rec["dirty"])]
        return ({"driver": rec, "drivers": earlier + [dict(rec, attempt=attempt)]},
                {"commit": differs[-1]["commit"], "dirty": differs[-1]["dirty"]} if differs else None)

    def stamp_driver(self, step, stage):
        """Writes this attempt's driver record into proof.json, before the proof is read, hashed or kept."""
        rec = self.run.status(step.id).get("driver")
        path = os.path.join(stage, "proof.json")
        proof = read_json(path)
        if rec and isinstance(proof, dict):
            proof["driver"] = rec
            write_json(path, proof)

    def attempt_log(self, step, attempt):
        d = self.run.step_dir(step.id)
        os.makedirs(d, exist_ok=True)
        log = os.path.join(d, f"attempt-{attempt}.log")
        link = os.path.join(d, "log.txt")
        try:
            if os.path.lexists(link):
                os.remove(link)
            os.symlink(os.path.basename(log), link)
        except OSError:
            pass
        return log

    def tdb(self, event, **fields):
        """One event into the test DB queue (tools/rellib/testdb); never raises, never blocks the run.
        The DB sits in the state root unless REL_TESTDB says otherwise; a dry run writes nothing."""
        if self.dry:
            return
        try:
            from .testdb import client
            root = os.path.dirname(os.path.dirname(self.run.path))
            client.emit(event, source="engine", db=os.path.join(root, "tests.db"), run=self.info["run_id"], **fields)
        except Exception:  # noqa: BLE001 - the DB is never a reason for a step or a run to fail
            pass

    def execute(self, step, infra_try=0):
        """Runs one step to an end state; returns its status dict. A failure whose cause is the
        machine (window.cause_of: a signal, no proof.json, an ssh drop, no build slot) runs once
        more by itself ([concurrency] infra_retries); a product or harness failure never does."""
        from . import builtins
        st = self.run.status(step.id)
        attempt = st.get("attempts", 0) + 1
        why = self.refusal(step)
        if why:
            with open(self.attempt_log(step, attempt), "a", encoding="utf-8") as f:
                f.write(f"tools/rel: refused: {why}\n")
            self.echo(f"✗ {step.id}  refused: {why}")
            return self.run.set_status(step.id, status="failed", attempts=attempt, note=f"refused: {why}",
                                       cause="check: refused", ended=now_iso(),
                                       attempt_causes=(st.get("attempt_causes") or []) + ["check: refused"])
        started = time.time()
        log = self.attempt_log(step, attempt)
        driver, changed_from = self.pin_driver(step, st, attempt)
        self.run.set_status(step.id, status="running", attempts=attempt, started=now_iso(), ended=None,
                            note=None, hint=None, rc=None, cause=None, infra_try=infra_try or None, flaky=None, failed_before=None, recovered=None,
                            **(driver or {}), driver_changed=True if changed_from else None)
        self.run.event(step.id, "start", host=step.host, attempt=attempt, dry=self.dry or None,
                       infra_try=infra_try or None)
        self.load.step_started(step.id)
        lane = dict(lane=step.id, n=attempt, platform=step.platforms[0] if len(step.platforms) == 1 else None,
                    variant=getattr(step, "variant", None))
        self.tdb("attempt.start", **lane)
        if self.relmsg:
            self.relmsg.step(step.id, "running", label=step.title, platform=(step.platforms[0] if len(step.platforms) == 1 else None))
        self.echo(f"▶ {step.id}  [{step.host}]{'  (dry run)' if self.dry else ''}"
                  + (f"  (automatic retry {infra_try})" if infra_try else ""))
        tested = self.snapshot(step) if step.proof and not self.dry else None
        tries = 1 + (0 if self.dry else step.retries)
        result = None
        rkey, result = self.try_reuse(step, log)
        for t in range(0 if result else tries):
            try:
                if step.kind in ("builtin", "gate") or (step.kind == "publish" and self.info.get("target") == "scratch"):
                    result = builtins.run(self, step, log)
                elif step.kind == "handoff":
                    result = self.exec_handoff(step, log)
                else:
                    result = self.exec_command(step, log)
            except Exception as e:  # a bug or an environment problem: the step failed, the run is kept
                with open(log, "a", encoding="utf-8") as f:
                    f.write(f"\ntools/rel: {type(e).__name__}: {e}\n")
                result = {"status": "failed", "note": f"{type(e).__name__}: {e}", "exception": True}
            if result["status"] != "failed" or t == tries - 1:
                break
            self.run.event(step.id, "retry", attempt=attempt, try_=t + 1)
        dur = round(time.time() - started, 1)
        result.setdefault("note", None)
        exception = result.pop("exception", None)
        will_retry = False
        if result["status"] == "failed":
            result["cause"] = win.cause_of(step, dict(result, exception=exception), log)
            result["attempt_causes"] = (st.get("attempt_causes") or []) + [result["cause"]]
            # Never a publish step: what reaches the outside world retries only where pipeline.toml
            # says so (`retries`), after a person looked.
            will_retry = (result["cause"].startswith("infra:") and infra_try < self.policy.infra_retries
                          and not self.dry and not step.publish)
            hits = known.match(self.failures, step.base, log)
            if hits:
                result["hint"] = " | ".join(h for _, h in hits)
                result["known"] = [i for i, _ in hits]
            if step.warn_only and not will_retry:
                # After the release is live (pipeline.toml warn_only): a failure is a warning in the
                # live message and the report; nothing after it is held and the run still ends ok.
                result.update(status="done", warned=True,
                              note=f"WARNING, not blocking: {result.get('note') or 'failed'}")
        if result["status"] in ("done", "failed", "skipped"):
            result["ended"] = now_iso()
            result["duration_s"] = dur
        if changed_from:
            result["note"] = ((result.get("note") or "").rstrip() + "; drivers changed between attempts ("
                              f"{evidence.driver_label(changed_from)} → {evidence.driver_label(driver['driver'])})").lstrip("; ")
        if result["status"] == "done":
            earlier = st.get("attempt_causes") or []
            # Passed after a failed attempt in this run (a warn_only failure is not a pass).
            result["flaky"] = True if earlier and not result.get("warned") else None
            result["failed_before"] = list(earlier) if result["flaky"] else None
            result["input_hash"] = self.input_hash(step)
            result["inputs_digest"] = None if self.dry else self.inputs_digest(step)
            if tested is not None:
                result["tested"] = tested  # the bytes the proof is about (update-trust checks them)
            if rkey:
                result["reuse_key"] = rkey
        st = self.run.set_status(step.id, **result)
        self.tdb_end(step, lane, st, log)
        self.run.event(step.id, "end", status=st["status"], duration_s=dur, rc=st.get("rc"), bytes=st.get("bytes"),
                       note=st.get("note"), hint=st.get("hint"), cause=st.get("cause"))
        self.metric(step, st, dur, self.load.step_ended(step.id), infra_try=infra_try)
        icon = {"done": "✓", "failed": "✗", "waiting": "⏸", "held": "✋", "closed": "✋", "skipped": "⏭"}.get(st["status"], "?")
        self.echo(f"{icon} {step.id}  {st['status']}  {dur:.0f}s" + (f"  {st['note']}" if st.get("note") else "")
                  + (f"  [{st['cause']}]" if st.get("cause") else ""))
        if st.get("hint"):
            self.echo(f"   hint: {st['hint']}")
        if will_retry:
            # The machine, not the product: once more, with a fresh attempt log; no alert yet.
            self.run.event(step.id, "retry", attempt=attempt, cause=st["cause"], automatic=True)
            self.echo(f"↻ {step.id}  {st['cause']}: one automatic retry")
            if self.relmsg:
                self.relmsg.step(step.id, "running", note=f"retrying after an infrastructure failure ({st['cause']})")
            return self.execute(step, infra_try=infra_try + 1)
        if self.relmsg:
            rs = relmsg_state(st)
            self.relmsg.step(step.id, rs, note=st.get("note"))
            if st["status"] == "done" and not st.get("warned") and not self.dry:
                self.forward_messages(step)
            if st["status"] == "failed":
                self.relmsg.alert(f"{step.id} failed", step=step.id, log=log, detail=self.server_logs(step, st, log),
                                  expects=st.get("hint") or "retry, skip or abort? (tools/rel retry|skip|debug)",
                                  key=f"{self.info['run_id']}/{step.id}/{attempt}")
        return st

    def tdb_end(self, step, lane, st, log):
        try:
            from .testdb import client
            cause = st.get("cause")
            cls = client.cause_class(cause)
            self.tdb("attempt.end", state={"done": "ok"}.get(st["status"], st["status"]), rc=st.get("rc"), cause=cause,
                     cause_class=cls, note=st.get("note"), log_path=log, out_dir=os.path.join(self.run.step_dir(step.id), "out"),
                     **lane)
            if st["status"] == "failed":
                self.tdb("failure", step=step.id, cause=cause, cause_class=cls, what=st.get("note") or cause, **lane)
        except Exception:  # noqa: BLE001
            pass

    def server_logs(self, step, st, log):
        """A failed G4 lane: the server-side log lines for its window (tools/rellib/serverlogs.py) go
        to the step's out folder, and quoted above the log's tail into the alert, so a harness fault
        reads apart from a server or product fault. Best effort: None leaves the alert as it was."""
        conf, local = self.pipeline.serverlogs, self.hosts.get("serverlogs")
        if self.dry or not serverlogs.is_lane_step(step) or not serverlogs.settings(conf, local)["enabled"]:
            return None
        try:
            summary = serverlogs.collect(step, st, os.path.join(self.run.step_dir(step.id), "out"), conf,
                                         local=local)
        except Exception as e:  # never in the way of the alert
            self.echo(f"   server logs: {type(e).__name__}: {e}")
            return None
        quoted = "\n".join(serverlogs.quote_lines(summary))[:1400]
        self.echo("   server logs:\n   " + quoted.replace("\n", "\n   "))
        tail = ""
        if os.path.exists(log):
            with open(log, encoding="utf-8", errors="replace") as f:
                tail = "\n".join(f.read().splitlines()[-40:])
        head = f"Server logs {'–'.join(summary['window'])} UTC (out/server-logs.txt):\n{quoted}\n--- step log ---\n"
        return head + tail[-max(0, 2990 - len(head)):]

    def forward_messages(self, step):
        """A step may leave, in its stage folder, links.json ([{label, url}]: links on the live
        message, e.g. the screen catalogue) and notice.json ({title, detail, expects}: one message
        to the owner, e.g. the announcement text). Best effort, like every status call."""
        out = os.path.join(self.run.step_dir(step.id), "out")
        links = read_json(os.path.join(out, "links.json"))
        for ln in links if isinstance(links, list) else []:
            if isinstance(ln, dict) and str(ln.get("url", "")).startswith("https://"):
                self.relmsg.link(str(ln.get("label") or step.id)[:40], ln["url"])
        notice = read_json(os.path.join(out, "notice.json"))
        if isinstance(notice, dict) and notice.get("title"):
            self.relmsg.alert(str(notice["title"]), step=step.id, detail=notice.get("detail"),
                              expects=notice.get("expects"), key=f"{self.info['run_id']}/{step.id}/notice")

    def try_reuse(self, step, log):
        """-> (key or None, a done result when an earlier passing result has the same key).
        Steps with `reuse` in pipeline.toml only (tools/rellib/reuse.py)."""
        spec = self.pipeline.steps.get(step.base) or {}
        if not spec.get("reuse") or self.dry:
            return None, None
        from . import reuse
        try:
            k, parts, src = reuse.find(self, step, spec["reuse"], reuse.nightly_dir(spec), reuse.green_dir(spec))
        except Exception as e:  # the check never fails a step: it runs instead
            with open(log, "a", encoding="utf-8") as f:
                f.write(f"tools/rel: reuse check failed ({type(e).__name__}: {e}); the step runs\n")
            return None, None
        with open(log, "a", encoding="utf-8") as f:
            f.write(f"reuse key {k}\n{json.dumps(parts, indent=1, sort_keys=True)}\n")
            f.write((f"same key as {src['label']} ({src['commit'][:12]}): not run, its result is reused\n" if src
                     else "no earlier passing result with this key: the step runs\n"))
        if not src:
            return k, None
        result = {"status": "done", "rc": 0, "reused_from": {k2: src[k2] for k2 in ("kind", "label", "commit")},
                  "note": f"reused from {src['label']} ({src['commit'][:12]}): nothing it depends on changed"}
        if src["kind"] == "run":
            result.update(reuse.reuse_into(self, step, src))
        return k, result

    def metric(self, step, st, dur, load=None, infra_try=0):
        """One line per step end in <state_root>/metrics.jsonl: time, when it started and ended, the
        machine's load meanwhile and the steps beside it (load.py), and the emulator's health when a
        driver wrote {stage}/emulator.json. These are the data for when trust may start (RELEASING.md).
        A failure carries its cause (window.cause_of: infra:<what>, timeout, product, harness,
        harness:crash, step, check, error); flaky marks a pass after a failed attempt in the run,
        driver_changed a proof step whose driver code differed from an earlier attempt's, recovered the
        number of AI recoveries in the proof (tools/rellib/health.py reads these);
        infra_try counts the automatic retries before this attempt; waited_s is the time the step
        waited for the heavy cap or a step kept apart."""
        line = {"ts": now_iso(), "run": self.info["run_id"], "version": self.info["version"], "step": step.id,
                "base": step.base, "host": step.host, "lane": step.lane, "status": st["status"], "duration_s": dur,
                "started": st.get("started"), "ended": st.get("ended"), "reused": bool(st.get("reused_from")) or None,
                "attempt": st.get("attempts"), "bytes": st.get("bytes"), "dry": self.dry or None,
                "test": self.info.get("test") or None, "cause": st.get("cause"), "infra_try": infra_try or None,
                "waited_s": st.get("waited_s"), "max_heavy": self.policy.max_heavy,
                "flaky": st.get("flaky") or None, "driver_changed": st.get("driver_changed") or None,
                "recovered": len(st["recovered"]) if st.get("recovered") else None}
        line.update(load or {})
        emu = read_json(os.path.join(self.run.step_dir(step.id), "out", "emulator.json"))
        if isinstance(emu, dict):
            line["emulator"] = emu
        self._metrics_line(line)

    def _metrics_line(self, line):
        root = os.path.dirname(os.path.dirname(self.run.path))
        with open(os.path.join(root, "metrics.jsonl"), "a", encoding="utf-8") as f:
            f.write(json.dumps({k: v for k, v in line.items() if v is not None}) + "\n")

    def overlap_metrics(self):
        """Steps that ran at the same time (e.g. the Android and Linux builds): one metrics line per
        set with its peak memory and CPU, kind "overlap" (tools/rel stats skips these)."""
        for o in self.load.take_overlaps():
            self._metrics_line({"ts": now_iso(), "kind": "overlap", "run": self.info["run_id"],
                                "version": self.info["version"], "dry": self.dry or None, **o})

    # ---- executors ----

    def command_line(self, step):
        """-> (argv, cwd, env) exactly as the step runs (also what `rel debug` prints)."""
        env = dict(self.base_env(step))
        env.update(step.env)
        script = "set -euo pipefail\n" + step.run
        argv = ["bash", "-c", script]
        if step.heavy:
            wrap = self.pipeline.defaults.get("heavy_wrap") or []
            if wrap and shutil.which(wrap[0]) and not os.environ.get("REL_NO_HEAVY"):
                argv = list(wrap) + argv
        # The release window's contract (docs/RELEASING.md): build-slot gives these callers priority.
        env["BUILD_SLOT_PRIORITY"] = "release"
        env["WFE_RELEASE_RUN"] = self.info["run_id"]
        cwd = step.cwd or self.info.get("src") or self.repo
        signer = self.hosts["host"].get("signer", {})
        if step.host == "signer" and signer and not signer.get("this_machine", True):
            argv = self.remote_argv(signer, script, env, cwd)
            cwd = self.repo
        return argv, cwd, env

    def remote_argv(self, host, script, env, cwd):
        """The signer on another machine: the run folder is synced to the same path there, the
        step runs in host.repo (which must be at the run's commit), and the folder comes back."""
        exports = " ".join(f"{k}={shlex.quote(v)}" for k, v in env.items() if k.startswith("REL_") or k.startswith("WFE_"))
        remote = (f"cd {shlex.quote(host['repo'])} && test \"$(git rev-parse HEAD)\" = {shlex.quote(self.info['commit'])} "
                  f"|| {{ echo 'the signer checkout is not at {self.info['commit']}' >&2; exit 1; }}; "
                  f"export {exports}; bash -c {shlex.quote(script)}")
        run = self.run.path
        alias = host["ssh"]
        sync_up = f"rsync -a --mkpath {shlex.quote(run + '/')} {shlex.quote(alias + ':' + run + '/')}"
        sync_down = f"rsync -a {shlex.quote(alias + ':' + run + '/')} {shlex.quote(run + '/')}"
        return ["bash", "-c", f"set -euo pipefail; {sync_up}; ssh {shlex.quote(alias)} {shlex.quote(remote)}; {sync_down}"]

    def exec_command(self, step, log):
        argv, cwd, env = self.command_line(step)
        stage = os.path.join(self.run.step_dir(step.id), "out")
        os.makedirs(stage, exist_ok=True)
        with open(log, "a", encoding="utf-8") as f:
            f.write(f"# {now_iso()} {step.id} on {step.host}\n# cwd: {cwd}\n")
            for k in sorted(step.env):
                f.write(f"# env {k}={step.env[k]}\n")
            f.write(f"# run: {step.run}\n\n")
        if self.dry:
            with open(log, "a", encoding="utf-8") as f:
                f.write("# dry run: not run\n")
            if step.proof:
                return self._dry_proof(step, cwd, env, log)
            return {"status": "done", "note": "dry run", "dry": True}
        if not os.path.isdir(cwd):
            return {"status": "failed", "note": f"working dir {cwd} does not exist"}
        if step.proof:
            # A proof from an earlier attempt never counts for this one.
            old = os.path.join(stage, "proof.json")
            if os.path.exists(old):
                os.replace(old, os.path.join(stage, f"proof.before-{os.path.basename(log)[:-4]}.json"))
        full_env = {k: v for k, v in os.environ.items()}
        full_env.update(env)
        full_env["LEPIC_NO_CACHE"] = "1"  # release builds come from source, never the prebuilt cache
        with open(log, "ab") as f:
            p = subprocess.Popen(argv, cwd=cwd, env=full_env, stdout=f, stderr=subprocess.STDOUT,
                                 stdin=subprocess.DEVNULL, start_new_session=True)
            try:
                rc = p.wait(timeout=step.timeout)
            except subprocess.TimeoutExpired:
                os.killpg(p.pid, signal.SIGTERM)
                try:
                    p.wait(timeout=30)
                except subprocess.TimeoutExpired:
                    os.killpg(p.pid, signal.SIGKILL)
                    p.wait()
                return {"status": "failed", "rc": None, "timed_out": True,
                        "note": f"timed out after {step.timeout:.0f}s (its hard limit)"}
        if step.proof:
            self.stamp_driver(step, stage)
            return self._check_proof(step, rc)
        if rc != 0:
            return {"status": "failed", "rc": rc, "note": f"exit {rc}"}
        return self.collect(step, stage)

    def _dry_proof(self, step, cwd, env, log):
        full_env = dict(os.environ)
        full_env.update(env)
        full_env["LEPIC_NO_CACHE"] = "1"
        argv = ["bash", "-c", "set -euo pipefail\n" + step.run]
        if not os.path.isdir(cwd):
            cwd = self.repo  # no release worktree in a dry run: the driver from this checkout
        with open(log, "ab") as f:
            rc = subprocess.call(argv, cwd=cwd, env=full_env, stdout=f, stderr=subprocess.STDOUT, timeout=120)
        return {"status": "done" if rc == 0 else "failed", "rc": rc,
                "note": "dry run of the driver" if rc == 0 else f"driver dry run exit {rc}", "dry": True}

    def _check_proof(self, step, rc):
        """Fail closed: the step passes only when proof.json has every required check true."""
        env = self.base_env(step)
        required = [c for c in env["REL_CHECKS"].split(",") if c]
        proof = read_json(os.path.join(env["REL_STAGE"], "proof.json"))
        if proof is None:
            reason = self.info["scope"]["proof"]["waive"].get(step.platforms[0]) if step.platforms else None
            if reason is not None:
                return {"status": "done", "waived": True, "rc": rc, "proven": False,
                        "note": f"NOT PROVEN (waived: {reason}): no proof.json (driver exit {rc})"}
            return {"status": "failed", "rc": rc, "note": f"no proof.json (driver exit {rc})", "proven": False,
                    "proof_missing": True}
        checks = proof.get("checks", {})
        # A new app installed beside the previous one (another package, authorised in pipeline.toml
        # [proof] beside_pairs) carries no data over: the checks on carried data do not apply.
        pkgs = proof.get("packages") or {}
        pairs = [list(p) for p in self.pipeline.proof.get("beside_pairs", [])]
        if pkgs.get("beside") is True and [pkgs.get("previous"), pkgs.get("candidate")] in pairs:
            skip = set(self.pipeline.proof.get("beside_not_applicable", []))
            required = [c for c in required if c not in skip]
        bad = [c for c in required if checks.get(c) is not True]
        res = {"rc": rc, "proof": proof, "proven": not bad and rc == 0, "failed_checks": bad or None}
        if bad or rc != 0:
            det = proof.get("details", {})
            note = "not proven: " + ", ".join(
                f"{c} ({det.get(c, 'false')})"[:80] for c in bad) if bad else f"driver exit {rc}"
            # the driver's one line (core/faults.py): PRODUCT or HARNESS, the step, what broke, the screenshot
            if (proof.get("fault") or {}).get("line"):
                note = proof["fault"]["line"][:200] + "; " + note
            # A waived platform (release.toml [proof.waive]) still runs its driver so the gate shows
            # what it found; its result is reported, never counted as proven, and blocks nothing.
            reason = self.info["scope"]["proof"]["waive"].get(step.platforms[0]) if step.platforms else None
            if reason is not None:
                res.update(status="done", waived=True, note=f"NOT PROVEN (waived: {reason}): {note}")
            else:
                res.update(status="failed", note=note)
        else:
            res.update(status="done", note=f"proven {proof.get('previous')} → {proof.get('candidate')} "
                                           f"({proof.get('update_method', '?')}; node {proof.get('node')}, epicbox {proof.get('epicbox')}"
                                           + (f"; from saved state" if proof.get("start") == "state" else "") + ")"
                                           + recovered_note(proof))
            res["recovered"] = [r.get("step") for r in proof["recovered"]] if proof.get("recovered") else None
        return res

    def collect(self, step, stage):
        outs, total, missing = {}, 0, []
        for rel in step.outputs:
            src = os.path.join(stage, rel)
            if not os.path.isfile(src):
                missing.append(rel)
                continue
            dst = os.path.join(self.run.files, os.path.basename(rel))
            place(src, dst)
            outs[os.path.basename(rel)] = {"sha256": sha256_file(dst), "bytes": os.path.getsize(dst)}
            total += os.path.getsize(dst)
        for rel in step.extras:
            src = os.path.join(stage, rel)
            if not os.path.isfile(src):
                missing.append(rel)
                continue
            dst = os.path.join(self.run.extra, rel)
            place(src, dst)
            outs[rel] = {"sha256": sha256_file(dst), "bytes": os.path.getsize(dst), "extra": True}
        if missing:
            return {"status": "failed", "rc": 0, "note": "outputs missing: " + ", ".join(missing), "outputs": outs}
        return {"status": "done", "rc": 0, "outputs": outs, "bytes": total or None}

    def exec_handoff(self, step, log):
        """Writes a job for the Apple builder (job.toml, a git bundle of the commit, the files it
        needs) and waits for its results; done when every expected result is there and its
        SHA256SUMS (when sent) agrees. Never blocks: a missing result = waiting."""
        hdir = os.path.join(self.run.path, "handoff", step.id)
        job, results = os.path.join(hdir, "job"), os.path.join(hdir, "results")
        os.makedirs(results, exist_ok=True)
        staging = self.hosts["host"].get("apple", {}).get("staging", "")
        with open(log, "a", encoding="utf-8") as f:
            if not os.path.exists(os.path.join(job, "job.toml")):
                os.makedirs(job, exist_ok=True)
                with open(os.path.join(job, "job.toml"), "w", encoding="utf-8") as j:
                    j.write(f'# Hand-off job for the Apple builder ({step.title}).\n'
                            f'run_id = "{self.info["run_id"]}"\nstep = "{step.id}"\nversion = "{self.info["version"]}"\n'
                            f'commit = "{self.info["commit"]}"\n'
                            f'# In a clean clone of wallet-for-epic (tools/apple-release.md), run:\ncommand = {json.dumps(step.run)}\n'
                            f'# Put these in results/ (beside job/), with a SHA256SUMS of them:\n'
                            f'results = {json.dumps(step.results)}\n')
                if not self.dry and self.info.get("src"):
                    subprocess.run(["git", "-C", self.info["src"], "bundle", "create", os.path.join(job, "wfe.bundle"),
                                    "HEAD"], stdout=f, stderr=subprocess.STDOUT)
                for d in step.send:
                    if os.path.isdir(d) and not self.dry:
                        for name in os.listdir(d):
                            place(os.path.join(d, name), os.path.join(job, name))
                f.write(f"job written: {job}\n")
            if staging and not self.dry:
                dest = f"{staging.rstrip('/')}/{self.info['run_id']}/{step.id}"
                subprocess.run(["rsync", "-a", "--mkpath", job + "/", dest + "/job/"], stdout=f, stderr=subprocess.STDOUT)
                subprocess.run(["rsync", "-a", dest + "/results/", results + "/"], stdout=f, stderr=subprocess.STDOUT)
        if self.dry:
            return {"status": "done", "note": f"dry run: job at {job}", "dry": True}
        missing = [r for r in step.results if not os.path.isfile(os.path.join(results, r))]
        if missing:
            where = f"{staging}/{self.info['run_id']}/{step.id}" if staging else hdir
            return {"status": "waiting", "note": f"waiting for the Mac: job at {where}/job, results to …/results "
                                                 f"(missing {', '.join(missing)})"}
        sums = os.path.join(results, "SHA256SUMS")
        if os.path.isfile(sums):
            p = subprocess.run(["sha256sum", "-c", "--quiet", "SHA256SUMS"], cwd=results, capture_output=True, text=True)
            if p.returncode != 0:
                return {"status": "failed", "note": "hand-off SHA256SUMS does not match: " + p.stdout.strip()[-200:]}
        return {"status": "done", "note": f"results in {results}"}

    # ---- the loop ----

    def ready(self, step, statuses):
        return all(statuses.get(n) in SETTLED for n in step.needs)

    def blocked(self, step, statuses):
        return any(statuses.get(n) in ("failed", "held", "closed") for n in step.needs)

    def drive(self, selected, stop_on_fail=True):
        """Runs the selected steps (ids) whose needs are met, in parallel across lanes, until
        nothing more can start. Returns the exit code."""
        steps = [s for s in self.run.steps if s.id in selected]
        lanes_busy, running = set(), {}
        self._running = running
        stop = False
        window = None
        if not self.dry:
            self.load.start()
            window = win.Window(win.marker_path(self.policy.marker), self.info, self.policy,
                                lambda: [r[2] for r in list(running.values())]).open()
        self._window = window
        self.tdb("run.start", run_kind=self.info.get("kind"), version=self.info.get("version"))
        code = None
        try:
            code = self._drive(steps, lanes_busy, running, stop, stop_on_fail, selected)
            return code
        finally:
            self.tdb("run.end", state={EXIT_OK: "ok", EXIT_WAITING: "waiting"}.get(code, "failed"),
                     note="exit %s" % code)
            if window:
                window.close()
            self._window = None
            self.load.stop()
            self.overlap_metrics()

    def external_suite(self):
        """A full suite running in a build-slot slot outside this run, or None (asked at most once
        per [concurrency] poll)."""
        t, text = self._status_cache
        if time.time() - t >= self.policy.poll:
            text = self.heavy_status()
            self._status_cache = (time.time(), text)
        return self.policy.external_suite(text)

    def may_start(self, s, running, now):
        """None when s may start now, else why it waits ([concurrency], tools/rellib/window.py)."""
        why = self.policy.why_not(s, [r[2] for r in running.values()])
        if why is None and self.policy.guards_external(s) and not self.dry:
            ext = self.external_suite()
            if ext:
                first = self._deferred.get(s.id, (None, now))[1]
                if now - first < self.policy.external_wait:
                    return f"a full test suite runs outside this run: {ext}"
                self.run.event(s.id, "external-suite", note=f"started anyway after {now - first:.0f}s: {ext}")
        return why

    def _drive(self, steps, lanes_busy, running, stop, stop_on_fail, selected):
        while True:
            statuses = {s.id: self.run.status(s.id)["status"] for s in self.run.steps}
            deferred_external = False
            if not stop:
                for s in steps:
                    if s.id in running or statuses[s.id] not in ("pending", "failed", "waiting", "held", "closed"):
                        continue
                    if statuses[s.id] == "failed" and not self.run.status(s.id).get("retry"):
                        continue
                    if not self.ready(s, statuses) or s.lane in lanes_busy:
                        continue
                    if self.run.status(s.id).get("polled") == id(self):
                        continue  # a waiting step is asked once per drive
                    now = time.time()
                    why = self.may_start(s, running, now)
                    if why:
                        prev = self._deferred.get(s.id)
                        if not prev or prev[0] != why:
                            self._deferred[s.id] = (why, prev[1] if prev else now)
                            self.run.event(s.id, "deferred", reason=why)
                            self.echo(f"… {s.id}  waits: {why}")
                        deferred_external = deferred_external or why.startswith("a full test suite")
                        continue
                    waited = self._deferred.pop(s.id, (None, now))[1]
                    self.run.set_status(s.id, retry=False, waited_s=round(now - waited, 1) or None)
                    lanes_busy.add(s.lane)
                    th = threading.Thread(target=self._worker, args=(s,), daemon=True)
                    running[s.id] = (th, s.lane, s)
                    if self._window:
                        self._window.beat()
                    th.start()
            if not running:
                if deferred_external:
                    time.sleep(self.policy.poll)  # only a suite outside the run holds it: look again
                    continue
                break
            try:
                sid, st = self._q.get(timeout=self.policy.poll if deferred_external else None)
            except queue.Empty:
                continue
            th, lane, _ = running.pop(sid)
            if self._window:
                self._window.beat()
            th.join()
            lanes_busy.discard(lane)
            if st["status"] == "waiting" or st["status"] in ("held", "closed"):
                self.run.set_status(sid, polled=id(self))
            if st["status"] == "failed" and stop_on_fail:
                stop = True
        for s in steps:
            if self.run.status(s.id).get("polled"):
                self.run.set_status(s.id, polled=None)
        return self.exit_code(selected)

    def _worker(self, step):
        try:
            st = self.execute(step)
        except Exception as e:  # never lose the queue entry
            st = self.run.set_status(step.id, status="failed", note=f"tools/rel: {e}")
        self._q.put((step.id, st))

    def exit_code(self, selected):
        sts = {sid: self.run.status(sid) for sid in selected}
        failed = [sid for sid, st in sts.items() if st["status"] == "failed"]
        if failed:
            if any(self.run.step(sid).base == "preflight" for sid in failed):
                return EXIT_PREFLIGHT
            return EXIT_FAILED
        if any(st["status"] in ("held", "closed") for st in sts.values()):
            return EXIT_DENIED
        if all(st["status"] in SETTLED for st in sts.values()):
            return EXIT_OK
        return EXIT_WAITING
