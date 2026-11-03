#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""The Android G4 lane on the shared core (core/lane.py): android_platform.py for the emulator and the
`adb install -r` update, core/phone.py on uiautomator for the screens, core/checks.py on the wallet's
files. Called by ../trust-android.sh with the REL_* environment (see there)."""
import os
import signal
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, HERE)
sys.path.append(os.path.join(os.path.dirname(HERE), "linux"))  # p_funder only; this folder's files.py first

from android_platform import AndroidPlatform  # noqa: E402
from core import checks  # noqa: E402
from core.driver import Driver  # noqa: E402
from core.faults import HarnessFault  # noqa: E402
from core.labels import Labels  # noqa: E402
from core.lane import Lane  # noqa: E402
from core.phone import Phone  # noqa: E402
from p_funder import P  # noqa: E402


def required(funds):
    """REL_CHECKS, else every check (as linux/lane.py): the migration ones only for a candidate that
    encrypts the store, the payment ones only with funds."""
    given = [c.strip() for c in (os.environ.get("REL_CHECKS") or "").split(",") if c.strip()]
    if given:
        return given
    migrate = checks.migrating()[0]
    base = ["wallet_opens", "balance_kept", "custom_nodes_kept", "custom_relays_kept", "settings_kept"]
    # without funds the wallet has no transaction: history has nothing to compare
    return base + (checks.MIGRATION_CHECKS if migrate else []) + (["history_kept", "send_ok", "receive_ok"] if funds else [])


def keep_secrets(out, secrets, log):
    """The test wallet still holds P's funds: its PIN, password and phrase in <out>/secrets (0600 files in a
    0700 folder, never printed), so the funds can be swept back to P with the LEPIC CLI."""
    folder = os.path.join(out, "secrets")
    os.makedirs(folder, mode=0o700, exist_ok=True)
    os.chmod(folder, 0o700)
    for n, v in secrets.items():
        if isinstance(v, str) and v:
            p = os.path.join(folder, n)
            fd = os.open(p, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
            with os.fdopen(fd, "w") as f:
                f.write(v)
            os.chmod(p, 0o600)
    log("funds left: the test wallet's secrets kept in %s (0600) to send them back to P" % folder)


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
    plat = AndroidPlatform(out, log)
    funder = P(e.get("REL_P_TOOL") or os.path.expanduser("/tmp/epic-build/interop/epicpay/p.py"),
               e.get("REL_P_PASS_FILE") or os.path.expanduser("~/.config/btlabs/p-pass-candidates"),
               int(e.get("REL_P_PASS_LINE") or "1"),
               e.get("REL_P_LOCK") or os.path.expanduser("/opt/epic/qa-funder/.rel-lock"), out, log)

    paid = []  # what P sent the test wallet: its secrets are kept when the funds are not sent back
    send = funder.send

    def counted(address, amount):
        ok, out_ = send(address, amount)
        if ok:
            paid.append(amount)
        return ok, out_
    funder.send = counted

    def recipe_for(lane, which, surface):
        d = Driver(surface, Labels.for_build(which), lane.rec, out=lane.out, log=lane.log)
        return Phone(d, which, lane.log)

    def stopped(sig, _frame):  # a runner's timeout: the emulator and stand-ins still go
        raise HarnessFault(lane.phase or "start", "the lane was stopped (signal %d)" % sig)
    signal.signal(signal.SIGTERM, stopped)
    lane = Lane(plat, recipe_for, checks, out=out, log=log, required=required(funds), funds=funds, p=funder)
    rc = lane.main()
    if paid and not lane.results.get("send_ok"):
        keep_secrets(out, lane.secrets, log)
    lane.details.setdefault("signer", plat.certs.get("previous"))
    lane.proof({"signer": plat.certs, "emulator": plat.health})
    return rc


if __name__ == "__main__":
    sys.exit(main())
