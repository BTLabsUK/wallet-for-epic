# SPDX-License-Identifier: Apache-2.0
"""How one tools/rel drive shares the machine (release/pipeline.toml [concurrency]).

- A cap on heavy steps at once (`max_heavy`, default 2): a step counts when it is heavy (wrapped
  in build-slot), a proof (G4 trust driver) or marked `capped` (the screens render). Remote
  builds and builtins never count.
- Steps kept apart: `apart` pairs never run at the same time (the full suite and the Android and
  Windows trust lanes), `apart_shared` pairs only while the machine is shared with agents
  (`shared`, default true; none by default: the Windows lanes run on the rigs).
- A full suite outside the run: a step kept apart from source-check also waits (up to
  `external_wait`) while a build-slot slot runs one (`external_suites`, matched against
  `build-slot --status`), then starts anyway and says so.
- Infrastructure retries: a failure whose cause is the machine, not the product or the driver (a signal, a
  missing proof.json, an ssh drop, no build slot), runs once more (`infra_retries`, default 1).
  Product and harness failures, timeouts, checks and publish steps never retry by themselves.
- The release window: while a run drives, a marker file (default
  $XDG_RUNTIME_DIR/wfe-release-window, i.e. /run/user/$UID/wfe-release-window) says so, for
  build-slot and the scheduler to give the release priority. Contract: docs/RELEASING.md, "The release
  window". Readers never change or delete it; a marker whose pid is gone or whose heartbeat is
  older than stale_after_s is no window.
"""
import json
import os
import re
import shlex
import subprocess
import threading
import time

from .config import parse_duration
from .run import now_iso

DEFAULTS = {
    "max_heavy": 2,
    "shared": True,
    "apart": [["source-check", "trust-android"], ["source-check", "trust-windows"]],
    "apart_shared": [],
    "external_suites": ["check.sh --full", "flutter-test-all", "source-check.sh"],
    "external_wait": "60m",
    "infra_retries": 1,
    "poll": "15s",
}
MARKER_NAME = "wfe-release-window"
MARKER_KIND = "wfe-release-window"
STALE_AFTER_S = 180
HEARTBEAT_S = 30


class Policy:
    def __init__(self, conf=None, overrides=None):
        c = dict(DEFAULTS)
        c.update(conf or {})
        c.update({k: v for k, v in (overrides or {}).items() if v is not None})
        self.max_heavy = max(1, int(c["max_heavy"]))
        self.shared = bool(c["shared"])
        self.apart = {}
        for a, b in list(c["apart"]) + (list(c["apart_shared"]) if self.shared else []):
            self.apart.setdefault(a, set()).add(b)
            self.apart.setdefault(b, set()).add(a)
        self.external_suites = list(c["external_suites"])
        self.external_wait = parse_duration(c["external_wait"]) or 0
        self.infra_retries = max(0, int(c["infra_retries"]))
        self.poll = parse_duration(c["poll"]) or 15
        self.marker = c.get("window_marker")

    @staticmethod
    def counts(step):
        if getattr(step, "remote", False):
            return False
        return bool(step.heavy or step.proof or getattr(step, "capped", False))

    def why_not(self, step, running):
        """None when step may start beside the steps in `running`, else why it waits."""
        if self.counts(step):
            n = sum(1 for s in running if self.counts(s))
            if n >= self.max_heavy:
                return f"heavy-step cap ({self.max_heavy}) reached"
        for s in running:
            if s.base in self.apart.get(step.base, ()):
                return f"kept apart from {s.id}"
        return None

    def guards_external(self, step):
        """True for a step kept apart from the full suite: it also waits for one outside the run."""
        return "source-check" in self.apart.get(step.base, ())

    def external_suite(self, status_text):
        """The build-slot slot running a full suite, or None."""
        for line in (status_text or "").splitlines():
            m = re.match(r"^slot \d+: (.*)$", line.strip())
            if m and m.group(1).strip() not in ("", "free", "busy") and \
                    any(p in m.group(1) for p in self.external_suites):
                return m.group(1).strip()[:160]
        return None


def heavy_status():
    """`build-slot --status` (REL_HEAVY_STATUS_CMD replaces the command; empty: none)."""
    cmd = os.environ.get("REL_HEAVY_STATUS_CMD", "build-slot --status")
    if not cmd.strip():
        return ""
    try:
        return subprocess.run(shlex.split(cmd), capture_output=True, text=True, timeout=20).stdout
    except (OSError, subprocess.SubprocessError):
        return ""


# ---- infrastructure or product ------------------------------------------------------------------

SSH_DROP = re.compile(r"client_loop: send disconnect|Connection (reset|closed) by|Broken pipe|"
                      r"ssh: connect to host .*(timed out|refused|No route)|kex_exchange_identification|"
                      r"Connection timed out during banner exchange|ssh_exchange_identification")


def _tail(path, n=50):
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            return f.readlines()[-n:]
    except OSError:
        return []


HARNESS_LINE = re.compile(r"^\s*(?:\S+:\s+)?HARNESS\b", re.MULTILINE)
TRACEBACK = re.compile(r"^Traceback \(most recent call last\)", re.MULTILINE)


