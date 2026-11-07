# SPDX-License-Identifier: Apache-2.0
"""The Windows rig from the build machine: SSH to the box as the rig user (one multiplexed connection), the agent
(agent.ps1) queued once per run through one rig session's queue, commands through rpc.ps1.

The box has rig sessions 1..9 (wintest-rig scripts\\task-entry.ps1): session k is the scheduled task
EpicWalletRig<k> (EpicWalletRig for 1) with the work dir C:\\EpicRig<k> (C:\\EpicRig for 1) and its own
queue. Everything of a run lives under <work>\\trust: bin\\ (agent.ps1, rpc.ps1) and runs\\<name>\\
(the agent's cmd/res folders, the app's USERPROFILE home\\ with its data folder and per-user install,
installers, logs).

Every rig job runs in session 0, where Local\\ is one namespace for all, and a job's user has one HKCU:
two runs as the same Windows user collide on the app's single-instance mutex and on Setup's uninstall
key. So a run holds a lock on its rig's user (here, flock, ~/.cache/rel-trust-windows/ctl/user-<host>-<user>.lock)
and a second run for the same user waits; only rigs with different users run side by side. A second user
shares session 0's names but not their access: the mutex the first user made refuses it
(ERROR_ACCESS_DENIED, which main.cpp lets start; only ERROR_ALREADY_EXISTS ends it), and it has an HKCU
of its own.

Rig users (2026-11-03): rigs 1..3 epicrig, rig 4 epicrig3, rig 5 epicrig2. A rig of its own user is made
on the box, elevated, with wintest-rig scripts\\setup-test-user.ps1 -UserName epicrig<n> -Only <k>."""
import base64
import datetime
import fcntl
import gzip
import json
import os
import re
import signal
import subprocess
import time

QUEUE = r"C:\wintest-rig\scripts\queue-script.ps1"
HERE = os.path.dirname(os.path.abspath(__file__))
# A rig task wakes every 2 minutes and picks the oldest job: a job not picked within PICKUP_S of an
# empty queue means the rig is dead (REL_WIN_PICKUP_S overrides). A task with no run for HEARTBEAT_S
# that is not running a job has stopped waking.
PICKUP_S = 180
HEARTBEAT_S = 600
STUCK_QUEUE_S = 600
# LastTaskResult: 0 ok, 0x41301 running; 0x41303 "has not yet run". 0x800710E0 ("the operator or
# administrator has refused the request") is the 2-minute trigger refused while a job runs: busy, not dead
RESULT_OK = (0, 0x41301)
NEVER_RAN = 0x41303
REFUSED_WHILE_RUNNING = 0x800710E0


def work_dir(session):
    return r"C:\EpicRig" if session == 1 else r"C:\EpicRig%d" % session


def task_name(session):
    return "EpicWalletRig" if session == 1 else "EpicWalletRig%d" % session


def pick_session(variant, hosts_file=None):
    """The rig session for a variant: REL_WIN_RIG, else [host.windows] rigs.<variant> in
    release-hosts.toml, else 1."""
    v = os.environ.get("REL_WIN_RIG", "").strip()
    if not v:
        path = os.path.expanduser(hosts_file or os.environ.get("REL_HOSTS") or "~/.config/btlabs/release-hosts.toml")
        try:
            import tomllib
            with open(path, "rb") as f:
                v = str(tomllib.load(f).get("host", {}).get("windows", {}).get("rigs", {}).get(variant, ""))
        except (OSError, ValueError):
            v = ""
    if not v:
        return 1
    if not re.fullmatch(r"[1-9]", v):
        raise RigError("rig session must be 1..9, not %r" % v)
    return int(v)


