# SPDX-License-Identifier: Apache-2.0
"""Rollback is a release going forward. Installed apps keep the highest manifest serial they
accepted (btlabs-public FORMAT.md section 5) and refuse a lower one, so putting the previous
update.json back on the server is ignored by every app that already read the bad one. Instead
`tools/rel rollback` takes the previous release (kept by retention: files, manifests and their
payloads), signs its payloads again with a NEW, higher serial, and publishes downloads, page and
manifests through the same steps, behind its own gate ("rollback").

Desktops compare version names only (no build number), so a desktop that already installed the
bad version is not offered the older one: it needs the next version (as 26.10.24-r2 showed). The
report says so.

GitHub (release.toml publish.github): when the bad or the good release had it on, the
re-signed update-v2.json also replaces the asset on the latest GitHub Release (the bad
release's, which stays; GitHub only mirrors). The page links the good release's GitHub Release
only when that release had it on."""
import datetime as dt
import json
import os
import shutil

from .config import render
from .graph import Step, build_graph, topo
from .resign import new_serial
from .run import Run, read_json, write_json


def choose(state_root, to=None):
    from .retention import published
    pubs = [p for p in published(state_root) if os.path.isdir(p["run"])]
    if not pubs:
        raise ValueError("nothing published by tools/rel yet: no release to roll back")
    bad = pubs[-1]
    if to:
        cands = [p for p in pubs if p["version"] == to and p["version"] != bad["version"]]
        if not cands:
            raise ValueError(f"{to} is not a kept, published release other than the current {bad['version']} "
                             f"(kept: {', '.join(sorted({p['version'] for p in pubs}))})")
        return bad, cands[-1]
    older = [p for p in pubs if p["version"] != bad["version"]]
    if not older:
        raise ValueError(f"no previous release kept besides {bad['version']}")
    return bad, older[-1]


def make_run(state_root, pipeline, hosts, repo, bad, good, test, base_ctx):
    """A run of kind rollback for the good release's version, with its files and payloads."""
    good_run = Run(good["run"])
    info = {
        "version": good["version"], "commit": good_run.info["commit"], "kind": "rollback",
        "replaces": bad["version"], "replaces_run": bad["run_id"], "test": bool(test),
        "target": "scratch" if test else good_run.info["scope"]["publish"]["target"],
        "scope": dict(good_run.info["scope"], test=bool(test)), "src": repo, "src_made": False,
        "previous": {"dir": os.path.join(bad["run"], "files"), "version": bad["version"]},
    }
    if test:
        info["scope"]["publish"] = dict(info["scope"]["publish"], target="scratch")
    path, run_id = Run.next_path(state_root, good["version"])
    ctx = dict(base_ctx, version=good["version"], commit=info["commit"], short=info["commit"][:7], run_id=run_id,
               run=path, files=f"{path}/files", extra=f"{path}/extra", manifests=f"{path}/manifests",
               src=repo, target=info["target"], scratch=f"{path}/scratch/target", notes_file=f"{path}/notes.txt",
               previous_dir=info["previous"]["dir"], previous_version=bad["version"], previous_ref="")
    full = build_graph(pipeline, info["scope"], ctx)
    keep = ("publish-downloads", "publish-page", "publish-manifests", "verify-live")
    steps = [s for s in full if s.base in keep]
    # The bad release may have put its update-v2.json on GitHub: the rollback replaces it there
    # too, even when the good release was published without the switch.
    bad_scope = Run(bad["run"]).info.get("scope", {}) if os.path.isdir(bad["run"]) else {}
    github = any(sc.get("publish", {}).get("github") for sc in (bad_scope, info["scope"]))
    for s in steps:
        if s.base == "publish-manifests" and github:
            s.env = dict(s.env, GITHUB_UPDATE_JSON="1")
    resign = Step(id="rollback-resign", base="rollback-resign", kind="builtin", title="Re-sign the previous release (higher serial)",
                  host="signer", lane="local", platforms=[])
    gate = Step(id="rollback-gate", base="rollback-gate", kind="gate", title="Rollback gate", host="local", lane="local",
                platforms=[], needs=["rollback-resign"])
    for s in steps:
        if s.base == "publish-downloads":
            s.needs = ["rollback-gate"]
        else:
            s.needs = [n for n in s.needs if n in {x.id for x in steps}]
    from .config import scope_toml
    run = Run.create(state_root, good["version"], info, scope_toml(info["scope"]), topo([resign, gate] + steps))
    from .engine import place
    for name in os.listdir(good_run.files):
        place(os.path.join(good_run.files, name), os.path.join(run.files, name))
    for name in ("update.payload.json", "update-v2.payload.json", "update-legacy.json"):
        p = os.path.join(good_run.path, "manifests", name)
        if os.path.isfile(p):
            shutil.copy2(p, os.path.join(run.path, "manifests", name))
    run.event("run", "rollback", replaces=bad["version"], to=good["version"])
    return run


