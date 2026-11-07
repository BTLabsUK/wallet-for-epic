# SPDX-License-Identifier: Apache-2.0
"""No blind retry (tools/rellib/repeats.py): each refusal fires, each way past it works, and the run
counts what was repeated. The lane's own refusal to start over: test_lane_resume.py."""
import json
import os
import pathlib
import subprocess
from unittest import mock

from support import Base, FAKE_PIPELINE
from rellib import evidence, repeats, window
from rellib.cli import report
from test_cli import rel

LANE = r"""#!/usr/bin/env bash
# A fake lane: $REL_SRC/<name>.json is its proof and <name>.rc its exit code, by what asked for it.
echo "lane $REL_OUT probe=${REL_TRUST_PROBE:-} fresh=${REL_TRUST_FRESH:-} resume=${REL_TRUST_RESUME:-} prior=${REL_PRIOR_CAUSE:-}" >> "$REL_SRC/calls"
name=attempt
[[ $REL_OUT == *trust-linux* ]] && name=linux
[[ -n ${REL_TRUST_PROBE:-} ]] && name=probe
if [[ -e $REL_SRC/$name.json ]]; then cat "$REL_SRC/$name.json" > "$REL_OUT/proof.json"; fi
exit "$(cat "$REL_SRC/$name.rc")"
"""
AT = "find-g4.advanced.technical"
GOOD = {"checks": {"wallet_opens": True, "history_kept": True, "send_ok": True}}


def fault(kind, step=AT):
    return {"fault": {"kind": kind, "cause_class": kind, "step": step, "what": "no row", "line": "%s %s" % (kind.upper(), step)},
            "phases": {"done": ["prepare", "install"], "failed": "previous-setup", "kept": []}, "checks": {}}


class Repeats(Base):
    def setUp(self):
        super().setUp()
        self.write("driver.sh", LANE)
        self.pipe = os.path.join(self.tmp, "pipeline.toml")
        pathlib.Path(self.pipe).write_text(FAKE_PIPELINE)
        self.lane("linux", GOOD, 0)
        self.run_ = self.make_run(only="android,linux", sets=["publish.manifests=false"])
        for s in self.run_.steps:
            if s.kind == "builtin" or s.id.startswith("build-"):
                self.run_.set_status(s.id, status="done")
        self.repo = self.drivers_repo()
        self.eng = self.engine(self.run_, relmsg=False)
        self.eng.runner = self.repo
        self.android = self.run_.step("trust-android-tor")
        self.linux = self.run_.step("trust-linux-tor")
        patch = mock.patch("rellib.cli.RUNNER", self.repo)
        patch.start()
        self.addCleanup(patch.stop)

    def write(self, name, text):
        pathlib.Path(os.path.join(self.src, name)).write_text(text)

    def lane(self, name, proof, rc):
        path = pathlib.Path(os.path.join(self.src, name + ".json"))
        path.write_text(json.dumps(proof)) if proof is not None else path.unlink(missing_ok=True)
        self.write(name + ".rc", str(rc))

    def git(self, *args):
        return subprocess.run(["git", "-C", self.repo, "-c", "user.name=t", "-c", "user.email=t@t", "-c", "commit.gpgsign=false",
                               *args], check=True, capture_output=True, text=True).stdout.strip()

    def drivers_repo(self):
        self.repo = os.path.join(self.tmp, "runner")
        os.makedirs(os.path.join(self.repo, "tools/rellib/drivers"))
        pathlib.Path(self.repo, "tools/rellib/drivers/a.py").write_text("a = 1\n")
        pathlib.Path(self.repo, "other.txt").write_text("1\n")
        self.git("init", "-q")
        self.commit()
        return self.repo

    def commit(self):
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "x")

    def driver_fix(self, text="a = 2\n"):
        pathlib.Path(self.repo, "tools/rellib/drivers/a.py").write_text(text)
        self.commit()

    def fail(self, kind="harness", rc=2, step=None):
        self.lane("attempt", fault(kind, step or AT), rc)
        return self.eng.execute(self.android)

    def rel(self, *args):
        cmd, *rest = args
        return rel("--state-root", self.root, "--hosts", os.path.join(self.tmp, "none.toml"), "--pipeline", self.pipe,
                   cmd, "--run", self.run_.path, *rest)

    def probe(self, passed=True, target="trust-android-tor", step=AT):
        self.lane("probe", {"probe": {"step": step, "reached": step if passed else None, "passed": passed},
                            "checks": {}}, 0 if passed else 2)
        return self.rel("probe", step, target)

    def st(self, step=None):
        return self.run_.status((step or self.android).id)

    def events(self, name):
        return [e for e in self.run_.events() if e["event"] == name]

    def lanes_run(self):
        return [c for c in self.calls() if c.startswith("lane") and "trust-android" in c and "probe=find" not in c]


