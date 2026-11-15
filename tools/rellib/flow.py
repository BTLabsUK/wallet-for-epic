# SPDX-License-Identifier: Apache-2.0
"""The release flow as data: the stages in order with class, needs and outputs (`tools/rel flow`, the
header block of pipeline.toml), and the cut of a release branch (`tools/rel cut`)."""
import os
import subprocess
import tempfile

from .config import ConfigError

BEGIN = "# flow:begin"
END = "# flow:end"
ORDER = ("common", "release", "publish")
# The checks every run makes first (G0, G1, the source, G2): source-check and what it needs.
COMMON_TO = "source-check"


def class_of(spec):
    return "informs" if spec.get("warn_only") else "blocks"


def _common(pipeline):
    names, todo = set(), [COMMON_TO] if COMMON_TO in pipeline.steps else []
    while todo:
        n = todo.pop()
        if n not in names:
            names.add(n)
            todo.extend(d.split("@")[0] for d in pipeline.steps[n].get("needs", []))
    return names


def _stage_of(name, spec, common):
    if spec.get("publish") or spec.get("kind") == "publish":
        return "publish"
    return "common" if name in common else "release"


def flow_stages(pipeline):
    """The steps by name, in the order they run: the common checks, the release up to the gate, publish."""
    common = _common(pipeline)
    seen, order = set(), []

    def visit(name):
        if name in seen:
            return
        seen.add(name)
        for n in pipeline.steps[name].get("needs", []):
            visit(n.split("@")[0])
        order.append(name)

    for name in pipeline.steps:
        visit(name)
    rows = []
    for name in order:
        spec = pipeline.steps[name]
        rows.append({"name": name, "title": spec.get("title", name), "stage": _stage_of(name, spec, common),
                     "class": class_of(spec), "kind": spec.get("kind", "command"),
                     "needs": list(spec.get("needs", [])), "outputs": list(spec.get("outputs", []))})
    rows.sort(key=lambda r: ORDER.index(r["stage"]))  # stable: the order inside a stage stays
    return rows


def flow_lines(pipeline):
    """One line per stage: what `tools/rel flow` prints and the header block of pipeline.toml holds."""
    lines = []
    for r in flow_stages(pipeline):
        lines.append(f"{r['stage']:8} {r['class']:8} {r['name']:24} needs {', '.join(r['needs']) or '-'}"
                     + (f"; outputs {', '.join(r['outputs'])}" if r["outputs"] else ""))
    return lines


def header_block(pipeline):
    return "\n".join([BEGIN + " (tools/rel flow --write; a test fails when it differs from the steps below)",
                      *("# " + x for x in flow_lines(pipeline)), END])


def header_lines(text):
    """The stage lines in pipeline.toml's header block, without the comment mark."""
    if BEGIN not in text or END not in text:
        return None
    body = text[text.index(BEGIN):text.index(END)].splitlines()[1:]
    return [x[2:] for x in body]


def rewrite_header(text, pipeline):
    if BEGIN not in text or END not in text:
        raise ConfigError(f"no {BEGIN} block in the pipeline file")
    a, b = text.index(BEGIN), text.index(END) + len(END)
    return text[:a] + header_block(pipeline) + text[b:]


# ---- the cut ----

def make_cut(main, version, base, work_root):
    """Branch release/<version> at base plus the version commit. -> (tip, made). A branch that is
    already there and has the version stands: main may move, the branch does not."""
    def git(*args, cwd=main):
        return subprocess.run(["git", "-C", cwd, *args], capture_output=True, text=True, check=False)

    branch = f"release/{version}"
    tip = git("rev-parse", "-q", "--verify", f"refs/heads/{branch}").stdout.strip()
    if tip:
        have = git("show", f"{tip}:app/lib/src/app_version.dart").stdout
        if f"appVersion = '{version}';" not in have:
            raise ConfigError(f"{branch} exists without version {version}: look at it before cutting again")
        return tip, False
    os.makedirs(work_root, exist_ok=True)
    wt = tempfile.mkdtemp(prefix=".cut-", dir=work_root)
    add = git("worktree", "add", "-q", "--force", "--detach", wt, base)
    if add.returncode:
        os.rmdir(wt)
        raise ConfigError(f"git worktree add: {add.stderr.strip()}")
    try:
        v = subprocess.run(["bash", os.path.join(wt, "tools", "version.sh"), "set", version], capture_output=True, text=True, check=False)
        if v.returncode:
            raise ConfigError(f"tools/version.sh set {version}: {(v.stderr or v.stdout).strip()}")
        git("add", "app/pubspec.yaml", "app/lib/src/app_version.dart", cwd=wt)
        if git("diff", "--cached", "--quiet", cwd=wt).returncode:
            done = git("commit", "-q", "-m", f"Set the version to {version}", cwd=wt)
            if done.returncode:
                raise ConfigError(f"git commit: {done.stderr.strip()}")
        tip = git("rev-parse", "HEAD", cwd=wt).stdout.strip()
        made = git("branch", branch, tip)
        if made.returncode:
            raise ConfigError(f"git branch {branch}: {made.stderr.strip()}")
    finally:
        git("worktree", "remove", "--force", wt)
    return tip, True
