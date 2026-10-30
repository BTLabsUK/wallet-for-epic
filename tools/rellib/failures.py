# SPDX-License-Identifier: Apache-2.0
"""release/failures.toml: log patterns of failures seen before, and the fix that worked."""
import re

from .config import load_toml


def load(path):
    try:
        return load_toml(path).get("failure", [])
    except Exception:
        return []


def match(failures, base_step, log_path, max_bytes=200_000):
    """-> [(id, hint)] of every known failure whose pattern is in the log's tail."""
    try:
        with open(log_path, "rb") as f:
            f.seek(0, 2)
            size = f.tell()
            f.seek(max(0, size - max_bytes))
            text = f.read().decode("utf-8", "replace")
    except OSError:
        return []
    hits = []
    for fl in failures:
        steps = fl.get("steps")
        if steps and base_step not in steps:
            continue
        try:
            if re.search(fl["pattern"], text, re.IGNORECASE | re.MULTILINE):
                hits.append((fl["id"], fl["hint"]))
        except re.error:
            continue
    return hits


def tail(log_path, lines=60):
    try:
        with open(log_path, "rb") as f:
            f.seek(0, 2)
            size = f.tell()
            f.seek(max(0, size - 64_000))
            return "\n".join(f.read().decode("utf-8", "replace").splitlines()[-lines:])
    except OSError:
        return ""
