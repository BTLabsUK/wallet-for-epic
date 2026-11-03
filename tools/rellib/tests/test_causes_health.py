# SPDX-License-Identifier: Apache-2.0
"""Failure causes of proof steps, flaky passes, the driver pinned to the evidence, lane health
(tools/rellib/window.py, engine.py, evidence.py, health.py; docs/RELEASING.md, "Causes", "Lane health")."""
import io
import json
import os
import subprocess
import unittest
from contextlib import redirect_stderr, redirect_stdout

from support import REPO, Base
from rellib import builtins, evidence, health, window
from rellib.cli import main, report
from rellib.config import ConfigError, Pipeline
from rellib.graph import Step

# 26.10.26 run-4 trust-android attempt 1 and run-2 trust-linux-tor attempt 3 (the v1 driver).
HARNESS_LOG = ("# run: drivers/trust-android.sh\n\n"
               "HARNESS start: no previous tor x86_64 APK under /tmp/epic-build/rel/26.10.25/run-15/files/emulator\n"
               "trust-android: exit 2 (could not run)\n")
CRASH_LOG = ("trust-linux: previous 26.10.25\n"
             "Traceback (most recent call last):\n"
             "  File \"/x/tools/rellib/drivers/linux/lane.py\", line 212, in <module>\n"
             "    main()\n"
             "  File \"/x/tools/rellib/drivers/linux/lane.py\", line 190, in main\n"
             "    node = nodes[args.variant]\n"
             "LookupError: 'tor'\n")

DRIVER = r"""#!/usr/bin/env bash
# $REL_SRC/mode says what the fake driver does.
case "$(cat "$REL_SRC/mode")" in
  good) printf '{"checks":{"wallet_opens":true,"history_kept":true,"send_ok":true}}' > "$REL_OUT/proof.json" ;;
  recovered) printf '{"checks":{"wallet_opens":true,"history_kept":true,"send_ok":true},"recovered":[{"step":"open"},{"step":"send"}]}' > "$REL_OUT/proof.json" ;;
  bad) printf '{"checks":{"wallet_opens":true,"history_kept":false,"send_ok":true}}' > "$REL_OUT/proof.json"; exit 1 ;;
  fault-harness) printf '{"checks":{},"fault":{"kind":"harness","step":"start","what":"no apk","line":"HARNESS start: no apk"}}' > "$REL_OUT/proof.json"; exit 2 ;;
  harness-line) echo "HARNESS start: no previous tor x86_64 APK"; printf '{"checks":{"wallet_opens":false}}' > "$REL_OUT/proof.json"; exit 1 ;;
  crash) printf 'Traceback (most recent call last):\n  File "lane.py", line 1, in <module>\nLookupError: x\n'; printf '{"checks":{"wallet_opens":false}}' > "$REL_OUT/proof.json"; exit 1 ;;
  fault-product) printf 'Traceback (most recent call last):\nValueError: seen\n'; printf '{"checks":{"wallet_opens":false},"fault":{"kind":"product","step":"open","what":"x","line":"PRODUCT open: x"}}' > "$REL_OUT/proof.json"; exit 1 ;;
esac
"""


def wtext(path, text):
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


