# SPDX-License-Identifier: Apache-2.0
"""Things that must never ship (rellib/guards.py): the commits on release/never-ship.toml."""
import os
from types import SimpleNamespace
from unittest import mock

from support import REPO, Base
from rellib import guards
from rellib.engine import Engine
from rellib.cli import main as rel_main

BAD = "b1e4540d52a45682b5025e25878b9dbce2d1e80a"


def step(base, kind="command", publish=False):
    return SimpleNamespace(id=base, base=base, kind=kind, publish=publish)


class NeverShipTest(Base):
    def repo_with(self, sha):
        d = os.path.join(self.tmp, "repo")
        os.makedirs(os.path.join(d, "release"), exist_ok=True)
        with open(os.path.join(d, guards.NEVER_SHIP), "w") as f:
            f.write('[[commit]]\nsha = "%s"\nreason = "bad build"\ndate = "2026-11-03"\n' % sha)
        return d

    def test_the_tracked_list_names_run_3(self):
        self.assertIn(BAD, guards.never_ship_commits(REPO))

    def test_listed_commit_refused_other_fine(self):
        repo = self.repo_with(BAD)
        self.assertIn("never ships", guards.never_ship_refusal({"commit": BAD}, repo))
        self.assertIsNone(guards.never_ship_refusal({"commit": "c" * 40}, repo))
        self.assertIsNone(guards.never_ship_refusal({"commit": BAD}, os.path.join(self.tmp, "empty")))

    def test_unreadable_list_refuses(self):
        repo = self.repo_with(BAD)
        with open(os.path.join(repo, guards.NEVER_SHIP), "w") as f:
            f.write("[[commit\n")
        self.assertIn("cannot be read", guards.never_ship_refusal({"commit": "c" * 40}, repo))

    def test_engine_refuses_source_gate_and_publish_steps(self):
        repo = self.repo_with("c" * 40)
        run = self.make_run(only="android", sets=["publish.manifests=false"])
        eng = Engine(run, self.pipeline, self.hosts, repo)
        for s in (step("source", "builtin"), step("publish-gate", "gate"), step("publish-page", "publish", True),
                  step("publish-source", "command")):
            self.assertIn("never ships", eng.refusal(s), s.id)
        self.assertIsNone(eng.refusal(step("build-android")))
        other = Engine(self.make_run(only="android", sets=["publish.manifests=false"]), self.pipeline, self.hosts,
                       self.repo_with(BAD))
        self.assertIsNone(other.refusal(step("source", "builtin")))
