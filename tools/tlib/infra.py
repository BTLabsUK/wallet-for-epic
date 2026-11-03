# SPDX-License-Identifier: Apache-2.0
"""Failures that are not the test's: the machine, not the code (docs/TESTING.md, "Infrastructure
failures are retried once").

A test result is `pass`, `fail` (an assertion or exception inside a test, or code that does not
compile) or `infra` (the process that runs the tests died or never started, and no test reported
an assertion). Only `infra` is retried, once, by itself; a `fail` is never retried.

classify_integration() is the same call for check.sh's integration tests, from the output of one
`flutter test -d linux integration_test/<file>` run under xvfb-run.
"""
import re

# The runner or its helpers failed before or around the tests, in the words of the tools.
INTEGRATION_INFRA = [
    (re.compile(r"xvfb-run: error|Xvfb failed to start|Cannot open display|Unable to open display"),
     "xvfb did not start"),
    (re.compile(r"dbus-run-session: |Failed to execute child process .*dbus|Could not connect: "
                r"No such file or directory.*dbus"), "dbus session did not start"),
    (re.compile(r"gnome-keyring-daemon: .*(?:failed|cannot|Cannot|couldn't)|"
                r"couldn't connect to dbus|GNOME_KEYRING_CONTROL.*(?:not set|unset)"),
     "keyring did not start"),
]
# Something the app's code or the test did: never infra.
INTEGRATION_FAIL = re.compile(
    r"\d+:\d\d \+\d+(?: ~\d+)? -\d+: |Some tests failed|\[E\]|Error: |error • |Expected: |"
    r"KeyringLocked|The following (?:\w+ )?was thrown")
# Progress lines that show a test started: `00:00 +0: (setUpAll)`, `00:03 +1: <name>`.
_STARTED = re.compile(r"^\d+:\d\d \+\d+(?: ~\d+)?: (?!loading )", re.M)
TIMEOUT_CODES = (124, 137, 143)  # timeout, then SIGKILL after --kill-after, or SIGTERM


def classify_integration(rc, output):
    """('pass' | 'fail' | 'infra', reason) for one integration file run: its exit code and output."""
    if rc == 0:
        return "pass", ""
    if INTEGRATION_FAIL.search(output):
        return "fail", "a test reported a failure"
    started = bool(_STARTED.search(output))
    for pattern, reason in INTEGRATION_INFRA:
        if pattern.search(output) and not started:
            return "infra", reason
    if rc in TIMEOUT_CODES and not started:
        return "infra", f"timed out (exit {rc}) before the app started"
    return "fail", f"exit {rc}" + (" while the test ran" if started else "")


def main(argv):
    """infra.py classify <exit code> <output file>: prints `pass`, `fail: <why>` or `infra: <why>`."""
    import sys
    if len(argv) != 4 or argv[1] != "classify":
        print(__doc__, file=sys.stderr)
        return 64
    try:
        with open(argv[3], encoding="utf-8", errors="replace") as f:
            output = f.read()
        rc = int(argv[2])
    except (OSError, ValueError) as e:
        print(f"fail: {e}")
        return 0
    result, why = classify_integration(rc, output)
    print(result + (f": {why}" if why else ""))
    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main(sys.argv))
