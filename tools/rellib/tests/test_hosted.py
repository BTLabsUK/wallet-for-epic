# SPDX-License-Identifier: Apache-2.0
"""Hosted builds (tools/rellib/hosted.py): the dispatch, build-fetch's checks and the graph of
`--builds hosted` / `--builds local`, against a fake gh on PATH that answers from a JSON file."""
import pathlib
import datetime as dt
import hashlib
import json
import shutil
import os
import stat
import tomllib

from support import REPO, Base
from rellib import hosted
from rellib.config import Pipeline, load_scope, scope_toml
from rellib.engine import Engine
from rellib.graph import build_graph
from rellib.relmsg import Relmsg
from rellib.run import Run
from test_scope_graph import PIPE, ctx as real_ctx

PUB = "b" * 40
LOCAL = "c" * 40

PIPELINE = """
[defaults]
heavy_wrap = []
min_free_gb = 0

[relmsg]
bin = "relmsg"

[hosted]
gh_config = "{tmp}/gh"
commit_map = "{tmp}/commit-map"
state = "{tmp}/dispatches.jsonl"
backup_dir = "{tmp}/backup"
ramp_until = ""
poll = "0.05s"
find_wait = "2s"
{waves}

[hosted.deadline]
android = "{deadline}"
linux = "{deadline}"

[step.hosted-dispatch]
kind = "builtin"
host = "local"
when = ["builds.hosted"]

[step.build-android]
platform = "android"
for_each = "variant"
hosted = "android"
needs = ["hosted-dispatch"]
run = "echo local build >> {{src}}/calls; exit 3"
env = {{ WFE_TOR = "{{tor}}", WFE_BUILD_ID = "{{build_id}}" }}
outputs = ["bt-wallet-{{version}}{{notor}}-android-arm64-v8a.apk"]
extras = ["emulator/bt-wallet-{{version}}{{notor}}-android-x86_64.apk"]
timeout = "5m"

[step.build-linux]
platform = "linux"
for_each = "variant"
hosted = "linux"
needs = ["hosted-dispatch"]
run = "echo local build >> {{src}}/calls; exit 3"
env = {{ WFE_TOR = "{{tor}}", WFE_BUILD_ID = "{{build_id}}" }}
outputs = ["bt-wallet-{{version}}{{notor}}-linux-x86_64.AppImage"]
timeout = "5m"
"""

# Answers from $FAKE_GH/state.json; every call goes to $FAKE_GH/calls.jsonl.
FAKE_GH = r'''#!/usr/bin/env python3
import json, os, pathlib, shutil, sys
d = os.environ["FAKE_GH"]
st = json.loads(pathlib.Path(os.path.join(d, "state.json")).read_text())
a = sys.argv[1:]
with open(os.path.join(d, "calls.jsonl"), "a") as f:
    f.write(json.dumps({"args": a, "config": os.environ.get("GH_CONFIG_DIR")}) + "\n")
def out(x):
    print(json.dumps(x)); sys.exit(0)
def save():
    pathlib.Path(os.path.join(d, "state.json")).write_text(json.dumps(st))
if a[:2] == ["api", "user"]:
    out({"login": st.get("login", "btlabs-uk")})
if a[:2] == ["workflow", "run"]:
    req = next(x.split("=", 1)[1] for x in a if x.startswith("request="))
    kind = next(x.split("=", 1)[1] for x in a if x.startswith("kind="))
    st["title"] = f"build {kind} {req}"; save(); sys.exit(0)
if a[:2] == ["run", "list"]:
    out([{"databaseId": 101, "displayTitle": st.get("title", ""), "headSha": st["head_sha"],
          "url": "https://github.com/R/actions/runs/101"}])
if a[:2] == ["run", "cancel"]:
    sys.exit(0)
if a[:2] == ["run", "download"]:
    name, dest = a[a.index("-n") + 1], a[a.index("-D") + 1]
    shutil.copytree(os.path.join(d, "art", name), dest, dirs_exist_ok=True); sys.exit(0)
if a[:1] == ["attestation"] and st.get("old_gh"):
    print('unknown command "attestation" for "gh"', file=sys.stderr); sys.exit(1)
if a[:2] == ["attestation", "verify"]:
    out([{"verificationResult": {"signature": {"certificate": {"sourceRepositoryDigest": st["attested"]}},
          "statement": {"predicate": {"buildDefinition": {"resolvedDependencies": [{"digest": {"gitCommit": st["attested"]}}]}}}}}])
if a[0] == "api" and a[1] == "-X":
    sys.exit(0)
if a[0] == "api" and a[1].endswith("/jobs?per_page=100"):
    out({"jobs": st["jobs"]})
if a[0] == "api" and "/artifacts?" in a[1]:
    out({"artifacts": [{"id": i + 1, "name": n} for i, n in enumerate(sorted(os.listdir(os.path.join(d, "art"))))]})
if a[0] == "api" and a[1].startswith("repos/") and "/actions/runs/" in a[1]:
    out({"head_sha": st["head_sha"], "path": st.get("path", ".github/workflows/build.yml@refs/heads/main"),
         "status": st.get("run_status", "in_progress")})
print("fake gh: no answer for", a, file=sys.stderr); sys.exit(1)
'''

