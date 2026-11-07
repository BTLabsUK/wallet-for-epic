# SPDX-License-Identifier: Apache-2.0
"""Configuration of tools/rel: the step graph (release/pipeline.toml), the machine's hosts
(~/.config/btlabs/release-hosts.toml) and one release's scope (release.toml + command line).

Everything here is read-only and has no side effects, so `rel plan` and the tests use it as is.
"""
import copy
import os
import re
import tomllib

PLATFORMS = ("android", "linux", "windows", "macos", "ios")
VARIANTS = ("tor", "notor")
KINDS = ("command", "builtin", "gate", "handoff", "publish")
VERSION_RE = re.compile(r"^\d{2}\.\d{1,2}\.\d+(-rc\d+)?$")
MANIFEST_DAYS = 182  # [manifest] validity_days when pipeline.toml does not say
SKIP_NEVER = ("command", "builtin", "gate", "handoff")  # kinds that are skippable only when marked


class ConfigError(Exception):
    """A config or scope that makes no sense: the message says what and how to fix it."""


def expand(path):
    return os.path.expanduser(path) if isinstance(path, str) else path


def load_toml(path):
    try:
        with open(path, "rb") as f:
            return tomllib.load(f)
    except FileNotFoundError:
        raise ConfigError(f"{path}: not found")
    except tomllib.TOMLDecodeError as e:
        raise ConfigError(f"{path}: {e}")


def parse_duration(text):
    """'90m', '2h', '45s', '1d' or a number of seconds -> seconds (None for empty)."""
    if text in (None, ""):
        return None
    if isinstance(text, (int, float)):
        return float(text)
    m = re.fullmatch(r"\s*(\d+(?:\.\d+)?)\s*([smhd]?)\s*", str(text))
    if not m:
        raise ConfigError(f"duration {text!r}: use e.g. 45s, 90m, 2h, 1d")
    return float(m.group(1)) * {"": 1, "s": 1, "m": 60, "h": 3600, "d": 86400}[m.group(2)]


# ---- templates ---------------------------------------------------------------------------------

_PH = re.compile(r"\{\{|\}\}|\{([A-Za-z_][A-Za-z0-9_.-]*)\}")


def render(text, ctx, where=""):
    """Fills {name} and {a.b.c} from ctx (nested dicts); {{ and }} are literal braces. An unknown
    name is an error, so a typo in pipeline.toml fails at plan time, not mid-release."""
    if not isinstance(text, str):
        return text

    def sub(m):
        if m.group(0) == "{{":
            return "{"
        if m.group(0) == "}}":
            return "}"
        cur = ctx
        for part in m.group(1).split("."):
            if isinstance(cur, dict) and part in cur:
                cur = cur[part]
            else:
                raise ConfigError(f"{where}: unknown placeholder {{{m.group(1)}}}")
        if isinstance(cur, (dict, list)):
            raise ConfigError(f"{where}: {{{m.group(1)}}} is not a single value")
        return str(cur)

    return _PH.sub(sub, text)


# ---- pipeline ----------------------------------------------------------------------------------

def is_night(spec):
    return spec.get("when") == "night"


