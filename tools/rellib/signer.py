# SPDX-License-Identifier: Apache-2.0
"""The release signer (tools/signer, btsign) as tools/rel sees it.

One setting names it: `endpoint` under [host.signer] of release-hosts.toml. Set, every signature
of a release is made there after the owner's code in Telegram (docs/RELEASING.md, "Signer"): the
Android files (step sign-android) and, on the same code, the manifests and the downloads'
SHA256SUMS (step manifests: the follow-up sign-android's request declares, CONTINUE_FILE), a
rollback's manifests. Unset, the old path: the keys on this machine (host.signer's signing_key
and android_key_properties), and sign-android only checks the builds signed themselves.

Approval: with the credential file `approve_token` of [host.signer] (default
~/.config/btlabs/signer-approve.token, owner-only) the signer approves this machine's requests
itself (btsign 1.2.0, the owner 2026-11-04: no TOTP code), and sign-android signs as soon as every
file it needs is in. Without it, the owner's code as before.

A run that never publishes (tainted: a step ran with unmet needs) signs only the Android files in
hand and declares no manifests.

Preflight writes <run>/signer.json (endpoint, the hosts file, the client; never a secret) so the
step scripts, which tools/rel does not hand the hosts file, follow the same signer."""
import importlib.util
import json
import os
import shutil
import subprocess

from .run import now_iso, write_json

CLIENT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "signer", "btsign_client.py")
RUN_FILE = "signer.json"
SIGNED_FILE = "signed.json"
# The request sign-android left open for the manifests step: {request, version, then, continue_by}.
CONTINUE_FILE = "signer-continue.json"
# What the manifests step signs on sign-android's code (steps/manifests.sh; the outputs of
# app/tool/release_android.sh and server_sums.py there).
MANIFEST_FOLLOW = [{"op": "update-manifest", "out": "update.json"},
                   {"op": "update-manifest", "out": "update-v2.json"},
                   {"op": "minisign", "out": "SHA256SUMS.sig"}]


def settings(hosts):
    return hosts["host"].get("signer", {})


def endpoint(hosts):
    return (settings(hosts).get("endpoint") or "").strip()


def client_module():
    spec = importlib.util.spec_from_file_location("btsign_client", CLIENT)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def client(engine, say):
    """The signer client for this run's hosts file (tests replace this function)."""
    return client_module().Client(settings(engine.hosts), say=say)


def approve_token(hosts):
    """[host.signer] approve_token, else REL_SIGNER_APPROVE_TOKEN (the tests point it into their
    temp dir), else the machine's ~/.config/btlabs/signer-approve.token."""
    return os.path.expanduser(settings(hosts).get("approve_token") or os.environ.get("REL_SIGNER_APPROVE_TOKEN")
                              or "~/.config/btlabs/signer-approve.token")


def auto_approve(engine):
    """True when the signer approves this machine's requests on its credential (no code)."""
    return os.path.isfile(approve_token(engine.hosts))


def never_published(run):
    """A tainted run never publishes (tools/rel refuses its gate)."""
    return bool(run.info.get("tainted"))


def write_run_file(engine):
    p = os.path.join(engine.run.path, RUN_FILE)
    if endpoint(engine.hosts):
        write_json(p, {"endpoint": endpoint(engine.hosts), "hosts": engine.hosts["file"], "client": CLIENT})
    elif os.path.exists(p):
        os.remove(p)


def preflight_checks(engine, ok, bad, keyring):
    """G1 with a signer: /info must hold exactly the shipped rank-1 key (and keyring) and G3's
    certificate, and this machine must have the client token."""
    try:
        c = client(engine, lambda *a: None)
        problems = c.check(engine.repo, keyring)
    except Exception as e:  # unreachable, no token, a bad answer: all fail closed
        bad(f"signer {endpoint(engine.hosts)}: {e}")
        return
    for p in problems:
        bad(f"signer: {p}")
    if not problems:
        ok(f"signer {endpoint(engine.hosts)} holds the shipped rank-1 key and G3's certificate")
    tok = os.path.expanduser(settings(engine.hosts).get("client_token", "~/.config/btlabs/signer-client.token"))
    (ok if os.path.isfile(tok) else bad)(f"signer client token ({tok}, not read)")


# ---- sign-android -------------------------------------------------------------------------------

def android_targets(engine):
    """[(step, key, path)]: every file the Android steps of this run made, published or kept
    (the emulator APK and the Play bundle too). key is how the step recorded it."""
    run, out = engine.run, []
    for s in run.steps:
        if s.base not in ("build-android", "build-play"):
            continue
        for o in s.outputs:
            out.append((s, os.path.basename(o), os.path.join(run.files, os.path.basename(o))))
        for e in s.extras:
            out.append((s, e, os.path.join(run.extra, e)))
    return out


