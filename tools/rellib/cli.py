# SPDX-License-Identifier: Apache-2.0
"""tools/rel: the release runner's command line (docs/RELEASING.md).

Every command takes --json (one JSON object on stdout) and ends with a stable exit code:
0 ok · 10 waiting (a gate or a hand-off) · 20 a step failed · 30 preflight failed ·
40 a gate said no (held, or could not be asked: fail closed) · 64 usage or a scope that makes no
sense · 75 another tools/rel is working on that run.

The run's Telegram release (relmsg) ends exactly once: publish done -> ok, preflight failed (30) ->
failed, tools/rel stopped by SIGTERM/SIGINT/SIGHUP while driving, or a new run of the same version
-> aborted. 10, 20, 40, 64 and 75 are not an end: the same run goes on (retry, resume, gate)."""
import pathlib
import argparse
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile

from . import failures as known, flow, guards, hosted, retention, slow
from .config import (ConfigError, PLATFORMS, Pipeline, VERSION_RE, load_hosts, load_scope, previous_of, scope_summary,
                     scope_toml, validate_scope)
from .engine import (EXIT_BUSY, EXIT_DENIED, EXIT_FAILED, EXIT_OK, EXIT_PREFLIGHT, EXIT_USAGE, EXIT_WAITING, Engine, STALE_BYTES, relmsg_state)
from .graph import build_graph, dependents
from .relmsg import Relmsg
from .run import Busy, Run, now_iso, read_json, write_json

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


# A follow-up run (--follow-up) skips these: the same commit's screens were checked and published
# by the run it follows.
FOLLOW_UP_SKIP = ("screens", "screens-publish")
# The base run's files a follow-up does not carry: it writes its own.
CARRY_NOT = ("SHA256SUMS", "SHA256SUMS.sig", "provenance.json", "sbom.cdx.json")


