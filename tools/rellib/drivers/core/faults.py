# SPDX-License-Identifier: Apache-2.0
"""The two ways a lane stops, and the one line that says which.

ProductFault: the app did something wrong (data lost, a send failed, the wallet does not open, the
app quit by itself). The lane fails (exit 1); never retried into a pass.
HarnessFault: the test could not drive or observe (a control not found after every recovery, the
emulator or display gone, P busy). The lane could not run (exit 2); the release reruns it.
InfraFault: the machine, network or rig under the test failed (node unreachable, ssh timeout, a
leftover install): a HarnessFault the engine retries as infra.
HarnessGone: the display, emulator, rig or sandbox behind a Surface disappeared mid-step; the lane
rebuilds the platform and resumes at the phase it was in (lane.py), once per phase.
LaneStopped: a signal stopped the lane (a runner's timeout).
RefusedStart: a lane that would start from the beginning after a failed attempt, with nothing to allow it;
it touched nothing and is no failure of the app, the rig or the driver (lane.py, Resume).
StepReached: a probe (REL_TRUST_PROBE) came to the step it was sent to: not a fault, the lane ends there.

A fault in a phase the lane can go on without is recorded and the lane goes on (Lane.try_phase).
`fatal` marks the ones that make going on impossible.
"""


class Fault(Exception):
    kind = "fault"
    fatal = False  # True: the lane cannot go on to its next phase
    route = None   # the shortest way back to this step (Driver.harness), for a probe

    def __init__(self, step, what, shot=None, check=None):
        super().__init__(what)
        self.step, self.what, self.shot, self.check = step, what, shot, check

    @property
    def cause_class(self):
        """PRODUCT, INFRA or HARNESS-ui: the class every failure ends in."""
        return {"product": "PRODUCT", "infra": "INFRA"}.get(self.kind, "HARNESS-ui")

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
    fatal = True


class LaneStopped(HarnessFault):
    """A signal stopped the lane: what is left is the coins going back and the shutdown."""
    fatal = True


class InfraFault(HarnessFault):
    """The infrastructure failed in a way a retry can fix: `sub` is node, ssh, leftover or rig."""
    kind = "infra"

    def __init__(self, step, what, sub="rig", shot=None, check=None):
        super().__init__(step, what, shot, check)
        self.sub = sub


class RefusedStart(HarnessFault):
    """The rule said no."""
    kind = "refused"
    fatal = True


class StepReached(BaseException):
    """The probe's step passed. A BaseException: no recovery and no `except Exception` may run on past it."""

    def __init__(self, step):
        super().__init__(step)
        self.step = step
