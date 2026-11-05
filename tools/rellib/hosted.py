# SPDX-License-Identifier: Apache-2.0
"""Hosted builds: the build-* steps of a run started with `tools/rel start --builds hosted`.

hosted-dispatch (a builtin, right after source) sends a workflow_dispatch of
.github/workflows/build.yml on BTLabsUK/wallet-for-epic for the published twin of the release
commit, with the platforms and variants of the build steps that the reuse check does not cover.
With [hosted] waves the builds go out in waves (the Tor builds, then the no-Tor ones): the first
wave from hosted-dispatch, a later one from the first of its build steps once every build of the
waves before is in; a failed one stops it there. Each build step then runs tools/rellib/steps/build-fetch.py instead of its local build: it waits
for its job (deadline from dispatch), downloads its artifact, verifies it (the run's commit and
workflow, SHA256SUMS, the build attestation and its commit, the platform's verify script,
build-info.json), places the files in {stage} as the local build would, writes built_by.json
backs the verified download up to [hosted] backup_dir and then deletes the artifact (never before). A failure or a missed deadline fails the step: no retry, no
re-dispatch, no local build (the owner 2026-11-03: "only try github or fail").

Every gh call runs with GH_CONFIG_DIR from [hosted] gh_config, after a check that `gh api user`
is [hosted] account. Dispatches are counted in [hosted] state (one JSON line each) and capped per
24 h ([hosted] max_per_day; ramp_max_per_day before ramp_until)."""
import datetime as dt
import fcntl
import hashlib
import json
import os
import re
import shutil
import subprocess
import time

from .config import ConfigError, expand, parse_duration

ZERO = "0" * 40
HOSTED_PLATFORMS = ("android", "linux", "windows")
WORKFLOW_PATH = ".github/workflows/build.yml"
DEFAULTS = {
    "repo": "BTLabsUK/wallet-for-epic", "workflow": "build.yml", "gh_config": "~/.config/gh-btlabs",
    "account": "btlabs-uk", "commit_map": "~/publish/wallet-for-epic.commit-map",
    "state": "/tmp/epic-build/rel/hosted-dispatches.jsonl", "backup_dir": "/tmp/epic-build/hosted-backup", "max_per_day": 8, "ramp_until": "",
    "ramp_max_per_day": 2, "poll": "30s", "find_wait": "120s", "waves": [],
    "deadline": {"android": "90m", "linux": "90m", "windows": "105m"},
}
# The verify scripts of the release checkout (shared with the local builds and the runner).
VERIFY = {"android": "app/tool/verify_android_release.sh", "linux": "scripts/verify-linux.sh",
          "windows": "app/tool/verify_windows_release.sh"}


class HostedError(Exception):
    """A hosted build that cannot go on: the message is the step's note."""


def conf(pipeline):
    """[hosted] of pipeline.toml with the defaults filled in, paths expanded, durations in s."""
    raw = dict(getattr(pipeline, "data", {}).get("hosted", {}))
    c = {**DEFAULTS, **raw}
    c["deadline"] = {**DEFAULTS["deadline"], **raw.get("deadline", {})}
    for k in ("gh_config", "commit_map", "state", "backup_dir"):
        c[k] = expand(c[k])
    out = dict(c)
    out["deadline_s"] = {p: parse_duration(v) for p, v in c["deadline"].items()}
    out["poll_s"] = parse_duration(c["poll"])
    out["find_wait_s"] = parse_duration(c["find_wait"])
    for k in ("max_per_day", "ramp_max_per_day"):
        if type(c[k]) is not int or c[k] < 0:
            raise ConfigError(f"[hosted] {k} = {c[k]!r}: a whole number, 0 or more")
    w = c["waves"]
    if not isinstance(w, list) or not all(isinstance(x, list) and x and set(x) <= {"tor", "notor"} for x in w) \
            or len([v for x in w for v in x]) != len({v for x in w for v in x}):
        raise ConfigError(f"[hosted] waves = {w!r}: lists of variants (tor, notor), each variant once")
    return out


def check_pipeline(pipeline):
    """Config errors of [hosted] and of the steps' `hosted` keys (called by Pipeline)."""
    conf(pipeline)
    for name, s in pipeline.steps.items():
        h = s.get("hosted")
        if h is None:
            continue
        if h not in HOSTED_PLATFORMS:
            raise ConfigError(f"{pipeline.path}: step {name}: hosted = {h!r}: one of {', '.join(HOSTED_PLATFORMS)}")
        if s.get("for_each") != "variant":
            raise ConfigError(f"{pipeline.path}: step {name}: a hosted build is per variant (for_each = \"variant\")")


def is_hosted(scope):
    return bool((scope.get("builds") or {}).get("hosted"))