def candidate_sessions(variant, hosts_file=None):
    """The session for a variant first, then the other sessions [host.windows] rigs names, then 1: where a
    run goes when its own rig is dead."""
    out = [pick_session(variant, hosts_file)]
    path = os.path.expanduser(hosts_file or os.environ.get("REL_HOSTS") or "~/.config/btlabs/release-hosts.toml")
    try:
        import tomllib
        with open(path, "rb") as f:
            rigs = tomllib.load(f).get("host", {}).get("windows", {}).get("rigs", {})
    except (OSError, ValueError):
        rigs = {}
    for k in [rigs.get(variant)] + [v for n, v in sorted(rigs.items()) if n != variant] + [1]:
        if re.fullmatch(r"[1-9]", str(k or "")) and int(k) not in out:
            out.append(int(k))
    return out


class RigError(Exception):
    pass


class RigDead(RigError):
    """The rig session did not pick up a job: another session may take the run."""


class RigStopped(RigError):
    """A signal stopped the run while it waited for its rig user's lock."""


# ---- health (read-only, as BT, no admin): rig-health.ps1 on the box, judged here

def ps_file_command(path, args=""):
    """A command line that runs a local PowerShell file on the box: gzip + base64 inline, short enough for
    cmd.exe (an -EncodedCommand of the whole file is not)."""
    with open(path, "rb") as f:
        b = base64.b64encode(gzip.compress(f.read(), 9)).decode()
    return ("pwsh -NoProfile -NonInteractive -Command \"$s=[IO.StreamReader]::new([IO.Compression.GZipStream]::new("
            "[IO.MemoryStream]::new([Convert]::FromBase64String('%s')),[IO.Compression.CompressionMode]::Decompress))"
            ".ReadToEnd(); & ([ScriptBlock]::Create($s)) %s\"" % (b, args))


def parse_health(out):
    """rig-health.ps1's output -> {session: facts}."""
    recs = {}
    for line in (out or "").splitlines():
        line = line.strip().lstrip("\ufeff")
        if line.startswith("RIG "):
            try:
                r = json.loads(line[4:])
            except ValueError:
                continue
            recs[int(r["session"])] = r
    return recs


def _when(s):
    try:
        return datetime.datetime.strptime(s, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc)
    except (TypeError, ValueError):
        return None


def judge(r, now=None):
    """What is wrong with one rig session, most basic cause first; [] when healthy."""
    if not r:
        return ["not found on the box"]
    if not r.get("exists"):
        return ["no scheduled task %s" % r.get("task")]
    now = now or _when(r.get("now")) or datetime.datetime.now(datetime.timezone.utc)
    user = r.get("user") or "?"
    bad = []
    if not r.get("enabled"):
        bad.append("task %s is disabled" % r["task"])
    if not r.get("sid") or "account_enabled" not in r:
        bad.append("the task's user %s is not a local account" % user)
    else:
        if not r.get("account_enabled"):
            bad.append("account %s is disabled" % user)
        if r.get("locked"):
            bad.append("account %s is locked out" % user)
        exp = _when(r.get("password_expires"))
        if exp and exp <= now:
            bad.append("the password of %s expired %s" % (user, r["password_expires"]))
        exp = _when(r.get("account_expires"))
        if exp and exp <= now:
            bad.append("account %s expired %s" % (user, r["account_expires"]))
        if r.get("batch_denied"):
            bad.append("%s is denied 'Log on as a batch job' (SeDenyBatchLogonRight)" % user)
        elif not r.get("batch_right") and not r.get("rights_error"):
            bad.append("%s lacks 'Log on as a batch job' (SeBatchLogonRight), so the task cannot log it on" % user)
        if r.get("work_grant") is False:
            bad.append("%s has no Modify grant of its own on %s" % (user, r.get("work")))
    res = r.get("last_result")
    running = r.get("state") == "Running"
    last = _when(r.get("last_run"))
    if res == NEVER_RAN and not last:
        bad.append("task %s has never run (last result 267011 = 0x41303, has not yet run)" % r["task"])
    elif res not in RESULT_OK and res is not None and not (running and res == REFUSED_WHILE_RUNNING):
        bad.append("task %s last run result %d (0x%X)" % (r["task"], res, res & 0xFFFFFFFF))
    if last and not running and (now - last).total_seconds() > HEARTBEAT_S:
        bad.append("task %s has not run since %s" % (r["task"], r["last_run"]))
    oldest = _when(r.get("oldest_queued"))
    if oldest and not running and (now - oldest).total_seconds() > STUCK_QUEUE_S:
        bad.append("%d job(s) waiting in %s\\queue since %s" % (r.get("queued") or 0, r.get("work"), r["oldest_queued"]))
    return bad


