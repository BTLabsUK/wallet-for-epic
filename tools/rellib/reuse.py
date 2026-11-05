# SPDX-License-Identifier: Apache-2.0
"""Reusing a step's passing result when nothing it depends on has changed.

A step with `reuse = [paths]` in release/pipeline.toml has a key: the git object id of each path
at the release commit (a tree for a folder, a blob for a file; "!path" leaves a part of a listed
folder out), the step's id, its environment (and the contents of any file that environment
names), its output names and the version. The toolchain is part of the key through the pins the
tree holds (scripts/linux/flutter.version, scripts/linux/Dockerfile, the Gradle files), and G1
checks the installed Flutter against that pin.

When an earlier run (any version folder under the state root) has the same step done with the
same key, and its output files are still there with their recorded checksums, the step is not
run: its files are copied in and it is marked "reused from <run> (<commit>)". For G2 a green
nightly full check (`reuse_nightly`) of a commit with the same key counts too, and so does any
green `tools/check.sh --full` on a clean tree (`reuse_green`: the <sha>.json records check.sh
writes in /tmp/epic-build/green/ after tools/t's full and full-notor passes, the nightly's own run
included). A candidate none of these covers runs G2 first in its run. A changed key runs the step. Dry runs
never reuse.
"""
import glob
import hashlib
import json
import os
import subprocess


def _git(repo, *args):
    p = subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True)
    return p.stdout if p.returncode == 0 else None


def path_id(repo, commit, path, excludes=()):
    """The git id of path at commit, or a hash of its listing with the excluded parts left out."""
    path = path.rstrip("/")
    inner = [e for e in excludes if e.startswith(path + "/")]
    if not inner:
        out = _git(repo, "rev-parse", "--verify", "--quiet", f"{commit}:{path}")
        return out.strip() if out else "missing"
    listing = _git(repo, "ls-tree", commit, path + "/")
    if listing is None:
        return "missing"
    h = hashlib.sha256()
    for line in sorted(listing.splitlines()):
        meta, name = line.split("\t", 1)
        if name in excludes:
            continue
        h.update(f"{name} {path_id(repo, commit, name, inner) if any(e.startswith(name + '/') for e in inner) else meta.split()[2]}\n".encode())
    return "x" + h.hexdigest()


def _file_hash(value):
    p = os.path.expanduser(str(value))
    if os.path.isfile(p):
        h = hashlib.sha256()
        with open(p, "rb") as f:
            for chunk in iter(lambda: f.read(1 << 20), b""):
                h.update(chunk)
        return h.hexdigest()
    return None


def key(repo, commit, version, step, paths):
    """-> (key, parts): what the step's result depends on, at commit."""
    excludes = [p[1:].rstrip("/") for p in paths if p.startswith("!")]
    trees = {p: path_id(repo, commit, p, excludes) for p in paths if not p.startswith("!")}
    env = {k: str(v) for k, v in sorted((step.env or {}).items())}
    parts = {
        "step": step.id, "version": version, "trees": trees, "excludes": sorted(excludes), "env": env,
        "env_files": {k: _file_hash(v) for k, v in env.items() if _file_hash(v)},
        "outputs": sorted(step.outputs or []), "extras": sorted(step.extras or []),
    }
    return hashlib.sha256(json.dumps(parts, sort_keys=True).encode()).hexdigest()[:24], parts


def _outputs_intact(run_dir, outs):
    from .engine import sha256_file
    for name, o in (outs or {}).items():
        p = os.path.join(run_dir, "extra" if o.get("extra") else "files", name)
        if not os.path.isfile(p) or os.path.getsize(p) != o.get("bytes") or sha256_file(p) != o.get("sha256"):
            return False
    return True


GREEN_DIR = "/tmp/epic-build/green"


def nightly_dir(spec):
    n = spec.get("reuse_nightly")
    return os.path.expanduser("/tmp/epic-build/nightly") if n is True else n


def green_dir(spec):
    """Where `tools/check.sh --full` records green runs (<sha>.json); WFE_GREEN_DIR wins, as for check.sh."""
    g = spec.get("reuse_green")
    if not g:
        return None
    return os.path.expanduser(os.environ.get("WFE_GREEN_DIR") or (GREEN_DIR if g is True else g))