# ---- commits -----------------------------------------------------------------------------------

def published_of(commit, map_path):
    """The published twin of a local commit from <repo>.commit-map ("old new" lines), or None
    (not in the map, or dropped as empty when published)."""
    try:
        with open(map_path, encoding="utf-8") as f:
            for line in f:
                parts = line.split()
                if len(parts) == 2 and parts[0] == commit:
                    return parts[1] if parts[1] != ZERO else None
    except OSError:
        return None
    return None


def build_id_for(commit, map_path):
    """WFE_BUILD_ID (the About line, D4): the published short commit when the release commit is
    published, else the local short commit."""
    pub = published_of(commit, map_path)
    return (pub or commit)[:7]


def kind_of(info):
    """release for a real release, dev for test runs (artifact retention, concurrency group)."""
    return "dev" if info.get("test") or info.get("target", "live") != "live" else "release"


# ---- gh ----------------------------------------------------------------------------------------

def gh_env(c):
    env = dict(os.environ)
    env.update(GH_CONFIG_DIR=c["gh_config"], GH_PROMPT_DISABLED="1", GH_NO_UPDATE_NOTIFIER="1", NO_COLOR="1")
    env.pop("GH_TOKEN", None)
    env.pop("GITHUB_TOKEN", None)
    return env


def gh(c, args, timeout=120):
    """-> (rc, stdout, stderr) of `gh <args>` as [hosted] account."""
    try:
        p = subprocess.run(["gh", *args], env=gh_env(c), capture_output=True, text=True, timeout=timeout,
                           stdin=subprocess.DEVNULL)
    except FileNotFoundError:
        return 127, "", "gh is not installed"
    except subprocess.TimeoutExpired:
        return 124, "", f"gh {' '.join(args[:3])}: no answer in {timeout} s"
    return p.returncode, p.stdout, p.stderr


def gh_json(c, args, timeout=120):
    rc, out, err = gh(c, args, timeout)
    if rc != 0:
        raise HostedError(f"gh {' '.join(args[:3])}: exit {rc}: {err.strip()[-200:]}")
    try:
        return json.loads(out or "null")
    except ValueError:
        raise HostedError(f"gh {' '.join(args[:3])}: not JSON: {out[:120]!r}")


def account_problem(c):
    """None when gh can verify build attestations and is logged in as [hosted] account, else why
    not. The first gh on PATH decides: an older one (Ubuntu's /usr/bin/gh 2.46) has no `attestation`."""
    rc, _, err = gh(c, ["attestation", "verify", "--help"], timeout=60)
    if rc != 0:
        return (f"{shutil.which('gh') or 'gh'} cannot verify build attestations (exit {rc}: {err.strip()[-120:]}); "
                "put gh 2.49 or newer first on PATH")
    try:
        who = gh_json(c, ["api", "user"], timeout=60)
    except HostedError as e:
        return f"gh as {c['account']} (GH_CONFIG_DIR={c['gh_config']}): {e}"
    login = (who or {}).get("login")
    if login != c["account"]:
        return f"gh is logged in as {login!r}, not {c['account']!r} (GH_CONFIG_DIR={c['gh_config']})"
    return None


def main_tip(c):
    return (gh_json(c, ["api", f"repos/{c['repo']}/commits/main"], timeout=60) or {}).get("sha")


# ---- the dispatch cap --------------------------------------------------------------------------

def _now():
    return dt.datetime.now(dt.timezone.utc)


def cap_of(c, now=None):
    now = now or _now()
    ramp = str(c.get("ramp_until") or "")
    if ramp and now.date().isoformat() < ramp:
        return c["ramp_max_per_day"], f"ramp-up until {ramp}"
    return c["max_per_day"], "per 24 h"


def dispatches_since(c, since):
    out = []
    try:
        with open(c["state"], encoding="utf-8") as f:
            for line in f:
                try:
                    d = json.loads(line)
                    ts = dt.datetime.fromisoformat(d["ts"].replace("Z", "+00:00"))
                except (ValueError, KeyError, TypeError):
                    continue
                if ts >= since:
                    out.append(d)
    except OSError:
        pass
    return out


def cap_problem(c, now=None):
    """None while a dispatch is allowed, else why not."""
    now = now or _now()
    n = len(dispatches_since(c, now - dt.timedelta(hours=24)))
    cap, what = cap_of(c, now)
    if n >= cap:
        return f"{n} hosted dispatches in the last 24 h, cap {cap} ({what}; [hosted] in release/pipeline.toml, {c['state']})"
    return None


# ---- G1 preflight (hosted runs only) -----------------------------------------------------------