def cert_of(path, tools):
    """The SHA-256 of the certificate a release file is signed with, or None."""
    if path.endswith(".aab"):
        cmd = [tools["keytool"], "-printcert", "-jarfile", path]
        mark = "SHA256: "
    else:
        cmd = [tools["apksigner"], "verify", "--print-certs", path]
        mark = "certificate SHA-256 digest: "
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=300).stdout
    except (OSError, subprocess.TimeoutExpired):
        return None
    # apksigner prints "Signer #1 certificate SHA-256 digest: <hex>", keytool "SHA256: AB:CD:..."
    for line in out.splitlines():
        if mark in line:
            return line.split(mark, 1)[1].strip().replace(":", "").lower()
    return None


def android_tools():
    from .builtins import build_tools
    bt = build_tools()
    return {"apksigner": os.path.join(bt, "apksigner") if bt else "apksigner", "keytool": shutil.which("keytool") or "keytool"}


def read_signed(run):
    try:
        with open(os.path.join(run.path, SIGNED_FILE), encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return {}


def manifests_follow(engine):
    """True when the manifests step of this run signs through the signer: then sign-android's
    request declares them and one code covers both. A TEST run signs its manifests with the
    test key, a run without manifests signs none."""
    return (bool(endpoint(engine.hosts)) and not engine.info.get("test") and not never_published(engine.run)
            and any(s.base == "manifests" for s in engine.run.steps))


def accepted_change(run, name, recorded, actual):
    """True when G3 may take a file whose hash differs from the one its step recorded: the
    signer signed exactly that build into exactly these bytes (sign-android's signed.json)."""
    e = read_signed(run).get(name)
    return bool(e and recorded and e.get("unsigned_sha256") == recorded and e.get("sha256") == actual)


def sign_now(engine):
    """True when sign-android may ask the signer for the owner's code now: [sign] when = "inline"
    (the code is asked as soon as every build is in, and the step waits up to 35 min for it), or a
    run where he said he is ready (`tools/rel sign`, or `tools/rel start --sign-inline`)."""
    when = (getattr(engine.pipeline, "sign", None) or {}).get("when", "inline")
    return when == "inline" or bool(engine.info.get("sign_requested")) or auto_approve(engine)


def wait_for_sign(engine, step, todo, say):
    """[sign] when = "on-demand": the request (and so the code) is bound to the exact bytes, so it
    can only be made once every build is in, and the owner may not be there then. Instead of holding
    a request open for 35 min, the step waits (exit 10) with every other lane going on, and he is
    told once; `tools/rel sign` makes the request when he is ready and the run carries on."""
    rid = engine.info["run_id"]
    say(f"{len(todo)} Android file(s) ready to sign; waiting for `tools/rel sign --run {rid}`")
    st = engine.run.status(step.id)
    if engine.relmsg and not st.get("sign_notified"):
        engine.relmsg.alert(f"Android files of {engine.info['version']} ready to sign", step=step.id,
                            detail=f"{len(todo)} file(s). The other checks go on meanwhile.",
                            expects=f"when you can enter the code: tools/rel sign --run {rid} (or tell the operator)",
                            key=f"{rid}/{step.id}/ready")
        engine.run.set_status(step.id, sign_notified=True)
    return {"status": "waiting", "note": f"ready to sign {len(todo)} Android file(s): "
                                         f"tools/rel sign --run {rid} when the owner can enter the code"}


def sign_android(engine, step, say):
    from .builtins import page_kinds
    from .engine import sha256_file
    run, info = engine.run, engine.info
    _, cert = page_kinds(engine.repo)
    targets = android_targets(engine)
    if engine.dry:
        for _, key, _ in targets:
            say(f"would sign {key}" if endpoint(engine.hosts) else f"would check {key} is signed")
        return {"status": "done", "note": f"dry run: {len(targets)} Android file(s)", "dry": True}
    problems, todo, absent = [], [], []
    signed = read_signed(run)
    for s, key, path in targets:
        st = run.status(s.id)
        if st["status"] != "done" and never_published(run):
            absent.append(key)  # never published: the Android files in hand are enough
            say(f"not in this run: {key} ({s.id} is {st['status']})")
            continue
        if st["status"] != "done":
            problems.append(f"{key}: its step {s.id} is {st['status']}")
            continue
        if not os.path.isfile(path):
            problems.append(f"{key}: missing")
            continue
        recorded = st.get("outputs", {}).get(key, {}).get("sha256")
        actual = sha256_file(path)
        if signed.get(key, {}).get("sha256") == actual and signed[key].get("unsigned_sha256") == recorded:
            say(f"already signed {key} {actual[:16]}")
        elif recorded != actual:
            problems.append(f"{key}: changed since {s.id} recorded it")
        else:
            todo.append((s, key, path, actual))
    if problems:
        for p in problems:
            say("FAIL", p)
        return {"status": "failed", "note": f"{len(problems)} problem(s): " + "; ".join(problems)[:300]}
    targets = [t for t in targets if t[1] not in absent]
    if not targets:
        return {"status": "failed", "note": "no Android file in hand to sign"}
    tools = android_tools()
    if not endpoint(engine.hosts):
        # The old path: Gradle signed with the key on this machine. Check, sign nothing.
        bad = [key for _, key, path, _ in todo if cert_of(path, tools) != cert]
        for key in bad:
            say("FAIL", f"{key}: not signed by the release key {cert[:12]}…")
        if bad:
            return {"status": "failed", "note": f"{len(bad)} file(s) not signed by the release key: " + ", ".join(bad)[:250]}
        return {"status": "done", "note": f"no signer endpoint: {len(todo)} file(s) signed in the build, checked"}
    if not todo:
        return {"status": "done", "note": f"{len(targets)} Android file(s) already signed"}
    if not sign_now(engine):
        return wait_for_sign(engine, step, todo, say)
    # The work folder stays between tries: when the signer already returned these files for
    # exactly these builds (its receipt in out/), a retry checks them again instead of opening
    # a new request (no second code).
    work = os.path.join(run.step_dir(step.id), "signer")
    inp, outp = os.path.join(work, "in"), os.path.join(work, "out")
    os.makedirs(inp, exist_ok=True)
    jobs, names = [], {}
    for s, key, path, unsigned in todo:
        name = os.path.basename(key)
        if name in names:
            return {"status": "failed", "note": f"two Android files are called {name}"}
        names[name] = (s, key, path)
        copy = os.path.join(inp, name)
        if not os.path.isfile(copy) or sha256_file(copy) != unsigned:
            shutil.copyfile(path, copy)
        jobs.append({"op": "aab" if name.endswith(".aab") else "apk", "file": copy, "out": name})
    # One code per release: with manifests in this run the same request declares them, and the
    # manifests step signs them on this code (CONTINUE_FILE) once the signed hashes are in.
    then = MANIFEST_FOLLOW if manifests_follow(engine) else None
    label = (f"Android + manifests {info['version']}" if then else f"Android {info['version']}") \
        + (" (TEST run)" if info.get("test") else " (never published)" if never_published(run) else "")
    cont = os.path.join(run.path, CONTINUE_FILE)
    if os.path.exists(cont):
        os.remove(cont)
    try:
        c = client(engine, say)
        if then:
            # The release's other files (the desktop builds, every build is in): the owner's message
            # lists them, and the follow-up's manifests may name no other.
            android = {os.path.basename(key) for _, key, _ in targets}
            expect = sorted(os.path.join(run.files, f) for f in os.listdir(run.files)
                            if f not in android and f not in ("SHA256SUMS", "provenance.json", "sbom.cdx.json"))
            st = c.sign(info["version"], jobs, outp, label=label, then=then, expect=expect, run_id=info["run_id"])
        else:
            st = c.sign(info["version"], jobs, outp, label=label, run_id=info["run_id"])
    except Exception as e:
        return {"status": "failed", "note": f"signer: {e}"}
    if then and isinstance(st, dict) and st.get("id"):
        write_json(cont, {"request": st["id"], "version": info["version"], "then": then,
                          "continue_by": st.get("continue_by")})
    for name, (s, key, path) in names.items():
        got = os.path.join(outp, name)
        if cert_of(got, tools) != cert:
            return {"status": "failed", "note": f"{name}: the signer's file is not signed by {cert[:12]}…"}
    for s, key, path, unsigned in todo:
        got = os.path.join(outp, os.path.basename(key))
        h = sha256_file(got)
        os.replace(got, path)
        signed[key] = {"step": s.id, "unsigned_sha256": unsigned, "sha256": h, "bytes": os.path.getsize(path),
                       "signed": now_iso()}
        write_json(os.path.join(run.path, SIGNED_FILE), signed)
        say(f"signed {key} {h[:16]}")
    shutil.rmtree(work, ignore_errors=True)
    return {"status": "done", "note": f"{len(todo)} Android file(s) signed by the signer, certificate {cert[:12]}…"
                                      + (f"; not in this run: {', '.join(absent)}" if absent else "")}
