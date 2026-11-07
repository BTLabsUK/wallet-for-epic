# SPDX-License-Identifier: Apache-2.0
"""tools/check.sh: the order of its steps, the timing line each step prints, and keep-going.
    python3 -m unittest discover -s tools/tlib/tests"""
import os
import re
import subprocess
import unittest

import support

CHECK = os.path.join(support.TOOLS, "check.sh")


def text():
    with open(CHECK, encoding="utf-8") as f:
        return f.read()


class StepOrderTest(unittest.TestCase):
    def test_seconds_long_checks_run_before_the_flutter_suite(self):
        t = text()
        names = re.findall(r'^\s*step "([^"]*)"', t, re.M)
        suite = names.index("flutter test (all)")
        for cheap in ("version (https://docs.btlabs.uk/developers/releases/)", "no hosts in code (docs/settings-file.md)",
                      "bot", "release tools (tools/)"):
            self.assertLess(names.index(cheap), suite, cheap)
        # the web build is slow and stays last
        self.assertEqual(names[-1], "web build (the preview, tool/build_web.sh)")
        self.assertGreater(names.index(names[-1]), suite)

    def test_bot_runs_the_lint_before_its_tests(self):
        line = next(x for x in text().splitlines() if "uvx ruff check" in x and "pytest" in x)
        self.assertLess(line.index("ruff check"), line.index("pytest"))


class StepTimingTest(unittest.TestCase):
    """The helper functions, cut out of check.sh and run on their own."""

    def helpers(self):
        t = text()
        a = t.index("step_name=")
        b = t.index("trap on_exit EXIT") + len("trap on_exit EXIT")
        return t[a:b]

    def run_script(self, body):
        script = "set -euo pipefail\n" + self.helpers() + "\n" + body
        return subprocess.run(["bash", "-c", script], capture_output=True, text=True)

    def test_each_step_prints_one_timing_line(self):
        r = self.run_script('step "bot (extra words)"\ntrue\nstep "web build"\ntrue\nstep_done\n')
        self.assertEqual(r.returncode, 0, r.stderr)
        lines = [x for x in r.stdout.splitlines() if x.startswith("== ")]
        self.assertRegex(lines[0], r"^== bot \(extra words\)$")
        self.assertRegex(lines[1], r"^== bot: ok \d+s$")
        self.assertRegex(lines[2], r"^== web build$")
        self.assertRegex(lines[3], r"^== web build: ok \d+s$")

    def test_a_failed_step_prints_its_time_and_keeps_the_exit_code(self):
        r = self.run_script('step "bot"\nexit 3\n')
        self.assertEqual(r.returncode, 3)
        self.assertRegex(r.stdout, r"== bot: FAILED \(exit 3\) after \d+s")
        self.assertNotIn("ok", r.stdout.split("== bot\n")[1])

    def test_a_failed_command_keeps_going_and_the_check_names_every_failed_step(self):
        r = self.run_script('mode=full\nstep "bot"\nfalse || step_failed $?\n(exit 4) || step_failed $?\necho after\n'
                            'step "release tools (tools/)"\ntrue\nstep "flutter analyze"\n(exit 2) || step_failed $?\n'
                            'check_end\necho unreachable\n')
        self.assertEqual(r.returncode, 1, r.stderr)
        self.assertIn("after", r.stdout)
        self.assertRegex(r.stdout, r"== bot: FAILED \(exit 1\) after \d+s")
        self.assertRegex(r.stdout, r"== release tools: ok \d+s")
        self.assertRegex(r.stdout, r"== flutter analyze: FAILED \(exit 2\) after \d+s")
        self.assertIn("check FAILED (full): bot; flutter analyze", r.stdout)
        self.assertNotIn("unreachable", r.stdout)

    def test_every_command_of_the_steps_keeps_going(self):
        """After the first step, a command that can fail is followed by `|| step_failed`."""
        t = text()
        body = t[t.index('step "version'):t.index("check_end\n")]
        for cmd in ('tools/lepic.sh" build linux', "flutter analyze --no-pub", 'tools/t" full --no-cache',
                    "dart run bin/core_check.dart", "tool/build_web.sh", "discover -s tools/rellib/tests",
                    "discover -s tools/tlib/tests", "test-incremental.sh", "vectors verify", "uv run pytest -q"):
            line = next(x for x in body.splitlines() if cmd in x and not x.lstrip().startswith("step "))
            self.assertIn("|| step_failed", line, cmd)
        self.assertNotIn('exit "$rc"', body)