def preflight_checks(engine, ok, bad):
    """The candidate is published (commit-map), it is GitHub main's tip, buildcheck is clean, the
    cap is not reached. Stores run.info["source_published"] (run.info["published"] is the live publish). Reads only: nothing is pushed."""
    info = engine.info
    c = conf(engine.pipeline)
    push = "push it first with tools/publish-github.sh --push (the lead runs it)"
    if not shutil.which("gh"):
        bad("tool gh (hosted builds)")
        return
    ok("tool gh")
    pub = published_of(info["commit"], c["commit_map"])
    if not pub:
        bad(f"hosted builds: {info['commit'][:12]} is not in {c['commit_map']} (not published): {push}")
        return
    ok(f"hosted builds: {info['commit'][:12]} is published as {pub[:12]}")
    why = account_problem(c)
    if why:
        bad(f"hosted builds: {why}")
        return
    ok(f"gh as {c['account']}")
    try:
        tip = main_tip(c)
    except HostedError as e:
        bad(f"hosted builds: GitHub main of {c['repo']}: {e}")
        return
    if tip != pub:
        bad(f"hosted builds: GitHub main of {c['repo']} is at {str(tip)[:12]}, not {pub[:12]} "
            f"(hosted builds run on main's tip only): {push}")
        return
    ok(f"GitHub main of {c['repo']} is {pub[:12]}")
    tool = os.path.join(engine.repo, "tools/publish/bin/buildcheck.py")
    if not os.path.isfile(tool):
        bad(f"hosted builds: no {tool} (the build-input check; it comes with the publish kit's hosted-builds change)")
        return
    try:
        p = subprocess.run(["python3", tool, info["commit"], "--json"], capture_output=True, text=True, timeout=900,
                           cwd=engine.repo)
    except subprocess.TimeoutExpired:
        bad("hosted builds: buildcheck.py did not finish in 900 s")
        return
    try:
        res = json.loads(p.stdout)
    except ValueError:
        res = {}
    if p.returncode != 0:
        what = res.get("error") or f"{len(res.get('findings') or [])} build-input finding(s)"
        bad(f"hosted builds: buildcheck.py {info['commit'][:12]}: exit {p.returncode}: {what} "
            f"(python3 tools/publish/bin/buildcheck.py {info['commit'][:12]})")
        return
    if res.get("published") and res["published"] != pub:
        bad(f"hosted builds: buildcheck names {res['published'][:12]}, the commit-map {pub[:12]}")
        return
    ok("buildcheck: the published build inputs are the local ones")
    why = cap_problem(c)
    (bad if why else ok)(f"hosted builds: {why}" if why else "hosted dispatch cap not reached")
    info["source_published"] = {"commit": pub, "short": pub[:7],
                         "lepic": (res.get("lepic") or {}).get("published"),
                         "lepic_flutter": (res.get("lepic_flutter") or {}).get("published")}
    engine.run.save_info()


# ---- hosted-dispatch ---------------------------------------------------------------------------

def hosted_dir(run):
    d = os.path.join(run.path, "hosted")
    os.makedirs(d, exist_ok=True)
    return d


def build_steps(engine):
    return [s for s in engine.run.steps if (engine.pipeline.steps.get(s.base) or {}).get("hosted")
            and s.local_run is not None]


def reused(engine, step):
    """True when the reuse check takes an earlier result for this build (it then never runs)."""
    from . import reuse
    spec = engine.pipeline.steps.get(step.base) or {}
    if not spec.get("reuse"):
        return False
    try:
        _, _, src = reuse.find(engine, step, spec["reuse"], reuse.nightly_dir(spec), reuse.green_dir(spec))
    except Exception:
        return False
    return bool(src)


def _ordered(names, allowed):
    return [x for x in allowed if x in names]


def waves_of(c, need_names):
    """The dispatch's waves: lists of `<platform>-<variant>` builds, in [hosted] waves order (a list
    of variant lists, e.g. [["tor"], ["notor"]]); a variant no wave names goes in a last wave of its
    own; empty waves are dropped. No waves: one wave with every build."""
    order = [list(w) for w in c.get("waves") or []]
    named = {v for w in order for v in w}
    rest = sorted({n.rsplit("-", 1)[1] for n in need_names} - named, key=("tor", "notor").index)
    if rest:
        order.append(rest)
    out = [[n for n in need_names if n.rsplit("-", 1)[1] in w] for w in order] if order else [list(need_names)]
    return [w for w in out if w]


