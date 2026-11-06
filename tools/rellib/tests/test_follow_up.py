# SPDX-License-Identifier: Apache-2.0
"""tools/rel start --follow-up: a run that adds platforms (macOS once its dmgs are in) to the
published run of the same version and commit. It carries that run's files unchanged, so the
manifests, SHA256SUMS, the page and the GitHub release list them all; --apple-results takes
the Apple hand-off results from a folder instead of sending a job."""
import hashlib
import io
import json
import os
import subprocess
import tomllib
from contextlib import redirect_stderr, redirect_stdout

from support import FAKE_PIPELINE, REPO, Base
from rellib import builtins, retention
from rellib.cli import main, version_at
from rellib.config import Pipeline, load_scope
from rellib.run import Run, read_json, write_json

V = version_at(REPO, "HEAD")
HEAD = subprocess.run(["git", "-C", REPO, "rev-parse", "HEAD"], capture_output=True, text=True).stdout.strip()


def rel(*args):
    out, err = io.StringIO(), io.StringIO()
    with redirect_stdout(out), redirect_stderr(err):
        code = main(list(args))
    return code, out.getvalue(), err.getvalue()


def sha(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


class FollowUpCliTest(Base):
    def common(self):
        return ["--state-root", self.root, "--hosts", os.path.join(self.tmp, "no-hosts.toml")]

    def published_base(self, commit=HEAD, only="android,linux,windows"):
        """A published run of V with Android, Linux and Windows files, as tools/rel leaves one."""
        path, run_id = Run.next_path(self.root, V)
        scope = load_scope(None, V, only=only)
        prev = {"dir": os.path.join(self.tmp, "prev"), "version": "26.1.0", "ref": "v26.1.0"}
        run = Run.create(self.root, V, {"version": V, "commit": commit, "scope": scope, "test": False,
                                        "kind": "release", "previous": prev, "published": "2026-11-05T21:52:10Z"}, "", [])
        names = [f"bt-wallet-{V}-android-arm64-v8a.apk", f"bt-wallet-{V}-linux-x86_64.AppImage"]
        for n in names + ["provenance.json"]:
            with open(os.path.join(run.files, n), "w") as f:
                f.write(n)
        os.makedirs(os.path.join(run.extra, "emulator"))
        with open(os.path.join(run.extra, "emulator", "x.apk"), "w") as f:
            f.write("x")
        with open(os.path.join(run.files, "SHA256SUMS"), "w") as f:
            for n in sorted(names + ["provenance.json"]):
                f.write(f"{sha(os.path.join(run.files, n))}  {n}\n")
        write_json(os.path.join(self.root, "published.json"),
                   [{"version": V, "run_id": run_id, "run": path, "at": "2026-11-05T21:52:10Z", "tag": f"v{V}",
                     "kind": "release"}])
        return run, names

    def plan(self, *extra):
        return rel(*self.common(), "plan", V, "--follow-up", "--commit", HEAD, *extra)

    def test_plan_takes_the_base_runs_previous_and_skips_the_screens(self):
        base, _ = self.published_base()
        code, out, err = self.plan("--only", "macos")
        self.assertEqual(code, 0, err)
        self.assertIn(f"follow-up of {base.info['run_id']}", out + err)
        self.assertIn("previous release (G4): 26.1.0", out)
        screens = [ln for ln in out.splitlines() if ln.split()[:1] == ["screens"]]
        self.assertTrue(screens and "SKIP" in screens[0], out)
        self.assertNotIn("manifests need", out + err)

    def test_plan_refuses_what_is_not_a_follow_up(self):
        code, out, err = self.plan("--only", "macos")
        self.assertEqual(code, 64)
        self.assertIn("no published run", err)
        self.published_base()
        code, out, err = self.plan("--only", "macos,linux")
        self.assertEqual(code, 64)
        self.assertIn("linux already shipped", err)
        code, out, err = self.plan("--only", "macos", "--test")
        self.assertEqual(code, 64)
        self.assertIn("not in a TEST", err)
        code, out, err = self.plan("--only", "macos", "--previous", self.tmp)
        self.assertEqual(code, 64)
        self.assertIn("no --previous", err)

    def test_plan_refuses_another_commit(self):
        self.published_base(commit="f" * 40)
        code, out, err = self.plan("--only", "macos")
        self.assertEqual(code, 64)
        self.assertIn("a follow-up ships the same commit", err)

    def start(self, *extra):
        return rel("--json", *self.common(), "start", V, "--follow-up", "--only", "macos", "--commit", HEAD,
                   "--dry-run", "--no-relmsg", "--src", self.src, "--until", "scope", *extra)

    def test_start_copies_the_base_files_and_refuses_changed_ones(self):
        base, names = self.published_base()
        given = os.path.join(self.tmp, "apple")
        os.makedirs(given)
        code, out, err = self.start("--apple-results", given)
        runs = sorted(r for r in os.listdir(os.path.join(self.root, V)) if r != os.path.basename(base.path))
        self.assertEqual(len(runs), 1, out + err)
        info = read_json(os.path.join(self.root, V, runs[0], "run.json"))
        self.assertEqual(info["follow_up"]["run_id"], base.info["run_id"])
        self.assertEqual(sorted(info["follow_up"]["platforms"]), ["android", "linux", "windows"])
        self.assertEqual(info["handoff_from"], given)
        # The release files and extras, not the base's listing (this run writes its own).
        self.assertEqual(sorted(info["carried"]), sorted(names))
        self.assertEqual(list(info["carried_extra"]), ["emulator/x.apk"])
        for n in names:
            self.assertEqual(sha(os.path.join(self.root, V, runs[0], "files", n)), info["carried"][n]["sha256"])
        self.assertFalse(os.path.exists(os.path.join(self.root, V, runs[0], "files", "provenance.json")))
        self.assertTrue(os.path.isfile(os.path.join(self.root, V, runs[0], "extra", "emulator", "x.apk")))
        # A base file that is no longer the bytes its SHA256SUMS names: no run.
        with open(os.path.join(base.files, names[0]), "a") as f:
            f.write("x")
        code, out, err = self.start()
        self.assertEqual(code, 64, out)
        self.assertIn("does not match", out)
        self.assertEqual(len(os.listdir(os.path.join(self.root, V))), 2)

    def test_apple_results_needs_a_folder_and_a_handoff_step(self):
        self.published_base()
        code, out, err = self.start("--apple-results", os.path.join(self.tmp, "none"))
        self.assertEqual(code, 64)
        self.assertIn("no such folder", out)


HANDOFF = """
[step.apple-mac]
kind = "handoff"
platform = "macos"
for_each = "variant"
host = "apple"
needs = ["scope"]
run = "true"
results = ["bt-wallet-{version}{notor}-macos.dmg", "bt-wallet-{version}{notor}-macos.dmg.sha256"]
"""


class HandoffFromTest(Base):
    def test_results_come_from_the_folder_and_no_job_is_written(self):
        self.pipeline = Pipeline(tomllib.loads(FAKE_PIPELINE + HANDOFF))
        run = self.make_run(only="macos", sets=["publish.manifests=false"])
        given = os.path.join(self.tmp, "apple")
        os.makedirs(given)
        run.info["handoff_from"] = given
        run.save_info()
        eng = self.engine(run, relmsg=False)
        step = run.step("apple-mac-tor")
        log = os.path.join(self.tmp, "handoff.log")
        with open(os.path.join(given, "bt-wallet-26.10.25-macos.dmg"), "w") as f:
            f.write("dmg")
        res = eng.exec_handoff(step, log)
        self.assertEqual(res["status"], "waiting")
        self.assertIn("missing bt-wallet-26.10.25-macos.dmg.sha256", res["note"])
        with open(os.path.join(given, "bt-wallet-26.10.25-macos.dmg.sha256"), "w") as f:
            f.write("x")
        res = eng.exec_handoff(step, log)
        self.assertEqual(res["status"], "done", res)
        hdir = os.path.join(run.path, "handoff", "apple-mac-tor")
        self.assertEqual(sorted(os.listdir(os.path.join(hdir, "results"))),
                         ["bt-wallet-26.10.25-macos.dmg", "bt-wallet-26.10.25-macos.dmg.sha256"])
        self.assertFalse(os.path.exists(os.path.join(hdir, "job")))


class CarriedArtefactsTest(Base):
    def test_carried_files_must_keep_their_bytes_and_strays_still_fail(self):
        run = self.make_run(only="linux", sets=["publish.manifests=false"])
        apk = "bt-wallet-26.10.25-android-arm64-v8a.apk"
        with open(os.path.join(run.files, apk), "wb") as f:
            f.write(b"PK" + b"\0" * 2_000_000)
        run.info["carried"] = {apk: {"sha256": "0" * 64, "bytes": 2_000_002, "from": "26.10.25-run1"}}
        run.info["src"] = os.path.join(self.tmp, "no-src")  # the runner's checkout: tools/version.sh, tools/sbom.py
        run.save_info()
        with open(os.path.join(run.files, "stray.txt"), "w") as f:
            f.write("x")
        eng = self.engine(run, relmsg=False)
        said = []
        res = builtins.artefacts(eng, run.step("artefacts") if any(s.id == "artefacts" for s in run.steps) else None,
                                 lambda *a: said.append(" ".join(map(str, a))))
        self.assertEqual(res["status"], "failed")
        text = "\n".join(said)
        self.assertIn(f"{apk}: not the bytes 26.10.25-run1 published", text)
        self.assertIn("stray.txt: not made by any step", text)
        self.assertNotIn(f"{apk}: not made by any step", text)


class RetentionKeepsTheBaseTest(Base):
    def test_the_run_a_follow_up_carries_from_stays(self):
        def run_of(version, follow_up=None):
            path, run_id = Run.next_path(self.root, version)
            info = {"version": version, "commit": "c" * 40, "scope": {}, "test": False}
            if follow_up:
                info["follow_up"] = {"run": follow_up.path, "run_id": follow_up.info["run_id"]}
            r = Run.create(self.root, version, info, "", [])
            pubs = retention.published(self.root)
            pubs.append({"version": version, "run_id": r.info["run_id"], "run": r.path, "at": "x", "tag": f"v{version}"})
            write_json(os.path.join(self.root, "published.json"), pubs)
            return r
        old = run_of("26.10.23")
        base = run_of("26.10.24")
        follow = run_of("26.10.24", follow_up=base)
        p = retention.plan(self.root)
        self.assertEqual(sorted(p["keep"]), sorted([old.path, base.path, follow.path]))
        self.assertTrue(any("follows up" in w for w in p["kept"]), p["kept"])
