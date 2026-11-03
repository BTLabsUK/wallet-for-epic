#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""A build step of a `tools/rel start --builds hosted` run: waits for its job of the run that
hosted-dispatch started, downloads the artifact <platform>-<variant>, verifies it, places the
files in <stage> as the local build would and writes <stage>/built_by.json
(tools/rellib/hosted.py Fetch). Exit 0 when the files are in place; else 1 with the reason.

Usage: build-fetch.py <android|linux|windows> <tor|notor> <stage dir>   (REL_RUN: the run folder)"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
from rellib import hosted  # noqa: E402
from rellib.run import Run  # noqa: E402
from rellib.window import SSH_DROP  # noqa: E402


def say(msg):
    # No automatic retry of a hosted step: a network error in gh's output must not read as an ssh
    # drop, which tools/rel retries by itself (window.cause_of).
    print(SSH_DROP.sub(lambda m: "[network] " + m.group(0).replace(" ", "_"), str(msg)), flush=True)


def main(argv):
    if len(argv) != 3 or argv[0] not in hosted.HOSTED_PLATFORMS or argv[1] not in ("tor", "notor"):
        print(__doc__.strip().splitlines()[-1], file=sys.stderr)
        return 2
    platform, variant, stage = argv
    stage = os.path.abspath(stage)
    run = Run(os.environ.get("REL_RUN") or os.path.dirname(os.path.dirname(os.path.dirname(stage))))
    sid = os.path.basename(os.path.dirname(stage))
    os.makedirs(stage, exist_ok=True)
    return hosted.Fetch(run, sid, platform, variant, stage, say=say).main()


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
