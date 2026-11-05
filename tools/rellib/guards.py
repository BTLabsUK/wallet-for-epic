# SPDX-License-Identifier: Apache-2.0
"""Things that must never ship: break tests in a release run, and the commits on release/never-ship.toml.
Each check returns the one-line reason to refuse, or None."""
import os
import tomllib

NEVER_SHIP = os.path.join("release", "never-ship.toml")


def run_kind(info):
    """REL_RUN_KIND for the steps: "test" for a --test run, else "release"."""
    return "test" if info.get("test") else "release"


def test_key(info):
    """True when the run's update manifests are signed with btlabs-public's test key and checked
    against the run's test keyring: a --test run, or a tainted run (it never publishes, so its
    manifests never take a real serial or the real update key)."""
    return bool(info.get("test") or info.get("tainted"))


def trust_break_refusal(info, env=None):
    """REL_TRUST_BREAK puts faults into the trust lanes on purpose (drivers/core/breaks.py): test runs only."""
    val = (os.environ if env is None else env).get("REL_TRUST_BREAK", "").strip()
    if val and run_kind(info) != "test":
        return (f"REL_TRUST_BREAK is set ({val}) and {info.get('run_id', 'this run')} is not a --test run: "
                "break tests never run in a release; unset it")
    return None


def never_ship_commits(repo):
    """{full sha: reason} from release/never-ship.toml; a file that cannot be read is an error (fail closed)."""
    path = os.path.join(repo, NEVER_SHIP)
    if not os.path.isfile(path):
        return {}
    with open(path, "rb") as f:
        data = tomllib.load(f)
    return {str(e["sha"]).lower(): f"{e.get('reason', '')} ({e.get('date', '')})".strip()
            for e in data.get("commit", [])}


def never_ship_refusal(info, repo):
    try:
        listed = never_ship_commits(repo)
    except (OSError, tomllib.TOMLDecodeError, KeyError) as e:
        return f"{NEVER_SHIP} cannot be read ({type(e).__name__}: {e}): no release without it"
    commit = str(info.get("commit", "")).lower()
    if commit and commit in listed:
        return f"commit {commit[:12]} is on {NEVER_SHIP} and never ships: {listed[commit]}"
    return None
