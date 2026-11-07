# SPDX-License-Identifier: Apache-2.0
"""One named test per goal of the test-infra plan: flow, night, cherry-picked steps, keep going,
one journal, bugs and logs, lanes, cut, gate note."""
import io
import json
import os
import pathlib
import re
import sqlite3
import subprocess
import tomllib
import unittest
from contextlib import redirect_stderr, redirect_stdout
from unittest import mock

from support import Base, FAKE_PIPELINE, REPO
from rellib import builtins, flow, health, retention
from rellib.cli import App, main, version_at
from rellib.config import Pipeline
from rellib.engine import STALE_INPUTS
from rellib.graph import Step
from rellib.run import Run
from rellib.reuse import find_source, key, version_only_diff
from rellib.testdb import writer

V = version_at(REPO, "HEAD")
REAL = os.path.join(REPO, "release/pipeline.toml")
# Stands in for tools/version.sh, which needs the whole tree: the same two lines change.
VERSION_SH = r"""#!/bin/sh
cd "$(dirname "$0")/.."
sed -i "s/^version: .*/version: $2+26010100/" app/pubspec.yaml
sed -i "s/appVersion = '[^']*'/appVersion = '$2'/" app/lib/src/app_version.dart
"""

NIGHT_PIPELINE = FAKE_PIPELINE + """
[step.test-a]
when = "night"
needs = ["scope"]
run = "true"

[step.test-b]
when = "night"
title = "B"
warn_only = true
needs = ["scope"]
run = "true"
"""


def rel(*args):
    out, err = io.StringIO(), io.StringIO()
    with redirect_stdout(out), redirect_stderr(err):
        code = main(list(args))
    return code, out.getvalue(), err.getvalue()


def git(cwd, *args):
    return subprocess.run(["git", "-C", cwd, "-c", "user.name=t", "-c", "user.email=t@t", *args],
                          capture_output=True, text=True, check=True).stdout.strip()


class Goal(Base):
    def common(self, pipeline=None):
        args = ["--state-root", self.root, "--hosts", os.path.join(self.tmp, "no-hosts.toml")]
        return args + (["--pipeline", pipeline] if pipeline else [])

    def write_pipeline(self, text):
        p = os.path.join(self.tmp, "pipeline.toml")
        pathlib.Path(p).write_text(text)
        return p

    def repo(self):
        """A small git repository with the two version files, tools/version.sh and a main branch."""
        r = os.path.join(self.tmp, "repo")
        os.makedirs(os.path.join(r, "app/lib/src"))
        os.makedirs(os.path.join(r, "tools"))
        pathlib.Path(r, "app/pubspec.yaml").write_text("name: x\nversion: 26.1.0+26010000\n")
        pathlib.Path(r, "app/lib/src/app_version.dart").write_text(
            "const String appVersion = '26.1.0';\nconst String coreVersion = '1';\n")
        pathlib.Path(r, "app/a.dart").write_text("a\n")
        pathlib.Path(r, "tools/driver.py").write_text("d\n")
        pathlib.Path(r, "tools/version.sh").write_text(VERSION_SH)
        git(self.tmp, "init", "-q", "-b", "main", r)
        git(r, "add", ".")
        git(r, "commit", "-qm", "one")
        return r

    def night_record(self, sha, source="done", **lanes):
        d = os.path.join(self.tmp, "nightly", "lanes")
        os.makedirs(d, exist_ok=True)
        rec = {"sha": sha, "ended": "2026-11-07T00:00:00Z", "run_id": "run-1", "source": {"status": source},
               "lanes": {b.replace("_", "-"): v for b, v in lanes.items()}}
        pathlib.Path(d, f"{sha}.json").write_text(json.dumps(rec))


