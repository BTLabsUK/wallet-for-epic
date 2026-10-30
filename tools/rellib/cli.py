# SPDX-License-Identifier: Apache-2.0
"""tools/rel: the release runner's command line (docs/RELEASING.md).

Every command takes --json (one JSON object on stdout) and ends with a stable exit code:
0 ok · 10 waiting (a gate or a hand-off) · 20 a step failed · 30 preflight failed ·
40 a gate said no (held, or could not be asked: fail closed) · 64 usage or a scope that makes no
sense · 75 another tools/rel is working on that run."""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

from . import failures as known, retention
from .config import (ConfigError, PLATFORMS, Pipeline, load_hosts, load_scope, scope_summary, scope_toml,
                     validate_scope)
from .engine import (EXIT_BUSY, EXIT_DENIED, EXIT_FAILED, EXIT_OK, EXIT_USAGE, EXIT_WAITING, Engine)
from .graph import build_graph, dependents
from .relmsg import Relmsg
from .run import Busy, Run, read_json, write_json

EXIT_TEXT = {0: "ok", 10: "waiting", 20: "step failed", 30: "preflight failed", 40: "gate closed", 64: "usage", 75: "busy"}


def repo_root():
    here = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    return here


class Lenient(dict):
    """host.* / path.* for templates: a key the machine's file lacks renders as <unset …>, and
    preflight refuses a run whose steps still hold one."""

    def __init__(self, data, prefix):
        super().__init__(data)
        self.prefix = prefix

    def __contains__(self, k):
        return True

    def __getitem__(self, k):
        if dict.__contains__(self, k):
            v = dict.__getitem__(self, k)
            return Lenient(v, f"{self.prefix}.{k}") if isinstance(v, dict) else v
        if self.prefix == "host":
            return Lenient({}, f"host.{k}")
        return f"<unset {self.prefix}.{k}>"


# The checkout tools/rel runs from: its own step scripts ({rel}/tools/rellib/steps/...) come from
# here, so a release commit older than the runner can still be released.
RUNNER = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def context(version, commit, run_path, run_id, src, scope, hosts, previous):
    return {
        "rel": RUNNER,
        "version": version, "commit": commit, "short": commit[:7], "run_id": run_id, "run": run_path,
        "files": f"{run_path}/files", "extra": f"{run_path}/extra", "manifests": f"{run_path}/manifests",
        "src": src, "target": scope["publish"]["target"], "scratch": f"{run_path}/scratch/target",
        "notes_file": f"{run_path}/notes.txt",
        "previous_dir": previous.get("dir", ""), "previous_version": previous.get("version", ""),
        "previous_ref": previous.get("ref", ""),
        "node": "$REL_NODE", "epicbox": "$REL_EPICBOX",
        "host": Lenient(hosts["host"], "host"), "path": Lenient(hosts["path"], "path"),
    }


def version_at(repo, commit):
    try:
        text = subprocess.run(["git", "-C", repo, "show", f"{commit}:app/pubspec.yaml"], capture_output=True,
                              text=True, check=True).stdout
    except subprocess.CalledProcessError:
        return None
    m = re.search(r"^version:\s*([0-9][^+\s]*)", text, re.M)
    return m.group(1) if m else None