class ReleaseToolsSkipTest(unittest.TestCase):
    """release_tools_green, cut out of check.sh, in a temp git repo with temp green records."""

    def setUp(self):
        import tempfile
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.repo = os.path.join(self.tmp.name, "repo")
        self.green = os.path.join(self.tmp.name, "green")
        os.makedirs(self.green)
        os.makedirs(os.path.join(self.repo, "tools"))
        self.git("init", "-q")
        self.commit("tools/a.py", "1", "first")

    def git(self, *a):
        return subprocess.run(["git", "-C", self.repo, "-c", "user.name=t", "-c", "user.email=t@x", *a],
                              capture_output=True, text=True, check=True).stdout.strip()

    def commit(self, path, body, msg):
        full = os.path.join(self.repo, path)
        os.makedirs(os.path.dirname(full), exist_ok=True)
        with open(full, "w") as f:
            f.write(body)
        self.git("add", "-A")
        self.git("commit", "-q", "-m", msg)
        return self.git("rev-parse", "HEAD")

    def record(self, sha, mtime):
        p = os.path.join(self.green, sha + ".json")
        with open(p, "w") as f:
            f.write('{\n  "sha": "%s",\n  "status": "green"\n}\n' % sha)
        os.utime(p, (mtime, mtime))

    def decide(self):
        t = text()
        fn = t[t.index("release_tools_green() {"):t.index("if [[ $mode == full || $tools_changed")]
        r = subprocess.run(["bash", "-c", f'root="$1"; {fn}\nrelease_tools_green', "_", self.repo],
                           capture_output=True, text=True, env={**os.environ, "WFE_GREEN_DIR": self.green})
        return r.returncode, r.stdout.strip()

    def test_no_record_runs_the_step(self):
        self.assertEqual(self.decide()[0], 1)

    def test_unchanged_since_a_green_ancestor_skips(self):
        green = self.git("rev-parse", "HEAD")
        self.record(green, 100)
        self.commit("app/lib/x.dart", "x", "app only")
        rc, out = self.decide()
        self.assertEqual(rc, 0)
        self.assertTrue(green.startswith(out))

    def test_a_diff_under_tools_runs_the_step(self):
        self.record(self.git("rev-parse", "HEAD"), 100)
        self.commit("tools/a.py", "2", "tools change")
        self.assertEqual(self.decide()[0], 1)

    def test_an_untracked_file_under_release_runs_the_step(self):
        self.record(self.git("rev-parse", "HEAD"), 100)
        os.makedirs(os.path.join(self.repo, "release"))
        open(os.path.join(self.repo, "release", "new.toml"), "w").close()
        self.assertEqual(self.decide()[0], 1)

    def test_the_newest_ancestor_decides_and_non_ancestors_are_ignored(self):
        old = self.git("rev-parse", "HEAD")
        self.commit("tools/a.py", "2", "tools change")
        new = self.git("rev-parse", "HEAD")
        self.record(old, 100)
        self.record(new, 200)
        self.assertEqual(self.decide()[0], 0)       # newest record is HEAD itself
        self.record("a" * 40, 300)                  # not in the repo: skipped
        self.assertEqual(self.decide()[0], 0)
        self.commit("tools/a.py", "3", "later")
        self.assertEqual(self.decide()[0], 1)       # newest ancestor (new) differs; old is not used


class CachedModeTest(unittest.TestCase):
    def test_usage_and_no_green_record_for_a_cached_run(self):
        r = subprocess.run(["bash", CHECK, "--cached"], capture_output=True, text=True)
        self.assertEqual(r.returncode, 64)
        r = subprocess.run(["bash", CHECK, "--list", "--cached"], capture_output=True, text=True)
        self.assertEqual(r.returncode, 64)
        t = text()
        end = t[t.index("check_end\nprintf"):]
        self.assertLess(end.index("if (( cached ))"), end.index("green.py"))


class SourceCheckRerunTest(unittest.TestCase):
    """source-check.sh with fakes for dbus-run-session, gnome-keyring-daemon and tools/check.sh."""

    def setUp(self):
        import tempfile
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        d = self.tmp.name
        self.bin = os.path.join(d, "bin")
        self.src = os.path.join(d, "src")
        self.out = os.path.join(d, "out")
        for x in (self.bin, os.path.join(self.src, "tools"), self.out):
            os.makedirs(x)
        self.write(os.path.join(self.bin, "dbus-run-session"), '#!/bin/sh\nshift\nexec "$@"\n')
        self.write(os.path.join(self.bin, "gnome-keyring-daemon"), "#!/bin/sh\ncat >/dev/null\n")
        self.log = os.path.join(d, "calls.log")
        self.write(os.path.join(self.src, "tools", "check.sh"),
                   '#!/bin/bash\necho "$*" >>"$CALLS"\n'
                   '[[ " $* " == *" --cached "* ]] && exit "${CACHED_RC:-0}"\nexit "${FULL_RC:-0}"\n')

    def write(self, path, body):
        with open(path, "w") as f:
            f.write(body)
        os.chmod(path, 0o755)

    def run_step(self, full_rc=0, cached_rc=0):
        env = {**os.environ, "PATH": self.bin + ":" + os.environ["PATH"], "CALLS": self.log,
               "FULL_RC": str(full_rc), "CACHED_RC": str(cached_rc)}
        script = os.path.join(support.TOOLS, "rellib", "steps", "source-check.sh")
        r = subprocess.run(["bash", script, self.out], cwd=self.src, capture_output=True, text=True, env=env)
        with open(self.log) as f:
            calls = f.read().split("\n")[:-1]
        os.remove(self.log)
        return r.returncode, calls

    def test_first_attempt_runs_only_the_uncached_check_and_a_failure_leaves_the_marker(self):
        self.assertEqual(self.run_step(full_rc=1), (1, ["--full"]))
        self.assertTrue(os.path.exists(os.path.join(self.out, "g2-failed")))

    def test_a_rerun_runs_cached_first_then_the_evidence_run_and_clears_the_marker(self):
        open(os.path.join(self.out, "g2-failed"), "w").close()
        self.assertEqual(self.run_step(), (0, ["--full --cached", "--full"]))
        self.assertFalse(os.path.exists(os.path.join(self.out, "g2-failed")))

    def test_a_rerun_that_fails_cached_stops_there_and_keeps_the_marker(self):
        open(os.path.join(self.out, "g2-failed"), "w").close()
        self.assertEqual(self.run_step(cached_rc=1), (1, ["--full --cached"]))
        self.assertTrue(os.path.exists(os.path.join(self.out, "g2-failed")))


if __name__ == "__main__":
    unittest.main()
