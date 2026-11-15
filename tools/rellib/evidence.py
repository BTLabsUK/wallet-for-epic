# SPDX-License-Identifier: Apache-2.0
"""Evidence tied to the artefacts (docs/RELEASING.md, "Evidence and rc-manifest.json").

G3 writes <run>/rc-manifest.json: the SHA-256 and size of every file the builds made (files/ and
extra/, after signing), and its hash, the hash of that list. The gate records the hash it showed
The owner, and `tools/rel publish` refuses when the files on disk no longer hash to it. A build that
runs again changes the bytes: the engine resets every step that recorded other build bytes
(engine.inputs_digest), and a new manifest and a new approval follow.
"""
import hashlib
import json
import os

from .run import now_iso, read_json, write_json

MANIFEST = "rc-manifest.json"


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
                "nothing is published; resume the run (G3 runs again)")
    return None