def context(version, commit, run_path, run_id, src, scope, hosts, previous, build_id=None):
    return {
        "rel": RUNNER,
        "version": version, "commit": commit, "short": commit[:7], "run_id": run_id, "run": run_path,
        "build_id": build_id or commit[:7],
        "files": f"{run_path}/files", "extra": f"{run_path}/extra", "manifests": f"{run_path}/manifests",
        "src": src, "target": scope["publish"]["target"], "scratch": f"{run_path}/scratch/target",
        "notes_file": f"{run_path}/notes.txt",
        "previous_dir": previous.get("dir", ""), "previous_version": previous.get("version", ""),
        "previous_ref": previous.get("ref", ""),
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


class Interrupted(BaseException):
    """SIGTERM, SIGINT or SIGHUP reached tools/rel: unwinds through the driver's cleanup."""

    def __init__(self, signum):
        super().__init__(signum)
        self.signum = signum


def _raise_interrupted(signum, frame):
    raise Interrupted(signum)


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
                      failures=self.failures, runner=RUNNER)

    def load_run(self, ref=None):
        return Run.find(self.state_root, ref or getattr(self.args, "run", None))

    # ---- scope and plan ----

    def resolve(self, a):
        commit = a.commit or subprocess.run(["git", "-C", self.repo, "rev-parse", "HEAD"], capture_output=True,
                                            text=True, check=True).stdout.strip()
        commit = subprocess.run(["git", "-C", self.repo, "rev-parse", "--verify", f"{commit}^{{commit}}"],
                                capture_output=True, text=True).stdout.strip() or commit
        if not a.version and a.cmd != "doctor":
            raise ConfigError("a version, e.g. tools/rel start 26.11.5")
        scope = load_scope(a.scope, a.version, a.only, a.skip_platform, a.no_variant, a.set, a.skip, a.test)
        if a.previous:
            scope["previous"]["dir"] = a.previous
        if getattr(a, "builds", "local") == "hosted":
            scope["builds"] = {"hosted": True}  # local runs carry no [builds]: their plan is as before
            if getattr(a, "local_build", None):
                scope["builds"]["local"] = a.local_build
            if getattr(a, "local_fallback", False):
                scope["builds"]["fallback"] = "local"
        elif getattr(a, "local_build", None) or getattr(a, "local_fallback", False):
            raise ConfigError("--local-build and --local-fallback go with --builds hosted")
        vac = version_at(self.repo, commit)
        prev = {}
        pubs = retention.published(self.state_root)
        base = self.follow_up_base(scope, commit) if getattr(a, "follow_up", False) else None
        if base:
            if a.previous:
                raise ConfigError("--follow-up takes the previous release of the run it follows: no --previous")
            # The release it adds to keeps its previous release: the version check, the manifests and the
            # rollback backup are as they were for that run.
            prev = base["previous"]
            for name in FOLLOW_UP_SKIP:
                if name in self.pipeline.steps and name not in scope["skip"]:
                    scope["skip"][name] = (f"follow-up of {base['run_id']}: the same commit, its screens were "
                                           "rendered and published there")
        elif previous_of(scope)["dir"]:
            given = previous_of(scope)
            d = os.path.expanduser(given["dir"])
            name = os.path.basename(d.rstrip("/"))
            m = re.match(r"\d{2}\.\d{1,2}\.\d+", name)
            prev = {"dir": d, "version": given["version"] or (m.group(0) if m else name),
                    "ref": given["ref"] or f"v{name}"}
        elif pubs:
            p = pubs[-1]
            prev = {"dir": os.path.join(p["run"], "files"), "version": p["version"], "ref": p.get("tag", "")}
        else:
            # Releases published by hand (26.10.23, 26.10.24-r2) are the previous release too.
            by_hand = [p for p in retention.published_by_hand(self.state_root)
                       if p["version"] != scope["version"] and os.path.isdir(os.path.expanduser(p.get("dir", "")))]
            if by_hand:
                p = by_hand[-1]
                d = os.path.expanduser(p["dir"])
                prev = {"dir": d, "version": p["version"], "ref": p.get("tag", f"v{p['version']}")}
        warns = validate_scope(scope, self.pipeline, vac, prev.get("version"),
                               carried=base["platforms"] if base else None)
        if base:
            warns.append(f"follow-up of {base['run_id']} ({base['tag'] or 'v' + scope['version']}): carries its "
                         f"{', '.join(base['platforms'])} files unchanged; the update manifests, SHA256SUMS, the "
                         "releases page, the server and the GitHub release then list them with this run's")
            a._follow_up = base
        return commit, scope, prev, warns

    def follow_up_base(self, scope, commit):
        """--follow-up: the published run of this version that a run adds platforms to (e.g. macOS
        once its dmgs are in). Same version and commit, none of its platforms again. The new run
        carries that run's files, so its manifests, SHA256SUMS, page and GitHub release are whole."""
        v = scope["version"]
        if scope["test"] or scope["publish"]["target"] != "live":
            raise ConfigError("--follow-up adds platforms to a published release: not in a TEST or scratch run")
        pubs = [p for p in retention.published(self.state_root)
                if p["version"] == v and p.get("kind", "release") == "release" and os.path.isdir(p["run"])]
        if not pubs:
            raise ConfigError(f"--follow-up: {v} has no published run in {self.state_root}/published.json")
        p = pubs[-1]
        info = read_json(os.path.join(p["run"], "run.json"), {})
        errs = []
        if not info.get("published"):
            errs.append(f"{p['run_id']} is not marked published in its run.json")
        if info.get("commit") != commit:
            errs.append(f"{p['run_id']} released {str(info.get('commit'))[:12]}, not {commit[:12]}: "
                        "a follow-up ships the same commit (another commit is a new version)")
        plats = [x for x in PLATFORMS if info.get("scope", {}).get("platforms", {}).get(x)
                 or x in (info.get("follow_up") or {}).get("platforms", [])]
        again = [x for x in PLATFORMS if scope["platforms"].get(x) and x in plats]
        if again:
            errs.append(f"{', '.join(again)} already shipped in {p['run_id']}: a follow-up adds only the other "
                        "platforms (--only)")
        if info.get("scope", {}).get("variants") != scope["variants"]:
            errs.append(f"the variants differ from {p['run_id']}'s")
        sums = os.path.join(p["run"], "files", "SHA256SUMS")
        if not os.path.isfile(sums):
            errs.append(f"{sums} is missing")
        if errs:
            raise ConfigError("--follow-up:\n  - " + "\n  - ".join(errs))
        return {"run": p["run"], "run_id": p["run_id"], "tag": p.get("tag", ""), "platforms": plats,
                "previous": info.get("previous") or {}}

    def carry(self, base):
        """The base run's release files (SHA256SUMS order) and extras, checked against its
        SHA256SUMS: -> ({name: {sha256, bytes}}, {extra path: {sha256, bytes}}). Raises on a mismatch."""
        from .engine import sha256_file
        files = os.path.join(base["run"], "files")
        out, extra = {}, {}
        for line in open(os.path.join(files, "SHA256SUMS"), encoding="utf-8"):
            sha, name = line.rstrip("\n").split("  ", 1)
            if name in CARRY_NOT:
                continue  # this run writes its own
            path = os.path.join(files, name)
            if os.path.islink(path) or not os.path.isfile(path) or sha256_file(path) != sha:
                raise ConfigError(f"--follow-up: {path} does not match {base['run_id']}'s SHA256SUMS")
            out[name] = {"sha256": sha, "bytes": os.path.getsize(path)}
        edir = os.path.join(base["run"], "extra")
        for d, _, names in os.walk(edir):
            for n in names:
                path = os.path.join(d, n)
                if not os.path.islink(path):
                    extra[os.path.relpath(path, edir)] = {"sha256": sha256_file(path), "bytes": os.path.getsize(path)}
        return out, extra

    def build_id(self, commit):
        """WFE_BUILD_ID: the published short commit when the commit is published, else the local one."""
        return hosted.build_id_for(commit, hosted.conf(self.pipeline)["commit_map"])

    def cmd_plan(self, a):
        commit, scope, prev, warns = self.resolve(a)
        path, run_id = Run.next_path(self.state_root, scope["version"])
        src = a.src or os.path.join(self.hosts["path"].get("worktrees", os.path.expanduser("~/wfe-worktrees")),
                                    f"rel-{scope['version']}-{commit[:7]}")
        steps = build_graph(self.pipeline, scope, context(scope["version"], commit, path, run_id, src, scope, self.hosts, prev,
                                                          self.build_id(commit)))
        if a.json:
            return self.out(0, "plan", steps=[s.to_dict() for s in steps], scope=scope, warnings=warns,
                            summary=scope_summary(scope))
        print(f"{'TEST ' if scope['test'] else ''}release {scope['version']} at {commit[:12]}")
        print(f"scope: {scope_summary(scope)}")
        for w in warns:
            print(f"warning: {w}")
        if prev:
            print(f"previous release: {prev['version']} at {prev['dir']}")
        for s in steps:
            skip = scope["skip"].get(s.base)
            print(f"  {'P' if s.publish else ' '} {s.id:28} {s.host:8} {s.kind:8} {s.lane:20} needs {', '.join(s.needs) or '-'}"
                  + (f"   SKIP ({skip})" if skip else ""))
            if a.verbose and s.run:
                print(f"      {s.run}")
        print("P = publish phase (tools/rel publish, after the publish gate); steps in one lane run one at a time, "
              "lanes side by side (screens renders beside the builds and holds neither the gate nor the publish)")
        return EXIT_OK

    # ---- start / resume / publish ----

    def run_refusal(self, info):
        return guards.never_ship_refusal(info, self.repo)

    def cmd_start(self, a):
        commit, scope, prev, warns = self.resolve(a)
        why = self.run_refusal({"commit": commit, "test": scope["test"]})
        if why:
            return self.out(EXIT_DENIED, why)
        version = scope["version"]
        path, run_id = Run.next_path(self.state_root, version)
        wt = self.hosts["path"].get("worktrees", os.path.expanduser("~/wfe-worktrees"))
        src = os.path.abspath(a.src) if a.src else os.path.join(wt, f"rel-{version}-{commit[:7]}")
        steps = build_graph(self.pipeline, scope, context(version, commit, path, run_id, src, scope, self.hosts, prev,
                                                          self.build_id(commit)))
        g2 = next((s for s in steps if s.base == "source-check"), None)
        if g2 and not a.dry_run and g2.base not in scope["skip"]:
            # Cheapest first: a candidate whose content passed the whole suite (full and full-notor:
            # an earlier run, a `tools/check.sh --full` on that commit) reuses it; any
            # other runs G2 here first. Nothing builds or dispatches before G2 passes.
            found, key = self.green_source(commit, version, g2)
            if found:
                self.echo(f"G2: green full check on this content: {found['label']} ({found['commit'][:12]})")
            else:
                self.echo(f"G2: no green full check for {commit[:12]} (key {key}): tools/check.sh --full runs "
                          "first in this run; no build or hosted dispatch before it passes")
        conc = {"max_heavy": a.max_heavy} if a.max_heavy is not None else {}
        info = {"version": version, "commit": commit, "scope": scope, "test": scope["test"], "dry": bool(a.dry_run),
                "target": scope["publish"]["target"], "src": src, "src_made": not a.src, "warnings": warns,
                "previous": prev, "kind": "release", "no_relmsg": bool(a.no_relmsg), "argv": sys.argv[1:]}
        if conc:
            info["concurrency"] = conc
        if a.sign_inline:
            info["sign_requested"] = "at start (--sign-inline)"
        if a.apple_results:
            d = os.path.abspath(os.path.expanduser(a.apple_results))
            if not os.path.isdir(d):
                return self.out(EXIT_USAGE, f"--apple-results {d}: no such folder")
            if not any(s.kind == "handoff" for s in steps):
                return self.out(EXIT_USAGE, "--apple-results: no Apple hand-off step in this scope")
            info["handoff_from"] = d
        base = getattr(a, "_follow_up", None)
        if base:
            try:
                carried, carried_extra = self.carry(base)
            except ConfigError as e:
                return self.out(EXIT_USAGE, str(e))
            info["follow_up"] = {"run": base["run"], "run_id": base["run_id"], "tag": base["tag"],
                                 "platforms": base["platforms"]}
            info["carried"] = {n: {**m, "from": base["run_id"]} for n, m in carried.items()}
            info["carried_extra"] = {n: {**m, "from": base["run_id"]} for n, m in carried_extra.items()}
        os.makedirs(self.state_root, exist_ok=True)
        run = Run.create(self.state_root, version, info, scope_toml(scope), steps)
        if base:
            from .engine import sha256_file
            for sub, items, dest in (("files", info["carried"], run.files), ("extra", info["carried_extra"], run.extra)):
                for name, m in items.items():
                    to = os.path.join(dest, name)
                    os.makedirs(os.path.dirname(to), exist_ok=True)
                    shutil.copy2(os.path.join(base["run"], sub, name), to)
                    if sha256_file(to) != m["sha256"]:
                        return self.out(EXIT_FAILED, f"{to}: the copy differs from {base['run_id']}'s", run)
            self.echo(f"follow-up of {base['run_id']}: carried {len(info['carried'])} files and "
                      f"{len(info['carried_extra'])} extras (sha256 checked)")
        with open(os.path.join(run.path, "notes.txt"), "w", encoding="utf-8") as f:
            f.write(scope["publish"].get("notes", ""))
        for s in run.steps:
            if s.base in scope["skip"]:
                run.set_status(s.id, status="skipped", reason=f"release.toml [skip]: {scope['skip'][s.base]}")
        self.echo(f"run {run.info['run_id']} in {run.path}")
        self.echo(f"scope: {scope_summary(scope)}")
        for w in warns:
            self.echo(f"warning: {w}")
        eng = self.engine(run, dry=bool(a.dry_run))
        for s in run.steps:
            st = run.status(s.id)
            if st["status"] == "skipped":
                run.event(s.id, "skipped", reason=st["reason"])
                eng.record_skip(s, st["reason"])
        if eng.relmsg:
            self.supersede(run)
        self.relmsg_start(run, eng)
        return self.drive(run, eng, phase="build", until=a.until, stop_on_fail=a.stop_on_fail)

    def concurrency_overrides(self, run, a):
        """--max-heavy N: kept in run.json, so a resume keeps it."""
        over = dict(run.info.get("concurrency") or {})
        if getattr(a, "max_heavy", None):
            over["max_heavy"] = a.max_heavy
        if over != (run.info.get("concurrency") or {}):
            run.info["concurrency"] = over
            run.save_info()

    def drive(self, run, eng, phase, until=None, retry_failed=False, stop_on_fail=False):
        why = self.run_refusal(run.info)
        if why:
            return self.out(EXIT_DENIED, why, run)
        if phase == "publish" and not eng.dry:
            # Only the bytes the gate approved are published (tools/rellib/evidence.py).
            from . import evidence
            why = evidence.publish_refusal(run)
            if why:
                return self.out(EXIT_DENIED, why, run)
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
            with run.short("admit"):
                elsewhere = {s.id for s in run.elsewhere()}
            for sid in sel:
                if sid in elsewhere:
                    continue  # another tools/rel runs it on its lane; the drive picks up what follows
                st = run.status(sid)
                s = run.step(sid)
                if st["status"] == "failed" and retry_failed:
                    run.set_status(sid, retry=True)
                why = eng.stale_why(s, st)
                if why:
                    run.set_status(sid, status="pending", note=why)
                if why == STALE_BYTES:
                    run.event(sid, "invalidated", reason="build inputs changed")
                    if s.kind == "gate":
                        gname = "rollback" if s.base == "rollback-gate" else "publish"
                        run.info.get("gates", {}).pop(gname, None)  # a new approval for the new bytes
                        run.save_info()
                if st["status"] == "running":
                    run.set_status(sid, status="pending", note="was running when tools/rel stopped")
            # A failed build-phase step stops only what needs it (--stop-on-fail: everything);
            # publishing always stops.
            code = eng.drive(sel, stop_on_fail=stop_on_fail or phase != "build")
        except Interrupted as e:
            # Stopped or killed: this run is over (a new run, not this one, is what comes next).
            if eng.relmsg:
                eng.relmsg.done("aborted", note=f"tools/rel stopped by {signal.Signals(e.signum).name}")
            raise
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
        if code == EXIT_PREFLIGHT and eng.relmsg:
            # Nothing was built: the run is dead. (Waiting, a failed step and a closed gate are not
            # an end: retry, resume and the gate carry the same run on; publish ends it.)
            eng.relmsg.done("failed", note=msg[:500])
        return self.out(code, msg, run)

    def supersede(self, new_run):
        """A new run of a version replaces the older runs of it: their live messages end aborted."""
        pubs = {p["run_id"] for p in retention.published(self.state_root)}
        for version, run_id, path, _ in Run.all(self.state_root):
            if version != new_run.info["version"] or run_id == new_run.info["run_id"] or run_id in pubs:
                continue
            old = Run(path)
            if old.info.get("dry") or old.info.get("no_relmsg"):
                continue
            Relmsg(old, self.pipeline.relmsg).done("aborted", note=f"superseded by {new_run.info['run_id']}")
            if (old.info.get("relmsg") or {}).get("ended") == "aborted":
                old.info["relmsg"]["superseded_by"] = new_run.info["run_id"]  # a resume does not reopen it
                old.save_info()

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
                eng.relmsg.step(s.id, relmsg_state(st), note=st.get("note") or st.get("reason"), label=s.title)

    def green_source(self, commit, version, step):
        """(source, key): where the G2 result for this content key already is (an earlier run, a
        green record of `tools/check.sh --full`), or (None, key)."""
        from . import reuse
        spec = self.pipeline.steps.get(step.base) or {}
        if not spec.get("reuse"):
            return None, "-"
        k, _, src = reuse.find_source(self.repo, self.state_root, {"commit": commit, "version": version}, step,
                                      spec["reuse"], reuse.green_dir(spec))
        return src, k

    def cmd_sign(self, a):
        """sign-android asks the signer now (or as soon as every build is in), and the run carries on
        from there. With the signer's credential on this machine (signer.auto_approve) the step signs
        on its own and this only starts it; without it the owner is ready for his code ([sign] when =
        "on-demand" in pipeline.toml)."""
        run = self.load_run()
        ss = [s for s in run.steps if s.base == "sign-android"]
        if not ss:
            return self.out(EXIT_USAGE, "this run has no sign-android step (no Android in scope)", run)
        st = run.status(ss[0].id)
        if st["status"] == "done":
            return self.out(EXIT_OK, f"{ss[0].id} is done: {st.get('note') or ''}", run)
        run.info["sign_requested"] = now_iso()
        run.save_info()
        run.event(ss[0].id, "sign-requested")
        if st["status"] in ("failed", "waiting"):
            run.set_status(ss[0].id, status="pending", retry=False, polled=None)
        self.concurrency_overrides(run, a)
        eng = self.engine(run)
        if eng.relmsg:
            eng.relmsg.reopen()
        self.relmsg_start(run, eng)
        return self.drive(run, eng, phase="build", stop_on_fail=a.stop_on_fail)

    def cmd_resume(self, a):
        run = self.load_run()
        if a.relmsg and run.info.get("no_relmsg"):
            run.info["no_relmsg"] = False
            run.save_info()
        self.concurrency_overrides(run, a)
        eng = self.engine(run)
        if eng.relmsg:
            eng.relmsg.reopen()
        self.relmsg_start(run, eng)
        return self.drive(run, eng, phase="publish" if a.publish else "build", until=a.until, retry_failed=True,
                          stop_on_fail=a.stop_on_fail)

    def cmd_run(self, a, run=None):
        """One step, and nothing after it. Several steps run side by side across their lanes. It holds
        their lanes, not the run: another lane's retry runs beside it (a publish step holds the run). A
        need among them is waited for, a need outside them must be met and still hold (or
        --ignore-needs): a done need whose inputs changed counts as not met. A failed step stops
        only the steps that need it (--stop-on-fail: all of them); a publish step always stops."""
        run = run or self.load_run()
        sel = [run.step(x) for x in [a.step, *(getattr(a, "more", None) or [])]]
        ids = [s.id for s in sel]
        eng = self.engine(run, dry=bool(a.dry_run))
        unmet_of = {}
        for s in sel:
            st = run.status(s.id)
            if s.publish and st["status"] == "done" and not a.again:
                return self.out(EXIT_USAGE, f"{s.id} is a publish step and already done: --again to run it again", run)
            if s.publish and not run.info.get("dry"):
                gate = [x for x in run.steps if x.kind == "gate"]
                if gate and run.status(gate[0].id)["status"] != "done":
                    return self.out(EXIT_DENIED, f"{s.id} publishes: the gate {gate[0].id} has not approved this run", run)
            unmet = [n for n in s.needs if n not in ids and run.status(n)["status"] not in ("done", "skipped")]
            why = [f"{n} is {run.status(n)['status']}" for n in unmet]
            for n, stale in self.stale_needs(run, eng, s, ids):
                unmet.append(n)
                why.append(f"{n} is stale: {stale}")
            if unmet and not a.ignore_needs:
                return self.out(EXIT_USAGE, f"{s.id} needs {', '.join(unmet)} first ({'; '.join(why)}; or --ignore-needs: "
                                            "the run is then tainted and can never be published)", run)
            if unmet and s.publish:
                return self.out(EXIT_USAGE, "a publish step never runs with --ignore-needs", run)
            unmet_of[s.id] = unmet
        whole = any(s.publish for s in sel)
        try:
            if whole:
                run.lock()
            run.claim_lanes(sel)
        except Busy as e:
            run.unlock()
            return self.out(EXIT_BUSY, str(e), run)
        for s in sel:
            if unmet_of[s.id]:
                run.taint(f"{s.id} run with unmet needs: {', '.join(unmet_of[s.id])}")
        try:
            saved = {s.id: s.needs for s in sel}
            for s in sel:
                run.set_status(s.id, status="pending", retry=False)
                s.needs = [n for n in s.needs if n not in unmet_of[s.id]]
            code = eng.drive(ids, stop_on_fail=getattr(a, "stop_on_fail", False) or any(s.publish for s in sel))
            for s in sel:
                s.needs = saved[s.id]
        finally:
            run.release_lanes(sel)
            run.unlock()
        return self.finish(run, eng, code)

    @staticmethod
    def stale_needs(run, eng, step, ids):
        """-> [(id, why)] of the done steps step rests on, outside ids, whose result no longer holds."""
        out, seen, frontier = [], set(ids), list(step.needs)
        while frontier:
            sid = frontier.pop()
            if sid in seen:
                continue
            seen.add(sid)
            s = run.step(sid)
            why = eng.stale_why(s, run.status(sid))
            if why:
                out.append((sid, why))
            frontier.extend(s.needs)
        return sorted(out)

    DOING = ("fixing", "rerun-queued", "rerunning", "accepted", "waits", "none")

    @staticmethod
    def doing(run, sid, state, note, commit=None, by="rel"):
        """What is being done about a step that failed, for the panel: status.json's `doing`, state "none"
        when nothing is. The journal keeps each change (event "doing")."""
        mark = {"state": state, "note": note, "commit": commit, "at": now_iso(), "by": by}
        run.set_status(sid, doing=mark)
        run.event(sid, "doing", state=state, note=note, commit=commit, by=by)
        return mark

    def after_rerun(self, run, sid, what):
        """A rerun's end: a pass needs nothing more; a failure is open until someone takes it up."""
        st = run.status(sid)
        if st["status"] == "done" and not st.get("warned"):
            self.doing(run, sid, "none", f"{what} passed")
        else:
            self.doing(run, sid, "none", f"{what} ended {st['status']}{' (warned)' if st.get('warned') else ''}")

    def cmd_doing(self, a):
        """Says what is being done about a failed step: fixing (with the commit), rerun-queued, accepted
        for the gate (with the reason), or none. Retry sets it itself."""
        run = self.load_run()
        s = run.step(a.step)
        state = a.state
        if state in ("fixing", "accepted", "rerun-queued", "waits") and not (a.note or "").strip():
            return self.out(EXIT_USAGE, f"{state} needs --note: what is fixed, why it is accepted, or what waits", run)
        mark = self.doing(run, s.id, state, (a.note or "").strip() or None, a.commit, by="lead")
        return self.out(EXIT_OK, f"{s.id}: {mark['state']}{': ' + mark['note'] if mark['note'] else ''}", run)

    def cmd_retry(self, a):
        run = self.load_run()
        s = run.step(a.step)
        st = run.status(s.id)
        if st["status"] not in ("failed", "waiting", "held", "closed") and not a.again:
            return self.out(EXIT_USAGE, f"{s.id} is {st['status']}; retry is for a failed step (--again to re-run a done one)", run)
        if s.publish and st["status"] == "done" and not a.again:
            return self.out(EXIT_USAGE, f"{s.id} publishes and is done: --again to run it again", run)
        try:
            run.claim_lanes([s])
        except Busy as e:
            return self.out(EXIT_BUSY, str(e), run)
        try:
            run.set_status(s.id, status="pending", retry=False)
            run.event(s.id, "retry-requested")
            a.ignore_needs, a.dry_run = False, False
            a.step = s.id
            n = st.get("attempts", 0) + 1
            self.doing(run, s.id, "rerunning", f"attempt {n}")
            try:
                return self.cmd_run(a, run)
            finally:
                self.after_rerun(run, s.id, f"rerun attempt {n}")
        finally:
            run.release_lanes([s])

    def cmd_skip(self, a):
        run = self.load_run()
        s = run.step(a.step)
        spec = self.pipeline.steps.get(s.base, {})
        if not spec.get("skippable"):
            return self.out(EXIT_USAGE, f"{s.id} cannot be skipped (builds and gates never are; drop a platform in "
                                        "release.toml and start a new run)", run)
        if not a.reason.strip():
            return self.out(EXIT_USAGE, "--reason is required", run)
        run.set_status(s.id, status="skipped", reason=a.reason)
        run.event(s.id, "skipped", reason=a.reason)
        eng = self.engine(run)
        eng.record_skip(s, a.reason)
        if eng.relmsg:
            eng.relmsg.step(s.id, "skipped", note=a.reason)
        return self.out(EXIT_OK, f"{s.id} skipped: {a.reason}", run)

    def cmd_add_step(self, a):
        """Steps of the current pipeline put into a run planned before they existed: plan.json keeps
        what the run was planned with, so a new step would never show. Nothing runs."""
        run = self.load_run()
        i = run.info
        scope = load_scope(os.path.join(run.path, "release.toml"))
        ctx = context(i["version"], i["commit"], run.path, i["run_id"], i["src"], scope, self.hosts, i.get("previous"))
        known = {s.id: s for s in build_graph(self.pipeline, scope, ctx)}
        have = {s.id for s in run.steps}
        new = [x for x in a.step if x not in have]
        for x in new:
            if x not in known:
                return self.out(EXIT_USAGE, f"{x}: no such step in this run's scope", run)
            if any(n not in have for n in known[x].needs):
                return self.out(EXIT_USAGE, f"{x} needs a step this run does not have", run)
        with run.short("info"):
            run.steps.extend(known[x] for x in new)
            write_json(os.path.join(run.path, "plan.json"), [s.to_dict() for s in run.steps])
        for x in new:
            run.event(x, "step-added", by="add-step")
        return self.out(EXIT_OK, f"added: {', '.join(new) or 'nothing, all were there'}", run)

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
            st = eng.execute_alone(g)
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
                warned = [s.id for s in run.steps if run.status(s.id).get("warned")]
                eng.relmsg.done("ok", note=f"{run.info['version']} published ({run.info['target']})"
                                + (f"; not blocking, failed: {', '.join(warned)}" if warned else ""))
        return code

    def cmd_gate_watch(self, a):
        """The gate watcher (tools/rellib/gatewatch.py): --foreground runs it here; without, it is
        started detached, as the gate does when it waits."""
        from . import gatewatch
        run = self.load_run()
        if run.info.get("dry"):
            return self.out(EXIT_USAGE, "a dry run has no gate to watch", run)
        if a.foreground:
            w = gatewatch.Watcher(run, self.pipeline, gatewatch.rel_caller(run, self.pipeline, self.args.hosts),
                                  every=a.every)
            code, msg = w.loop()
            return self.out(code, msg, run)
        ok, msg = gatewatch.start(run, self.pipeline, self.args.hosts, "gate-watch", every=a.every)
        return self.out(EXIT_OK if ok else EXIT_USAGE, msg or "not started: REL_GATEWATCH is set", run,
                        watch=gatewatch.watch_of(run))

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
        from . import gatewatch
        w = gatewatch.watch_of(run)
        if w:
            print(f"gate watcher running: {w.get('unit') or 'pid ' + str(w.get('pid'))}, log {gatewatch.log_path(run)}")
        for r in rows:
            d = f"{r['duration_s']:.0f}s" if r.get("duration_s") is not None else ""
            extra = (r.get("note") or r.get("reason") or "").strip()
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
            full = eng.spawn_env(info["env"])
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
                                                      "test": scope["test"], "src": self.repo, "previous": prev,
                                                      "state_root": self.state_root}, "", [])
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

    def server(self, a):
        from .server import Server
        return Server(self.repo, self.hosts, root=getattr(a, "test_root", None), say=self.echo)

    def work_dir(self, kind):
        return os.path.join(self.state_root, kind, time.strftime("%Y%m%dT%H%M%SZ", time.gmtime()))

    def cmd_rollback(self, a):
        return self.flip(a, "rollback")

    def cmd_rollforward(self, a):
        return self.flip(a, "rollforward")

    def flip(self, a, direction):
        """The website serves the previous (rollback) or the newer (rollforward) release: one ssh
        call, then GitHub, the Pages mirror and the read-back, each timed (instant.py)."""
        from .instant import Flip, FlipError, PARTS
        from .server import ServerError
        parts = tuple(x for x in (a.parts.split(",") if a.parts else PARTS) if x)
        bad = [x for x in parts if x not in PARTS]
        if bad:
            return self.out(EXIT_USAGE, f"--parts: {', '.join(bad)} is not one of {', '.join(PARTS)}")
        f = Flip(self.repo, self.server(a), self.work_dir(direction), say=self.echo, github_repo=a.github_repo)
        try:
            res = f.run(direction, to=a.to, dry=a.dry_run, parts=parts)
        except (FlipError, ServerError) as e:
            return self.out(EXIT_FAILED, f"{direction} refused: {e}")
        if res.get("dry"):
            return self.out(EXIT_OK if res["ok"] else EXIT_FAILED, f"dry run: {direction} {res['live']} -> {res['target']} would change the website, GitHub and the mirrors as above; nothing was changed", **res)
        failed = res.get("failed", [])
        word = "rolled back" if direction == "rollback" else "rolled forward"
        if not res["ok"]:
            return self.out(EXIT_FAILED, f"{word} {res['live']} -> {res['target']}: the website {'is switched' if 'site' in res['parts'] else 'was not touched'}, "
                                         f"but {', '.join(failed)} failed (above); repeat the failed part with --parts {','.join(failed)}", **res)
        note = f" (warning: {', '.join(failed)} failed)" if failed else ""
        return self.out(EXIT_OK, f"{word} {res['live']} -> {res['target']} in {res['total']:.0f} s{note}", **res)

    def cmd_presign(self, a):
        from .presign import Presign
        from .resign import ResignError
        from .server import ServerError
        p = Presign(self.repo, self.state_root, self.pipeline, self.hosts, self.server(a), say=self.echo, test=bool(a.test_root))
        try:
            res = p.refresh(self.work_dir("presign"), dry=a.dry_run, github=not a.no_github, other=a.other)
        except (ResignError, ServerError) as e:
            return self.out(EXIT_FAILED, f"presign refused: {e}")
        return self.out(EXIT_OK, f"{'would pre-sign' if a.dry_run else 'pre-signed'}: {res}", **res)

    def cmd_publish_one(self, a):
        """One built file onto the live release, signed the way the release signs it (pubone.py)."""
        from .pubone import BAR_SECONDS as BAR_SECONDS_ONE, PublishOne, PublishOneError
        from .resign import ResignError
        from .server import ServerError
        po = PublishOne(self.repo, self.state_root, self.pipeline, self.hosts, self.server(a), say=self.echo, test=bool(a.test_root),
                        apple_results=a.apple_results, github_repo=a.github_repo, data_path=a.data, no_github=a.no_github)
        try:
            res = po.run(a.platform, a.variant, os.path.abspath(a.file), version=a.version, dry=a.dry_run)
        except (PublishOneError, ResignError, ServerError) as e:
            return self.out(EXIT_FAILED, f"publish-one refused: {e}")
        if res.get("dry"):
            return self.out(EXIT_OK, "dry run: nothing was signed, uploaded or changed", **res)
        warns = res.get("warnings", [])
        if not res["ok"]:
            return self.out(EXIT_FAILED, "published, but a read-back check failed (above)", **res)
        late = f" (over the {BAR_SECONDS_ONE} s bar)" if res["total"] > BAR_SECONDS_ONE else ""
        return self.out(EXIT_OK, f"published {res['name']} in {res['total']:.0f} s{late}" + (f"; {len(warns)} warning(s) above" if warns else ""), **res)

    def cmd_migrate_layout(self, a):
        from .server import ServerError
        srv = self.server(a)
        live = a.version
        try:
            if not live:
                from .server import payload
                live = payload(srv.fetch("update-v2.json"))["versionName"]
            self.echo(f"live release: {live}")
            if not srv.test:
                deploy = os.path.join(os.path.expanduser(self.hosts["path"]["page_repo"]), "deploy-epic-cash.sh")
                text = open(deploy, encoding="utf-8").read()
                if "--exclude /versions" not in text:
                    self.echo(f"{deploy}: needs '--exclude /versions --exclude /current' on its rsync --delete line"
                              + (" (would be added)" if a.dry_run else " (adding; a copy stays as deploy-epic-cash.sh.pre-layout)"))
                    if not a.dry_run:
                        import shutil
                        shutil.copyfile(deploy, deploy + ".pre-layout")
                        new = text.replace("--exclude downloads ", "--exclude downloads --exclude /versions --exclude /current ", 1)
                        if new == text:
                            return self.out(EXIT_FAILED, f"{deploy}: its rsync line is not the one expected; add the two excludes by hand")
                        open(deploy, "w", encoding="utf-8").write(new)
            out = srv.relsrv("migrate", live, *(["--dry"] if a.dry_run else []))
            for l in out.splitlines():
                self.echo(l)
            if not a.dry_run:
                st = srv.state()
                got = srv.fetch("download", "SHA256SUMS") == srv.read_remote(os.path.join(srv.R, "versions", live, "downloads", "SHA256SUMS"))
                self.echo(f"served SHA256SUMS is versions/{live}'s: {'yes' if got else 'NO'}; live {st['live']}, downloads is a link: {st['downloads_is_link']}")
                if not got:
                    return self.out(EXIT_FAILED, "migrated, but the served downloads do not read back")
        except ServerError as e:
            return self.out(EXIT_FAILED, f"migrate-layout refused: {e}")
        return self.out(EXIT_OK, "dry run: nothing changed" if a.dry_run else f"version folders in place: current -> versions/{live}")

    def cmd_resign(self, a):
        from .resign import Resign, ResignError
        if a.live_dir and not a.test:
            return self.out(EXIT_USAGE, "--live-dir is for --test only: a real re-sign reads and publishes the live files")
        srv = None
        if a.test_root:
            srv = self.server(a)
        elif not a.test:
            try:  # version folders on the server? (a server that is not reachable counts as none)
                s0 = self.server(a)
                if s0.state().get("live"):
                    srv = s0
            except Exception:
                srv = None
        if a.test and not a.live_dir and not srv:
            return self.out(EXIT_USAGE, "--test needs --live-dir (a folder with update.json and update-v2.json) or --test-root")
        r = Resign(self.repo, self.state_root, self.pipeline, self.hosts, say=self.echo, test=a.test, live_dir=a.live_dir, server=srv)
        try:
            res = r.run(dry=a.dry_run)
            if srv and not a.dry_run:
                from .presign import Presign
                Presign(self.repo, self.state_root, self.pipeline, self.hosts, srv, say=self.echo, test=a.test).refresh(
                    os.path.join(r.work, "presign"))
        except ResignError as e:
            return self.out(EXIT_FAILED, f"resign refused: {e}")
        verb = "would re-sign" if a.dry_run else "re-signed and published"
        return self.out(EXIT_OK, f"{verb} {res['version']}: serial {res['serial']}, expires {res['expires']} "
                                 f"(record {res['work']})", **res)

    def cmd_cleanup(self, a):
        lines = []
        res = retention.apply(self.state_root, self.repo, lambda x: (lines.append(x), self.echo(x)), dry=a.dry_run)
        msg = f"{'would remove' if a.dry_run else 'removed'} {len(res['removed']) if not a.dry_run else len(lines)} run(s); kept: {', '.join(res['kept']) or 'nothing'}"
        return self.out(EXIT_OK, msg, kept=res["kept"], removed=res["removed"] if not a.dry_run else lines)

    def cmd_flow(self, a):
        if a.write:
            with open(self.pipeline.path, encoding="utf-8") as f:
                text = f.read()
            with open(self.pipeline.path, "w", encoding="utf-8") as f:
                f.write(flow.rewrite_header(text, self.pipeline))
            return self.out(EXIT_OK, f"{self.pipeline.path}: header rewritten")
        if a.json:
            print(json.dumps({"stages": flow.flow_stages(self.pipeline)}))
            return EXIT_OK
        print("\n".join(flow.flow_lines(self.pipeline)))
        return EXIT_OK

    def cmd_cut(self, a):
        """Branch release/<version> from the tip of main (or --from), plus the version commit. The app
        is frozen on that branch: main may move, an exception fix is cherry-picked and reruns G2."""
        if not VERSION_RE.fullmatch(a.version):
            return self.out(EXIT_USAGE, f"--version {a.version}: expected YY.MM.patch")
        main = os.path.expanduser(self.hosts["path"].get("main_checkout") or self.repo)
        ref = getattr(a, "from_commit", None) or "main"
        base = subprocess.run(["git", "-C", main, "rev-parse", "-q", "--verify", f"{ref}^{{commit}}"],
                              capture_output=True, text=True, check=False).stdout.strip()
        if not base:
            return self.out(EXIT_USAGE, f"{ref}: no such commit in {main}")
        branch = f"release/{a.version}"
        tip, made = flow.make_cut(main, a.version, base, self.state_root)
        start = f"tools/rel start {a.version} --commit {tip}"
        return self.out(EXIT_OK, f"{branch} at {tip[:12]}{'' if made else ' (already cut)'}\n{start}",
                        version=a.version, commit=tip, branch=branch, base=base, start=start)

    def cmd_stats(self, a):
        path = os.path.join(self.state_root, "metrics.jsonl")
        rows = []
        if os.path.isfile(path):
            for line in pathlib.Path(path).read_text().splitlines(True):
                try:
                    rows.append(json.loads(line))
                except json.JSONDecodeError:
                    pass
        rows = [r for r in rows if not r.get("dry") and r.get("base")]  # step lines (not "overlap")
        by = {}
        for r in rows:
            by.setdefault(r["base"], []).append(r)
        slows = {h["step"]: h for h in slow.slow_steps(path)}
        table = []
        for base, rs in by.items():
            done = [r["duration_s"] for r in rs if r["status"] == "done"]
            last = done[-1] if done else None
            prev5 = done[-6:-1]
            avg = sum(prev5) / len(prev5) if prev5 else None
            table.append({"step": base, "runs": len(rs), "failed": sum(1 for r in rs if r["status"] == "failed"),
                          "last_s": last, "avg_prev5_s": round(avg, 1) if avg else None,
                          "slower": bool(last and avg and last > 1.25 * avg),
                          "over_median": slows.get(base)})
        if a.json:
            return self.out(EXIT_OK, "stats", stats=table)
        print(f"{'step':24} {'runs':>5} {'failed':>6} {'last':>8} {'avg(5)':>8}")
        for t in sorted(table, key=lambda t: t["step"]):
            fmt = lambda v: f"{v:.0f}s" if v is not None else "-"
            print(f"{t['step']:24} {t['runs']:>5} {t['failed']:>6} {fmt(t['last_s']):>8} {fmt(t['avg_prev5_s']):>8}"
                  + ("  slower" if t["slower"] else ""))
        for h in slows.values():
            print(slow.slow_line(h))
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