class App:
    def __init__(self, args):
        self.args = args
        self.repo = repo_root()
        self.pipeline = Pipeline.load(args.pipeline or os.path.join(self.repo, "release/pipeline.toml"))
        self.hosts = load_hosts(args.hosts)
        self.state_root = self.pipeline.state_root(args.state_root)
        self.failures = known.load(os.path.join(self.repo, "release/failures.toml"))

    def out(self, code, message, run=None, **extra):
        a = self.args
        if a.json:
            obj = {"exit": code, "result": EXIT_TEXT.get(code, "?"), "message": message}
            if run:
                obj.update(run_id=run.info["run_id"], run=run.path, version=run.info["version"],
                           test=bool(run.info.get("test")), dry=bool(run.info.get("dry")), steps=run.summary_rows())
            obj.update(extra)
            print(json.dumps(obj, indent=None))
        else:
            if message:
                print(message)
        return code

    def echo(self, text):
        if not self.args.json:
            print(text, flush=True)

    def engine(self, run, relmsg_on=True, dry=False):
        rm = None
        if not run.info.get("dry") and not dry:
            rm = Relmsg(run, self.pipeline.relmsg, enabled=relmsg_on and not run.info.get("no_relmsg"))
        return Engine(run, self.pipeline, self.hosts, self.repo, relmsg=rm, dry=dry, echo=self.echo,
                      failures=self.failures)

    def load_run(self, ref=None):
        return Run.find(self.state_root, ref or getattr(self.args, "run", None))

    # ---- scope and plan ----

    def resolve(self, a):
        commit = a.commit or subprocess.run(["git", "-C", self.repo, "rev-parse", "HEAD"], capture_output=True,
                                            text=True, check=True).stdout.strip()
        commit = subprocess.run(["git", "-C", self.repo, "rev-parse", "--verify", f"{commit}^{{commit}}"],
                                capture_output=True, text=True).stdout.strip() or commit
        scope = load_scope(a.scope, a.version, a.only, a.skip_platform, a.no_variant, a.set, a.skip,
                           a.test, None, a.waive)
        if a.previous:
            scope["proof"]["previous_dir"] = a.previous
        vac = version_at(self.repo, commit)
        prev = {}
        pubs = retention.published(self.state_root)
        if scope["proof"]["previous_dir"]:
            d = os.path.expanduser(scope["proof"]["previous_dir"])
            name = os.path.basename(d.rstrip("/"))
            m = re.match(r"\d{2}\.\d{1,2}\.\d+", name)
            prev = {"dir": d, "version": scope["proof"]["previous_version"] or (m.group(0) if m else name),
                    "ref": scope["proof"]["previous_ref"] or f"v{name}"}
        elif pubs:
            p = pubs[-1]
            prev = {"dir": os.path.join(p["run"], "files"), "version": p["version"], "ref": p.get("tag", "")}
        warns = validate_scope(scope, self.pipeline, vac, prev.get("version"))
        return commit, scope, prev, warns

    def cmd_plan(self, a):
        commit, scope, prev, warns = self.resolve(a)
        path, run_id = Run.next_path(self.state_root, scope["version"])
        src = a.src or os.path.join(self.hosts["path"].get("worktrees", os.path.expanduser("~/wfe-worktrees")),
                                    f"rel-{scope['version']}-{commit[:7]}")
        steps = build_graph(self.pipeline, scope, context(scope["version"], commit, path, run_id, src, scope, self.hosts, prev))
        if a.json:
            return self.out(0, "plan", steps=[s.to_dict() for s in steps], scope=scope, warnings=warns,
                            summary=scope_summary(scope))
        print(f"{'TEST ' if scope['test'] else ''}release {scope['version']} at {commit[:12]}")
        print(f"scope: {scope_summary(scope)}")
        for w in warns:
            print(f"warning: {w}")
        if prev:
            print(f"previous release (G4): {prev['version']} at {prev['dir']}")
        drivers = self.pipeline.proof.get("drivers", {})
        for s in steps:
            waived = s.proof and s.platforms and s.platforms[0] in scope["proof"]["waive"]
            skip = scope["skip"].get(s.base) or (f"waived: {scope['proof']['waive'][s.platforms[0]]}"
                                                  if waived and not drivers.get(s.platforms[0]) else None)
            print(f"  {'P' if s.publish else ' '} {s.id:28} {s.host:8} {s.kind:8} needs {', '.join(s.needs) or '-'}"
                  + (f"   SKIP ({skip})" if skip else "   (waived: runs, shown, blocks nothing)" if waived else ""))
            if a.verbose and s.run:
                print(f"      {s.run}")
        print("P = publish phase (tools/rel publish, after the publish gate)")
        return EXIT_OK

    # ---- start / resume / publish ----

    def cmd_start(self, a):
        commit, scope, prev, warns = self.resolve(a)
        version = scope["version"]
        path, run_id = Run.next_path(self.state_root, version)
        wt = self.hosts["path"].get("worktrees", os.path.expanduser("~/wfe-worktrees"))
        src = os.path.abspath(a.src) if a.src else os.path.join(wt, f"rel-{version}-{commit[:7]}")
        steps = build_graph(self.pipeline, scope, context(version, commit, path, run_id, src, scope, self.hosts, prev))
        info = {"version": version, "commit": commit, "scope": scope, "test": scope["test"], "dry": bool(a.dry_run),
                "target": scope["publish"]["target"], "src": src, "src_made": not a.src, "warnings": warns,
                "previous": prev, "kind": "release", "no_relmsg": bool(a.no_relmsg), "argv": sys.argv[1:]}
        os.makedirs(self.state_root, exist_ok=True)
        run = Run.create(self.state_root, version, info, scope_toml(scope), steps)
        with open(os.path.join(run.path, "notes.txt"), "w", encoding="utf-8") as f:
            f.write(scope["publish"].get("notes", ""))
        for s in run.steps:
            if s.base in scope["skip"]:
                run.set_status(s.id, status="skipped", reason=f"release.toml [skip]: {scope['skip'][s.base]}")
            elif (s.proof and s.platforms and s.platforms[0] in scope["proof"]["waive"]
                  and not self.pipeline.proof.get("drivers", {}).get(s.platforms[0])):
                # A waived platform with a driver still runs it: the gate shows what it found.
                run.set_status(s.id, status="skipped", reason=f"waived: {scope['proof']['waive'][s.platforms[0]]}")
        self.echo(f"run {run.info['run_id']} in {run.path}")
        self.echo(f"scope: {scope_summary(scope)}")
        for w in warns:
            self.echo(f"warning: {w}")
        eng = self.engine(run, dry=bool(a.dry_run))
        self.relmsg_start(run, eng)
        return self.drive(run, eng, phase="build", until=a.until)

    def drive(self, run, eng, phase, until=None, retry_failed=False):
        try:
            run.lock()
        except Busy as e:
            return self.out(EXIT_BUSY, str(e), run)
        try:
            sel = [s.id for s in run.steps if (s.phase == "build" or phase == "publish")]
            if until:
                target = run.step(until).id
                need, frontier = {target}, {target}
                while frontier:
                    nxt = set()
                    for sid in frontier:
                        nxt |= set(run.step(sid).needs)
                    frontier = nxt - need
                    need |= nxt
                sel = [x for x in sel if x in need]
            for sid in sel:
                st = run.status(sid)
                s = run.step(sid)
                if st["status"] == "failed" and retry_failed:
                    run.set_status(sid, retry=True)
                if st["status"] == "done" and not st.get("dry") and st.get("input_hash") and \
                        st["input_hash"] != eng.input_hash(s) and not s.publish:
                    run.set_status(sid, status="pending", note="inputs changed since it ran")
                if st["status"] == "running":
                    run.set_status(sid, status="pending", note="was running when tools/rel stopped")
            code = eng.drive(sel)
        finally:
            run.unlock()
        return self.finish(run, eng, code)

    def finish(self, run, eng, code):
        report(run)
        rows = run.summary_rows()
        waiting = [r for r in rows if r["status"] in ("waiting", "held", "closed")]
        failed = [r for r in rows if r["status"] == "failed"]
        if code == EXIT_OK:
            msg = f"{run.info['run_id']}: all selected steps done"
        elif failed:
            f = failed[0]
            msg = (f"{run.info['run_id']}: {f['id']} failed: {f.get('note') or ''}\n"
                   + (f"hint: {f['hint']}\n" if f.get("hint") else "")
                   + f"log: {os.path.join(run.step_dir(f['id']), 'log.txt')}\n"
                   + f"last lines:\n{known.tail(os.path.join(run.step_dir(f['id']), 'log.txt'), 25)}\n"
                   + f"debug: tools/rel debug {f['id']}   retry: tools/rel retry {f['id']}")
        elif waiting:
            msg = f"{run.info['run_id']}: waiting: " + "; ".join(f"{w['id']}: {w.get('note') or w['status']}" for w in waiting)
        else:
            msg = f"{run.info['run_id']}: {EXIT_TEXT.get(code)}"
        return self.out(code, msg, run)

    def relmsg_start(self, run, eng):
        """Opens the run's live message (idempotent on the run id) and shows every step's state
        so far, so a run resumed or switched to Telegram midway shows the whole picture."""
        if not eng.relmsg or eng.relmsg.release_id:
            return
        if not eng.relmsg.start([s.id for s in run.steps], [p for p in PLATFORMS if run.info["scope"]["platforms"].get(p)]):
            return
        for p in PLATFORMS:
            if not run.info["scope"]["platforms"].get(p):
                eng.relmsg.platform(p, "skipped", note="out of scope")
        for s in run.steps:
            st = run.status(s.id)
            if st["status"] not in ("pending", "running"):
                rs = {"held": "waiting", "closed": "waiting"}.get(st["status"], st["status"])
                eng.relmsg.step(s.id, rs, note=st.get("note") or st.get("reason"), label=s.title)

    def cmd_resume(self, a):
        run = self.load_run()
        if a.relmsg and run.info.get("no_relmsg"):
            run.info["no_relmsg"] = False
            run.save_info()
        eng = self.engine(run)
        self.relmsg_start(run, eng)
        return self.drive(run, eng, phase="publish" if a.publish else "build", until=a.until, retry_failed=True)

    def cmd_run(self, a):
        """One step, and nothing after it."""
        run = self.load_run()
        s = run.step(a.step)
        eng = self.engine(run, dry=bool(a.dry_run))
        st = run.status(s.id)
        if s.publish and st["status"] == "done" and not a.again:
            return self.out(EXIT_USAGE, f"{s.id} is a publish step and already done: --again to run it again", run)
        if s.publish and not run.info.get("dry"):
            gate = [x for x in run.steps if x.kind == "gate"]
            if gate and run.status(gate[0].id)["status"] != "done":
                return self.out(EXIT_DENIED, f"{s.id} publishes: the gate {gate[0].id} has not approved this run", run)
        unmet = [n for n in s.needs if run.status(n)["status"] not in ("done", "skipped")]
        if unmet and not a.ignore_needs:
            return self.out(EXIT_USAGE, f"{s.id} needs {', '.join(unmet)} first (or --ignore-needs: the run is then "
                                        "tainted and can never be published)", run)
        if unmet:
            if s.publish:
                return self.out(EXIT_USAGE, "a publish step never runs with --ignore-needs", run)
            run.taint(f"{s.id} run with unmet needs: {', '.join(unmet)}")
        try:
            run.lock()
        except Busy as e:
            return self.out(EXIT_BUSY, str(e), run)
        try:
            run.set_status(s.id, status="pending", retry=False)
            saved = s.needs
            s.needs = [] if unmet else s.needs
            code = eng.drive([s.id])
            s.needs = saved
        finally:
            run.unlock()
        return self.finish(run, eng, code)

    def cmd_retry(self, a):
        run = self.load_run()
        s = run.step(a.step)
        st = run.status(s.id)
        if st["status"] not in ("failed", "waiting", "held", "closed") and not a.again:
            return self.out(EXIT_USAGE, f"{s.id} is {st['status']}; retry is for a failed step (--again to re-run a done one)", run)
        if s.publish and st["status"] == "done" and not a.again:
            return self.out(EXIT_USAGE, f"{s.id} publishes and is done: --again to run it again", run)
        run.set_status(s.id, status="pending", retry=False)
        run.event(s.id, "retry-requested")
        a.ignore_needs, a.dry_run = False, False
        a.step = s.id
        return self.cmd_run(a)

    def cmd_skip(self, a):
        run = self.load_run()
        s = run.step(a.step)
        spec = self.pipeline.steps.get(s.base, {})
        if not spec.get("skippable"):
            return self.out(EXIT_USAGE, f"{s.id} cannot be skipped (builds and gates never are; drop a platform in "
                                        "release.toml and start a new run, or waive its proof)", run)
        if not a.reason.strip():
            return self.out(EXIT_USAGE, "--reason is required", run)
        run.set_status(s.id, status="skipped", reason=a.reason)
        run.event(s.id, "skipped", reason=a.reason)
        eng = self.engine(run)
        if eng.relmsg:
            eng.relmsg.step(s.id, "skipped", note=a.reason)
        return self.out(EXIT_OK, f"{s.id} skipped: {a.reason}", run)

    def cmd_gate(self, a):
        run = self.load_run()
        gates = [s for s in run.steps if s.kind == "gate"]
        if not gates:
            return self.out(EXIT_USAGE, "this run has no gate", run)
        g = gates[0]
        unmet = [n for n in g.needs if run.status(n)["status"] not in ("done", "skipped")]
        if unmet:
            return self.out(EXIT_WAITING, f"{g.id} is not asked yet: {', '.join(unmet)} first", run)
        eng = self.engine(run)
        try:
            run.lock()
        except Busy as e:
            return self.out(EXIT_BUSY, str(e), run)
        try:
            st = eng.execute(g)
        finally:
            run.unlock()
        code = {"done": EXIT_OK, "waiting": EXIT_WAITING}.get(st["status"], EXIT_DENIED)
        return self.out(code, f"{g.id}: {st['status']}: {st.get('note') or ''}", run, gate=run.info.get("gates", {}))

    def cmd_publish(self, a):
        run = self.load_run()
        dry = bool(a.dry_run) or bool(run.info.get("dry"))
        gates = [s for s in run.steps if s.kind == "gate"]
        if not dry:
            if run.info.get("tainted"):
                return self.out(EXIT_DENIED, "this run is tainted and can never be published: "
                                + run.info["tainted"][-1]["reason"], run)
            if not gates:
                return self.out(EXIT_DENIED, "no gate in this run: nothing is published without one", run)
            gst = run.status(gates[0].id)["status"]
            if gst != "done":
                self.cmd_gate(a)
                gst = run.status(gates[0].id)["status"]
                if gst != "done":
                    return self.out(EXIT_WAITING if gst == "waiting" else EXIT_DENIED,
                                    f"{gates[0].id} is {gst}: nothing is published", run)
        eng = self.engine(run, dry=dry)
        code = self.drive(run, eng, phase="publish", until=a.until, retry_failed=True)
        if code == EXIT_OK and eng.relmsg:
            if run.info.get("kind") == "rollback":
                eng.relmsg.done("ok", note=f"rolled back {run.info.get('replaces')} → {run.info['version']}")
            else:
                eng.relmsg.done("ok", note=f"{run.info['version']} published ({run.info['target']})")
        return code

    # ---- looking ----

    def cmd_status(self, a):
        run = self.load_run()
        rows = run.summary_rows()
        if a.json:
            return self.out(EXIT_OK, "status", run, gates=run.info.get("gates", {}), tainted=run.info.get("tainted"))
        print(f"{'TEST ' if run.info.get('test') else ''}{'DRY ' if run.info.get('dry') else ''}"
              f"{run.info['run_id']}  {run.info['commit'][:12]}  {run.path}")
        print(f"scope: {scope_summary(run.info['scope'])}")
        if run.info.get("tainted"):
            print(f"TAINTED: {run.info['tainted'][-1]['reason']} (never publishable)")
        for r in rows:
            d = f"{r['duration_s']:.0f}s" if r.get("duration_s") is not None else ""
            extra = r.get("note") or r.get("reason") or ""
            print(f"  {r['status']:8} {r['id']:28} {d:>7}  {extra[:110]}")
        return EXIT_OK

    def cmd_logs(self, a):
        run = self.load_run()
        s = run.step(a.step)
        d = run.step_dir(s.id)
        log = os.path.join(d, f"attempt-{a.attempt}.log") if a.attempt else os.path.join(d, "log.txt")
        if a.json:
            return self.out(EXIT_OK, "log", run, log=log, tail=known.tail(log, a.lines))
        if a.follow:
            os.execvp("tail", ["tail", "-n", str(a.lines), "-F", log])
        print(known.tail(log, a.lines))
        return EXIT_OK

    def cmd_debug(self, a):
        run = self.load_run()
        s = run.step(a.step)
        eng = self.engine(run)
        st = run.status(s.id)
        info = {"step": s.id, "kind": s.kind, "host": s.host, "status": st.get("status"), "note": st.get("note"),
                "hint": st.get("hint"), "log": os.path.join(run.step_dir(s.id), "log.txt"), "stage": os.path.join(run.step_dir(s.id), "out")}
        if s.kind in ("command", "publish"):
            argv, cwd, env = eng.command_line(s)
            info.update(cwd=cwd, env=env, run=s.run, argv=argv)
        if s.kind == "handoff":
            info.update(job=os.path.join(run.path, "handoff", s.id, "job"), results=os.path.join(run.path, "handoff", s.id, "results"))
        if a.json:
            return self.out(EXIT_OK, "debug", run, debug=info)
        for k, v in info.items():
            if k == "env":
                print("env:")
                for ek in sorted(v):
                    print(f"  {ek}={v[ek]}")
            elif v is not None and k != "argv":
                print(f"{k}: {v}")
        if s.kind in ("command", "publish"):
            exports = " ".join(f"{k}={shlex_quote(v)}" for k, v in sorted(info["env"].items()))
            print(f"\nreproduce:\n  cd {shlex_quote(info['cwd'])} && env {exports} bash -c {shlex_quote('set -euo pipefail; ' + s.run)}")
        if a.exec:
            if s.kind not in ("command",):
                return self.out(EXIT_USAGE, "--exec is for command steps", run)
            if s.publish:
                return self.out(EXIT_USAGE, "never --exec a publish step", run)
            print("\n(--exec: runs it here with the console attached; the log is debug-<n>.log; the step's status is not changed)")
            n = len([f for f in os.listdir(run.step_dir(s.id)) if f.startswith("debug-")]) + 1
            dlog = os.path.join(run.step_dir(s.id), f"debug-{n}.log")
            full = dict(os.environ)
            full.update(info["env"])
            p = subprocess.run(["bash", "-c", f"set -o pipefail; ( {s.run} ) 2>&1 | tee {shlex_quote(dlog)}"],
                               cwd=info["cwd"], env=full)
            return p.returncode and EXIT_FAILED
        return EXIT_OK

    def cmd_verify(self, a):
        from .builtins import page_kinds, build_tools, sh
        folder = a.folder
        kinds, cert = page_kinds(self.repo)
        problems, ok = [], []
        sums = os.path.join(folder, "SHA256SUMS")
        if os.path.isfile(sums):
            p = subprocess.run(["sha256sum", "-c", "--quiet", "SHA256SUMS"], cwd=folder, capture_output=True, text=True)
            (ok if p.returncode == 0 else problems).append("SHA256SUMS " + ("agrees" if p.returncode == 0 else p.stdout.strip()[-300:]))
        else:
            problems.append("no SHA256SUMS")
        bt = build_tools()
        for name in sorted(os.listdir(folder)):
            path = os.path.join(folder, name)
            if not os.path.isfile(path) or name in ("SHA256SUMS", "provenance.json", "DONE"):
                continue
            hit = [k for k in kinds if re.match(k[0], name)]
            if not hit:
                problems.append(f"{name}: no KINDS pattern")
                continue
            if name.endswith(".apk") and bt:
                out = subprocess.run([os.path.join(bt, "apksigner"), "verify", "--print-certs", path], capture_output=True, text=True).stdout
                (ok if cert in out else problems).append(f"{name}: release certificate {'ok' if cert in out else 'MISSING'}")
            else:
                ok.append(f"{name}: {hit[0][1]} {hit[0][2]}")
        if a.json:
            return self.out(EXIT_OK if not problems else EXIT_FAILED, "verify", ok=ok, problems=problems)
        for x in ok:
            print("ok  ", x)
        for x in problems:
            print("FAIL", x)
        return EXIT_OK if not problems else EXIT_FAILED

    def cmd_doctor(self, a):
        """G1 alone: what this machine is missing for this scope."""
        from .builtins import preflight
        a.version = a.version or version_at(self.repo, "HEAD")
        commit, scope, prev, warns = self.resolve(a)
        tmp = os.path.join(self.state_root, ".doctor")
        os.makedirs(tmp, exist_ok=True)
        root = tempfile.mkdtemp(dir=tmp)
        try:
            run = Run.create(root, scope["version"], {"version": scope["version"], "commit": commit, "scope": scope,
                                                      "test": scope["test"], "src": self.repo, "previous": prev}, "", [])
            eng = Engine(run, self.pipeline, self.hosts, self.repo, echo=self.echo)
            lines = []
            res = preflight(eng, None, lambda *x: lines.append(" ".join(str(y) for y in x)))
        finally:
            shutil.rmtree(root, ignore_errors=True)
        code = EXIT_OK if res["status"] == "done" else 30
        if a.json:
            return self.out(code, res.get("note", ""), checks=lines, warnings=warns + res.get("warnings", []))
        print("\n".join(lines))
        print(res.get("note", ""))
        return code

    def cmd_rollback(self, a):
        from . import rollback
        try:
            bad, good = rollback.choose(self.state_root, a.to)
        except ValueError as e:
            return self.out(EXIT_USAGE, str(e))
        base_ctx = {"host": Lenient(self.hosts["host"], "host"), "path": Lenient(self.hosts["path"], "path"),
                    "node": "$REL_NODE", "epicbox": "$REL_EPICBOX"}
        run = rollback.make_run(self.state_root, self.pipeline, self.hosts, self.repo, bad, good, a.test, base_ctx)
        if a.dry_run:
            run.info["dry"] = True
            run.save_info()
        eng = self.engine(run, dry=bool(a.dry_run))
        if eng.relmsg:
            eng.relmsg.start([s.id for s in run.steps], [])
        self.echo(f"rollback {bad['version']} → {good['version']}: run {run.info['run_id']}")
        return self.drive(run, eng, phase="build")

    def cmd_cleanup(self, a):
        lines = []
        res = retention.apply(self.state_root, self.repo, lambda x: (lines.append(x), self.echo(x)), dry=a.dry_run)
        msg = f"{'would remove' if a.dry_run else 'removed'} {len(res['removed']) if not a.dry_run else len(lines)} run(s); kept: {', '.join(res['kept']) or 'nothing'}"
        return self.out(EXIT_OK, msg, kept=res["kept"], removed=res["removed"] if not a.dry_run else lines)

    def cmd_stats(self, a):
        path = os.path.join(self.state_root, "metrics.jsonl")
        rows = []
        if os.path.isfile(path):
            for line in open(path):
                try:
                    rows.append(json.loads(line))
                except json.JSONDecodeError:
                    pass
        rows = [r for r in rows if not r.get("dry")]
        by = {}
        for r in rows:
            by.setdefault(r["base"], []).append(r)
        table = []
        for base, rs in by.items():
            done = [r["duration_s"] for r in rs if r["status"] == "done"]
            last = done[-1] if done else None
            prev5 = done[-6:-1]
            avg = sum(prev5) / len(prev5) if prev5 else None
            table.append({"step": base, "runs": len(rs), "failed": sum(1 for r in rs if r["status"] == "failed"),
                          "last_s": last, "avg_prev5_s": round(avg, 1) if avg else None,
                          "slower": bool(last and avg and last > 1.25 * avg)})
        if a.json:
            return self.out(EXIT_OK, "stats", stats=table)
        print(f"{'step':24} {'runs':>5} {'failed':>6} {'last':>8} {'avg(5)':>8}")
        for t in sorted(table, key=lambda t: t["step"]):
            fmt = lambda v: f"{v:.0f}s" if v is not None else "-"
            print(f"{t['step']:24} {t['runs']:>5} {t['failed']:>6} {fmt(t['last_s']):>8} {fmt(t['avg_prev5_s']):>8}"
                  + ("  slower" if t["slower"] else ""))
        return EXIT_OK

    def cmd_report(self, a):
        run = self.load_run()
        md, html = report(run)
        return self.out(EXIT_OK, f"{md}\n{html}", run)

    def cmd_runs(self, a):
        runs = Run.all(self.state_root)
        pubs = {p["run_id"] for p in retention.published(self.state_root)}
        if a.json:
            return self.out(EXIT_OK, "runs", runs=[{"version": v, "run_id": r, "run": p, "created": c, "published": r in pubs}
                                                   for v, r, p, c in runs])
        for v, r, p, c in runs:
            info = read_json(os.path.join(p, "run.json"), {})
            tags = [t for t, on in (("published", r in pubs), ("TEST", info.get("test")), ("DRY", info.get("dry")),
                                    ("rollback", info.get("kind") == "rollback")) if on]
            print(f"{c}  {r:24} {' '.join(tags)}")
        return EXIT_OK


