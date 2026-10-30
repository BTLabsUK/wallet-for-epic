# SPDX-License-Identifier: Apache-2.0
"""Fixtures for tools/rel's tests: a small pipeline of fake steps, a fake relmsg, temp roots."""
import json
import os
import shutil
import stat
import sys
import tempfile
import textwrap
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(os.path.dirname(HERE)))

from rellib import builtins  # noqa: E402
from rellib.config import Pipeline, load_scope, scope_toml, validate_scope  # noqa: E402
from rellib.engine import Engine  # noqa: E402
from rellib.graph import build_graph  # noqa: E402
from rellib.relmsg import Relmsg  # noqa: E402
from rellib.run import Run  # noqa: E402

REPO = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))

FAKE_PIPELINE = """
[defaults]
heavy_wrap = []
min_free_gb = 0
nodes = ["https://node.example"]
epicboxes = ["box.example"]

[relmsg]
bin = "relmsg"

[proof]
checks = ["wallet_opens", "history_kept"]
funds_checks = ["send_ok"]
funds_variant = "tor"
variants = ["tor"]

[proof.drivers]
android = "bash {src}/driver.sh"
linux = "bash {src}/driver.sh"

[step.scope]
kind = "builtin"
host = "local"

[step.build-android]
platform = "android"
for_each = "variant"
needs = ["scope"]
run = "echo build {variant} >> {src}/calls; test ! -e {src}/fail-{variant}; mkdir -p {stage}/emulator; head -c 2000000 /dev/zero > {stage}/epic-cash-mobile-{version}{notor}-arm64-v8a.apk; touch {stage}/emulator/x{notor}.apk"
outputs = ["epic-cash-mobile-{version}{notor}-arm64-v8a.apk"]
extras = ["emulator/x{notor}.apk"]

[step.build-linux]
platform = "linux"
for_each = "variant"
needs = ["scope"]
run = "echo linux {variant} >> {src}/calls; head -c 2000000 /dev/zero > {stage}/EpicCashDesktop-{version}{notor}-x86_64.AppImage"
outputs = ["EpicCashDesktop-{version}{notor}-x86_64.AppImage"]

[step.trust-android]
platform = "android"
for_each = "proof_variant"
needs = ["build-android", "build-linux"]
proof = true

[step.trust-linux]
platform = "linux"
for_each = "proof_variant"
needs = ["build-android", "build-linux"]
proof = true

[step.update-trust]
kind = "builtin"
host = "local"
needs = ["trust-android", "trust-linux"]

[step.publish-gate]
kind = "gate"
host = "local"
needs = ["update-trust"]

[step.publish-downloads]
kind = "publish"
needs = ["publish-gate"]
run = "echo publish >> {src}/calls"
scratch = "scratch_noop"

[step.publish-source]
kind = "publish"
skippable = true
needs = ["publish-downloads"]
run = "echo source >> {src}/calls"
scratch = "scratch_noop"
"""

FAKE_RELMSG = r"""#!/usr/bin/env bash
# A stand-in for relmsg: records every call; the gate's answer comes from $REL_FAKE_GATE
# (approved | held | pending | error | crash).
echo "$*" >> "$REL_FAKE_DIR/relmsg.calls"
args=("$@")
while [[ ${#args[@]} -gt 0 && ( ${args[0]} == --json || ${args[0]} == --release ) ]]; do
  if [[ ${args[0]} == --release ]]; then args=("${args[@]:2}"); else args=("${args[@]:1}"); fi
done
case "${args[0]}" in
  start) echo '{"release_id": 7, "message_id": 1}' ;;
  gate) echo '{"gate_id": 3, "status": "pending"}' ;;
  gate-status)
    case "${REL_FAKE_GATE:-pending}" in
      approved) echo '{"gate_id": 3, "status": "approved", "decided_by": "the owner", "via": "telegram", "at": "2026-10-30T14:30:00Z"}'; exit 0 ;;
      held) echo '{"gate_id": 3, "status": "held", "decided_by": "the owner"}'; exit 3 ;;
      pending) echo '{"gate_id": 3, "status": "pending"}'; exit 5 ;;
      approved-but-exit1) echo '{"gate_id": 3, "status": "approved"}'; exit 1 ;;
      error) echo 'boom' >&2; exit 1 ;;
      crash) exit 2 ;;
    esac ;;
  *) echo '{}' ;;
esac
"""