class Goal1Flow(Goal):
    def test_goal1_header_and_graph_agree(self):
        text = pathlib.Path(REAL).read_text()
        pipeline = Pipeline.load(REAL)
        self.assertEqual(flow.header_lines(text), flow.flow_lines(pipeline))
        changed = text.replace('[step.source-check]\ntitle = "G2 source gate (tools/check.sh)"\nhost = "build"\nneeds = ["source"]',
                               '[step.source-check]\ntitle = "G2 source gate (tools/check.sh)"\nhost = "build"\nneeds = ["scope"]')
        self.assertNotEqual(changed, text)
        self.assertNotEqual(flow.header_lines(changed), flow.flow_lines(Pipeline(tomllib.loads(changed), REAL)))

    def test_goal1_flow_json_lists_stages_with_class_needs_outputs(self):
        code, out, err = rel("flow", "--json")
        self.assertEqual(code, 0, err)
        rows = {r["name"]: r for r in json.loads(out)["stages"]}
        self.assertEqual(rows["lane-payments-linux"]["class"], "informs")
        self.assertEqual(rows["source-check"]["needs"], ["source"])
        self.assertIn("outputs", rows["build-linux"])


class Goal2Night(Goal):
    def test_goal2_night_steps_are_only_in_the_night_plan(self):
        code, out, err = rel("--json", *self.common(), "plan", V, "--night")
        self.assertEqual(code, 0, err)
        night = {s["id"] for s in json.loads(out)["steps"]}
        self.assertIn("lane-pairing-linux-tor", night)
        self.assertIn("source-check", night)
        self.assertFalse([s for s in night if s.startswith("publish")])
        code, out, err = rel("--json", *self.common(), "plan", V, "--test")
        release = {s["id"] for s in json.loads(out)["steps"]}
        self.assertFalse([s for s in release if s.startswith(("flow-", "create-", "testbuild-", "lane-"))])
        self.assertIn("source-check", release)

    def test_goal2_a_night_without_proof_steps_needs_no_previous_release(self):
        run = self.make_run(only="android", sets=["publish.manifests=false"], test=True)
        pre = Step(id="preflight", base="preflight", kind="builtin", title="pre", host="local", lane="local", platforms=[])
        run.steps[:] = [pre]
        run.set_status("preflight", status="pending")
        self.hosts["exists"] = True
        lines = []
        with mock.patch.object(builtins, "health_node", lambda u, timeout=10: True), \
                mock.patch.object(builtins, "health_epicbox", lambda h, timeout=8: True):
            eng = self.engine(run)
            eng.echo = lines.append
            eng.drive(["preflight"])
        log = pathlib.Path(run.step_dir("preflight"), "log.txt").read_text()
        self.assertNotIn("G4 needs the previous release", log)

    def test_goal2_run_refuses_a_missing_need_on_a_fresh_run(self):
        code, out, err = rel(*self.common(), "start", V, "--test", "--dry-run", "--no-relmsg", "--until", "scope")
        self.assertIn(code, (0, 30), err)
        code, out, err = rel(*self.common(), "run", "source-check")
        self.assertEqual(code, 64)
        self.assertIn("source-check needs source first", err + out)
        self.assertIn("source is pending", err + out)

    def test_goal2_cherry_picked_steps_run_on_a_fresh_run(self):
        code, out, err = rel(*self.common(), "start", V, "--test", "--dry-run", "--no-relmsg", "--until", "scope")
        self.assertIn(code, (0, 30), err)
        code, out, err = rel(*self.common(), "run", "preflight", "source")
        self.assertIn(code, (0, 30), err)
        code, out, err = rel("--json", *self.common(), "status")
        steps = {s["id"]: s["status"] for s in json.loads(out)["steps"]}
        self.assertIn(steps["preflight"], ("done", "failed"))
        if steps["preflight"] == "done":
            self.assertEqual(steps["source"], "done")

    def test_goal2_a_stale_need_is_named_with_why(self):
        run = self.make_run(only="android", test=True)
        eng = self.engine(run)
        ids = [s.id for s in run.steps]
        need = next(x for x in ids if x.startswith("build-android"))
        target = next(s for s in run.steps if s.base == "trust-android")
        run.set_status(need, status="done", input_hash="not-this-one")
        self.assertIn((need, STALE_INPUTS), App.stale_needs(run, eng, target, [target.id]))
        self.assertEqual(App.stale_needs(run, eng, target, [target.id, need]), [], "a need among the steps is waited for")