def _local_builds(v):
    """--local-build: a comma list of hosted platforms, e.g. "linux"."""
    plats = sorted({p.strip() for p in v.split(",") if p.strip()})
    if not plats or any(p not in hosted.HOSTED_PLATFORMS for p in plats):
        raise argparse.ArgumentTypeError(f"one or more of {', '.join(hosted.HOSTED_PLATFORMS)}")
    return ",".join(plats)


def shlex_quote(s):
    import shlex
    return shlex.quote(str(s))


def tries_cell(r):
    """The report's tries column: the count, or `flaky (N tries)` for a pass after a failed attempt."""
    return f"flaky ({r['attempts']} tries)" if r.get("flaky") else str(r["attempts"])


def row_note(r):
    """The report's note column: the note (or skip reason) and the known-failure hint."""
    note = r.get("note") or r.get("reason") or ""
    if r.get("hint"):
        note += f" — hint: {r['hint']}"
    return note


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
    for g, v in info.get("gates", {}).items():
        md.append(f"- gate {g}: {v.get('state')} (id {v.get('gate_id')}" + (f", by {v.get('decided_by')} via {v.get('via')}" if v.get("decided_by") else "") + ")")
    md += ["", "| step | status | time | tries | size | note |", "|---|---|---|---|---|---|"]
    for r in rows:
        d = f"{r['duration_s']:.0f}s" if r.get("duration_s") is not None else ""
        size = f"{r['bytes'] / 1e6:.0f} MB" if r.get("bytes") else ""
        note = row_note(r).replace("|", "/")
        md.append(f"| {r['id']} | {r['status']} | {d} | {tries_cell(r)} | {size} | {note[:160]} |")
    text = "\n".join(md) + "\n"
    mdp = os.path.join(run.path, "summary.md")
    with open(mdp, "w", encoding="utf-8") as f:
        f.write(text)
    import html as h
    def cell(r):
        d = "" if r.get("duration_s") is None else f"{r['duration_s']:.0f}s"
        size = f"{r['bytes'] / 1e6:.0f} MB" if r.get("bytes") else ""
        note = row_note(r)[:200]
        return (f"<tr class='{h.escape(r['status'])}'><td>{h.escape(r['id'])}</td><td>{h.escape(r['status'])}</td>"
                f"<td>{d}</td><td>{h.escape(tries_cell(r))}</td><td>{size}</td><td>{h.escape(note)}</td></tr>")

    trs = "".join(cell(r) for r in rows)
    page = f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{h.escape(info['run_id'])}</title><style>