def green_records(gdir):
    """[(sha, record)] of the green full checks in gdir, newest first. Only a clean tree's
    `--full` run that ended with `check passed` with both tools/t passes green (suites full and
    full-notor, tools/rellib/green.py) counts; an older record without suites does not."""
    out = []
    for p in glob.glob(os.path.join(gdir, "*.json")):
        try:
            with open(p, encoding="utf-8") as f:
                r = json.load(f)
            mtime = os.path.getmtime(p)
        except (OSError, ValueError):
            continue
        if not isinstance(r, dict) or r.get("status") != "green" or r.get("clean") is not True \
                or "--full" not in str(r.get("command", "")) or not r.get("sha") \
                or not {"full", "full-notor"} <= set(r.get("suites") or []):
            continue
        out.append((mtime, r["sha"], r))
    return [(s, r) for _, s, r in sorted(out, key=lambda x: x[0], reverse=True)]


def find(engine, step, paths, nightly=None, green=None):
    """-> (key, parts, source or None). source: {"kind": "run"|"nightly"|"green", "label", "commit",
    "run_dir"?, "status"?}."""
    root = os.path.dirname(os.path.dirname(engine.run.path))
    return find_source(engine.repo, root, engine.info, step, paths, nightly, green, this_run=engine.run.path)


def find_source(repo, root, info, step, paths, nightly=None, green=None, this_run=None):
    """find() without a run: also what `tools/rel start` asks before it makes one (G2's green check)."""
    k, parts = key(repo, info["commit"], info["version"], step, paths)
    keys = {}  # commit → key, computed once
    cands = []
    for st_path in glob.glob(os.path.join(root, "*", "run-*", "steps", step.id, "status.json")):
        run_dir = os.path.dirname(os.path.dirname(os.path.dirname(st_path)))
        if this_run and os.path.realpath(run_dir) == os.path.realpath(this_run):
            continue
        try:
            st = json.load(open(st_path))
            other = json.load(open(os.path.join(run_dir, "run.json")))
        except (OSError, ValueError):
            continue
        if st.get("status") != "done" or st.get("dry") or other.get("dry") or other.get("version") != info["version"]:
            continue
        cands.append((os.path.getmtime(st_path), run_dir, st, other))
    for _, run_dir, st, other in sorted(cands, reverse=True):
        c = other.get("commit")
        if st.get("reuse_key") is not None:
            ok = st["reuse_key"] == k
        else:
            if c not in keys:
                keys[c] = key(repo, c, other["version"], step, paths)[0]
            ok = keys[c] == k
        if ok and _outputs_intact(run_dir, st.get("outputs")):
            label = other.get("run_id") or os.path.basename(run_dir)
            return k, parts, {"kind": "run", "label": label, "commit": c, "run_dir": run_dir, "status": st}
    if nightly:
        for lj in sorted(glob.glob(os.path.join(os.path.expanduser(nightly), "runs", "*", "result.json")), reverse=True) + \
                [os.path.join(os.path.expanduser(nightly), "latest.json")]:
            try:
                n = json.load(open(lj))
            except (OSError, ValueError):
                continue
            if n.get("status") != "green" or n.get("exit") != 0 or "--full" not in n.get("command", ""):
                continue
            c = n.get("sha")
            if c and _git(repo, "cat-file", "-e", f"{c}^{{commit}}") is not None:
                if c not in keys:
                    keys[c] = key(repo, c, info["version"], step, paths)[0]
                if keys[c] == k:
                    return k, parts, {"kind": "nightly", "label": f"nightly {n.get('ended', '')}".strip(), "commit": c}
    if green and os.path.isdir(green):
        for c, r in green_records(green):
            if _git(repo, "cat-file", "-e", f"{c}^{{commit}}") is None:
                continue
            if c not in keys:
                keys[c] = key(repo, c, info["version"], step, paths)[0]
            if keys[c] == k:
                label = f"tools/check.sh --full {r.get('ended', '')} ({r.get('by') or r.get('host') or '?'})".strip()
                return k, parts, {"kind": "green", "label": label, "commit": c}
    return k, parts, None


def reuse_into(engine, step, src):
    """Copies the source run's outputs into this run; -> the status fields of the reused step."""
    from .engine import place
    outs = (src.get("status") or {}).get("outputs") or {}
    for name, o in outs.items():
        sub = "extra" if o.get("extra") else "files"
        place(os.path.join(src["run_dir"], sub, name),
              os.path.join(engine.run.extra if o.get("extra") else engine.run.files, name))
    total = sum(o.get("bytes") or 0 for o in outs.values() if not o.get("extra"))
    return {"outputs": outs, "bytes": total or None}