class Pipeline:
    def __init__(self, data, path="pipeline.toml"):
        self.path = path
        self.data = data
        self.defaults = data.get("defaults", {})
        self.relmsg = data.get("relmsg", {})
        self.proof = data.get("proof", {})
        self.steps = data.get("step", {})
        # How a drive shares the machine (tools/rellib/window.py) and when Android signing asks
        # for the owner's code (tools/rellib/signer.py).
        self.concurrency = data.get("concurrency", {})
        self.sign = data.get("sign", {})
        self.health = data.get("health", {})  # per-lane health (tools/rellib/health.py)
        self.serverlogs = data.get("serverlogs", {})  # server-side lines for a failed lane (tools/rellib/serverlogs.py)
        self.night = data.get("night", {})  # where `tools/rel start --night` keeps its runs
        self.ledger = data.get("ledger", {})  # the bug ledger file (Engine.record_bug)
        if not self.steps:
            raise ConfigError(f"{path}: no [step.*] tables")
        c = self.concurrency
        if "max_heavy" in c and (type(c["max_heavy"]) is not int or c["max_heavy"] < 1):
            raise ConfigError(f"{path}: [concurrency] max_heavy = {c['max_heavy']!r}: a whole number, 1 or more")
        if "infra_retries" in c and (type(c["infra_retries"]) is not int or not 0 <= c["infra_retries"] <= 3):
            raise ConfigError(f"{path}: [concurrency] infra_retries = {c['infra_retries']!r}: 0 to 3")
        for k in ("external_wait", "poll"):
            parse_duration(c.get(k))
        for k in ("apart", "apart_shared"):
            for pair in c.get(k, []):
                if not (isinstance(pair, list) and len(pair) == 2 and all(p in self.steps for p in pair)):
                    raise ConfigError(f"{path}: [concurrency] {k}: {pair!r} is not a pair of step names")
        h = self.health
        for k, ok in (("runs", lambda v: type(v) is int and v >= 1), ("min_runs", lambda v: type(v) is int and v >= 1),
                      ("min_first_try", lambda v: type(v) in (int, float) and 0 <= v <= 1)):
            if k in h and not ok(h[k]):
                raise ConfigError(f"{path}: [health] {k} = {h[k]!r}: " + ("a number from 0 to 1" if k == "min_first_try" else "a whole number, 1 or more"))
        if self.proof.get("funds_in", "proof") not in ("proof", "flow"):
            raise ConfigError(f"{path}: [proof] funds_in = {self.proof.get('funds_in')!r}: proof or flow")
        if self.sign.get("when", "inline") not in ("inline", "on-demand"):
            raise ConfigError(f"{path}: [sign] when = {self.sign.get('when')!r}: inline or on-demand")
        parse_duration(self.defaults.get("timeout"))
        for name, s in self.steps.items():
            kind = s.get("kind", "command")
            if kind not in KINDS:
                raise ConfigError(f"{path}: step {name}: kind {kind!r} is not one of {', '.join(KINDS)}")
            if kind in ("command", "handoff") and not s.get("run") and not s.get("proof"):
                raise ConfigError(f"{path}: step {name}: a {kind} step needs `run`")
            if kind == "publish" and not s.get("run"):
                raise ConfigError(f"{path}: step {name}: a publish step needs `run`")
            for n in s.get("needs", []):
                if n.split("@")[0] not in self.steps:
                    raise ConfigError(f"{path}: step {name} needs unknown step {n}")
            pl = s.get("platform")
            for p in ([pl] if isinstance(pl, str) else (pl or [])):
                if p not in PLATFORMS:
                    raise ConfigError(f"{path}: step {name}: unknown platform {p}")
            parse_duration(s.get("timeout"))
            when = s.get("when", [])
            if isinstance(when, str) and when != "night":
                raise ConfigError(f"{path}: step {name}: when = {when!r}: \"night\" or a list of scope switches")
            if not is_night(s):
                for n in s.get("needs", []):
                    if is_night(self.steps[n.split("@")[0]]):
                        raise ConfigError(f"{path}: step {name} is in the release but needs night step {n}")
            for v in s.get("variants", []):
                if v not in VARIANTS:
                    raise ConfigError(f"{path}: step {name}: unknown variant {v}")
            for v, over in (s.get("by_variant") or {}).items():
                if v not in VARIANTS:
                    raise ConfigError(f"{path}: step {name}: by_variant: unknown variant {v}")
                if not s.get("for_each") or set(over) - {"run", "results", "outputs", "title"}:
                    raise ConfigError(f"{path}: step {name}: by_variant needs for_each and sets only run, results, outputs, title")
            # warn_only: a failure is shown as a warning and holds nothing. For what comes after the
            # release is live, and for a pre-gate step another step judges (the screens render,
            # judged by screens-check); a gate, a proof or a build never just warns.
            if s.get("warn_only") and (kind in ("gate", "builtin", "handoff") or s.get("proof") or s.get("outputs")):
                raise ConfigError(f"{path}: step {name}: warn_only is never for a gate, proof or build")
        from . import hosted  # [hosted] and the build steps' `hosted` keys (tools/rellib/hosted.py)
        hosted.check_pipeline(self)
        self._check_cycles()

    def _check_cycles(self):
        seen, stack = set(), set()

        def visit(n):
            if n in stack:
                raise ConfigError(f"{self.path}: the needs of step {n} form a cycle")
            if n in seen:
                return
            stack.add(n)
            for d in self.steps[n].get("needs", []):
                visit(d.split("@")[0])
            stack.discard(n)
            seen.add(n)

        for n in self.steps:
            visit(n)

    @classmethod
    def load(cls, path):
        return cls(load_toml(path), path)

    def manifest_days(self):
        """[manifest] validity_days: how long a signed update manifest is valid (1-400 days)."""
        days = self.data.get("manifest", {}).get("validity_days", MANIFEST_DAYS)
        if type(days) is not int or not 1 <= days <= 400:
            raise ConfigError(f"{self.path}: [manifest] validity_days = {days!r}: a whole number of days, 1 to 400 "
                              "(clients accept at most 400)")
        return days

    def manifest_warn_days(self):
        return int(self.data.get("manifest", {}).get("warn_days", 14))

    def state_root(self, override=None):
        return expand(override or os.environ.get("REL_STATE_ROOT") or self.defaults.get("state_root", "/tmp/epic-build/rel"))

    def night_root(self):
        """Where night runs live: their own run folders, and lanes/<sha>.json beside them."""
        return expand(os.environ.get("REL_NIGHT_ROOT") or self.night.get("state_root", "/tmp/epic-build/nightly/rel"))

    def stage_steps(self, stage):
        """The step names of a stage. release: every step without `when = "night"`. night: the night
        steps and what they need (scope, preflight, source, G2)."""
        if stage == "release":
            return {n for n, s in self.steps.items() if not is_night(s)}
        names, todo = set(), [n for n, s in self.steps.items() if is_night(s)]
        while todo:
            n = todo.pop()
            if n not in names:
                names.add(n)
                todo.extend(d.split("@")[0] for d in self.steps[n].get("needs", []))
        return names


