#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Shared test binaries of Epic Wallet: one Linux debug bundle and one debug APK per app commit,
built once into a store on this host and reused by every agent and worktree.

  testbin.sh get [linux|apk] [--commit X] [--variant tor|notor] [--no-build]
        print the path of the binary for commit X (default: HEAD of the worktree you are in).
        A hit prints at once. A miss builds it once into the store, under the store's build
        lock (a second caller waits for the first and then reuses its build), and prints it.
        linux: the bundle directory (run <path>/epic_wallet); apk: the .apk file.
  testbin.sh refresh     what the timer runs: builds main (tor; linux and apk) when it has no
                         entry yet and moves `latest` to it. Skips while a tools/rel run holds
                         its lock or another build holds the store's lock.
  testbin.sh list        the entries, newest first
  testbin.sh prune       keep `latest` and the most recently used entries (TESTBIN_KEEP, 4)

Store: /tmp/epic-build/testbins/ (TESTBIN_STORE)
  <app12>-<lepic12>/manifest.json         app commit, LEPIC and lepic-flutter commits, and per
                                          artifact: built, sha256, size, LEPIC features, seconds
  <app12>-<lepic12>/<variant>/linux/      flutter build linux --debug -t lib/main_desktop.dart
  <app12>-<lepic12>/<variant>/app-debug.apk   flutter build apk --debug
  <app12>-<lepic12>/<variant>/build-<artifact>.log
  latest -> <entry of main>