DRIVER = r"""#!/usr/bin/env bash
# A fake update-trust driver: $REL_SRC/proof-mode says what to write.
mode="$(cat "$REL_SRC/proof-mode" 2>/dev/null || echo good)"
echo "driver $REL_VARIANT checks=$REL_CHECKS funds=$REL_FUNDS" >> "$REL_SRC/calls"
case "$mode" in
  good) printf '{"platform":"x","previous":"a","candidate":"b","checks":{"wallet_opens":true,"history_kept":true,"send_ok":true}}' > "$REL_OUT/proof.json" ;;
  bad) printf '{"checks":{"wallet_opens":true,"history_kept":false,"send_ok":true},"details":{"history_kept":"0 of 3 txs"}}' > "$REL_OUT/proof.json"; exit 1 ;;
  liar) printf '{"checks":{"wallet_opens":true}}' > "$REL_OUT/proof.json" ;;
  none) exit 0 ;;
esac
"""


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix="reltest-", dir=os.environ.get("TMPDIR"))
        self.root = os.path.join(self.tmp, "state")
        self.src = os.path.join(self.tmp, "src")
        os.makedirs(self.src)
        with open(os.path.join(self.src, "driver.sh"), "w") as f:
            f.write(DRIVER)
        self.fake = os.path.join(self.tmp, "relmsg")
        with open(self.fake, "w") as f:
            f.write(FAKE_RELMSG)
        os.chmod(self.fake, os.stat(self.fake).st_mode | stat.S_IEXEC)
        os.environ["REL_FAKE_DIR"] = self.tmp
        os.environ["REL_RELMSG"] = self.fake
        os.environ["REL_FAKE_GATE"] = "pending"
        self.pipeline = Pipeline.loads(FAKE_PIPELINE) if hasattr(Pipeline, "loads") else Pipeline(
            __import__("tomllib").loads(FAKE_PIPELINE))
        self.hosts = {"host": {}, "path": {}, "file": "none", "exists": True}

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)
        for k in ("REL_FAKE_DIR", "REL_RELMSG", "REL_FAKE_GATE"):
            os.environ.pop(k, None)

    def make_run(self, version="26.10.25", **scope_kw):
        scope = load_scope(None, version, **scope_kw)
        validate_scope(scope, self.pipeline)
        path, run_id = Run.next_path(self.root, version)
        ctx = {"version": version, "commit": "c" * 40, "short": "c" * 7, "run_id": run_id, "run": path,
               "files": f"{path}/files", "extra": f"{path}/extra", "manifests": f"{path}/manifests", "src": self.src,
               "target": scope["publish"]["target"], "scratch": f"{path}/scratch/target", "notes_file": "",
               "previous_dir": "", "previous_version": "", "previous_ref": "", "node": "$REL_NODE", "epicbox": "$REL_EPICBOX",
               "host": {}, "path": {}}
        steps = build_graph(self.pipeline, scope, ctx)
        info = {"version": version, "commit": "c" * 40, "scope": scope, "test": scope["test"], "src": self.src,
                "target": scope["publish"]["target"]}
        run = Run.create(self.root, version, info, scope_toml(scope), steps)
        for s in run.steps:
            if s.base in scope["skip"]:
                run.set_status(s.id, status="skipped", reason=scope["skip"][s.base])
            if s.proof and s.platforms[0] in scope["proof"]["waive"]:
                run.set_status(s.id, status="skipped", reason="waived")
        return run

    def engine(self, run, relmsg=True):
        rm = Relmsg(run, {"bin": self.fake}, enabled=relmsg)
        rm.start([s.id for s in run.steps], [])
        return Engine(run, self.pipeline, self.hosts, REPO, relmsg=rm)

    def calls(self):
        try:
            return open(os.path.join(self.src, "calls")).read().split("\n")
        except FileNotFoundError:
            return []

    def relmsg_calls(self):
        try:
            return open(os.path.join(self.tmp, "relmsg.calls")).read()
        except FileNotFoundError:
            return ""

    def build_ids(self, run):
        return [s.id for s in run.steps if s.phase == "build"]