def shlex_quote(s):
    import shlex
    return shlex.quote(str(s))


def report(run):
    """summary.md and report.html in the run folder: steps, times, sizes, gates, skips."""
    rows = run.summary_rows()
    info = run.info
    tot = sum(r["duration_s"] or 0 for r in rows)
    md = [f"# {'TEST ' if info.get('test') else ''}{'DRY RUN ' if info.get('dry') else ''}Epic Wallet {info['version']} — {info['run_id']}",
          "", f"- commit `{info['commit']}`", f"- scope: {scope_summary(info['scope'])}",
          f"- step time (sum): {tot / 60:.1f} min"]
    if info.get("tainted"):
        md.append(f"- **TAINTED** (never publishable): {info['tainted'][-1]['reason']}")
    if info.get("net"):
        md.append(f"- test network: node {info['net'].get('node')}, Epicbox {info['net'].get('epicbox')}")
    for g, v in info.get("gates", {}).items():
        md.append(f"- gate {g}: {v.get('state')} (id {v.get('gate_id')}" + (f", by {v.get('decided_by')} via {v.get('via')}" if v.get("decided_by") else "") + ")")
    md += ["", "| step | status | time | tries | size | note |", "|---|---|---|---|---|---|"]
    for r in rows:
        d = f"{r['duration_s']:.0f}s" if r.get("duration_s") is not None else ""
        size = f"{r['bytes'] / 1e6:.0f} MB" if r.get("bytes") else ""
        note = (r.get("note") or r.get("reason") or "").replace("|", "/")
        if r.get("hint"):
            note += f" — hint: {r['hint']}"
        md.append(f"| {r['id']} | {r['status']} | {d} | {r['attempts']} | {size} | {note[:160]} |")
    text = "\n".join(md) + "\n"
    mdp = os.path.join(run.path, "summary.md")
    with open(mdp, "w", encoding="utf-8") as f:
        f.write(text)
    import html as h
    def cell(r):
        d = "" if r.get("duration_s") is None else f"{r['duration_s']:.0f}s"
        size = f"{r['bytes'] / 1e6:.0f} MB" if r.get("bytes") else ""
        note = (r.get("note") or r.get("reason") or "")[:200]
        return (f"<tr class='{h.escape(r['status'])}'><td>{h.escape(r['id'])}</td><td>{h.escape(r['status'])}</td>"
                f"<td>{d}</td><td>{r['attempts']}</td><td>{size}</td><td>{h.escape(note)}</td></tr>")

    trs = "".join(cell(r) for r in rows)
    page = f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{h.escape(info['run_id'])}</title><style>