def dispatch(engine, step, say):
    run, info = engine.run, engine.info
    c = conf(engine.pipeline)
    path = os.path.join(hosted_dir(run), "dispatch.json")
    old = _read(path)
    if old and (old.get("waves") or [{}])[0].get("run_id"):
        # One dispatch per wave, never a second (no re-dispatch): a resume finds the same run.
        say(f"already dispatched: {old['waves'][0].get('run_url')}")
        return {"status": "done", "note": f"dispatched earlier: run {old['waves'][0]['run_id']}"}
    builds = [s for s in build_steps(engine) if run.status(s.id).get("status") != "skipped"]
    need = [s for s in builds if not reused(engine, s)]
    for s in builds:
        if s not in need:
            say(f"{s.id}: reused (an earlier build with the same inputs), not built")
    if not need:
        return {"status": "done", "note": "nothing to build: every build is reused"}
    pub = (info.get("source_published") or {}).get("commit")
    build_id = need[0].env.get("WFE_BUILD_ID") or (pub or info["commit"])[:7]
    kind = kind_of(info)
    names = [f"{engine.pipeline.steps[s.base]['hosted']}-{s.variant}" for s in need]
    waves = waves_of(c, names)
    if engine.dry:
        for i, w in enumerate(waves, 1):
            say(f"dry run: wave {i} would dispatch {c['workflow']} on {c['repo']}: {', '.join(w)}, kind {kind}")
        return {"status": "done", "note": "dry run: " + "; then ".join(", ".join(w) for w in waves), "dry": True}
    if not pub:
        return {"status": "failed", "note": "no published commit in run.json (G1 preflight records it)"}
    why = account_problem(c)
    if why:
        return {"status": "failed", "note": why}
    if not old:
        old = {"commit": pub, "local_commit": info["commit"], "build_id": build_id, "version": info["version"],
               "kind": kind, "run": info["run_id"], "conf": _fetch_conf(c),
               "waves": [{"expected": w} for w in waves]}
        _write(path, old)
    ok, note = send_wave(c, path, 0, say)
    if not ok:
        return {"status": "failed", "note": note}
    w = _read(path)["waves"][0]
    out_dir = os.path.join(run.step_dir(step.id), "out")
    os.makedirs(out_dir, exist_ok=True)
    _write(os.path.join(out_dir, "links.json"), [{"label": "hosted builds", "url": w["run_url"]}])
    later = old["waves"][1:]
    if later:
        note += "; then " + "; then ".join(", ".join(x["expected"]) for x in later) + " once these are in"
    return {"status": "done", "note": note}


