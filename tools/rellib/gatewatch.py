# SPDX-License-Identifier: Apache-2.0
"""The gate watcher (docs/RELEASING.md, "The publish gate"). When the publish or rollback gate is
asked and waits, tools/rel starts `tools/rel gate-watch --foreground` detached from the agent and
the terminal that ran it (a systemd user unit, else a new session). It reads the gate every
[gate] watch_every seconds as tools/rel does (Relmsg.gate_status, the producer token, which cannot
approve) and, once the owner approves, runs `tools/rel publish` once; that checks the gate again
itself before anything is published. A hold is recorded through `tools/rel gate` and ends the
watch. It never approves and never decides: only the gate's own answer moves the run.

One watcher per gate question (a lock file in the run folder). It stops on a hold, a new gate
question, a tainted, superseded, ended or published run, or after [gate] watch_hours. A relay
error is not an answer: it keeps watching, less often. Its log: <run>/gatewatch.log.
REL_GATEWATCH set to anything starts none (the watcher sets it for its own tools/rel calls)."""
import pathlib
import fcntl
import os
import random
import re
import shutil
import subprocess
import time

from .engine import EXIT_BUSY, EXIT_OK, EXIT_WAITING
from .relmsg import GATE_APPROVED, GATE_HELD, GATE_PENDING, Relmsg
from .run import Run, now_iso

ENV = "REL_GATEWATCH"
EVERY_S, HOURS = 60, 72
BACKOFF_MAX_S = 900
# What the detached watcher keeps of the starting environment. Not TMPDIR and the like: an agent's
# scratch dir goes when the agent does, and the watcher outlives it.
ENV_KEEP = ("PATH", "HOME", "USER", "LOGNAME", "LANG", "LC_ALL", "SSH_AUTH_SOCK", "XDG_RUNTIME_DIR",
            "DBUS_SESSION_BUS_ADDRESS")
ENV_PREFIXES = ("REL_", "RELMSG_", "WFE_")


def settings(pipeline, every=None):
    g = getattr(pipeline, "data", {}).get("gate", {})
    return float(every or g.get("watch_every", EVERY_S)), float(g.get("watch_hours", HOURS))


def gate_of(run):
    """-> (gate name, gate step) or (None, None): the rollback gate is "rollback", as publish_gate names it."""
    step = next((s for s in run.steps if s.kind == "gate"), None)
    if step is None:
        return None, None
    return ("rollback" if step.base == "rollback-gate" else "publish"), step


def gate_id(run, gname):
    return ((run.info.get("gates") or {}).get(gname) or {}).get("gate_id")


def log_path(run):
    return os.path.join(run.path, "gatewatch.log")


def lock_path(run, gname, gid):
    return os.path.join(run.path, f".gatewatch-{gname}-{re.sub(r'[^A-Za-z0-9_-]', '-', str(gid))}.lock")


def unit_name(run, gname, gid):
    return "rel-gatewatch-" + re.sub(r"[^A-Za-z0-9-]", "-", f"{run.info['run_id']}-{gname}-{gid}")


def take_lock(run, gname, gid):
    """-> the open lock file, or None when a watcher already holds it. Closing it releases it, and a
    watcher that died released it with its process."""
    f = open(lock_path(run, gname, gid), "a+")
    try:
        fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        f.close()
        return None
    f.seek(0)
    f.truncate()
    f.write(f"{os.getpid()}\n")
    f.flush()
    return f


def alive(run, gname, gid):
    """Is a watcher on this gate question running? Read from the pid in its lock file, without
    taking the lock (a watcher starting at that moment would find it taken)."""
    try:
        pid = int(pathlib.Path(lock_path(run, gname, gid)).read_text().split()[0])
    except (OSError, ValueError, IndexError):
        return False
    try:
        with open(f"/proc/{pid}/cmdline", "rb") as f:
            return b"gate-watch" in f.read()
    except FileNotFoundError:
        return False
    except OSError:
        try:
            os.kill(pid, 0)
            return True
        except OSError:
            return False


def watcher_env():
    env = {k: v for k, v in os.environ.items()
           if (k in ENV_KEEP or k.startswith(ENV_PREFIXES)) and "\n" not in v}
    env[ENV] = "1"
    return env