def health(host, sessions=None, timeout=120, ssh_opts=()):
    """{session: (facts, problems)} for the given sessions (every rig task on the box when None); raises
    RigError when the box does not answer."""
    args = ("-Sessions %s" % ",".join(str(int(k)) for k in sessions)) if sessions else ""
    r = subprocess.run(["ssh", "-o", "BatchMode=yes", "-o", "ConnectTimeout=15", *ssh_opts, host,
                        ps_file_command(os.path.join(HERE, "rig-health.ps1"), args)],
                       capture_output=True, text=True, errors="replace", timeout=timeout)
    recs = parse_health(r.stdout)
    if r.returncode != 0 and not recs:
        raise RigError("rig health on %s: exit %d: %s" % (host, r.returncode, (r.stderr or r.stdout)[-300:]))
    want = list(sessions) if sessions else sorted(recs)
    return {k: (recs.get(k), judge(recs.get(k))) for k in want}


def describe(session, problems, facts=None):
    who = " as %s" % facts["user"] if facts and facts.get("user") else ""
    return "rig %d (%s%s): %s" % (session, task_name(session), who, "; ".join(problems) if problems else "ok")


def same_user(report):
    """{user: [sessions]} from health(): rigs listed together share one user and run one at a time."""
    out = {}
    for k, (facts, _) in sorted(report.items()):
        if facts and facts.get("user"):
            out.setdefault(facts["user"], []).append(k)
    return out