class Goal3KeepGoing(Goal):
    def test_goal3_a_failed_step_stops_only_what_needs_it(self):
        run = self.make_run(test=True)
        pathlib.Path(self.src, "fail-tor").touch()
        code = self.engine(run).drive(self.build_ids(run), stop_on_fail=False)
        self.assertEqual(code, 20)
        self.assertEqual(run.status("build-android-tor")["status"], "failed")
        self.assertEqual(run.status("build-android-notor")["status"], "done")
        self.assertEqual(run.status("build-linux-tor")["status"], "done")
        self.assertEqual(run.status("trust-android-tor")["status"], "pending")

    def test_goal3_retry_restarts_that_step_only(self):
        run = self.make_run(test=True)
        pathlib.Path(self.src, "fail-tor").touch()
        self.engine(run).drive(self.build_ids(run), stop_on_fail=False)
        before = run.status("build-linux-tor")
        os.remove(os.path.join(self.src, "fail-tor"))
        p = self.write_pipeline(FAKE_PIPELINE)
        with mock.patch.object(App, "load_run", return_value=run), mock.patch.object(App, "engine", return_value=self.engine(run)):
            code, out, err = rel(*self.common(p), "retry", "build-android-tor")
        self.assertEqual(run.status("build-android-tor")["status"], "done", err)
        self.assertEqual(run.status("build-linux-tor").get("ended"), before.get("ended"))

    def test_goal3_stop_flag_and_publish_decide_how_the_engine_stops(self):
        p = self.write_pipeline(FAKE_PIPELINE)
        for args, want in ((["run", "build-linux-tor"], False),
                           (["run", "build-linux-tor", "--stop-on-fail"], True)):
            run = self.make_run(test=True)
            drive = mock.Mock(return_value=0)
            eng = self.engine(run)
            eng.drive = drive
            with mock.patch.object(App, "load_run", return_value=run), mock.patch.object(App, "engine", return_value=eng):
                code, out, err = rel(*self.common(p), *args, "--ignore-needs")
            self.assertEqual(drive.call_args.kwargs["stop_on_fail"], want, err)
        run = self.make_run(test=True)
        run.set_status("publish-gate", status="done")
        run.set_status("publish-downloads", status="done")
        drive = mock.Mock(return_value=0)
        eng = self.engine(run)
        eng.drive = drive
        with mock.patch.object(App, "load_run", return_value=run), mock.patch.object(App, "engine", return_value=eng):
            rel(*self.common(p), "run", "publish-source")
        self.assertTrue(drive.call_args.kwargs["stop_on_fail"], "a publish step always stops")


class PublishSource(Goal):
    def test_publish_source_stops_at_the_release_commit(self):
        self.assertIn("tools/publish-github.sh --push --ref {commit}", Pipeline.load(REAL).steps["publish-source"]["run"])

    def test_the_scratch_publish_stops_at_the_release_commit_and_never_pushes(self):
        run = self.make_run(test=True)
        with mock.patch("rellib.builtins.sh", return_value=(0, "")) as sh:
            out = builtins.scratch_source(self.engine(run), run.step("publish-source"), print)
        self.assertEqual(out["status"], "done")
        self.assertEqual(sh.call_args.args[0], ["tools/publish-github.sh", "--ref", "c" * 40])


