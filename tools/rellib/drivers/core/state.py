# SPDX-License-Identifier: Apache-2.0
"""Saved end states: a passing lane leaves its wallet for the next release's lane to start from.

Layout under REL_TRUST_STATE_ROOT (default /tmp/epic-build/trust-state):
    <platform>-<variant>/<version>/meta.json     version, commit, run, saved_at, signer, address, end digest
                                  /secrets/      password, pin, phrase (0600 files in a 0700 folder)
                                  /payload/      the platform's own (sandbox HOME, AVD snapshot, rig data folder)
A save writes <version>.tmp-<pid> and renames it into place; the newest KEEP versions per
platform-variant stay. Nothing secret is ever logged.

Choice (REL_TRUST_START): `fresh` never uses a state; `state` must (could not run without one);
`auto` (default) uses one when it exists for the previous version and its meta says it fits (the
platform's `fits(meta)`, e.g. an Android state signed with the key this run's previous APK carries).
A state that will not load is the harness's fault, never the product's: auto then falls back to fresh.
Saving is on by default; REL_TRUST_SAVE_STATE=0 for trial runs (a build that is not a release).

A state keeps the servers its wallet had in use: meta "hermetic" says which were this host's local
node and relay (core/hermetic.py). A run restores only a state whose servers are as local as its own
(hermetic_fits, from the platform's fits): the restored previous release is not pointed again.
A state without the key was saved before hermetic lanes, on public servers.
"""
import json
import os
import shutil
import time

from . import hermetic

KEEP = 2
SECRET_NAMES = ("password", "pin", "phrase")


def root():
    return os.environ.get("REL_TRUST_STATE_ROOT") or os.path.expanduser("/tmp/epic-build/trust-state")


class Saved:
    def __init__(self, folder):
        self.folder = folder
        self.payload = os.path.join(folder, "payload")
        with open(os.path.join(folder, "meta.json")) as f:
            self.meta = json.load(f)

    def secrets(self):
        out = {}
        for n in SECRET_NAMES:
            p = os.path.join(self.folder, "secrets", n)
            if os.path.exists(p):
                with open(p) as f:
                    out[n] = f.read().strip()
        return out


def in_use(platform):
    """{"node", "relay"}: whether the server the platform's app has in use is this host's own."""
    return {"node": hermetic.local(getattr(platform, "node", "")), "relay": hermetic.local(getattr(platform, "relay", ""))}


def hermetic_fits(meta, platform):
    """(ok, why): the state's servers in use are as local as this run's."""
    saved = meta.get("hermetic") or {"node": False, "relay": False}
    now = in_use(platform)
    if {k: bool(saved.get(k)) for k in now} == now:
        return True, ""
    say = lambda d: ", ".join("%s %s" % (k, "local" if d.get(k) else "public") for k in ("node", "relay"))
    return False, "saved with %s in use, this run uses %s" % (say(saved), say(now))


def pick(platform, variant, version, fits=None, log=print):
    mode = os.environ.get("REL_TRUST_START", "auto")
    if mode == "fresh" or not version:
        return None
    folder = os.path.join(root(), "%s-%s" % (platform, variant), version)
    try:
        s = Saved(folder)
    except (OSError, ValueError) as e:
        if mode == "state":
            from .faults import HarnessFault
            raise HarnessFault("start", "REL_TRUST_START=state but no saved state for %s %s %s (%s)" % (platform, variant, version, e))
        return None
    if fits is not None:
        ok, why = fits(s.meta)
        if not ok:
            log("saved state %s not used: %s" % (folder, why))
            if mode == "state":
                from .faults import HarnessFault
                raise HarnessFault("start", "saved state does not fit: %s" % why)
            return None
    return s


def save(platform, secrets, digest, *, log=print, extra=None):
    """Called by a lane whose every check passed, after its funds went back to P."""
    version = os.environ.get("REL_CANDIDATE_VERSION")
    if not version:
        return None
    base = os.path.join(root(), "%s-%s" % (platform.name, platform.variant))
    os.makedirs(base, exist_ok=True)
    tmp = os.path.join(base, "%s.tmp-%d" % (version, os.getpid()))
    os.makedirs(tmp, mode=0o700)
    os.makedirs(os.path.join(tmp, "secrets"), mode=0o700)
    os.makedirs(os.path.join(tmp, "payload"), mode=0o700)
    for n, v in secrets.items():
        if n in SECRET_NAMES and v:
            p = os.path.join(tmp, "secrets", n)
            fd = os.open(p, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
            with os.fdopen(fd, "w") as f:
                f.write(v)
    platform.save_state(os.path.join(tmp, "payload"))
    meta = {"version": version, "commit": os.environ.get("REL_CANDIDATE_COMMIT"), "run": os.environ.get("REL_RUN"),
            "saved_at": time.strftime("%Y-%m-%dT%H:%M:%S"), "platform": platform.name, "variant": platform.variant,
            "digest": digest, "hermetic": in_use(platform)}
    meta.update(extra or {})
    meta.update(getattr(platform, "state_meta", lambda: {})())
    with open(os.path.join(tmp, "meta.json"), "w") as f:
        json.dump(meta, f, indent=1, default=str)
    final = os.path.join(base, version)
    if os.path.isdir(final):
        os.rename(final, "%s.old-%d" % (final, os.getpid()))
    os.rename(tmp, final)
    _prune(base, log)
    log("saved end state %s" % final)
    return final


def _prune(base, log):
    """Keeps the newest KEEP versions (by saved_at); moves older ones and leftovers aside into .trash."""
    entries = []
    for d in os.listdir(base):
        p = os.path.join(base, d)
        if ".tmp-" in d or ".old-" in d:
            entries.append((None, p))
            continue
        try:
            with open(os.path.join(p, "meta.json")) as f:
                entries.append((json.load(f).get("saved_at", ""), p))
        except (OSError, ValueError):
            entries.append((None, p))
    good = sorted((e for e in entries if e[0]), reverse=True)
    drop = [p for _, p in good[KEEP:]] + [p for s, p in entries if s is None and not os.path.basename(p).startswith(".")]
    if not drop:
        return
    trash = os.path.join(base, ".trash")
    os.makedirs(trash, exist_ok=True)
    for p in drop:
        shutil.move(p, os.path.join(trash, "%s-%d" % (os.path.basename(p), int(time.time()))))
        log("old state moved aside: %s" % p)
