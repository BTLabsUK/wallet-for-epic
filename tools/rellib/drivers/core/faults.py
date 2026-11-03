# SPDX-License-Identifier: Apache-2.0
"""The two ways a lane stops, and the one line that says which.

ProductFault: the app did something wrong (data lost, a send failed, the wallet does not open, the
app quit by itself). The lane fails (exit 1); never retried into a pass.
HarnessFault: the test could not drive or observe (a control not found after every recovery, the
emulator or display gone, P busy). The lane could not run (exit 2); the release reruns it.
HarnessGone: the display, emulator, rig or sandbox behind a Surface disappeared mid-step; the lane
rebuilds the platform and resumes at the phase it was in (lane.py), once per phase.
"""


class Fault(Exception):
    kind = "fault"

    def __init__(self, step, what, shot=None, check=None):
        super().__init__(what)
        self.step, self.what, self.shot, self.check = step, what, shot, check

    def line(self):
        """`PRODUCT <step>: <what> [shot]` — the failure in one line, for the log tail, proof.json and the gate."""
        s = "%s %s: %s" % (self.kind.upper(), self.step, self.what)
        return s + (" [%s]" % self.shot if self.shot else "")


class ProductFault(Fault):
    kind = "product"


class HarnessFault(Fault):
    kind = "harness"


class HarnessGone(HarnessFault):
    """The infrastructure under the app went away (not the app itself)."""