# ---- hosts -------------------------------------------------------------------------------------

def hosts_path():
    return expand(os.environ.get("REL_HOSTS") or "~/.config/btlabs/release-hosts.toml")


def load_hosts(path=None):
    """The machine's release-hosts.toml; empty roles when the file is missing (doctor says so)."""
    path = path or hosts_path()
    data = load_toml(path) if os.path.exists(path) else {}
    hosts = {k: {kk: expand(vv) for kk, vv in v.items()} for k, v in data.get("host", {}).items()}
    paths = {k: expand(v) for k, v in data.get("paths", {}).items()}
    return {"host": hosts, "path": paths, "serverlogs": data.get("serverlogs", {}), "file": path,
            "exists": os.path.exists(path)}


# ---- scope -------------------------------------------------------------------------------------

DEFAULT_SCOPE = {
    "version": "",
    "test": False,
    "platforms": {p: True for p in PLATFORMS},
    "variants": {v: True for v in VARIANTS},
    "stores": {"play": False, "play_promote": ""},
    "publish": {"target": "live", "manifests": True, "notes": "", "github": True},
    "apple": {"signed": True},
    "skip": {},
    "proof": {"previous_dir": "", "previous_version": "", "previous_ref": "", "waive": {}},
}


def _merge(base, over, where):
    out = copy.deepcopy(base)
    for k, v in over.items():
        if k not in base:
            raise ConfigError(f"{where}: unknown key {k!r} (known: {', '.join(base)})")
        if isinstance(base[k], dict) and k not in ("skip", "waive"):
            if not isinstance(v, dict):
                raise ConfigError(f"{where}: {k} must be a table")
            out[k] = _merge(base[k], v, f"{where} [{k}]")
        elif isinstance(base[k], dict):
            if not isinstance(v, dict):
                raise ConfigError(f"{where}: {k} must be a table")
            out[k] = dict(v)
        else:
            if type(v) is not type(base[k]):
                raise ConfigError(f"{where}: {k} = {v!r} must be a {type(base[k]).__name__}")
            out[k] = v
    return out


