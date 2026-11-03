# SPDX-License-Identifier: Apache-2.0
"""Infrastructure failures (tlib/infra.py): which failed integration runs are retried.
    python3 -m unittest discover -s tools/tlib/tests"""
import os
import subprocess
import sys
import tempfile
import unittest

import support
from tlib import infra

# From a green run of /tmp/epic-build/rel/26.10.26/run-1 (source-check/log.txt), noise included.
START = """\
00:00 +0: loading /w/app/integration_test/simple_test.dart
Building Linux application...
✓ Built build/linux/x64/debug/bundle/btwallet
fusermount3: failed to access mountpoint /run/user/1000/gvfs: Permission denied
error: fuse init failed: Can't mount path /run/user/1000/doc
** (xdg-desktop-portal-gnome:2420568): WARNING **: Failed to open service channel Wayland connection
"""
GREEN = START + """\
00:00 +0: (setUpAll)
00:00 +0: PIN vault through LEPIC: create, wrong PIN, phrase, change
00:06 +3: (tearDownAll)
00:06 +3: All tests passed!
A connection to the bus can't be made
"""


class IntegrationTest(unittest.TestCase):
    def test_green(self):
        self.assertEqual(infra.classify_integration(0, GREEN)[0], "pass")

    def test_timeout_before_the_app_started_is_infra(self):
        self.assertEqual(infra.classify_integration(124, START)[0], "infra")
        self.assertEqual(infra.classify_integration(137, START)[0], "infra")

    def test_timeout_while_a_test_ran_is_a_failure(self):
        hung = START + "00:00 +0: (setUpAll)\n00:00 +0: first run through the real core\n"
        self.assertEqual(infra.classify_integration(124, hung)[0], "fail")

    def test_a_failed_expect_is_never_retried_even_after_a_timeout_code(self):
        out = START + "00:00 +0: (setUpAll)\n00:03 +1 -1: first run [E]\n  Expected: 'a'\n"
        self.assertEqual(infra.classify_integration(1, out)[0], "fail")
        self.assertEqual(infra.classify_integration(124, out)[0], "fail")

    def test_a_compile_error_in_the_app_is_a_failure(self):
        out = "lib/src/x.dart:4:7: Error: A value of type 'String' can't be assigned.\n"
        self.assertEqual(infra.classify_integration(1, out)[0], "fail")

    def test_keyring_locked_is_a_failure(self):
        out = START + "KeyringLocked: the keyring is locked\n"
        self.assertEqual(infra.classify_integration(1, out)[0], "fail")

    def test_xvfb_and_dbus_start_errors_are_infra(self):
        for out, why in (("xvfb-run: error: Xvfb failed to start\n", "xvfb"),
                         ("dbus-run-session: failed to exec 'bash'\n", "dbus")):
            result, reason = infra.classify_integration(1, out)
            self.assertEqual(result, "infra", out)
            self.assertIn(why, reason)

    def test_an_unknown_exit_without_tests_is_a_failure(self):
        self.assertEqual(infra.classify_integration(1, START)[0], "fail")

    def test_the_command_line_helper_check_sh_calls(self):
        with tempfile.TemporaryDirectory() as d:
            log = os.path.join(d, "log")
            with open(log, "w", encoding="utf-8") as f:
                f.write(START)
            out = subprocess.run([sys.executable, os.path.join(support.TOOLS, "tlib", "infra.py"),
                                  "classify", "124", log], capture_output=True, text=True)
        self.assertTrue(out.stdout.startswith("infra: timed out"), out.stdout + out.stderr)


if __name__ == "__main__":
    unittest.main()
