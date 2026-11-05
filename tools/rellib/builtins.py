# SPDX-License-Identifier: Apache-2.0
"""Steps tools/rel does itself: the gates (G0 scope, G1 preflight, G3 artefacts, G4 update trust
and manifest checks, G5 publish, G6 read back), the source checkout, cleanup, and the scratch
publish target (a folder in the run that stands in for the server, page, GitHub and manifests).

Every gate fails closed: what it cannot check counts as failed, never as passed."""
import datetime as dt
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
import time
import tomllib
import urllib.request

from . import guards, health, hosted
from .config import PLATFORMS, scope_summary
from .run import Run, now_iso, read_json, write_json


def run(engine, step, log):
    name = step.scratch if (step.kind == "publish" and engine.info.get("target") == "scratch") else step.base
    fn = {
        "scope": scope, "preflight": preflight, "source": source, "artefacts": artefacts,
        "trust-manifest": trust_manifest, "update-trust": update_trust, "publish-gate": publish_gate,
        "verify-live": verify_live, "cleanup": cleanup_step,
        "scratch_downloads": scratch_downloads, "scratch_page": scratch_page, "scratch_source": scratch_source,
        "scratch_manifests": scratch_manifests, "scratch_prune": scratch_prune, "scratch_noop": scratch_noop,
        "rollback-gate": publish_gate, "rollback-resign": _resign, "sign-android": _sign_android,
        "hosted-dispatch": hosted_dispatch,
    }.get(name)
    if fn is None:
        return {"status": "failed", "note": f"no builtin {name!r}"}
    with open(log, "a", encoding="utf-8") as f:
        def say(*a):
            f.write(" ".join(str(x) for x in a) + "\n")
            f.flush()
        return fn(engine, step, say)


def hosted_dispatch(engine, step, say):
    return hosted.dispatch(engine, step, say)


def built_by(engine, s):
    """Who built a release file: {stage}/built_by.json of a hosted build (of the run it was reused
    from, when reused), else a local build."""
    st = engine.run.status(s.id)
    src = st.get("reused_from") or {}
    out = {"via": "local"}
    try:
        stage = engine.run.step_dir(s.id)
        if src.get("kind") == "run":
            stage = Run.find(os.path.dirname(os.path.dirname(engine.run.path)), src["label"]).step_dir(s.id)
        got = read_json(os.path.join(stage, "out", "built_by.json"))
        if isinstance(got, dict) and got.get("via"):
            out = got
    except Exception:
        pass
    if src:
        out = dict(out, reused_from=src.get("label"))
    return out


def _resign(engine, step, say):
    from .rollback import resign
    return resign(engine, step, say)


def _sign_android(engine, step, say):
    from .signer import sign_android
    return sign_android(engine, step, say)


def sh(cmd, say, cwd=None, env=None, timeout=600, check=False):
    full = dict(os.environ)
    full.update(env or {})
    p = subprocess.run(cmd, cwd=cwd, env=full, capture_output=True, text=True, timeout=timeout,
                       shell=isinstance(cmd, str), executable="/bin/bash" if isinstance(cmd, str) else None)
    out = (p.stdout + p.stderr).strip()
    if out:
        say(out[-4000:])
    if check and p.returncode != 0:
        raise RuntimeError(f"{cmd if isinstance(cmd, str) else ' '.join(cmd)}: exit {p.returncode}")
    return p.returncode, p.stdout


def scratch_dir(engine):
    d = os.path.join(engine.run.path, "scratch", "target")
    os.makedirs(d, exist_ok=True)
    return d


# ---- G0 scope -----------------------------------------------------------------------------------

def scope(engine, step, say):
    s = engine.info["scope"]
    say("scope:", scope_summary(s))
    for w in engine.info.get("warnings", []):
        say("warning:", w)
    if engine.relmsg:
        for p in PLATFORMS:
            if not s["platforms"].get(p):
                engine.relmsg.platform(p, "skipped", note="out of scope")
    return {"status": "done", "note": scope_summary(s)[:200]}


# ---- G1 preflight -------------------------------------------------------------------------------

