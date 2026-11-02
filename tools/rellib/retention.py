# SPDX-License-Identifier: Apache-2.0
"""What tools/rel keeps: the current release and the one before it (the rollback backup:
its files, manifests and run record). Everything older goes: older published runs, failed,
test and dry runs of versions that are not newer than the current release, older runs of a
version still in progress, and the release worktrees tools/rel made for them. Runs on every
release (step `cleanup`) and on its own (`tools/rel cleanup`, e.g. from a timer)."""
import fcntl
import os
import shutil
import subprocess

from .run import Run, now_iso, read_json, write_json


def _vkey(v):
    base = v.split("-")[0]
    try:
        return tuple(int(x) for x in base.split(".")), v
    except ValueError:
        return (0,), v


def published(state_root):
    return read_json(os.path.join(state_root, "published.json"), [])


def published_by_hand(state_root):
    """Releases published outside tools/rel, oldest first: [{version, dir, tag}]."""
    pubs = read_json(os.path.join(state_root, "published-by-hand.json"), [])
    return sorted((p for p in pubs if p.get("version")), key=lambda p: _vkey(p["version"]))


def mark_published(run):
    root = os.path.dirname(os.path.dirname(run.path))
    pubs = [p for p in published(root) if p["run_id"] != run.info["run_id"]]
    if run.info.get("test") or run.info.get("dry"):
        # A TEST run is recorded as published only within the scratch target: never as a release.
        run.info["published_scratch"] = now_iso()
        run.save_info()
        return
    # The tag step's tag (v<version>, or v<version>-rN for a rebuild of the same version).
    tag = f"v{run.info['version']}"
    try:
        with open(os.path.join(run.step_dir("tag"), "out", "tag.txt"), encoding="utf-8") as f:
            tag = f.read().strip() or tag
    except OSError:
        pass
    pubs.append({"version": run.info["version"], "run_id": run.info["run_id"], "run": run.path, "at": now_iso(),
                 "tag": tag, "kind": run.info.get("kind", "release")})
    write_json(os.path.join(root, "published.json"), pubs)
    run.info["published"] = pubs[-1]["at"]
    run.save_info()


def busy(path):
    """True while a tools/rel holds the run's lock: such a run is never removed."""
    try:
        f = open(os.path.join(path, ".lock"))
    except OSError:
        return False
    with f:
        try:
            fcntl.flock(f, fcntl.LOCK_SH | fcntl.LOCK_NB)
        except BlockingIOError:
            return True
        fcntl.flock(f, fcntl.LOCK_UN)
    return False


def plan(state_root, keep_run=None):
    """-> {"keep": [paths], "remove": [paths], "kept": [why]}; pure."""
    runs = Run.all(state_root)
    pubs = [p for p in published(state_root) if os.path.isdir(p["run"])]
    keep, why = set(), []
    # The current release and the previous one, by publication order (a rollback publishes the
    # older version again: then it is the current one).
    seen_versions = []
    for p in reversed(pubs):
        if p["version"] in seen_versions:
            continue
        seen_versions.append(p["version"])
        keep.add(p["run"])
        why.append(f"{p['version']} ({'current' if len(seen_versions) == 1 else 'previous, rollback backup'})")
        if len(seen_versions) == 2:
            break
    current = _vkey(seen_versions[0]) if seen_versions else None
    # Runs of a version newer than the current release (a candidate in progress): its newest run.
    newest = {}
    for v, rid, path, created in runs:
        if current is not None and _vkey(v) > current:
            newest[v] = path
    for v, path in newest.items():
        if path not in keep:
            keep.add(path)
            why.append(f"{v} (newest run, not yet released)")
    if keep_run:
        keep.add(os.path.abspath(keep_run))
    if not pubs and runs and not keep_run:
        keep.add(runs[-1][2])
        why.append(f"{runs[-1][0]} (newest run; nothing published yet)")
    for v, rid, path, created in runs:
        if path not in keep and busy(path):
            keep.add(path)
            why.append(f"{rid} (a tools/rel is working on it)")
    remove = [path for v, rid, path, created in runs if path not in keep]
    return {"keep": sorted(keep), "remove": remove, "kept": why}


def apply(state_root, repo, say=print, keep_run=None, dry=False):
    p = plan(state_root, keep_run)
    removed = []
    for path in p["remove"]:
        info = read_json(os.path.join(path, "run.json"), {})
        if dry:
            src = info.get("src") if info.get("src_made") else None
            say(f"would remove {path}" + (f" and its worktree {src}" if src and os.path.isdir(src) else ""))
            continue
        src = info.get("src")
        kept_srcs = {read_json(os.path.join(k, "run.json"), {}).get("src") for k in p["keep"]}
        if src and info.get("src_made") and src not in kept_srcs and os.path.isdir(src):
            rc = subprocess.run(["git", "-C", repo, "worktree", "remove", src], capture_output=True, text=True)
            say(f"worktree {src}: {'removed' if rc.returncode == 0 else 'kept (' + rc.stderr.strip()[:120] + ')'}")
        shutil.rmtree(path)
        removed.append(path)
        say(f"removed {path}")
        vdir = os.path.dirname(path)
        if os.path.isdir(vdir) and not os.listdir(vdir):
            os.rmdir(vdir)
    pubs = [x for x in published(state_root) if x["run"] not in removed]
    if not dry and os.path.isdir(state_root):
        write_json(os.path.join(state_root, "published.json"), pubs)
    return {"removed": removed, "kept": p["kept"], "keep": p["keep"]}
