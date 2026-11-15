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

from . import failures as known
from . import guards
from . import window as win
from .load import LoadSampler
from .run import SETTLED, Busy, now_iso, read_json

# Exit codes (stable; agents read them).
EXIT_OK, EXIT_WAITING, EXIT_FAILED, EXIT_PREFLIGHT, EXIT_DENIED, EXIT_USAGE, EXIT_BUSY = 0, 10, 20, 30, 40, 64, 75

STALE_INPUTS = "inputs changed since it ran"
STALE_BYTES = "not applicable any more: a build it depends on ran again since (new bytes)"


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


# The checkout tools/rel runs from: its step scripts ({rel} in pipeline.toml).
RUNNER = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
# Runs a hand-off step on the Apple builder over ssh ([host.apple] ssh + auto); its time limit.
APPLE_REMOTE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "steps", "apple-remote.sh")
APPLE_REMOTE_MINUTES = 150


def relmsg_state(st):
    """A step's state as relmsg shows it: a warn_only step that failed shows as failed (with its
    WARNING note and no alert) although the run carries on."""
    if st.get("warned"):
        return "failed"
    return {"held": "waiting", "closed": "waiting"}.get(st["status"], st["status"])



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
        # run.json "concurrency" holds a run's own overrides (tools/rel --max-heavy).
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
        env = {
            "REL_RUN": self.run.path, "REL_RUN_ID": i["run_id"], "REL_VERSION": i["version"],
            "REL_COMMIT": i["commit"], "REL_FILES": self.run.files, "REL_EXTRA": self.run.extra,
            "REL_MANIFESTS": os.path.join(self.run.path, "manifests"),
            "REL_STAGE": os.path.join(self.run.step_dir(step.id), "out"), "REL_SRC": i.get("src", ""),
            "REL_TEST": "1" if i.get("test") else "0",
            "REL_TEST_KEY": "1" if guards.test_key(i) else "0", "REL_RUN_KIND": guards.run_kind(i), "REL_TARGET": i.get("target", "live"),
            "REL_VARIANT": step.variant or "", "REL_NOTES_FILE": os.path.join(self.run.path, "notes.txt"),
            "REL_PREVIOUS_DIR": prev.get("dir", ""), "REL_PREVIOUS_VERSION": prev.get("version", ""),
            "REL_PREVIOUS_REF": prev.get("ref", ""),
            "REL_DRY_RUN": "1" if self.dry else "0",
            "REL_FOLLOW_UP": "1" if i.get("follow_up") else "0",
            "REL_MANIFEST_DAYS": str(self.pipeline.manifest_days()),
        }
        signer = self.hosts["host"].get("signer", {})
        for k in ("signing_key", "btlabs_public", "android_key_properties"):
            if signer.get(k):
                env[f"REL_SIGNER_{k.upper()}"] = signer[k]
        return env

    def stale_why(self, step, st):
        """Why a done result no longer holds: STALE_INPUTS, STALE_BYTES, or None. Every start, resume
        and run asks the same question."""
        if st["status"] != "done" or st.get("dry") or step.publish:
            return None
        if st.get("input_hash") and st["input_hash"] != self.input_hash(step):
            return STALE_INPUTS
        if st.get("inputs_digest") and st["inputs_digest"] != self.inputs_digest(step):
            # Evidence tied to the artefacts: a build it depends on ran again, so what this step
            # checked (G3, signing, the gate) is about other bytes.
            return STALE_BYTES
        return None

    def input_hash(self, step):
        h = hashlib.sha256()
        h.update(json.dumps({"run": step.run, "env": step.env, "commit": self.info["commit"], "kind": step.kind,
                             "outputs": step.outputs, "scope": self.info.get("scope")}, sort_keys=True).encode())
        return h.hexdigest()[:16]

    # ---- evidence tied to the artefacts (docs/RELEASING.md, "Evidence and rc-manifest.json") ----

    @staticmethod
    def is_build(step):
        return bool(step.outputs or step.extras) and not step.publish

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
        made against the old bytes (G3, the gate) stops applying."""
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

    # ---- one step ----

    def refusal(self, step):
        """Why this step must not start (guards.py), or None. Every start, resume, retry and run passes here."""
        if step.base == "source" or step.kind in ("gate",) or step.publish or step.base.startswith("publish"):
            return guards.never_ship_refusal(self.info, self.repo)
        return None

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
        machine (window.cause_of: a signal, an ssh drop, no build slot) runs once more by itself
        ([concurrency] infra_retries); any other failure never does."""
        from . import builtins
        st = self.run.status(step.id)
        attempt = st.get("attempts", 0) + 1
        lane = self.lane_fields(step, attempt)
        why = self.refusal(step)
        if why:
            log = self.attempt_log(step, attempt)
            with open(log, "a", encoding="utf-8") as f:
                f.write(f"tools/rel: refused: {why}\n")
            self.echo(f"✗ {step.id}  refused: {why}")
            self.run.event(step.id, "start", host=step.host, attempt=attempt, dry=self.dry or None)
            self.tdb("attempt.start", **lane)
            st = self.run.set_status(step.id, status="failed", attempts=attempt, note=f"refused: {why}",
                                     cause="check: refused", ended=now_iso(),
                                     attempt_causes=(st.get("attempt_causes") or []) + ["check: refused"])
            self.close_attempt(step, lane, st, log, 0)
            return st
        started = time.time()
        log = self.attempt_log(step, attempt)
        self.run.set_status(step.id, status="running", attempts=attempt, started=now_iso(), ended=None,
                            note=None, hint=None, rc=None, cause=None, infra_try=infra_try or None, flaky=None,
                            failed_before=None)
        self.run.event(step.id, "start", host=step.host, attempt=attempt, dry=self.dry or None,
                       infra_try=infra_try or None)
        self.load.step_started(step.id)
        self.tdb("attempt.start", **lane)
        if self.relmsg:
            self.relmsg.step(step.id, "running", label=step.title, platform=(step.platforms[0] if len(step.platforms) == 1 else None))
        self.echo(f"▶ {step.id}  [{step.host}]{'  (dry run)' if self.dry else ''}"
                  + (f"  (automatic retry {infra_try})" if infra_try else ""))
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
        if result["status"] == "done":
            earlier = st.get("attempt_causes") or []
            # Passed after a failed attempt in this run (a warn_only failure is not a pass).
            result["warned"] = result.get("warned") or None   # a pass clears an earlier attempt's warning
            result["flaky"] = True if earlier and not result.get("warned") else None
            result["failed_before"] = list(earlier) if result["flaky"] else None
            result["input_hash"] = self.input_hash(step)
            result["inputs_digest"] = None if self.dry else self.inputs_digest(step)
            if rkey:
                result["reuse_key"] = rkey
        st = self.run.set_status(step.id, **result)
        self.close_attempt(step, lane, st, log, dur, self.load.step_ended(step.id), infra_try)
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
                self.relmsg.alert(f"{step.id} failed", step=step.id, log=log,
                                  expects=st.get("hint") or "retry, skip or abort? (tools/rel retry|skip|debug)",
                                  key=f"{self.info['run_id']}/{step.id}/{attempt}")
        return st

    @staticmethod
    def lane_fields(step, attempt):
        return dict(lane=step.id, n=attempt, platform=step.platforms[0] if len(step.platforms) == 1 else None,
                    variant=getattr(step, "variant", None))

    def close_attempt(self, step, lane, st, log, dur, load=None, infra_try=0):
        """Every attempt of every run ends here: the journal, metrics.jsonl and tests.db get the same
        record."""
        self.tdb_end(step, lane, st, log)
        self.run.event(step.id, "end", status=st["status"], duration_s=dur, rc=st.get("rc"), bytes=st.get("bytes"),
                       note=st.get("note"), hint=st.get("hint"), cause=st.get("cause"), warned=st.get("warned") or None,
                       attempts=st.get("attempts"))
        self.metric(step, st, dur, load, infra_try=infra_try)

    def record_skip(self, step, reason):
        """A step skipped by hand (tools/rel skip): the same record as an attempt that ended, in
        metrics.jsonl and tests.db; the caller has written the journal."""
        st = self.run.status(step.id)
        lane = self.lane_fields(step, (st.get("attempts") or 0) + 1)
        self.tdb("attempt.start", **lane)
        self.tdb("attempt.end", state="skipped", note=reason, **lane)
        self.metric(step, st, 0)

    def tdb_end(self, step, lane, st, log):
        try:
            from .testdb import client
            cause = st.get("cause")
            cls = client.attempt_class(cause) if st["status"] == "failed" or st.get("warned") else None
            state = "warned" if st.get("warned") else {"done": "ok"}.get(st["status"], st["status"])
            self.tdb("attempt.end", state=state, rc=st.get("rc"), cause=cause,
                     cause_class=cls, note=st.get("note"), log_path=log, out_dir=os.path.join(self.run.step_dir(step.id), "out"),
                     **lane)
            if st["status"] == "failed":
                self.tdb("failure", step=step.id, cause=cause, cause_class=cls, what=st.get("note") or cause, **lane)
        except Exception:  # noqa: BLE001
            pass

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
            k, parts, src = reuse.find(self, step, spec["reuse"], reuse.green_dir(spec))
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
        """One line per step end in <state_root>/metrics.jsonl: time, when it started and ended, and
        the machine's load meanwhile and the steps beside it (load.py). A failure carries its cause
        (window.cause_of: infra:<what>, timeout, step, check, error); flaky marks a pass after a
        failed attempt in the run (tools/rel stats reads these); infra_try counts the automatic
        retries before this attempt; waited_s is the time the step waited for the heavy cap."""
        line = {"ts": now_iso(), "run": self.info["run_id"], "version": self.info["version"], "step": step.id,
                "base": step.base, "host": step.host, "lane": step.lane, "status": st["status"], "duration_s": dur,
                "started": st.get("started"), "ended": st.get("ended"), "reused": bool(st.get("reused_from")) or None,
                "attempt": st.get("attempts"), "bytes": st.get("bytes"), "dry": self.dry or None,
                "test": self.info.get("test") or None, "cause": st.get("cause"), "infra_try": infra_try or None,
                "commit": self.info.get("commit"), "warned": st.get("warned") or None,
                "waited_s": st.get("waited_s"), "max_heavy": self.policy.max_heavy,
                "flaky": st.get("flaky") or None}
        line.update(load or {})
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

    @staticmethod
    def spawn_env(env):
        """The process environment of a step: this one's, with the step's own on top."""
        full = dict(os.environ)
        full.update(env)
        full["LEPIC_NO_CACHE"] = "1"  # release builds come from source, never the prebuilt cache
        return full

    @staticmethod
    def spawn(argv, cwd, env, log, timeout):
        """Runs argv with its output in log. -> its exit code, None when it hit timeout."""
        with open(log, "ab") as f:
            p = subprocess.Popen(argv, cwd=cwd, env=env, stdout=f, stderr=subprocess.STDOUT,
                                 stdin=subprocess.DEVNULL, start_new_session=True)
            try:
                return p.wait(timeout=timeout)
            except subprocess.TimeoutExpired:
                os.killpg(p.pid, signal.SIGTERM)
                try:
                    p.wait(timeout=30)
                except subprocess.TimeoutExpired:
                    os.killpg(p.pid, signal.SIGKILL)
                    p.wait()
                return None

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
            return {"status": "done", "note": "dry run", "dry": True}
        if not os.path.isdir(cwd):
            return {"status": "failed", "note": f"working dir {cwd} does not exist"}
        rc = self.spawn(argv, cwd, self.spawn_env(env), log, step.timeout)
        if rc is None:
            return {"status": "failed", "rc": None, "timed_out": True,
                    "note": f"timed out after {step.timeout:.0f}s (its hard limit)"}
        if rc != 0:
            return {"status": "failed", "rc": rc, "note": f"exit {rc}"}
        return self.collect(step, stage)

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
        SHA256SUMS (when sent) agrees. Never blocks: a missing result = waiting.
        With run.json handoff_from (tools/rel start --apple-results DIR) the results are already in
        DIR: no job is written or sent, the expected results are copied from there."""
        hdir = os.path.join(self.run.path, "handoff", step.id)
        job, results = os.path.join(hdir, "job"), os.path.join(hdir, "results")
        os.makedirs(results, exist_ok=True)
        staging = self.hosts["host"].get("apple", {}).get("staging", "")
        given = self.info.get("handoff_from")
        if given:
            staging = ""
            with open(log, "a", encoding="utf-8") as f:
                for r in step.results:
                    src, dest = os.path.join(given, r), os.path.join(results, r)
                    if os.path.isfile(src) and not os.path.islink(src) and not os.path.exists(dest):
                        shutil.copy2(src, dest)
                        f.write(f"result from {src}\n")
            missing = [r for r in step.results if not os.path.isfile(os.path.join(results, r))]
            if missing:
                return {"status": "waiting", "note": f"results from {given}: missing {', '.join(missing)}"}
            return {"status": "done", "note": f"results from {given} (no job sent)"}
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
        remote = self.remote_handoff(step, log, job, results)
        if remote:
            return remote
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

    def remote_handoff(self, step, log, job, results):
        """[host.apple] ssh + auto = ["apple-mac"]: the Mac runs this step by itself over ssh
        (steps/apple-remote.sh: job copied, LEPIC pins pushed, the command run under the Mac's build
        lock, results copied back with their SHA256SUMS). Synchronous: the step's lane waits.
        -> None when the step is not one of them (the manual route goes on), else a failed result or
        None again once the results are in results/ (the checks after it are the same)."""
        apple = self.hosts["host"].get("apple", {})
        if not apple.get("ssh") or step.base not in (apple.get("auto") or []) or self.info.get("handoff_from"):
            return None
        if not self.info.get("src") or not os.path.isfile(os.path.join(job, "wfe.bundle")):
            return {"status": "failed", "note": "apple-remote: the job has no wfe.bundle (no source checkout in this run)"}
        minutes = int(apple.get("timeout_min") or APPLE_REMOTE_MINUTES)
        env = dict(os.environ, APPLE_REMOTE_CMD=step.run,
                   APPLE_REMOTE_ENV="\n".join(f"{k}={v}" for k, v in sorted((apple.get("env") or {}).items())))
        argv = ["bash", APPLE_REMOTE, apple["ssh"], apple.get("workdir") or "~/rel-jobs", self.info["run_id"],
                step.id, job, results, self.info["commit"], self.info["src"], str(minutes), *step.results]
        with open(log, "ab") as f:
            f.write(f"# {now_iso()} {os.path.basename(APPLE_REMOTE)} on {apple['ssh']} (limit {minutes} min)\n".encode())
            f.flush()
            try:
                p = subprocess.run(argv, env=self.spawn_env(env), stdout=f, stderr=subprocess.STDOUT,
                                   stdin=subprocess.DEVNULL, timeout=(minutes + 5) * 60)
                rc = p.returncode
            except subprocess.TimeoutExpired:
                rc = None
        if rc == 0:
            return None
        with open(log, "r", encoding="utf-8", errors="replace") as f:
            tail = [l.strip() for l in f.read().splitlines()[-12:] if l.strip()]
        why = next((l for l in reversed(tail) if l.startswith("apple-remote:")), tail[-1] if tail else "")
        return {"status": "failed", "rc": rc,
                "note": ("timed out" if rc is None else f"exit {rc}") + f": {why}"[:300]}

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
            for r in list(running.values()):
                self.run.release_lane(r[1])
            if window:
                window.close()
            self._window = None
            self.load.stop()
            self.overlap_metrics()

    def execute_alone(self, step):
        """One step outside drive (the gate), with the same run.start and run.end around it."""
        self.tdb("run.start", run_kind=self.info.get("kind"), version=self.info.get("version"))
        st = None
        try:
            st = self.execute(step)
            return st
        finally:
            self.tdb("run.end", state="waiting" if st and st["status"] == "waiting" else
                     "ok" if st and st["status"] == "done" else "failed", note=f"{step.id}: {st and st['status']}")

    def external_suite(self):
        """A full suite running in a build-slot slot outside this run, or None (asked at most once
        per [concurrency] poll)."""
        t, text = self._status_cache
        if time.time() - t >= self.policy.poll:
            text = self.heavy_status()
            self._status_cache = (time.time(), text)
        return self.policy.external_suite(text)

    def may_start(self, s, running, now, elsewhere=()):
        """None when s may start now, else why it waits ([concurrency], tools/rellib/window.py).
        elsewhere: what other tools/rel processes run, which the cap and `apart` count too."""
        others = [r[2] for r in running.values()] + list(elsewhere)
        why = self.policy.why_not(s, others)
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
            deferred_external = False  # something outside this drive holds a step: look again by the clock
            skipped = False  # a step skipped for its needs frees what comes after it: look again at once
            if not stop:
                for s in steps:
                    if s.id in running or statuses[s.id] not in ("pending", "failed", "waiting", "held", "closed"):
                        continue
                    if statuses[s.id] == "failed" and not self.run.status(s.id).get("retry"):
                        continue
                    if not self.ready(s, statuses) or s.lane in lanes_busy:
                        continue
                    if statuses[s.id] == "pending" and self.skip_for_need(s):
                        skipped = True
                        continue
                    if self.run.status(s.id).get("polled") == id(self):
                        continue  # a waiting step is asked once per drive
                    now = time.time()
                    with self.run.short("admit"):
                        elsewhere = self.run.elsewhere()
                        why = self.may_start(s, running, now, elsewhere)
                        if not why:
                            try:
                                self.run.claim_lane(s.lane, s.id)
                            except Busy as e:
                                why = str(e)
                    if why:
                        prev = self._deferred.get(s.id)
                        if not prev or prev[0] != why:
                            self._deferred[s.id] = (why, prev[1] if prev else now)
                            self.run.event(s.id, "deferred", reason=why)
                            self.echo(f"… {s.id}  waits: {why}")
                        deferred_external = (deferred_external or why.startswith("a full test suite")
                                             or bool(elsewhere) or why.startswith("another tools/rel"))
                        continue
                    waited = self._deferred.pop(s.id, (None, now))[1]
                    self.run.set_status(s.id, retry=False, waited_s=round(now - waited, 1) or None)
                    lanes_busy.add(s.lane)
                    th = threading.Thread(target=self._worker, args=(s,), daemon=True)
                    running[s.id] = (th, s.lane, s)
                    if self._window:
                        self._window.beat()
                    th.start()
            if not deferred_external and not stop:
                deferred_external = self.running_elsewhere(steps, statuses)
            if not running:
                if skipped:
                    continue
                if deferred_external:
                    time.sleep(self.policy.poll)  # only something outside this drive holds it: look again
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
            self.run.release_lane(lane)
            if st["status"] == "waiting" or st["status"] in ("held", "closed"):
                self.run.set_status(sid, polled=id(self))
            if st["status"] == "failed" and stop_on_fail:
                stop = True
        for s in steps:
            if self.run.status(s.id).get("polled"):
                self.run.set_status(s.id, polled=None)
        return self.exit_code(selected)

    def running_elsewhere(self, steps, statuses):
        """One of these steps runs in another tools/rel: this drive stays for what comes after it."""
        waiting = [s for s in steps if statuses[s.id] == "running"]
        if not waiting:
            return False
        with self.run.short("admit"):
            return any(self.run.lane_user(s.lane) == s.id for s in waiting)

    def skip_for_need(self, step):
        """pipeline.toml needs_ok: a step with nothing to work on when one of these needs failed as a
        warning or was skipped (screens-publish after a failed screens render) is skipped, not run.
        -> True when it was skipped."""
        bad = [n for n in step.needs_ok if self.run.status(n).get("warned") or self.run.status(n)["status"] == "skipped"]
        if not bad:
            return False
        reason = f"skipped: {', '.join(bad)} " + ("failed (warn_only)" if any(self.run.status(n).get("warned") for n in bad)
                                                   else "was skipped") + ", so there is nothing to work on"
        st = self.run.set_status(step.id, status="skipped", note=reason, ended=now_iso())
        self.run.event(step.id, "skipped", reason=reason, automatic=True)
        self.record_skip(step, reason)
        self.echo(f"⏭ {step.id}  {reason}")
        if self.relmsg:
            self.relmsg.step(step.id, relmsg_state(st), note=reason)
        return True

    def _worker(self, step):
        try:
            st = self.execute(step)
        except Exception as e:  # never lose the queue entry
            st = self.run.set_status(step.id, status="failed", note=f"tools/rel: {e}", cause="error", ended=now_iso())
            self.close_attempt(step, self.lane_fields(step, st.get("attempts", 0)), st, None, 0)
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