class Goal4Record(Goal):
    def warn_pipeline(self):
        self.pipeline = Pipeline(tomllib.loads(FAKE_PIPELINE + """
[step.lane-x]
warn_only = true
needs = ["scope"]
run = "exit 1"
"""), "fake")

    def db(self):
        db = os.path.join(self.tmp, "tests.db")
        os.environ["REL_TESTDB"] = db
        self.addCleanup(os.environ.pop, "REL_TESTDB", None)
        return db

    def rows(self, db, sql):
        writer.drain(db, wait=True)
        conn = writer.connect(db)
        conn.row_factory = sqlite3.Row
        try:
            return [dict(r) for r in conn.execute(sql)]
        finally:
            conn.close()

    def test_goal4_a_partial_run_writes_journal_metrics_and_testdb(self):
        db = self.db()
        run = self.make_run(test=True)
        pathlib.Path(self.src, "fail-tor").touch()
        self.engine(run).drive(["scope", "build-android-tor"], stop_on_fail=False)
        ev = [e["event"] for e in run.events() if e.get("step") == "build-android-tor"]
        self.assertIn("start", ev)
        self.assertIn("end", ev)
        self.assertIn("bug", ev)
        metrics = [json.loads(x) for x in pathlib.Path(health.metrics_path(run)).read_text().splitlines()]
        line = [m for m in metrics if m.get("step") == "build-android-tor"][-1]
        self.assertEqual(line["status"], "failed")
        self.assertEqual(line["commit"], "c" * 40)
        states = self.rows(db, "SELECT a.state FROM attempts a JOIN lanes l ON l.id = a.lane_id WHERE l.name = 'build-android-tor'")
        self.assertEqual(states, [{"state": "failed"}])

    def test_goal4_a_skipped_step_writes_journal_metrics_and_testdb(self):
        db = self.db()
        run = self.make_run(test=True)
        with mock.patch.object(App, "load_run", return_value=run), mock.patch.object(App, "engine", return_value=self.engine(run)):
            code, out, err = rel(*self.common(), "skip", "publish-source", "--reason", "token renewal")
        self.assertEqual(code, 0, err + out)
        self.assertEqual(run.status("publish-source")["status"], "skipped")
        self.assertIn("skipped", [e["event"] for e in run.events() if e.get("step") == "publish-source"])
        metrics = [json.loads(x) for x in pathlib.Path(health.metrics_path(run)).read_text().splitlines()]
        line = [m for m in metrics if m.get("step") == "publish-source"][-1]
        self.assertEqual((line["status"], line["duration_s"], line["commit"]), ("skipped", 0, "c" * 40))
        rows = self.rows(db, "SELECT a.state, a.note FROM attempts a JOIN lanes l ON l.id = a.lane_id WHERE l.name = 'publish-source'")
        self.assertEqual(rows, [{"state": "skipped", "note": "token renewal"}])

    def test_goal4_warned_is_stored_as_warned_with_a_class(self):
        db = self.db()
        self.warn_pipeline()
        run = self.make_run(test=True)
        self.engine(run).drive(["scope", "lane-x"], stop_on_fail=False)
        self.assertTrue(run.status("lane-x").get("warned"))
        bugs = self.rows(db, "SELECT * FROM bugs")
        self.assertEqual(len(bugs), 1)
        self.assertEqual(bugs[0]["warned"], 1)
        self.assertTrue(bugs[0]["class"])
        self.assertIn("warned", [a["state"] for a in self.rows(db, "SELECT state FROM attempts")])

    def test_goal4_every_failed_attempt_has_a_class_and_a_ledger_line(self):
        db = self.db()
        self.pipeline.ledger = {"path": "ledger/bugs.jsonl"}
        repo = os.path.join(self.tmp, "ledger-repo")
        os.makedirs(os.path.join(repo, "ledger"))
        run = self.make_run(test=True)
        pathlib.Path(self.src, "fail-tor").touch()
        eng = self.engine(run)
        eng.repo = repo
        eng.drive(["scope", "build-android-tor"], stop_on_fail=False)
        bugs = self.rows(db, "SELECT * FROM bugs")
        self.assertEqual([b["step"] for b in bugs], ["build-android-tor"])
        self.assertTrue(bugs[0]["class"])
        with self.assertRaises(sqlite3.IntegrityError):
            conn = writer.connect(db)
            self.addCleanup(conn.close)
            conn.execute("INSERT INTO bugs(attempt_id, class) VALUES (?, NULL)", (bugs[0]["attempt_id"],))
        line = json.loads(pathlib.Path(repo, "ledger/bugs.jsonl").read_text().splitlines()[0])
        self.assertEqual(line["step"], "build-android-tor")

    def test_goal4_logs_of_the_last_ten_versions_are_kept(self):
        for i in range(1, 13):
            path = os.path.join(self.root, f"26.1.{i}", "run-1")
            os.makedirs(os.path.join(path, "steps", "a"))
            pathlib.Path(path, "events.jsonl").write_text("{}\n")
            pathlib.Path(path, "steps", "a", "attempt-1.log").write_text("log\n")
            pathlib.Path(path, "steps", "a", "big.bin").write_text("x")
            retention.keep_logs(self.root, path, f"26.1.{i}")
        kept = sorted(os.listdir(os.path.join(self.root, ".logs")), key=lambda v: int(v.split(".")[2]))
        self.assertEqual(kept, [f"26.1.{i}" for i in range(3, 13)])
        d = pathlib.Path(self.root, ".logs", "26.1.12", "run-1")
        self.assertTrue((d / "events.jsonl").is_file())
        self.assertTrue((d / "steps" / "a" / "attempt-1.log").is_file())
        self.assertFalse((d / "steps" / "a" / "big.bin").exists())


