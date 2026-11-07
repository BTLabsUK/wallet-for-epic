# SPDX-License-Identifier: Apache-2.0
"""Runs that stay on older tools. A version named in <state root>/.tool-pins.toml runs on that
checkout of tools/rel: its plan, its drivers and its publish steps stop moving with main. tools/rel
hands such a command over before anything else loads. Nothing else reads the file."""
import os
import sys
import tomllib

ACTING = {"resume", "publish", "sign", "run", "retry", "skip", "debug", "gate", "gate-watch", "report", "status", "logs"}


def pins_path(argv):
    if "--state-root" in argv[:-1]:
        return os.path.join(argv[argv.index("--state-root") + 1], ".tool-pins.toml")
    return os.path.join(os.path.expanduser("/tmp/epic-build/rel"), ".tool-pins.toml")


def named_version(argv, versions):
    """The pinned version this command is about, or None. A command without --run acts on the newest run."""
    for a in argv:
        for v in versions:
            if a == v or a.startswith(f"{v}-run") or f"/{v}/" in a:
                return v
    if "--run" in argv or not ACTING & set(argv):
        return None
    root = os.path.dirname(pins_path(argv))
    newest, stamp = None, ""
    for v in os.listdir(root):
        vdir = os.path.join(root, v)
        if v.startswith(".") or not os.path.isdir(vdir):
            continue
        for d in os.listdir(vdir):
            info = os.path.join(vdir, d, "run.json")
            if os.path.isfile(info) and os.path.getmtime(info) > (float(stamp) if stamp else 0):
                newest, stamp = v, str(os.path.getmtime(info))
    return newest if newest in versions else None


def target(argv):
    """The pinned tools/rel for this command, or None."""
    try:
        with open(pins_path(argv), "rb") as f:
            pins = tomllib.load(f)
    except (OSError, tomllib.TOMLDecodeError):
        return None
    v = named_version(argv, pins)
    return os.path.join(pins[v], "tools/rel") if v else None


def follow(argv):
    """Hands the command to the pinned checkout when it has one; returns otherwise."""
    rel = target(argv)
    here = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    if rel and os.path.dirname(os.path.dirname(rel)) != here:
        os.execv(rel, [rel, *argv])