OK_SCRIPT = "#!/usr/bin/env bash\necho \"verify $1 tor=$WFE_TOR id=$WFE_BUILD_ID unsigned=${WFE_UNSIGNED:-}\" >> \"$(dirname \"$0\")/verify.calls\"\n"


def text(path):
    with open(path) as f:
        return f.read()


def job(platform, variant, status="completed", conclusion="success"):
    return {"name": f"{platform} ({variant})", "status": status, "conclusion": conclusion,
            "html_url": f"https://github.com/R/actions/runs/101/job/{platform}-{variant}"}


class HostedTest(Base):
    def setUp(self):
        super().setUp()
        self.gh = os.path.join(self.tmp, "fakegh")
        os.makedirs(os.path.join(self.gh, "bin"))
        exe = os.path.join(self.gh, "bin", "gh")
        with open(exe, "w") as f:
            f.write(FAKE_GH)
        os.chmod(exe, os.stat(exe).st_mode | stat.S_IEXEC)
        self.old_path = os.environ["PATH"]
        os.environ["PATH"] = os.path.join(self.gh, "bin") + os.pathsep + self.old_path
        os.environ["FAKE_GH"] = self.gh
        with open(os.path.join(self.tmp, "commit-map"), "w") as f:
            f.write(f"old new\n{LOCAL} {PUB}\n")
        for rel in ("app/tool/verify_android_release.sh", "scripts/verify-linux.sh"):
            p = os.path.join(self.src, rel)
            os.makedirs(os.path.dirname(p), exist_ok=True)
            with open(p, "w") as f:
                f.write(OK_SCRIPT)
        self.state({"head_sha": PUB, "attested": PUB,
                    "jobs": [job("android", "tor"), job("android", "notor"), job("linux", "tor")]})
        self.artifact("android", "tor", {"bt-wallet-26.10.25-android-arm64-v8a.apk": b"apk",
                                         "emulator/bt-wallet-26.10.25-android-x86_64.apk": b"emu"})
        self.artifact("linux", "tor", {"bt-wallet-26.10.25-linux-x86_64.AppImage": b"\x7fELF"})

    def tearDown(self):
        os.environ["PATH"] = self.old_path
        os.environ.pop("FAKE_GH", None)
        super().tearDown()

    def state(self, st=None, **kw):
        p = os.path.join(self.gh, "state.json")
        cur = st if st is not None else json.loads(text(p))
        cur.update(kw)
        with open(p, "w") as f:
            json.dump(cur, f)

    def artifact(self, platform, variant, files, info=None, sums=None):
        d = os.path.join(self.gh, "art", f"{platform}-{variant}")
        lines, digests = [], {}
        for rel, data in files.items():
            os.makedirs(os.path.dirname(os.path.join(d, rel)), exist_ok=True)
            with open(os.path.join(d, rel), "wb") as f:
                f.write(data)
            digests[rel] = hashlib.sha256(data).hexdigest()
            lines.append(f"{(sums or {}).get(rel, digests[rel])}  {rel}")
        with open(os.path.join(d, "SHA256SUMS"), "w") as f:
            f.write("\n".join(lines) + "\n")
        bi = {"commit": PUB, "build_id": PUB[:7], "version": "26.10.25", "platform": platform, "variant": variant,
              "runner_image": "ubuntu-24.04", "files": digests}
        bi.update(info or {})
        with open(os.path.join(d, "build-info.json"), "w") as f:
            json.dump(bi, f)

    def gh_calls(self):
        try:
            return [json.loads(x) for x in text(os.path.join(self.gh, "calls.jsonl")).splitlines()]
        except FileNotFoundError:
            return []

    def hosted_run(self, only="android,linux", deadline="60s", test=True, no_variant="notor", waves="", fallback=False):
        text = PIPELINE.format(tmp=self.tmp, deadline=deadline, waves=waves)
        self.pipeline = Pipeline(tomllib.loads(text))
        scope = load_scope(None, "26.10.25", only=only, no_variant=no_variant, sets=["publish.manifests=false"], test=test)
        scope["builds"] = {"hosted": True, **({"fallback": "local"} if fallback else {})}
        path, run_id = Run.next_path(self.root, "26.10.25")
        c = {"version": "26.10.25", "commit": LOCAL, "short": LOCAL[:7], "run_id": run_id, "run": path, "rel": REPO,
             "build_id": hosted.build_id_for(LOCAL, os.path.join(self.tmp, "commit-map")),
             "files": f"{path}/files", "extra": f"{path}/extra", "src": self.src, "host": {}, "path": {}}
        steps = build_graph(self.pipeline, scope, c)
        info = {"version": "26.10.25", "commit": LOCAL, "scope": scope, "test": test, "src": self.src,
                "target": scope["publish"]["target"], "source_published": {"commit": PUB, "short": PUB[:7]}}
        run = Run.create(self.root, "26.10.25", info, scope_toml(scope), steps)
        rm = Relmsg(run, {"bin": self.fake}, enabled=False)
        return run, Engine(run, self.pipeline, self.hosts, REPO, relmsg=rm)

    def drive(self, **kw):
        run, eng = self.hosted_run(**kw)
        eng.drive([s.id for s in run.steps])
        return run

    def log(self, run, sid):
        return text(os.path.join(run.step_dir(sid), "log.txt"))

    def assertFailed(self, run, sid, fragment):
        self.assertEqual(run.status(sid)["status"], "failed")
        self.assertIn(fragment, self.log(run, sid))
        self.assertNotIn("local build", self.calls())  # never the local fallback

    # ---- the whole way ----

    def test_hosted_ok(self):
        run = self.drive()
        self.assertEqual(run.status("hosted-dispatch")["status"], "done")
        for sid in ("build-android-tor", "build-linux-tor"):
            self.assertEqual(run.status(sid)["status"], "done", self.log(run, sid))
        self.assertEqual(sorted(os.listdir(run.files)), ["bt-wallet-26.10.25-android-arm64-v8a.apk",
                                                         "bt-wallet-26.10.25-linux-x86_64.AppImage"])
        self.assertTrue(os.path.isfile(os.path.join(run.extra, "emulator/bt-wallet-26.10.25-android-x86_64.apk")))
        calls = self.gh_calls()
        self.assertTrue(all(c["config"] == os.path.join(self.tmp, "gh") for c in calls))
        disp = [c["args"] for c in calls if c["args"][:2] == ["workflow", "run"]]
        self.assertEqual(len(disp), 1)
        a = disp[0]
        for want in (f"commit={PUB}", f"build_id={PUB[:7]}", "version=26.10.25", 'platforms=["android", "linux"]',
                     'variants=["tor"]', "kind=dev", f"request={run.info['run_id']}-1"):
            self.assertIn(want, a)
        self.assertEqual(a[a.index("--ref") + 1], "main")
        bb = json.loads(text(os.path.join(run.step_dir("build-android-tor"), "out", "built_by.json")))
        self.assertEqual(bb["via"], "hosted")
        self.assertEqual(bb["runner_image"], "ubuntu-24.04")
        self.assertEqual(set(bb["attestation"]), {"bt-wallet-26.10.25-android-arm64-v8a.apk",
                                                  "emulator/bt-wallet-26.10.25-android-x86_64.apk"})
        verify = text(os.path.join(self.src, "app/tool/verify.calls"))
        self.assertIn(f"tor=1 id={PUB[:7]} unsigned=1", verify)
        self.assertIn(f"id={PUB[:7]} unsigned=", text(os.path.join(self.src, "scripts/verify.calls")))
        deletes = [c for c in calls if c["args"][:2] == ["api", "-X"]]
        self.assertTrue(deletes)  # the artifacts go once fetched
        self.assertNotIn("cancel", [c["args"][1] for c in calls if c["args"][0] == "run"])
        self.assertTrue(any(e["event"] == "via" and e.get("via") == "hosted" for e in run.events()))
        links = json.loads(text(os.path.join(run.step_dir("hosted-dispatch"), "out", "links.json")))
        self.assertEqual(links[0]["url"], "https://github.com/R/actions/runs/101")
        lines = text(os.path.join(self.tmp, "dispatches.jsonl")).splitlines()
        self.assertEqual(len(lines), 1)
        # A second pass of the dispatch never dispatches again.
        eng = Engine(run, self.pipeline, self.hosts, REPO, relmsg=Relmsg(run, {"bin": self.fake}, enabled=False))
        from rellib import builtins
        res = builtins.hosted_dispatch(eng, run.step("hosted-dispatch"), lambda *a: None)
        self.assertEqual(res["status"], "done")
        self.assertEqual(len([c for c in self.gh_calls() if c["args"][:2] == ["workflow", "run"]]), 1)

    # ---- waves: tor first, notor only once every tor build is in ----

    def waves_run(self, **kw):
        self.artifact("android", "notor", {"bt-wallet-26.10.25-notor-android-arm64-v8a.apk": b"apk2",
                                           "emulator/bt-wallet-26.10.25-notor-android-x86_64.apk": b"emu2"})
        return self.drive(only="android", no_variant=None, waves='waves = [["tor"], ["notor"]]', **kw)

    def test_waves_second_after_first(self):
        run = self.waves_run()
        for sid in ("hosted-dispatch", "build-android-tor", "build-android-notor"):
            self.assertEqual(run.status(sid)["status"], "done", self.log(run, sid))
        disp = [c["args"] for c in self.gh_calls() if c["args"][:2] == ["workflow", "run"]]
        self.assertEqual(len(disp), 2)
        self.assertIn('variants=["tor"]', disp[0])
        self.assertIn('variants=["notor"]', disp[1])
        self.assertIn(f"request={run.info['run_id']}-2", disp[1])
        self.assertIn("android-notor once these are in", run.status("hosted-dispatch")["note"])
        self.assertIn("wave 2: waiting for android-tor", self.log(run, "build-android-notor"))
        self.assertEqual(len(text(os.path.join(self.tmp, "dispatches.jsonl")).splitlines()), 2)

    def test_waves_first_fails_second_not_sent(self):
        self.state(jobs=[job("android", "tor", conclusion="failure"), job("android", "notor")])
        run = self.waves_run()
        self.assertFailed(run, "build-android-tor", "job android (tor) failure")
        self.assertFailed(run, "build-android-notor", "wave 2 not sent: android-tor failed")
        self.assertEqual(len([c for c in self.gh_calls() if c["args"][:2] == ["workflow", "run"]]), 1)

    def test_waves_of(self):
        c = {"waves": [["tor"], ["notor"]]}
        self.assertEqual(hosted.waves_of(c, ["android-tor", "linux-notor", "linux-tor"]),
                         [["android-tor", "linux-tor"], ["linux-notor"]])
        self.assertEqual(hosted.waves_of(c, ["linux-notor"]), [["linux-notor"]])
        self.assertEqual(hosted.waves_of({"waves": []}, ["a-tor", "a-notor"]), [["a-tor", "a-notor"]])
        self.assertEqual(hosted.waves_of({"waves": [["notor"]]}, ["a-tor", "a-notor"]), [["a-notor"], ["a-tor"]])
        # One wave of both: every build in one dispatch.
        six = ["android-tor", "android-notor", "linux-tor", "linux-notor", "windows-tor", "windows-notor"]
        self.assertEqual(hosted.waves_of({"waves": [["tor", "notor"]]}, six), [six])

    # ---- failures: the step fails with the reason, nothing local runs ----

    def test_job_fails_step_fails(self):
        self.state(jobs=[job("android", "tor", conclusion="failure")])
        run = self.drive(only="android")
        self.assertFailed(run, "build-android-tor", "job android (tor) failure")
        self.assertIn(["run", "cancel", "101", "--repo", "BTLabsUK/wallet-for-epic"], [c["args"] for c in self.gh_calls()])

    def test_deadline_step_fails(self):
        self.state(jobs=[job("android", "tor", status="in_progress", conclusion=None)])
        run = self.drive(only="android", deadline="1s")
        self.assertFailed(run, "build-android-tor", "deadline: android-tor not done")

    def deletes(self):
        return [c for c in self.gh_calls() if c["args"][:2] == ["api", "-X"]]

    def test_verify_fails_keeps_artifact(self):
        self.artifact("android", "tor", {"bt-wallet-26.10.25-android-arm64-v8a.apk": b"apk",
                                         "emulator/bt-wallet-26.10.25-android-x86_64.apk": b"emu"},
                      sums={"bt-wallet-26.10.25-android-arm64-v8a.apk": "0" * 64})
        run = self.drive(only="android")
        self.assertFailed(run, "build-android-tor", "SHA256SUMS says")
        self.assertEqual(self.deletes(), [])
        self.assertFalse(os.path.exists(os.path.join(self.tmp, "backup")))

    def test_success_backs_up_then_deletes(self):
        run = self.drive(only="android")
        self.assertEqual(run.status("build-android-tor")["status"], "done", self.log(run, "build-android-tor"))
        bdir = os.path.join(self.tmp, "backup", f"{run.info['run_id']}-101", "android-tor")
        self.assertEqual(text(os.path.join(bdir, "bt-wallet-26.10.25-android-arm64-v8a.apk")), "apk")
        for f in ("SHA256SUMS", "build-info.json", ".attestation-bt-wallet-26.10.25-android-arm64-v8a.apk.json"):
            self.assertTrue(os.path.exists(os.path.join(bdir, f)), f)
        self.assertTrue(self.deletes())

    def test_fetch_again_uses_the_backup(self):
        run = self.drive(only="android")
        self.assertEqual(run.status("build-android-tor")["status"], "done", self.log(run, "build-android-tor"))
        shutil.rmtree(os.path.join(self.gh, "art", "android-tor"))  # deleted on GitHub after the backup
        shutil.rmtree(os.path.join(run.step_dir("build-android-tor"), "out"))
        downloads = len([c for c in self.gh_calls() if c["args"][:2] == ["run", "download"]])
        run.set_status("build-android-tor", status="pending")
        eng = Engine(run, self.pipeline, self.hosts, REPO, relmsg=Relmsg(run, {"bin": self.fake}, enabled=False))
        eng.drive(["build-android-tor"])
        self.assertEqual(run.status("build-android-tor")["status"], "done", self.log(run, "build-android-tor"))
        self.assertIn("fetched and backed up before", self.log(run, "build-android-tor"))
        self.assertEqual(len([c for c in self.gh_calls() if c["args"][:2] == ["run", "download"]]), downloads)
        self.assertEqual(text(os.path.join(run.step_dir("build-android-tor"), "out",
                                           "bt-wallet-26.10.25-android-arm64-v8a.apk")), "apk")

    def test_backup_fails_keeps_artifact(self):
        os.makedirs(os.path.join(self.tmp, "backup"))
        os.chmod(os.path.join(self.tmp, "backup"), 0o500)
        try:
            if os.access(os.path.join(self.tmp, "backup"), os.W_OK):
                self.skipTest("running as a user that can write anywhere")
            run = self.drive(only="android")
        finally:
            os.chmod(os.path.join(self.tmp, "backup"), 0o700)
        self.assertEqual(run.status("build-android-tor")["status"], "done")
        self.assertIn("backup", self.log(run, "build-android-tor"))
        self.assertEqual(self.deletes(), [])

    def test_cleanup_keeps_artifact_of_failed_fetch(self):
        # android-tor verify fails, linux-tor is fine: the linux fetch's cleanup must not take android-tor
        self.artifact("android", "tor", {"bt-wallet-26.10.25-android-arm64-v8a.apk": b"apk",
                                         "emulator/bt-wallet-26.10.25-android-x86_64.apk": b"emu"},
                      sums={"bt-wallet-26.10.25-android-arm64-v8a.apk": "0" * 64})
        run = self.drive()
        self.assertEqual(run.status("build-android-tor")["status"], "failed")
        self.assertEqual(run.status("build-linux-tor")["status"], "done")
        # fake artifact ids: sorted names, android-tor is 1
        self.assertEqual({c["args"][-1] for c in self.deletes()},  # the fake keeps listing what it deleted
                         {"repos/BTLabsUK/wallet-for-epic/actions/artifacts/2"})

    def test_sha256_mismatch_fails(self):
        self.artifact("android", "tor", {"bt-wallet-26.10.25-android-arm64-v8a.apk": b"apk",
                                         "emulator/bt-wallet-26.10.25-android-x86_64.apk": b"emu"},
                      sums={"bt-wallet-26.10.25-android-arm64-v8a.apk": "0" * 64})
        run = self.drive(only="android")
        self.assertFailed(run, "build-android-tor", "SHA256SUMS says")
        self.assertEqual(os.listdir(run.files) if os.path.isdir(run.files) else [], [])

    def test_local_fallback_builds_here(self):
        """--local-fallback: the failed job's local build runs (here it exits 3, so the step still fails)."""
        self.state(jobs=[job("android", "tor", conclusion="failure")])
        run = self.drive(only="android", fallback=True)
        self.assertEqual(run.status("build-android-tor")["status"], "failed")
        self.assertIn("building locally instead", self.log(run, "build-android-tor"))
        self.assertEqual(self.calls(), ["local build", ""])

    def test_attested_commit_wrong_fails(self):
        self.state(attested="d" * 40)
        run = self.drive(only="android")
        self.assertFailed(run, "build-android-tor", "attested commit dddddddddddd")

    def test_head_sha_wrong_fails(self):
        self.state(head_sha="e" * 40)
        run = self.drive(only="android")
        self.assertFailed(run, "build-android-tor", "built eeeeeeeeeeee, not the published")

    def test_build_info_wrong_fails(self):
        self.artifact("linux", "tor", {"bt-wallet-26.10.25-linux-x86_64.AppImage": b"\x7fELF"}, info={"build_id": "x"})
        run = self.drive(only="linux")
        self.assertFailed(run, "build-linux-tor", "build-info.json: build_id 'x'")

    # ---- the dispatch ----

    def test_cap_reached_dispatch_fails(self):
        now = dt.datetime.now(dt.timezone.utc)
        with open(os.path.join(self.tmp, "dispatches.jsonl"), "w") as f:
            for i in range(8):
                f.write(json.dumps({"ts": (now - dt.timedelta(hours=i)).isoformat(), "run": "x"}) + "\n")
            f.write(json.dumps({"ts": (now - dt.timedelta(hours=30)).isoformat(), "run": "old"}) + "\n")
        run = self.drive(only="android")
        self.assertEqual(run.status("hosted-dispatch")["status"], "failed")
        self.assertIn("8 hosted dispatches in the last 24 h, cap 8", run.status("hosted-dispatch")["note"])
        self.assertFalse([c for c in self.gh_calls() if c["args"][:2] == ["workflow", "run"]])
        self.assertNotEqual(run.status("build-android-tor")["status"], "done")

    def test_ramp_cap(self):
        c = {"max_per_day": 8, "ramp_max_per_day": 2, "ramp_until": "2026-11-10",
             "state": os.path.join(self.tmp, "dispatches.jsonl")}
        now = dt.datetime(2026, 11, 5, 12, tzinfo=dt.timezone.utc)
        with open(c["state"], "w") as f:
            for i in range(2):
                f.write(json.dumps({"ts": (now - dt.timedelta(hours=i)).isoformat()}) + "\n")
        self.assertIn("cap 2 (ramp-up until 2026-11-10", hosted.cap_problem(c, now))
        self.assertIsNone(hosted.cap_problem(c, dt.datetime(2026, 11, 10, 12, tzinfo=dt.timezone.utc)))

    def test_all_builds_reused_no_dispatch(self):
        real = hosted.reused
        hosted.reused = lambda engine, step: True
        try:
            run, eng = self.hosted_run(only="android")
            from rellib import builtins
            res = builtins.hosted_dispatch(eng, run.step("hosted-dispatch"), lambda *a: None)
        finally:
            hosted.reused = real
        self.assertEqual(res["status"], "done")
        self.assertIn("nothing to build", res["note"])
        self.assertFalse([c for c in self.gh_calls() if c["args"][:2] == ["workflow", "run"]])

    def test_gh_without_attestation_fails_before_dispatch(self):
        self.state(old_gh=True)
        run = self.drive(only="android")
        self.assertIn("cannot verify build attestations", hosted.account_problem(hosted.conf(self.pipeline)))
        self.assertEqual(run.status("hosted-dispatch")["status"], "failed")
        self.assertIn("gh 2.49 or newer", run.status("hosted-dispatch")["note"])
        self.assertFalse([c for c in self.gh_calls() if c["args"][:2] == ["workflow", "run"]])

    def test_misc(self):
        self.assertEqual(hosted.build_id_for(LOCAL, os.path.join(self.tmp, "commit-map")), PUB[:7])
        self.assertEqual(hosted.build_id_for("f" * 40, os.path.join(self.tmp, "commit-map")), "f" * 7)
        self.assertIsNone(hosted.published_of("f" * 40, os.path.join(self.tmp, "nope")))
        self.assertEqual(hosted.kind_of({"test": True}), "dev")
        self.assertEqual(hosted.kind_of({"test": False, "target": "live"}), "release")
        jobs = [job("android", "notor"), job("android", "tor")]
        self.assertEqual(hosted.job_of(jobs, "android", "tor")["name"], "android (tor)")
        self.assertIsNone(hosted.job_of(jobs, "linux", "tor"))