def _parse_bool(text, where):
    t = str(text).strip().lower()
    if t in ("true", "yes", "on", "1"):
        return True
    if t in ("false", "no", "off", "0"):
        return False
    raise ConfigError(f"{where}: {text!r} is not true or false")


def _split(text):
    return [x.strip() for x in str(text).split(",") if x.strip()]


def load_scope(path=None, version=None, only=None, skip_platform=None, no_variant=None,
               sets=None, skips=None, test=None, target=None, waive=None):
    """release.toml (or the defaults) + command-line overrides, unvalidated (see validate_scope)."""
    scope = copy.deepcopy(DEFAULT_SCOPE)
    if path:
        scope = _merge(scope, load_toml(path), path)
    if version:
        if scope["version"] and scope["version"] != version:
            raise ConfigError(f"the version on the command line ({version}) differs from {path} ({scope['version']})")
        scope["version"] = version
    if only:
        names = _split(only)
        for p in names:
            if p not in PLATFORMS:
                raise ConfigError(f"--only {p}: not a platform (one of {', '.join(PLATFORMS)})")
        scope["platforms"] = {p: p in names for p in PLATFORMS}
    for p in _split(skip_platform or ""):
        if p not in PLATFORMS:
            raise ConfigError(f"--skip-platform {p}: not a platform (one of {', '.join(PLATFORMS)})")
        scope["platforms"][p] = False
    for v in _split(no_variant or ""):
        if v not in VARIANTS:
            raise ConfigError(f"--no-variant {v}: not a variant (tor or notor)")
        scope["variants"][v] = False
    for item in sets or []:
        if "=" not in item:
            raise ConfigError(f"--set {item}: use key.sub=value, e.g. stores.play=true")
        key, val = item.split("=", 1)
        parts = key.strip().split(".")
        cur, ref = scope, DEFAULT_SCOPE
        for p in parts[:-1]:
            if p not in ref or not isinstance(ref[p], dict):
                raise ConfigError(f"--set {key}: unknown key")
            cur, ref = cur[p], ref[p]
        last = parts[-1]
        if last not in ref:
            raise ConfigError(f"--set {key}: unknown key")
        if isinstance(ref[last], bool):
            cur[last] = _parse_bool(val, f"--set {key}")
        elif isinstance(ref[last], str):
            cur[last] = val
        else:
            raise ConfigError(f"--set {key}: a table; set its keys one by one")
    for item in skips or []:
        if "=" not in item or not item.split("=", 1)[1].strip():
            raise ConfigError(f"--skip {item}: give a reason, e.g. --skip publish-source=\"token renewal\"")
        k, v = item.split("=", 1)
        scope["skip"][k.strip()] = v.strip()
    for item in waive or []:
        if "=" not in item or not item.split("=", 1)[1].strip():
            raise ConfigError(f"--waive {item}: give a reason, e.g. --waive macos=\"no Apple update test yet\"")
        k, v = item.split("=", 1)
        scope["proof"]["waive"][k.strip()] = v.strip()
    if test is not None:
        scope["test"] = bool(test) or scope["test"]
    if target:
        scope["publish"]["target"] = target
    if scope["test"]:
        scope["publish"]["target"] = "scratch"
    return scope


