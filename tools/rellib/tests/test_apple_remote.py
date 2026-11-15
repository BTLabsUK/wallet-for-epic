# SPDX-License-Identifier: Apache-2.0
"""A hand-off step that [host.apple] ssh + auto names runs on the Mac by itself
(Engine.remote_handoff, steps/apple-remote.sh). The script is replaced by a stub here; the real
one is proven live."""
import os
import stat
import tomllib

from support import FAKE_PIPELINE, Base
from rellib import engine
from rellib.config import Pipeline

HANDOFF = """
[step.apple-mac]
kind = "handoff"
platform = "macos"
for_each = "variant"
host = "apple"
needs = ["scope"]
run = "echo build {version}{notor}"
results = ["bt-wallet-{version}{notor}-macos.dmg", "bt-wallet-{version}{notor}-macos.dmg.sha256"]

[step.ios-testflight]
kind = "handoff"
platform = "ios"
host = "apple"
needs = ["scope"]
run = "echo by hand"
results = ["REPORT.txt"]
"""

# Records its arguments and environment; writes the results (and their SHA256SUMS) unless told not to.
STUB = r"""#!/bin/bash
shift 0
host="$1"; workdir="$2"; run_id="$3"; step_id="$4"; job="$5"; results="$6"; commit="$7"; src="$8"; tmo="$9"
shift 9
{
  echo "host=$host workdir=$workdir run=$run_id step=$step_id commit=$commit tmo=$tmo"
  echo "cmd=$APPLE_REMOTE_CMD"
  echo "env=$APPLE_REMOTE_ENV"
  echo "names=$*"
} > "$job/../stub.txt"
echo "apple-remote: stub ran"
case "${STUB_MODE:-ok}" in
  fail) echo "apple-remote: the command failed on $host (exit 3); see the log above" >&2; exit 1 ;;
  ok) mkdir -p "$results"; for n in "$@"; do echo "x $n" > "$results/$n"; done
      (cd "$results" && sha256sum -- "$@" > SHA256SUMS) ;;
esac
"""


class RemoteHandoffTest(Base):
    def setUp(self):
        super().setUp()
        self.pipeline = Pipeline(tomllib.loads(FAKE_PIPELINE + HANDOFF))
        self.stub = os.path.join(self.tmp, "apple-remote-stub.sh")
        with open(self.stub, "w") as f:
            f.write(STUB)
        os.chmod(self.stub, os.stat(self.stub).st_mode | stat.S_IEXEC)
        old = engine.APPLE_REMOTE
        engine.APPLE_REMOTE = self.stub
        self.addCleanup(setattr, engine, "APPLE_REMOTE", old)
        self.hosts["host"]["apple"] = {"ssh": "mac", "auto": ["apple-mac"], "workdir": "~/rel-jobs",
                                       "env": {"NOTARY_KEYCHAIN": "$HOME/Library/Keychains/build.keychain-db",
                                               "APPLE_TEAM_ID": "AM8YPW9P6T"}}
        self.run_ = self.make_run(only="macos", sets=["publish.manifests=false"])
        self.addCleanup(os.environ.pop, "STUB_MODE", None)
        self.log = os.path.join(self.tmp, "step.log")
        self.eng = self.engine(self.run_, relmsg=False)

    def job(self, step):
        """A job as exec_handoff leaves it (the test source is no git repo, so the bundle is made here)."""
        job = os.path.join(self.run_.path, "handoff", step.id, "job")
        os.makedirs(job)
        for n in ("job.toml", "wfe.bundle"):
            with open(os.path.join(job, n), "w") as f:
                f.write("x")

    def test_an_auto_step_runs_the_script_and_takes_its_results(self):
        step = self.run_.step("apple-mac-tor")
        self.job(step)
        os.environ["STUB_MODE"] = "ok"
        res = self.eng.exec_handoff(step, self.log)
        self.assertEqual(res["status"], "done", res)
        hdir = os.path.join(self.run_.path, "handoff", step.id)
        self.assertEqual(sorted(os.listdir(os.path.join(hdir, "results"))),
                         ["SHA256SUMS", "bt-wallet-26.10.25-macos.dmg", "bt-wallet-26.10.25-macos.dmg.sha256"])
        with open(os.path.join(hdir, "stub.txt")) as f:
            seen = f.read()
        self.assertIn("host=mac workdir=~/rel-jobs run=", seen)
        self.assertIn(f"step=apple-mac-tor commit={'c' * 40} tmo=150", seen)
        self.assertIn("cmd=echo build 26.10.25", seen)
        self.assertIn("env=APPLE_TEAM_ID=AM8YPW9P6T\nNOTARY_KEYCHAIN=$HOME/Library/Keychains/build.keychain-db", seen)
        self.assertIn("names=bt-wallet-26.10.25-macos.dmg bt-wallet-26.10.25-macos.dmg.sha256", seen)
        with open(self.log) as f:
            self.assertIn("stub ran", f.read())

    def test_a_failing_script_fails_the_step_with_its_last_line(self):
        step = self.run_.step("apple-mac-tor")
        self.job(step)
        os.environ["STUB_MODE"] = "fail"
        res = self.eng.exec_handoff(step, self.log)
        self.assertEqual(res["status"], "failed", res)
        self.assertIn("exit 1", res["note"])
        self.assertIn("the command failed on mac (exit 3)", res["note"])

    def test_a_script_that_exits_0_without_results_leaves_the_step_waiting(self):
        step = self.run_.step("apple-mac-tor")
        self.job(step)
        os.environ["STUB_MODE"] = "none"
        res = self.eng.exec_handoff(step, self.log)
        self.assertEqual(res["status"], "waiting", res)  # same as the manual route: the result is not there yet
        self.assertIn("missing", res["note"])

    def test_without_ssh_or_when_not_in_auto_nothing_runs(self):
        step = self.run_.step("apple-mac-tor")
        for apple in ({"auto": ["apple-mac"]}, {"ssh": "mac", "auto": []}, {"ssh": "mac", "auto": ["ios-testflight"]}):
            self.hosts["host"]["apple"] = apple
            self.assertIsNone(self.eng.remote_handoff(step, self.log, "j", "r"))
        self.assertFalse(os.path.exists(os.path.join(self.run_.path, "handoff", step.id, "stub.txt")))

    def test_apple_results_from_a_folder_never_runs_the_script(self):
        step = self.run_.step("apple-mac-tor")
        self.run_.info["handoff_from"] = os.path.join(self.tmp, "given")
        self.assertIsNone(self.eng.remote_handoff(step, self.log, "j", "r"))

    def test_a_job_without_a_bundle_fails_clearly(self):
        step = self.run_.step("apple-mac-tor")
        os.makedirs(os.path.join(self.run_.path, "handoff", step.id, "job"))
        res = self.eng.remote_handoff(step, self.log, os.path.join(self.run_.path, "handoff", step.id, "job"), "r")
        self.assertEqual(res["status"], "failed")
        self.assertIn("wfe.bundle", res["note"])

    def test_workdir_keeps_its_tilde_when_the_hosts_file_is_read(self):
        from rellib.config import load_hosts
        path = os.path.join(self.tmp, "hosts.toml")
        with open(path, "w") as f:
            f.write('[host.apple]\nssh = "mac"\nworkdir = "~/rel-jobs"\nstaging = "~/x"\nauto = ["apple-mac"]\n')
        apple = load_hosts(path)["host"]["apple"]
        self.assertEqual(apple["workdir"], "~/rel-jobs")
        self.assertEqual(apple["staging"], os.path.expanduser("~/x"))