def proof_cause(result, log):
    """Why a G4 driver failed, from what it left: proof.fault.kind, its exit code, its log tail.
    "harness" (the rig or the setup could not run the test: exit 2, a fault of kind harness or a
    `HARNESS ...` line), "harness:crash" (the driver raised: a Python traceback and no proof fault),
    "infra:driver-<sub>" (the driver named the machine: a fault of kind infra, its sub e.g. node, ssh, rig),
    "product" (a required check is false, or the driver said PRODUCT) or "step"."""
    proof = result.get("proof") if isinstance(result.get("proof"), dict) else {}
    fault = proof.get("fault") if isinstance(proof.get("fault"), dict) else {}
    if fault.get("kind") == "infra":
        return "infra:driver-%s" % (re.sub(r"[^\w-]+", "-", str(fault.get("sub") or "rig")) or "rig")
    if fault.get("kind") == "harness":
        return "harness"
    if fault.get("kind") == "refused":
        return "check: refused"
    if fault.get("kind") == "product":
        return "product"
    text = "".join(_tail(log, 120))
    if TRACEBACK.search(text):
        return "harness:crash"
    if result.get("rc") == 2 or HARNESS_LINE.search(text):
        return "harness"
    if result.get("failed_checks"):
        return "product"
    return "step"


def cause_of(step, result, log):
    """Why a step failed, for metrics.jsonl and the retry rule: "infra:<what>" (the machine: a
    signal, a missing proof.json, an ssh drop, no build slot), "timeout" (its own hard limit),
    "error" (tools/rel itself), "check" (a builtin or gate said no), for a proof step what
    proof_cause says ("product", "harness", "harness:crash"), else "step" (a build or script
    that exited non-zero). Only "infra:*" retries by itself (a proof's infra:driver-* too)."""
    if result.get("timed_out"):
        return "timeout"
    if result.get("exception"):
        return "error"
    rc = result.get("rc")
    if rc in (-15, 143):
        return "infra:sigterm"
    if rc in (-9, 137):
        return "infra:sigkill"
    if rc in (-1, -2, 129, 130):  # SIGHUP / SIGINT: a shell or session went away
        return "infra:signal"
    if step.kind in ("builtin", "gate"):
        return "check"
    if rc == 75 and step.heavy:
        return "infra:no-slot"
    if rc == 255 or any(SSH_DROP.search(l) for l in _tail(log)):
        return "infra:ssh"
    if step.driven and result.get("proof_missing"):
        return "infra:no-proof"
    if step.driven:
        return proof_cause(result, log)
    return "step"


# ---- the release window marker -----------------------------------------------------------------

def marker_path(conf_path=None):
    p = os.environ.get("REL_WINDOW_MARKER") or conf_path
    if p:
        return os.path.expanduser(p.replace("{uid}", str(os.getuid())))
    rt = os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}"
    if os.path.isdir(rt):
        return os.path.join(rt, MARKER_NAME)
    return os.path.expanduser(f"~/.cache/{MARKER_NAME}")


def read_marker(path, now=None):
    """The marker's data when it is a live window (its pid runs, its heartbeat is fresh), else None."""
    try:
        with open(path, encoding="utf-8") as f:
            d = json.load(f)
    except (OSError, ValueError):
        return None
    if not isinstance(d, dict) or d.get("kind") != MARKER_KIND:
        return None
    try:
        os.kill(int(d["pid"]), 0)
    except (KeyError, ValueError, TypeError, ProcessLookupError):
        return None
    except PermissionError:
        pass  # alive, another user's
    age = (now or time.time()) - float(d.get("heartbeat_t", 0))
    return d if age < float(d.get("stale_after_s", STALE_AFTER_S)) else None


class Window:
    """Holds the marker while a drive runs: written at open, rewritten on every step start and
    end and every HEARTBEAT_S, removed at close (only when it is ours). A live window of another
    tools/rel process is left alone; ours is written once it is gone."""

    def __init__(self, path, info, policy, running, interval=HEARTBEAT_S):
        self.path, self.info, self.policy, self.running = path, info, policy, running
        self.interval = interval
        self.pid = os.getpid()
        self.started = now_iso()
        self._stop = threading.Event()
        self._lock = threading.Lock()
        self._th = None

    def data(self):
        run = list(self.running())
        return {
            "kind": MARKER_KIND, "version": 1, "pid": self.pid, "run_id": self.info.get("run_id"),
            "release": self.info.get("version"), "test": bool(self.info.get("test")),
            "started": self.started, "heartbeat": now_iso(), "heartbeat_t": round(time.time(), 3),
            "stale_after_s": STALE_AFTER_S, "max_heavy": self.policy.max_heavy, "want_slots": self.policy.max_heavy,
            "running": sorted(s.id for s in run),
            "heavy_running": sum(1 for s in run if self.policy.counts(s)),
            "priority_env": "BUILD_SLOT_PRIORITY=release",
        }

    def beat(self):
        with self._lock:
            cur = read_marker(self.path)
            if cur and int(cur.get("pid", -1)) != self.pid:
                return False  # another tools/rel holds the window
            try:
                os.makedirs(os.path.dirname(self.path), exist_ok=True)
                tmp = f"{self.path}.{self.pid}.tmp"
                with open(tmp, "w", encoding="utf-8") as f:
                    json.dump(self.data(), f, indent=1)
                os.replace(tmp, self.path)
                return True
            except OSError:
                return False  # the window is a courtesy: never fails a run

    def open(self):
        self.beat()
        self._th = threading.Thread(target=self._loop, daemon=True)
        self._th.start()
        return self

    def _loop(self):
        while not self._stop.wait(self.interval):
            self.beat()

    def close(self):
        self._stop.set()
        if self._th:
            self._th.join(timeout=5)
        with self._lock:
            try:
                with open(self.path, encoding="utf-8") as f:
                    mine = int(json.load(f).get("pid", -1)) == self.pid
            except (OSError, ValueError, TypeError, AttributeError):
                mine = False
            if mine:
                try:
                    os.remove(self.path)
                except OSError:
                    pass
