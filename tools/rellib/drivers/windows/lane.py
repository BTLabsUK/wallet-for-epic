#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""The Windows G4 lane on the shared core (core/lane.py): windows_platform.py for the rig, Setup and its
files, core/desktop.py on UI Automation (uia.py) for the screens, core/checks.py on the wallet's files.
Called by ../trust-windows.sh (REL_TRUST_V2=1) with the REL_* environment (see there).
The rig user's language is Polish: the app's strings come from the Polish ARB (REL_TRUST_LOCALE=pl)."""
import os
import signal
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "linux"))   # p_funder

# the rig's app shows a change up to ~20 s after a press (no display in a rig session): waits run twice as long
os.environ.setdefault("REL_TRUST_SLOW", "2")

from core import checks  # noqa: E402
from core.desktop import Desktop  # noqa: E402
from core.driver import Driver  # noqa: E402
from core.faults import HarnessFault  # noqa: E402
from core.labels import Labels  # noqa: E402
from core.lane import Lane  # noqa: E402
from windows_platform import WindowsPlatform  # noqa: E402
from p_funder import P  # noqa: E402


def required(funds):
    """REL_CHECKS, else every check: the migration ones only for a candidate that encrypts the store,
    the payment ones only with funds."""
    given = [c.strip() for c in (os.environ.get("REL_CHECKS") or "").split(",") if c.strip()]
    if given:
        return given
    migrate = checks.migrating()[0]
    base = ["wallet_opens", "balance_kept", "history_kept", "custom_nodes_kept", "custom_relays_kept", "settings_kept"]
    return base + (checks.MIGRATION_CHECKS if migrate else []) + (["send_ok", "receive_ok"] if funds else [])


def main():
    e = os.environ
    out = os.path.abspath(e.get("REL_OUT") or ".")
    os.makedirs(out, exist_ok=True)

    def log(s):
        line = "%s %s" % (time.strftime("%H:%M:%S"), s)
        print(line, flush=True)
        with open(os.path.join(out, "trust.log"), "a") as f:
            f.write(line + "\n")

    funds = e.get("REL_FUNDS", "1") == "1"
    os.environ.setdefault("REL_TRUST_LOCALE", "pl")
    os.environ.setdefault("REL_TRUST_SAVE_STATE", "0")   # no saved Windows states yet (windows_platform.save_state)
    os.environ.setdefault("REL_TRUST_START", "fresh")
    plat = WindowsPlatform(out, log)
    funder = P(e.get("REL_P_TOOL") or os.path.expanduser("/tmp/epic-build/interop/epicpay/p.py"),
               e.get("REL_P_PASS_FILE") or os.path.expanduser("~/.config/btlabs/p-pass-candidates"),
               int(e.get("REL_P_PASS_LINE") or "1"),
               e.get("REL_P_LOCK") or os.path.expanduser("/opt/epic/qa-funder/.rel-lock"), out, log)

    def recipe_for(lane, which, surface):
        d = Driver(surface, Labels.for_build(which), lane.rec, out=lane.out, log=lane.log)
        return Desktop(d, which, lane.log)

    def stopped(sig, _frame):  # a runner's timeout: the sandbox and stand-ins still go
        raise HarnessFault(lane.phase or "start", "the lane was stopped (signal %d)" % sig)
    signal.signal(signal.SIGTERM, stopped)
    lane = Lane(plat, recipe_for, checks, out=out, log=log, required=required(funds), funds=funds, p=funder)
    return lane.main()


if __name__ == "__main__":
    sys.exit(main())