:root{{--bg:#111418;--fg:#e6e8eb;--mut:#9aa3ad;--ok:#3fb950;--bad:#f85149;--wait:#d29922;--line:#2a2f36}}
:root[data-theme=light]{{--bg:#fff;--fg:#1f2328;--mut:#59636e;--line:#d0d7de}}
body{{background:var(--bg);color:var(--fg);font:14px/1.45 system-ui,sans-serif;margin:0;padding:16px;max-width:1100px}}
table{{border-collapse:collapse;width:100%}}td,th{{border-bottom:1px solid var(--line);padding:4px 6px;text-align:left;vertical-align:top}}
.done td:nth-child(2){{color:var(--ok)}}.failed td:nth-child(2){{color:var(--bad)}}.waiting td:nth-child(2),.held td:nth-child(2),.warned td:nth-child(2){{color:var(--wait)}}
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
        sp.add_argument("version", nargs="?", help="YY.MM.patch (= app/pubspec.yaml)")
        sp.add_argument("--scope", help="a release.toml (default: everything on, stores off)")
        sp.add_argument("--only", help="only these platforms, e.g. android,linux")
        sp.add_argument("--skip-platform", help="drop platforms, e.g. macos,ios")
        sp.add_argument("--no-variant", help="drop a variant: tor or notor")
        sp.add_argument("--set", action="append", help="a scope key, e.g. stores.play=true, publish.notes=...")
        sp.add_argument("--skip", action="append", help="skip a skippable step: name=reason")
        sp.add_argument("--test", action="store_true", help="a TEST run: scratch target, test key, TEST in Telegram")
        sp.add_argument("--commit", help="the commit to release (default HEAD of this checkout)")
        sp.add_argument("--src", help="use this clean checkout at the commit instead of a new worktree")
        sp.add_argument("--previous", help="the previous release's folder (default: the last published run)")
        sp.add_argument("--builds", choices=("local", "hosted"), default="local",
                        help="hosted: android, linux and windows build on GitHub runners from the published commit "
                             "(release/pipeline.toml [hosted]); default local")
        sp.add_argument("--local-build", type=_local_builds,
                        help="with --builds hosted: these platforms build on this machine instead, e.g. linux")
        sp.add_argument("--follow-up", action="store_true",
                        help="add platforms to the published run of this version (same commit): the run carries "
                             "that run's files, so manifests, SHA256SUMS, page and GitHub release list them all")
        sp.add_argument("--local-fallback", action="store_true",
                        help="with --builds hosted: a hosted build that fails runs its local build instead "
                             "(no second dispatch)")

    sp = sub.add_parser("plan", help="the graph for a scope; no side effects")
    scope_args(sp)
    sp.add_argument("-v", "--verbose", action="store_true")
    sp = sub.add_parser("start", help="create a run and run it up to the publish gate")
    scope_args(sp)
    sp.add_argument("--dry-run", action="store_true", help="print and record every command; run nothing")
    sp.add_argument("--apple-results", metavar="DIR",
                    help="the Apple hand-off results are already in DIR (the builder's dmgs, .sha256, REPORT): "
                         "no job is sent, the hand-off steps take their results from there")
    sp.add_argument("--no-relmsg", action="store_true", help="no Telegram (the publish gate then stays closed)")
    sp.add_argument("--until", help="stop after this step")
    sp.add_argument("--run-source-check", action="store_true",
                    help="the default: without a green full check of this content G2 runs in this run")
    sp.add_argument("--sign-inline", action="store_true",
                    help="sign as soon as every build is in; "
                         "default: the run waits at sign-android until `tools/rel sign`")

    def machine_args(sp):
        sp.add_argument("--max-heavy", type=int, help="heavy steps at once (default [concurrency] max_heavy, 2)")
        sp.add_argument("--stop-on-fail", action="store_true",
                        help="the first failed step stops the run (default: only the steps that need it; "
                             "publishing always stops)")
        sp.add_argument("--keep-going", action="store_true", help=argparse.SUPPRESS)  # the default now
    machine_args(sp)
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
            machine_args(sp)
        if name == "publish":
            sp.add_argument("--dry-run", action="store_true")
    for name, hlp in (("run", "one step, nothing after it"), ("retry", "a failed step again"), ("logs", "a step's log"),
                      ("debug", "a step's exact command, env and log; --exec re-runs it here"), ("skip", "skip a skippable step")):
        sp = sub.add_parser(name, help=hlp)
        sp.add_argument("step")
        sp.add_argument("--run")
        if name in ("run", "retry"):
            sp.add_argument("--again", action="store_true", help="also a step that is done (publish steps need it)")
            sp.add_argument("--stop-on-fail", action="store_true",
                            help="a failed step stops the others too (default: only the steps that need it)")
        if name == "run":
            sp.add_argument("more", nargs="*", metavar="step", help="more steps, run side by side across their lanes")
            sp.add_argument("--keep-going", action="store_true", help=argparse.SUPPRESS)  # the default now
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
    sp = sub.add_parser("add-step", help="steps of the current pipeline into a run planned before them; runs nothing")
    sp.add_argument("step", nargs="+")
    sp.add_argument("--run")
    sp = sub.add_parser("doing", help="what is being done about a failed step, for the panel: fixing, accepted, none...")
    sp.add_argument("step")
    sp.add_argument("state", choices=App.DOING)
    sp.add_argument("--note", help="what is fixed, why it is accepted, what waits")
    sp.add_argument("--commit", help="the fix's commit")
    sp.add_argument("--run")
    sp = sub.add_parser("sign", help="sign the Android files now (the owner's code only without the signer credential), then carry on")
    sp.add_argument("--run", help="run id, folder or version (default: the newest run)")
    machine_args(sp)
    sp = sub.add_parser("verify", help="G3 checks on any folder of release files")
    sp.add_argument("folder")
    for name, what in (("rollback", "the website, GitHub and the mirrors serve the previous release again (one switch, nothing signed or uploaded)"),
                       ("rollforward", "undo a rollback: serve the newer release again")):
        sp = sub.add_parser(name, help=what)
        sp.add_argument("--to", help="the version to switch to (default: the previous release; after a rollback, the newer one)")
        sp.add_argument("--dry-run", action="store_true", help="read-only: what would switch and what GitHub would do")
        sp.add_argument("--parts", help="only these parts: site,readback,github,mirrors (repeat a failed one; the site part first)")
        sp.add_argument("--github-repo", help="owner/repo on GitHub (tests)")
        sp.add_argument("--test-root", help="a folder standing in for the server (site/, api/): nothing leaves this machine")
    sp = sub.add_parser("publish-one", help="publish ONE built file on the live release: signed, on the page, in the manifests, read back (the owner's word is the approval)")
    sp.add_argument("platform", choices=["windows", "linux", "android", "macos", "ios"])
    sp.add_argument("variant", choices=["tor", "notor"])
    sp.add_argument("file", help="the built file (bt-wallet-<version>[-notor]-<platform>-...)")
    sp.add_argument("--version", help="refuse unless the file is this version (default: the file's own)")
    sp.add_argument("--dry-run", action="store_true", help="read-only: check the file and the live release, say what would change")
    sp.add_argument("--apple-results", help="macOS: the folder with the dmg, its .sha256 and REPORT.txt from the Mac (default: the dmg's folder)")
    sp.add_argument("--data", help="releases.json to change (default: the main checkout's)")
    sp.add_argument("--no-github", action="store_true", help="leave the GitHub release alone")
    sp.add_argument("--github-repo", help="owner/repo on GitHub (tests)")
    sp.add_argument("--test-root", help="a folder standing in for the server (site/, api/): signs with the test key, nothing leaves this machine")
    sp = sub.add_parser("presign", help="sign the rollback manifest pairs of the live and the other release now")
    sp.add_argument("--dry-run", action="store_true")
    sp.add_argument("--other", help="the release to prepare next to the live one (default: the newer, else the previous)")
    sp.add_argument("--no-github", action="store_true", help="leave the GitHub release's pre-signed update-v2.json alone")
    sp.add_argument("--test-root", help="a folder standing in for the server; signs with the test key")
    sp = sub.add_parser("migrate-layout", help="once: turn the server's flat downloads folder into version folders (needs the owner's yes)")
    sp.add_argument("--version", help="the live release (default: read from the live manifest)")
    sp.add_argument("--dry-run", action="store_true", help="read-only: say what would change")
    sp.add_argument("--test-root", help="a folder standing in for the server")
    sp = sub.add_parser("resign", help="sign the live manifests again: new serial and expiry only (one approval)")
    sp.add_argument("--dry-run", action="store_true", help="check the live files and print the new dates; sign nothing")
    sp.add_argument("--test", action="store_true", help="the test key, and --live-dir instead of the server")
    sp.add_argument("--live-dir", help="--test: the folder standing in for the live manifests")
    sp.add_argument("--test-root", help="--test: a folder standing in for the server with version folders (site/, api/)")
    sp = sub.add_parser("cleanup", help="keep the current and the previous release; remove the rest")
    sp.add_argument("--dry-run", action="store_true")
    sp = sub.add_parser("gate-watch", help="check the gate until it is decided; publish once approved (started by the gate)")
    sp.add_argument("--run", help="run id, folder or version (default: the newest run)")
    sp.add_argument("--every", type=float, help="seconds between checks (default [gate] watch_every, 60)")
    sp.add_argument("--foreground", action="store_true", help="watch here instead of starting a detached watcher")
    sub.add_parser("stats", help="per-step times and failures across runs")
    sub.add_parser("runs", help="every run kept")
    sp = sub.add_parser("flow", help="the stages in order: class, needs, outputs (the header of pipeline.toml)")
    sp.add_argument("--json", action="store_true", default=argparse.SUPPRESS, help="one JSON object on stdout")
    sp.add_argument("--write", action="store_true", help="regenerate the header block of pipeline.toml")
    sp = sub.add_parser("cut", help="branch release/<version> from the tip of main (or --from), with the version commit")
    sp.add_argument("--version", required=True)
    sp.add_argument("--from", dest="from_commit", metavar="COMMIT", help="branch from this commit instead of main's tip")
    return p


def main(argv=None):
    p = parser()
    try:
        a = p.parse_args(argv)
    except SystemExit as e:
        return EXIT_USAGE if e.code else 0
    old = {}
    for sig in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
        try:
            old[sig] = signal.signal(sig, _raise_interrupted)
        except ValueError:  # not the main thread (tests): no handlers
            break
    try:
        app = App(a)
        fn = getattr(app, "cmd_" + a.cmd.replace("-", "_"))
        return fn(a) or 0
    except Interrupted as e:
        print(f"tools/rel: stopped by {signal.Signals(e.signum).name}", file=sys.stderr)
        return 128 + e.signum
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
    finally:
        for sig, h in old.items():
            signal.signal(sig, h)