class HarnessGateTest(Repeats):
    def test_a_failed_attempt_leaves_its_record(self):
        st = self.fail()
        rec = st["failures"][0]
        self.assertEqual((rec["attempt"], rec["cause"], rec["kind"], rec["step"], rec["phase"]),
                         (1, "harness", "harness", AT, "previous-setup"))
        self.assertEqual(rec["driver"]["commit"], self.git("rev-parse", "HEAD"))
        self.assertEqual(st["attempt_seconds"], [rec["seconds"]])

    def test_a_retry_without_a_probe_is_refused(self):
        self.fail()
        code, out, err = self.rel("retry", self.android.id)
        self.assertEqual(code, 40, out + err)
        label = evidence.driver_label(self.st()["failures"][0]["driver"])
        self.assertEqual(out.strip(), f"refused: trust-android-tor failed on the driver at {AT} (harness, attempt 1, driver {label}). "
                                      f"A retry needs that step passed alone on android on a newer driver commit: change the driver, "
                                      f"commit it, then tools/rel probe {AT} trust-android-tor.")
        self.assertEqual(len(self.lanes_run()), 1)
        self.assertEqual((self.st()["status"], self.st()["attempts"]), ("failed", 1))
        self.assertEqual(self.events("repeat-refused")[-1]["rule"], "needs-probe")

    def test_run_is_refused_too(self):
        self.fail()
        self.assertEqual(self.rel("run", self.android.id)[0], 40)
        self.assertEqual(len(self.lanes_run()), 1)

    def test_a_reason_does_not_stand_in_for_a_probe(self):
        self.fail()
        code, out, _ = self.rel("retry", self.android.id, "--fresh", "I am sure")
        self.assertEqual(code, 40)
        self.assertIn("needs that step passed alone", out)
        self.assertFalse(self.events("fresh-forced"))

    def test_resume_leaves_the_lane_and_says_why(self):
        self.fail()
        code, out, err = self.rel("resume", "--keep-going")
        self.assertEqual(code, 20, out + err)
        self.assertEqual(len(self.lanes_run()), 1)
        self.assertIn("needs that step passed alone", self.st()["stopped"])
        self.assertEqual(self.run_.status(self.linux.id)["status"], "done")

    def test_a_probe_on_another_platform_does_not_count(self):
        self.fail()
        self.driver_fix()
        code, out, err = self.probe(target="trust-linux-tor")
        self.assertEqual(code, 0, out + err)
        self.assertIn(f"probe 1 of {AT} on linux", out)
        code, out, _ = self.rel("retry", self.android.id)
        self.assertEqual(code, 40)
        self.assertIn("The pass on linux (probe 1 on trust-linux-tor) does not count.", out)

    def test_a_probe_on_the_failing_driver_does_not_count(self):
        self.fail()
        self.assertEqual(self.probe()[0], 0)
        code, out, _ = self.rel("retry", self.android.id)
        self.assertEqual(code, 40)
        self.assertIn("is not newer than the failure", out)

    def test_a_probe_on_uncommitted_drivers_does_not_count(self):
        self.fail()
        pathlib.Path(self.repo, "tools/rellib/drivers/a.py").write_text("a = 3\n")
        self.assertEqual(self.probe()[0], 0)
        code, out, _ = self.rel("retry", self.android.id)
        self.assertEqual(code, 40)
        self.assertIn("uncommitted driver changes", out)

    def test_a_commit_that_leaves_the_drivers_alone_does_not_count(self):
        self.fail()
        pathlib.Path(self.repo, "other.txt").write_text("2\n")
        self.commit()
        self.assertEqual(self.probe()[0], 0)
        code, out, _ = self.rel("retry", self.android.id)
        self.assertEqual(code, 40)
        self.assertIn("changed nothing in the drivers", out)

    def test_a_probe_that_fails_opens_nothing(self):
        self.fail()
        self.driver_fix()
        code, out, _ = self.probe(passed=False)
        self.assertEqual(code, 20)
        self.assertIn("not a pass", out)
        self.assertEqual(self.rel("retry", self.android.id)[0], 40)

    def test_a_probe_after_the_pass_the_checkout_moved_off_does_not_count(self):
        self.fail()
        self.driver_fix()
        self.assertEqual(self.probe()[0], 0)
        pathlib.Path(self.repo, "tools/rellib/drivers/a.py").write_text("a = 4\n")
        code, out, _ = self.rel("retry", self.android.id)
        self.assertEqual(code, 40)
        self.assertIn("uncommitted driver changes, which probe 1", out)

    def test_a_good_probe_opens_the_retry(self):
        self.fail()
        self.driver_fix()
        code, out, err = self.probe()
        self.assertEqual(code, 0, out + err)
        self.assertIn("tools/rel retry trust-android-tor", out)
        self.lane("attempt", GOOD, 0)
        code, out, err = self.rel("retry", self.android.id)
        self.assertEqual(self.st()["status"], "done", out + err)
        self.assertIn("prior=harness", self.lanes_run()[-1])
        self.assertIn("fresh= ", self.lanes_run()[-1])
        self.assertEqual(self.st()["repeats"], 1)

    def test_a_later_commit_on_top_of_the_probe_still_counts(self):
        self.fail()
        self.driver_fix()
        self.assertEqual(self.probe()[0], 0)
        self.driver_fix("a = 5\n")  # another lane's fix
        self.lane("attempt", GOOD, 0)
        self.rel("retry", self.android.id)
        self.assertEqual(self.st()["status"], "done")

    def test_a_failure_from_before_the_records_is_not_gated(self):
        self.run_.set_status(self.android.id, status="failed", attempts=1, cause="harness", attempt_causes=["harness"])
        self.lane("attempt", GOOD, 0)
        code, out, err = self.rel("retry", self.android.id)
        self.assertEqual(self.st()["status"], "done", out + err)

    def test_other_bytes_are_a_new_test(self):
        self.run_.set_status("build-android-tor", outputs={"a.apk": {"sha256": "1"}})
        self.fail()
        self.assertTrue(repeats.verdict(self.eng, self.android, manual=True))
        self.run_.set_status("build-android-tor", outputs={"a.apk": {"sha256": "2"}})
        self.assertIsNone(repeats.verdict(self.eng, self.android, manual=True))
        self.lane("attempt", GOOD, 0)
        self.eng.execute(self.android)
        self.assertIn("fresh=" + repeats.NEW_BYTES, self.lanes_run()[-1])
        self.assertFalse(self.st().get("forced"))