def rtext(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


class CauseOfTest(Base):
    def step(self, **kw):
        base = dict(id="s", base="s", kind="command", title="s", host="build", lane="s", platforms=[])
        return Step(**dict(base, **kw))

    def log(self, text):
        self.n = getattr(self, "n", 0) + 1
        path = os.path.join(self.tmp, f"log{self.n}")
        wtext(path, text)
        return path

    def test_a_driver_that_could_not_run_is_harness(self):
        proof = self.step(proof=True)
        log = self.log("building\n")
        fault = {"checks": {}, "fault": {"kind": "harness", "line": "HARNESS start: x"}}
        self.assertEqual(window.cause_of(proof, {"rc": 1, "proof": fault, "failed_checks": ["wallet_opens"]}, log), "harness")
        self.assertEqual(window.cause_of(proof, {"rc": 2, "proof": {"checks": {}}}, log), "harness")
        # run-4 trust-android attempt 1: only the HARNESS line says so
        log = self.log(HARNESS_LOG)
        self.assertEqual(window.cause_of(proof, {"rc": 1, "proof": {"checks": {}}, "failed_checks": ["wallet_opens"]}, log), "harness")
        self.assertEqual(window.cause_of(proof, {"rc": 1, "proof": {"checks": {}}}, self.log("trust-android: HARNESS lock: busy\n")), "harness")

    def test_an_uncaught_driver_exception_is_harness_crash(self):
        proof = self.step(proof=True)
        # run-2 trust-linux-tor attempt 3: a LookupError traceback, a proof without a fault
        self.assertEqual(window.cause_of(proof, {"rc": 1, "proof": {"checks": {}}, "failed_checks": ["wallet_opens"]},
                                         self.log(CRASH_LOG)), "harness:crash")
        self.assertEqual(window.cause_of(proof, {"rc": 1, "proof": {"checks": {}, "fault": {}}}, self.log(CRASH_LOG)), "harness:crash")

    def test_a_check_that_is_false_is_product(self):
        proof = self.step(proof=True)
        log = self.log("trust-android: PRODUCT checks false: settings_kept\n")
        self.assertEqual(window.cause_of(proof, {"rc": 1, "proof": {"checks": {}}, "failed_checks": ["settings_kept"]}, log), "product")
        fault = {"fault": {"kind": "product", "line": "PRODUCT open: x"}}
        self.assertEqual(window.cause_of(proof, {"rc": 1, "proof": fault}, self.log(CRASH_LOG)), "product",
                         "the driver's own product fault outranks a traceback in the log")
        self.assertEqual(window.cause_of(proof, {"rc": 1, "proof": {"checks": {}}}, log), "step",
                         "exit 1 with every check true and no fault says nothing about the product")

    def test_infrastructure_stays_first(self):
        proof = self.step(proof=True)
        ssh = self.log("HARNESS start: x\nclient_loop: send disconnect: Broken pipe\n")
        self.assertEqual(window.cause_of(proof, {"rc": 1, "proof": {"checks": {}}}, ssh), "infra:ssh")
        self.assertEqual(window.cause_of(proof, {"rc": 2, "proof_missing": True}, self.log(HARNESS_LOG)), "infra:no-proof")
        self.assertEqual(window.cause_of(proof, {"rc": 143, "proof": {"fault": {"kind": "harness"}}}, self.log("")), "infra:sigterm")
        self.assertEqual(window.cause_of(proof, {"rc": None, "timed_out": True}, self.log("")), "timeout")
        self.assertEqual(window.cause_of(proof, {"rc": 1, "exception": True}, self.log("")), "error")

    def test_other_steps(self):
        log = self.log(CRASH_LOG + "HARNESS x\n")
        self.assertEqual(window.cause_of(self.step(), {"rc": 1}, log), "step", "a build is never harness or product")
        self.assertEqual(window.cause_of(self.step(kind="publish"), {"rc": 3}, log), "step")
        self.assertEqual(window.cause_of(self.step(kind="builtin"), {"rc": None}, log), "check")
        self.assertEqual(window.cause_of(self.step(kind="gate"), {}, log), "check")

    def test_only_infrastructure_retries_by_itself(self):
        for mode, cause in (("harness-line", "harness"), ("crash", "harness:crash"), ("fault-harness", "harness"),
                            ("fault-product", "product"), ("bad", "product")):
            with self.subTest(mode):
                wtext(os.path.join(self.src, "driver.sh"), DRIVER)
                wtext(os.path.join(self.src, "mode"), mode)
                run = self.make_run(only="android", sets=["publish.manifests=false"])
                st = self.engine(run, relmsg=False).execute(run.step("trust-android-tor"))
                self.assertEqual((st["status"], st["attempts"], st["cause"]), ("failed", 1, cause), st)
                self.assertEqual(st["attempt_causes"], [cause])

    def test_a_refused_step_says_check(self):
        run = self.make_run(only="android", sets=["publish.manifests=false"])
        eng = self.engine(run, relmsg=False)
        eng.refusal = lambda step: "never ship"
        st = eng.execute(run.step("trust-android-tor"))
        self.assertEqual((st["status"], st["cause"]), ("failed", "check: refused"))
        self.assertEqual(st["attempt_causes"], ["check: refused"])

    def test_a_failed_build_says_step(self):
        run = self.make_run(only="android", sets=["publish.manifests=false"])
        wtext(os.path.join(self.src, "fail-tor"), "")
        st = self.engine(run, relmsg=False).execute(run.step("build-android-tor"))
        self.assertEqual((st["status"], st["cause"]), ("failed", "step"))


class FlakyAndDriverTest(Base):
    def setUp(self):
        super().setUp()
        wtext(os.path.join(self.src, "driver.sh"), DRIVER)
        self.run_ = self.make_run(only="android", sets=["publish.manifests=false"])
        self.eng = self.engine(self.run_, relmsg=False)
        self.step = self.run_.step("trust-android-tor")

    def go(self, mode):
        wtext(os.path.join(self.src, "mode"), mode)
        return self.eng.execute(self.step)

    def lines(self):
        path = os.path.join(self.root, "metrics.jsonl")
        return [json.loads(x) for x in rtext(path).splitlines() if '"step": "trust-android-tor"' in x]

    def git(self, repo, *args):
        subprocess.run(["git", "-C", repo, "-c", "user.name=t", "-c", "user.email=t@t", "-c", "commit.gpgsign=false", *args],
                       check=True, capture_output=True)

    def drivers_repo(self):
        repo = os.path.join(self.tmp, "runner")
        os.makedirs(os.path.join(repo, "tools/rellib/drivers"))
        wtext(os.path.join(repo, "tools/rellib/drivers/a.sh"), "echo a\n")
        self.git(repo, "init", "-q")
        self.git(repo, "add", "-A")
        self.git(repo, "commit", "-q", "-m", "drivers")
        return repo

    # ---- flaky ----

    def test_a_pass_after_a_failed_attempt_is_flaky(self):
        self.assertEqual(self.go("bad")["cause"], "product")
        st = self.go("good")
        self.assertEqual((st["status"], st["attempts"], st["flaky"], st["failed_before"]), ("done", 2, True, ["product"]))
        first, second = self.lines()
        self.assertNotIn("flaky", first)
        self.assertIs(second["flaky"], True)

    def test_a_clean_pass_is_not_flaky(self):
        st = self.go("good")
        self.assertFalse(st.get("flaky"))
        self.assertNotIn("flaky", self.lines()[0])

    def test_reports_and_the_gate_say_flaky(self):
        self.go("harness-line")
        self.go("good")
        row = next(r for r in self.run_.summary_rows() if r["id"] == "trust-android-tor")
        self.assertEqual((row["flaky"], row["failed_before"]), (True, ["harness"]))
        md, html = report(self.run_)
        self.assertIn("flaky (2 tries)", rtext(md))
        self.assertIn("flaky (2 tries)", rtext(html))
        state, text = builtins.proof_table(self.eng)["android"]
        self.assertEqual(state, "proven")
        self.assertIn("passed on try 2 (flaky)", text)

    def test_recoveries_are_counted_on_the_metrics_line(self):
        self.go("recovered")
        self.assertEqual(self.lines()[0]["recovered"], 2)
        self.go("good")
        self.assertNotIn("recovered", self.lines()[1])

    # ---- the driver pinned to the evidence ----

    def test_driver_record_follows_the_drivers_files(self):
        repo = self.drivers_repo()
        head = evidence.driver_record(repo)
        self.assertEqual(head["dirty"], None)
        self.assertEqual(len(head["commit"]), 40)
        wtext(os.path.join(repo, "tools/rellib/drivers/a.sh"), "echo b\n")
        edited = evidence.driver_record(repo)["dirty"]
        self.assertTrue(edited and len(edited) == 12)
        wtext(os.path.join(repo, "tools/rellib/drivers/a.sh"), "echo a\n")
        self.assertIsNone(evidence.driver_record(repo)["dirty"])
        wtext(os.path.join(repo, "tools/rellib/drivers/new.py"), "x = 1\n")
        new = evidence.driver_record(repo)["dirty"]
        self.assertTrue(new)
        wtext(os.path.join(repo, "tools/rellib/drivers/new.py"), "x = 2\n")
        self.assertNotEqual(evidence.driver_record(repo)["dirty"], new, "an untracked file's bytes count")
        os.makedirs(os.path.join(repo, "tools/rellib/drivers/__pycache__"))
        wtext(os.path.join(repo, "tools/rellib/drivers/__pycache__/a.pyc"), "junk")
        wtext(os.path.join(repo, "tools/rellib/other.sh"), "outside\n")
        before = evidence.driver_record(repo)["dirty"]
        wtext(os.path.join(repo, "tools/rellib/drivers/__pycache__/a.pyc"), "other junk")
        self.assertEqual(evidence.driver_record(repo)["dirty"], before)
        self.assertEqual(evidence.driver_record(self.tmp), {"commit": None, "dirty": None}, "not a git repo")

    def test_the_driver_is_recorded_in_status_and_in_proof_json(self):
        self.eng.runner = self.drivers_repo()
        st = self.go("good")
        rec = evidence.driver_record(self.eng.runner)
        self.assertEqual(st["driver"], rec)
        self.assertEqual(st["drivers"], [dict(rec, attempt=1)])
        self.assertEqual(st["proof"]["driver"], rec)
        on_disk = json.loads(rtext(os.path.join(self.run_.step_dir(self.step.id), "out", "proof.json")))
        self.assertEqual(on_disk["driver"], rec)
        self.assertFalse(st.get("driver_changed"))
        self.assertNotIn("driver_changed", self.lines()[0])

    def test_a_driver_edited_between_attempts_is_marked(self):
        repo = self.eng.runner = self.drivers_repo()
        self.go("bad")
        wtext(os.path.join(repo, "tools/rellib/drivers/a.sh"), "echo changed\n")
        st = self.go("good")
        old = evidence.driver_label({"commit": subprocess.run(["git", "-C", repo, "rev-parse", "HEAD"], capture_output=True,
                                                              text=True).stdout.strip(), "dirty": None})
        self.assertIs(st["driver_changed"], True)
        self.assertIn(f"; drivers changed between attempts ({old} → {old}+dirty)", st["note"])
        self.assertEqual([d["attempt"] for d in st["drivers"]], [1, 2])
        self.assertIs(self.lines()[-1]["driver_changed"], True)
        self.assertIsNone(self.lines()[0].get("driver_changed"))
        self.assertIn("DRIVERS CHANGED between attempts", builtins.proof_table(self.eng)["android"][1])
        md, _ = report(self.run_)
        self.assertIn("DRIVERS CHANGED between attempts", rtext(md))

    def test_the_same_driver_twice_is_not_a_change(self):
        self.eng.runner = self.drivers_repo()
        self.go("bad")
        st = self.go("good")
        self.assertFalse(st.get("driver_changed"))
        self.assertNotIn("drivers changed", st["note"])
        self.assertNotIn("DRIVERS CHANGED", builtins.proof_table(self.eng)["android"][1])


def line(run, step, status, attempt=1, cause=None, dur=100.0, **kw):
    d = {"run": run, "step": step, "base": step.rsplit("-", 1)[0], "status": status, "attempt": attempt, "duration_s": dur}
    if cause:
        d["cause"] = cause
    d.update(kw)
    return d


class LaneHealthTest(Base):
    A = "trust-android-tor"

    def metrics(self, lines):
        path = os.path.join(self.root, "metrics.jsonl")
        os.makedirs(self.root, exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            for ln in lines:
                f.write((ln if isinstance(ln, str) else json.dumps(ln)) + "\n")
        return path

    def history(self):
        """android: 6 runs, first try passes in 2, harness failures otherwise, 1 recovery; linux always passes."""
        out = []
        for i in range(1, 7):
            run = f"26.10.26-run{i}"
            if i in (1, 4):
                out.append(line(run, self.A, "done", dur=1000.0 + i))
            else:
                out.append(line(run, self.A, "failed", 1, "harness", 5.0))
                out.append(line(run, self.A, "done", 2, dur=2000.0, **({"recovered": 1} if i == 6 else {})))
            out.append(line(run, "trust-linux-tor", "done", dur=500.0))
        return out

    def test_lane_numbers(self):
        junk = ["not json", {"kind": "overlap", "run": "26.10.26-run6", "steps": ["trust-android-tor"]},
                line("26.10.26-run7", self.A, "failed", cause="product", dry=True), line("26.10.26-run6", "build-android-tor", "done"),
                line("26.10.26-run6", "trust-manifest", "done")]
        lanes = {h["lane"]: h for h in health.lanes_of(self.metrics(self.history() + junk))}
        self.assertEqual(sorted(lanes), ["trust-android-tor", "trust-linux-tor"])
        a = lanes[self.A]
        self.assertEqual((a["runs"], a["first_try"], a["rate"], a["tries"], a["recovered"], a["weak"]), (6, 2, 0.33, 1.7, 1, True))
        self.assertEqual(a["mean_pass_s"], round((1001 + 1004 + 4 * 2000) / 6))
        self.assertEqual(a["causes"], {"harness": 4})
        self.assertEqual(a["last_causes"], {"harness": 1})
        l = lanes["trust-linux-tor"]
        self.assertEqual((l["first_try"], l["rate"], l["tries"], l["weak"]), (6, 1.0, 1.0, False))

    def test_last_runs_only_and_the_last_runs_causes(self):
        lines = self.history()
        a = {h["lane"]: h for h in health.lanes_of(self.metrics(lines), {"runs": 3})}[self.A]
        self.assertEqual((a["runs"], a["first_try"]), (3, 1))   # runs 4, 5 and 6
        self.assertEqual(a["last_causes"], {"harness": 1})
        lines.append(line("26.10.26-run7", self.A, "done"))
        a = {h["lane"]: h for h in health.lanes_of(self.metrics(lines), {"runs": 3})}[self.A]
        self.assertEqual((a["first_try"], a["last_causes"]), (1, {}))   # runs 5, 6 and 7

    def test_weak_needs_enough_runs_and_a_low_rate(self):
        lines = [line("r1", self.A, "failed", 1, "product"), line("r2", self.A, "failed", 1, "product")]
        self.assertFalse(health.lanes_of(self.metrics(lines))[0]["weak"], "2 runs are fewer than min_runs")
        lines.append(line("r3", self.A, "failed", 1, "product"))
        self.assertTrue(health.lanes_of(self.metrics(lines))[0]["weak"])
        self.assertFalse(health.lanes_of(self.metrics(lines), {"min_first_try": 0.0})[0]["weak"])
        self.assertEqual(health.lanes_of(self.metrics([])), [])
        self.assertEqual(health.lanes_of(os.path.join(self.tmp, "none.jsonl")), [])

    def test_the_gate_names_weak_lanes_before_approve(self):
        self.metrics(self.history())
        run = self.make_run(only="android", sets=["publish.manifests=false"])
        text = builtins.gate_summary(self.engine(run, relmsg=False))
        want = "- trust-android-tor: first try 2/6, 1.7 tries a run, causes harness×4, recovered 1"
        self.assertIn(want, text)
        self.assertNotIn("- trust-linux-tor: first try", text)
        self.assertLess(text.index(want), text.index("Approve = tag"))

    def test_the_gate_has_no_lane_lines_when_all_is_well(self):
        self.metrics([ln for ln in self.history() if ln["step"] != self.A])
        run = self.make_run(only="android", sets=["publish.manifests=false"])
        self.assertNotIn("Weak trust lanes", builtins.gate_summary(self.engine(run, relmsg=False)))

    def test_a_long_gate_message_never_loses_its_approve_line(self):
        self.metrics(self.history())
        run = self.make_run(only="android", sets=["publish.manifests=false"])
        eng = self.engine(run, relmsg=False)
        old_line, old_screens = health.weak_line, builtins.screens_lines
        self.addCleanup(setattr, health, "weak_line", old_line)
        self.addCleanup(setattr, builtins, "screens_lines", old_screens)
        health.weak_line = lambda h: "- " + h["lane"] + " " + "w" * 3000
        text = builtins.gate_summary(eng)
        self.assertLessEqual(len(text), 2900)
        self.assertIn("Weak trust lanes (they still gate): trust-android-tor (tools/rel stats --lanes)", text)
        self.assertIn("Approve = tag", text)
        builtins.screens_lines = lambda r: ["S" * 3500, "b", "c", "d"]
        text = builtins.gate_summary(eng)
        self.assertLessEqual(len(text), 2900)
        self.assertIn("Approve = tag, then publish", text)

    def test_the_report_has_the_table(self):
        self.metrics(self.history())
        run = self.make_run(only="android", sets=["publish.manifests=false"])
        md, html = report(run, {"runs": 6})
        self.assertIn("## Lane health (last 6 runs)", rtext(md))
        self.assertIn("| trust-android-tor (weak) | 6 | 2/6 (33%) | 1.7 | 1 |", rtext(md))
        self.assertIn("Lane health (last 6 runs)", rtext(html))
        self.assertIn("trust-linux-tor", rtext(html))

    def test_stats_lanes(self):
        self.metrics(self.history())
        common = ["--state-root", self.root, "--hosts", os.path.join(self.tmp, "no-hosts.toml")]
        out, err = io.StringIO(), io.StringIO()
        with redirect_stdout(out), redirect_stderr(err):
            code = main(["--json", *common, "stats", "--lanes"])
        self.assertEqual(code, 0, err.getvalue())
        obj = json.loads(out.getvalue())
        self.assertEqual({h["lane"]: h["weak"] for h in obj["lanes"]}, {self.A: True, "trust-linux-tor": False})
        self.assertEqual(obj["health"], {"runs": 10, "min_first_try": 0.8, "min_runs": 3})
        out = io.StringIO()
        with redirect_stdout(out), redirect_stderr(io.StringIO()):
            main([*common, "stats", "--lanes"])
        self.assertIn("Lane health (last 10 runs)", out.getvalue())
        self.assertIn("trust-android-tor (weak)", out.getvalue())

    def test_the_health_table_is_read_from_pipeline_toml(self):
        import tomllib
        with open(os.path.join(REPO, "release/pipeline.toml"), "rb") as f:
            data = tomllib.load(f)
        self.assertEqual(health.settings(data.get("health")), {"runs": 10, "min_first_try": 0.8, "min_runs": 3})
        for bad in ({"runs": 0}, {"min_runs": "3"}, {"min_first_try": 1.5}):
            with self.assertRaises(ConfigError):
                Pipeline(dict(data, health=bad))


if __name__ == "__main__":
    unittest.main()