def health_node(url, timeout=10):
    body = json.dumps({"jsonrpc": "2.0", "method": "get_tip", "params": [], "id": 1}).encode()
    req = urllib.request.Request(url.rstrip("/") + "/v2/foreign", data=body, headers={"content-type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return b'"height"' in r.read(4096)
    except Exception:
        return False


def health_epicbox(host, timeout=8):
    rc = subprocess.run(["curl", "-s", "-m", str(timeout), "-o", "/dev/null", "-w", "%{http_code}",
                         "-H", "Connection: Upgrade", "-H", "Upgrade: websocket", "-H", "Sec-WebSocket-Version: 13",
                         "-H", "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==", f"https://{host}:443/"],
                        capture_output=True, text=True)
    return rc.stdout.strip() == "101"


def pick(candidates, ok, override=None):
    tried = []
    for c in ([override] if override else []) + list(candidates):
        if c and c not in tried:
            tried.append(c)
            if ok(c):
                return c, tried
    return None, tried


def previous_candidates(root, version):
    """Every release G4 could update from, newest first: published runs, then the releases published
    by hand (published-by-hand.json: 26.10.23 and 26.10.24-r2 went out that way). [{dir, version, ref,
    extra?}]; `version` (the one being built) is left out."""
    from . import retention
    out = [{"dir": os.path.join(p["run"], "files"), "version": p["version"], "ref": p.get("tag", f"v{p['version']}"),
            "extra": os.path.join(p["run"], "extra")}
           for p in reversed(retention.published(root)) if p["version"] != version]
    out += [{"dir": os.path.expanduser(p["dir"]), "version": p["version"], "ref": p.get("tag", f"v{p['version']}")}
            for p in reversed(retention.published_by_hand(root))
            if p.get("version") != version and os.path.isdir(os.path.expanduser(p.get("dir", "")))]
    return out


def state_root_of(engine):
    # tools/rel doctor's throwaway run lives under .doctor/, not in the state root: it names the root.
    return engine.info.get("state_root") or os.path.dirname(os.path.dirname(engine.run.path))


def resolve_previous(engine):
    """The release G4 updates from: the scope's previous_dir, else the newest published run, else
    the newest release published by hand (without it every run failed G1 until someone passed
    --previous). This is the overall previous release (prune-downloads, rollback, the version
    check); a platform the newest one lacks has its own, see previous_by_platform."""
    s = engine.info["scope"]["proof"]
    if s.get("previous_dir"):
        d = os.path.expanduser(s["previous_dir"])
        v = s.get("previous_version") or os.path.basename(d.rstrip("/")).split("-r")[0]
        return {"dir": d, "version": v, "ref": s.get("previous_ref") or f"v{os.path.basename(d.rstrip('/'))}"}
    cands = previous_candidates(state_root_of(engine), engine.info["version"])
    return cands[0] if cands else {}


def previous_by_platform(scope, pipe, root, version, overall):
    """{platform: previous release} for every G4 lane platform: the newest published release whose
    folders hold that platform's input for all its variants in scope (a release without a platform
    leaves that platform's older release live, as build.py keep does). An explicit previous_dir is one
    release for every platform: {}. A platform no release serves gets the overall previous (G1 names
    the missing file)."""
    if scope["proof"].get("previous_dir"):
        return {}
    cands = previous_candidates(root, version)
    out = {}
    for plat in dict.fromkeys(p for p, _ in trust_lanes_of(scope, pipe)):
        vs = [v for p, v in trust_lanes_of(scope, pipe) if p == plat]
        if plat not in PREVIOUS_INPUTS:
            continue
        pick = next((c for c in cands if all(previous_input(c, plat, v)[0] for v in vs)), overall)
        if pick:
            out[plat] = pick
    return out


def previous_for(info, platform):
    """The previous release a platform's G4 steps use: its own choice, else the overall one."""
    return (info.get("previous_by_platform") or {}).get(platform) or info.get("previous", {})


def previous_text(prev, by_platform):
    """'26.11.1 at DIR', or per platform when they differ: 'android 26.11.1, linux 26.11.0, windows 26.11.0'."""
    if by_platform and any(b.get("version") != prev.get("version") for b in by_platform.values()):
        return ", ".join(f"{p} {b.get('version')}" for p, b in by_platform.items())
    return f"{prev.get('version')}"


# What each G4 lane installs first, per platform: (folders under the previous release, file names). The
# drivers look the same way (trust-android.sh apk_in, linux_platform.appimage, windows_platform.setup_exe);
# checked here so a missing input fails G1, not a lane after signing (26.10.26 run-4).
PREVIOUS_INPUTS = {
    "android": (("extra/emulator", "dir/emulator"), r"(?:bt-wallet-{v}{sfx}-android|epic-cash-mobile-{v}{sfx})-x86_64\.apk"),
    "linux": (("dir",), r"(?:bt-wallet-{v}{sfx}-linux|EpicCashDesktop-{v}{sfx})-x86_64\.AppImage"),
    "windows": (("dir",), r"(?:bt-wallet|epic-cash-desktop)-{v}{sfx}-windows-x64-setup\.exe"),
}


def previous_input(prev, platform, variant):
    """The previous release's file a G4 lane starts from, or None; -> (path or None, folders looked in)."""
    where, pattern = PREVIOUS_INPUTS[platform]
    rx = re.compile("^" + pattern.format(v=re.escape(prev.get("version", "")), sfx="-notor" if variant == "notor" else "") + "$")
    looked = []
    for w in where:
        base, _, sub = w.partition("/")
        if not prev.get(base):
            continue
        d = os.path.join(os.path.expanduser(prev[base]), sub)
        looked.append(d)
        hits = sorted(f for f in os.listdir(d) if rx.match(f)) if os.path.isdir(d) else []
        if hits:
            return os.path.join(d, hits[0]), looked
    return None, looked


def android_avd_module():
    spec = importlib.util.spec_from_file_location("trust_avd", os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                                                            "drivers", "android", "avd.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def trust_lanes(engine):
    return trust_lanes_of(engine.info["scope"], engine.pipeline)


def trust_lanes_of(s, pipe):
    """[(platform, variant)] of every G4 lane in scope: platform with a driver, not waived; proof variant."""
    from .graph import variants_for
    drivers = pipe.proof.get("drivers", {})
    variants = variants_for({"for_each": "proof_variant"}, s, pipe)
    return [(plat, v) for plat in PLATFORMS if s["platforms"].get(plat) and plat not in s["proof"]["waive"] and plat in drivers
            for v in variants]


def lane_inputs(engine, prev, ok, bad, by_platform=None):
    """Every G4 lane in scope: the previous release's file it installs (its platform's own previous
    release when by_platform has one), and for Android the emulator AVD it boots."""
    for plat, v in trust_lanes(engine):
        if plat in PREVIOUS_INPUTS:
            pv = (by_platform or {}).get(plat) or prev
            f, looked = previous_input(pv, plat, v)
            if f:
                ok(f"G4 {plat} {v}: previous {os.path.basename(f)} ({pv.get('version')})")
            else:
                bad(f"G4 {plat} {v}: no previous {pv.get('version')} file for the lane in {' or '.join(looked) or 'no folder'}")
            if plat == "android":
                avd = android_avd_module()
                name = os.environ.get("REL_ANDROID_AVD") or avd.avd_name(v)
                err = avd.avd_problem(name)
                (ok if not err else bad)(f"G4 android {v}: emulator AVD {name}" + (f": {err}" if err else ""))


def lane_seed_module():
    d = os.path.join(os.path.dirname(os.path.abspath(__file__)), "drivers")
    if d not in sys.path:
        sys.path.insert(0, d)
    from core import lane_seed
    return lane_seed


def lane_seeds(engine, ok, bad, say, p_spendable=None):
    """The permanent wallet of every G4 lane in scope (drivers/core/lane_seed.py): its seed present, private,
    valid, distinct and free, and P's spendable (EPIC text; None: not read) covering what the lanes take
    from it. A missing or shared seed fails; a balance not known warns. -> the warnings."""
    ls = lane_seed_module()
    lanes = [ls.lane_name(p, v) for p, v in trust_lanes(engine) if ls.lane_name(p, v) in ls.LANES]
    fv = engine.pipeline.proof.get("funds_variant", "tor")
    warns = []
    for level, line in ls.doctor(lanes, p_spendable, [x for x in lanes if x.endswith("-" + fv)]):
        if level == "FAIL":
            bad(line)
        elif level == "warn":
            warns.append(line)
            say("warn", line)
        else:
            ok(line)
    return warns


def windows_rig_module():
    spec = importlib.util.spec_from_file_location("win_rig", os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                                                          "drivers", "windows", "rig.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def rig_preflight(alias, variants, hosts_file, ok, bad, say, rig=None, report=None):
    """Every Windows rig session on the box, read before the run (drivers/windows/rig.py health): the
    variant's own rig, or a healthy one it falls back to, must be there; a dead rig is named with its
    cause. -> the warnings."""
    rig = rig or windows_rig_module()
    warns = []
    if report is None:
        try:
            report = rig.health(alias)
        except Exception as e:  # noqa: BLE001
            bad(f"Windows rig health not read on {alias}: {e}")
            return warns
    used = set()
    for v in variants:
        cands = rig.candidate_sessions(v, hosts_file)
        healthy = [k for k in cands if k in report and not report[k][1]]
        own = cands[0]
        if healthy and healthy[0] == own:
            ok(f"Windows rig for {v}: {rig.describe(own, [])}")
        elif healthy:
            warns.append(f"Windows rig for {v} is dead, the run falls back to rig {healthy[0]}: "
                         f"{rig.describe(own, report.get(own, (None, ['not found on the box']))[1])}")
            say("warn", warns[-1])
        else:
            bad(f"no healthy Windows rig for {v}: " + " | ".join(
                rig.describe(k, report.get(k, (None, ["not found on the box"]))[1]) for k in cands))
        used.update(cands)
    for k, (_, probs) in sorted(report.items()):
        if probs and k not in used:
            warns.append(f"Windows {rig.describe(k, probs)} (not used by this run)")
            say("warn", warns[-1])
    return warns


def preflight(engine, step, say):
    info, s = engine.info, engine.info["scope"]
    hosts, pipe = engine.hosts, engine.pipeline
    plats = [p for p in PLATFORMS if s["platforms"].get(p)]
    live = s["publish"]["target"] == "live" and not info.get("test")
    problems, warns = [], []

    def bad(msg):
        problems.append(msg)
        say("FAIL", msg)

    def ok(msg):
        say("ok  ", msg)

    root = os.path.dirname(os.path.dirname(engine.run.path))
    free = shutil.disk_usage(root).free / 1e9
    need = float(pipe.defaults.get("min_free_gb", 30))
    (ok if free >= need else bad)(f"disk: {free:.1f} GB free at {root} (need {need:.0f})")
    if not hosts.get("exists"):
        bad(f"no {hosts['file']}: copy release/hosts.example.toml there and fill it in")
    tools = ["git", "bash", "jq", "sha256sum", "rsync", "curl"]
    if "android" in plats:
        tools += ["flutter", "java"]
    if "linux" in plats:
        tools += ["docker"]
    if engine.relmsg and engine.relmsg.enabled:
        tools.append(engine.relmsg.bin)
    for t in tools:
        (ok if shutil.which(t) else bad)(f"tool {t}")
    if s["publish"]["target"] == "live" and not info.get("test"):
        # publish-source (tools/publish-github.sh) and publish-manifests (tools/publish-update-json.sh)
        # rewrite history with it, after the gate; a broken install there strands a half-published release.
        rc, _ = sh(["git", "filter-repo", "--version"], lambda *a: None, timeout=30)
        (ok if rc == 0 else bad)("tool git-filter-repo (publish-source, publish-manifests)")
    if "android" in plats and shutil.which("flutter"):
        want = open(os.path.join(engine.repo, "scripts/linux/flutter.version")).read().strip()
        rc, out = sh(["flutter", "--version", "--machine"], lambda *a: None, timeout=120)
        try:
            got = json.loads(out[out.index("{"):])["frameworkVersion"]
        except Exception:
            got = "?"
        (ok if got == want else bad)(f"flutter {got} (pin {want}, scripts/linux/flutter.version)")
        if not os.environ.get("ANDROID_HOME") and not os.path.isdir(os.path.expanduser("~/Android/Sdk")):
            bad("ANDROID_HOME / ~/Android/Sdk")
    signer = hosts["host"].get("signer", {})
    from . import signer as btsign
    if btsign.endpoint(hosts):
        # The release signer holds the keys (docs/RELEASING.md, "Signer"): none is read here.
        bp = signer.get("btlabs_public", os.path.expanduser("~/code/btlabs-public"))
        (ok if os.path.isfile(os.path.join(bp, "tool/btlabs_sign.py")) else bad)(f"btlabs_sign.py in {bp}")
        btsign.preflight_checks(engine, ok, bad, os.path.join(bp, "keys/btlabs-keyring.json"))
    elif signer.get("this_machine", True):
        if "android" in plats:
            kp = signer.get("android_key_properties", os.path.expanduser("~/.config/btlabs/android/key.properties"))
            (ok if os.path.isfile(kp) else bad)(f"Android release key ({kp})")
        if s["publish"]["manifests"]:
            bp = signer.get("btlabs_public", os.path.expanduser("~/code/btlabs-public"))
            (ok if os.path.isfile(os.path.join(bp, "tool/btlabs_sign.py")) else bad)(f"btlabs_sign.py in {bp}")
            if live:
                key = signer.get("signing_key", os.path.expanduser("~/.config/btlabs/signing/btlabs-2026-a.key"))
                (ok if os.path.isfile(key) else bad)("update signing key present (not read)")
    elif not signer.get("ssh"):
        bad("host.signer: this_machine = false needs ssh and repo")
    roles = {"windows": "windows" in plats, "web": live}
    for role, needed in roles.items():
        if not needed:
            continue
        alias = hosts["host"].get(role, {}).get("ssh")
        if not alias or alias.startswith("<"):
            bad(f"host.{role}.ssh is not set in {hosts['file']}")
            continue
        rc = subprocess.run(["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=10", alias, "exit"],
                            capture_output=True, timeout=40).returncode
        (ok if rc == 0 else bad)(f"ssh {role} ({alias}) reachable")
        if role == "windows" and rc == 0:
            warns += rig_preflight(alias, [v for v, on in s["variants"].items() if on], hosts["file"], ok, bad, say)
    for k, plat in (("node_bin_linux", "linux"), ("node_bin_windows", "windows")):
        if plat in plats:
            pth = hosts["path"].get(k, "")
            (ok if pth and os.path.isfile(pth) else bad)(f"paths.{k} ({pth or 'unset'}): the built-in node")
    if live:
        from .resign import live_expiry_warning
        w = live_expiry_warning(engine.repo, pipe.manifest_warn_days())
        if w:
            warns.append(w)
            say("warn", w)
        else:
            ok(f"live update manifests valid for more than {pipe.manifest_warn_days()} days")
    ids = {x.base for x in engine.run.steps}
    if live:
        # tag, publish-page and publish-source run in it after the gate: a missing one would strand
        # a half-published release (on 2026-11-02 a worktree cleanup had removed it). Doctor's run
        # has no steps, so this does not wait for "tag" to be in the plan.
        main = os.path.expanduser(hosts["path"].get("main_checkout") or engine.repo)
        rc, head = sh(["git", "-C", main, "branch", "--show-current"], lambda *a: None)
        (ok if rc == 0 and head.strip() == "main" else bad)(
            f"paths.main_checkout {main}: " + ("on main" if rc == 0 and head.strip() == "main" else
                                               "missing or not on main (git worktree add <it> main)"))
    if live and "tag" in ids:
        # The tag step refuses a commit that is not on main: say so now, not after the gate.
        main = os.path.expanduser(hosts["path"].get("main_checkout") or engine.repo)
        rc, _ = sh(["git", "-C", main, "merge-base", "--is-ancestor", info["commit"], "main"], lambda *a: None)
        if rc == 0:
            ok(f"release commit {info['commit'][:12]} is on main ({main})")
        else:
            warns.append(f"release commit {info['commit'][:12]} is not on main ({main}): merge it before the "
                         "publish gate, or step tag refuses it")
            say("warn", warns[-1])
    if live and "screens-publish" in ids and engine.run.status("screens-publish").get("status") != "skipped":
        conf = os.environ.get("SCREENS_PUBLISH_CONF", os.path.expanduser("~/.config/btlabs/screens-publish.env"))
        if not os.path.isfile(conf):
            warns.append(f"no {conf}: the screens-publish step will warn (it never holds the release)")
            say("warn", warns[-1])
    if live and ("announce" in ids or "publish-page" in ids):
        page = os.path.expanduser(hosts["path"].get("page_repo", ""))
        log = os.path.join(page, "site/epic-cash/changelog/index.html")
        try:
            has = f'id="v{info["version"]}"' in open(log, encoding="utf-8").read()
        except OSError:
            has = False
        if not has:
            warns.append(f"the changelog has no entry for {info['version']} ({log}): publish-page will refuse, "
                         "announce will warn; write it before the gate")
            say("warn", warns[-1])
    if any(s["platforms"].get(p) and p not in s["proof"]["waive"] for p in PLATFORMS):
        prev = resolve_previous(engine)
        if not prev or not os.path.isdir(prev.get("dir", "")):
            bad("G4 needs the previous release: set [proof] previous_dir in release.toml (or publish one with tools/rel)")
        else:
            ok(f"previous release {prev['version']} at {prev['dir']}")
            info["previous"] = prev
            by_plat = previous_by_platform(info["scope"], engine.pipeline, state_root_of(engine), info["version"], prev)
            info["previous_by_platform"] = by_plat
            if previous_text(prev, by_plat) != prev["version"]:
                ok("G4 previous release per platform: " + previous_text(prev, by_plat))
            lane_inputs(engine, prev, ok, bad, by_plat)
        p_spendable = None
        if not engine.dry:
            # G4 pays from P side by side (the shared P service): at least p_outputs.LOW free outputs.
            from . import p_outputs
            p = p_outputs.P.from_env()
            if not p.ready():
                bad(f"P for G4: no p.py at {p.tool} or no password at line {p.pass_line} of {p.pass_file}")
            else:
                try:
                    good, note = p_outputs.ensure(p, lambda m: say("    ", m))
                except (subprocess.TimeoutExpired, OSError):
                    good, note = False, f"the shared P service did not answer in {p.timeout} s"
                (ok if good else bad)(note)
                try:
                    r = p.client.call("info", timeout=300)
                    p_spendable = r.get("spendable") if r.get("ok") else None
                except (OSError, ValueError):
                    p_spendable = None
        warns += lane_seeds(engine, ok, bad, say, p_spendable)
    if hosted.is_hosted(s):
        hosted.preflight_checks(engine, ok, bad)  # published, main's tip, buildcheck, the dispatch cap
    nodes, boxes = pipe.defaults.get("nodes", []), pipe.defaults.get("epicboxes", [])
    node, tried = pick(nodes, health_node, os.environ.get("REL_NODE"))
    (ok if node else bad)(f"node for tests: {node or 'none healthy'} (tried {', '.join(tried)})")
    box, tried = pick(boxes, health_epicbox, os.environ.get("REL_EPICBOX"))
    (ok if box else bad)(f"Epicbox for tests: {box or 'none healthy'} (tried {', '.join(tried)})")
    info["net"] = {"node": node, "epicbox": box}
    engine.run.save_info()
    btsign.write_run_file(engine)
    if problems:
        return {"status": "failed", "note": f"{len(problems)} problem(s): " + "; ".join(problems)[:300], "problems": problems}
    return {"status": "done", "note": f"ok; node {node}, epicbox {box}" + (f"; {len(warns)} warning(s)" if warns else ""),
            "warnings": warns}


# ---- source -------------------------------------------------------------------------------------

def source(engine, step, say):
    info = engine.info
    src, commit = info["src"], info["commit"]
    if engine.dry:
        say(f"dry run: the release worktree {src} at {commit}, then tools/lepic.sh sync")
        return {"status": "done", "note": f"dry run: {src}", "dry": True}
    if not os.path.isdir(src):
        rc, _ = sh(["git", "-C", engine.repo, "worktree", "add", "--detach", src, commit], say)
        if rc != 0:
            return {"status": "failed", "note": f"git worktree add {src} failed"}
    rc, head = sh(["git", "-C", src, "rev-parse", "HEAD"], say)
    if head.strip() != commit:
        return {"status": "failed", "note": f"{src} is at {head.strip()[:12]}, not {commit[:12]}: "
                                            "remove that worktree or give --src a clean one"}
    rc, dirty = sh(["git", "-C", src, "status", "--porcelain", "--untracked-files=no"], lambda *a: None)
    if dirty.strip():
        return {"status": "failed", "note": f"{src} has uncommitted changes to tracked files"}
    rc, _ = sh(["tools/lepic.sh", "sync"], say, cwd=src, timeout=1800)
    if rc != 0:
        return {"status": "failed", "note": "tools/lepic.sh sync failed"}
    pins = {k: open(os.path.join(src, f"tools/{k}.rev")).read().strip() for k in ("lepic", "lepic-flutter")}
    info["pins"] = pins
    engine.run.save_info()
    # The worktree path is in run.json; the live message shows only what was checked out.
    return {"status": "done", "note": f"commit {commit[:12]}; LEPIC {pins['lepic'][:10]}"}


# ---- G3 artefacts -------------------------------------------------------------------------------

def page_kinds(repo):
    """KINDS of tools/releases/build.py: the one table of release file names."""
    spec = importlib.util.spec_from_file_location("releases_build", os.path.join(repo, "tools/releases/build.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.KINDS, mod.ANDROID_CERT_SHA256


def file_magic(path, n=8):
    with open(path, "rb") as f:
        return f.read(n)


def build_tools():
    sdk = os.environ.get("ANDROID_HOME") or os.path.expanduser("~/Android/Sdk")
    bt = os.path.join(sdk, "build-tools")
    vers = sorted(os.listdir(bt), key=lambda v: [int(x) if x.isdigit() else 0 for x in re.split(r"[.-]", v)]) if os.path.isdir(bt) else []
    return os.path.join(bt, vers[-1]) if vers else None


def artefacts(engine, step, say):
    info, run = engine.info, engine.run
    repo = info.get("src") if os.path.isdir(info.get("src", "")) else engine.repo
    kinds, cert = page_kinds(engine.repo)
    expected = {}
    for s in run.steps:
        if s.phase != "build" or not s.outputs:
            continue
        st = run.status(s.id)
        for o in s.outputs:
            expected[os.path.basename(o)] = (s, st["status"])
    if engine.dry:
        for name, (s, _) in expected.items():
            say(f"would check {name} (from {s.id})")
        return {"status": "done", "note": f"dry run: {len(expected)} files expected", "dry": True}
    from .signer import never_published
    problems, absent = [], []
    present = sorted(f for f in os.listdir(run.files) if f not in ("SHA256SUMS", "provenance.json", SBOM))
    for name, (s, stt) in expected.items():
        if stt != "done" and never_published(run) and name not in present:
            absent.append(name)  # never published: the files in hand are checked (as sign-android)
            say(f"not in this run: {name} ({s.id} is {stt})")
        elif stt != "done":
            problems.append(f"{name}: its step {s.id} is {stt}")
        elif name not in present:
            problems.append(f"{name}: missing from files/")
    for name in present:
        if name not in expected:
            problems.append(f"{name}: not made by any step of this run")
    version = info["version"]
    want_code = None
    if os.path.isdir(repo):
        rc, out = sh([os.path.join(repo, "tools/version.sh"), "code"], lambda *a: None)
        want_code = out.strip() if rc == 0 else None
    bt = build_tools()
    meta = {}
    for name in present:
        path = os.path.join(run.files, name)
        hits = [k for k in kinds if re.match(k[0], name)]
        s = expected.get(name, (None,))[0]
        if not hits:
            problems.append(f"{name}: no file-name pattern in tools/releases/build.py KINDS")
        else:
            m = re.match(hits[0][0], name)
            if m.group(1).split("-r")[0] != version.split("-rc")[0]:
                problems.append(f"{name}: version {m.group(1)} in the name, not {version}")
            if s and hits[0][1] not in s.platforms:
                problems.append(f"{name}: a {hits[0][1]} file from a {'/'.join(s.platforms)} step")
        size = os.path.getsize(path)
        if os.path.islink(path):
            problems.append(f"{name}: a symlink (files must be real files)")
        if size < 1_000_000:
            problems.append(f"{name}: only {size} bytes")
        magic = file_magic(path)
        if name.endswith(".apk") or name.endswith(".ipa"):
            if magic[:2] != b"PK":
                problems.append(f"{name}: not a zip")
        if name.endswith(".AppImage") and magic[:4] != b"\x7fELF":
            problems.append(f"{name}: not an ELF AppImage")
        if name.endswith(".exe") and magic[:2] != b"MZ":
            problems.append(f"{name}: not a Windows executable")
        if name.endswith(".dmg"):
            with open(path, "rb") as f:
                f.seek(-512, 2)
                if f.read(4) != b"koly":
                    problems.append(f"{name}: not a disk image")
        if name.endswith(".apk") and bt:
            rc, out = sh([os.path.join(bt, "apksigner"), "verify", "--print-certs", path], lambda *a: None)
            if f"certificate SHA-256 digest: {cert}" not in out:
                problems.append(f"{name}: not signed by the release key {cert[:12]}…")
            rc, out = sh([os.path.join(bt, "aapt2"), "dump", "badging", path], lambda *a: None)
            head = out.splitlines()[0] if out else ""
            if f"versionName='{version}'" not in head:
                problems.append(f"{name}: versionName is not {version}")
            if want_code and f"versionCode='{want_code}'" not in head:
                problems.append(f"{name}: versionCode is not {want_code}")
            if "name='uk.btlabs.btwallet'" not in head:
                problems.append(f"{name}: package is not uk.btlabs.btwallet")
        meta[name] = {"bytes": size, "sha256": run.status(s.id)["outputs"].get(name, {}).get("sha256") if s else None,
                      "step": s.id if s else None, "host": s.host if s else None,
                      "built_by": built_by(engine, s) if s else None}
    if "android" in [p for p in PLATFORMS if info["scope"]["platforms"].get(p)]:
        for s in run.steps:
            if s.base == "build-android" and not (never_published(run) and run.status(s.id)["status"] != "done"):
                for e in s.extras:
                    if not os.path.isfile(os.path.join(run.extra, e)):
                        problems.append(f"extra/{e}: missing (G4 needs it)")
    from .engine import sha256_file
    from .signer import accepted_change, read_signed
    signed = read_signed(run)
    for name in present:
        actual = sha256_file(os.path.join(run.files, name))
        if meta[name]["sha256"] and meta[name]["sha256"] != actual:
            if accepted_change(run, name, meta[name]["sha256"], actual):
                meta[name]["unsigned_sha256"] = meta[name]["sha256"]
                meta[name]["signed_by"] = "signer"
            else:
                problems.append(f"{name}: changed since its step recorded it")
        elif name in signed and signed[name].get("sha256") != actual:
            problems.append(f"{name}: signed.json says the signer signed it, but it is the unsigned build")
        meta[name]["sha256"] = actual
    # The SBOM and provenance.json first, then SHA256SUMS over the release files and both, so the
    # signed SHA256SUMS covers them too.
    sbom_err = write_sbom(engine, repo, version, os.path.join(run.files, SBOM), say)
    if sbom_err:
        problems.append(sbom_err)
    prov = {
        "version": version, "version_code": want_code, "commit": info["commit"], "run_id": info["run_id"],
        "created": now_iso(), "pins": info.get("pins", {}), "scope": scope_summary(info["scope"]),
        "toolchain": toolchain(engine.repo), "files": meta, "test": bool(info.get("test")),
        "published_commit": (info.get("published") or {}).get("commit"),
        "published_pins": {k: (info.get("published") or {}).get(k) for k in ("lepic", "lepic_flutter")},
    }
    write_json(os.path.join(run.files, "provenance.json"), prov)
    listed = {name: meta[name]["sha256"] for name in present}
    for extra in ("provenance.json", SBOM):
        if os.path.isfile(os.path.join(run.files, extra)):
            listed[extra] = sha256_file(os.path.join(run.files, extra))
    with open(os.path.join(run.files, "SHA256SUMS"), "w", encoding="utf-8") as f:
        for name in sorted(listed):
            f.write(f"{listed[name]}  {name}\n")
    for name in present:
        say(f"{meta[name]['sha256']}  {meta[name]['bytes']:>12}  {name}")
    if problems:
        for p in problems:
            say("FAIL", p)
        return {"status": "failed", "note": f"{len(problems)} problem(s): " + "; ".join(problems)[:300]}
    # Every built file's bytes as they ship (after signing): the evidence after G3 is keyed by
    # this list's hash (tools/rellib/evidence.py).
    from . import evidence
    mhash, missing = evidence.write_manifest(engine)
    if missing:
        return {"status": "failed", "note": "rc-manifest.json: built files missing: " + ", ".join(missing)[:250]}
    say(f"rc-manifest.json {mhash}")
    total = sum(m["bytes"] for m in meta.values())
    return {"status": "done", "note": f"{len(present)} files, {total / 1e6:.0f} MB, SHA256SUMS + provenance.json + {SBOM}"
                                      f"; rc-manifest {mhash[:12]}"
                                      + (f"; not in this run: {', '.join(absent)}" if absent else ""),
            "bytes": total, "rc_manifest": mhash}


SBOM = "sbom.cdx.json"


def write_sbom(engine, repo, version, out, say):
    """tools/sbom.py (CycloneDX, deterministic) over the release checkout's lockfiles: the
    checkout's own tool when it has one, else this checkout's. -> a problem, or None."""
    tool = next((t for t in (os.path.join(repo, "tools/sbom.py"), os.path.join(engine.repo, "tools/sbom.py"))
                 if os.path.isfile(t)), None)
    if not tool:
        return f"{SBOM}: no tools/sbom.py in {repo} or {engine.repo}"
    rc, _ = sh(["python3", "-I", tool, "--version", version, "--pubspec-lock", os.path.join(repo, "app/pubspec.lock"),
                "--cargo-lock", os.path.join(repo, "app/third_party/lepic/Cargo.lock"), "--out", out], say)
    if rc != 0 or not os.path.isfile(out):
        return f"{SBOM}: tools/sbom.py failed (exit {rc})"
    return None


def toolchain(repo):
    out = {}
    try:
        out["flutter_pin"] = open(os.path.join(repo, "scripts/linux/flutter.version")).read().strip()
    except OSError:
        pass
    try:
        img = subprocess.run(["docker", "image", "inspect", "-f", "{{.Id}}", "wfe-linux-build:22.04"],
                             capture_output=True, text=True, timeout=30).stdout.strip()
        if img:
            out["linux_container"] = img
    except Exception:
        pass
    return out


# ---- G4 ---------------------------------------------------------------------------------------

def keyring_for(engine):
    signer = engine.hosts["host"].get("signer", {})
    bp = signer.get("btlabs_public", os.path.expanduser("~/code/btlabs-public"))
    if guards.test_key(engine.info):
        return os.path.join(engine.run.path, "manifests", "test-keyring.json"), bp
    return os.path.join(bp, "keys/btlabs-keyring.json"), bp


def payload_of(envelope):
    import base64
    return json.loads(base64.b64decode(json.load(open(envelope))["payload"]))


def fetch(url, timeout=20):
    with urllib.request.urlopen(url, timeout=timeout) as r:
        return r.read()


def trust_manifest(engine, step, say):
    """Both manifests: they verify against the keyring the apps trust (the test keyring in a TEST
    run), name exactly this run's files with their sizes and checksums, every URL sits under its
    folder, and the serial is above the live one."""
    if engine.dry:
        say("dry run: would verify update.json and update-v2.json (keyring, URLs, sizes, serial above live)")
        return {"status": "done", "note": "dry run", "dry": True}
    mdir = os.path.join(engine.run.path, "manifests")
    src = engine.info["src"]
    keyring, bp = keyring_for(engine)
    tool = os.path.join(bp, "tool/btlabs_sign.py")
    cfg = os.path.join(src, "app/assets/config/app-config.toml")
    problems = []
    for name, extra in (("update.json", []), ("update-v2.json", ["--app-config", cfg])):
        env_path = os.path.join(mdir, name)
        if not os.path.isfile(env_path):
            problems.append(f"{name}: missing")
            continue
        rc, _ = sh(["python3", tool, "verify", "--type", "update", "--keyring", keyring, "--envelope", env_path] + extra, say)
        if rc != 0:
            problems.append(f"{name}: does not verify against {os.path.basename(keyring)}")
    old_base = tomllib.load(open(os.path.join(src, "app/tool/config/old-update.toml"), "rb"))["old_update"]
    new_cfg = tomllib.load(open(cfg, "rb"))["updates"]
    for name, base in (("update.payload.json", old_base["downloads"]), ("update-v2.payload.json", new_cfg["downloads"])):
        p = os.path.join(mdir, name)
        if os.path.isfile(p):
            rc, _ = sh([os.path.join(src, "app/tool/check_update_urls.sh"), p, base], say)
            if rc != 0:
                problems.append(f"{name}: a file URL is off {base}")
    sums = {}
    try:
        for line in open(os.path.join(engine.run.files, "SHA256SUMS")):
            sha, fname = line.split()
            sums[fname] = sha
    except OSError:
        problems.append("files/SHA256SUMS missing")
    # Desktop systems this release leaves out keep their live entry (steps/desktop_keep.py).
    kept = {}
    kp = os.path.join(mdir, "desktop-keep.json")
    if os.path.isfile(kp):
        kept = {e["url"].rsplit("/", 1)[-1]: e for e in walk_objects(json.load(open(kp))) if isinstance(e.get("url"), str)}
    serial = None
    for name in ("update.json", "update-v2.json"):
        pth = os.path.join(mdir, name)
        if not os.path.isfile(pth):
            continue
        pl = payload_of(pth)
        serial = pl.get("serial")
        if pl.get("versionName") != engine.info["version"]:
            problems.append(f"{name}: versionName {pl.get('versionName')} is not {engine.info['version']}")
        for entry in [o for o in walk_objects(pl) if isinstance(o.get("url"), str)]:
            fname = entry["url"].rsplit("/", 1)[-1]
            if fname not in sums:
                k = kept.get(fname)
                if k and (k.get("sha256"), k.get("size"), k.get("version")) == (entry.get("sha256"), entry.get("size"), entry.get("version")):
                    say(f"{name}: {fname} kept from the live manifest ({k.get('version')})")
                else:
                    problems.append(f"{name}: names {fname}, which is not a file of this run")
                continue
            if entry.get("sha256") and entry["sha256"] != sums[fname]:
                problems.append(f"{name}: sha256 of {fname} differs from the file")
            size = os.path.getsize(os.path.join(engine.run.files, fname))
            if entry.get("size") and entry["size"] != size:
                problems.append(f"{name}: size of {fname} is {entry['size']}, the file is {size}")
        if engine.info["scope"]["variants"].get("notor") and "notor" not in pl:
            problems.append(f"{name}: no notor section, but this release has -notor builds")
    for name, url in (("update.json", old_base["manifest"]), ("update-v2.json", new_cfg["manifests"][0])):
        try:
            live = json.loads(fetch(url))
            import base64
            live_serial = json.loads(base64.b64decode(live["payload"])).get("serial")
            say(f"live {name}: serial {live_serial}")
            if serial is not None and live_serial is not None and serial <= live_serial:
                (problems.append if not engine.info.get("test") else say)(
                    f"{name}: serial {serial} is not above the live {live_serial}")
        except Exception as e:
            msg = f"live {name} unreadable ({e})"
            if engine.info.get("test"):
                say("warn", msg)
            else:
                problems.append(msg + ": the serial check cannot be made")
    if problems:
        for p in problems:
            say("FAIL", p)
        return {"status": "failed", "note": "; ".join(problems)[:300]}
    return {"status": "done", "note": f"both manifests verify; serial {serial}" + (" (test key)" if engine.info.get("test") else "")}


def kept_files(run):
    """{file name: sha256} of the live files this run keeps: the desktop entries its manifests
    keep (desktop-keep.json) and every platform it has no file for (live-keep.sums)."""
    out = {}
    kp = os.path.join(run.path, "manifests", "desktop-keep.json")
    if os.path.isfile(kp):
        out.update({e["url"].rsplit("/", 1)[-1]: e.get("sha256") for e in walk_objects(json.load(open(kp)))
                    if isinstance(e.get("url"), str)})
    lp = os.path.join(run.path, "manifests", "live-keep.sums")
    if os.path.isfile(lp):
        for line in open(lp, encoding="utf-8"):
            sha, _, name = line.rstrip("\n").partition("  ")
            if name:
                out[name] = sha
    return out


def walk_objects(o):
    if isinstance(o, dict):
        yield o
        for v in o.values():
            yield from walk_objects(v)
    elif isinstance(o, list):
        for v in o:
            yield from walk_objects(v)


def proof_table(engine):
    """{platform: (state, text)}: proven | waived | not proven, per platform in scope."""
    s, run = engine.info["scope"], engine.run
    out = {}
    for p in PLATFORMS:
        if not s["platforms"].get(p):
            continue
        ts = [x for x in run.steps if x.base == f"trust-{p}"]
        if p in s["proof"]["waive"]:
            found = "; ".join(f"{x.variant}: {st.get('note') or st['status']}" for x in ts
                              for st in [run.status(x.id)] if st["status"] != "skipped")
            out[p] = ("waived", f"NOT PROVEN — waived: {s['proof']['waive'][p]}"
                      + (f" · driver: {found}" if found else ""))
            continue
        if not ts:
            out[p] = ("not proven", "no update-trust step in scope")
            continue
        sts = [(x, run.status(x.id)) for x in ts]
        if all(st["status"] == "done" and (st.get("proven") or st.get("dry")) for _, st in sts):
            dry = any(st.get("dry") for _, st in sts)
            # What a reader must see first: a pass that took more than one try, drivers edited between tries.
            flags = [f"{x.variant} passed on try {st.get('attempts')} (flaky)" for x, st in sts if st.get("flaky")]
            flags += [f"{x.variant}: DRIVERS CHANGED between attempts" for x, st in sts if st.get("driver_changed")]
            out[p] = ("dry" if dry else "proven",
                      ("; ".join(flags) + " · " if flags else "")
                      + ("dry run only" if dry else "proven: ") + "; ".join(f"{x.variant}: {st.get('note', '')}" for x, st in sts))
        else:
            out[p] = ("not proven", "; ".join(f"{x.id} {st['status']}" + (f" ({st.get('note')})" if st.get("note") else "")
                                             for x, st in sts))
    return out


def update_trust(engine, step, say):
    table = proof_table(engine)
    failed = []
    for p, (state, text) in table.items():
        say(f"{p:8} {state:10} {text}")
        if state == "not proven":
            failed.append(p)
        if engine.relmsg:
            engine.relmsg.platform(p, {"proven": "ok", "waived": "waiting", "dry": "pending"}.get(state, "failed"),
                                   note=text[:150])
    if engine.info["scope"]["publish"]["manifests"]:
        mst = [engine.run.status(x.id) for x in engine.run.steps if x.base == "trust-manifest"]
        if not mst or mst[0]["status"] != "done":
            failed.append("manifests")
    summary = {k: {"state": v[0], "text": v[1]} for k, v in table.items()}
    write_json(os.path.join(engine.run.path, "proof-summary.json"), summary)
    if failed:
        return {"status": "failed", "note": "not proven: " + ", ".join(failed)}
    from . import evidence
    manifest = None if engine.dry else evidence.read_manifest(engine.run)
    extra = {}
    if manifest:
        # A proof counts only for the bytes it tested: those must be the release's (rc-manifest.json).
        stale = evidence.stale_proofs(engine, manifest)
        for sid, why in stale:
            say(f"not applicable: {sid}: {why}")
        if stale:
            return {"status": "failed", "note": "proofs made on other bytes than rc-manifest.json: "
                    + "; ".join(f"{sid} ({why})" for sid, why in stale)[:300]
                    + " (tools/rel resume runs them again)"}
        d = evidence.keep(engine, manifest, summary)
        say(f"evidence for rc-manifest {manifest['hash']}: {d}")
        extra = {"rc_manifest": manifest["hash"]}
    waived = [p for p, (st, _) in table.items() if st == "waived"]
    head = "dry run: every driver answered its dry run" if engine.dry else "every platform proven"
    return {"status": "done", "note": head + (f"; waived (NOT PROVEN): {', '.join(waived)}" if waived else ""),
            **extra, **({"dry": True} if engine.dry else {})}


# ---- G5 publish gate ----------------------------------------------------------------------------

def gate_summary(engine):
    info, run = engine.info, engine.run
    s = info["scope"]
    if info.get("kind") == "rollback":
        st = run.status("rollback-resign")
        return "\n".join([
            f"{'TEST ' if info.get('test') else ''}ROLLBACK: Epic Wallet {info.get('replaces')} → {info['version']}?",
            f"run {info['run_id']} · target {s['publish']['target']}",
            st.get("note") or "",
            f"Publishes {info['version']}'s files, page and manifests again (manifests last).",
            "Phones on the bad version get the older one only if its version code is higher: they usually need the next version too.",
        ])[:2900]
    lines = [f"{'TEST ' if info.get('test') else ''}Epic Wallet {info['version']} — publish?",
             f"commit {info['commit'][:12]} · run {info['run_id']} · target {s['publish']['target']}",
             f"scope: {scope_summary(s)}", ""]
    sums = os.path.join(run.files, "SHA256SUMS")
    if os.path.isfile(sums):
        lines.append("Files:")
        for line in open(sums):
            sha, name = line.split()
            lines.append(f"- {name} {os.path.getsize(os.path.join(run.files, name)) / 1e6:.1f} MB {sha[:16]}…")
    mp = os.path.join(run.path, "manifests", "update.json")
    if os.path.isfile(mp):
        pl = payload_of(mp)
        lines.append(f"Manifests: serial {pl.get('serial')}, version {pl.get('versionName')}"
                     + (" (TEST key)" if info.get("test") else ""))
    elif not s["publish"]["manifests"]:
        lines.append("Manifests: NONE (publish.manifests = false): no app is offered this update")
    from . import evidence
    m = evidence.read_manifest(run)
    if m:
        lines.append(f"Artefacts: rc-manifest {m['hash'][:16]}… ({len(m['files'])} built files); "
                     "the proofs below are about exactly these bytes")
    lines.append("Update trust (G4):")
    for p, (state, text) in proof_table(engine).items():
        lines.append(f"- {p}: {text}"[:300])
    srv = server_log_lines(engine)
    at_srv = len(lines)
    lines.extend(srv)
    at_screens = len(lines)
    lines.extend(screens_lines(run))
    prev = info.get("previous", {})
    if prev:
        lines.append(f"Server: older files leave downloads/ after the switch (keeps {prev.get('version')} as the rollback backup).")
        bp = previous_text(prev, info.get("previous_by_platform"))
        if bp != prev.get("version"):
            lines.append(f"G4 updates from: {bp}.")
    skips = [x for x in run.steps if run.status(x.id)["status"] == "skipped"]
    if skips:
        lines.append("Skipped (not done, not passed): " + "; ".join(f"{x.id} ({run.status(x.id).get('reason', '')})" for x in skips))
    weak = [h for h in health.lanes_of(health.metrics_path(run), engine.pipeline.health) if h["weak"]]
    at_weak = len(lines)
    if weak:
        lines.append("Weak trust lanes (they still gate):")
        lines.extend(health.weak_line(h) for h in weak)
    approve = len(lines)
    lines.append("Approve = tag, then publish in this order: downloads → page → source → manifests last.")
    after = [x.id for x in run.steps if x.base in ("screens-publish", "announce", "store-play", "store-play-promote")]
    if after:
        lines.append("Then, after the read-back: " + ", ".join(after) + " (the gallery and announce never hold the release).")
    text = "\n".join(lines)
    if len(text) > 2900:
        # Too long for the message: the server-log quotes shrink to their count lines, the weak lanes to
        # one line, then the screens part to its first line and the report link, so the approve line is
        # never cut off.
        if srv:
            short = [x for x in srv if not x.startswith("    ")]
            lines[at_srv:at_srv + len(srv)] = short
            shift = len(srv) - len(short)
            at_screens, at_weak, approve = at_screens - shift, at_weak - shift, approve - shift
        if weak:
            lines[at_weak:approve] = ["Weak trust lanes (they still gate): " + ", ".join(h["lane"] for h in weak)
                                      + " (tools/rel stats --lanes)"]
            approve = at_weak + 1
        sl = screens_lines(run)
        if len(sl) > 3:
            lines[at_screens:at_screens + len(sl)] = [sl[0], sl[1], sl[-1]]
            approve -= len(sl) - 3
        text = "\n".join(lines)
    if len(text) > 2900:
        # Still too long: the lines before the Approve line give way, never the lines from it on.
        tail = "\n".join(lines[approve:])
        text = "\n".join(lines[:approve])[:max(0, 2900 - len(tail) - 1)] + "\n" + tail
    return text[:2900]


def server_log_lines(engine):
    """For each G4 lane that failed an attempt in this run (flaky, failed, skipped or warned): the
    server-side lines its last failure left (out/server-logs.json, tools/rellib/serverlogs.py)."""
    from . import serverlogs
    run, out = engine.run, []
    for x in run.steps:
        if not serverlogs.is_lane_step(x):
            continue
        st = run.status(x.id)
        if not (st.get("attempt_causes") or st["status"] != "done" or st.get("warned")):
            continue
        sm = read_json(os.path.join(run.step_dir(x.id), "out", "server-logs.json"))
        if isinstance(sm, dict):
            out.append(f"- {x.id} at its failure, {'–'.join(sm.get('window') or [])} UTC:")
            out.extend("    " + q.strip() if q.startswith("  ") else "  " + q
                       for q in serverlogs.quote_lines(sm, width=200))
    return ["Server logs for lanes that failed a try:"] + out if out else []


def screens_lines(run):
    """The pre-gate screen check's lines for the gate (steps/screens-check/out/summary.json, written by
    tools/rellib/steps/screens_check.py), at most 900 characters: tour renders, not proof of an update."""
    st = run.status("screens-check") if any(x.base == "screens-check" for x in run.steps) else None
    if st is None:
        return []
    sm = read_json(os.path.join(run.step_dir("screens-check"), "out", "summary.json"))
    skipped = f"Screens: check SKIPPED ({st.get('reason', '')})" if st["status"] == "skipped" else None
    if not isinstance(sm, dict):
        return [skipped or f"Screens: no check result ({st['status']})"]
    # A skipped check still shows what its last attempt found (the FAIL lines it was skipped over).
    out, size = [(skipped + ", its last result:") if skipped else
                 "Screens (tour renders before the gate; not update proof):"], 0
    for ln in sm.get("lines", [])[:7]:
        ln = "- " + ln[:240]
        if size + len(ln) > 900:
            out.append("- … more in the report")
            break
        out.append(ln)
        size += len(ln)
    out.append(f"- report: {sm['url']}" if sm.get("url") else
               "- report: the 'Screens check' link on the live message (the release lead publishes "
               "steps/screens-check/out/report/)")
    return out


def publish_gate(engine, step, say):
    info = engine.info
    if engine.dry:
        say("dry run: the publish gate is never asked in a dry run")
        return {"status": "done", "note": "dry run: not asked", "dry": True}
    if info.get("tainted"):
        return {"status": "closed", "note": "run is tainted (" + info["tainted"][-1]["reason"] + "): start a clean run"}
    gname = "rollback" if step.base == "rollback-gate" else "publish"
    text = gate_summary(engine)
    path = os.path.join(engine.run.path, f"gate-{gname}.md")
    with open(path, "w", encoding="utf-8") as f:
        f.write(text + "\n")
    say(text)
    gates = info.setdefault("gates", {})
    g = gates.get(gname, {})
    if not engine.relmsg or not engine.relmsg.enabled:
        return {"status": "closed", "note": "relmsg is off for this run: the publish gate cannot open (fail closed)"}
    from . import evidence
    m = evidence.read_manifest(engine.run)
    if g.get("gate_id") and m and g.get("rc_manifest") and g["rc_manifest"] != m["hash"]:
        # Asked about other bytes: that question no longer applies; a new one is asked.
        engine.run.event(step.id, "gate", gate=gname, gate_id=g["gate_id"], state="superseded")
        g = {}
    if not g.get("gate_id"):
        gid, err = engine.relmsg.gate_open(gname, path)
        if gid is None:
            return {"status": "closed", "note": f"gate not opened: {err} (fail closed; tools/rel gate publish asks again)"}
        g = {"gate_id": gid, "asked": now_iso()}
        if m:
            g["rc_manifest"] = m["hash"]  # the bytes this question is about (tools/rel publish checks)
        gates[gname] = g
        engine.run.save_info()
        engine.run.event(step.id, "gate", gate=gname, gate_id=gid, state="asked")
    state, out = engine.relmsg.gate_status(g["gate_id"])
    g.update(state=state, checked=now_iso(), decided_by=out.get("decided_by"), via=out.get("via"), at=out.get("at"))
    engine.run.save_info()
    engine.run.event(step.id, "gate", gate=gname, gate_id=g["gate_id"], state=state, via=out.get("via"))
    if state == "approved":
        return {"status": "done", "note": f"approved by {out.get('decided_by') or '?'} via {out.get('via') or '?'} at {out.get('at') or '?'}"}
    if state == "pending":
        # A detached watcher checks from now on and publishes once approved (tools/rellib/gatewatch.py).
        from . import gatewatch
        _, watch = gatewatch.start(engine.run, engine.pipeline, engine.hosts.get("file"), step.id)
        return {"status": "waiting", "note": f"waiting for approval (gate {g['gate_id']}); tools/rel gate to check again"
                + (f"; {watch}" if watch else "")}
    if state == "held":
        return {"status": "held", "note": f"held by {out.get('decided_by') or 'the owner'}" + (f": {out.get('note')}" if out.get("note") else "")}
    return {"status": "closed", "note": "gate status unreadable (relmsg error): not approved (fail closed)"}


# ---- G6 read back -------------------------------------------------------------------------------

def verify_live(engine, step, say):
    run, info = engine.run, engine.info
    if engine.dry:
        say("dry run: would read every published copy back")
        return {"status": "done", "note": "dry run", "dry": True}
    sums = dict((l.split()[1], l.split()[0]) for l in open(os.path.join(run.files, "SHA256SUMS")))
    problems = []
    if info.get("target") == "scratch":
        tgt = scratch_dir(engine)
        from .engine import sha256_file
        for name, sha in sums.items():
            p = os.path.join(tgt, "downloads", name)
            if not os.path.isfile(p) or sha256_file(p) != sha:
                problems.append(f"downloads/{name}: missing or different")
        if info["scope"]["publish"]["manifests"]:
            for m in ("update.json", "update-v2.json"):
                a, b = os.path.join(tgt, "manifests", m), os.path.join(run.path, "manifests", m)
                if not os.path.isfile(a) or sha256_file(a) != sha256_file(b):
                    problems.append(f"manifests/{m}: missing or different")
        if not os.path.isfile(os.path.join(tgt, "page", "index.html")) and run.status("publish-page")["status"] == "done":
            problems.append("page/index.html missing")
    else:
        src = info["src"]
        old = tomllib.load(open(os.path.join(src, "app/tool/config/old-update.toml"), "rb"))["old_update"]
        new = tomllib.load(open(os.path.join(src, "app/assets/config/app-config.toml"), "rb"))["updates"]
        for base in (old["downloads"], new["downloads"]):
            try:
                served = fetch(base.rstrip("/") + "/SHA256SUMS").decode()
                served = dict((l.split()[1], l.split()[0]) for l in served.splitlines() if l.strip())
            except Exception as e:
                problems.append(f"{base}SHA256SUMS unreadable: {e}")
                continue
            for name, sha in sums.items():
                if served.get(name) != sha:
                    problems.append(f"{base}{name}: not served with this checksum")
            for name, sha in kept_files(run).items():
                if served.get(name) != sha:
                    problems.append(f"{base}{name}: kept in the manifest but not served with its checksum")
        if info["scope"]["publish"]["manifests"]:
            import hashlib
            for name, url in (("update.json", old["manifest"]), ("update-v2.json", new["manifests"][0])):
                want = hashlib.sha256(open(os.path.join(run.path, "manifests", name), "rb").read()).hexdigest()
                try:
                    got = hashlib.sha256(fetch(url)).hexdigest()
                except Exception as e:
                    got = f"unreadable ({e})"
                if got != want:
                    problems.append(f"{url}: {'differs' if len(got) == 64 else got}")
                else:
                    say(f"ok {url}")
    if problems:
        for p in problems:
            say("FAIL", p)
        return {"status": "failed", "note": "; ".join(problems)[:300] + " — consider tools/rel rollback"}
    from . import retention
    retention.mark_published(engine.run)
    return {"status": "done", "note": f"every copy reads back ({info.get('target')})"}


def cleanup_step(engine, step, say):
    from . import retention
    if engine.dry:
        plan = retention.plan(os.path.dirname(os.path.dirname(engine.run.path)), keep_run=engine.run.path)
        for p in plan["remove"]:
            say("would remove", p)
        return {"status": "done", "note": f"dry run: would remove {len(plan['remove'])}", "dry": True}
    res = retention.apply(os.path.dirname(os.path.dirname(engine.run.path)), engine.repo, say, keep_run=engine.run.path)
    return {"status": "done", "note": f"removed {len(res['removed'])}, kept {', '.join(res['kept']) or 'nothing older'}"}


# ---- scratch publish target ---------------------------------------------------------------------

def scratch_downloads(engine, step, say):
    tgt = os.path.join(scratch_dir(engine), "downloads")
    os.makedirs(tgt, exist_ok=True)
    from .engine import place, sha256_file
    names = [l.split()[1] for l in open(os.path.join(engine.run.files, "SHA256SUMS"))]
    for n in names:
        place(os.path.join(engine.run.files, n), os.path.join(tgt, n))
    with open(os.path.join(tgt, "SHA256SUMS"), "w") as f:
        for n in sorted(x for x in os.listdir(tgt) if x != "SHA256SUMS"):
            f.write(f"{sha256_file(os.path.join(tgt, n))}  {n}\n")
    say(f"{len(names)} files into {tgt}")
    return {"status": "done", "note": f"scratch: {len(names)} files"}


def scratch_page(engine, step, say):
    tool = os.path.join(engine.run.path, "scratch", "page-tool")
    if os.path.isdir(tool):
        shutil.rmtree(tool)
    shutil.copytree(os.path.join(engine.info["src"], "tools/releases"), tool)
    out = os.path.join(scratch_dir(engine), "page")
    mirror = ["--github"] if engine.info["scope"]["publish"].get("github") else []
    rc1, _ = sh(["python3", os.path.join(tool, "build.py"), "add", engine.info["version"], engine.run.files] + mirror, say)
    rc2, _ = sh(["python3", os.path.join(tool, "build.py"), "render", "--out", out], say)
    if rc1 or rc2:
        return {"status": "failed", "note": "build.py add/render failed"}
    return {"status": "done", "note": f"scratch page in {out}"}


def scratch_source(engine, step, say):
    """The real tools/publish-github.sh without --push: the rewrite and its scanners run, nothing
    is pushed."""
    pub = os.path.join(engine.run.path, "scratch", "publish")
    main = engine.hosts["path"].get("main_checkout") or engine.repo
    rc, _ = sh(["tools/publish-github.sh"], say, cwd=main, env={"PUBLISH_DIR": pub}, timeout=3600)
    if os.path.isdir(pub):
        shutil.rmtree(pub, ignore_errors=True)
    if rc != 0:
        return {"status": "failed", "note": "publish-github.sh dry run failed"}
    return {"status": "done", "note": "publish-github.sh dry run passed (nothing pushed)"}


def scratch_manifests(engine, step, say):
    tgt = os.path.join(scratch_dir(engine), "manifests")
    os.makedirs(tgt, exist_ok=True)
    keyring, bp = keyring_for(engine)
    tool = os.path.join(bp, "tool/btlabs_sign.py")
    cfg = os.path.join(engine.info["src"], "app/assets/config/app-config.toml")
    for name, extra in (("update.json", []), ("update-v2.json", ["--app-config", cfg])):
        src = os.path.join(engine.run.path, "manifests", name)
        rc, _ = sh(["python3", tool, "verify", "--type", "update", "--keyring", keyring, "--envelope", src] + extra, say)
        if rc != 0:
            return {"status": "failed", "note": f"{name} does not verify"}
        shutil.copy2(src, os.path.join(tgt, name))
    return {"status": "done", "note": f"scratch: both manifests in {tgt}"}


def releases_keep(repo, version, names):
    """tools/releases/build.py keep: per platform and variant the newest version's files."""
    spec = importlib.util.spec_from_file_location("releases_build", os.path.join(repo, "tools/releases/build.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.keep(version, names)


def scratch_prune(engine, step, say):
    d = os.path.join(scratch_dir(engine), "downloads")
    arch = os.path.join(scratch_dir(engine), "archive")
    v = engine.info["version"]
    moved = []
    names = sorted(os.listdir(d)) if os.path.isdir(d) else []
    keep = releases_keep(engine.repo, v, names) | set(kept_files(engine.run))
    for n in names:
        if n not in ("SHA256SUMS", "SHA256SUMS.sig", "provenance.json", SBOM) and n not in keep:
            os.makedirs(arch, exist_ok=True)
            shutil.move(os.path.join(d, n), os.path.join(arch, n))
            moved.append(n)
    say("archived:", ", ".join(moved) or "nothing")
    return {"status": "done", "note": f"scratch: {len(moved)} older file(s) archived"}


def scratch_noop(engine, step, say):
    say(f"scratch target: {step.id} not run (it only talks to a store)")
    return {"status": "done", "note": "scratch: not run"}