class ProbeTest(Repeats):
    def test_a_step_that_never_failed_is_no_probe(self):
        self.fail()
        code, out, _ = self.probe(step="find-typo")
        self.assertEqual(code, 40)
        self.assertIn(f"Failed on trust-android-tor: {AT}", out)
        self.assertFalse([c for c in self.calls() if "probe=find" in c])

    def test_it_reaches_the_failing_step_in_a_folder_of_its_own(self):
        self.fail()
        before = pathlib.Path(self.run_.step_dir(self.android.id), "out", "proof.json").read_text()
        self.driver_fix()
        self.assertEqual(self.probe()[0], 0)
        call = [c for c in self.calls() if "probe=find" in c][0]
        self.assertIn(f"probe={AT}", call)
        self.assertIn("trust-android-tor/probe-1/out", call)
        st = self.st()
        self.assertEqual((st["attempts"], st["status"], len(st["probes"])), (1, "failed", 1))
        self.assertEqual(st["probes"][0]["driver"]["commit"], self.git("rev-parse", "HEAD"))
        self.assertEqual(pathlib.Path(self.run_.step_dir(self.android.id), "out", "proof.json").read_text(), before)
        event = self.events("probe")[-1]
        self.assertEqual((event["name"], event["platform"], event["passed"]), (AT, "android", True))

    def test_the_env_it_sets_goes_to_the_lane_alone(self):
        self.fail()
        env = repeats.probe_env(self.run_, self.android, self.st()["failures"][0], "/x")
        self.assertEqual((env["REL_TRUST_PROBE"], env["REL_PROBE_PHASE"], env["REL_OUT"], env["REL_STAGE"]),
                         (AT, "previous-setup", "/x", "/x"))
        self.assertEqual(env["REL_PROBE_FROM"], os.path.join(self.run_.step_dir(self.android.id), "out"))
        self.assertEqual(self.eng.command_line(self.android, env)[2]["REL_OUT"], "/x")

    def test_it_waits_for_its_lane(self):
        self.fail()
        self.run_.set_status(self.android.id, status="running")
        self.assertEqual(self.probe()[0], 75)

    def test_it_is_for_lanes(self):
        self.assertEqual(self.rel("probe", AT, "build-linux-tor")[0], 64)

    def test_a_run_lock_does_not_hold_it_off(self):
        self.fail()
        self.driver_fix()
        self.run_.lock()
        self.addCleanup(self.run_.unlock)
        self.assertEqual(self.probe()[0], 0)

    def test_a_failure_from_before_the_records_can_be_probed(self):
        self.lane("attempt", fault("harness"), 2)
        self.eng.execute(self.android)
        self.run_.set_status(self.android.id, failures=None)
        self.assertEqual(self.probe()[0], 0)


