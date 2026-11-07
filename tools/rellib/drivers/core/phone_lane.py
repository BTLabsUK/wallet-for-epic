# SPDX-License-Identifier: Apache-2.0
"""The phone G4 lane's entry, shared by android/lane.py and ios/lane.py: the required checks, the
fail-closed proof, P's funder, core/phone.py as the recipe and core/lane.py's Lane on the platform the
caller gives. Each platform's lane.py is its CLI (`checks`, `fail <reason>`, else the lane)."""
import json
import os
import signal
import sys
import time

CORE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(CORE))
sys.path.append(os.path.join(os.path.dirname(CORE), "linux"))  # p_funder only; the platform's own files.py first

from core import checks  # noqa: E402
from core.driver import Driver  # noqa: E402
from core.faults import HarnessFault  # noqa: E402
from core.labels import Labels  # noqa: E402
from core.lane import Lane, fail_closed as lane_fail_closed  # noqa: E402
from core.phone import Phone  # noqa: E402


def create_mode():
    """REL_TRUST_MODE=create: the candidate installed fresh and a new wallet made on it (Lane.main runs
    Lane.create_only); no previous release, no update, no funds."""
    return (os.environ.get("REL_TRUST_MODE") or "").strip() == "create"


def required(funds):
    """REL_CHECKS, else every check (as linux/lane.py): the migration ones only for a candidate that
    encrypts the store, the candidate's payment ones only with funds (every lane funds the previous
    release's wallet). Create mode: checks.CREATE_CHECKS."""
    given = [c.strip() for c in (os.environ.get("REL_CHECKS") or "").split(",") if c.strip()]
    if given:
        return given
    if create_mode():
        return list(getattr(checks, "CREATE_CHECKS", ["create_ok"]))
    migrate = checks.migrating()[0]
    base = ["wallet_opens", "balance_kept", "history_kept", "custom_nodes_kept", "custom_relays_kept", "settings_kept"]
    return base + (checks.MIGRATION_CHECKS if migrate else []) + (["send_ok", "receive_ok"] if funds else [])


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


def fail_closed(platform, reason):
    """The entry script could not start the lane: result.txt and a proof.json with every required check false."""
    return lane_fail_closed(platform, reason, required(os.environ.get("REL_FUNDS", "1") == "1"))


def run(make_platform, proof_extra, not_checked=None):
    """The lane on make_platform(out, log); proof_extra(platform) -> the platform's own proof fields.
    [not_checked]: {check: why} the platform cannot make, said in the result line when not required."""
    e = os.environ
    out = os.path.abspath(e.get("REL_OUT") or ".")
    os.makedirs(out, exist_ok=True)

    def log(s):
        line = "%s %s" % (time.strftime("%H:%M:%S"), s)
        print(line, flush=True)
        with open(os.path.join(out, "trust.log"), "a") as f:
            f.write(line + "\n")

    from p_funder import P
    create = create_mode()
    funds = e.get("REL_FUNDS", "1") == "1" and not create
    plat = make_platform(out, log)
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
    returned = []  # the sends back to P that the wallet's data shows confirmed (send_ok is unset without REL_FUNDS)
    send_to_p = checks._send_to_p

    def tracked(lane_, d0, amount=None, **kw):
        ok, why = send_to_p(lane_, d0, amount, **kw)
        returned.append(ok)
        return ok, why
    checks._send_to_p = tracked

    def recipe_for(lane, which, surface):
        d = Driver(surface, Labels.for_build(which), lane.rec, out=lane.out, log=lane.log)
        return Phone(d, which, lane.log)

    def stopped(sig, _frame):  # a runner's timeout: the device and stand-ins still go
        raise HarnessFault(lane.phase or "start", "the lane was stopped (signal %d)" % sig)
    signal.signal(signal.SIGTERM, stopped)
    lane = Lane(plat, recipe_for, checks, out=out, log=log, required=required(funds), funds=funds, p=funder)
    rc = lane.main()
    if paid and not any(returned):
        if getattr(lane, "mode", None) == "seed":  # the lane's own wallet: its phrase is in the seed store, nothing written here
            log("funds left on the lane's seed wallet: sent back by the next run, no secrets written")
        else:
            keep_secrets(out, lane.secrets, log)
    lane.details.setdefault("signer", plat.certs.get("previous"))
    gaps = {c: why for c, why in (not_checked or {}).items() if c not in lane.required}
    lane.proof(dict(proof_extra(plat), not_checked=gaps))
    if gaps:  # the summary line says what the lane did not check
        res = os.path.join(out, "result.txt")
        with open(res) as f:
            line = f.read().strip()
        with open(res, "w") as f:
            f.write("%s; %s\n" % (line, "; ".join(gaps.values())))
        log("not checked: " + "; ".join(gaps.values()))
    return rc


def cli(platform, make_platform, proof_extra, not_checked=None):
    if sys.argv[1:2] == ["checks"]:  # the dry run's plan
        print(",".join(required(os.environ.get("REL_FUNDS", "1") == "1" and not create_mode())))
        return 0
    if sys.argv[1:2] == ["fail"]:
        return fail_closed(platform, sys.argv[2])
    return run(make_platform, proof_extra, not_checked)
