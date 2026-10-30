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
from .load import LoadSampler
from .run import SETTLED, now_iso, read_json, write_json

# Exit codes (stable; agents read them).
EXIT_OK, EXIT_WAITING, EXIT_FAILED, EXIT_PREFLIGHT, EXIT_DENIED, EXIT_USAGE, EXIT_BUSY = 0, 10, 20, 30, 40, 64, 75

SAFE_ENV = ("PATH", "HOME", "USER", "LANG", "ANDROID_HOME", "ANDROID_NDK_HOME", "JAVA_HOME", "TMPDIR")


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


class Engine:
    def __init__(self, run, pipeline, hosts, repo, *, relmsg=None, dry=False, echo=None, failures=None):
        self.run = run
        self.pipeline = pipeline
        self.hosts = hosts
        self.repo = repo
        self.relmsg = relmsg
        self.dry = dry or bool(run.info.get("dry"))
        self.echo = echo or (lambda *a: None)
        self.failures = failures or []
        self._q = queue.Queue()
        self.load = LoadSampler()

    # ---- context ----

    @property
    def info(self):
        return self.run.info

    def base_env(self, step):
        i = self.info
        prev = i.get("previous", {})
        net = i.get("net", {})
        env = {
            "REL_RUN": self.run.path, "REL_RUN_ID": i["run_id"], "REL_VERSION": i["version"],
            "REL_COMMIT": i["commit"], "REL_FILES": self.run.files, "REL_EXTRA": self.run.extra,
            "REL_MANIFESTS": os.path.join(self.run.path, "manifests"),
            "REL_STAGE": os.path.join(self.run.step_dir(step.id), "out"), "REL_SRC": i.get("src", ""),
            "REL_TEST": "1" if i.get("test") else "0", "REL_TARGET": i.get("target", "live"),
            "REL_VARIANT": step.variant or "", "REL_NOTES_FILE": os.path.join(self.run.path, "notes.txt"),
            "REL_PREVIOUS_DIR": prev.get("dir", ""), "REL_PREVIOUS_VERSION": prev.get("version", ""),
            "REL_PREVIOUS_REF": prev.get("ref", ""),
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

    # ---- one step ----

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

    def execute(self, step):
        """Runs one step to an end state; returns its status dict."""
        from . import builtins
        st = self.run.status(step.id)
        attempt = st.get("attempts", 0) + 1
        started = time.time()
        log = self.attempt_log(step, attempt)
        self.run.set_status(step.id, status="running", attempts=attempt, started=now_iso(), ended=None,
                            note=None, hint=None, rc=None)
        self.run.event(step.id, "start", host=step.host, attempt=attempt, dry=self.dry or None)
        self.load.step_started(step.id)
        if self.relmsg:
            self.relmsg.step(step.id, "running", label=step.title, platform=(step.platforms[0] if len(step.platforms) == 1 else None))
        self.echo(f"▶ {step.id}  [{step.host}]{'  (dry run)' if self.dry else ''}")
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
                result = {"status": "failed", "note": f"{type(e).__name__}: {e}"}
            if result["status"] != "failed" or t == tries - 1:
                break
            self.run.event(step.id, "retry", attempt=attempt, try_=t + 1)
        dur = round(time.time() - started, 1)
        result.setdefault("note", None)
        if result["status"] == "failed":
            hits = known.match(self.failures, step.base, log)
            if hits:
                result["hint"] = " | ".join(h for _, h in hits)
                result["known"] = [i for i, _ in hits]
        if result["status"] in ("done", "failed", "skipped"):
            result["ended"] = now_iso()
            result["duration_s"] = dur
        if result["status"] == "done":
            result["input_hash"] = self.input_hash(step)
            if rkey:
                result["reuse_key"] = rkey
        st = self.run.set_status(step.id, **result)
        self.run.event(step.id, "end", status=st["status"], duration_s=dur, rc=st.get("rc"), bytes=st.get("bytes"),
                       note=st.get("note"), hint=st.get("hint"))
        self.metric(step, st, dur, self.load.step_ended(step.id))
        icon = {"done": "✓", "failed": "✗", "waiting": "⏸", "held": "✋", "closed": "✋", "skipped": "⏭"}.get(st["status"], "?")
        self.echo(f"{icon} {step.id}  {st['status']}  {dur:.0f}s" + (f"  {st['note']}" if st.get("note") else ""))
        if st.get("hint"):
            self.echo(f"   hint: {st['hint']}")
        if self.relmsg:
            rs = {"held": "waiting", "closed": "waiting"}.get(st["status"], st["status"])
            self.relmsg.step(step.id, rs, note=st.get("note"))
            if st["status"] == "failed":
                self.relmsg.alert(f"{step.id} failed", step=step.id, log=log,
                                  expects=st.get("hint") or "retry, skip or abort? (tools/rel retry|skip|debug)",
                                  key=f"{self.info['run_id']}/{step.id}/{attempt}")
        return st

    def try_reuse(self, step, log):
        """-> (key or None, a done result when an earlier passing result has the same key).
        Steps with `reuse` in pipeline.toml only (tools/rellib/reuse.py)."""
        spec = self.pipeline.steps.get(step.base) or {}
        if not spec.get("reuse") or self.dry:
            return None, None
        from . import reuse
        nightly = spec.get("reuse_nightly")
        nightly = os.path.expanduser("/tmp/epic-build/nightly") if nightly is True else nightly
        try:
            k, parts, src = reuse.find(self, step, spec["reuse"], nightly)
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

    def metric(self, step, st, dur, load=None):
        """One line per step end in <state_root>/metrics.jsonl: time, when it started and ended, the
        machine's load meanwhile and the steps beside it (load.py), and the emulator's health when a
        driver wrote {stage}/emulator.json. These are the data for when trust may start (RELEASING.md)."""
        line = {"ts": now_iso(), "run": self.info["run_id"], "version": self.info["version"], "step": step.id,
                "base": step.base, "host": step.host, "lane": step.lane, "status": st["status"], "duration_s": dur,
                "started": st.get("started"), "ended": st.get("ended"), "reused": bool(st.get("reused_from")) or None,
                "attempt": st.get("attempts"), "bytes": st.get("bytes"), "dry": self.dry or None,
                "test": self.info.get("test") or None}
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
        full_env = {k: v for k, v in os.environ.items()}
        full_env.update(env)
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
                return {"status": "failed", "rc": None, "note": f"timed out after {step.timeout:.0f}s"}
        if step.proof:
            return self._check_proof(step, rc)
        if rc != 0:
            return {"status": "failed", "rc": rc, "note": f"exit {rc}"}
        return self.collect(step, stage)

    def _dry_proof(self, step, cwd, env, log):
        full_env = dict(os.environ)
        full_env.update(env)
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
            return {"status": "failed", "rc": rc, "note": f"no proof.json (driver exit {rc})", "proven": False}
        checks = proof.get("checks", {})
        bad = [c for c in required if checks.get(c) is not True]
        res = {"rc": rc, "proof": proof, "proven": not bad and rc == 0}
        if bad or rc != 0:
            det = proof.get("details", {})
            note = "not proven: " + ", ".join(
                f"{c} ({det.get(c, 'false')})"[:80] for c in bad) if bad else f"driver exit {rc}"
            # A waived platform (release.toml [proof.waive]) still runs its driver so the gate shows
            # what it found; its result is reported, never counted as proven, and blocks nothing.
            reason = self.info["scope"]["proof"]["waive"].get(step.platforms[0]) if step.platforms else None
            if reason is not None:
                res.update(status="done", waived=True, note=f"NOT PROVEN (waived: {reason}): {note}")
            else:
                res.update(status="failed", note=note)
        else:
            res.update(status="done", note=f"proven {proof.get('previous')} → {proof.get('candidate')} "
                                           f"({proof.get('update_method', '?')}; node {proof.get('node')}, epicbox {proof.get('epicbox')})")
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
                if step.base == "apple-build" and not self.dry and self.info.get("src"):
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
        stop = False
        if not self.dry:
            self.load.start()
        try:
            return self._drive(steps, lanes_busy, running, stop, stop_on_fail, selected)
        finally:
            self.load.stop()
            self.overlap_metrics()

    def _drive(self, steps, lanes_busy, running, stop, stop_on_fail, selected):
        while True:
            statuses = {s.id: self.run.status(s.id)["status"] for s in self.run.steps}
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
                    self.run.set_status(s.id, retry=False)
                    lanes_busy.add(s.lane)
                    th = threading.Thread(target=self._worker, args=(s,), daemon=True)
                    running[s.id] = (th, s.lane)
                    th.start()
            if not running:
                break
            sid, st = self._q.get()
            th, lane = running.pop(sid)
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