class SameFailureTest(Repeats):
    def twice(self):
        self.fail("product", rc=1)
        self.assertEqual(self.rel("retry", self.android.id)[0], 20)

    def test_the_second_stops_the_automatic_attempts_and_the_others_go_on(self):
        self.twice()
        code, out, err = self.rel("resume", "--keep-going")
        self.assertEqual(code, 20, out + err)
        self.assertEqual(len(self.lanes_run()), 2)
        self.assertEqual(self.st()["stopped"], f"stopped: trust-android-tor failed the same way twice at {AT} (product): no further "
                                               "automatic attempts, the other lanes carry on. To go again: only with a reason: "
                                               "tools/rel retry trust-android-tor --fresh \"<reason>\"")
        self.assertEqual(self.events("repeat-refused")[-1]["rule"], "same-failure")
        self.assertEqual(self.run_.status(self.linux.id)["status"], "done")

    def test_a_retry_after_it_needs_a_reason(self):
        self.twice()
        code, out, _ = self.rel("retry", self.android.id)
        self.assertEqual(code, 40)
        self.assertEqual(out.strip(), f"refused: trust-android-tor failed the same way twice at {AT} (product). Only with a reason: "
                                      "tools/rel retry trust-android-tor --fresh \"<reason>\"")
        self.assertEqual(len(self.lanes_run()), 2)

    def test_a_reason_goes_to_the_journal_and_counts(self):
        self.twice()
        self.lane("attempt", GOOD, 0)
        self.rel("retry", self.android.id, "--fresh", "the node was replaced")
        self.assertIn("fresh=the node was replaced", self.lanes_run()[-1])
        self.assertEqual(self.events("fresh-forced")[-1]["reason"], "the node was replaced")
        st = self.st()
        self.assertEqual([(f["attempt"], f["reason"]) for f in st["forced"]], [(3, "the node was replaced")])
        self.assertIsNone(st.get("fresh"))
        row = [r for r in self.run_.summary_rows() if r["id"] == self.android.id][0]
        self.assertEqual((row["repeats"], row["repeats_forced"]), (2, 1))

    def test_one_failure_is_not_the_same_failure(self):
        self.fail("product", rc=1)
        self.assertIsNone(repeats.verdict(self.eng, self.android))
        self.assertIsNone(repeats.verdict(self.eng, self.android, manual=True))

    def test_another_step_is_another_failure(self):
        self.fail("product", rc=1)
        self.fail("product", rc=1, step="other")
        self.assertIsNone(repeats.verdict(self.eng, self.android))

    def test_an_infra_failure_gets_its_retry_and_then_stops(self):
        self.lane("attempt", None, 0)  # exit 0 and no proof: the machine
        st = self.eng.execute(self.android)
        self.assertEqual((st["attempts"], st["cause"]), (2, "infra:no-proof"))
        self.assertEqual(len(st["failures"]), 2)
        self.assertEqual(repeats.verdict(self.eng, self.android)["rule"], "same-failure")
        self.assertIn("To go again: tools/rel retry trust-android-tor", repeats.verdict(self.eng, self.android)["line"])

    def test_an_infra_failure_retries_by_hand_with_no_reason(self):
        self.lane("attempt", None, 0)
        self.eng.execute(self.android)
        self.assertIsNone(repeats.verdict(self.eng, self.android, manual=True))

    def test_a_cause_tells_the_kinds_apart(self):
        self.assertEqual(repeats.kind_of("infra:driver-rig"), "infra")
        self.assertEqual(repeats.kind_of("harness:crash"), "harness")
        self.assertEqual(repeats.kind_of("product"), "product")
        self.assertEqual(repeats.kind_of("step", {"kind": "harness"}), "harness")
        self.assertEqual(repeats.kind_of("timeout"), "other")
        self.assertEqual(window.proof_cause({"proof": {"fault": {"kind": "refused"}}}, ""), "check: refused")

    def test_a_harness_failure_naming_no_step_has_nothing_to_probe(self):
        self.lane("attempt", {"checks": {}}, 2)
        st = self.eng.execute(self.android)
        self.assertEqual(st["failures"][0]["kind"], "harness")
        self.assertIsNone(repeats.verdict(self.eng, self.android, manual=True))