def validate_scope(scope, pipeline, version_at_commit=None, previous_version=None, base_steps=None, carried=None):
    """Refuses a scope that makes no sense, with one message per problem. Returns warnings.
    carried: the platforms a follow-up run carries from the published run it adds to."""
    carried = list(carried or [])
    errs, warns = [], []
    v = scope["version"]
    if not v:
        errs.append("no version: give it on the command line (tools/rel start 26.10.25) or in release.toml")
    elif not VERSION_RE.match(v):
        errs.append(f"version {v}: must be YY.MM.patch (or YY.MM.patch-rcN for a test build), https://docs.btlabs.uk/developers/releases/")
    elif version_at_commit and v != version_at_commit:
        errs.append(f"version {v} differs from app/pubspec.yaml at the commit ({version_at_commit}): "
                    "the release lead sets it with tools/version.sh set on the release commit first")
    if v and "-rc" in v and scope["publish"]["target"] == "live":
        errs.append(f"{v} is a test build (-rcN): never published live; use --test or publish.target = \"scratch\"")
    if scope["publish"]["target"] not in ("live", "scratch"):
        errs.append(f"publish.target {scope['publish']['target']!r}: live or scratch")
    if scope["test"] and scope["publish"]["target"] != "scratch":
        errs.append("a TEST run publishes only to scratch")
    if previous_version and not VERSION_RE.match(previous_version):
        errs.append(f"the previous release's version {previous_version!r} is not a version: "
                    "set [proof] previous_version (or name the folder after it)")
        previous_version = None
    if previous_version and v and VERSION_RE.match(v):
        key = lambda s: tuple(int(x) for x in s.split("-")[0].split("."))
        if key(v) <= key(previous_version):
            (warns if scope["test"] else errs).append(
                f"version {v} is not newer than the previous release {previous_version}"
                + (" (allowed in a TEST run only)" if scope["test"] else ": apps would not offer it"))
    plats = [p for p in PLATFORMS if scope["platforms"].get(p)]
    for p in scope["platforms"]:
        if p not in PLATFORMS:
            errs.append(f"[platforms] {p}: unknown platform")
    vars_ = [x for x in VARIANTS if scope["variants"].get(x)]
    if not plats:
        errs.append("no platform in scope: nothing to release")
    if not vars_:
        errs.append("no variant in scope: switch on tor, notor or both")
    if scope["stores"].get("play") and not scope["platforms"].get("android"):
        errs.append("stores.play needs android in scope")
    promote = scope["stores"].get("play_promote") or ""
    if promote and not scope["stores"].get("play"):
        errs.append("stores.play_promote needs stores.play (the bundle is uploaded to internal first)")
    if promote in ("internal", "production"):
        errs.append(f"stores.play_promote = {promote!r}: a testing track after internal (e.g. beta); "
                    "production stays a click in Play Console")
    if promote and not scope["variants"].get("tor"):
        errs.append("stores.play_promote needs the tor variant (Play takes the build with Tor)")
    if scope["platforms"].get("ios") and not scope.get("apple", {}).get("signed", True) and not scope["variants"].get("notor"):
        errs.append("Apple ad hoc ios needs the notor variant (the one unsigned ipa is the build without Tor): "
                    "keep notor or leave ios out")
    if scope["publish"]["manifests"]:
        if not scope["platforms"].get("android") and "android" not in carried:
            errs.append("publish.manifests needs android in scope (app/tool/release_android.sh builds the manifest "
                        "from the APKs): add android or set publish.manifests = false (then no app is offered the update)")
        elif not all(scope["variants"].values()):
            errs.append("publish.manifests needs both variants (the manifest names the Tor APK at the top level and the "
                        "-notor APK in its notor section): keep both or set publish.manifests = false")
    if scope["publish"].get("github") and "publish-source" in scope["skip"]:
        errs.append("publish.github needs publish-source (it puts the tag on GitHub, where the release is made): "
                    "do not skip it, or set publish.github = false")
    notes = scope["publish"].get("notes", "")
    if "\t" in notes or "\r" in notes:
        errs.append("publish.notes: no tabs or carriage returns")
    steps = pipeline.steps
    for name, reason in scope["skip"].items():
        if name not in steps:
            errs.append(f"[skip] {name}: no such step (release/pipeline.toml)")
            continue
        s = steps[name]
        if not s.get("skippable"):
            kind = s.get("kind", "command")
            what = "a gate" if kind == "gate" or name.startswith(("trust-", "update-trust", "artefacts", "preflight", "scope", "source")) else f"a {kind} step"
            fix = ("to drop a platform or variant, switch it off in [platforms] / [variants]"
                   if name.startswith(("build-", "apple-")) else
                   "to ship a platform without the update proof, waive it in [proof.waive]"
                   if name.startswith("trust-") else "gates never skip")
            errs.append(f"[skip] {name}: {what} cannot be skipped ({fix})")
        if not str(reason).strip():
            errs.append(f"[skip] {name}: give a reason")
    for p, reason in scope["proof"]["waive"].items():
        if p not in PLATFORMS:
            errs.append(f"[proof.waive] {p}: not a platform")
        elif not scope["platforms"].get(p):
            errs.append(f"[proof.waive] {p}: not in scope, nothing to waive")
        elif not str(reason).strip():
            errs.append(f"[proof.waive] {p}: give a reason")
    left = [p for p in ("windows", "linux", "macos") if not scope["platforms"].get(p) and p not in carried]
    if left and scope["publish"].get("manifests"):
        warns.append(f"{', '.join(left)} out of scope: the update manifests keep those systems' live entries, "
                     "and the releases page, SHA256SUMS and the server keep their newest files")
    if errs:
        raise ConfigError("the release scope makes no sense:\n  - " + "\n  - ".join(errs))
    return warns