Artifacts are read-only; copy one before changing it. Builds run in one worktree,
~/wfe-worktrees/testbins-build (detached, used by nothing else), under build-slot, one at a time.
The commit must be committed: uncommitted changes in your worktree are not in the binary.
Release builds never come from here (tools/rel, the 22.04 container).
Python 3 standard library only.
"""

import argparse
import datetime as dt
import fcntl
import glob
import hashlib
import json
import os
import shutil
import stat
import subprocess
import sys
import time
from pathlib import Path

HOME = Path.home()
STORE = Path(os.environ.get("TESTBIN_STORE", HOME / "epic-build" / "testbins"))
MAIN_REPO = Path(os.environ.get("WFE_REPO", HOME / "wallet-for-epic"))
BUILD_WT = Path(os.environ.get("TESTBIN_WORKTREE", HOME / "wfe-worktrees" / "testbins-build"))
KEEP = int(os.environ.get("TESTBIN_KEEP", "4"))
MIN_FREE_GB = float(os.environ.get("TESTBIN_MIN_FREE_GB", "12"))
REL_LOCKS = str(HOME / "epic-build" / "rel" / "*" / "run-*" / ".lock")
ARTIFACTS = {"linux": "linux", "apk": "app-debug.apk"}
VARIANTS = ("tor", "notor")
# systemd's PATH lacks ~/.local/bin, where build-slot lives
if str(HOME / ".local" / "bin") not in os.environ.get("PATH", "").split(":"):
    os.environ["PATH"] = f"{HOME / '.local' / 'bin'}:{os.environ.get('PATH', '/usr/bin:/bin')}"


def log(msg):
    print(f"testbin: {msg}", file=sys.stderr, flush=True)


def git(repo, *args, check=True):
    r = subprocess.run(["git", "-C", str(repo), *args], capture_output=True, text=True)
    if check and r.returncode != 0:
        raise SystemExit(f"testbin: git {' '.join(args)} failed: {r.stderr.strip()}")
    return r.stdout.strip()


def repo_of(cwd):
    """The worktree you are in when it is a wallet-for-epic checkout, else the main checkout."""
    r = subprocess.run(["git", "-C", str(cwd), "rev-parse", "--show-toplevel"],
                       capture_output=True, text=True)
    top = Path(r.stdout.strip()) if r.returncode == 0 else None
    if top and (top / "tools" / "lepic.rev").exists():
        return top
    return MAIN_REPO


def resolve(repo, rev):
    sha = git(repo, "rev-parse", "--verify", f"{rev}^{{commit}}")
    lepic = git(repo, "show", f"{sha}:tools/lepic.rev").strip()
    binding = git(repo, "show", f"{sha}:tools/lepic-flutter.rev", check=False).strip()
    return sha, lepic, binding


def entry_dir(sha, lepic):
    return STORE / f"{sha[:12]}-{lepic[:12]}"


def artifact_path(entry, variant, what):
    return entry / variant / ARTIFACTS[what]


def read_manifest(entry):
    try:
        return json.loads((entry / "manifest.json").read_text())
    except (OSError, ValueError):
        return None


def have(entry, variant, what):
    m = read_manifest(entry)
    return bool(m and f"{variant}/{what}" in m.get("artifacts", {})
                and artifact_path(entry, variant, what).exists())


def write_manifest(entry, m):
    tmp = entry / ".manifest.json.tmp"
    tmp.write_text(json.dumps(m, indent=2, sort_keys=True) + "\n")
    os.replace(tmp, entry / "manifest.json")


def main_sha():
    return git(MAIN_REPO, "rev-parse", "refs/heads/main")


def rel_busy():
    held = []
    for path in sorted(glob.glob(REL_LOCKS)):
        try:
            fd = os.open(path, os.O_RDONLY)
        except OSError:
            continue
        try:
            fcntl.flock(fd, fcntl.LOCK_SH | fcntl.LOCK_NB)
            fcntl.flock(fd, fcntl.LOCK_UN)
        except OSError:
            held.append(path)
        finally:
            os.close(fd)
    return held


def build_lock(wait=True):
    STORE.mkdir(parents=True, exist_ok=True)
    f = open(STORE / ".build.lock", "a+")
    try:
        fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        if not wait:
            f.close()
            return None
        f.seek(0)
        holder = f.read().strip()
        log(f"waiting for the build in progress ({holder or 'unknown'})")
        fcntl.flock(f, fcntl.LOCK_EX)
    f.seek(0)
    f.truncate()
    f.write(f"pid {os.getpid()} since {dt.datetime.now():%H:%M:%S}\n")
    f.flush()
    return f


def make_writable(path):
    for root, dirs, files in os.walk(path):
        os.chmod(root, os.stat(root).st_mode | stat.S_IWUSR)
        for n in files:
            p = os.path.join(root, n)
            if not os.path.islink(p):
                os.chmod(p, os.stat(p).st_mode | stat.S_IWUSR)


def make_readonly(path):
    if path.is_file():
        os.chmod(path, 0o444 | (os.stat(path).st_mode & 0o111))
        return
    for root, dirs, files in os.walk(path, topdown=False):
        for n in files:
            p = os.path.join(root, n)
            if not os.path.islink(p):
                os.chmod(p, os.stat(p).st_mode & ~0o222)
        os.chmod(root, os.stat(root).st_mode & ~0o222)


def remove(path):
    """Removes one exact path of the store (a file or a tree)."""
    path = Path(path)
    if not path.exists() and not path.is_symlink():
        return
    assert STORE in path.parents, path
    if path.is_dir() and not path.is_symlink():
        make_writable(path)
        shutil.rmtree(path)
    else:
        path.unlink()


def sha256_file(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def tree_sums(d):
    """Writes <d>/SHA256SUMS over every file in the tree and returns its own sha256."""
    lines = []
    for root, dirs, files in os.walk(d):
        dirs.sort()
        for n in sorted(files):
            p = Path(root) / n
            if p.is_symlink() or n == "SHA256SUMS":
                continue
            lines.append(f"{sha256_file(p)}  {p.relative_to(d)}")
    (d / "SHA256SUMS").write_text("\n".join(lines) + "\n")
    return sha256_file(d / "SHA256SUMS")


def size_of(p):
    if p.is_file():
        return p.stat().st_size
    return sum(f.stat().st_size for f in p.rglob("*") if f.is_file() and not f.is_symlink())


def latest_target():
    link = STORE / "latest"
    return (STORE / os.readlink(link)).resolve() if link.is_symlink() else None


def entries():
    out = [p for p in STORE.iterdir() if p.is_dir() and not p.is_symlink()
           and (p / "manifest.json").exists()] if STORE.is_dir() else []
    return sorted(out, key=last_used, reverse=True)


def last_used(entry):
    for n in (".used", "manifest.json"):
        try:
            return (entry / n).stat().st_mtime
        except OSError:
            continue
    return 0


def prune(keep=KEEP):
    """Keeps `latest` and the most recently used entries; call with the build lock held."""
    keep_set = {latest_target()}
    for e in entries():
        if len(keep_set - {None}) >= keep:
            break
        keep_set.add(e.resolve())
    for e in entries():
        if e.resolve() not in keep_set:
            log(f"pruning {e}")
            remove(e)
    # what a killed build left
    for t in STORE.glob("*/*/.tmp-*"):
        remove(t)


def free_gb():
    p = STORE
    while not p.exists():
        p = p.parent
    return shutil.disk_usage(p).free / 1e9


def ensure_worktree(sha):
    if not (BUILD_WT / ".git").exists():
        BUILD_WT.parent.mkdir(parents=True, exist_ok=True)
        git(MAIN_REPO, "worktree", "add", "--detach", str(BUILD_WT), sha)
    git(BUILD_WT, "checkout", "--quiet", "--force", "--detach", sha)
    # keep the LEPIC clones and the incremental build outputs; everything else untracked goes
    git(BUILD_WT, "clean", "-ffdxq", "-e", "app/third_party", "-e", "app/build",
        "-e", "app/.dart_tool", "-e", "app/android/.gradle")


def build(sha, lepic, binding, variant, wants):
    """Builds the artifacts in `wants` that the entry lacks; call with the build lock held."""
    entry = entry_dir(sha, lepic)
    wants = [w for w in wants if not have(entry, variant, w)]
    if not wants:
        return entry
    prune()
    if free_gb() < MIN_FREE_GB:
        raise SystemExit(f"testbin: only {free_gb():.1f} GB free under {STORE} (needs "
                         f"{MIN_FREE_GB:g}); free some space or lower TESTBIN_MIN_FREE_GB")
    ensure_worktree(sha)
    (entry / variant).mkdir(parents=True, exist_ok=True)
    notor = variant == "notor"
    define = " --dart-define=WFE_TOR=false" if notor else ""
    lepic_what = "all" if len(wants) == 2 else ("linux" if wants == ["linux"] else "android")
    steps = [". tools/env.sh", "tools/lepic.sh sync",
             f"{'WFE_TOR=0 ' if notor else ''}LEPIC_SHARED=1 tools/lepic.sh build {lepic_what}",
             "cd app", "flutter pub get"]
    if "linux" in wants:
        steps.append(f"flutter build linux --debug -t lib/main_desktop.dart{define}")
    if "apk" in wants:
        steps.append(f"flutter build apk --debug{define}")
    script = " && ".join(steps)
    logf = entry / variant / f".tmp-build-{'-'.join(wants)}.log"
    log(f"building {', '.join(wants)} ({variant}) of {sha[:12]} in {BUILD_WT}; log {logf}")
    env = dict(os.environ)
    for k in ("WFE_TOR", "LEPIC_NO_CACHE", "CARGO_TARGET_DIR"):
        env.pop(k, None)
    t0 = time.time()
    heavy = ["build-slot"] if shutil.which("build-slot") else []
    with open(logf, "w") as out:
        rc = subprocess.run(["nice", "-n", "10", "ionice", "-c3", *heavy, "bash", "-c", script],
                            cwd=BUILD_WT, env=env, stdout=out, stderr=subprocess.STDOUT).returncode
    seconds = round(time.time() - t0)
    if rc != 0:
        tail = logf.read_text(errors="replace").splitlines()[-25:]
        print("\n".join(tail), file=sys.stderr)
        raise SystemExit(f"testbin: the build failed (exit {rc}); full log {logf}")
    native = BUILD_WT / "app" / "third_party" / "lepic-flutter" / "native"
    features = {p.parent.name: p.read_text().strip()
                for p in sorted(native.glob("*/FEATURES"))}
    flutter_ver = subprocess.run(["bash", "-c", ". tools/env.sh && flutter --version --machine"],
                                 cwd=BUILD_WT, capture_output=True, text=True).stdout
    try:
        flutter_ver = json.loads(flutter_ver[flutter_ver.index("{"):]).get("frameworkVersion")
    except ValueError:
        flutter_ver = None
    m = read_manifest(entry) or {
        "app_commit": sha, "lepic_commit": lepic, "lepic_flutter_commit": binding,
        "app_subject": git(MAIN_REPO, "log", "-1", "--format=%s", sha), "artifacts": {}}
    srcs = {"linux": BUILD_WT / "app/build/linux/x64/debug/bundle",
            "apk": BUILD_WT / "app/build/app/outputs/flutter-apk/app-debug.apk"}
    for w in wants:
        dst = artifact_path(entry, variant, w)
        tmp = entry / variant / f".tmp-{w}"
        remove(tmp)
        if w == "linux":
            shutil.copytree(srcs[w], tmp, symlinks=True)
            digest = tree_sums(tmp)
        else:
            shutil.copy2(srcs[w], tmp)
            digest = sha256_file(tmp)
        make_readonly(tmp)
        remove(dst)
        os.rename(tmp, dst)
        want_feat = {t: f for t, f in features.items()
                     if (t == "x86_64-unknown-linux-gnu") == (w == "linux")}
        m["artifacts"][f"{variant}/{w}"] = {
            "path": str(dst.relative_to(entry)), "variant": variant,
            "built": dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "sha256": digest, "sha256_of": "SHA256SUMS" if w == "linux" else "file",
            "size": size_of(dst), "lepic_features": want_feat, "build_seconds": seconds,
            "flutter": flutter_ver, "log": f"{variant}/build-{w}.log"}
        shutil.copy2(logf, entry / variant / f"build-{w}.log")
    remove(logf)
    write_manifest(entry, m)
    return entry


def set_latest(entry):
    link = STORE / "latest"
    tmp = STORE / ".latest.tmp"
    if tmp.is_symlink() or tmp.exists():
        tmp.unlink()
    os.symlink(entry.name, tmp)
    os.replace(tmp, link)


def cmd_get(a):
    repo = repo_of(Path.cwd())
    sha, lepic, binding = resolve(repo, a.commit or "HEAD")
    if not a.commit and git(repo, "status", "--porcelain", "--untracked-files=no"):
        log(f"{repo} has uncommitted changes: they are not in the binary of {sha[:12]}")
    entry = entry_dir(sha, lepic)
    if not have(entry, a.variant, a.what):
        if a.no_build:
            raise SystemExit(f"testbin: no {a.what} ({a.variant}) for {sha[:12]} in {STORE}")
        lock = build_lock(wait=True)
        try:
            # the other caller may have built it while we waited
            build(sha, lepic, binding, a.variant, [a.what])
            if sha == main_sha() and have(entry, "tor", "linux") and have(entry, "tor", "apk"):
                set_latest(entry)
        finally:
            lock.close()
    (entry / ".used").touch()
    print(artifact_path(entry, a.variant, a.what))


def cmd_refresh(a):
    busy = rel_busy()
    if busy:
        log(f"skipped: a release run holds {busy[0]}")
        return
    sha, lepic, binding = resolve(MAIN_REPO, "refs/heads/main")
    entry = entry_dir(sha, lepic)
    if not (have(entry, "tor", "linux") and have(entry, "tor", "apk")):
        lock = build_lock(wait=False)
        if lock is None:
            log("skipped: another build holds the store's lock")
            return
        try:
            if rel_busy():
                log("skipped: a release run started")
                return
            build(sha, lepic, binding, "tor", ["linux", "apk"])
            set_latest(entry)
            prune()
        finally:
            lock.close()
    elif latest_target() != entry.resolve():
        set_latest(entry)
    log(f"main {sha[:12]}: {entry}")


def cmd_list(a):
    lt = latest_target()
    for e in entries():
        m = read_manifest(e)
        arts = ", ".join(sorted(m.get("artifacts", {})))
        mark = " (latest)" if e.resolve() == lt else ""
        print(f"{e.name}{mark}  {size_of(e) / 1e6:.0f} MB  [{arts}]  {m.get('app_subject', '')[:60]}")
    print(f"free: {free_gb():.1f} GB")


def cmd_prune(a):
    lock = build_lock(wait=True)
    try:
        prune()
    finally:
        lock.close()


def main():
    p = argparse.ArgumentParser(prog="testbin.sh", description=__doc__.split("\n\n")[0])
    sub = p.add_subparsers(dest="cmd", required=True)
    g = sub.add_parser("get")
    g.add_argument("what", nargs="?", default="linux", choices=sorted(ARTIFACTS))
    g.add_argument("--commit")
    g.add_argument("--variant", default="tor", choices=VARIANTS)
    g.add_argument("--no-build", action="store_true")
    g.set_defaults(fn=cmd_get)
    for name, fn in (("refresh", cmd_refresh), ("list", cmd_list), ("prune", cmd_prune)):
        sub.add_parser(name).set_defaults(fn=fn)
    a = p.parse_args()
    a.fn(a)


if __name__ == "__main__":
    main()