def spawn(argv, unit, log, max_s):
    """Starts argv detached: a systemd user unit (survives the session; lingering is on), else a
    new session with no terminal, output to the log. -> what was started. Tests replace it."""
    env = watcher_env()
    why = "no systemd-run"
    if shutil.which("systemd-run"):
        cmd = ["systemd-run", "--user", f"--unit={unit}", "--collect", "--quiet",
               f"--property=RuntimeMaxSec={int(max_s)}", f"--working-directory={os.path.dirname(os.path.dirname(argv[0]))}"]
        cmd += [f"--setenv={k}={v}" for k, v in sorted(env.items())] + ["--"] + argv
        try:
            p = subprocess.run(cmd, capture_output=True, text=True, timeout=30, stdin=subprocess.DEVNULL)
            if p.returncode == 0:
                return {"how": "systemd", "unit": unit}
            why = f"systemd-run exit {p.returncode}: {p.stderr.strip()[-200:]}"
        except (OSError, subprocess.TimeoutExpired) as e:
            why = f"systemd-run: {e}"
    with open(log, "a", encoding="utf-8") as f:
        f.write(f"{now_iso()} {why}; starting in a new session\n")
        f.flush()
        p = subprocess.Popen(argv, stdin=subprocess.DEVNULL, stdout=f, stderr=subprocess.STDOUT, env=env,
                             start_new_session=True, close_fds=True)
    return {"how": "setsid", "pid": p.pid, "why": why}


def rel_argv(run, pipeline, hosts_file, args):
    from .cli import RUNNER
    argv = [os.path.join(RUNNER, "tools", "rel"), "--state-root", os.path.dirname(os.path.dirname(run.path))]
    if getattr(pipeline, "path", None) and os.path.isfile(pipeline.path):
        argv += ["--pipeline", os.path.abspath(pipeline.path)]
    if hosts_file:
        argv += ["--hosts", hosts_file]
    return argv + args


def start(run, pipeline, hosts_file, step_id, every=None):
    """Starts a watcher for the gate question on record, unless one runs. -> (started or already
    running, a line for the step note). Never raises: the gate's answer does not depend on it."""
    try:
        if os.environ.get(ENV):
            return False, None
        gname, _ = gate_of(run)
        gid = gate_id(run, gname) if gname else None
        if gid is None:
            return False, "no gate question to watch"
        if alive(run, gname, gid):
            return True, "a gate watcher checks it and publishes once approved"
        ev, hours = settings(pipeline, every)
        args = ["gate-watch", "--run", run.path, "--foreground"] + (["--every", f"{ev:g}"] if every else [])
        w = spawn(rel_argv(run, pipeline, hosts_file, args), unit_name(run, gname, gid), log_path(run),
                  hours * 3600 + 600)
        w.update(started=now_iso(), gate_id=gid)
        run.info.setdefault("gates", {}).setdefault(gname, {})["watch"] = w
        run.save_info()
        run.event(step_id, "gate-watch", state="started", gate=gname, **w)
        return True, f"a gate watcher ({w.get('unit') or 'pid ' + str(w.get('pid'))}) publishes once approved"
    except Exception as e:  # noqa: BLE001 - the gate goes on without a watcher
        try:
            run.event(step_id, "gate-watch", state="not-started", error=f"{type(e).__name__}: {e}"[:300])
        except Exception:  # noqa: BLE001
            pass
        return False, f"gate watcher not started: {type(e).__name__}: {e}"[:160]


def rel_caller(run, pipeline, hosts_file):
    """-> rel(args): runs tools/rel from this runner with the run's state root, output to the
    watcher's log, and returns its exit code."""
    def rel(args):
        with open(log_path(run), "a", encoding="utf-8") as f:
            f.write(f"{now_iso()} $ tools/rel {' '.join(args)}\n")
            f.flush()
            p = subprocess.run(rel_argv(run, pipeline, hosts_file, args), stdin=subprocess.DEVNULL, stdout=f,
                               stderr=subprocess.STDOUT, env=dict(os.environ, **{ENV: "1"}))
            f.write(f"{now_iso()} tools/rel {args[0]} exit {p.returncode}\n")
        return p.returncode
    return rel