def send_wave(c, path, i, say):
    """Dispatches wave i of dispatch.json (once: a wave with a request is looked up, never sent
    again) and records its run. -> (ok, note)."""
    os.makedirs(os.path.dirname(c["state"]) or ".", exist_ok=True)
    with open(c["state"] + ".lock", "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)  # two runs (or two fetches of a wave) never both pass the cap
        d = _read(path)
        w = d["waves"][i]
        if not w.get("request"):
            why = cap_problem(c)
            if why:
                return False, f"not dispatched: {why}"
            n = 1 + sum(1 for x in dispatches_since(c, dt.datetime.min.replace(tzinfo=dt.timezone.utc))
                        if x.get("run") == d["run"])
            request = f"{d['run']}-{n}"
            plats = _ordered({x.rsplit("-", 1)[0] for x in w["expected"]}, HOSTED_PLATFORMS)
            vars_ = _ordered({x.rsplit("-", 1)[1] for x in w["expected"]}, ("tor", "notor"))
            args = ["workflow", "run", c["workflow"], "--repo", c["repo"], "--ref", "main",
                    "-f", f"commit={d['commit']}", "-f", f"build_id={d['build_id']}", "-f", f"version={d['version']}",
                    "-f", f"platforms={json.dumps(plats)}", "-f", f"variants={json.dumps(vars_)}",
                    "-f", f"kind={d['kind']}", "-f", f"request={request}"]
            say("gh " + " ".join(args))
            rc, out, err = gh(c, args)
            if rc != 0:
                return False, f"gh workflow run: exit {rc}: {err.strip()[-200:]}"
            w.update(request=request, dispatched_at=_now().isoformat(), platforms=plats, variants=vars_)
            _write(path, d)
            with open(c["state"], "a", encoding="utf-8") as f:
                f.write(json.dumps({"ts": w["dispatched_at"], "run": d["run"], "request": request,
                                    "kind": d["kind"], "commit": d["commit"], "builds": w["expected"]}) + "\n")
        if w.get("run_id"):
            return True, f"{', '.join(w['expected'])}: {w['run_url']}"
        title = f"build {d['kind']} {w['request']}"
    found, deadline = None, time.time() + c["find_wait_s"]
    while True:
        try:
            runs = gh_json(c, ["run", "list", "--repo", c["repo"], "--workflow", c["workflow"], "--limit", "30",
                               "--json", "databaseId,displayTitle,headSha,url"])
        except HostedError as e:
            say(str(e))
            runs = []
        found = next((r for r in runs or [] if r.get("displayTitle") == title), None)
        if found or time.time() >= deadline:
            break
        time.sleep(min(5, c["poll_s"]) or 0.1)
    if not found:
        return False, (f"dispatched ({w['request']}) but no run titled {title!r} in {c['find_wait_s']:.0f} s; "
                       "tools/rel retry looks again")
    with open(c["state"] + ".lock", "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        d = _read(path)
        d["waves"][i].update(run_id=found["databaseId"], run_url=found["url"], head_sha=found.get("headSha"))
        _write(path, d)
    say(f"wave {i + 1}: run {found['databaseId']}: {found['url']}")
    return True, f"{', '.join(w['expected'])}: {found['url']}"


def _fetch_conf(c):
    return {k: c[k] for k in ("repo", "workflow", "gh_config", "account", "deadline_s", "poll_s", "find_wait_s",
                              "state", "backup_dir", "max_per_day", "ramp_until", "ramp_max_per_day")}


def _read(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def _write(path, data):
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=1, sort_keys=True)
    os.replace(tmp, path)


# ---- build-fetch -------------------------------------------------------------------------------

def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def job_of(jobs, platform, variant):
    """The matrix job `<platform> (<variant>)` ("tor" never matches "notor")."""
    for j in jobs:
        name = str(j.get("name", "")).lower()
        if name.split(" ")[0] == platform and re.search(rf"(?<![a-z]){variant}(?![a-z])", name[len(platform):]):
            return j
    return None


def read_sums(path):
    out = {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            m = re.match(r"^([0-9a-f]{64}) [ *](.+)$", line.rstrip("\n"))
            if not m:
                raise HostedError(f"SHA256SUMS: a line that is not `<sha256>  <file>`: {line.strip()[:80]!r}")
            out[m.group(2).removeprefix("./")] = m.group(1)
    return out


def attested_commits(doc):
    """The commits an attestation names (the signing certificate's and the build definition's)."""
    out = set()
    for e in doc if isinstance(doc, list) else [doc]:
        vr = (e or {}).get("verificationResult") or {}
        cert = ((vr.get("signature") or {}).get("certificate") or {})
        if cert.get("sourceRepositoryDigest"):
            out.add(cert["sourceRepositoryDigest"])
        pred = ((vr.get("statement") or {}).get("predicate") or {})
        for dep in ((pred.get("buildDefinition") or {}).get("resolvedDependencies") or []):
            if (dep.get("digest") or {}).get("gitCommit"):
                out.add(dep["digest"]["gitCommit"])
    return out


class Fetch:
    def __init__(self, run, sid, platform, variant, stage, say=print):
        self.run, self.sid, self.platform, self.variant, self.stage, self.say = run, sid, platform, variant, stage, say
        self.dir = hosted_dir(run)
        self.path = os.path.join(self.dir, "dispatch.json")
        self.all = _read(self.path)
        self.name = f"{platform}-{variant}"
        self.state_path = os.path.join(self.dir, f"fetch-{self.name}.json")
        self.c = dict((self.all or {}).get("conf") or {})
        self.wave = next((i for i, w in enumerate((self.all or {}).get("waves") or []) if self.name in w["expected"]), None)
        self.d = None if self.wave is None else {**self.all, **self.all["waves"][self.wave]}

    def mark(self, status, **kw):
        _write(self.state_path, dict(status=status, ts=_now().isoformat(), **kw))

    def main(self):
        self.mark("running")
        try:
            built_by = self.fetch()
        except HostedError as e:
            self.say(f"FAIL {e}")
            self.mark("failed", reason=str(e))
            self.after_failure()
            self.run.event(self.sid, "via", via="hosted", failed=str(e)[:300])
            self.say(f"FAIL {e}")  # the log's last line: the step's reason
            # Local fallback: off unless the run was started with --local-fallback (the owner 2026-11-03,
            # "only try github or fail"; 26.11.0 run-4: a failed hosted build is built here instead).
            if ((self.run.info.get("scope") or {}).get("builds") or {}).get("fallback") != "local":
                return 1
            if self.platform == "windows":  # its local build runs on the Windows host, not through bash here
                self.say("no local fallback for a Windows build: build it on the Windows host")
                return 1
            self.say("building locally instead")
            rc = subprocess.call(
                ["bash", "-c", "set -euo pipefail\n" + self.run.step(self.sid).local_run], cwd=self.run.info["src"])
            if rc == 0:
                self.run.event(self.sid, "via", via="local", attestation="none", why=str(e)[:300])
            return rc
        self.mark("done", **{k: built_by.get(k) for k in ("run_url", "job_url")})
        self.run.event(self.sid, "via", via="hosted", run_url=built_by["run_url"], job_url=built_by.get("job_url"))
        self.cleanup_run()
        self.say(f"ok   {self.name} via hosted: {built_by.get('job_url') or built_by['run_url']}")
        return 0

    def fetch(self):
        if not self.all or not (self.all.get("waves") or [{}])[0].get("run_id"):
            raise HostedError(f"no dispatched run ({self.dir}/dispatch.json): hosted-dispatch did not run or failed")
        if self.wave is None:
            raise HostedError(f"{self.name} was not in the dispatch "
                              f"({', '.join(n for w in self.all['waves'] for n in w['expected'])})")
        if self.wave > 0:
            self.send_after_earlier_waves()
        d = self.d
        repo, rid = self.c["repo"], d["run_id"]
        why = account_problem(self.c)
        if why:
            raise HostedError(why)
        started = dt.datetime.fromisoformat(d["dispatched_at"]).timestamp()
        limit = started + float(self.c["deadline_s"][self.platform])
        poll = float(self.c.get("poll_s", 30))
        self.say(f"waiting for {self.name} in {d['run_url']} (deadline {dt.datetime.fromtimestamp(limit).isoformat(timespec='seconds')})")
        job = None
        while True:
            try:
                jobs = (gh_json(self.c, ["api", f"repos/{repo}/actions/runs/{rid}/jobs?per_page=100"]) or {}).get("jobs") or []
                job = job_of(jobs, self.platform, self.variant)
                runinfo = gh_json(self.c, ["api", f"repos/{repo}/actions/runs/{rid}"]) or {}
            except HostedError as e:
                self.say(f"gh: {e}")  # a missed answer: asked again at the next poll, up to the deadline
                job, runinfo = None, {}
            if job and job.get("status") == "completed":
                break
            if not job and runinfo.get("status") == "completed":
                raise HostedError(f"run {rid} ended ({runinfo.get('conclusion')}) without a job {self.name}")
            if time.time() >= limit:
                raise HostedError(f"deadline: {self.name} not done {self.c['deadline_s'][self.platform] / 60:.0f} min "
                                  f"after dispatch (job {(job or {}).get('status', 'not started')})")
            time.sleep(poll)
        job_url = job.get("html_url")
        if job.get("conclusion") != "success":
            raise HostedError(f"job {job.get('name')} {job.get('conclusion')}: {job_url}")
        # (1) the run built the published commit with the one allowed workflow
        runinfo = gh_json(self.c, ["api", f"repos/{repo}/actions/runs/{rid}"]) or {}
        if runinfo.get("head_sha") != d["commit"]:
            raise HostedError(f"run {rid} built {str(runinfo.get('head_sha'))[:12]}, not the published {d['commit'][:12]}")
        if str(runinfo.get("path", "")).split("@")[0] != WORKFLOW_PATH:
            raise HostedError(f"run {rid} came from {runinfo.get('path')!r}, not {WORKFLOW_PATH}")
        dl = os.path.join(self.dir, f"dl-{self.name}")
        if os.path.isdir(dl):
            shutil.rmtree(dl)  # this step's own download folder from an earlier attempt
        # Fetched and backed up before (the artifact is gone from GitHub then): the backup is verified
        # again instead of a download.
        backup = (_read(self.backup_mark(self.name)) or {}).get("backup")
        if backup and os.path.basename(os.path.dirname(backup)) == f"{self.run.info['run_id']}-{rid}" \
                and os.path.isfile(os.path.join(backup, "SHA256SUMS")):
            shutil.copytree(backup, dl, ignore=shutil.ignore_patterns(".attestation-*"))
            self.say(f"artifact {self.name} was fetched and backed up before: verifying {backup}")
        else:
            os.makedirs(dl)
            rc, out, err = gh(self.c, ["run", "download", str(rid), "--repo", repo, "-n", self.name, "-D", dl],
                              timeout=1800)
            if rc != 0:
                raise HostedError(f"gh run download {rid} -n {self.name}: exit {rc}: {err.strip()[-200:]}")
        files = self.verify(dl, d, job)  # a failure keeps the artifact on GitHub
        backed_up = self.back_up(dl, rid)  # before the move below empties dl
        att_dir = os.path.join(self.stage, "attestations")
        os.makedirs(att_dir, exist_ok=True)
        att = {}
        for rel, digest in files.items():
            dst = os.path.join(self.stage, rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.move(os.path.join(dl, rel), dst)
            bundle = os.path.join(att_dir, os.path.basename(rel) + ".json")
            shutil.move(os.path.join(dl, ".attestation-" + os.path.basename(rel) + ".json"), bundle)
            att[rel] = {"sha256": digest, "verified": os.path.relpath(bundle, self.stage)}
        info = _read(os.path.join(dl, "build-info.json")) or {}
        built_by = {"via": "hosted", "run_url": d["run_url"], "job_url": job_url, "run_id": rid,
                    "runner_image": info.get("runner_image"), "commit": d["commit"], "build_id": d["build_id"],
                    "attestation": att}
        _write(os.path.join(self.stage, "built_by.json"), built_by)
        shutil.rmtree(dl, ignore_errors=True)
        if backed_up:  # downloaded, verified, in the stage and backed up: now the artifact may go
            _write(self.backup_mark(self.name), {"backup": backed_up})
            self.delete_artifact(self.name)
        return built_by

    def backup_mark(self, name):
        return os.path.join(self.dir, f"backed-up-{name}.json")

    def back_up(self, dl, rid):
        """Copies the verified download (files, SHA256SUMS, build-info.json, attestation bundles) to
        {backup_dir}/<rel run id>-<github run id>/<artifact name>. Returns the folder, or None
        (with a warning) when the copy failed: the artifact then stays on GitHub."""
        dst = os.path.join(self.c["backup_dir"], f"{self.run.info['run_id']}-{rid}", self.name)
        try:
            if os.path.isdir(dst):
                shutil.rmtree(dst)
            shutil.copytree(dl, dst)
            return dst
        except OSError as e:
            self.say(f"warn backup to {dst} failed, the artifact stays on GitHub: {e}")
            return None

    def verify(self, dl, d, job):
        say = self.say
        sums_path = os.path.join(dl, "SHA256SUMS")
        if not os.path.isfile(sums_path):
            raise HostedError(f"artifact {self.name}: no SHA256SUMS")
        sums = read_sums(sums_path)
        present = set()
        for root, _, names in os.walk(dl):
            for n in names:
                present.add(os.path.relpath(os.path.join(root, n), dl))
        present -= {"SHA256SUMS", "build-info.json"}
        # (2) SHA256SUMS covers exactly the files, and they match
        if present != set(sums):
            raise HostedError(f"SHA256SUMS lists {sorted(sums)}, the artifact holds {sorted(present)}")
        for rel, want in sums.items():
            got = sha256(os.path.join(dl, rel))
            if got != want:
                raise HostedError(f"{rel}: sha256 {got[:16]}…, SHA256SUMS says {want[:16]}…")
        say(f"ok   SHA256SUMS: {len(sums)} file(s)")
        # (3) each file's build attestation: this repo, this workflow, the published commit
        repo = self.c["repo"]
        for rel in sums:
            rc, out, err = gh(self.c, ["attestation", "verify", os.path.join(dl, rel), "--repo", repo,
                                       "--signer-workflow", f"{repo}/{WORKFLOW_PATH}", "--format", "json"], timeout=300)
            if rc != 0:
                raise HostedError(f"{rel}: gh attestation verify: exit {rc}: {err.strip()[-200:]}")
            try:
                doc = json.loads(out)
            except ValueError:
                raise HostedError(f"{rel}: gh attestation verify: not JSON")
            commits = attested_commits(doc)
            if commits != {d["commit"]}:
                raise HostedError(f"{rel}: attested commit {', '.join(sorted(c[:12] for c in commits)) or 'none'}, "
                                  f"not the published {d['commit'][:12]}")
            with open(os.path.join(dl, ".attestation-" + os.path.basename(rel) + ".json"), "w", encoding="utf-8") as f:
                f.write(out)
        say(f"ok   attestations: {len(sums)} file(s) from {WORKFLOW_PATH} at {d['commit'][:12]}")
        # (4) the platform's own post-build checks, as the local build runs them
        src = self.run.info.get("src") or ""
        script = os.path.join(src, VERIFY[self.platform])
        if not os.path.isfile(script):
            raise HostedError(f"no {VERIFY[self.platform]} in the release checkout {src}")
        if self.platform == "android":
            target = dl
        else:
            tops = [r for r in sums if "/" not in r]
            if len(tops) != 1:
                raise HostedError(f"artifact {self.name}: {len(tops)} files at its root, want 1")
            target = os.path.join(dl, tops[0])
        env = dict(os.environ, WFE_TOR="0" if self.variant == "notor" else "1", WFE_VERSION=d["version"],
                   WFE_BUILD_ID=d["build_id"])
        if self.platform == "android":
            env["WFE_UNSIGNED"] = "1"
        p = subprocess.run(["bash", script, target], cwd=src, env=env, capture_output=True, text=True, timeout=900)
        say((p.stdout + p.stderr).strip()[-3000:])
        if p.returncode != 0:
            lines = [l for l in p.stderr.strip().splitlines() if l.strip()][-3:]
            raise HostedError(f"{VERIFY[self.platform]}: exit {p.returncode}: {'; '.join(lines)[:200]}")
        # (5) build-info.json says what was asked for
        info = _read(os.path.join(dl, "build-info.json"))
        if not isinstance(info, dict):
            raise HostedError(f"artifact {self.name}: no build-info.json")
        want = {"commit": d["commit"], "build_id": d["build_id"], "version": d["version"], "platform": self.platform,
                "variant": self.variant}
        bad = [f"{k} {info.get(k)!r} (want {v!r})" for k, v in want.items() if info.get(k) != v]
        if info.get("files") is not None and info.get("files") != sums:
            bad.append("files differ from SHA256SUMS")
        if bad:
            raise HostedError("build-info.json: " + "; ".join(bad))
        say(f"ok   build-info.json: {self.name} {d['version']} {d['build_id']} on {info.get('runner_image')}")
        return sums

    def send_after_earlier_waves(self):
        """A later wave goes out only when every build of the waves before it is in (fetched and
        verified); a failed one stops it there (the owner 2026-11-03). The first of its fetches to get
        here dispatches it; the others find the dispatch."""
        earlier = [n for w in self.all["waves"][:self.wave] for n in w["expected"]]
        first = self.all["waves"][0]
        limit = (dt.datetime.fromisoformat(first["dispatched_at"]).timestamp()
                 + max(float(v) for v in self.c["deadline_s"].values()) + 1800)
        self.say(f"wave {self.wave + 1}: waiting for {', '.join(earlier)}")
        while True:
            st = {n: (_read(os.path.join(self.dir, f"fetch-{n}.json")) or {}).get("status") for n in earlier}
            bad = [n for n, s in st.items() if s == "failed"]
            if bad:
                raise HostedError(f"wave {self.wave + 1} not sent: {', '.join(bad)} failed in an earlier wave")
            if all(s == "done" for s in st.values()):
                break
            if time.time() >= limit:
                raise HostedError(f"wave {self.wave + 1} not sent: "
                                  f"{', '.join(n for n, s in st.items() if s != 'done')} not in by the deadline")
            time.sleep(float(self.c.get("poll_s", 30)))
        ok, note = send_wave(self.c, self.path, self.wave, self.say)
        if not ok:
            raise HostedError(f"wave {self.wave + 1}: {note}")
        self.all = _read(self.path)
        self.d = {**self.all, **self.all["waves"][self.wave]}

    def delete_artifact(self, name=None):
        """Deletes this run's artifact `name` (every artifact when None) on GitHub, but only one whose
        fetch is done and backed up: a failed or not yet run fetch still needs its artifact (26.11.2
        run2 lost both Windows builds that way). Best effort: retention removes what this misses."""
        repo, rid = self.c["repo"], self.d["run_id"]
        try:
            arts = (gh_json(self.c, ["api", f"repos/{repo}/actions/runs/{rid}/artifacts?per_page=100"]) or {}).get("artifacts") or []
        except HostedError as e:
            self.say(f"warn could not list the run's artifacts: {e}")
            return
        for a in arts:
            if name is not None and a.get("name") != name:
                continue
            if not os.path.isfile(self.backup_mark(a.get("name"))):
                self.say(f"kept artifact {a.get('name')}: not fetched and backed up")
                continue
            rc, _, err = gh(self.c, ["api", "-X", "DELETE", f"repos/{repo}/actions/artifacts/{a['id']}"])
            self.say(f"{'deleted' if rc == 0 else 'warn could not delete'} artifact {a.get('name')}"
                     + ("" if rc == 0 else f": {err.strip()[-120:]}"))

    def others_ended(self):
        for n in self.d.get("expected") or []:
            st = _read(os.path.join(self.dir, f"fetch-{n}.json")) or {}
            if n != self.name and st.get("status") not in ("done", "failed"):
                return False
        return True

    def cleanup_run(self):
        """After the run's last fetch: every artifact left (e.g. a variant built for the matrix
        but reused here) is deleted."""
        if self.others_ended():
            self.delete_artifact(None)

    def after_failure(self):
        """The run is cancelled only when no other build of it is still waited for."""
        if not self.d or not self.d.get("run_id"):
            return
        if self.others_ended():
            rc, _, err = gh(self.c, ["run", "cancel", str(self.d["run_id"]), "--repo", self.c["repo"]])
            self.say("cancelled the run" if rc == 0 else f"run not cancelled (ended already?): {err.strip()[-120:]}")
            self.delete_artifact(None)