def scope_summary(scope):
    """One line for Telegram and the report."""
    plats = [p for p in PLATFORMS if scope["platforms"].get(p)]
    out = [p for p in PLATFORMS if not scope["platforms"].get(p)]
    vars_ = "+".join(v for v in VARIANTS if scope["variants"].get(v))
    parts = [f"{', '.join(plats) or 'nothing'} ({vars_})"]
    if out:
        parts.append(f"out of scope: {', '.join(out)}")
    stores = [k for k in ("play",) if scope["stores"].get(k)]
    if stores and scope["stores"].get("play_promote"):
        stores = [f"play (internal, then {scope['stores']['play_promote']})"]
    if stores:
        parts.append(f"stores: {', '.join(stores)}")
    if not scope["publish"]["manifests"]:
        parts.append("no update manifests")
    if not scope.get("apple", {}).get("signed", True) and (scope["platforms"].get("macos") or scope["platforms"].get("ios")):
        parts.append("Apple ad hoc (dmg not notarised, iOS unsigned ipa)")
    if scope["publish"].get("github"):
        parts.append("GitHub release mirror")
    if (scope.get("builds") or {}).get("hosted"):
        local = (scope.get("builds") or {}).get("local")
        fb = (scope.get("builds") or {}).get("fallback") == "local"
        parts.append("builds on GitHub runners" + (f" ({local} on this machine)" if local else "")
                     + ("; a failed one is built locally" if fb else ""))
    if scope["skip"]:
        parts.append("skip: " + "; ".join(f"{k} ({v})" for k, v in scope["skip"].items()))
    if scope["proof"]["waive"]:
        parts.append("NOT PROVEN (waived): " + "; ".join(f"{k} ({v})" for k, v in scope["proof"]["waive"].items()))
    parts.append(f"target: {scope['publish']['target']}")
    return " · ".join(parts)


def scope_toml(scope):
    """The resolved scope as release.toml text (kept in the run folder)."""
    def val(v):
        if isinstance(v, bool):
            return "true" if v else "false"
        return '"' + str(v).replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'

    lines = ["# The resolved scope of this run (release.toml + command line).",
             f"version = {val(scope['version'])}", f"test = {val(scope['test'])}"]
    for table in ("platforms", "variants", "stores", "publish", "apple", "skip", "builds"):
        if table == "builds" and table not in scope:
            continue  # only --builds hosted sets it (tools/rel start)
        lines.append(f"\n[{table}]")
        for k, v in scope.get(table, {}).items():  # runs from before a table was added lack it
            lines.append(f"{k if re.fullmatch(r'[A-Za-z0-9_-]+', k) else val(k)} = {val(v)}")
    lines.append("\n[proof]")
    for k in ("previous_dir", "previous_version", "previous_ref"):
        lines.append(f"{k} = {val(scope['proof'][k])}")
    lines.append("\n[proof.waive]")
    for k, v in scope["proof"]["waive"].items():
        lines.append(f"{k} = {val(v)}")
    return "\n".join(lines) + "\n"
