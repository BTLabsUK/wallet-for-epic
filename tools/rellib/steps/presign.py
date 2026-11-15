#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""Step `presign` of tools/rel, after verify-live: signs the rollback pair ladder of the live
release and the previous one (tools/rellib/presign.py) and puts the previous release's pair on its
GitHub release, so `tools/rel rollback` later signs nothing. Never holds the release.

  presign.py <version> <stage dir>"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
from rellib.config import Pipeline, load_hosts  # noqa: E402
from rellib.presign import Presign  # noqa: E402
from rellib.resign import ResignError  # noqa: E402
from rellib.server import Server, ServerError  # noqa: E402


def main(argv):
    version, stage = argv[0], argv[1]
    repo = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
    pipeline = Pipeline.load(os.path.join(repo, "release/pipeline.toml"))
    hosts = load_hosts(None)
    server = Server(repo, hosts)
    p = Presign(repo, pipeline.state_root(None), pipeline, hosts, server)
    try:
        st = server.state()
        if not st.get("live"):
            print("the server has no version folders yet (tools/rel migrate-layout): nothing to pre-sign")
            return 0
        if st["live"] != version:
            print(f"live is {st['live']}, not {version}: pre-signing for the live release anyway")
        res = p.refresh(os.path.join(stage, "presign"))
    except (ResignError, ServerError) as e:
        print(f"presign failed: {e}", file=sys.stderr)
        return 1
    print(f"rollback pairs ready: {res}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
