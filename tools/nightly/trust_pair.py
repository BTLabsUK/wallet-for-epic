#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""The night's update trust on one platform, as a tools/rel step (release/pipeline.toml trust-pair-*):
the previous published release updates to the last published one. The candidate's own update test is
G4 in the release stage. Exit: the driver's, 1 when it ended with no proof or a check not true."""
import json
import os
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import nightly  # noqa: E402


def main(platform, variant):
    prev, cand = nightly.published_pair(None)
    if prev is None:
        print(f"trust-pair: {cand}", flush=True)
        return 2
    extra, why = nightly.trust_inputs(platform, prev, cand, variant)
    if extra is None:
        print(f"trust-pair: {why}", flush=True)
        return 2
    out = Path(os.environ["REL_OUT"])
    out.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ, REL_VARIANT=variant, REL_FUNDS="1" if variant == "tor" else "0",
               REL_NODE=nightly.TRUST_NODE, REL_EPICBOX=nightly.TRUST_EPICBOX,
               REL_CANDIDATE_REF="v" + cand["version"], **extra)
    print(f"trust-pair: {platform} {variant}, {prev['version']} to {cand['version']}", flush=True)
    rc = subprocess.call([str(HERE.parent / "rellib" / "drivers" / f"trust-{platform}.sh")], env=env)
    try:
        proof = json.loads((out / "proof.json").read_text())
    except (OSError, ValueError):
        print("trust-pair: no proof.json", flush=True)
        return rc or 1
    failing = nightly.failing_checks(proof)
    if failing:
        print("trust-pair: not proven: " + ", ".join(failing), flush=True)
    return rc or (1 if failing else 0)


if __name__ == "__main__":
    sys.exit(main(*sys.argv[1:3]))