class GraphTest(Base):
    def graph(self, builds, local=None):
        s = load_scope(None, "26.10.25")
        if builds == "hosted":
            s["builds"] = {"hosted": True, **({"local": local} if local else {})}
        return {x.id: x for x in build_graph(PIPE, s, real_ctx(s))}

    def test_builds_local_plan_unchanged(self):
        g = self.graph("local")
        self.assertNotIn("hosted-dispatch", g)
        a = g["build-android-tor"]
        self.assertEqual(a.run, "app/tool/build_android_release.sh /r/26.10.25/run-1/steps/build-android-tor/out")
        self.assertEqual((a.host, a.heavy, a.lane), ("signer", True, "heavy"))
        self.assertEqual(a.needs, ["source", "source-check"])
        self.assertEqual(a.env["WFE_BUILD_ID"], "a" * 7)
        self.assertNotIn("local_run", a.to_dict())
        self.assertEqual(g["build-linux-notor"].lane, "build-linux")
        self.assertEqual(g["build-windows-tor"].host, "windows")
        self.assertNotIn("(hosted)", g["build-windows-tor"].title)

    def test_builds_hosted_graph(self):
        g = self.graph("hosted")
        self.assertEqual(g["hosted-dispatch"].needs, ["source", "source-check"])
        for plat in ("android", "linux", "windows"):
            for var in ("tor", "notor"):
                s = g[f"build-{plat}-{var}"]
                self.assertEqual(s.run, f"python3 /rel/tools/rellib/steps/build-fetch.py {plat} {var} "
                                        f"/r/26.10.25/run-1/steps/build-{plat}-{var}/out")
                self.assertEqual((s.host, s.heavy, s.lane), ("local", False, f"hosted-{plat}-{var}"))
                self.assertIn("hosted-dispatch", s.needs)
                self.assertTrue(s.local_run)
                self.assertIn("(hosted)", s.title)
        # Same env as the local build: one reuse key for both.
        self.assertEqual(g["build-linux-tor"].env, self.graph("local")["build-linux-tor"].env)

    def test_local_build_keeps_a_platform_here(self):
        g, local = self.graph("hosted", local="linux"), self.graph("local")
        for var in ("tor", "notor"):
            s, l = g[f"build-linux-{var}"], local[f"build-linux-{var}"]
            self.assertEqual((s.run, s.host, s.heavy, s.lane), (l.run, l.host, l.heavy, l.lane))
            self.assertIsNone(s.local_run)
            self.assertNotIn("(hosted)", s.title)
            self.assertTrue(g[f"build-android-{var}"].local_run)
            self.assertTrue(g[f"build-windows-{var}"].local_run)
        self.assertIn("hosted-dispatch", g)

    def test_hosted_key_checked(self):
        from rellib.config import ConfigError
        bad = tomllib.loads('[step.a]\nrun = "x"\nhosted = "macos"\nfor_each = "variant"\n')
        with self.assertRaises(ConfigError):
            Pipeline(bad)


if __name__ == "__main__":
    import unittest
    unittest.main()