class Watcher:
    def __init__(self, run, pipeline, rel, every=None, sleep=time.sleep, clock=time.time):
        self.path = run.path
        self.run = run
        self.pipeline = pipeline
        self.rel = rel
        self.every, self.hours = settings(pipeline, every)
        self.sleep = sleep
        self.clock = clock

    def say(self, text):
        with open(log_path(self.run), "a", encoding="utf-8") as f:
            f.write(f"{now_iso()} {text}\n")

    def loop(self):
        """-> (exit code, message). 0 for every ordinary end; the publish exit code once it ran."""
        gname, step = gate_of(self.run)
        gid = gate_id(self.run, gname) if gname else None
        if gid is None:
            return EXIT_OK, "no gate question to watch"
        lock = take_lock(self.run, gname, gid)
        if lock is None:
            return EXIT_OK, f"already watching {gname} gate {gid} of {self.run.info['run_id']}"
        try:
            self.say(f"watching {gname} gate {gid} every {self.every:g}s, at most {self.hours:g} h (pid {os.getpid()})")
            self.run.event(step.id, "gate-watch", state="watching", gate=gname, gate_id=gid, pid=os.getpid())
            code, why = self._loop(gname, step, gid)
            self.say(f"stopped: {why}")
            self.run.event(step.id, "gate-watch", state="stopped", gate=gname, gate_id=gid, reason=why)
            return code, why
        finally:
            lock.close()

    def stop_reason(self, run, gname, step, gid):
        info, rm = run.info, run.info.get("relmsg") or {}
        if info.get("tainted"):
            return f"run tainted: {info['tainted'][-1]['reason']}"
        if rm.get("superseded_by"):
            return f"superseded by {rm['superseded_by']}"
        if rm.get("ended"):
            return f"the run's relay release ended ({rm['ended']})"
        if info.get("published") or info.get("published_scratch"):
            return "already published"
        if info.get("no_relmsg"):
            return "relmsg is off for this run"
        now = gate_id(run, gname)
        if now != gid:
            return f"a new gate question ({now}) has its own watcher" if now is not None else "the gate question is gone"
        if run.status(step.id)["status"] == "held":
            return "the gate is held"
        return None

    def _loop(self, gname, step, gid):
        deadline = self.clock() + self.hours * 3600
        fails = 0
        while True:
            run = Run(self.path)
            why = self.stop_reason(run, gname, step, gid)
            if why:
                return EXIT_OK, why
            if self.clock() >= deadline:
                return EXIT_OK, f"no decision in {self.hours:g} h: tools/rel gate-watch --run {run.info['run_id']} watches again"
            try:
                state, out = Relmsg(run, self.pipeline.relmsg).gate_status(gid)
            except Exception as e:  # noqa: BLE001 - not an answer
                state, out = "error", {"error": str(e)}
            if state == GATE_APPROVED:
                rc = self.rel(["publish", "--run", self.path])
                # The run lock was taken (75), or tools/rel publish found the gate busy and said
                # waiting: the approval stands, so ask again next time.
                if rc == EXIT_BUSY or (rc == EXIT_WAITING and Run(self.path).status(step.id)["status"] != "done"):
                    self.say(f"approved; tools/rel publish exit {rc} (busy): again in {self.every:g}s")
                else:
                    run.event(step.id, "gate-watch", state="published" if rc == EXIT_OK else "publish-ended",
                              gate=gname, gate_id=gid, rc=rc)
                    return rc, f"approved; tools/rel publish exit {rc}"
            elif state == GATE_HELD:
                rc = self.rel(["gate", "--run", self.path])  # records the hold as tools/rel does
                if rc == EXIT_BUSY:
                    self.say(f"held; tools/rel gate busy: recording it again in {self.every:g}s")
                elif rc != EXIT_OK:
                    return EXIT_OK, f"held by {out.get('decided_by') or 'the owner'}" + (f": {out['note']}" if out.get("note") else "")
            if state in (GATE_APPROVED, GATE_HELD, GATE_PENDING):
                fails = 0
            else:
                fails += 1
                self.say(f"gate status unreadable ({str(out.get('error') or out)[:160]}): not an answer, watching on")
            delay = min(self.every * 2 ** min(fails, 6), max(self.every, BACKOFF_MAX_S))
            self.sleep(delay + random.uniform(0, self.every / 10))


def watch_of(run):
    """The running watcher on the gate question on record ({how, unit|pid, ...}), or None."""
    gname, _ = gate_of(run)
    gid = gate_id(run, gname) if gname else None
    if gid is None or not alive(run, gname, gid):
        return None
    return ((run.info.get("gates") or {}).get(gname) or {}).get("watch") or {"how": "by hand"}