class Rig:
    def __init__(self, host, name, log, control_dir, session=1):
        self.host = host
        self.session = session
        self.base = work_dir(session) + r"\trust"
        self.run = self.base + r"\runs" + "\\" + name
        self.log = log
        self.user = None
        self.job = None
        self.control_dir = control_dir
        self._lock = None
        self.agent_queued = False
        os.makedirs(control_dir, mode=0o700, exist_ok=True)
        self.ssh_opts = ["-o", "BatchMode=yes", "-o", "ControlMaster=auto", "-o", "ControlPersist=900",
                         "-o", "ControlPath=%s/cm-s%d-%%C" % (control_dir, session), "-o", "ServerAliveInterval=30"]
        self.seq = 0

    # ---- plumbing

    def ssh(self, command, timeout=120, check=True):
        r = subprocess.run(["ssh", *self.ssh_opts, self.host, command], capture_output=True, text=True, errors="replace",
                           timeout=timeout)
        if check and r.returncode != 0:
            raise RigError("ssh %r: exit %d: %s" % (command[:80], r.returncode, (r.stderr or r.stdout)[-400:]))
        return r.stdout

    def pwsh(self, script, timeout=120, check=True):
        """A PowerShell snippet as BT (session 0 over SSH; never epicrig's windows)."""
        enc = base64.b64encode(script.encode("utf-16-le")).decode()
        return self.ssh("pwsh -NoProfile -NonInteractive -EncodedCommand %s" % enc, timeout=timeout, check=check)

    def put(self, local, remote, timeout=600):
        r = subprocess.run(["scp", "-q", *self.ssh_opts, local, "%s:%s" % (self.host, remote.replace("\\", "/"))],
                           capture_output=True, text=True, timeout=timeout)
        if r.returncode != 0:
            raise RigError("scp %s: %s" % (os.path.basename(local), r.stderr[-300:]))

    def get(self, remote, local, timeout=300):
        r = subprocess.run(["scp", "-q", *self.ssh_opts, "%s:%s" % (self.host, remote.replace("\\", "/")), local],
                           capture_output=True, text=True, timeout=timeout)
        return r.returncode == 0

    def forward(self, ports):
        """This host's [ports] on the rig's own 127.0.0.1 (ssh -R on this session's ControlMaster), where
        the app reaches the hermetic node and relay as loopback servers (core/hermetic.py plan).

        NEVER RUN ON A RIG: written and unit-tested only. To check on the first live run: the rig's
        sshd_config allows TCP forwarding (Windows OpenSSH does by default) and nothing on the rig holds
        43413 / 43423. A master asked again for a forward it has answers yes; another master (a lane on
        another rig session of the same host) is refused the port ("remote port forwarding failed"),
        which is taken as that lane's forward serving it, and logged. The forward lives as long as the
        master that made it (ControlPersist after the last use; close() ends it)."""
        if not ports:
            return True
        if subprocess.run(["ssh", *self.ssh_opts, "-O", "check", self.host], capture_output=True, timeout=20).returncode != 0:
            # no master yet: one is made by a plain command, so the forward has one to ride on
            self.ssh("echo up", timeout=60)
        args = [a for p in ports for a in ("-R", "%d:127.0.0.1:%d" % (p, p))]
        r = subprocess.run(["ssh", *self.ssh_opts, "-O", "forward", *args, self.host], capture_output=True, text=True,
                           errors="replace", timeout=30)
        if r.returncode == 0:
            self.log("rig: this host's %s forwarded to the rig's 127.0.0.1" % ", ".join(map(str, ports)))
            return True
        why = (r.stderr or r.stdout).strip()[-300:]
        if "forwarding failed" in why:
            self.log("rig: %s already held on the rig (another lane's forward, taken as serving it): %s" % (
                ", ".join(map(str, ports)), why))
            return True
        raise RigError("ssh -O forward %s: exit %d: %s" % (" ".join(args), r.returncode, why))

    def close(self):
        # the master is this session's own (ControlPath above): lanes on other rigs keep theirs
        subprocess.run(["ssh", *self.ssh_opts, "-O", "exit", self.host], capture_output=True, timeout=20)
        if self._lock:
            self._lock.close()
            self._lock = None

    # ---- the agent

    def lock_user(self):
        """The Windows user of this rig session's task (read, never changed), then a lock on it held until
        close(): a second run on a rig with the same user waits here."""
        out = self.pwsh("$ProgressPreference = 'SilentlyContinue'; $t = Get-ScheduledTask -TaskName '%s' -ErrorAction "
                        "SilentlyContinue; if ($t) { 'USER=' + $t.Principal.UserId }" % task_name(self.session))
        m = re.search(r"^USER=(?:.*\\)?([^\\\s]+)\s*$", out, re.M)
        if not m:
            raise RigError("rig session %d: no scheduled task %s on %s" % (self.session, task_name(self.session), self.host))
        self.user = m.group(1)
        path = os.path.join(self.control_dir, "user-%s-%s.lock" % (re.sub(r"[^A-Za-z0-9_.-]", "_", self.host), self.user))
        self._lock = open(path, "w")
        try:
            fcntl.flock(self._lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            self.log("rig session %d runs as %s, whose other run is still on the rig: waiting for it" % (self.session, self.user))
            self._wait_lock()
        self.log("rig session %d (%s, %s) as %s" % (self.session, task_name(self.session), work_dir(self.session), self.user))

    def _wait_lock(self):
        """The blocking wait for the user's lock, ended by SIGTERM or SIGINT: the caller's handler runs (lane.py
        raises its HarnessFault), else RigStopped; either way the lock file is closed and the stop logged."""
        def stop(sig, frame):
            h = old.get(sig)
            if h == signal.SIG_IGN:
                return
            if callable(h) and h is not signal.default_int_handler:
                h(sig, frame)
            raise RigStopped("stopped by %s while waiting for %s's lock on rig session %d"
                             % (signal.Signals(sig).name, self.user, self.session))
        old = {}
        try:
            for sig in (signal.SIGTERM, signal.SIGINT):
                old[sig] = signal.signal(sig, stop)
        except ValueError:  # not the main thread: the default handlers stay
            pass
        try:
            fcntl.flock(self._lock, fcntl.LOCK_EX)
        except BaseException as e:
            self._lock.close()
            self._lock = None
            self.log("HARNESS lock: rig session %d stopped while waiting for %s's lock: %s" % (self.session, self.user, e))
            raise
        finally:
            for sig, h in old.items():
                signal.signal(sig, h)

    def prepare(self):
        self.lock_user()
        # a stop file left in this run folder, for the agent stop_orphans ended, would end the next one on its first pass
        # (the if: a last command that failed, even silently, is pwsh's exit 1, and mostly there is no such file)
        self.pwsh("New-Item -ItemType Directory -Force '%s\\bin','%s' | Out-Null; if (Test-Path -LiteralPath '%s\\stop') { "
                  "Remove-Item -LiteralPath '%s\\stop' -Force -ErrorAction Stop }" % (self.base, self.run, self.run, self.run))
        for f in ("agent.ps1", "rpc.ps1"):
            self.put(os.path.join(HERE, f), self.base + "\\bin\\" + f)

    def stop_orphans(self, wait_s=300):
        """Agents of earlier trust runs still on this rig (the running jobs of <base>\\bin\\agent.ps1 for another
        run folder): with the user's lock held no live run drives them, so their driver died (killed, a lost
        ssh). Each gets its run's stop file (the agent stops what it started and ends); the wait ends when
        their running marks are gone. -> the run folders stopped; RigDead (another session may take the run)
        when one is still running."""
        done = work_dir(self.session) + "\\queue\\done"
        out = self.pwsh(
            "Get-ChildItem '%s' -Filter *.running.json -File -ErrorAction SilentlyContinue | "
            "Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-4) } | ForEach-Object { "
            "$j = Get-Content -Raw -LiteralPath $_.FullName | ConvertFrom-Json; "
            "if ($j.script -eq '%s\\bin\\agent.ps1') { 'ORPHAN ' + $j.args[0] } }" % (done, self.base), check=False)
        runs = [r for r in re.findall(r"^ORPHAN (.+?)\s*$", out, re.M)
                if r.lower().startswith((self.base + "\\runs\\").lower()) and r.lower() != self.run.lower()]
        if not runs:
            return []
        for r in runs:
            self.log("rig session %d: the agent of %s is still running with no run behind it: stopping it" % (self.session, r))
            made = self.pwsh("New-Item -ItemType File -Force -Path '%s\\stop' | Out-Null; Test-Path -LiteralPath '%s\\stop'"
                             % (r, r), check=False)
            if "True" not in made:
                raise RigDead("rig session %d: no stop file could be made for the leftover agent of %s" % (self.session, r))
        t0 = time.time()
        while True:
            left = [r for r in runs if ("ORPHAN " + r) in self.pwsh(
                "Get-ChildItem '%s' -Filter *.running.json -File -ErrorAction SilentlyContinue | ForEach-Object { "
                "$j = Get-Content -Raw -LiteralPath $_.FullName | ConvertFrom-Json; 'ORPHAN ' + $j.args[0] }" % done, check=False)]
            if not left:
                self.log("rig session %d: %d leftover agent(s) stopped" % (self.session, len(runs)))
                return runs
            if time.time() - t0 > wait_s:
                raise RigDead("rig session %d: the leftover agent of %s did not stop within %d s" % (self.session, left[0], wait_s))
            time.sleep(10)

    def busy(self):
        """Jobs waiting in or running from the rig queue (an agent waits behind them). A running mark
        older than the task's 4 h limit is a leftover, not a job."""
        q = work_dir(self.session) + "\\queue"
        out = self.pwsh("(Get-ChildItem %s -Filter *.json -File).Count; "
                        "(Get-ChildItem %s\\done -Filter *.running.json -File | "
                        "Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-4) }).Count" % (q, q))
        n = [int(x) for x in out.split()[:2]] if out.strip() else [0, 0]
        return n[0] + n[1]

    def start_agent(self, idle_min=45, wait_s=420, waiting=0, pickup_s=None):
        """Queues the agent and waits for it. With an empty queue the rig must pick the job within pickup_s
        (PICKUP_S): otherwise the job is taken back and RigDead says why. Behind other jobs the wait is
        wait_s, cut short when the rig turns out dead."""
        label = "trust-" + self.run.rsplit("\\", 1)[-1][-15:]
        out = self.pwsh("& '%s' '%s\\bin\\agent.ps1' -ScriptArgs @('%s','%d') -Label '%s' -Session %d"
                        % (QUEUE, self.base, self.run, idle_min, label, self.session))
        self.agent_queued = True
        m = re.search(r"queued (\S+\.json)", out)
        self.job = m.group(1) if m else None
        self.log("rig agent queued as %s in rig session %d (%s)" % (self.user, self.session, label))
        if pickup_s is None:
            pickup_s = int(os.environ.get("REL_WIN_PICKUP_S") or PICKUP_S)
        t0 = time.time()
        limit = wait_s if waiting else min(pickup_s, wait_s)
        checked = t0
        while self.job and self.queued():
            if time.time() - t0 > limit:
                self.withdraw()
                raise RigDead("rig session %d did not pick up the job within %d s: %s" % (
                    self.session, limit, "; ".join(self.problems()) or "no cause found by the health check"))
            if waiting and time.time() - checked > 120:
                checked = time.time()
                probs = self.problems()
                if probs:
                    self.withdraw()
                    raise RigDead("rig session %d is dead: %s" % (self.session, "; ".join(probs)))
            time.sleep(15)
        r = self.call("ping", timeout=max(60, int(wait_s - (time.time() - t0))))
        if not r.get("ok"):
            raise RigError("rig agent did not start: %s" % r.get("error"))
        self.log("rig agent up: user %s, profile %s" % (r.get("user"), r.get("profile")))
        return r

    def attach_agent(self):
        """The agent an earlier attempt left in this run folder: True when it answers."""
        self.agent_queued = True
        r = self.call("ping", timeout=30)
        if not r.get("ok"):
            self.agent_queued = False
            return False
        self.log("rig agent of the failed attempt still up: user %s, profile %s" % (r.get("user"), r.get("profile")))
        return True

    def detach_agent(self):
        """Ends the agent attach_agent found; start_agent queues the next."""
        self.quit_agent()
        self.agent_queued = False

    def queued(self):
        """Our job file still waits in the queue (the task moves it to done\\ when it starts it)."""
        out = self.pwsh("if (Test-Path -LiteralPath '%s') { 'QUEUED' } else { 'GONE' }" % self.job, check=False)
        return "QUEUED" in out

    def withdraw(self):
        """Takes our own job back out of the queue (by its exact path), so a dead rig keeps no stale job."""
        if self.job:
            self.pwsh("Remove-Item -LiteralPath '%s' -Force -ErrorAction SilentlyContinue" % self.job, check=False)
            self.log("rig session %d: took our job %s back out of its queue" % (self.session, self.job))

    def problems(self):
        try:
            return health(self.host, [self.session], ssh_opts=self.ssh_opts)[self.session][1]
        except (RigError, subprocess.TimeoutExpired, OSError) as e:
            return ["health check failed: %s" % e]

    def call(self, op, timeout=120, **kw):
        if not self.agent_queued:  # a run stopped before its agent: nothing would answer rpc.ps1 for minutes
            return {"ok": False, "error": "no agent on the rig (this run never queued one)"}
        self.seq += 1
        seq = "%s-%05d" % (time.strftime("%H%M%S"), self.seq)
        kw["op"] = op
        b64 = base64.b64encode(json.dumps(kw).encode()).decode()
        out = self.ssh("pwsh -NoProfile -NonInteractive -File %s\\bin\\rpc.ps1 %s %s %s %d" % (self.base, self.run, seq, b64, timeout),
                       timeout=timeout + 60, check=False)
        out = out.strip().lstrip("\ufeff")
        try:
            return json.loads(out) if out else {"ok": False, "error": "no answer"}
        except ValueError:
            return {"ok": False, "error": "bad answer: %s" % out[-300:]}

    # ---- reading the app's files: by the agent, as the rig's user. From 26.10.25 the app keeps its data
    # folder to its own user and SYSTEM (WAL-12), so BT is refused there; before the agent is up
    # (or after it quit) the read falls back to BT over SSH, which an older release still allows.

    def as_owner(self, script, timeout=120):
        """A PowerShell snippet run by the agent (the rig's user); its output, or None when no agent answers."""
        r = self.call("ps", timeout=timeout, code=script)
        return (r.get("out") or "") if r.get("ok") else None

    def text(self, path):
        """A text file's content, None when it does not exist."""
        out = self.as_owner("$p = '%s'; if (Test-Path -LiteralPath $p) { 'OK'; $t = Get-Content -Raw -Encoding utf8 "
                            "-LiteralPath $p; if ($null -eq $t) { $t = '' }; "
                            "[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($t)) -split '(.{1,200})' | "
                            "Where-Object { $_ } } else { 'NONE' }" % path)
        if out is not None:
            lines = [x.strip() for x in out.replace("\r", "").split("\n") if x.strip()]
            if lines and lines[0] == "OK":
                return base64.b64decode("".join(lines[1:])).decode("utf-8", "replace")
            if lines and lines[0] == "NONE":
                return None
        out = self.pwsh("$p = '%s'; if (Test-Path -LiteralPath $p) { 'OK'; Get-Content -Raw -Encoding utf8 -LiteralPath $p } "
                        "else { 'NONE' }" % path, check=False)
        out = out.lstrip("\ufeff")
        return out[2:].lstrip("\r\n") if out.startswith("OK") else None

    def files(self, root, skip=("logs", "tor", "cache")):
        """Files under [root], relative, without the given top folders, lock and log files."""
        script = ("$r = '%s'; if (Test-Path -LiteralPath $r) { Get-ChildItem -LiteralPath $r -Recurse -File -Force | "
                  "ForEach-Object { $_.FullName.Substring($r.Length + 1) } }" % root)
        out = self.as_owner(script)
        if out is None:
            out = self.pwsh(script, check=False)
        keep = []
        for f in out.replace("\r", "").splitlines():
            f = f.strip()
            if not f or f.split("\\")[0] in skip or f.endswith((".lock", ".log")) or f.startswith("LOCK"):
                continue
            keep.append(f.replace("\\", "/"))
        return sorted(keep)

    def fetch_db(self, db, local_dir, tag):
        """Copies the wallet's SQLite files (with -wal and -shm) on the box, then here; the local path. The
        copies land under the run folder, which BT can read."""
        snap = self.run + "\\snap\\" + tag
        script = ("New-Item -ItemType Directory -Force '%s' | Out-Null; foreach ($x in '', '-wal', '-shm') { "
                  "if (Test-Path -LiteralPath ('%s' + $x)) { Copy-Item -LiteralPath ('%s' + $x) -Destination '%s' -Force } }"
                  % (snap, db, db, snap))
        if self.as_owner(script) is None:
            self.pwsh(script)
        local = os.path.join(local_dir, tag)
        os.makedirs(local, exist_ok=True)
        name = db.rsplit("\\", 1)[-1]
        for x in ("", "-wal", "-shm"):
            self.get(snap + "\\" + name + x, os.path.join(local, name + x))
        return os.path.join(local, name)

    def put_secret(self, local, name):
        """A secret file into <run>\\secret (readable by BT and the rig's user only); its path on the box."""
        d = self.run + "\\secret"
        if getattr(self, "_secret_dir", None) != d:  # made once per run (each phrase word is a file of its own)
            self.pwsh("New-Item -ItemType Directory -Force '%s' | Out-Null; icacls '%s' /inheritance:r /grant:r "
                      "\"${env:USERNAME}:(OI)(CI)F\" \"%s:(OI)(CI)F\" | Out-Null" % (d, d, self.user or "epicrig"))
            self._secret_dir = d
        self.put(local, d + "\\" + name)
        return d + "\\" + name

    def quit_agent(self):
        try:
            self.call("quit", timeout=60)
        except Exception:  # noqa: BLE001
            pass
