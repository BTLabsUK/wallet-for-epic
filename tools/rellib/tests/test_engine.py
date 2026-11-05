# SPDX-License-Identifier: Apache-2.0
"""The engine on fake steps: order, outputs, failures and hints, resume, proofs, gates (fail
closed), skips, the publish phase and exit codes."""
import json
import os
import subprocess
import time
import unittest

from support import FAKE_PIPELINE, REPO, Base
from rellib import builtins
from rellib.engine import EXIT_DENIED, EXIT_FAILED, EXIT_OK, EXIT_PREFLIGHT, EXIT_WAITING, Engine


class EngineTest(Base):
    def test_builds_run_and_outputs_are_collected(self):
        run = self.make_run(only="android,linux", sets=["publish.manifests=false"])
        eng = self.engine(run)
        code = eng.drive(self.build_ids(run))
        self.assertEqual(code, EXIT_WAITING)  # stops at the publish gate
        self.assertEqual(run.status("publish-gate")["status"], "waiting")
        files = sorted(os.listdir(run.files))
        self.assertEqual(files, ["bt-wallet-26.10.25-android-arm64-v8a.apk", "bt-wallet-26.10.25-linux-x86_64.AppImage",
                                 "bt-wallet-26.10.25-notor-android-arm64-v8a.apk", "bt-wallet-26.10.25-notor-linux-x86_64.AppImage"])
        self.assertTrue(os.path.isfile(os.path.join(run.extra, "emulator/x-notor.apk")))
        st = run.status("build-android-tor")
        self.assertEqual(st["outputs"]["bt-wallet-26.10.25-android-arm64-v8a.apk"]["bytes"], 2000000)
        self.assertNotIn("publish", self.calls())  # nothing outward in the build phase
        self.assertIn("driver tor checks=wallet_opens,history_kept,send_ok funds=1", self.calls())
        ev = [e["event"] for e in run.events()]
        self.assertIn("start", ev)
        self.assertIn("end", ev)
        metrics = open(os.path.join(self.root, "metrics.jsonl")).read()
        self.assertIn('"base": "build-android"', metrics)
        line = next(json.loads(x) for x in metrics.splitlines() if '"step": "build-android-tor"' in x)
        self.assertTrue(line["started"] and line["ended"] and line["lane"])
        self.assertIn("step build-android-tor running", self.relmsg_calls())

    def test_load_sampler_peaks_per_step_and_overlaps(self):
        from rellib.load import LoadSampler
        ls = LoadSampler(interval=0.05)
        ls.start()
        ls.step_started("a")
        ls.step_started("b")
        time.sleep(0.3)
        b = ls.step_ended("b")
        a = ls.step_ended("a")
        ls.stop()
        for f in (a, b):
            self.assertGreater(f["mem_peak_gb"], 0)
            self.assertIn("cpu_avg_pct", f)
        self.assertEqual(a["beside"], ["b"])
        ov = ls.take_overlaps()
        self.assertEqual([o["steps"] for o in ov], [["a", "b"]])
        self.assertEqual(ls.take_overlaps(), [])
        self.assertEqual(ls.step_ended("never"), {})

    def test_failure_stops_dependents_gives_hint_and_exit_20(self):
        open(os.path.join(self.src, "fail-notor"), "w").close()
        run = self.make_run(only="android,linux", sets=["publish.manifests=false"])
        eng = self.engine(run)
        eng.failures = [{"id": "fake", "steps": ["build-android"], "pattern": "test ! -e", "hint": "remove the fail file"}]
        code = eng.drive(self.build_ids(run))
        self.assertEqual(code, EXIT_FAILED)
        st = run.status("build-android-notor")
        self.assertEqual(st["status"], "failed")
        self.assertEqual(st["hint"], "remove the fail file")
        self.assertEqual(run.status("trust-android-tor")["status"], "pending")
        self.assertIn("alert build-android-notor failed", self.relmsg_calls())
        self.assertIn("--no-alert", self.relmsg_calls())

    def test_known_failure_hint(self):
        run = self.make_run(only="android", sets=["publish.manifests=false"])
        eng = self.engine(run)
        eng.failures = [{"id": "nospace", "pattern": "No space left", "hint": "free disk"}]
        s = run.step("build-android-tor")
        s.run = "echo 'write: No space left on device'; exit 1"
        st = eng.execute(s)
        self.assertEqual(st["hint"], "free disk")
        self.assertEqual(st["known"], ["nospace"])
        self.assertIn("free disk", self.relmsg_calls())

    def test_resume_keeps_done_steps_and_reruns_failed(self):
        open(os.path.join(self.src, "fail-notor"), "w").close()
        run = self.make_run(only="android,linux", sets=["publish.manifests=false"])
        eng = self.engine(run)
        self.assertEqual(eng.drive(self.build_ids(run)), EXIT_FAILED)
        first = self.calls().count("build tor")
        os.remove(os.path.join(self.src, "fail-notor"))
        for sid in self.build_ids(run):
            if run.status(sid)["status"] == "failed":
                run.set_status(sid, retry=True)
        eng2 = Engine(run, self.pipeline, self.hosts, eng.repo, relmsg=eng.relmsg)
        self.assertEqual(eng2.drive(self.build_ids(run)), EXIT_WAITING)
        self.assertEqual(self.calls().count("build tor"), first)  # not built again
        self.assertEqual(self.calls().count("build notor"), 2)
        self.assertEqual(run.status("build-android-notor")["attempts"], 2)
        self.assertTrue(os.path.isfile(os.path.join(run.step_dir("build-android-notor"), "attempt-1.log")))
        self.assertTrue(os.path.isfile(os.path.join(run.step_dir("build-android-notor"), "attempt-2.log")))

    def test_missing_output_fails(self):
        run = self.make_run(only="android", sets=["publish.manifests=false"])
        eng = self.engine(run)
        s = run.step("build-android-tor")
        s.run = "true"
        st = eng.execute(s)
        self.assertEqual(st["status"], "failed")
        self.assertIn("outputs missing", st["note"])

    def proof(self, mode):
        with open(os.path.join(self.src, "proof-mode"), "w") as f:
            f.write(mode)
        run = self.make_run(only="android", sets=["publish.manifests=false"])
        eng = self.engine(run)
        eng.drive(self.build_ids(run))
        return run

    def test_proof_all_true_passes(self):
        run = self.proof("good")
        self.assertEqual(run.status("trust-android-tor")["status"], "done")
        self.assertTrue(run.status("trust-android-tor")["proven"])
        self.assertEqual(run.status("update-trust")["status"], "done")

    def test_proof_fails_closed(self):
        for mode in ("bad", "liar", "none"):
            with self.subTest(mode=mode):
                self.tearDown()
                self.setUp()
                run = self.proof(mode)
                self.assertEqual(run.status("trust-android-tor")["status"], "failed", mode)
                self.assertEqual(run.status("update-trust")["status"], "pending")
                self.assertEqual(run.status("publish-gate")["status"], "pending")

    def test_proof_beside_drops_only_carried_checks_for_a_listed_pair(self):
        run = self.proof("beside")
        self.assertEqual(run.status("trust-android-tor")["status"], "done")
        self.assertTrue(run.status("trust-android-tor")["proven"])

    def test_proof_beside_refused_for_another_pair(self):
        run = self.proof("beside-other")
        self.assertEqual(run.status("trust-android-tor")["status"], "failed")
        self.assertIn("history_kept", run.status("trust-android-tor")["note"])

    def test_same_inputs_reuse_an_earlier_passing_build(self):
        a = self.make_run(only="linux", sets=["publish.manifests=false"])
        self.engine(a).drive(self.build_ids(a))
        self.assertEqual(self.calls().count("linux tor"), 1)
        key = a.status("build-linux-tor")["reuse_key"]
        b = self.make_run(only="linux", sets=["publish.manifests=false"])
        self.engine(b).drive(self.build_ids(b))
        st = b.status("build-linux-tor")
        self.assertEqual(self.calls().count("linux tor"), 1, "not built again")
        self.assertEqual((st["status"], st["reuse_key"]), ("done", key))
        self.assertIn("reused from", st["note"])
        self.assertTrue(os.path.isfile(os.path.join(b.files, "bt-wallet-26.10.25-linux-x86_64.AppImage")))
        # Its files gone or changed: no reuse, it builds.
        os.remove(os.path.join(a.files, "bt-wallet-26.10.25-linux-x86_64.AppImage"))
        os.remove(os.path.join(b.files, "bt-wallet-26.10.25-linux-x86_64.AppImage"))
        c = self.make_run(only="linux", sets=["publish.manifests=false"])
        self.engine(c).drive(self.build_ids(c))
        self.assertEqual(self.calls().count("linux tor"), 2)
        # Another version is another key.
        d = self.make_run(version="26.10.26", only="linux", sets=["publish.manifests=false"])
        self.engine(d).drive(self.build_ids(d))
        self.assertEqual(self.calls().count("linux tor"), 3)

    def test_reuse_key_follows_the_content_of_the_paths(self):
        from rellib import reuse
        head = subprocess.run(["git", "-C", REPO, "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
        app = reuse.path_id(REPO, head, "app")
        no_tests = reuse.path_id(REPO, head, "app", ["app/test"])
        self.assertNotEqual(app, no_tests)
        self.assertEqual(no_tests, reuse.path_id(REPO, head, "app", ["app/test"]))
        self.assertEqual(reuse.path_id(REPO, head, "no/such/path"), "missing")

    def test_waived_platform_runs_its_driver_and_shows_what_it_found(self):
        with open(os.path.join(self.src, "proof-mode"), "w") as f:
            f.write("bad")
        run = self.make_run(only="android", sets=["publish.manifests=false"], waive=["android=bug #143 open"])
        eng = self.engine(run)
        eng.drive(self.build_ids(run))
        st = run.status("trust-android-tor")
        self.assertEqual(st["status"], "done")          # reported, blocks nothing
        self.assertFalse(st["proven"])
        self.assertIn("NOT PROVEN (waived: bug #143 open): not proven: history_kept (0 of 3 txs)", st["note"])
        self.assertEqual(run.status("update-trust")["status"], "done")
        summary = builtins.gate_summary(eng)
        self.assertIn("NOT PROVEN — waived: bug #143 open · driver: tor: NOT PROVEN", summary)
        self.assertIn("history_kept", summary)

    def test_waived_platform_is_shown_not_proven(self):
        run = self.make_run(only="android", sets=["publish.manifests=false"], waive=["android=no emulator today"])
        eng = self.engine(run)
        eng.drive(self.build_ids(run))
        self.assertEqual(run.status("trust-android-tor")["status"], "done")   # the driver still ran
        ut = run.status("update-trust")
        self.assertEqual(ut["status"], "done")
        self.assertIn("NOT PROVEN", ut["note"])
        summary = builtins.gate_summary(eng)
        self.assertIn("NOT PROVEN — waived: no emulator today", summary)

    def test_update_trust_fails_for_a_platform_without_proof(self):
        run = self.make_run(only="android", sets=["publish.manifests=false"])
        eng = self.engine(run)
        s = run.step("update-trust")
        st = eng.execute(s)
        self.assertEqual(st["status"], "failed")
        self.assertIn("android", st["note"])

    def gate(self, answer, relmsg=True, taint=False):
        run = self.make_run(only="android", sets=["publish.manifests=false"])
        if taint:
            run.taint("a step ran with unmet needs")
        eng = self.engine(run, relmsg=relmsg)
        os.environ["REL_FAKE_GATE"] = answer
        eng.drive(self.build_ids(run))
        return run, eng

    def test_gate_approved(self):
        run, eng = self.gate("approved")
        self.assertEqual(run.status("publish-gate")["status"], "done")
        self.assertIn("approved by the owner via telegram", run.status("publish-gate")["note"])
        self.assertEqual(eng.exit_code(self.build_ids(run)), EXIT_OK)

    def test_gate_fails_closed(self):
        for answer, status, code in (("pending", "waiting", EXIT_WAITING), ("held", "held", EXIT_DENIED),
                                     ("error", "closed", EXIT_DENIED), ("crash", "closed", EXIT_DENIED),
                                     ("approved-but-exit1", "closed", EXIT_DENIED)):
            with self.subTest(answer=answer):
                run, eng = self.gate(answer)
                self.assertEqual(run.status("publish-gate")["status"], status)
                self.assertEqual(eng.exit_code(self.build_ids(run)), code)
        run, eng = self.gate("approved", relmsg=False)
        self.assertEqual(run.status("publish-gate")["status"], "closed")
        run, eng = self.gate("approved", taint=True)
        self.assertEqual(run.status("publish-gate")["status"], "closed")
        self.assertIn("tainted", run.status("publish-gate")["note"])

    def test_gate_reasks_and_keeps_its_id(self):
        run, eng = self.gate("pending")
        os.environ["REL_FAKE_GATE"] = "approved"
        st = eng.execute(run.step("publish-gate"))
        self.assertEqual(st["status"], "done")
        self.assertEqual(self.relmsg_calls().count(" gate publish "), 1)  # opened once, polled twice
        self.assertEqual(run.info["gates"]["publish"]["gate_id"], 3)

    def test_relay_rate_limit_is_waited_out_never_an_answer(self):
        os.environ["REL_FAKE_BUSY"] = "3"
        run, eng = self.gate("approved")
        self.assertEqual(run.status("publish-gate")["status"], "done")
        self.assertTrue(any(e["event"] == "relmsg" and e.get("status") == "retry" or "retry" in json.dumps(e)
                            for e in run.events()))

    def test_relay_down_is_asked_once_more_then_left_alone(self):
        os.environ["REL_FAKE_DOWN"] = "1"
        run, eng = self.gate("approved")
        self.assertEqual(run.status("publish-gate")["status"], "closed")  # fail closed
        calls = self.relmsg_calls().splitlines()
        self.assertEqual(len([c for c in calls if " start " in f" {c} "]), 4)  # start: three waits
        self.assertLessEqual(len(calls), 8)  # nothing else retried once the relay was found down

    def test_publish_phase_only_after_gate_and_skips_recorded(self):
        run = self.make_run(only="android", sets=["publish.manifests=false", "publish.github=false"],
                             skips=["publish-source=token renewal"])
        os.environ["REL_FAKE_GATE"] = "approved"
        eng = self.engine(run)
        eng.drive(self.build_ids(run))
        self.assertEqual(run.status("publish-downloads")["status"], "pending")
        code = eng.drive([s.id for s in run.steps])
        self.assertEqual(code, EXIT_OK)
        self.assertEqual(run.status("publish-downloads")["status"], "done")  # scratch target
        self.assertEqual(run.status("publish-source")["status"], "skipped")
        self.assertEqual(run.status("publish-source")["reason"], "token renewal")

    def test_warn_only_failure_warns_and_holds_nothing(self):
        import tomllib
        from rellib.config import Pipeline
        from support import FAKE_PIPELINE
        self.pipeline = Pipeline(tomllib.loads(FAKE_PIPELINE + """
[step.after]
publish = true
warn_only = true
needs = ["publish-source"]
run = "echo after >> {src}/calls; mkdir -p {stage}; echo '[{\\"label\\": \\"L\\", \\"url\\": \\"https://x.example/\\"}]' > {stage}/links.json; exit 3"

[step.last]
kind = "publish"
needs = ["after"]
run = "echo last >> {src}/calls"
scratch = "scratch_noop"
"""))
        run = self.make_run(only="android", sets=["publish.manifests=false", "publish.github=false"])
        os.environ["REL_FAKE_GATE"] = "approved"
        eng = self.engine(run)
        eng.drive(self.build_ids(run))
        code = eng.drive([s.id for s in run.steps])
        self.assertEqual(code, EXIT_OK)
        st = run.status("after")
        self.assertEqual((st["status"], st.get("warned")), ("done", True))
        self.assertIn("WARNING, not blocking", st["note"])
        self.assertEqual(run.status("last")["status"], "done")
        self.assertIn("last", self.calls())
        self.assertEqual(next(r for r in run.summary_rows() if r["id"] == "after")["status"], "warned")
        relmsg = open(os.path.join(self.tmp, "relmsg.calls")).read()
        self.assertIn("step after failed", relmsg)       # shown as failed in the live message …
        self.assertNotIn("alert after failed", relmsg)   # … with no alert,
        self.assertNotIn("link L", relmsg)                # and a failed step's links are not shown

    def test_warn_only_is_refused_on_a_gate_or_build(self):
        import tomllib
        from rellib.config import ConfigError, Pipeline
        from support import FAKE_PIPELINE
        for extra in ('[step.g]\nkind = "gate"\nwarn_only = true\n',
                      '[step.b]\nrun = "true"\noutputs = ["x"]\nwarn_only = true\n'):
            with self.assertRaises(ConfigError):
                Pipeline(tomllib.loads(FAKE_PIPELINE + extra))

    def test_preflight_failure_is_exit_30(self):
        run = self.make_run(only="android", sets=["publish.manifests=false"])
        from rellib.graph import Step
        pre = Step(id="preflight", base="preflight", kind="builtin", title="pre", host="local", lane="local", platforms=[])
        run.steps.insert(0, pre)
        run.set_status("preflight", status="pending")
        self.pipeline.defaults["min_free_gb"] = 10 ** 9
        self.hosts["exists"] = False
        builtins.health_node, saved_n = (lambda u, timeout=10: False), builtins.health_node
        builtins.health_epicbox, saved_b = (lambda h, timeout=8: True), builtins.health_epicbox
        try:
            eng = self.engine(run)
            code = eng.drive(["preflight"])
        finally:
            builtins.health_node, builtins.health_epicbox = saved_n, saved_b
        self.assertEqual(code, EXIT_PREFLIGHT)
        st = run.status("preflight")
        self.assertTrue(any("disk" in p for p in st["problems"]))
        self.assertTrue(any("node for tests" in p for p in st["problems"]))
        self.assertTrue(any("release-hosts" in p or "hosts.example" in p for p in st["problems"]))

    def test_health_pick_order(self):
        seen = []
        pick, tried = builtins.pick(["a", "b", "c"], lambda x: seen.append(x) or x == "b")
        self.assertEqual((pick, tried), ("b", ["a", "b"]))
        pick, tried = builtins.pick(["a", "b"], lambda x: False, override="z")
        self.assertEqual((pick, tried), (None, ["z", "a", "b"]))

    def test_dry_run_runs_nothing(self):
        run = self.make_run(only="android", sets=["publish.manifests=false"])
        run.info["dry"] = True
        run.save_info()
        eng = Engine(run, self.pipeline, self.hosts, self.src, dry=True)
        code = eng.drive([s.id for s in run.steps])
        self.assertEqual(code, EXIT_OK)
        self.assertNotIn("build tor", self.calls())
        self.assertNotIn("publish", self.calls())
        self.assertEqual(os.listdir(run.files), [])
        log = open(os.path.join(run.step_dir("build-android-tor"), "log.txt")).read()
        self.assertIn("# run: echo build tor", log)


FLOW_PIPELINE = FAKE_PIPELINE.replace('funds_variant = "tor"', 'funds_variant = "tor"\nfunds_in = "flow"').replace(
    "[step.build-android]", """[step.flow-linux]
platform = "linux"
for_each = "proof_variant"
needs = ["scope"]
capped = true
run = "bash {src}/driver.sh"
env = { REL_TRUST_MODE = "flow" }

[step.build-android]""").replace('needs = ["scope"]\nrun = "echo build', 'needs = ["scope", "flow-linux"]\nrun = "echo build').replace(
    'needs = ["scope"]\nrun = "echo linux', 'needs = ["scope", "flow-linux"]\nrun = "echo linux')


class FlowLaneTest(Base):
    """A flow lane (REL_TRUST_MODE=flow) on the test build, before the release builds."""

    def setUp(self):
        super().setUp()
        import tomllib
        from rellib.config import Pipeline
        self.pipeline = Pipeline(tomllib.loads(FLOW_PIPELINE))

    def test_flow_lane_takes_the_funds_legs_and_the_update_lanes_do_not(self):
        run = self.make_run(only="android,linux", sets=["publish.manifests=false"])
        self.assertEqual(self.engine(run).drive(self.build_ids(run)), EXIT_WAITING)
        calls = self.calls()
        self.assertEqual(calls[0], "driver tor checks=wallet_opens,history_kept,send_ok funds=1")
        self.assertEqual(calls.count("driver tor checks=wallet_opens,history_kept funds=0"), 2)  # trust-android, trust-linux
        self.assertIn("flow passed on the test build", run.status("flow-linux-tor")["note"])

    def test_a_failed_flow_lane_fails_closed_before_any_build(self):
        with open(os.path.join(self.src, "proof-mode"), "w") as f:
            f.write("liar")  # exit 0, but proof.json lacks a required check
        run = self.make_run(only="android,linux", sets=["publish.manifests=false"])
        self.assertEqual(self.engine(run).drive(self.build_ids(run)), EXIT_FAILED)
        self.assertEqual(run.status("flow-linux-tor")["status"], "failed")
        self.assertFalse([c for c in self.calls() if c.startswith(("build", "linux"))], "no build started")

    def test_funds_in_is_checked(self):
        import tomllib
        from rellib.config import ConfigError, Pipeline
        with self.assertRaises(ConfigError):
            Pipeline(tomllib.loads(FLOW_PIPELINE.replace('funds_in = "flow"', 'funds_in = "both"')))


if __name__ == "__main__":
    unittest.main()
