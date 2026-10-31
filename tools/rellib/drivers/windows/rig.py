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
key. So a run holds a lock on its rig's user (here, flock) and a second run for the same user waits;
only rigs with different users run side by side."""
import base64
import fcntl
import json
import os
import re
import subprocess
import time

QUEUE = r"C:\wintest-rig\scripts\queue-script.ps1"
HERE = os.path.dirname(os.path.abspath(__file__))


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


class RigError(Exception):
    pass


class Rig:
    def __init__(self, host, name, log, control_dir, session=1):
        self.host = host
        self.session = session
        self.base = work_dir(session) + r"\trust"
        self.run = self.base + r"\runs" + "\\" + name
        self.log = log
        self.user = None
        self.control_dir = control_dir
        self._lock = None
        os.makedirs(control_dir, mode=0o700, exist_ok=True)
        self.ssh_opts = ["-o", "BatchMode=yes", "-o", "ControlMaster=auto", "-o", "ControlPersist=900",
                         "-o", "ControlPath=%s/cm-%%C" % control_dir, "-o", "ServerAliveInterval=30"]
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

    def close(self):
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
            fcntl.flock(self._lock, fcntl.LOCK_EX)
        self.log("rig session %d (%s, %s) as %s" % (self.session, task_name(self.session), work_dir(self.session), self.user))

    def prepare(self):
        self.lock_user()
        self.pwsh("New-Item -ItemType Directory -Force '%s\\bin','%s' | Out-Null" % (self.base, self.run))
        for f in ("agent.ps1", "rpc.ps1"):
            self.put(os.path.join(HERE, f), self.base + "\\bin\\" + f)

    def busy(self):
        """Jobs waiting in or running from the rig queue (an agent waits behind them). A running mark
        older than the task's 4 h limit is a leftover, not a job."""
        q = work_dir(self.session) + "\\queue"
        out = self.pwsh("(Get-ChildItem %s -Filter *.json -File).Count; "
                        "(Get-ChildItem %s\\done -Filter *.running.json -File | "
                        "Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-4) }).Count" % (q, q))
        n = [int(x) for x in out.split()[:2]] if out.strip() else [0, 0]
        return n[0] + n[1]

    def start_agent(self, idle_min=45, wait_s=420):
        label = "trust-" + self.run.rsplit("\\", 1)[-1][-15:]
        self.pwsh("& '%s' '%s\\bin\\agent.ps1' -ScriptArgs @('%s','%d') -Label '%s' -Session %d"
                  % (QUEUE, self.base, self.run, idle_min, label, self.session))
        self.log("rig agent queued as %s in rig session %d (%s)" % (self.user, self.session, label))
        r = self.call("ping", timeout=wait_s)
        if not r.get("ok"):
            raise RigError("rig agent did not start: %s" % r.get("error"))
        self.log("rig agent up: user %s, profile %s" % (r.get("user"), r.get("profile")))
        return r

    def call(self, op, timeout=120, **kw):
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
        self.pwsh("New-Item -ItemType Directory -Force '%s' | Out-Null; icacls '%s' /inheritance:r /grant:r "
                  "\"${env:USERNAME}:(OI)(CI)F\" \"%s:(OI)(CI)F\" | Out-Null" % (d, d, self.user or "epicrig"))
        self.put(local, d + "\\" + name)
        return d + "\\" + name

    def quit_agent(self):
        try:
            self.call("quit", timeout=60)
        except Exception:  # noqa: BLE001
            pass
