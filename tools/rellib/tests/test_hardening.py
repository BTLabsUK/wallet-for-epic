# SPDX-License-Identifier: Apache-2.0
"""The release runner's hardening for the next candidate (audit 2026-11-01, Phase A): the heavy
cap and steps kept apart, the release-window marker, infrastructure-only retries, Android signing
on demand, G2 from a green full check of the same content, and evidence tied to the artefacts."""
import io
import json
import os
import subprocess
import time
import tomllib
from contextlib import redirect_stderr, redirect_stdout

from support import FAKE_PIPELINE, REPO, Base
from rellib import evidence, green, reuse, signer, window
from rellib.cli import main, version_at
from rellib.config import ConfigError, Pipeline
from rellib.engine import EXIT_WAITING, Engine
from rellib.graph import Step

V = version_at(REPO, "HEAD")
HEAD = subprocess.run(["git", "-C", REPO, "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()


def jload(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def jdump(obj, path):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f)


def wtext(path, text):
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


def rtext(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def rel(*args):
    out, err = io.StringIO(), io.StringIO()
    with redirect_stdout(out), redirect_stderr(err):
        code = main(list(args))
    return code, out.getvalue(), err.getvalue()


# Four lanes of fake work; names the default [concurrency] rules know.
LANES = """
[defaults]
heavy_wrap = []
min_free_gb = 0

[relmsg]
bin = "relmsg"

[step.scope]
kind = "builtin"
host = "local"
%s
"""


def lane(name, heavy=True, extra=""):
    return f"""
[step.{name}]
needs = ["scope"]
lane = "{name}"
heavy = {str(heavy).lower()}
run = "echo $REL_RUN_ID $BUILD_SLOT_PRIORITY > {{src}}/env-{name}; cat \\"$REL_WINDOW_MARKER\\" > {{src}}/window-{name} 2>/dev/null || true; sleep 0.7"
{extra}
"""


def spans(run):
    """{step: (start t, end t)} from events.jsonl."""
    out = {}
    for e in run.events():
        if e["event"] == "start":
            out.setdefault(e["step"], [e["t"], None])[0] = e["t"]
        elif e["event"] == "end":
            out.setdefault(e["step"], [None, None])[1] = e["t"]
    return {k: tuple(v) for k, v in out.items()}


def overlap(a, b):
    return a[0] < b[1] and b[0] < a[1]


class ConcurrencyTest(Base):
    def lanes_run(self, names, conc=""):
        self.pipeline = Pipeline(tomllib.loads(LANES % ("".join(lane(n) for n in names) + conc)))
        run = self.make_run(only="linux", sets=["publish.manifests=false"])
        return run, self.engine(run, relmsg=False)

    def test_heavy_cap_holds_and_lanes_still_run_side_by_side(self):
        run, eng = self.lanes_run(["a1", "a2", "a3", "a4"])
        eng.drive([s.id for s in run.steps])
        sp = spans(run)
        ids = ["a1", "a2", "a3", "a4"]
        for t in [x for s in ids for x in sp[s]]:
            self.assertLessEqual(sum(1 for s in ids if sp[s][0] <= t < sp[s][1]), 2, sp)
        self.assertTrue(any(overlap(sp[a], sp[b]) for a in ids for b in ids if a < b), "never side by side")
        self.assertTrue(any(e["event"] == "deferred" and "cap (2)" in e.get("reason", "") for e in run.events()))
        line = [json.loads(x) for x in rtext(os.path.join(self.root, "metrics.jsonl")).splitlines() if '"step": "a4"' in x][0]
        self.assertEqual(line["max_heavy"], 2)
        self.assertGreater(line.get("waited_s", 0), 0)

    def test_android_and_windows_trust_side_by_side_but_never_beside_the_suite(self):
        names = ["source-check", "trust-android", "trust-windows", "trust-linux"]
        run, eng = self.lanes_run(names, '\n[concurrency]\nmax_heavy = 4\n')
        eng.drive([s.id for s in run.steps])
        sp = spans(run)
        self.assertTrue(overlap(sp["trust-android"], sp["trust-windows"]), sp)
        self.assertFalse(overlap(sp["source-check"], sp["trust-android"]))
        self.assertFalse(overlap(sp["source-check"], sp["trust-windows"]))
        self.assertTrue(overlap(sp["source-check"], sp["trust-linux"]))
        # --exclusive-machine: the same; never beside the suite.
        run, eng = self.lanes_run(names, '\n[concurrency]\nmax_heavy = 4\n')
        run.info["concurrency"] = {"shared": False}
        eng = Engine(run, self.pipeline, self.hosts, REPO)
        eng.drive([s.id for s in run.steps])
        sp = spans(run)
        self.assertTrue(overlap(sp["trust-android"], sp["trust-windows"]), sp)
        self.assertFalse(overlap(sp["source-check"], sp["trust-android"]))

    def test_a_full_suite_outside_the_run_holds_android_and_windows_trust(self):
        run, eng = self.lanes_run(["trust-android"], '\n[concurrency]\npoll = "0.2s"\n')
        answers = ["slot 1: agent-x since 10:00:00: tools/check.sh --full"] * 3 + ["slot 1: free"]
        eng.heavy_status = lambda: answers.pop(0) if len(answers) > 1 else answers[0]
        self.assertEqual(eng.drive([s.id for s in run.steps]), 0)
        ev = [e for e in run.events() if e["step"] == "trust-android" and e["event"] == "deferred"]
        self.assertIn("full test suite runs outside this run", ev[0]["reason"])
        self.assertEqual(run.status("trust-android")["status"], "done")
        # After external_wait it starts anyway and says so.
        run, eng = self.lanes_run(["trust-android"], '\n[concurrency]\npoll = "0.1s"\nexternal_wait = "0.3s"\n')
        eng.heavy_status = lambda: "slot 2: agent-y since 10:00:00: tools/flutter-test-all.sh"
        self.assertEqual(eng.drive([s.id for s in run.steps]), 0)
        self.assertTrue(any(e["event"] == "external-suite" for e in run.events()))

    def test_a_remote_lane_takes_no_heavy_slot_and_runs_beside_android(self):
        """Windows trust runs its app on a rig: with both slots held by local lanes it still starts,
        and beside Android too."""
        from types import SimpleNamespace as NS
        pol = window.Policy()
        lin = [NS(base="trust-linux", id="trust-linux-%s" % v, heavy=False, proof=True) for v in ("tor", "notor")]
        win = NS(base="trust-windows", id="trust-windows-tor", heavy=False, proof=True, remote=True)
        self.assertIsNone(pol.why_not(win, lin))
        self.assertIn("cap (2)", pol.why_not(NS(base="trust-android", id="trust-android-tor", heavy=False, proof=True), lin))
        self.assertIsNone(pol.why_not(win, [NS(base="trust-android", id="trust-android-tor", heavy=False, proof=True)]))
        kept = window.Policy({"apart_shared": [["trust-android", "trust-windows"]]})
        self.assertIn("kept apart", kept.why_not(win, [NS(base="trust-android", id="trust-android-tor", heavy=False, proof=True)]))
        self.assertIsNone(pol.why_not(lin[0], [lin[1], win]), "a running remote lane holds no slot")

    def test_concurrency_config_is_checked(self):
        for bad in ('max_heavy = 0', 'infra_retries = 9', 'apart = [["trust-android"]]', 'apart = [["nope", "scope"]]'):
            with self.subTest(bad=bad), self.assertRaises(ConfigError):
                Pipeline(tomllib.loads(LANES % lane("a1") + f"\n[concurrency]\n{bad}\n"))
        with self.assertRaises(ConfigError):
            Pipeline(tomllib.loads(LANES % lane("a1") + '\n[sign]\nwhen = "sometimes"\n'))
        real = Pipeline.load(os.path.join(REPO, "release/pipeline.toml"))
        self.assertEqual(real.concurrency["max_heavy"], 2)
        self.assertEqual(real.sign["when"], "on-demand")


class WindowTest(Base):
    def test_marker_while_a_run_drives_and_heavy_steps_ask_for_priority(self):
        self.pipeline = Pipeline(tomllib.loads(LANES % lane("a1")))
        run = self.make_run(only="linux", sets=["publish.manifests=false"])
        marker = os.environ["REL_WINDOW_MARKER"]
        self.engine(run, relmsg=False).drive([s.id for s in run.steps])
        seen = jload(os.path.join(self.src, "window-a1"))
        self.assertEqual((seen["kind"], seen["run_id"], seen["pid"]), ("wfe-release-window", run.info["run_id"], os.getpid()))
        self.assertIn("a1", seen["running"])
        self.assertEqual(seen["heavy_running"], 1)
        self.assertEqual(rtext(os.path.join(self.src, "env-a1")).split(), [run.info["run_id"], "release"])
        self.assertFalse(os.path.exists(marker), "removed when the drive ends")

    def test_a_live_window_of_another_run_is_kept_and_a_stale_one_replaced(self):
        path = os.path.join(self.tmp, "w")
        pol = window.Policy()
        info = {"run_id": "26.11.0-run1", "version": "26.11.0"}
        other = {"kind": "wfe-release-window", "pid": 1, "heartbeat_t": time.time(), "stale_after_s": 180}
        jdump(other, path)
        w = window.Window(path, info, pol, lambda: [])
        self.assertFalse(w.beat())
        self.assertEqual(jload(path)["pid"], 1)
        w.close()
        self.assertTrue(os.path.exists(path), "never removes another run's window")
        jdump(dict(other, heartbeat_t=time.time() - 3600), path)
        self.assertIsNone(window.read_marker(path))
        self.assertTrue(w.beat())
        self.assertEqual(window.read_marker(path)["pid"], os.getpid())
        p = subprocess.Popen(["true"])
        p.wait()
        jdump(dict(other, pid=p.pid), path)
        self.assertIsNone(window.read_marker(path), "a dead pid is no window")
        self.assertTrue(w.beat())
        w.close()
        self.assertFalse(os.path.exists(path))


class InfraRetryTest(Base):
    def driver(self, script):
        with open(os.path.join(self.src, "driver.sh"), "w") as f:
            f.write(script)

    def trust(self):
        run = self.make_run(only="android", sets=["publish.manifests=false"])
        eng = self.engine(run)
        eng.drive(self.build_ids(run))
        return run, run.status("trust-android-tor")

    def metric_lines(self, step):
        return [json.loads(x) for x in rtext(os.path.join(self.root, "metrics.jsonl")).splitlines() if f'"step": "{step}"' in x]

    def test_a_driver_killed_by_the_machine_runs_once_more(self):
        self.driver('n=$(cat "$REL_SRC/n" 2>/dev/null || echo 0); echo $((n+1)) > "$REL_SRC/n"\n'
                    'if [ "$n" = 0 ]; then kill -TERM $$; fi\n'
                    'printf \'{"checks":{"wallet_opens":true,"history_kept":true,"send_ok":true}}\' > "$REL_OUT/proof.json"\n')
        run, st = self.trust()
        self.assertEqual((st["status"], st["attempts"]), ("done", 2), st)
        lines = self.metric_lines("trust-android-tor")
        self.assertEqual([(l["status"], l.get("cause"), l.get("infra_try")) for l in lines],
                         [("failed", "infra:sigterm", None), ("done", None, 1)])
        self.assertNotIn("alert trust-android-tor failed", self.relmsg_calls())
        self.assertTrue(any(e["event"] == "retry" and e.get("automatic") for e in run.events()))

    def test_a_missing_proof_retries_once_then_fails_with_its_cause(self):
        self.driver('echo run >> "$REL_SRC/n"; exit 0\n')
        run, st = self.trust()
        self.assertEqual((st["status"], st["attempts"], st["cause"]), ("failed", 2, "infra:no-proof"))
        self.assertEqual(rtext(os.path.join(self.src, "n")).count("run"), 2)
        self.assertEqual(self.relmsg_calls().count("alert trust-android-tor failed"), 1)

    def test_a_product_failure_never_retries(self):
        with open(os.path.join(self.src, "proof-mode"), "w") as f:
            f.write("bad")
        run, st = self.trust()
        self.assertEqual((st["status"], st["attempts"], st["cause"]), ("failed", 1, "product"))

    def test_a_stale_proof_never_counts_for_a_new_attempt(self):
        with open(os.path.join(self.src, "proof-mode"), "w") as f:
            f.write("good")
        run, st = self.trust()
        self.assertEqual(st["status"], "done")
        self.driver("exit 0\n")
        s = run.step("trust-android-tor")
        st = self.engine(run).execute(s)
        self.assertEqual((st["status"], st["cause"]), ("failed", "infra:no-proof"))
        out = os.listdir(os.path.join(run.step_dir(s.id), "out"))
        self.assertNotIn("proof.json", out)
        self.assertTrue(any(n.startswith("proof.before-") for n in out))

    def test_its_own_timeout_is_not_retried(self):
        run = self.make_run(only="android", sets=["publish.manifests=false"])
        eng = self.engine(run, relmsg=False)
        s = run.step("build-android-tor")
        s.run, s.timeout = "sleep 20", 1
        st = eng.execute(s)
        self.assertEqual((st["status"], st["attempts"], st["cause"]), ("failed", 1, "timeout"))

    def test_a_publish_step_never_retries_by_itself(self):
        run = self.make_run(only="android", sets=["publish.manifests=false"])
        eng = self.engine(run, relmsg=False)
        s = run.step("publish-downloads")
        s.run = "kill -TERM $$"
        st = eng.execute(s)
        self.assertEqual((st["status"], st["attempts"], st["cause"]), ("failed", 1, "infra:sigterm"))

    def test_causes(self):
        log = os.path.join(self.tmp, "log")
        cmd = Step(id="b", base="b", kind="command", title="b", host="build", lane="b", platforms=[])
        heavy = Step(id="h", base="h", kind="command", title="h", host="build", lane="h", platforms=[], heavy=True)
        proof = Step(id="p", base="p", kind="command", title="p", host="build", lane="p", platforms=[], proof=True)
        wtext(log, "building\nerror: tests failed\n")
        self.assertEqual(window.cause_of(cmd, {"rc": 1}, log), "step")
        self.assertEqual(window.cause_of(cmd, {"rc": 137}, log), "infra:sigkill")
        self.assertEqual(window.cause_of(cmd, {"rc": 255}, log), "infra:ssh")
        self.assertEqual(window.cause_of(heavy, {"rc": 75}, log), "infra:no-slot")
        self.assertEqual(window.cause_of(cmd, {"rc": 75}, log), "step")
        self.assertEqual(window.cause_of(proof, {"rc": 2, "proof_missing": True}, log), "infra:no-proof")
        self.assertEqual(window.cause_of(cmd, {"rc": None, "timed_out": True}, log), "timeout")
        wtext(log, rtext(log) + "client_loop: send disconnect: Broken pipe\n")
        self.assertEqual(window.cause_of(cmd, {"rc": 1}, log), "infra:ssh")


class SignOnDemandTest(Base):
    def setUp(self):
        super().setUp()
        from test_signer import CERT, FakeClient, tail
        self.fake = FakeClient()
        self.saved = signer.client, signer.cert_of
        signer.client = lambda engine, say: self.fake
        signer.cert_of = lambda path, tools: CERT if tail(path) else None
        self.hosts["host"]["signer"] = {"endpoint": "http://100.64.0.9:8797"}

    def tearDown(self):
        signer.client, signer.cert_of = self.saved
        super().tearDown()

    def write_pipeline(self):
        text = FAKE_PIPELINE.replace('needs = ["build-android", "build-linux"]\nproof = true\n\n[step.trust-linux]',
                                     'needs = ["build-android", "build-linux", "sign-android"]\nproof = true\n\n'
                                     '[step.trust-linux]')
        text += ('\n[step.sign-android]\nkind = "builtin"\nhost = "local"\nplatform = "android"\nlane = "sign"\n'
                 'needs = ["build-android", "build-linux"]\n\n[sign]\nwhen = "on-demand"\n')
        path = os.path.join(self.tmp, "pipeline.toml")
        wtext(path, text)
        hosts = os.path.join(self.tmp, "hosts.toml")
        wtext(hosts, '[host.signer]\nendpoint = "http://100.64.0.9:8797"\n')
        self.pipeline = Pipeline.load(path)
        return path, hosts

    def test_the_run_goes_on_without_the_code_and_tools_rel_sign_asks_for_it(self):
        path, hosts = self.write_pipeline()
        run = self.make_run(only="android,linux", sets=["publish.manifests=false"])
        eng = self.engine(run)
        self.assertEqual(eng.drive(self.build_ids(run)), EXIT_WAITING)
        st = run.status("sign-android")
        self.assertEqual(st["status"], "waiting")
        self.assertIn("tools/rel sign --run", st["note"])
        self.assertEqual(self.fake.requests, [], "no request, so no code is asked yet")
        self.assertEqual(run.status("trust-linux-tor")["status"], "done", "the other lanes went on")
        self.assertEqual(run.status("trust-android-tor")["status"], "pending")
        self.assertEqual(self.relmsg_calls().count("Android files of"), 1)
        # A resume asks nobody again.
        Engine(run, self.pipeline, self.hosts, REPO, relmsg=eng.relmsg).drive(self.build_ids(run))
        self.assertEqual(self.relmsg_calls().count("Android files of"), 1)
        code, out, err = rel("--state-root", self.root, "--pipeline", path, "--hosts", hosts, "sign", "--run", run.path)
        self.assertEqual(code, EXIT_WAITING, out + err)  # on to the publish gate
        self.assertEqual(len(self.fake.requests), 1)
        self.assertEqual(run.status("sign-android")["status"], "done")
        self.assertEqual(run.status("trust-android-tor")["status"], "done")
        self.assertTrue(jload(os.path.join(run.path, "run.json"))["sign_requested"])

    def test_inline_asks_at_once(self):
        self.write_pipeline()
        run = self.make_run(only="android,linux", sets=["publish.manifests=false"])
        run.info["sign_requested"] = "at start (--sign-inline)"
        run.save_info()
        self.engine(run).drive(self.build_ids(run))
        self.assertEqual(run.status("sign-android")["status"], "done")
        self.assertEqual(len(self.fake.requests), 1)


G2_PIPELINE = FAKE_PIPELINE.replace("[step.build-android]", """[step.source-check]
needs = ["scope"]
run = "echo g2 >> {src}/calls"
reuse = ["tools/lepic.rev", "tools/check.sh"]
reuse_green = true

[step.build-android]""")


class GreenTest(Base):
    def record(self, sha=HEAD, **kw):
        d = os.environ["WFE_GREEN_DIR"]
        os.makedirs(d, exist_ok=True)
        rec = {"sha": sha, "status": "green", "clean": True, "command": "tools/check.sh --full",
               "ended": "2026-11-02T03:00:00Z", "by": "test"}
        rec.update(kw)
        jdump(rec, os.path.join(d, f"{sha}.json"))

    def test_check_full_records_only_a_clean_commit(self):
        repo = os.path.join(self.tmp, "repo")
        os.makedirs(repo)
        for c in (["init", "-q"], ["-c", "user.email=t@t", "-c", "user.name=t", "commit", "-q", "--allow-empty", "-m", "x"]):
            subprocess.run(["git", "-C", repo, *c], check=True)
        sha = subprocess.run(["git", "-C", repo, "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()
        path, msg = green.record(repo, time.time() - 900)
        r = jload(path)
        self.assertEqual((r["sha"], r["status"], r["clean"], r["command"]), (sha, "green", True, "tools/check.sh --full"))
        self.assertGreaterEqual(r["duration_s"], 899)
        os.remove(path)
        wtext(os.path.join(repo, "stray"), "")
        path, msg = green.record(repo, 0)
        self.assertIsNone(path)
        self.assertIn("has changes", msg)
        self.assertEqual(os.listdir(os.environ["WFE_GREEN_DIR"]), [])

    def g2_step(self):
        self.pipeline = Pipeline(tomllib.loads(G2_PIPELINE))
        return Step(id="source-check", base="source-check", kind="command", title="g2", host="build",
                    lane="heavy", platforms=[])

    def test_g2_takes_a_green_record_of_the_same_content_from_any_source(self):
        step = self.g2_step()
        spec = self.pipeline.steps["source-check"]
        info = {"commit": HEAD, "version": V}
        k, _, src = reuse.find_source(REPO, self.root, info, step, spec["reuse"], None, reuse.green_dir(spec))
        self.assertIsNone(src)
        self.record(clean=False)
        self.assertIsNone(reuse.find_source(REPO, self.root, info, step, spec["reuse"], None, reuse.green_dir(spec))[2])
        self.record(command="tools/check.sh")
        self.assertIsNone(reuse.find_source(REPO, self.root, info, step, spec["reuse"], None, reuse.green_dir(spec))[2])
        self.record()
        k2, _, src = reuse.find_source(REPO, self.root, info, step, spec["reuse"], None, reuse.green_dir(spec))
        self.assertEqual((k2, src["kind"], src["commit"]), (k, "green", HEAD))
        self.assertIn("tools/check.sh --full", src["label"])

    def start(self, *extra):
        path = os.path.join(self.tmp, "pipeline.toml")
        wtext(path, G2_PIPELINE)
        prev = os.path.join(self.tmp, "26.1.0")
        os.makedirs(prev, exist_ok=True)
        return rel("--state-root", self.root, "--pipeline", path, "--hosts", os.path.join(self.tmp, "none.toml"),
                   "start", V, "--test", "--only", "linux", "--set", "publish.manifests=false", "--no-relmsg", "--src", self.src,
                   "--previous", prev,
                   *extra)

    def test_start_refuses_a_candidate_without_a_green_full_check(self):
        code, out, err = self.start()
        self.assertEqual(code, 30, out + err)
        self.assertIn("no green full check", out)
        self.assertIn("--run-source-check", out)
        self.assertFalse(os.path.isdir(os.path.join(self.root, V)), "no run made")
        code, out, err = self.start("--run-source-check")
        self.assertNotEqual(code, 30, out + err)
        self.assertIn("g2", self.calls(), "G2 ran in the run")

    def test_start_takes_a_green_record_and_g2_is_not_run(self):
        self.record()
        code, out, err = self.start()
        self.assertNotEqual(code, 30, out + err)
        self.assertIn("G2: green full check on this content", out)
        self.assertNotIn("g2", self.calls())
        run = [d for d in os.listdir(os.path.join(self.root, V))]
        st = jload(os.path.join(self.root, V, run[0], "steps", "source-check", "status.json"))
        self.assertEqual(st["reused_from"]["kind"], "green")


class EvidenceTest(Base):
    def built(self):
        with open(os.path.join(self.src, "proof-mode"), "w") as f:
            f.write("good")
        run = self.make_run(only="android,linux", sets=["publish.manifests=false"])
        eng = self.engine(run)
        eng.drive(self.build_ids(run))
        return run, eng

    def test_rc_manifest_proofs_and_publish_are_tied_to_the_bytes(self):
        run, eng = self.built()
        self.assertTrue(run.status("trust-android-tor")["tested"])
        h, missing = evidence.write_manifest(eng)
        self.assertEqual(missing, [])
        m = evidence.read_manifest(run)
        self.assertEqual(m["hash"], h)
        self.assertIn("emulator/x.apk", m["files"])
        self.assertEqual(evidence.stale_proofs(eng, m), [])
        d = evidence.keep(eng, m, {"android": {"state": "proven"}})
        self.assertTrue(os.path.isfile(os.path.join(d, "proofs", "trust-android-tor.json")))
        self.assertEqual(os.path.basename(d), h)
        run.info["gates"] = {"publish": {"gate_id": 3, "rc_manifest": h}}
        run.save_info()
        self.assertIsNone(evidence.publish_refusal(run))
        # The bytes change (a rebuild, or anything else): the proof is about other bytes, the
        # approval too, and nothing is published.
        apk = os.path.join(run.files, "bt-wallet-26.10.25-android-arm64-v8a.apk")
        with open(apk, "ab") as f:
            f.write(b"x")
        self.assertIn("no longer match", evidence.publish_refusal(run))
        evidence.write_manifest(eng)
        self.assertIn("approved rc-manifest", evidence.publish_refusal(run))
        self.assertEqual([sid for sid, _ in evidence.stale_proofs(eng, evidence.read_manifest(run))], ["trust-android-tor"])

    def test_a_build_that_ran_again_resets_what_depended_on_its_bytes(self):
        run, eng = self.built()
        before = run.status("trust-linux-tor")
        self.assertTrue(before["inputs_digest"])
        self.assertIsNone(run.status("build-android-tor").get("inputs_digest"))
        # build-android-tor ran again and made other bytes.
        st = run.status("build-android-tor")
        outs = st["outputs"]
        outs["bt-wallet-26.10.25-android-arm64-v8a.apk"]["sha256"] = "0" * 64
        run.set_status("build-android-tor", outputs=outs)
        path = os.path.join(self.tmp, "pipeline.toml")
        wtext(path, FAKE_PIPELINE)
        code, out, err = rel("--state-root", self.root, "--pipeline", path, "--hosts", os.path.join(self.tmp, "none.toml"),
                             "resume", "--run", run.path)
        self.assertEqual(code, EXIT_WAITING, out + err)
        inval = {e["step"] for e in run.events() if e["event"] == "invalidated"}
        self.assertEqual(inval, {"trust-android-tor", "trust-linux-tor", "update-trust"})
        self.assertEqual(run.status("trust-linux-tor")["attempts"], 2)
        self.assertEqual(run.status("build-linux-tor")["attempts"], 1, "a build is never reset by this")


if __name__ == "__main__":
    import unittest
    unittest.main()
