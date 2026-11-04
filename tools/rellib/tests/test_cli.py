# SPDX-License-Identifier: Apache-2.0
"""The command line: exit codes and --json for agents, plan without side effects, refusals."""
import io
import json
import os
import unittest
from contextlib import redirect_stderr, redirect_stdout

from support import Base, FAKE_PIPELINE, REPO
from rellib.cli import main, version_at

# The version these runs ask for is the one app/pubspec.yaml carries, as a real run must.
V = version_at(REPO, "HEAD")


def rel(*args):
    out, err = io.StringIO(), io.StringIO()
    with redirect_stdout(out), redirect_stderr(err):
        code = main(list(args))
    return code, out.getvalue(), err.getvalue()


class CliTest(Base):
    def common(self):
        return ["--state-root", self.root, "--hosts", os.path.join(self.tmp, "no-hosts.toml")]

    def test_nonsense_scope_is_exit_64_with_reason(self):
        code, out, err = rel("--json", *self.common(), "plan", V, "--only", "toaster")
        self.assertEqual(code, 64)
        obj = json.loads(out)
        self.assertEqual(obj["exit"], 64)
        self.assertIn("not a platform", obj["message"])
        code, out, err = rel(*self.common(), "start", V, "--skip", "build-linux=because", "--test", "--dry-run")
        self.assertEqual(code, 64)
        self.assertIn("cannot be skipped", err)
        self.assertFalse(os.path.isdir(os.path.join(self.root, V)), "no run folder for a refused scope")

    def test_plan_has_no_side_effects_and_json(self):
        code, out, err = rel("--json", *self.common(), "plan", V, "--test", "--only", "android")
        self.assertEqual(code, 0, err)
        obj = json.loads(out)
        ids = [s["id"] for s in obj["steps"]]
        self.assertIn("build-android-tor", ids)
        self.assertNotIn("build-linux-tor", ids)
        self.assertFalse(os.path.exists(self.root))

    def test_unknown_run_and_usage(self):
        self.assertEqual(rel(*self.common(), "status")[0], 64)
        self.assertEqual(rel("nonsense-command")[0], 64)

    def test_previous_must_be_a_version(self):
        code, out, err = rel(*self.common(), "plan", V, "--test", "--previous", self.tmp)
        self.assertEqual(code, 64)
        self.assertIn("previous_version", err)

    def test_dry_run_start_status_publish(self):
        prev = os.path.join(self.tmp, "26.1.0")
        os.makedirs(prev)
        code, out, err = rel("--json", *self.common(), "start", V, "--test", "--dry-run", "--only", "android",
                             "--no-relmsg", "--previous", prev, "--waive", "android=fake")
        obj = json.loads(out.strip().splitlines()[-1])
        self.assertTrue(obj["dry"])
        self.assertIn(obj["exit"], (0, 30), obj["message"])  # 30 on a machine without the Android tools
        code, out, err = rel("--json", *self.common(), "status")
        self.assertEqual(json.loads(out)["exit"], 0)
        code, out, err = rel(*self.common(), "skip", "build-android-tor", "--reason", "x")
        self.assertEqual(code, 64)
        code, out, err = rel(*self.common(), "run", "publish-downloads")
        self.assertIn(code, (40, 64))

    def test_run_several_steps_keep_going(self):
        pipe = os.path.join(self.tmp, "pipeline.toml")
        with open(pipe, "w") as f:
            f.write(FAKE_PIPELINE)
        run = self.make_run(only="android,linux", sets=["publish.manifests=false"])
        args = [*self.common(), "--pipeline", pipe, "run", "--run", run.info["version"]]
        code, out, err = rel(*args, "build-android-tor", "build-linux-tor")
        self.assertEqual(code, 64)
        self.assertIn("needs scope", out + err)
        run.set_status("scope", status="done")
        open(os.path.join(self.src, "fail-notor"), "w").close()
        lanes = ["build-android-notor", "build-android-tor", "build-linux-tor", "trust-linux-tor"]
        code, out, err = rel(*args, *lanes, "--keep-going")
        self.assertEqual(code, 64)  # trust-linux-tor also needs build-linux-notor, outside the selection
        self.assertIn("build-linux-notor", out + err)
        code, out, err = rel(*args, *lanes, "--keep-going", "--ignore-needs")
        self.assertEqual(code, 20, out + err)
        run = type(run).find(self.root, run.info["version"])
        st = {s: run.status(s)["status"] for s in lanes}
        self.assertEqual(st, {"build-android-notor": "failed", "build-android-tor": "done", "build-linux-tor": "done",
                              "trust-linux-tor": "pending"})  # a need in the selection failed: it never started
        self.assertIn("linux tor", self.calls())
        self.assertNotIn("linux notor", self.calls())
        self.assertTrue(any("trust-linux-tor" in t["reason"] for t in run.info.get("tainted", [])))
        self.assertEqual(run.step("trust-linux-tor").needs, ["build-android-tor", "build-android-notor", "build-linux-tor",
                                                             "build-linux-notor"])


if __name__ == "__main__":
    unittest.main()