class WayRoundTest(Repeats):
    def test_a_callers_environment_never_reaches_the_lane(self):
        self.lane("attempt", GOOD, 0)
        with mock.patch.dict(os.environ, {"REL_TRUST_RESUME": "0", "REL_TRUST_FRESH": "from the shell", "REL_TRUST_PROBE": "x"}):
            self.eng.execute(self.android)
        self.assertIn("probe= fresh= resume= prior=", self.lanes_run()[-1])

    def test_debug_exec_does_not_run_a_failed_lane(self):
        self.fail()
        code, out, _ = self.rel("debug", self.android.id, "--exec")
        self.assertEqual(code, 40)
        self.assertIn("tools/rel probe <step> trust-android-tor", out)
        self.assertEqual(len(self.lanes_run()), 1)

    def test_fresh_wants_a_reason_and_a_lane(self):
        self.fail()
        self.assertEqual(self.rel("retry", self.android.id, "--fresh", " ")[0], 64)
        self.run_.set_status("build-linux-tor", status="failed")
        self.assertEqual(self.rel("retry", "build-linux-tor", "--fresh", "x")[0], 64)

    def test_a_refused_start_is_no_failure_of_the_lane(self):
        self.fail("product", rc=1)
        self.lane("attempt", {"fault": {"kind": "refused", "step": "start", "what": "x"}, "refused": True, "checks": {}}, 2)
        st = self.eng.execute(self.android)
        self.assertEqual(st["cause"], "check: refused")
        self.assertEqual(len(st["failures"]), 1)
        self.assertFalse(st.get("repeats"))


class CountTest(Repeats):
    def test_the_journal_status_and_metrics_count_a_repeat(self):
        self.fail("product", rc=1)
        first = self.st()["duration_s"]
        self.fail("product", rc=1)
        st = self.st()
        self.assertEqual(st["repeats"], 1)
        self.assertEqual(st["seconds_repeated"], st["duration_s"])
        self.assertEqual(len(st["attempt_seconds"]), 2)
        self.assertEqual(st["attempt_seconds"][0], first)
        end = self.events("end")[-1]
        self.assertEqual((end["attempts"], end["repeats"], end["seconds_repeated"], end["failed_at"]),
                         (2, 1, st["seconds_repeated"], AT))
        lines = [json.loads(x) for x in pathlib.Path(self.root, "metrics.jsonl").read_text().splitlines()
                 if self.android.id in x]
        self.assertIsNone(lines[0].get("repeated_s"))
        self.assertEqual(lines[1]["repeated_s"], st["duration_s"])

    def test_status_and_the_report_show_them(self):
        self.fail("product", rc=1)
        self.fail("product", rc=1)
        self.assertRegex(self.rel("status")[1], r"repeat 1, \d+ s repeated")
        md, _ = report(self.run_)
        self.assertRegex(pathlib.Path(md).read_text(), r"repeat 1, \d+ s repeated")
