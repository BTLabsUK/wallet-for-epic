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


if __name__ == "__main__":
    unittest.main()
