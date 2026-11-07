#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""The Linux G4 lane on the shared core (core/lane.py): linux_platform.py for the sandbox and the
AppImage swap, core/desktop.py on AT-SPI for the screens, core/checks.py on the wallet's files.
Called by ../trust-linux.sh with the REL_* environment (see there)."""
import os
import signal
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, HERE)

from core import checks  # noqa: E402
from core.desktop import Desktop  # noqa: E402
from core.driver import Driver  # noqa: E402
from core.faults import HarnessFault  # noqa: E402
from core.labels import Labels  # noqa: E402
from core.lane import Lane, dry_or_fail  # noqa: E402
from linux_platform import LinuxPlatform  # noqa: E402
from p_funder import P  # noqa: E402


def required(funds):
    """REL_CHECKS, else every check: the migration ones only for a candidate that encrypts the store,
    the candidate's payment ones only with funds (every lane funds the previous release's wallet)."""
    given = [c.strip() for c in (os.environ.get("REL_CHECKS") or "").split(",") if c.strip()]
    if given:
        return given
    migrate = checks.migrating()[0]
    base = ["wallet_opens", "balance_kept", "history_kept", "custom_nodes_kept", "custom_relays_kept", "settings_kept"]
    return base + (checks.MIGRATION_CHECKS if migrate else []) + (["send_ok", "receive_ok"] if funds else [])


def main():
    done = dry_or_fail("linux", required)
    if done is not None:
        return done
    e = os.environ
    out = os.path.abspath(e.get("REL_OUT") or ".")
    os.makedirs(out, exist_ok=True)

    def log(s):
        line = "%s %s" % (time.strftime("%H:%M:%S"), s)
        print(line, flush=True)
        with open(os.path.join(out, "trust.log"), "a") as f:
            f.write(line + "\n")

    create = e.get("REL_TRUST_MODE") == "create"   # the create-wallet test: the candidate fresh, no funds
    funds = not create and e.get("REL_FUNDS", "1") == "1"
    plat = LinuxPlatform(out, log)
    funder = P(e.get("REL_P_TOOL") or os.path.expanduser("/tmp/epic-build/interop/epicpay/p.py"),
               e.get("REL_P_PASS_FILE") or os.path.expanduser("~/.config/btlabs/p-pass-candidates"),
               int(e.get("REL_P_PASS_LINE") or "1"),
               e.get("REL_P_LOCK") or os.path.expanduser("/opt/epic/qa-funder/.rel-lock"), out, log)

    def recipe_for(lane, which, surface):
        d = Driver(surface, Labels.for_build(which), lane.rec, out=lane.out, log=lane.log)
        return Desktop(d, which, lane.log)

    def stopped(sig, _frame):  # a runner's timeout: the sandbox and stand-ins still go
        raise HarnessFault(lane.phase or "start", "the lane was stopped (signal %d)" % sig)
    lane = Lane(plat, recipe_for, checks, out=out, log=log, required=["create_ok"] if create else required(funds), funds=funds, p=funder)
    signal.signal(signal.SIGTERM, stopped)
    return lane.create_only() if create else lane.main()


if __name__ == "__main__":
    sys.exit(main())
