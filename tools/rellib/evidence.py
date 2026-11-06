# SPDX-License-Identifier: Apache-2.0
"""Evidence tied to the artefacts (docs/RELEASING.md, "Evidence and rc-manifest.json").

G3 writes <run>/rc-manifest.json: the SHA-256 and size of every file the builds made (files/ and
extra/, after signing), and its hash, the hash of that list. The proofs record the bytes they
tested (status `tested`); update-trust takes a proof only when those bytes are the manifest's and
then keeps the run's evidence under <run>/evidence/<manifest hash>/ (the manifest, every proof,
the proof summary). The gate records the hash it showed the owner, and `tools/rel publish` refuses
when the files on disk no longer hash to it. A build that runs again changes the bytes, so the
old evidence stops applying: the engine resets every step that recorded other build bytes
(engine.inputs_digest) and a new manifest, new proofs and a new approval follow.
"""
import hashlib
import json
import os
import shutil
import subprocess

from .run import now_iso, read_json, write_json

MANIFEST = "rc-manifest.json"
DRIVERS_DIR = "tools/rellib/drivers"


def manifest_hash(files):
    """The hash of {name: sha256}: names and bytes only, never times."""
    flat = {n: f["sha256"] for n, f in sorted(files.items())}
    return hashlib.sha256(json.dumps(flat, sort_keys=True).encode()).hexdigest()


def artefact_paths(engine):
    """{name: path} of every file the run's builds made: outputs in files/, extras in extra/.
    A run that never publishes (tainted) lists only the builds that ran: the files in hand."""
    from .signer import never_published
    out = {}
    in_hand = never_published(engine.run)
    for s in engine.run.steps:
        if not engine.is_build(s) or (in_hand and engine.run.status(s.id)["status"] != "done"):
            continue
        for o in s.outputs:
            out[os.path.basename(o)] = os.path.join(engine.run.files, os.path.basename(o))
        for e in s.extras:
            out[e] = os.path.join(engine.run.extra, e)
    # A follow-up run's carried files and extras (tools/rel start --follow-up) ship too.
    for name in engine.info.get("carried") or {}:
        out[name] = os.path.join(engine.run.files, name)
    for name in engine.info.get("carried_extra") or {}:
        out[name] = os.path.join(engine.run.extra, name)
    return out


def write_manifest(engine):
    """Writes rc-manifest.json from the bytes on disk now; -> (hash, missing names)."""
    from .engine import sha256_file
    files, missing = {}, []
    for name, path in sorted(artefact_paths(engine).items()):
        if not os.path.isfile(path):
            missing.append(name)
            continue
        files[name] = {"sha256": sha256_file(path), "bytes": os.path.getsize(path),
                       "where": "extra" if path.startswith(engine.run.extra + os.sep) else "files"}
    h = manifest_hash(files)
    info = engine.info
    write_json(os.path.join(engine.run.path, MANIFEST), {
        "run_id": info["run_id"], "version": info["version"], "commit": info["commit"], "written": now_iso(),
        "hash": h, "files": files})
    return h, missing


def read_manifest(run):
    return read_json(os.path.join(run.path, MANIFEST))


def current_hash(run, manifest):
    """The hash of the manifest's files as they are on disk now (None for a file gone)."""
    from .engine import sha256_file
    files = {}
    for name, f in manifest["files"].items():
        p = os.path.join(run.path, f.get("where", "files"), name)
        files[name] = {"sha256": sha256_file(p) if os.path.isfile(p) else None}
    return manifest_hash(files)


def stale_proofs(engine, manifest):
    """[(step id, why)] for proofs done on other bytes than the manifest's."""
    out = []
    for s in engine.run.steps:
        if not s.proof:
            continue
        st = engine.run.status(s.id)
        if st.get("status") != "done" or st.get("dry") or st.get("tested") is None:
            continue
        about = engine.platform_files(s)  # a file of a build the proof never waited for is not its business
        for name, sha in st["tested"].items():
            if name not in about:
                continue
            want = (manifest["files"].get(name) or {}).get("sha256")
            if sha != want:
                out.append((s.id, f"{name} tested as {str(sha)[:12]}, the release has {str(want)[:12]}"))
                break
    return out


def keep(engine, manifest, summary):
    """<run>/evidence/<hash>/: the manifest, the proof summary and every proof with its status."""
    d = os.path.join(engine.run.path, "evidence", manifest["hash"])
    os.makedirs(os.path.join(d, "proofs"), exist_ok=True)
    shutil.copyfile(os.path.join(engine.run.path, MANIFEST), os.path.join(d, MANIFEST))
    write_json(os.path.join(d, "proof-summary.json"), summary)
    for s in engine.run.steps:
        if not s.proof:
            continue
        st = engine.run.status(s.id)
        proof = read_json(os.path.join(engine.run.step_dir(s.id), "out", "proof.json"))
        write_json(os.path.join(d, "proofs", f"{s.id}.json"), {"status": st, "proof": proof})
    return d


def publish_refusal(run):
    """Why the publish phase must not start (the approved bytes are not the ones on disk), or None.
    Runs without a manifest (rollbacks, runs from before rc-manifest.json) are not checked here."""
    m = read_manifest(run)
    if not m:
        return None
    gate = (run.info.get("gates") or {}).get("publish") or {}
    approved = gate.get("rc_manifest")
    if approved and approved != m["hash"]:
        return (f"the publish gate approved rc-manifest {approved[:16]}, this run's is now {m['hash'][:16]}: "
                "a build ran again after the approval; resume the run for new evidence and a new approval")
    now = current_hash(run, m)
    if now != m["hash"]:
        return (f"the release files on disk no longer match rc-manifest.json ({m['hash'][:16]} → {now[:16]}): "
                "nothing is published; resume the run (G3 and the proofs run again)")
    return None


def _git(repo, *args):
    try:
        p = subprocess.run(["git", "-C", repo, "-c", "core.quotepath=off", *args], capture_output=True, timeout=30)
    except (OSError, subprocess.SubprocessError):
        return None
    return p.stdout if p.returncode == 0 else None


def driver_record(repo):
    """The G4 drivers as they are on disk: {"commit": HEAD of repo, "dirty": None or a short
    SHA-256 of the drivers' uncommitted changes (git diff HEAD, and the name and bytes of each
    untracked file under tools/rellib/drivers)}. A proof says which driver code made it; two attempts
    with another record ran different drivers (an edit between attempts, 26.10.26 run-4)."""
    head = _git(repo, "rev-parse", "HEAD")
    commit = head.decode().strip() if head else None
    diff = _git(repo, "diff", "HEAD", "--", DRIVERS_DIR)
    untracked = _git(repo, "ls-files", "--others", "--exclude-standard", "-z", "--", DRIVERS_DIR)
    if diff is None and untracked is None:
        return {"commit": commit, "dirty": None}
    h = hashlib.sha256(diff or b"")
    for name in sorted(n for n in (untracked or b"").decode("utf-8", "replace").split("\0") if n):
        if "__pycache__" in name.split("/") or name.endswith(".pyc"):
            continue
        try:
            with open(os.path.join(repo, name), "rb") as f:
                data = f.read()
        except OSError:
            continue
        h.update(b"\0untracked\0" + name.encode() + b"\0" + data)
    dirty = None if h.digest() == hashlib.sha256(b"").digest() else h.hexdigest()[:12]
    return {"commit": commit, "dirty": dirty}


def driver_label(rec):
    """`abc1234` or `abc1234+dirty`: a driver record in a note."""
    return f"{(rec.get('commit') or '?')[:7]}" + ("+dirty" if rec.get("dirty") else "")