class GoalA03Lanes(Goal):
    def test_a03_warn_only_is_frozen_in_the_plan(self):
        lane = """
[step.lane-x]
%s
needs = ["scope"]
run = "exit 1"
"""
        self.pipeline = Pipeline(tomllib.loads(FAKE_PIPELINE + lane % "warn_only = true"), "fake")
        run = self.make_run(test=True)
        self.pipeline = Pipeline(tomllib.loads(FAKE_PIPELINE + lane % ""), "fake")  # changed in flight
        again = Run(run.path)
        self.assertEqual(self.engine(again).drive(["scope", "lane-x"], stop_on_fail=False), 0)
        self.assertEqual(again.status("lane-x")["status"], "done")
        self.assertTrue(again.status("lane-x").get("warned"))

    def test_a03_lanes_json_has_the_contract_fields(self):
        code, out, err = rel("--json", *self.common(), "lanes")
        self.assertEqual(code, 0, err)
        rows = json.loads(out)
        row = next(r for r in rows if r["base"] == "lane-linking-linux")
        self.assertEqual(set(row), {"base", "title", "class", "stage", "last", "green_streak"})
        self.assertEqual((row["class"], row["stage"]), ("informs", "night"))

    def test_a03_lane_commits_one_line_and_refuses_a_dirty_file(self):
        r = os.path.join(self.tmp, "m")
        os.makedirs(os.path.join(r, "release"))
        git(self.tmp, "init", "-q", "-b", "main", r)
        text = flow.rewrite_header(FAKE_PIPELINE + flow.header_block(Pipeline(tomllib.loads(NIGHT_PIPELINE), "x")) + "\n"
                                   + NIGHT_PIPELINE[len(FAKE_PIPELINE):], Pipeline(tomllib.loads(NIGHT_PIPELINE), "x"))
        pathlib.Path(r, "release/pipeline.toml").write_text(text)
        git(r, "add", ".")
        git(r, "commit", "-qm", "p")
        git(r, "config", "user.name", "t")
        git(r, "config", "user.email", "t@t")
        pipeline = Pipeline(tomllib.loads(text), "x")
        sha = flow.change_class(r, "test-a", "informs", pipeline)
        self.assertTrue(sha)
        self.assertEqual(git(r, "show", "--name-only", "--format=", "HEAD"), "release/pipeline.toml")
        self.assertIn("warn_only = true", pathlib.Path(r, "release/pipeline.toml").read_text().split("[step.test-a]")[1].split("[step")[0])
        pathlib.Path(r, "release/pipeline.toml").write_text(text + "\n# dirty\n")
        with self.assertRaisesRegex(Exception, "uncommitted"):
            flow.change_class(r, "test-b", "blocks", pipeline)