def resign(engine, step, say):
    """Builtin rollback-resign: the kept payloads, with a fresh serial above every serial an app
    may hold (the live manifests' and the bad release's), signed and verified. With a signer
    ([host.signer] endpoint) both are signed there in one request the owner approves; the key here
    is then never read, and the run's signer.json makes publish-downloads sign SHA256SUMS too."""
    from .builtins import keyring_for, payload_of, fetch, sh
    import base64
    import tomllib
    run, info = engine.run, engine.info
    m = os.path.join(run.path, "manifests")
    floors = []
    bad_run = Run.find(os.path.dirname(os.path.dirname(run.path)), info.get("replaces_run")) if info.get("replaces_run") else None
    if bad_run:
        for n in ("update.json", "update-v2.json"):
            p = os.path.join(bad_run.path, "manifests", n)
            if os.path.isfile(p):
                floors.append(payload_of(p).get("serial"))
    src = info["src"]
    cfg = os.path.join(src, "app/assets/config/app-config.toml")
    if not info.get("test"):
        old = tomllib.load(open(os.path.join(src, "app/tool/config/old-update.toml"), "rb"))["old_update"]
        new = tomllib.load(open(cfg, "rb"))["updates"]
        for url in (old["manifest"], new["manifests"][0]):
            try:
                live = json.loads(fetch(url))
                floors.append(json.loads(base64.b64decode(live["payload"])).get("serial"))
            except Exception as e:
                say(f"warn: {url} unreadable ({e})")
    serial = new_serial(*floors)
    now = dt.datetime.fromtimestamp(serial, dt.timezone.utc)
    issued = now.strftime("%Y-%m-%dT%H:%M:%SZ")
    expires = (now + dt.timedelta(days=engine.pipeline.manifest_days())).strftime("%Y-%m-%dT%H:%M:%SZ")
    if engine.dry:
        say(f"dry run: would re-sign with serial {serial} (floors {floors})")
        return {"status": "done", "note": f"dry run: serial {serial}", "dry": True}
    keyring, bp = keyring_for(engine)
    tool = os.path.join(bp, "tool/btlabs_sign.py")
    from . import signer as btsign
    use_signer = bool(btsign.endpoint(engine.hosts)) and not info.get("test")
    if use_signer:
        btsign.write_run_file(engine)
        key = None
    elif info.get("test"):
        key = os.path.join(bp, "testdata/keys/test-a.key")
        sh(["python3", tool, "keyring", "--out", keyring, os.path.join(bp, "testdata/keys/test-a.pub.json")], say)
    else:
        key = engine.hosts["host"].get("signer", {}).get("signing_key",
                                                           os.path.expanduser("~/.config/btlabs/signing/btlabs-2026-a.key"))
    pairs = (("update.payload.json", "update.json", []),
             ("update-v2.payload.json", "update-v2.json", ["--app-config", cfg]))
    jobs = []
    for pname, ename, extra in pairs:
        pp = os.path.join(m, pname)
        if not os.path.isfile(pp):
            return {"status": "failed", "note": f"the kept release has no {pname}: cannot re-sign"}
        pl = read_json(pp)
        pl.update(serial=serial, issued_at=issued, expires_at=expires)
        write_json(pp, pl)
        if use_signer:
            jobs.append({"op": "update-manifest", "payload": pp, "out": ename, **({"app_config": cfg} if extra else {})})
            continue
        rc, _ = sh(["python3", tool, "sign", "--type", "update", "--key", key, "--keyring", keyring,
                    "--payload", pp, "--out", os.path.join(m, ename)] + extra, say)
        if rc != 0:
            return {"status": "failed", "note": f"signing {ename} failed"}
    if use_signer:
        for _, ename, _ in pairs:
            if os.path.exists(os.path.join(m, ename)):
                os.remove(os.path.join(m, ename))
        try:
            btsign.client(engine, say).sign(info["version"], jobs, m, label=f"ROLLBACK to {info['version']}")
        except Exception as e:
            return {"status": "failed", "note": f"signer: {e}"}
    for _, ename, extra in pairs:
        rc, _ = sh(["python3", tool, "verify", "--type", "update", "--keyring", keyring,
                    "--envelope", os.path.join(m, ename)] + extra, say)
        if rc != 0:
            return {"status": "failed", "note": f"{ename} does not verify"}
    note = (f"{info['version']} re-signed with serial {serial} (above {max([f for f in floors if f] or [0])}). "
            f"Desktops already on {info.get('replaces')} compare version names only: they need the next version.")
    return {"status": "done", "note": note, "serial": serial}
