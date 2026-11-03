# SPDX-License-Identifier: Apache-2.0
"""Things that must never ship (rellib/guards.py): REL_TRUST_BREAK in a release run, and the commits on
release/never-ship.toml."""
import os
import subprocess
import sys
from types import SimpleNamespace
from unittest import mock

from support import REPO, Base
from rellib import guards
from rellib.engine import Engine
from rellib.cli import main as rel_main

BAD = "b1e4540d52a45682b5025e25878b9dbce2d1e80a"
BREAK = {"REL_TRUST_BREAK": "hide:x"}


def step(base, kind="command", publish=False):
    return SimpleNamespace(id=base, base=base, kind=kind, publish=publish)


class TrustBreakTest(Base):
    def build(self, run):
        return run.step(self.build_ids(run)[1])

    def test_release_run_refused_test_run_allowed(self):
        rel = {"run_id": "r", "test": False}
        tst = {"run_id": "r", "test": True}
        self.assertIn("REL_TRUST_BREAK", guards.trust_break_refusal(rel, BREAK))
        self.assertIsNone(guards.trust_break_refusal(tst, BREAK))
        self.assertIsNone(guards.trust_break_refusal(rel, {}))
        self.assertIsNone(guards.trust_break_refusal(rel, {"REL_TRUST_BREAK": " "}))

    def test_engine_refuses_every_step_of_a_release_run(self):
        run = self.make_run(only="android", sets=["publish.manifests=false"])
        eng = Engine(run, self.pipeline, self.hosts, REPO)
        with mock.patch.dict(os.environ, BREAK):
            self.assertIn("REL_TRUST_BREAK", eng.refusal(step("build-android")))
            st = eng.execute(self.build(run))
        self.assertEqual(st["status"], "failed")
        self.assertIn("refused", st["note"])
        self.assertNotIn("REL_TRUST_BREAK", os.environ)
        self.assertIsNone(eng.refusal(step("build-android")))

    def test_engine_allows_a_test_run(self):
        run = self.make_run(only="android", test=True, sets=["publish.manifests=false"])
        eng = Engine(run, self.pipeline, self.hosts, REPO)
        with mock.patch.dict(os.environ, BREAK):
            self.assertIsNone(eng.refusal(step("build-android")))

    def test_engine_marks_the_run_kind(self):
        live = self.make_run(only="android", sets=["publish.manifests=false"])
        tst = self.make_run(version="26.10.26", only="android", test=True, sets=["publish.manifests=false"])
        for run, kind in ((live, "release"), (tst, "test")):
            env = Engine(run, self.pipeline, self.hosts, REPO).base_env(self.build(run))
            self.assertEqual(env["REL_RUN_KIND"], kind)


class DriverEntryTest(Base):
    def run_sh(self, name, kind, brk):
        env = dict(os.environ, REL_OUT=self.tmp, REL_DRY_RUN="1")
        env.pop("REL_TRUST_BREAK", None)
        env["REL_RUN_KIND"] = kind
        if brk:
            env["REL_TRUST_BREAK"] = brk
        return subprocess.run(["bash", os.path.join(REPO, "tools/rellib/drivers", name)], env=env,
                              capture_output=True, text=True, timeout=60, stdin=subprocess.DEVNULL)

    def test_shell_entries_refuse_in_a_release_run(self):
        for name in ("trust-linux.sh", "trust-android.sh", "trust-windows.sh"):
            r = self.run_sh(name, "release", "hide:x")
            self.assertEqual(r.returncode, 2, name)
            self.assertIn("REL_TRUST_BREAK", r.stderr, name)
            r = self.run_sh(name, "test", "hide:x")
            self.assertNotIn("REL_TRUST_BREAK is set in a release run", r.stderr, name)

    def test_lane_refuses_in_a_release_run(self):
        sys.path.insert(0, os.path.join(REPO, "tools/rellib/drivers"))
        from core import breaks
        with mock.patch.dict(os.environ, dict(BREAK, REL_RUN_KIND="release")):
            with self.assertRaises(breaks.BreakRefused):
                breaks.refuse_in_release()
        with mock.patch.dict(os.environ, dict(BREAK, REL_RUN_KIND="test")):
            breaks.refuse_in_release()
        with mock.patch.dict(os.environ, {"REL_RUN_KIND": "release"}):
            breaks.refuse_in_release()


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