class GoalA02Cut(Goal):
    def step(self, outputs=()):
        run = self.make_run(test=True)
        s = run.step("build-linux-tor")
        s.outputs, s.extras, s.env = list(outputs), [], {}
        s.id = "source-check"
        return s

    def cut_pipeline(self, r):
        self.pipeline = Pipeline(tomllib.loads(NIGHT_PIPELINE), "fake")
        git(r, "config", "user.name", "t")
        git(r, "config", "user.email", "t@t")

    def test_a02_cut_takes_the_newest_green_night_and_stands(self):
        r = self.repo()
        self.cut_pipeline(r)
        green = git(r, "rev-parse", "HEAD")
        pathlib.Path(r, "app/a.dart").write_text("b\n")
        git(r, "commit", "-qam", "two")
        red = git(r, "rev-parse", "HEAD")
        self.night_record(green, test_a={"class": "blocks", "status": "done"}, test_b={"class": "informs", "status": "failed"})
        self.night_record(red, test_a={"class": "blocks", "status": "failed"})
        base, why = flow.cut_base(self.pipeline, r)
        self.assertEqual(base, green, "an Informs lane holds nothing; a Blocks lane does")
        self.assertIn("test-a is failed", why[0])
        tip, made = flow.make_cut(r, "26.1.1", base, self.root)
        self.assertTrue(made)
        self.assertEqual(git(r, "rev-parse", "release/26.1.1"), tip)
        self.assertEqual(git(r, "rev-parse", f"{tip}~1"), green)
        self.assertEqual(git(r, "show", "--format=%s", "--name-only", tip).split(),
                         "Set the version to 26.1.1 app/lib/src/app_version.dart app/pubspec.yaml".split())
        self.assertEqual(git(r, "rev-parse", "HEAD"), red, "main does not move")
        self.assertEqual(git(r, "status", "--porcelain"), "")
        self.assertEqual(flow.make_cut(r, "26.1.1", red, self.root), (tip, False))
        self.assertEqual(len(git(r, "worktree", "list").splitlines()), 1)

    def test_a02_a_missing_blocks_lane_or_red_source_is_no_base(self):
        r = self.repo()
        self.cut_pipeline(r)
        sha = git(r, "rev-parse", "HEAD")
        self.night_record(sha, test_b={"class": "informs", "status": "done"})
        self.assertEqual(flow.cut_base(self.pipeline, r)[0], None)
        self.night_record(sha, source="failed", test_a={"class": "blocks", "status": "done"})
        self.assertEqual(flow.cut_base(self.pipeline, r)[0], None)
        self.night_record(sha, test_a={"class": "blocks", "status": "done", "warned": True})
        self.assertEqual(flow.cut_base(self.pipeline, r)[0], None)

    def test_a02_a_candidate_from_a_green_night_reuses_g2(self):
        r = self.repo()
        self.cut_pipeline(r)
        green = git(r, "rev-parse", "HEAD")
        tip, _ = flow.make_cut(r, "26.1.1", green, self.root)
        gdir = os.path.join(self.tmp, "green")
        os.makedirs(gdir)
        pathlib.Path(gdir, f"{green}.json").write_text(json.dumps(
            {"status": "green", "clean": True, "command": "tools/check.sh --full", "sha": green, "suites": ["full", "full-notor"]}))
        info = {"commit": tip, "version": "26.1.1"}
        paths = ["app", "tools/version.sh"]
        src = find_source(r, self.root, info, self.step(), paths, green=gdir)[2]
        self.assertEqual((src["kind"], src["commit"]), ("green", green))
        # App code after the night: not reused.
        pathlib.Path(r, "app/a.dart").write_text("b\n")
        git(r, "commit", "-qam", "fix")
        info = {"commit": git(r, "rev-parse", "HEAD"), "version": "26.1.1"}
        self.assertIsNone(find_source(r, self.root, info, self.step(), paths, green=gdir)[2])
        # A step that leaves files needs its own bytes.
        info = {"commit": tip, "version": "26.1.1"}
        self.assertIsNone(find_source(r, self.root, info, self.step(outputs=["x"]), paths, green=gdir)[2])

    def test_a02_a_drivers_only_commit_does_not_rerun_g2(self):
        reuse = Pipeline.load(REAL).steps["source-check"]["reuse"]
        self.assertFalse([p for p in reuse if p.startswith("tools/rellib") or p == "tools"])
        r = self.repo()
        a = git(r, "rev-parse", "HEAD")
        pathlib.Path(r, "tools/driver.py").write_text("e\n")
        git(r, "commit", "-qam", "driver")
        b = git(r, "rev-parse", "HEAD")
        step = self.step()
        self.assertEqual(key(r, a, "1", step, ["app"])[0], key(r, b, "1", step, ["app"])[0])

    def test_a02_version_lines_only(self):
        r = self.repo()
        self.cut_pipeline(r)
        a = git(r, "rev-parse", "HEAD")
        b, _ = flow.make_cut(r, "26.1.1", a, self.root)
        self.assertTrue(version_only_diff(r, a, b, ["app"]))
        self.assertFalse(version_only_diff(r, a, "nonsense", ["app"]))
        pathlib.Path(r, "app/pubspec.yaml").write_text("name: y\nversion: 26.1.0+26010000\n")
        git(r, "commit", "-qam", "name")
        self.assertFalse(version_only_diff(r, a, git(r, "rev-parse", "HEAD"), ["app"]))
        git(r, "checkout", "-q", a)
        os.chmod(os.path.join(r, "app/a.dart"), 0o755)
        git(r, "commit", "-qam", "mode")
        self.assertFalse(version_only_diff(r, a, git(r, "rev-parse", "HEAD"), ["app"]))

    def tag(self, r, commit, version="26.1.1", env=None):
        stage = os.path.join(self.tmp, "stage")
        script = os.path.join(REPO, "tools/rellib/steps/tag.sh")
        e = {**os.environ, "REL_TEST": "0", "REL_TARGET": "live", "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t",
             "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@t", **(env or {})}
        return subprocess.run(["bash", script, version, commit, r, stage], capture_output=True, text=True, env=e)

    def test_a02_tag_merges_the_release_branch_into_main(self):
        r = self.repo()
        self.cut_pipeline(r)
        base = git(r, "rev-parse", "HEAD")
        tip, _ = flow.make_cut(r, "26.1.1", base, self.root)
        pathlib.Path(r, "app/a.dart").write_text("moved on\n")
        git(r, "commit", "-qam", "main moved")
        p = self.tag(r, tip, env={"REL_TARGET": "scratch"})
        self.assertIn("would merge release/26.1.1", p.stdout)
        self.assertNotEqual(subprocess.run(["git", "-C", r, "merge-base", "--is-ancestor", tip, "main"]).returncode, 0)
        p = self.tag(r, tip)
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(subprocess.run(["git", "-C", r, "merge-base", "--is-ancestor", tip, "main"]).returncode, 0)
        self.assertEqual(git(r, "rev-parse", "v26.1.1^{commit}"), tip)

    def test_a02_tag_refuses_a_commit_that_is_neither(self):
        r = self.repo()
        git(r, "checkout", "-q", "-b", "other")
        pathlib.Path(r, "app/a.dart").write_text("c\n")
        git(r, "commit", "-qam", "other")
        sha = git(r, "rev-parse", "HEAD")
        git(r, "checkout", "-q", "main")
        p = self.tag(r, sha)
        self.assertEqual(p.returncode, 1)
        self.assertIn("not on main", p.stderr)

    def test_a02_cut_cli_refuses_without_a_green_night(self):
        self.assertEqual(rel(*self.common(), "cut", "--version", "bad")[0], 64)
        with mock.patch.object(flow, "cut_base", return_value=(None, ["abc: test-a is failed"])), \
                mock.patch("subprocess.run", return_value=mock.Mock(stdout="")):
            code, out, err = rel(*self.common(), "cut", "--version", "26.1.1")
        self.assertEqual(code, 20)
        self.assertIn("no commit of main has a green night: abc: test-a is failed", err + out)