:root{{--bg:#111418;--fg:#e6e8eb;--mut:#9aa3ad;--ok:#3fb950;--bad:#f85149;--wait:#d29922;--line:#2a2f36}}
:root[data-theme=light]{{--bg:#fff;--fg:#1f2328;--mut:#59636e;--line:#d0d7de}}
body{{background:var(--bg);color:var(--fg);font:14px/1.45 system-ui,sans-serif;margin:0;padding:16px;max-width:1100px}}
table{{border-collapse:collapse;width:100%}}td,th{{border-bottom:1px solid var(--line);padding:4px 6px;text-align:left;vertical-align:top}}
.done td:nth-child(2){{color:var(--ok)}}.failed td:nth-child(2){{color:var(--bad)}}.waiting td:nth-child(2),.held td:nth-child(2){{color:var(--wait)}}
.skipped td:nth-child(2){{color:var(--mut)}}button{{float:right}}.wrap{{overflow-x:auto}}</style></head><body>
<button onclick="document.documentElement.dataset.theme=document.documentElement.dataset.theme==='light'?'':'light'">Light/dark</button>
<pre>{h.escape(chr(10).join(md[:12]))}</pre><div class="wrap"><table><tr><th>step</th><th>status</th><th>time</th><th>tries</th><th>size</th><th>note</th></tr>{trs}</table></div></body></html>"""
    hp = os.path.join(run.path, "report.html")
    with open(hp, "w", encoding="utf-8") as f:
        f.write(page)
    return mdp, hp


def parser():
    p = argparse.ArgumentParser(prog="tools/rel", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--json", action="store_true", help="one JSON object on stdout")
    p.add_argument("--state-root", help="where runs live (default [defaults] state_root, or REL_STATE_ROOT)")
    p.add_argument("--pipeline", help="release/pipeline.toml")
    p.add_argument("--hosts", help="release-hosts.toml (default ~/.config/btlabs/release-hosts.toml, or REL_HOSTS)")
    sub = p.add_subparsers(dest="cmd", required=True)

    def scope_args(sp, version_required=True):
        sp.add_argument("version", nargs="?" if not version_required else None, help="YY.MM.patch (= app/pubspec.yaml)")
        sp.add_argument("--scope", help="a release.toml (default: everything on, stores off)")
        sp.add_argument("--only", help="only these platforms, e.g. android,linux")
        sp.add_argument("--skip-platform", help="drop platforms, e.g. macos,ios")
        sp.add_argument("--no-variant", help="drop a variant: tor or notor")
        sp.add_argument("--set", action="append", help="a scope key, e.g. stores.play=true, publish.notes=...")
        sp.add_argument("--skip", action="append", help="skip a skippable step: name=reason")
        sp.add_argument("--waive", action="append", help="ship a platform without the update proof: platform=reason")
        sp.add_argument("--test", action="store_true", help="a TEST run: scratch target, test key, TEST in Telegram")
        sp.add_argument("--commit", help="the commit to release (default HEAD of this checkout)")
        sp.add_argument("--src", help="use this clean checkout at the commit instead of a new worktree")
        sp.add_argument("--previous", help="the previous release's folder for G4 (default: the last published run)")

    sp = sub.add_parser("plan", help="the graph for a scope; no side effects")
    scope_args(sp)
    sp.add_argument("-v", "--verbose", action="store_true")
    sp = sub.add_parser("start", help="create a run and run it up to the publish gate")
    scope_args(sp)
    sp.add_argument("--dry-run", action="store_true", help="print and record every command; run nothing")
    sp.add_argument("--no-relmsg", action="store_true", help="no Telegram (the publish gate then stays closed)")
    sp.add_argument("--until", help="stop after this step")
    sp = sub.add_parser("doctor", help="G1 preflight alone")
    scope_args(sp, version_required=False)
    for name, hlp in (("resume", "carry on: failed steps again, done ones kept"), ("status", "steps and gates"),
                      ("gate", "ask or check the gate"), ("publish", "after approval: downloads → page → source → manifests"),
                      ("report", "summary.md + report.html")):
        sp = sub.add_parser(name, help=hlp)
        sp.add_argument("--run", help="run id, folder or version (default: the newest run)")
        if name in ("resume", "publish"):
            sp.add_argument("--until")
        if name == "resume":
            sp.add_argument("--publish", action="store_true", help="also the publish phase (needs the gate)")
            sp.add_argument("--relmsg", action="store_true", help="turn Telegram on for a run started with --no-relmsg")
        if name == "publish":
            sp.add_argument("--dry-run", action="store_true")
    for name, hlp in (("run", "one step, nothing after it"), ("retry", "a failed step again"), ("logs", "a step's log"),
                      ("debug", "a step's exact command, env and log; --exec re-runs it here"), ("skip", "skip a skippable step")):
        sp = sub.add_parser(name, help=hlp)
        sp.add_argument("step")
        sp.add_argument("--run")
        if name in ("run", "retry"):
            sp.add_argument("--again", action="store_true", help="also a step that is done (publish steps need it)")
        if name == "run":
            sp.add_argument("--ignore-needs", action="store_true", help="taints the run: never publishable")
            sp.add_argument("--dry-run", action="store_true")
        if name == "logs":
            sp.add_argument("-f", "--follow", action="store_true")
            sp.add_argument("-n", "--lines", type=int, default=60)
            sp.add_argument("--attempt", type=int)
        if name == "debug":
            sp.add_argument("--exec", action="store_true")
        if name == "skip":
            sp.add_argument("--reason", required=True)
    sp = sub.add_parser("verify", help="G3 checks on any folder of release files")
    sp.add_argument("folder")
    sp = sub.add_parser("rollback", help="re-sign and publish the previous release with a higher serial")
    sp.add_argument("--to", help="the kept release to go back to (default: the previous one)")
    sp.add_argument("--test", action="store_true")
    sp.add_argument("--dry-run", action="store_true")
    sp = sub.add_parser("cleanup", help="keep the current and the previous release; remove the rest")
    sp.add_argument("--dry-run", action="store_true")
    sub.add_parser("stats", help="per-step times and failures across runs")
    sub.add_parser("runs", help="every run kept")
    return p


def main(argv=None):
    p = parser()
    try:
        a = p.parse_args(argv)
    except SystemExit as e:
        return EXIT_USAGE if e.code else 0
    try:
        app = App(a)
        fn = getattr(app, "cmd_" + a.cmd.replace("-", "_"))
        return fn(a) or 0
    except ConfigError as e:
        if a.json:
            print(json.dumps({"exit": EXIT_USAGE, "result": "usage", "message": str(e)}))
        else:
            print(f"tools/rel: {e}", file=sys.stderr)
        return EXIT_USAGE
    except (FileNotFoundError, KeyError) as e:
        msg = f"not found: {e}"
        if a.json:
            print(json.dumps({"exit": EXIT_USAGE, "result": "usage", "message": msg}))
        else:
            print(f"tools/rel: {msg}", file=sys.stderr)
        return EXIT_USAGE
