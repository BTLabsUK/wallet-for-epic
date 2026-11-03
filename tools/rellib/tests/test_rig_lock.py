# SPDX-License-Identifier: Apache-2.0
"""The Windows rig's user lock (drivers/windows/rig.py lock_user): a run waiting for another run of the same
rig user ends promptly on SIGTERM or SIGINT with a HARNESS stop, and its cleanup does not wait on an agent
it never queued. No rig: the box's answers are stubbed, the other run is this test holding the lock."""
import fcntl
import os
import signal
import subprocess
import sys
import tempfile
import time
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
DRIVERS = os.path.join(os.path.dirname(HERE), "drivers")
WIN = os.path.join(DRIVERS, "windows")
sys.path.insert(0, WIN)

import rig  # noqa: E402

# A lane in a child process: lane.py's SIGTERM handler (when asked), the rig's prepare(), then the cleanup
# windows_platform.shutdown() does (rpc calls, quit, close). ssh is a stub that would hang for minutes.
CHILD = r'''
import os, signal, sys, time
sys.path.insert(0, %(win)r); sys.path.insert(0, %(drivers)r)
import rig
from core.faults import Fault, HarnessFault
r = rig.Rig("windows-pc", "lock-test", lambda s: print("LOG " + s, flush=True), %(ctl)r, session=4)
r.pwsh = lambda script, timeout=120, check=True: "USER=DESKTOP\\epicrig3\n"
def ssh(command, timeout=120, check=True):
    print("SSH " + command[:40], flush=True)
    time.sleep(300)
r.ssh = ssh
if %(handler)r:
    def stopped(sig, _frame):
        raise HarnessFault("prepare", "the lane was stopped (signal %%d)" %% sig)
    signal.signal(signal.SIGTERM, stopped)
code = 0
try:
    r.lock_user()
    print("LOCKED", flush=True)
except Fault as f:
    print("FAULT " + f.line(), flush=True)
    code = 2
except rig.RigStopped as e:
    print("STOPPED " + str(e), flush=True)
    code = 2
finally:
    for op in ("close", "stop_all", "uninstall"):
        print("CALL %%s %%s" %% (op, r.call(op, timeout=200)), flush=True)
    r.quit_agent()
    r.close()
    print("DONE", flush=True)
sys.exit(code)
'''


class LockWaitTest(unittest.TestCase):
    def setUp(self):
        self.ctl = tempfile.mkdtemp()
        self.held = open(os.path.join(self.ctl, "user-windows-pc-epicrig3.lock"), "w")
        fcntl.flock(self.held, fcntl.LOCK_EX)

    def tearDown(self):
        self.held.close()

    def run_stopped(self, sig, handler):
        p = subprocess.Popen([sys.executable, "-c", CHILD % {"win": WIN, "drivers": DRIVERS, "ctl": self.ctl, "handler": handler}],
                             stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        out = []
        t0 = time.time()
        for line in p.stdout:  # until the child says it waits for the lock
            out.append(line)
            if "waiting for it" in line:
                break
            self.assertLess(time.time() - t0, 20, "".join(out))
        p.send_signal(sig)
        t1 = time.time()
        try:
            rest, _ = p.communicate(timeout=10)
        except subprocess.TimeoutExpired:
            p.kill()
            self.fail("the lock wait did not end within 10 s of %s: %s" % (signal.Signals(sig).name, "".join(out)))
        return "".join(out) + rest, p.returncode, time.time() - t1

    def check(self, out, code, took):
        self.assertLess(took, 5, out)
        self.assertEqual(code, 2, out)
        self.assertIn("HARNESS", out)
        self.assertNotIn("LOCKED", out)
        self.assertNotIn("SSH ", out, "the cleanup reached for an agent this run never queued")
        self.assertIn("no agent on the rig", out)
        self.assertIn("DONE", out)

    def test_sigterm_with_the_lanes_handler(self):
        out, code, took = self.run_stopped(signal.SIGTERM, True)
        self.check(out, code, took)
        self.assertIn("FAULT HARNESS", out)
        self.assertIn("the lane was stopped (signal 15)", out)

    def test_sigterm_without_a_handler(self):
        out, code, took = self.run_stopped(signal.SIGTERM, False)
        self.check(out, code, took)
        self.assertIn("STOPPED stopped by SIGTERM while waiting for epicrig3's lock on rig session 4", out)

    def test_sigint(self):
        out, code, took = self.run_stopped(signal.SIGINT, False)
        self.check(out, code, took)
        self.assertIn("STOPPED stopped by SIGINT", out)

    def test_other_user_does_not_wait(self):
        """The lock is per user: a run for epicrig2 takes its own lock while epicrig3's is held."""
        r = rig.Rig("windows-pc", "other", lambda s: None, self.ctl, session=5)
        r.pwsh = lambda script, timeout=120, check=True: "USER=epicrig2\n"
        t0 = time.time()
        r.lock_user()
        self.assertLess(time.time() - t0, 2)
        self.assertEqual(r.user, "epicrig2")
        r._lock.close()

    def test_handlers_restored_after_the_wait(self):
        before = signal.getsignal(signal.SIGTERM)
        r = rig.Rig("windows-pc", "x", lambda s: None, self.ctl, session=4)
        r.pwsh = lambda script, timeout=120, check=True: "USER=epicrig3\n"
        self.held.close()  # free: no wait, and no handler change
        r.lock_user()
        self.assertIs(signal.getsignal(signal.SIGTERM), before)
        r._lock.close()
        self.held = open(os.path.join(self.ctl, "user-windows-pc-epicrig3.lock"), "w")


class RigUserFactsTest(unittest.TestCase):
    REC = {"session": 4, "task": "EpicWalletRig4", "work": "C:\\EpicRig4", "exists": True, "enabled": True,
           "state": "Ready", "last_result": 0, "last_run": "2026-11-03T07:10:00Z", "sid": "S-1-5-21-1-2-3-1005",
           "user": "epicrig3", "account_enabled": True, "locked": False, "rights_error": "", "batch_right": True,
           "batch_denied": False, "profile": True, "queued": 0, "now": "2026-11-03T07:11:00Z"}

    def test_missing_work_grant_flagged(self):
        self.assertEqual(rig.judge(dict(self.REC, work_grant=True)), [])
        self.assertEqual(rig.judge(self.REC), [])  # an older rig-health without the field
        self.assertEqual(rig.judge(dict(self.REC, work_grant=False)), ["epicrig3 has no Modify grant of its own on C:\\EpicRig4"])

    def test_describe_and_same_user(self):
        self.assertEqual(rig.describe(4, [], self.REC), "rig 4 (EpicWalletRig4 as epicrig3): ok")
        self.assertEqual(rig.describe(4, ["x"]), "rig 4 (EpicWalletRig4): x")
        report = {1: (dict(self.REC, session=1, user="epicrig"), []), 2: (dict(self.REC, session=2, user="epicrig"), []),
                  4: (self.REC, []), 5: (dict(self.REC, session=5, user="epicrig2"), []), 6: (None, ["not found"])}
        self.assertEqual(rig.same_user(report), {"epicrig": [1, 2], "epicrig3": [4], "epicrig2": [5]})


if __name__ == "__main__":
    unittest.main()