class GoalGateNote(Goal):
    def test_a08_a10_lanes_walk_and_slow_steps_sit_on_the_gate_note(self):
        run = self.make_run(test=True)
        run.set_status("trust-linux-tor", status="done")
        eng = self.engine(run)
        r = self.repo()
        eng.repo = r
        run.info["commit"] = git(r, "rev-parse", "HEAD")
        self.night_record(run.info["commit"], test_a={"class": "blocks", "status": "done"},
                          test_b={"class": "informs", "status": "failed", "warned": True})
        with open(health.metrics_path(run), "w") as f:
            for i, d in enumerate((100, 100, 100, 160, 170)):
                f.write(json.dumps({"base": "build-linux", "step": "build-linux-tor", "status": "done", "duration_s": d,
                                    "commit": f"{i}" * 40}) + "\n")
        text = builtins.gate_summary(eng)
        self.assertIn("- blocks passed: test-a", text)
        self.assertIn("- informs warned: test-b", text)
        self.assertIn("trust-linux", text)
        self.assertIn("- linux: not walked yet", text)
        self.assertIn("Slower: build-linux 170s, median 100s (+70%), moved at 333333333333", text)
        p = self.write_pipeline(FAKE_PIPELINE)
        code, out, err = rel(*self.common(p), "walk", "linux", "ok", "--note", "fine", "--run", run.path)
        self.assertEqual(code, 0, err)
        self.assertIn("- linux: ok (fine)", builtins.gate_summary(eng))
        self.assertEqual(rel(*self.common(p), "walk", "toaster", "ok", "--run", run.path)[0], 64)

    def test_a08_every_platform_has_the_four_points(self):
        text = pathlib.Path(REPO, "release/person-walk.md").read_text()
        parts = dict(zip(re.findall(r"^## (\w+)$", text, re.M), re.split(r"^## \w+$", text, flags=re.M)[1:]))
        self.assertEqual(set(parts), {"android", "ios", "linux", "windows", "macos"})
        for body in parts.values():
            for point in ("Background:", "Unlock:", "Update:", "CPU:"):
                self.assertIn(point, body)

    def test_a10_stats_reports_the_commit_that_moved_a_step(self):
        os.makedirs(self.root)
        with open(os.path.join(self.root, "metrics.jsonl"), "w") as f:
            for i, d in enumerate((10, 11, 10, 20, 21)):
                f.write(json.dumps({"base": "x", "status": "done", "duration_s": d, "commit": f"{i}" * 40}) + "\n")
        code, out, err = rel("--json", *self.common(), "stats")
        self.assertEqual(code, 0, err)
        row = next(s for s in json.loads(out.strip().splitlines()[-1])["stats"] if s["step"] == "x")
        self.assertEqual(row["over_median"]["commit"], "3" * 40)
        self.assertEqual(health.slow_steps(os.path.join(self.tmp, "none")), [])


if __name__ == "__main__":
    unittest.main()
