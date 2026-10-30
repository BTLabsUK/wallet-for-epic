# SPDX-License-Identifier: Apache-2.0
"""The step graph of one run: pipeline.toml's steps, filtered by the scope, expanded per variant,
with every {placeholder} filled in. Pure: no files are touched."""
from dataclasses import dataclass, field, asdict

from .config import ConfigError, PLATFORMS, VARIANTS, parse_duration, render


@dataclass
class Step:
    id: str
    base: str
    kind: str
    title: str
    host: str
    lane: str
    platforms: list
    variant: str = None
    needs: list = field(default_factory=list)
    run: str = None
    cwd: str = None
    env: dict = field(default_factory=dict)
    heavy: bool = False
    outputs: list = field(default_factory=list)
    extras: list = field(default_factory=list)
    results: list = field(default_factory=list)
    send: list = field(default_factory=list)
    proof: bool = False
    publish: bool = False
    skippable: bool = False
    timeout: float = None
    retries: int = 0
    scratch: str = None

    @property
    def phase(self):
        return "publish" if self.publish else "build"

    def to_dict(self):
        return asdict(self)

    @classmethod
    def from_dict(cls, d):
        return cls(**d)


def _in_scope(spec, scope):
    pl = spec.get("platform")
    if pl:
        pls = [pl] if isinstance(pl, str) else pl
        if not any(scope["platforms"].get(p) for p in pls):
            return False
    for w in spec.get("when", []):
        cur = scope
        for part in w.split("."):
            cur = cur.get(part) if isinstance(cur, dict) else None
        if not cur:
            return False
    return True


def variants_for(spec, scope, pipeline):
    fe = spec.get("for_each")
    if not fe:
        return [None]
    if fe == "variant":
        return [v for v in VARIANTS if scope["variants"].get(v)]
    if fe == "proof_variant":
        allowed = pipeline.proof.get("variants", list(VARIANTS))
        return [v for v in VARIANTS if scope["variants"].get(v) and v in allowed]
    raise ConfigError(f"for_each {fe!r}: variant or proof_variant")


def lane_of(spec, host):
    """Steps in one lane run one at a time: heavy local builds share the machine; each remote
    host is its own lane; a hand-off waits on another person's Mac. A step's own `lane` ({variant}
    filled in) puts it in that lane instead."""
    if spec.get("heavy"):
        return "heavy"
    if host in ("local", "build", "signer"):
        return "local"
    return host


def build_graph(pipeline, scope, ctx):
    """-> ordered list of Step (topological, pipeline order among equals)."""
    instances = {}
    for name, spec in pipeline.steps.items():
        if not _in_scope(spec, scope):
            continue
        instances[name] = variants_for(spec, scope, pipeline)
    steps = []
    for name, vars_ in instances.items():
        spec = pipeline.steps[name]
        kind = spec.get("kind", "command")
        host = spec.get("host", "build")
        for var in vars_:
            sid = f"{name}-{var}" if var else name
            c = dict(ctx)
            c["variant"] = var or ""
            c["notor"] = "-notor" if var == "notor" else ""
            c["tor"] = "0" if var == "notor" else "1"
            c["stage"] = f"{ctx['run']}/steps/{sid}/out"
            where = f"step {sid}"
            needs = []
            for n in spec.get("needs", []):
                base, _, at = n.partition("@")
                if base not in instances:
                    continue  # out of scope
                if at:
                    if var is None or var not in instances[base]:
                        continue
                    needs.append(f"{base}-{var}")
                else:
                    needs.extend(f"{base}-{v}" if v else base for v in instances[base])
            run = spec.get("run")
            if spec.get("proof") and not run:
                plat = spec["platform"]
                driver = pipeline.proof.get("drivers", {}).get(plat)
                run = driver or f"echo 'no update-trust driver for {plat} (release/pipeline.toml [proof.drivers])' >&2; exit 2"
            step = Step(
                id=sid, base=name, kind=kind,
                title=render(spec.get("title", name), {"variant": var or ""}, where),
                host=host, lane=render(spec["lane"], c, where) if spec.get("lane") else lane_of(spec, host),
                platforms=([spec["platform"]] if isinstance(spec.get("platform"), str) else list(spec.get("platform") or [])),
                variant=var, needs=needs,
                run=render(run, c, where) if run else None,
                cwd=render(spec.get("cwd", "{src}"), c, where),
                env={k: render(str(v), c, where) for k, v in spec.get("env", {}).items()},
                heavy=bool(spec.get("heavy")),
                outputs=[render(o, c, where) for o in spec.get("outputs", [])],
                extras=[render(o, c, where) for o in spec.get("extras", [])],
                results=[render(o, c, where) for o in spec.get("results", [])],
                send=[render(o, c, where) for o in spec.get("send", [])],
                proof=bool(spec.get("proof")),
                publish=bool(spec.get("publish")) or kind == "publish",
                skippable=bool(spec.get("skippable")),
                timeout=parse_duration(spec.get("timeout")),
                retries=int(spec.get("retries", 0)),
                scratch=spec.get("scratch"),
            )
            steps.append(step)
    return topo(steps)


def topo(steps):
    by_id = {s.id: s for s in steps}
    order, done, temp = [], set(), set()

    def visit(s):
        if s.id in done:
            return
        if s.id in temp:
            raise ConfigError(f"cycle at {s.id}")
        temp.add(s.id)
        for n in s.needs:
            visit(by_id[n])
        temp.discard(s.id)
        done.add(s.id)
        order.append(s)

    for s in steps:
        visit(s)
    # Publish-phase steps never come before build-phase ones they do not depend on.
    return order


def dependents(steps, sid):
    """Every step that (transitively) needs sid."""
    out, frontier = set(), {sid}
    while frontier:
        nxt = {s.id for s in steps if set(s.needs) & frontier} - out
        out |= nxt
        frontier = nxt
    return out


def platforms_in(scope):
    return [p for p in PLATFORMS if scope["platforms"].get(p)]
